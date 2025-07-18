local fs = require "lib.fs"
local log = require "lib.log"

local function launch(project)
	if not project.runner then
		local f = log.assert(io.open(fs.path(project.output, ".runner"), "r+b"), "ERROR: Could not find a valid game runner\nPlease add a 'runner' property to project.json")
		project.runner = f:read("*all")
		f:close()
	end
	local code = fs.execute(fs.path(project.output, project.runner), {
		args = {
			"-game",
			fs.path(project.output, "data.win"),
		}
	})
	log.assert(code, "ERROR: Could not find a valid game runner\nPlease check the 'runner' property to project.json")
end

return launch