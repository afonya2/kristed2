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

function backend()
    sock = initSocket()

    function onTrans(json)
        if json.type == "event" and json.event == "transaction" then
            local trans = json.transaction
            trans.meta = kristed.kapi.parseMeta(trans.metadata)
            if mindTrans(trans) then
                if kristed.checkout.currently then
                    kristed.checkout.paid = kristed.checkout.paid + trans.value
                    if kristed.checkout.paid == kristed.checkout.price then
                        -- Make the item dropping thing
                    elseif kristed.checkout.paid > kristed.checkout.price then
                        -- Make the item dropping thing
                        local dist = math.floor(kristed.checkout.paid - kristed.checkout.price)
                        if dist >= 1 then
                            returnKrist(trans, dist, "Thank you for your purchase, here is your change!")
                        end
                    end
                    os.queueEvent("kristed_rerender")
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