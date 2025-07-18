local fs = require "lib.fs"
local log = require "lib.log"

local function create_patch(project)
	local code = fs.execute(fs.path(fs.appdata, "xdelta3-3.1.0-x86_64.exe"), {
		args = {
			"-e",
			"-s",
			fs.path(project.game, project.data),
			fs.path(project.output, "data.win"),
			fs.path(project.output, "patch.xdelta"),
		}
	}, function(err, data, stderr)
		if stderr and data then
			io.write(data)
		end
	end)
	log.assert(code == 0, "Failed to create .xdelta patch")
end

return create_patch