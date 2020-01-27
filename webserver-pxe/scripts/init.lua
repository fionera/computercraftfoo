local label = os.getComputerLabel()
if not label then
    label = ""
end

local response, err = http.get("http://dn42.fionera.de/startup.lua?label=" .. label)
if not response then
    printError(err)
end
local responseData = response.readAll()
response.close()

code = loadstring(responseData)
local ran, err = pcall( code )
if not ran then
    write(err)
    sleep(10)
    os.reboot()
end
