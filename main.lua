local kapi = require("modules.kristapi")
local frontend = require("modules.frontend")
local alive = require("alive")

local cfg = fs.open("config.conf","r")
local config = textutils.unserialise(cfg.readAll())
cfg.close()

_G.kristed = {
    kapi = kapi,
    config = config
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