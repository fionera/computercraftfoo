WEBHOOK = "https://discordapp.com/api/webhooks/670398991019540501/FJRApzdRzq2Og0fhjKXnGozFea_wBCdWoJ0C6umaICtGwiapNi-MIEDnBm3snN2LtvOU"
function sendWebhookMessage(message)
    local headers = {
        [ "Content-Type" ] = "application/json",
    }

    local payload = json.encode({ username = "Minecraft", content = message })
    local handle, err, err_handle = http.post(WEBHOOK, payload, headers)
    if handle then
        handle.close()
    else
        printError(err)
        if err_handle then
            print(err_handle.readAll())
            err_handle.close()
        end
        return
    end
end
