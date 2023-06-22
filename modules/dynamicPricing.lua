local mainPrices = {}

function dynamicPricing()
    for k,v in ipairs(kristed.config.items) do
        mainPrices[k] = v.price
    end
    while true do
        if kristed.config.dynamicPricing then
            for k,v in ipairs(kristed.config.items) do
                local ic = v.normalStock / kristed.getItemCount(v.id)
                local np = mainPrices[k] * ic
                np = math.floor(np*100)/100
                if np == 0 then
                    np = mainPrices[k]
                end
                kristed.config.items[k].price = np
            end
        end
        os.sleep(0)
    end
end

return dynamicPricing