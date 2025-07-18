local luvi = require "luvi"
local fs = require "lib.fs"
local log = require "lib.log"
local json = require "lib.json"

local function forceremove(dir) -- todo: replace this function
	local uv = require "uv"
	local success, err, d
	success, err = uv.fs_rmdir(dir)
	if success then
		return success, err
	end
	d, err = uv.fs_opendir(dir)
	if not d then return d, err end
	local entries = {}
	repeat
		success, err = uv.fs_readdir(d)
		if success then
			for i = 1, #success do
				local entry = success[i]
				if entry.type == "file" then
					os.remove(fs.path(dir, entry.name))
				elseif entry.type == "directory" then
					forceremove(fs.path(dir, entry.name))
				end
			end
		end
	until not success
	uv.fs_closedir(d)
	uv.fs_rmdir(dir)
	return true, ""
end

local function create_csx(project)
	local scripts = {
		"csx/using.csx",
		"",
		"csx/gml.csx",
		"csx/sprites.csx",
		"csx/sounds.csx",
		"csx/build.csx",
	}
	local c = {}
	for i = 1, #scripts do
		if scripts[i] == "" then
			local statics = {}
			local strings = {"Name", "DisplayName"}
			for i = 1, #strings do
				local k, v = strings[i], project.GeneralInfo[strings[i]]
				if v ~= nil then
					log.assert(type(v) == "string", "ERROR: Incorrectly formatted project.json\n\"GeneralInfo."..k.."\" must be a string value")
					statics[#statics+1] = "static string GeneralInfo_"..k.." = "..json.stringify(v)..";"
				else
					statics[#statics+1] = "static string GeneralInfo_"..k..";"
				end
			end
			c[#c+1] = '#line 1 "STATICS"\n'..table.concat(statics, "\n").."\n"
		else
			local content = luvi.bundle.readfile(scripts[i])
			c[#c+1] = '#line 1 "'..scripts[i]..'"\n'..content.."\n"
		end
	end
	return table.concat(c)
end

local function build(project)
	local success, err = forceremove(project.output)
	log.assert(success or err:starts("ENOENT"), "ERROR: Could not remove directory "..project.output.."\n"..tostring(err))

	success, err = fs.mkdir(project.output)
	log.assert(success, "ERROR: Could not create directory "..project.output.."\n"..tostring(err))

	for k, v in pairs(project.copy) do
		local from, to = fs.path(project.game, v), fs.path(project.output, k)
		success, err = fs.copyfile(from, to)
		log.assert(success, "ERROR: Could not copy file "..from.." to "..to.."\n"..tostring(err))
	end

	for k, v in pairs(project.juncture) do
		local from, to = fs.path(project.game, v), fs.path(project.output, k)
		success, err = fs.junction(from, to)
		log.assert(success, "ERROR: Could not create juncture from "..from.." to "..to.."\n"..tostring(err))
	end

	local umtlogger
	if flags.verbose then
		umtlogger = function(err, data)
			if data then
				if data:starts("%RUNNER:") and not project.runner then
					local runner = data:gsub("^%%RUNNER:",""):gsub("\r?\n", "")..".exe"
					project.runner = fs.path(project.game, runner)
					fs.write(fs.path(project.output, ".runner"), project.runner)
				end
				io.write(data)
			end
		end
	else
		local shouldclear = false
		umtlogger = function(err, data)
			if data then
				if data:starts("%RUNNER:") and not project.runner then
					local runner = data:gsub("^%%RUNNER:",""):gsub("\r?\n", "")..".exe"
					project.runner = fs.path(project.game, runner)
					fs.write(fs.path(project.output, ".runner"), project.runner)
				end
				if data:starts("[") then
					shouldclear = true
					io.write("\x1b[s\x1b[2K"..data:gsub("\n", "").."\x1b[u")
				elseif
					not data:starts("%RUNNER:") and
					not data:starts("Trying to load file: ") and
					not data:starts("Attempting to execute ") and
					not data:starts("Finished executing ") and
					not data:starts("Saving new data file to ")
				then
					if shouldclear then
						io.write("\x1b[2K")
						shouldclear = false
					end
					io.write(data)
				end
			end
		end
	end
	fs.write(fs.path(fs.appdata, ".csx"), create_csx(project))
	local code = fs.execute(fs.path(fs.appdata, "UndertaleModCli/UndertaleModCli.exe"), {
		args = {
			"load",
			fs.path(project.game, project.data),
			"-v",
			"-s",
			fs.path(fs.appdata, ".csx"),
			"-l",
			"if (Environment.GetEnvironmentVariable(\"do_save\") == null) { Environment.Exit(1); }",
			"-o",
			fs.path(project.output, "data.win"),
		},
		env = {
			"SOURCE="..project.source
		}
	}, umtlogger)
	os.remove(fs.path(fs.appdata, ".csx"))
	log.assert(code == 0, "Build failed, aborting...")
end

return build