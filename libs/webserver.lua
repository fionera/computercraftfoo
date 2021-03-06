local Webserver = {}
Webserver.__index = Webserver

function Webserver.new(url)
    local obj = {}
    setmetatable(obj, Webserver)
    obj.url = url
    obj.handler = {}
    return obj
end

function Webserver:register(pattern, handler)
    self.handler[pattern] = handler
end

function Webserver:handle(pattern)
    return self.handler[pattern]()
end

local function splitByChunk(text, chunkSize)
    local s = {}
    for i = 1, #text, chunkSize do
        s[#s + 1] = text:sub(i, i + chunkSize - 1)
    end
    return s
end

function Webserver:run()
    local ws, err = http.websocket(self.url)
    if not ws then
        write(err)
    else
        for pattern, _ in pairs(self.handler) do
            write("Registering " .. pattern .. "\n")
            ws.send(json.encode({ cmd = "register", pattern = pattern }))
        end

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

            for pattern, func in pairs(self.handler) do
                if pattern == url then
                    local ok, response = pcall(func, decodedMsg)
                    if not ok then
                        printError(err)
                    end

                    maxMessageSize = 60 * 1024
                    if string.len(response) > maxMessageSize then
                        local st = splitByChunk(response, maxMessageSize)
                        for i, v in ipairs(st) do
                            ws.send(json.encode({ cmd = "chunk", id = id, response = v }))
                        end

                        ws.send(json.encode({ cmd = "handle", id = id }))
                    end

                    break
                end
            end
        end
    end
end

return Webserver