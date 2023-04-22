local api = {}
local server = "https://krist.dev"

function api.getAddress(address)
    local requ = http.get(server.."/addresses/"..address)
    local out = textutils.unserialiseJSON(requ.readAll())
    if out.ok then
        return out.address
    else
        error(out.message)
    end
end

function api.getBalance(address)
    local requ = http.get(server.."/addresses/"..address)
    local out = textutils.unserialiseJSON(requ.readAll())
    if out.ok then
        return out.address.balance
    else
        error(out.message)
    end
end

function api.getTransactions(address)
    local requ = http.get(server.."/addresses/"..address.."/transactions")
    local out = textutils.unserialiseJSON(requ.readAll())
    if out.ok then
        return out.transactions
    else
        error(out.message)
    end
end

function api.makeTransaction(privKey, to, amount, meta)
    if meta == nil then
        meta = ""
    end
    local kutyus = {
        privatekey = privKey,
        to = to,
        amount = amount,
        meta = meta
    }
    local requ = http.post(server.."/transactions", textutils.serialiseJSON(kutyus), {["Content-Type"] = "application/json"})
    local out = textutils.unserialiseJSON(requ.readAll())
    if out.ok then
        return true
    else
        error(out.message)
    end
end

function api.websocket()
    local requ = http.post(server.."/ws/start")
    local out = textutils.unserialiseJSON(requ.readAll())
    if out.ok then
        local sock = http.websocket(out.url)
        return sock
    else
        error(out.message)
    end
end

return api