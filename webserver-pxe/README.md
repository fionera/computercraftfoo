# Minimal Bootscript
```lua
r = http.get("http://dn42.fionera.de/init.lua")
f = fs.open("startup.lua", "w")
f.write(r.readAll())
f.close()
r.close()
```