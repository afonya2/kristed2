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
end

function renderItems(items)
    local x = 1
    local y = 3
    for k,v in ipairs(items) do
        addItem(x,y,v)
        x = x + iw+1
        if x+iw >= w then
            x = 1
            y = y + ih+1
        end
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

function frontend()
    screen.setTextScale(kristed.config.scale)
    w,h = screen.getSize()
    screen.setBackgroundColor(mbg)
    screen.clear()
    renderItems({
        {
            name = "Test",
            aviable = 10,
            price = 10
        },
        {
            name = "Test2",
            aviable = 2,
            price = 3
        },
        {
            name = "Test3",
            aviable = 10,
            price = 10
        },
        {
            name = "Test4",
            aviable = 2,
            price = 3
        },
        {
            name = "Test5",
            aviable = 10,
            price = 10
        },
        {
            name = "Test6",
            aviable = 2,
            price = 3
        }
    })
    renderTitle()
    while true do
        os.sleep(0.1)
    end
end

return frontend