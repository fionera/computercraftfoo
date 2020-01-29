function require(url, filename)
    local response, err = http.get(url)
    if not response then
        write("Error on " .. url)
        printError(err)
    end
    local responseData = response.readAll()
    response.close()

    return loadstring(responseData, filename)()
end

json = require("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua", "json.lua")
prometheus = require("https://raw.githubusercontent.com/tarantool/prometheus/master/prometheus.lua", "prometheus.lua")
Broadcaster = require("https://raw.githubusercontent.com/fionera/computercraftfoo/master/libs/broadcaster.lua", "broadcaster.lua")

items_available = prometheus.gauge("items_available", "Items available in the AE2 Network", { "item_type" })
function monitor_ae2_items()
    local controller = peripheral.wrap("bottom")

    while true do
        local items = controller.listAvailableItems()
        for _, v in pairs(items) do
            local itemType = v.name .. "@" .. v.damage
            items_available:set(v.count, { itemType })
        end
        sleep(10)
    end
end

fluids_available = prometheus.gauge("fluids_available", "Fluids available in the AE2 Network", { "fluid_type" })
function monitor_ae2_fluids()
    local controller = peripheral.wrap("bottom")

    while true do
        local items = controller.listAvailableFluids()
        for _, v in pairs(items) do
            fluids_available:set(v.amount, { v.id })
        end
        sleep(10)
    end
end

function onMetricRequest(message)
    if message.type == "collect" then
        broadcast.send("metrics", {type = "data", name = "ae2", data = prometheus.collect})
    end
end

broadcast = Broadcaster("ws://dn42.fionera.de/bc")
broadcast.register("metrics", onMetricRequest)

parallel.waitForAny(monitor_ae2_items, monitor_ae2_fluids, broadcast.run)

os.reboot()