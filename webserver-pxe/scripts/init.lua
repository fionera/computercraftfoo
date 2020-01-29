function getComputerLabel()
    local label = os.getComputerLabel()
    if not label then
        label = ""
    end

    return label
end

local response, err = http.get("http://dn42.fionera.de/startup.lua?label=" .. getComputerLabel())
if not response then
    printError(err)
end
local responseData = response.readAll()
response.close()

local code = loadstring(responseData)
local ok, err = pcall(code)
if not ok then
    write(err)
    sleep(10)
    os.reboot()
end
