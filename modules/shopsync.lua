local modem = peripheral.find("modem")
local PORT = 9773
local TIME = 30

function shopsync()
    while true do
        if kristed.config.shopsync then
            local items = {}
            for k,v in ipairs(kristed.config.items) do
                local stock = kristed.getItemCount(v.id)
                table.insert(items, {
                    prices = {
                        {
                            value = v.price,
                            currency = "KST",
                            address = kristed.config.address
                        }
                    },
                    item = {
                        name = v.id,
                        displayName = v.name
                    },
                    stock = stock,
                    requiresInteraction = true
                })
            end
            local sendData = {
                type = "ShopSync",
                info = {
                    name = kristed.config.shopname,
                    description = kristed.config.desc,
                    owner = kristed.config.owner,
                    software = {
                        name = "Kristed2",
                        version = kristed.version
                    }
                },
                items = items
            }
            modem.transmit(PORT, os.getComputerID(), sendData)
        end
        os.sleep(TIME)
    end
end

return shopsync