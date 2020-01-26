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

loadstring(responseData)()