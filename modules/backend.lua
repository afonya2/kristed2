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
        if amountt > 64 then
            amountt = 64
        end
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
            :addField("Paid", kristed.checkout.paid.."kst", true)
            :addField("Return address", trans.meta["return"] and trans.meta["return"] or "Address", true)
            :addField("-", "-")
            :addField("Cart", citems, true)
            :addField("Cost", kristed.checkout.price.."kst", true)
            :addField("Change", dist.."kst", true)
            :setAuthor("Kristed2")
            :setFooter("Kristed2 v"..kristed.version)
            :setTimestamp()
            :setThumbnail("https://github.com/afonya2/kristed2/raw/main/logo.png")
        if kristed.checkout.whmsgid == nil then
            local msg = kristed.dw.sendMessage(kristed.config["webhook_url"], kristed.config.shopname, "https://github.com/afonya2/kristed2/raw/main/logo.png", "", {emb.sendable()}) 
            kristed.checkout.whmsgid = msg.id
        else
            kristed.dw.editMessage(kristed.config["webhook_url"], kristed.checkout.whmsgid, "", {emb.sendable()}) 
        end
    end
end

function giveReceipt(dist)
    if kristed.config.giveReceipts == true then
        local printer = peripheral.find("printer")
        if (printer ~= nil) and (printer.getPaperLevel() > 0) and (printer.getInkLevel() > 0) then
            printer.newPage()
            printer.setPageTitle("Shop purchase")

            printer.setCursorPos(1,1)
            printer.write(kristed.config.shopname)
            printer.setCursorPos(1,2)
            printer.write(kristed.config.desc)
            printer.setCursorPos(1,3)
            printer.write("Owner: "..kristed.config.owner)
            printer.setCursorPos(1,4)
            printer.write(" --- RECEIPT --- ")
            for k,v in ipairs(kristed.checkout.cart) do
                printer.setCursorPos(1,4+k)
                printer.write(kristed.config.items[v.item].name.." x"..v.count.."("..(v.count*kristed.config.items[v.item].price)..")")
            end
            printer.setCursorPos(1,4+#kristed.checkout.cart+1)
            printer.write(" --- RECEIPT --- ")
            printer.setCursorPos(1,4+#kristed.checkout.cart+2)
            printer.write("Cost: "..kristed.checkout.price.."kst")
            printer.setCursorPos(1,4+#kristed.checkout.cart+3)
            printer.write("Paid: "..kristed.checkout.paid.."kst")
            printer.setCursorPos(1,4+#kristed.checkout.cart+4)
            printer.write("Change: "..dist.."kst")
            printer.setCursorPos(1,4+#kristed.checkout.cart+6)
            printer.write("Thank you for")
            printer.setCursorPos(1,4+#kristed.checkout.cart+7)
            printer.write("your purchase!")
            
            printer.endPage()
            kristed.storages[1].wrap.pullItems(kristed.config.printerId, 8)
            for k,v in ipairs(kristed.storages[1].wrap.list()) do
                if v.name == "computercraft:printed_page" then
                    kristed.storages[1].wrap.pushItems(kristed.config.selfId, k)
                    turtle.drop()
                    break
                end
            end
        else
            if kristed.config.webhook == true then
                local emb = kristed.dw.createEmbed()
                    :setTitle("Printer issues")
                    :setColor(13120050)
                    :addField("Printer attached?", printer ~= nil and "yes" or "no")
                    :addField("Ink level", printer ~= nil and tostring(printer.getInkLevel()) or "Unknown", true)
                    :addField("Paper level", printer ~= nil and tostring(printer.getPaperLevel()) or "Unknown", true)
                    :addField("Please try:", "Filling your printer or set the giveReceipts in the config to `false`")
                    :setAuthor("Kristed2")
                    :setFooter("Kristed2 v"..kristed.version)
                    :setTimestamp()
                    :setThumbnail("https://github.com/afonya2/kristed2/raw/main/logo.png")
                kristed.dw.sendMessage(kristed.config["webhook_url"], kristed.config.shopname, "https://github.com/afonya2/kristed2/raw/main/logo.png", "", {emb.sendable()})
            end
        end
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
                        table.insert(kristed.checkout.refund, {
                            address = trans.from,
                            ["return"] = trans.meta["return"],
                            value = trans.value
                        })
                        sendHook(trans, math.floor(kristed.checkout.paid - kristed.checkout.price))
                        if kristed.checkout.paid == kristed.checkout.price then
                            for k,v in ipairs(kristed.checkout.cart) do
                                dropItems(kristed.config.items[v.item].id, v.count)
                            end
                            giveReceipt(math.floor(kristed.checkout.paid - kristed.checkout.price))
                            kristed.checkout.whmsgid = nil
                        elseif kristed.checkout.paid > kristed.checkout.price then
                            for k,v in ipairs(kristed.checkout.cart) do
                                dropItems(kristed.config.items[v.item].id, v.count)
                            end
                            giveReceipt(math.floor(kristed.checkout.paid - kristed.checkout.price))
                            local dist = math.floor(kristed.checkout.paid - kristed.checkout.price)
                            if dist >= 1 then
                                returnKrist(trans, dist, "Thank you for your purchase, here is your change!")
                            end
                            kristed.checkout.whmsgid = nil
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