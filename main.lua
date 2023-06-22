local kapi = require("kristapi")
local dw = require("discordWebhook")
local frontend = require("modules.frontend")
local backed = require("modules.backend")
local alive = require("modules.alive")
local shopsync = require("modules.shopsync")
local dynamicPricing = require("modules.dynamicPricing")

local cfg = fs.open("config.conf","r")
local config = textutils.unserialise(cfg.readAll())
cfg.close()

local storages = {}
local perps = peripheral.getNames()
for k,v in ipairs(perps) do
    local _, t = peripheral.getType(v)
    if t == "inventory" then
        table.insert(storages, {
            id = v,
            wrap = peripheral.wrap(v)
        })
    end
end

local itemCountCache = {}
function getItemCount(id)
    if itemCountCache[id] then
        local out = itemCountCache[id].count
        if os.clock() > itemCountCache[id].time+10 then
            itemCountCache[id] = nil
        end
        return out
    else
        local co = 0
        for k,v in ipairs(storages) do
            for kk,vv in pairs(v.wrap.list()) do
                if vv.name == id then
                    co = co + vv.count
                end
            end
        end
        itemCountCache[id] = {
            count = co,
            time = os.clock()
        }
        return co
    end
end

if kristed ~= nil then
    kristed.ws.close()
end

_G.kristed = {
    kapi = kapi,
    dw = dw,
    config = config,
    storages = storages,
    version = "0.1.4",
    getItemCount = getItemCount,
    getItemById = function(id)
        for k,v in ipairs(config.items) do
            if v.id == id then
                return v
            end
        end
    end,
    checkout = {
        currently = false,
        price = 0,
        paid = 0,
        cart = {},
        refund = {}
    }
}

function kristed.refundCheckout()
    local function returnKrist(from,returnn,amount,message)
        if returnn then
            kristed.kapi.makeTransaction(kristed.config.privKey, from, amount, returnn..(message ~= nil and ";message="..message or ""))
        else
            kristed.kapi.makeTransaction(kristed.config.privKey, from, amount, (message ~= nil and ";message="..message or ""))
        end
    end
    if kristed.checkout.currently then
        for k,v in ipairs(kristed.checkout.refund) do
            returnKrist(v.address, v["return"], v.value, "Transaction cancelled")
        end
    end
end

print([[
 _  __     _     _           _ ___
| |/ /    (_)   | |         | |__ \
| ' / _ __ _ ___| |_ ___  __| |  ) |
|  < | '__| / __| __/ _ \/ _` | / /
| . \| |  | \__ \ ||  __/ (_| |/ /_
|_|\_\_|  |_|___/\__\___|\__,_|____|
]])

function rawNotify(message,bg,fg)
    local screen = peripheral.find("monitor")
    local w,h = screen.getSize()
    local nw = 52
    local nh = 10
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
end

local errored = false
function onErr(err)
    if errored then
        return
    end
    errored = true
    if err == "Terminated" then
        local screen = peripheral.find("monitor")
        screen.setBackgroundColor(colors.black)
        screen.clear()

        rawNotify({
            kristed.config.shopname,
            "The shop is currently offline"
        }, colors.gray, colors.white)
        print(err)
    
        if kristed.config.webhook == true then
            local emb = kristed.dw.createEmbed()
                :setTitle("The shop went offline")
                :setColor(6579300)
                :setAuthor("Kristed2")
                :setFooter("Kristed2 v"..kristed.version)
                :setTimestamp()
                :setThumbnail("https://github.com/afonya2/kristed2/raw/main/logo.png")
            kristed.dw.sendMessage(kristed.config["webhook_url"], kristed.config.shopname, "https://github.com/afonya2/kristed2/raw/main/logo.png", "", {emb.sendable()}) 
        end
        return
    end
    rawNotify({
        "An error occurred",
        "Please report this to the owner",
        kristed.config.owner,
        "And/or to the github repo",
        "afonya/kristed2",
        "And please specify this error message:",
        err
    }, colors.red, colors.white)
    print(err)

    if kristed.config.webhook == true then
        local emb = kristed.dw.createEmbed()
            :setTitle("An error occurred")
            :setColor(13120050)
            :addField("Please report this to the github repo", "afonya/kristed2")
            :addField("And please specify this error message", "`"..err.."`")
            :setAuthor("Kristed2")
            :setFooter("Kristed2 v"..kristed.version)
            :setTimestamp()
            :setThumbnail("https://github.com/afonya2/kristed2/raw/main/logo.png")
        kristed.dw.sendMessage(kristed.config["webhook_url"], kristed.config.shopname, "https://github.com/afonya2/kristed2/raw/main/logo.png", "", {emb.sendable()}) 
    end
end

parallel.waitForAny(function()
    local ok,err = pcall(dynamicPricing)
    if not ok then
        onErr(err)
    end
end, function()
    local ok,err = pcall(frontend)
    if not ok then
        onErr(err)
    end
end, function()
    local ok,err = pcall(backend)
    if not ok then
        onErr(err)
    end
end, function()
    local ok,err = pcall(alive)
    if not ok then
        onErr(err)
    end
end, function()
    local ok,err = pcall(shopsync)
    if not ok then
        onErr(err)
    end
end)