ws = nil
function runWebsocketConnection()
    err = nil
    ws, err = http.websocket("ws://dn42.fionera.de/ws")
    if not ws then
        write(err)
    else
        while true do
            local msg, err = ws.receive()
            if not msg then
                write(err)
                break
            end

            write(msg)
        end
    end
end

function runReadLine()
    while true do
        local input = read()
        ws.send(input)
    end
end

parallel.waitForAny(runWebsocketConnection, runReadLine)

write("End of code... Rebooting in 3 seconds")
os.sleep(1)
write(".")
os.sleep(1)
write(".")
os.sleep(1)
os.reboot()
