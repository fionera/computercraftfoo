function eval(code)
    return loadstring(code)()
end

function pEval(code)
    return pcall(eval, code)
end

function require(url)
    local response = http.get(url)
    local responseData = response.readAll()
    response.close()

    return loadstring(responseData)()
end

json = require("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua")

SIDES = { "front", "back", "left", "right", "top", "bottom" }

function detectHardware()
    for _, v in pairs(SIDES) do
        if peripheral.isPresent(v) then
            write("Found something on: " .. v .. "\n")
            local type = peripheral.getType(v)
            write("Type of Device is: " .. type .. "\n")
            initHardware(v, type)
        end
    end
end
