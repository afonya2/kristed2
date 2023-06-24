local mainPrices = {}

function dynamicPricing()
    for k,v in ipairs(kristed.config.items) do
        mainPrices[k] = v.price
    end
    while true do
        if kristed.config.dynamicPricing then
            for k,v in ipairs(kristed.config.items) do
                local icc = kristed.getItemCount(v.id)
                local catt = kristed.config.categories[v.category]
                if (icc > 0) and (not v.forcePrice) and (not catt.forcePrice) then
                    local ic = v.normalStock / icc
                    local np = mainPrices[k] * ic
                    np = math.floor(np*100)/100
                    if np == 0 then
                        np = mainPrices[k]
                    end
                    kristed.config.items[k].price = np
                else
                    kristed.config.items[k].price = mainPrices[k]
                end
            end
        end
        os.sleep(0)
    end
end

return dynamicPricing