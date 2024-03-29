local screen = peripheral.find("monitor")
local w,h = 0,0

local mbg = colors.lightGray
local mfg = colors.gray
local tbg = colors.red
local tfg = colors.lightGray
local ibg = colors.gray
local ifg = colors.lightGray
local diw = 16
local iw = 16
local ih = 3
local nw = 42
local nh = 7
local webhookbuffer = {}
webhookbuffer.CheckOutCancel = {msg={},time=os.clock(),times=0}

if fs.exists("theme.conf") then
    local them = fs.open("theme.conf","r")
    local themd = textutils.unserialise(them.readAll())
    them.close()

    mbg = themd.mainBg
    mfg = themd.mainFg
    tbg = themd.titleBg
    fbg = themd.titleFg
    ibg = themd.itemBg
    ifg = themd.itemFg

    diw = themd.itemWidth
    iw = themd.itemWidth
    ih = themd.itemHeight
    nw = themd.notificationWidth
    nh = themd.notificationHeight
end

local cart = false
local selectedItem = nil
local selectedCount = 1
local selectedCategory = 1
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

function notify(message,bg,fg,onclick)
    if onclick == nil then
        onclick = function() end
    end
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
        onclick = onclick,
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
    screen.write(("Price "..data.price.."kst"):sub(1,iw))

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
    local y = 4
    local id = 1
    local longest = 0
    local function longg(str)
        if #str > longest then
            longest = #str
        end
    end
    for k,v in ipairs(items) do
        if cart or (v.category == selectedCategory) then
            longg(v.name)
            longg("Stock "..v.aviable)
            longg("Price "..v.price.."kst")
        end
    end
    if longest < diw then
        longest = diw
    end
    iw = longest
    for k,v in ipairs(items) do
        if cart or (v.category == selectedCategory) then
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
end

function renderCats()
    local x = w-#("Cart")+1
    for k,v in ipairs(kristed.config.categories) do
        x = x-#v.name-1
        local bool = (selectedCategory == k) and not cart
        addButton(x,3,#v.name,1, bool and mbg or tbg,bool and mfg or tfg,v.name,function()
            cart = false
            selectedItem = nil
            selectedCount = 1
            selectedCategory = k
            kristed.checkout.currently = false
            kristed.checkout.price = 0
            kristed.checkout.paid = 0
            kristed.checkout.cart = {}
            kristed.checkout.refund = {}
            kristed.checkout.whmsgid = nil
        end)
    end
end

