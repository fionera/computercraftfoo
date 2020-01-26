function runWebsocketConnection()
    local ws, err = http.websocket("ws://dn42.fionera.de/ws")
    if not ws then
        write(err)
    else
        ws.send(json.encode({cmd = "register", pattern = "/"}))

        while true do
            local msg, err = ws.receive()
            if not msg then
                write(err)
                break
            end

            msg = json.decode(msg)
            local method = msg["method"]
            local url = msg["url"]
            local id = msg["id"]
            local ip = msg["ip"]

            write(ip .. " " .. method .. " " .. url .. " \n")

            if url == "/" then
                ws.send(json.encode({cmd= "handle", id = id, response = "<h1>Hello World</h1>"}))
            end
        end
    end
end