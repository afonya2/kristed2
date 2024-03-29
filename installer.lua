print("Welcome to the Kristed2 installer!")

local repo = "afonya2/kristed2"
local branch = "main"
local files = {
    ["modules/alive.lua"] = "modules/alive.lua",
    ["modules/backend.lua"] = "modules/backend.lua",
    ["modules/frontend.lua"] = "modules/frontend.lua",
    ["modules/shopsync.lua"] = "modules/shopsync.lua",
    ["modules/dynamicPricing.lua"] = "modules/dynamicPricing.lua",
    ["config.conf"] = "config.conf",
    ["theme.conf"] = "theme.conf",
    ["kristapi.lua"] = "kristapi.lua",
    ["discordWebhook.lua"] = "discordWebhook.lua",
    ["main.lua"] = "main.lua"
}
print("Scanning for old config files...")
local cfgfiles = {
    "config.conf",
    "theme.conf",
}
local cfgcache = {}
print("Do you want to keep your config files? (y/n)")
local yass = io.read()
if yass == "y" then
    for k,v in ipairs(cfgfiles) do
        if fs.exists(v) then
            local h = fs.open(v, "rb")
            cfgcache[v] = h.readAll()
            h.close()
        end
    end
end
print("Downloading files...")
for k,v in pairs(files) do
    print("Downloading file "..k)
    local url = "https://raw.githubusercontent.com/"..repo.."/"..branch.."/"..k
    local con = http.get({url = url, binary = true})
    local h = fs.open(v, "wb")
    h.write(con.readAll())
    h.close()
    print("done")
end
print("Loading old config files...")
for k,v in pairs(cfgcache) do
    local h = fs.open(k, "wb")
    h.write(v)
    h.close()
end

print("Do you want to configure your shop now? (y/n)")
local yess = io.read()
if yess == "y" then
    print("Enter the name for the shop")
    local shopname = io.read()
    print("Enter the owner's name")
    local owner = io.read()
    print("Enter the description for the shop")
    local desc = io.read()
    print("Enter the redstone emmit way")
    local rds = io.read()
    print("Enter the address of the wallet")
    local address = io.read()
    print("Enter the privateKey for the wallet")
    local privKey = io.read()
    print("Enter the turtle's network id")
    local selfId = io.read()
    print("Enter the monitor's network id")
    local monId = io.read()
    print("Do you want discord webhook enabled? (y/n)")
    local whe = (io.read() == "y") and true or false
    local whu = ""
    if whe then
        print("Enter the webhook's url")
        whu = io.read()
    end
    print("Do you want to give receipts on purchases? (y/n)")
    local gir = (io.read() == "y") and true or false
    local gur = ""
    if gir then
        print("Enter the printers's id, starts with: printer_")
        gur = io.read()
    end
    print("Do you want shopsync enabled? (y/n)")
    local shoppy = (io.read() == "y") and true or false
    print("Do you want dynamic pricing enabled? (y/n)")
    local dp = (io.read() == "y") and true or false

    print("Configuring...")
    local confi = {
        shopname = shopname,
        scale = 0.5,
        owner = owner,
        desc = desc,
        redstone = rds,
        address = address,
        privKey = privKey,
        selfId = selfId,
        monitorId = monId,
        webhook = whe,
        ["webhook_url"] = whu,
        giveReceipts = gir,
        printerId = gur,
        shopsync = shoppy,
        dynamicPricing = dp,
        categories = {
            {
                name = "Items",
                forcePrice = false
            }
        },
        items = {
            {
                name = "Test",
                id = "minecraft:redstone",
                price = 1,
                category = 1,
                normalStock = 10,
                forcePrice = false
            }
        }
    }
    local cof = fs.open("config.conf", "w")
    cof.write(textutils.serialise(confi))
    cof.close()

    print("You still have to configure the items and categories!")
end

print("Done")
print("To add other configuration edit the config.conf file")
print("To start the shop on startup, rename the main.lua to startup.lua")