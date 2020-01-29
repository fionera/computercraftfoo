Broadcaster = {}
function Broadcaster.__init__ (baseClass, url)
    self = { url = url, handler = {} }
    setmetatable(self, { __index = Broadcaster })
    return self
end
setmetatable(Broadcaster, { __call = Broadcaster.__init__ })

function Broadcaster.register(channel, handler)
    if not self.handler[channel] then
        self.handler[channel] = {}
    end
    table.insert(self.handler[channel], handler)
end

function Broadcaster.send(channel, message)
    if not ws then
        return error("websocket is not open")
    end

    ws.send(json.encode({ channel = channel, message = message }))
end

function Broadcaster.run()
    local ws, err = http.websocket(self.url)
    if not ws then
        write(err)
    else
        while true do
            local msg, err = ws.receive()
            if not msg then
                write("Error in Websocket Connection: " .. err .. "\n")
                break
            end

            local decodedMsg = json.decode(msg)
            local channel = decodedMsg.channel
            local message = decodedMsg.message

            local handler = self.handler[channel]
            if not handler then
                return
            end

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

return Broadcaster