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

energy_stored = prometheus.gauge("energy_stored", "Energy stored in the Core")
max_energy_stored = prometheus.gauge("max_energy_stored", "Max Energy stored in the Core")
transfer_per_tick = prometheus.gauge("transfer_per_tick", "Transfer per Tick into/out from the Core")
function monitor_power_core()
    local pylon = peripheral.wrap("right")

    while true do
        energy_stored:set(pylon.getEnergyStored())
        max_energy_stored:set(pylon.getMaxEnergyStored())
        transfer_per_tick:set(pylon.getTransferPerTick())
        sleep(5)
    end
end

local webserver = Webserver("ws://dn42.fionera.de/ws")
webserver.register("/metrics/de", prometheus.collect)

parallel.waitForAny(monitor_power_core, webserver.run)

os.reboot()