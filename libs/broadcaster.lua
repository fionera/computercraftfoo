local Broadcaster = {}
Broadcaster.__index = Broadcaster

function Broadcaster.new(url)
    local obj = {}
    setmetatable(obj, Broadcaster)
    obj.url = url
    obj.handler = {}
    return obj
end

function Broadcaster:register(channel, handler)
    if self.handler[channel] == nil then
        self.handler[channel] = {}
    end
    table.insert(self.handler[channel], handler)
end

function Broadcaster:send(channel, message)
    if not self.ws then
        return error("websocket is not open")
    end

    self.ws.send(json.encode({ channel = channel, message = message }))
end

function Broadcaster:run()
    local ws, err = http.websocket(self.url)
    if not ws then
        write(err)
    else
        self.ws = ws
        while true do
            local msg, err = ws.receive()
            if not msg then
                write("Error in Websocket Connection: " .. err .. "\n")
                break
            end

            write("got " .. msg)
            local decodedMsg = json.decode(msg)
            local channel = decodedMsg.channel
            local message = decodedMsg.message

            local handler = self.handler[channel]
            if handler then
                for _, f in pairs(self.handler[channel]) do
                    local ran, err = pcall(f, message)
                    if not ran then
                        write(err)
                    end
                    break
                end
            end
        end
    end
end

return Broadcaster