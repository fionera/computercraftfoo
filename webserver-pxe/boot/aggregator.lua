function require(url)
    local response, err = http.get(url)
    if not response then
        write("Error on " .. url)
        printError(err)
    end
    local responseData = response.readAll()
    response.close()

    return loadstring(responseData)()
end

json = require("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua")
prometheus = require("https://raw.githubusercontent.com/tarantool/prometheus/master/prometheus.lua")
Webserver = require("https://raw.githubusercontent.com/fionera/computercraftfoo/master/libs/webserver.lua")
Broadcaster = require("https://raw.githubusercontent.com/fionera/computercraftfoo/master/libs/broadcaster.lua")

function onMetricRequest(message)
    if message.type == "data" then
        metricCache[message.name] = data
    end
end

function onHttpRequest()
    broadcast.send("metrics", {type = "collect"})

    local data = ""
    for _, v in pairs(metricCache) do
        data = data .. v .. "\n"
    end
    metricCache = {}

    return data
end

metricCache = {}
broadcast = Broadcaster("ws://dn42.fionera.de/bc")
broadcast.register("metrics", onMetricRequest)

local webserver = Webserver("ws://dn42.fionera.de/ws")
webserver.register("/metrics", onHttpRequest)

parallel.waitForAny(broadcast.run, webserver.run)

os.reboot()
