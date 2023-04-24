local screen = peripheral.find("monitor")
local w,h = 0,0

local mbg = colors.lightGray
local mfg = colors.gray
local tbg = colors.red
local tfg = colors.lightGray
local ibg = colors.gray
local ifg = colors.lightGray
local iw = 12
local ih = 3
local nw = 42
local nh = 6

local cart = false
local selectedItem = nil
local selectedCount = 1
local cartt = {}

local btns = {}

function addButton(x,y,bw,bh,bg,fg,text,onclick,norefresh)
    if norefresh == nil then
        norefresh = false
    end
    screen.setBackgroundColor(bg)
    screen.setTextColor(fg)

    -- Set the button background
    for iy=y,y+bh-1,1 do
        for ix=x,x+bw-1,1 do
            screen.setCursorPos(ix,iy)
            screen.write(" ")
        end
    end

    -- Write the stuff
    local nx = x+math.floor(bw/2-#text:sub(1,bw)/2)
    local ny = y+math.floor(bh/2)
    screen.setCursorPos(nx,ny)
    screen.write(text:sub(1,bw))

    table.insert(btns, {
        x = x,
        y = y,
        w = x+bw-1,
        h = y+bh-1,
        onclick = onclick,
        norefresh = norefresh
    })
end

function notify(message,bg,fg)
    local x = math.floor(w/2 - nw/2)
    local y = math.floor(h/2 - nh/2)
    screen.setCursorPos(x,y)
    screen.setBackgroundColor(bg)
    screen.setTextColor(fg)
    -- Render the background background
    for iy=y,y+nh-1,1 do
        for ix=x,x+nw-1,1 do
            screen.setCursorPos(ix,iy)
            screen.write(" ")
        end
    end

    -- Render the message
    if type(message) == "table" then
        local nny = y+math.floor(nh/2)
        for k,v in ipairs(message) do
            local nnx = x+math.floor(nw/2-#v:sub(1,nw)/2)
            local nnyn = nny-(math.floor(#message/2)-k)-1
            screen.setCursorPos(nnx,nnyn)
            screen.write(v:sub(1,nw))
        end
    else
        local nnx = x+math.floor(nw/2-#message:sub(1,nw)/2)
        local nny = y+math.floor(nh/2)
        screen.setCursorPos(nnx,nny)
        screen.write(message:sub(1,nw))
    end

    btns = {}
    table.insert(btns, {
        x = 1,
        y = 1,
        w = w,
        h = h,
        onclick = function() end,
        norefresh = false
    })
end

function addItem(x,y,data)
    screen.setCursorPos(x,y)
    screen.setBackgroundColor(ibg)
    screen.setTextColor(ifg)
    -- Set the item background
    for iy=y,y+ih-1,1 do
        for ix=x,x+iw-1,1 do
            screen.setCursorPos(ix,iy)
            screen.write(" ")
        end
    end

    -- Write the name and stuff
    screen.setCursorPos(x,y)
    screen.write(data.name:sub(1,iw))

    screen.setCursorPos(x,y+1)
    if data.cart then
        screen.write(("Count "..data.aviable):sub(1,iw))
    else
        screen.write(("Stock "..data.aviable):sub(1,iw))
    end

    screen.setCursorPos(x,y+2)
    screen.write(("Price "..data.price):sub(1,iw))

    if data.cart then
        table.insert(btns, {
            x = x,
            y = y,
            w = x+iw-1,
            h = y+ih-1,
            onclick = function()
                table.remove(cartt, data.id)
            end,
            norefresh = false
        })
    else
        table.insert(btns, {
            x = x,
            y = y,
            w = x+iw-1,
            h = y+ih-1,
            onclick = function()
                selectedItem = data.id
                selectedCount = 1
            end,
            norefresh = false
        })
    end
end

function renderItems(items,isCart)
    if isCart == nil then
        isCart = false
    end
    local x = 1
    local y = 3
    local id = 1
    for k,v in ipairs(items) do
        v.cart = isCart
        addItem(x,y,v)
        x = x + iw+1
        if x+iw >= w then
            x = 1
            y = y + ih+1
        end
        id = id + 1
    end
end

function renderTitle()
    -- Set the first two lines colored
    screen.setBackgroundColor(tbg)
    screen.setCursorPos(1,1)
    screen.clearLine()
    screen.setCursorPos(1,2)
    screen.clearLine()

    -- Writing the shopname and the description
    screen.setTextColor(tfg)
    screen.setCursorPos(math.floor(w/2-#kristed.config.shopname/2),1)
    screen.write(kristed.config.shopname)
    screen.setCursorPos(math.floor(w/2-#kristed.config.desc/2),2)
    screen.write(kristed.config.desc)

    -- Add the kristed2 label to the bottom left corner
    screen.setCursorPos(1,h)
    screen.setBackgroundColor(mbg)
    screen.setTextColor(mfg)
    screen.write("Powered by Kristed2 v"..kristed.version)

    -- Add the cart to the top right corner
    addButton(w-#("Cart")+1,2,4,1,cart and mbg or tbg,cart and mfg or tfg,"Cart",function()
        cart = true
        selectedItem = nil
        selectedCount = 1
        kristed.checkout.currently = false
        kristed.checkout.price = 0
        kristed.checkout.paid = 0
        kristed.checkout.cart = {}
    end)

    -- Add the items to the top right corner
    addButton(w-#("Cart")-#("Items"),2,5,1,not cart and mbg or tbg,not cart and mfg or tfg,"Items",function()
        cart = false
        selectedItem = nil
        selectedCount = 1
        kristed.checkout.currently = false
        kristed.checkout.price = 0
        kristed.checkout.paid = 0
        kristed.checkout.cart = {}
    end)
end

function renderItemDisplay()
    local items = {}
    for k,v in ipairs(kristed.config.items) do
        table.insert(items, {
            name = v.name,
            aviable = kristed.getItemCount(v.id),
            price = v.price,
            id = k
        })
    end
    renderItems(items)
end

function renderItemSelect()
    -- Render the back button and the item name
    addButton(1,4,6,3,colors.red,colors.gray,"Back",function()
        selectedItem = nil
    end)
    screen.setBackgroundColor(mbg)
    screen.setTextColor(mfg)
    screen.setCursorPos(1,8)
    screen.write("Item: "..kristed.config.items[selectedItem].name)
    -- Render the count thing
    addButton(1,9,3,3,colors.red,colors.gray,"-",function()
        selectedCount = selectedCount - 1
        if selectedCount < 1 then
            selectedCount = 1
        end
    end)
    screen.setBackgroundColor(mbg)
    screen.setTextColor(mfg)
    screen.setCursorPos(4,10)
    screen.write(tostring(selectedCount))
    local x,y = screen.getCursorPos()
    addButton(x,9,3,3,colors.green,colors.gray,"+",function()
        selectedCount = selectedCount + 1
        if selectedCount > kristed.getItemCount(kristed.config.items[selectedItem].id) then
            selectedCount = kristed.getItemCount(kristed.config.items[selectedItem].id)
        end
        if selectedCount < 1 then
            selectedCount = 1
        end
    end)
    -- Render the price(s)
    screen.setBackgroundColor(mbg)
    screen.setTextColor(mfg)
    screen.setCursorPos(1,13)
    screen.write("Price/i: "..kristed.config.items[selectedItem].price.."kst/i")
    screen.setCursorPos(1,14)
    screen.write("Price: "..kristed.config.items[selectedItem].price*selectedCount.."kst")
    -- Render the add cart button
    addButton(1,16,13,3,colors.blue,colors.gray,"Add to cart",function()
        table.insert(cartt, {
            item = selectedItem,
            count = selectedCount,
        })
        selectedItem = nil
    end)
end

function renderCart()
    local items = {}
    local cost = 0
    for k,v in ipairs(cartt) do
        table.insert(items, {
            name = kristed.config.items[v.item].name,
            aviable = v.count,
            price = kristed.config.items[v.item].price*v.count,
            id = k
        })
        cost = cost + (v.count*kristed.config.items[v.item].price)
    end
    renderItems(items, true)

    screen.setBackgroundColor(mbg)
    screen.setTextColor(mfg)
    screen.setCursorPos(w-#("Cost: "..cost.."kst")+1,h-4)
    screen.write("Cost: "..cost.."kst")
    addButton(w-#("Checkout")-1,h-3,10,3,colors.blue,colors.gray,"Checkout",function()
        if #cartt < 1 then
            notify("You must buy something",colors.red,colors.blue)
            return
        end
        local calc = {}
        for k,v in ipairs(cartt) do
            calc[kristed.config.items[v.item].id] = (calc[kristed.config.items[v.item].id] and calc[kristed.config.items[v.item].id] or 0) + v.count
        end
        local canbe = true
        local cbreason = ""
        for k,v in pairs(calc) do
            if kristed.getItemCount(k) < v then
                canbe = false
                cbreason = kristed.getItemById(k).name
                break
            end
        end
        if canbe then
            kristed.checkout.currently = true
            kristed.checkout.price = cost
            kristed.checkout.paid = 0
            kristed.checkout.cart = cartt
            rerender()
        else
            notify("Not enough items: "..cbreason,colors.red,colors.blue)
        end
    end,true)

    addButton(w-#("Checkout")-#("Clear")-4,h-3,7,3,colors.red,colors.gray,"Clear",function()
        cartt = {}
    end)
end

function renderCheckout()
    notify({
        "Waiting for payment to: "..kristed.config.address,
        "Currently paid: "..kristed.checkout.paid.."kst",
        "Remaining: "..(kristed.checkout.price-kristed.checkout.paid).."kst",
        "Total: "..kristed.checkout.price.."kst"
    },colors.blue, colors.gray)
    if (kristed.checkout.price-kristed.checkout.paid) < 0 then
        cart = false
        selectedItem = nil
        selectedCount = 1
        kristed.checkout.currently = false
        kristed.checkout.price = 0
        kristed.checkout.paid = 0
        kristed.checkout.cart = {}
        cartt = {}
        rerender()
    end
end

function rerender()
    screen.setBackgroundColor(mbg)
    screen.clear()
    btns = {}
    if not cart and (selectedItem == nil) then
        renderItemDisplay()
    end
    if not cart and (selectedItem ~= nil) then
        renderItemSelect()
    end
    if cart and not kristed.checkout.currently then
        renderCart()
    end
    if cart and kristed.checkout.currently then
        renderCheckout()
    end
    renderTitle()
end

function frontend()
    screen.setTextScale(kristed.config.scale)
    w,h = screen.getSize()
    rerender()
    function clicker()
        while true do
            local event, side, x, y = os.pullEvent("monitor_touch")
            for k,v in ipairs(btns) do
                if (x >= v.x) and (x <= v.w) and (y >= v.y) and (y <= v.h) then
                    v.onclick()
                    if not v.norefresh then
                        rerender()
                    end
                end
            end
            os.sleep(0.1)
        end
    end
    function pupdate()
        while true do
            os.pullEvent("rerender")
            rerender()
            os.sleep(0.1)
        end
    end
    parallel.waitForAny(clicker,pupdate)
end

return frontend