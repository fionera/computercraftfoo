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

fluids_available = prometheus.gauge("fluids_available", "Fluids available in the AE2 Network", { "fluid_type" })
function monitor_ae2_fluids()
    local controller = peripheral.wrap("back")

    while true do
        local items = controller.listAvailableFluids()
        for _, v in pairs(items) do
            fluids_available:set(v.amount, { v.id })
        end
        sleep(10)
    end
end

local webserver = Webserver("ws://dn42.fionera.de/ws")
webserver.register("/metrics/ae2", prometheus.collect)

parallel.waitForAny(monitor_ae2_items, monitor_ae2_fluids, webserver.run)

os.reboot()