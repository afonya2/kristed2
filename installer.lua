print("Welcome to the Kristed2 installer!")

local repo = "afonya2/kristed2"
local branch = "main"
local files = {
    ["modules/alive.lua"] = "modules/alive.lua",
    ["modules/backend.lua"] = "modules/backend.lua",
    ["modules/frontend.lua"] = "modules/frontend.lua",
    ["config.conf"] = "config.conf",
    ["kristapi.lua"] = "kristapi.lua",
    ["main.lua"] = "main.lua"
}
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
        items = {
            {
                name = "Test",
                id = "minecraft:redstone",
                price = 1
            }
        }
    }
    local cof = fs.open("config.conf", "w")
    cof.write(textutils.serialise(confi))
    cof.close()

    print("You still have to configure the items!")
end

print("Done")
print("To add other configuration edit the config.conf file")
print("To start the shop on startup, rename the main.lua to startup.lua")