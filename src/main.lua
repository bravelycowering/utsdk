local luvi = require "luvi"

-- allow require to get bundled lua files 
package.loaders[#package.loaders+1] = function(modname)
	local modpath = modname:gsub("%.+", "/")..".lua"
	local stat = luvi.bundle.stat(modpath)
	if stat and stat.type == "file" then
		return function()
			local f, err = load(luvi.bundle.readfile(modpath), modpath)
			if not f then
				error(err, 2)
			end
			return f()
		end
	end
end

-- parse arguments
require "args"

-- attempt to start in gui mode if the love2d library is present
if #arg == 0 then
	local success, love = xpcall(require, function(err) end, "love")
	if success then
		-- gui mode doesnt exist so this will always throw an error
		-- however the chances if it finding a love2d library via require are slim
		return require "gui.boot"
	end
end

-- run cli tool
return require "cli.main"