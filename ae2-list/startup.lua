function require(url)
    local response = http.get(url)
    local responseData = response.readAll()
    response.close()

    return loadstring(responseData)()
end

json = require("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua")

function runWebsocketConnection()
    local ws, err = http.websocket("ws://dn42.fionera.de/ws")
    if not ws then
        write(err)
    else
        ws.send(json.encode({cmd = "register", pattern = "/"}))

        while true do
            local msg, err = ws.receive()
            if not msg then
                write("Error in Websocket Connection\n")
                break
            end

            local decodedMsg = json.decode(msg)
            local method = decodedMsg["method"]
            local url = decodedMsg["url"]
            local id = decodedMsg["id"]
            local ip = decodedMsg["ip"]

            write(ip .. " " .. method .. " " .. url .. "\n")

            if url == "/" then
                local response = ""
                local items = controller.listAvailableItems()
                for _, v in pairs(items) do
                    response = response .. v.name .. " " .. v.count .. "\n"
                end

                ws.send(json.encode({cmd= "handle", id = id, response = response}))
            end
        end
    end
end

controller = peripheral.wrap("back")

runWebsocketConnection()

write("End of code... Rebooting in 3 seconds")
os.sleep(1)
write(".")
os.sleep(1)
write(".")
os.sleep(1)
os.reboot()
