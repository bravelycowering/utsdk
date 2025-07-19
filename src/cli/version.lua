local luvi = require "luvi"
local MAJOR,MINOR,PATCH = 0,2,0
return {
	utsdk = MAJOR.."."..MINOR.."."..PATCH.."-"..(type(luvi.bundle.stat("main.lua").mtime) == "number" and luvi.bundle.stat("main.lua").mtime or "source"),
	umcli = "none",
	xdelta = "none",
	luvi = luvi.version,
	jit = jit.version_num,
}