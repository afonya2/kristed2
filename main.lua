local kapi = require("kristapi")
local frontend = require("modules.frontend")
local alive = require("modules.alive")

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

_G.kristed = {
    kapi = kapi,
    config = config,
    storages = storages,
    version = "0.0.1-TEST",
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
        cart = {}
    }
}

print([[
 _  __     _     _           _ ___
| |/ /    (_)   | |         | |__ \
| ' / _ __ _ ___| |_ ___  __| |  ) |
|  < | '__| / __| __/ _ \/ _` | / /
| . \| |  | \__ \ ||  __/ (_| |/ /_
|_|\_\_|  |_|___/\__\___|\__,_|____|
]])
parallel.waitForAny(frontend, alive)