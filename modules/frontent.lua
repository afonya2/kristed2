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

local cart = false
local selectedItem = nil

local btns = {}

function addButton(x,y,bw,bh,bg,fg,text,onclick)
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
    screen.write(("Stock "..data.aviable):sub(1,iw))

    screen.setCursorPos(x,y+2)
    screen.write(("Price "..data.price):sub(1,iw))

    table.insert(btns, {
        x = x,
        y = y,
        w = x+iw-1,
        h = y+ih-1,
        onclick = function()
            selectedItem = data.id
        end
    })
end

function renderItems(items)
    local x = 1
    local y = 3
    local id = 1
    for k,v in ipairs(items) do
        v.id = id
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
    screen.setCursorPos(w-#("Cart")+1,2)
    screen.setBackgroundColor(cart and mbg or tbg)
    screen.setTextColor(cart and mfg or tfg)
    screen.write("Cart")

    -- Add the items to the top right corner
    screen.setCursorPos(w-#("Cart")-#("Items"),2)
    screen.setBackgroundColor(not cart and mbg or tbg)
    screen.setTextColor(not cart and mfg or tfg)
    screen.write("Items")
end

function renderItemDisplay()
    local items = {}
    for k,v in ipairs(kristed.config.items) do
        table.insert(items, {
            name = v.name,
            aviable = kristed.getItemCount(v.id),
            price = v.price
        })
    end
    renderItems(items)
end

function renderItemSelect()
    addButton(1,4,6,3,colors.red,colors.gray,"Back")
    addButton()
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
                    rerender()
                end
            end
        end
    end
    parallel.waitForAny(clicker)
end

return frontend