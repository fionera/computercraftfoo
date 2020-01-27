function require(url)
    local response, err = http.get(url)
    if not response then
        printError(err)
    end
    local responseData = response.readAll()
    response.close()

    return loadstring(responseData)()
end

json = require("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua")
prometheus = require("https://raw.githubusercontent.com/tarantool/prometheus/master/prometheus.lua")
Webserver = require("https://raw.githubusercontent.com/fionera/computercraftfoo/master/libs/webserver.lua")

items_available = prometheus.gauge("items_available", "Items available in the AE2 Network", { "item_type" })
function monitor_ae2_items()
    local controller = peripheral.wrap("back")

    while true do
        local items = controller.listAvailableItems()
        for _, v in pairs(items) do
            local itemType = v.name .. "@" .. v.damage
            items_available:set(v.count, { itemType })
        end
        sleep(10)
    end
end



function runBroadcastListener(msg)
    local ws, err = http.websocket("ws://dn42.fionera.de/bc")
    if not ws then
        write(err)
    else
        self.websocket = ws
        while true do
            local msg, err = ws.receive()
            if not msg then
                write("Error in Websocket Connection\n")
                break
            end

            local decodedMsg = json.decode(msg)
            local method = decodedMsg["method"]


            if method == "metrics" then

            end
        end
    end
end

local webserver = Webserver("ws://dn42.fionera.de/ws")
webserver.register("/metrics", prometheus.collect)

parallel.waitForAny(monitor_ae2_items, webserver.run)

os.reboot()