function renderTitle()
    -- Set the first three lines colored
    screen.setBackgroundColor(tbg)
    screen.setCursorPos(1,1)
    screen.clearLine()
    screen.setCursorPos(1,2)
    screen.clearLine()
    screen.setCursorPos(1,3)
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
    -- Add the shop owner label to the bottom left corner
    screen.setCursorPos(w-#("Shop owned by: "..kristed.config.owner)+1,h)
    screen.setBackgroundColor(mbg)
    screen.setTextColor(mfg)
    screen.write("Shop owned by: "..kristed.config.owner)

    -- Add the cart to the top right corner
    addButton(w-#("Cart")+1,3,4,1,cart and mbg or tbg,cart and mfg or tfg,"Cart",function()
        cart = true
        selectedItem = nil
        selectedCount = 1
        kristed.checkout.currently = false
        kristed.checkout.price = 0
        kristed.checkout.paid = 0
        kristed.checkout.cart = {}
        kristed.checkout.refund = {}
        kristed.checkout.whmsgid = nil
    end)

    -- Add the items to the top right corner
    --[[addButton(w-#("Cart")-#("Items"),3,5,1,not cart and mbg or tbg,not cart and mfg or tfg,"Items",function()
        cart = false
        selectedItem = nil
        selectedCount = 1
        kristed.checkout.currently = false
        kristed.checkout.price = 0
        kristed.checkout.paid = 0
        kristed.checkout.cart = {}
        kristed.checkout.refund = {}
        kristed.checkout.whmsgid = nil
    end)]]
    -- Add the categories
    renderCats()
end

function renderItemDisplay()
    local items = {}
    for k,v in ipairs(kristed.config.items) do
        table.insert(items, {
            name = v.name,
            aviable = kristed.getItemCount(v.id),
            price = v.price,
            category = v.category,
            id = k
        })
    end
    renderItems(items)

    addButton(w-#("Refresh")-1,h-3,10,3,colors.blue,colors.gray,"Refresh",function() end)
end

function renderItemSelect()
    local function writeToCenter(text, y)
        local w,h = screen.getSize()
        screen.setCursorPos(math.floor(w/2-#text/2)+1,y)
        screen.write(text)
    end
    -- Render the back button and the item name
    local w, h = screen.getSize()
    addButton(w-6,h-4,6,3,colors.red,colors.gray,"Back",function()
        selectedItem = nil
    end)
    screen.setBackgroundColor(mbg)
    screen.setTextColor(mfg)
    writeToCenter("Item: "..kristed.config.items[selectedItem].name, 9)
    -- Render the count thing
    writeToCenter(tostring(selectedCount), 11)
    addButton(math.floor((w)/2)-4,10,3,3,colors.red,colors.gray,"-",function()
        selectedCount = selectedCount - math.min(1,selectedCount-1)
    end)
    addButton(math.floor((w)/2)-10,10,5,3,colors.red,colors.gray,"-10",function()
        selectedCount = selectedCount - math.min(10,selectedCount-1)
    end)
    addButton(math.floor((w)/2)-16,10,5,3,colors.red,colors.gray,"-64",function()
        selectedCount = selectedCount - math.min(64,selectedCount-1)
    end)

    addButton(math.floor((w)/2)+4,10,3,3,colors.green,colors.gray,"+",function()
        selectedCount = selectedCount + math.min(1,kristed.getItemCount(kristed.config.items[selectedItem].id)-selectedCount)
    end)
    addButton(math.floor((w)/2)+8,10,5,3,colors.green,colors.gray,"+10",function()
        selectedCount = selectedCount + math.min(10,kristed.getItemCount(kristed.config.items[selectedItem].id)-selectedCount)
    end)
    addButton(math.floor((w)/2)+14,10,5,3,colors.green,colors.gray,"+64",function()
        selectedCount = selectedCount + math.min(64,kristed.getItemCount(kristed.config.items[selectedItem].id)-selectedCount)
    end)
    -- Render the price(s)
    screen.setBackgroundColor(mbg)
    screen.setTextColor(mfg)
    writeToCenter("Price/i: "..kristed.config.items[selectedItem].price.."kst/i", 14)
    writeToCenter("Price: "..kristed.config.items[selectedItem].price*selectedCount.."kst", 15)
    -- Render the add cart button
    addButton(math.floor((w-11)/2),17,13,3,colors.blue,colors.gray,"Add to cart",function()
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
            kristed.checkout.refund = {}
            kristed.checkout.whmsgid = nil
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
        "Total: "..kristed.checkout.price.."kst",
        "Click to cancel"
    },colors.blue, colors.gray, function()
        kristed.refundCheckout()
        kristed.checkout.currently = false
        kristed.checkout.price = 0
        kristed.checkout.paid = 0
        kristed.checkout.cart = {}
        kristed.checkout.refund = {}
        kristed.checkout.whmsgid = nil
        if kristed.config.webhook == true and webhookbuffer.CheckOutCancel.times ~= 0 and (os.clock() - webhookbuffer.CheckOutCancel.time) < 60 then
            local emb = kristed.dw.createEmbed()
                :setTitle("Checkout cancelled x"..webhookbuffer.CheckOutCancel.times+1)
                :setColor(6579300)
                :setAuthor("Kristed2")
                :setFooter("Kristed2 v"..kristed.version)
                :setTimestamp()
                :setThumbnail("https://github.com/afonya2/kristed2/raw/main/logo.png")
            kristed.dw.editMessage(kristed.config["webhook_url"],webhookbuffer.CheckOutCancel.msg.id,"",{emb.sendable()})
            webhookbuffer.CheckOutCancel = {msg=webhookbuffer.CheckOutCancel.msg,time=os.clock(),times=webhookbuffer.CheckOutCancel.times+1}
        elseif kristed.config.webhook == true then
            local emb = kristed.dw.createEmbed()
                :setTitle("Checkout cancelled")
                :setColor(6579300)
                :setAuthor("Kristed2")
                :setFooter("Kristed2 v"..kristed.version)
                :setTimestamp()
                :setThumbnail("https://github.com/afonya2/kristed2/raw/main/logo.png")
            local msg = kristed.dw.sendMessage(kristed.config["webhook_url"], kristed.config.shopname, "https://github.com/afonya2/kristed2/raw/main/logo.png", "", {emb.sendable()})
            webhookbuffer.CheckOutCancel = {msg=msg,time=os.clock(),times=1}
        end
    end)
    if (kristed.checkout.price-kristed.checkout.paid) <= 0 then
        cart = false
        selectedItem = nil
        selectedCount = 1
        selectedCategory = 1
        kristed.checkout.currently = false
        kristed.checkout.price = 0
        kristed.checkout.paid = 0
        kristed.checkout.cart = {}
        kristed.checkout.refund = {}
        kristed.checkout.whmsgid = nil
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
            local event, side, x, y
            repeat
                event, side, x, y = os.pullEvent("monitor_touch")
            until side == kristed.config.monitorId
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
            os.pullEvent("kristed_rerender")
            rerender()
            os.sleep(0.1)
        end
    end
    parallel.waitForAny(clicker,pupdate)
end

return frontend
