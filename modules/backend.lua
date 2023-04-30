local sock = nil

function initSocket()
    local socket = kristed.kapi.websocket()
    socket.send(textutils.serialiseJSON({
        type = "subscribe",
        id = 1,
        event = "transactions"
    }))
    kristed.ws = socket
    return function()
        local ok,data = pcall(socket.receive)

        if not ok then
            print("Socket error: "..data)
            socket.close()
            return initSocket()()
        end
        return data
    end
end

function mindTrans(trans)
    return (trans.to == kristed.config.address) and (trans.meta.donate ~= "true")
end

function returnKrist(trans,amount,message)
    if trans.meta["return"] then
        kristed.kapi.makeTransaction(kristed.config.privKey, trans.from, amount, trans.meta["return"]..(message ~= nil and ";message="..message or ""))
    else
        kristed.kapi.makeTransaction(kristed.config.privKey, trans.from, amount, (message ~= nil and ";message="..message or ""))
    end
end

function dropItems(id, amount)
    local remaining = amount
    local function itemDrop(idd, amountt)
        for k,v in ipairs(kristed.storages) do
            for kk,vv in pairs(v.wrap.list()) do
                if vv.name == id then
                    local co = v.wrap.pushItems(kristed.config.selfId, kk, amountt, 1)
                    turtle.drop(amountt)
                    return co
                end
            end
        end
    end
    while remaining > 0 do
        local ca = itemDrop(id, remaining)
        remaining = remaining - ca
    end
end

function sendHook(trans, dist)
    if kristed.config.webhook == true then
        local citems = ""
        for k,v in ipairs(kristed.checkout.cart) do
            citems = citems .. kristed.config.items[v.item].name.." x"..v.count.."("..(v.count*kristed.config.items[v.item].price)..")\n"
        end
        local emb = kristed.dw.createEmbed()
            :setTitle("Purchase info")
            :setColor(3302600)
            :addField("From address", trans.from, true)
            :addField("Value", kristed.checkout.paid.."kst", true)
            :addField("Return address", trans.meta["return"] and trans.meta["return"] or "Address", true)
            :addField("-", "-")
            :addField("Cart", citems, true)
            :addField("Cost", kristed.checkout.price.."kst", true)
            :addField("Change", dist.."kst", true)
            :setAuthor("Kristed")
            :setFooter("Kristed v"..kristed.version)
            :setTimestamp()
            :setThumbnail("https://github.com/afonya2/kristed2/raw/main/logo.png")
        dw.sendMessage(kristed.config["webhook_url"], kristed.config.shopname, "https://github.com/afonya2/kristed2/raw/main/logo.png", "", {emb.sendable()})
    end
end

function backend()
    sock = initSocket()

    function onTrans(json)
        if json.type == "event" and json.event == "transaction" then
            local trans = json.transaction
            trans.meta = kristed.kapi.parseMeta(trans.metadata)
            if mindTrans(trans) then
                if kristed.checkout.currently then
                    -- Check if there is enough items
                    local canbe = true
                    local cbreason = ""
                    for k,v in ipairs(kristed.checkout.cart) do
                        if kristed.getItemCount(kristed.config.items[v.item].id) < v.count then
                            canbe = false
                            cbreason = kristed.config.items[v.item].name
                            break
                        end
                    end

                    if canbe then
                        kristed.checkout.paid = kristed.checkout.paid + trans.value
                        if kristed.checkout.paid == kristed.checkout.price then
                            for k,v in ipairs(kristed.checkout.cart) do
                                dropItems(kristed.config.items[v.item].id, v.count)
                            end
                            sendHook(trans, 0)
                        elseif kristed.checkout.paid > kristed.checkout.price then
                            for k,v in ipairs(kristed.checkout.cart) do
                                dropItems(kristed.config.items[v.item].id, v.count)
                            end
                            local dist = math.floor(kristed.checkout.paid - kristed.checkout.price)
                            if dist >= 1 then
                                returnKrist(trans, dist, "Thank you for your purchase, here is your change!")
                            end
                            sendHook(trans, 0)
                        end
                        os.queueEvent("kristed_rerender")
                    else
                        returnKrist(trans, trans.value, "Not enough items: "..cbreason)
                    end
                else
                    returnKrist(trans, trans.value, "Currently there is no checkout")
                end
            end
        end
    end

    while true do
        local data = sock()
        if not data then
            print("Socket error")
        else
            local ok,json = pcall(textutils.unserialiseJSON, data)
            if not ok then
                print("JSON error: "..json)
            else
                onTrans(json)
            end
        end
    end
end

return backend