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

_G.kristed = {
    kapi = kapi,
    config = config,
    storages = storages,
    version = "0.0.1-TEST"
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