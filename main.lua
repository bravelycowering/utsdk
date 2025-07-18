local luvi = require "luvi"

-- require fixer
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

local uv = require "uv"
local json = require "json"

local MAJOR, MINOR, PATCH = 0,1,0

local project
local argi, noflags, flags = 1, true, {
	help = false,
	build = false,
	launch = false,
	verbose = false,
	version = false,
}

local function exit(code, msg)
	if msg then
		print("\x1b[31m"..msg.."\x1b[0m")
	end
	if code ~= nil then
		os.exit(code)
	end
end

local function assert(v, message)
	if not v then
		exit(1, message or "Assertion failed")
	end
	return v
end

local function readfile(p)
	local contents
	local f = io.open(p, "r")
	if not f then
		return nil, "Could not open file "..p
	end
	contents = f:read("*all")
	f:close()
	return contents
end

local function mkdir(dir)
	local result, err = uv.fs_mkdir(dir, 0)
	if err and err:starts("EEXIST") then
		result, err = true, ""
	end
	return result, err
end

function string.starts(str, start)
	return string.sub(str, 1, string.len(start)) == start
end

local function path(...)
	local paths = {...}
	local t = {}
	for i = 1, #paths do
		local p = paths[i]:gsub("%%[^%%]+%%", function(m)
			return os.getenv(m)
		end)
		for m in p:gmatch("[^%/%\\]+") do
			if m == ".." then
				t[#t] = nil
			elseif m:byte(2, 2) == string.byte(":", 1, 1) then
				t = {m}
			elseif m ~= "." then
				t[#t+1] = m
			end
		end
	end
	return table.concat(t, "/")
end

local function forceremove(dir)
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
					os.remove(path(dir, entry.name))
				elseif entry.type == "directory" then
					forceremove(path(dir, entry.name))
				end
			end
		end
	until not success
	uv.fs_closedir(d)
	uv.fs_rmdir(dir)
	return true, ""
end

local function execute(exe, options, l, ignorenotfound)
	if not ignorenotfound and not (uv.fs_stat(exe) or uv.fs_stat(exe..".exe")) then
		exit(1, "INTERNAL ERROR: EXE NOT FOUND\n"..exe.."\n\nplease report this to bravelycowering")
	end
	local stdin = uv.new_pipe()
	local stdout = uv.new_pipe()
	local stderr = uv.new_pipe()

	l = l or function(err, data) if data then io.write(data) end end

	options.stdio = {stdin, stdout, stderr}

	local c, s = 0, 0

	local handle, pid = uv.spawn(exe, options, function(code, signal) -- on exit
		c, s = code, signal
	end)

	uv.read_start(stdout, function(err, data) return l(err, data, false) end)
	uv.read_start(stderr, function(err, data) return l(err, data, true) end)

	uv.run()

	return c, s
end

local function confirm(question)
	local yes = false
	local stdin = uv.new_tty(0, true)
	uv.tty_set_mode(stdin, "raw")
	io.write(question.." (Y/N) ")
	stdin:read_start(function(err, data)
		if data:lower() == "y" then
			print(data:upper())
			yes = true
			uv.tty_set_mode(stdin, "normal")
			stdin:close()
		elseif data:lower() == "n" then
			print(data:upper())
			uv.tty_set_mode(stdin, "normal")
			stdin:close()
		elseif data:byte(1) == 3 then
			os.exit(0)
		end
	end)
	uv.run()
	return yes
end

local bin = ".bin"

local exename = uv.exepath():gsub("^.+[%/%\\]", ""):gsub("%.[^%.]+$", "")
local appdata = path(os.getenv("appdata"), "UndertaleModdingSDK")

local umcli_version = "none"

local function dependancies()
	local xdelta3_missing = true
	local umcli_missing = true
	local umcli_wanted_version = "1.0.0+473b731a8d16b75ac889972466470dc05d9c90ed"
	if uv.fs_stat(appdata) then
		if uv.fs_stat(path(appdata, "UndertaleModCli")) and uv.fs_stat(path(appdata, "UndertaleModCli/UndertaleModCli.exe")) then
			umcli_missing = false
			execute(path(appdata, "UndertaleModCli/UndertaleModCli.exe"), { args = { "--version" } }, function(err, data)
				if not data then return end
				local v = data:gsub("%s+", "")
				if #v > 0 then
					umcli_version = v
				end
			end)
			if umcli_version ~= umcli_wanted_version then
				umcli_missing = true
			end
		else
			umcli_missing = true
		end
		xdelta3_missing = not uv.fs_stat(path(appdata, "xdelta3-3.1.0-x86_64.exe"))
	else
		mkdir(appdata)
	end
	if umcli_missing or xdelta3_missing then
		if umcli_version == "none" or xdelta3_missing then
			print("\n"..exename.." is missing the following binaries and needs them to function properly\n")
		else
			print("There is an update available for the following binaries")
		end
		if umcli_missing then
			print("    UndertaleModCli (https://github.com/UnderminersTeam/UndertaleModTool/)")
		end
		if xdelta3_missing then
			print("    xdelta3 (https://github.com/jmacd/xdelta-gpl)")
		end
		if confirm("\nWould you like to download them now?") then
			if umcli_missing then
				print("Downloading UndertaleModCli...")
				execute("curl", {
					args = {
						"https://github.com/UnderminersTeam/UndertaleModTool/releases/download/0.8.2.0/UTMT_CLI_v0.8.2.0-Windows.zip",
						"-o", path(appdata, "UndertaleModCli.zip"), "-f", "-L"
					}
				}, nil, true)
				print("Unzipping UndertaleModCli...")
				mkdir(path(appdata, "UndertaleModCli"))
				execute("tar", {
					args = {
						"-xf", path(appdata, "UndertaleModCli.zip"),
					},
					cwd = path(appdata, "UndertaleModCli"),
				}, nil, true)
				uv.fs_unlink(path(appdata, "UndertaleModCli.zip"))
			end
			if xdelta3_missing then
				print("Downloading xdelta3...")
				execute("curl", {
					args = {
						"https://github.com/jmacd/xdelta-gpl/releases/download/v3.1.0/xdelta3-3.1.0-x86_64.exe.zip",
						"-o", path(appdata, "xdelta3.zip"), "-f", "-L"
					}
				}, nil, true)
				print("Unzipping xdelta3...")
				execute("tar", {
					args = {
						"-xf", path(appdata, "xdelta3.zip"),
					},
					cwd = appdata,
				}, nil, true)
				uv.fs_unlink(path(appdata, "xdelta3.zip"))
			end
		else
			os.exit(0)
		end
	end
end

local function readproject(source)
	local pfile, success, err
	pfile, err = readfile(source.."/project.json")
	assert(pfile, "ERROR: Could not read project file\n"..tostring(err))

	local project
	success, project = xpcall(json.parse, function(e) err = e end, pfile)
	assert(success, "ERROR: Could not parse project file\n"..tostring(err))

	assert(type(project) == "table" and json.type(project) == "table", "ERROR: Incorrectly formatted project.json\ni dont feel like writing an error message for this one")
	assert(json.type(project.game) == "array", "ERROR: Incorrectly formatted project.json\n\"game\" must be an array of paths")
	assert(json.type(project.copy) == "table", "ERROR: Incorrectly formatted project.json\n\"copy\" must be an object containing files to copy")
	assert(json.type(project.juncture) == "table", "ERROR: Incorrectly formatted project.json\n\"juncture\" must be an object containing files to create junctures")
	assert(json.type(project.data) == "string", "ERROR: Incorrectly formatted project.json\n\"data\" must be a path to the data.win file to patch")
	assert(json.type(project.GeneralInfo) == "table" or json.type(project.GeneralInfo) == "nil", "ERROR: Incorrectly formatted project.json\n\"GeneralInfo\" must be a table or be omitted")

	local gamelocation
	for i = 1, #project.game do
		success, err = uv.fs_scandir(project.game[i])
		if success then
			gamelocation = project.game[i]
			break
		end
	end
	assert(gamelocation, "ERROR: Could not find game in any valid paths")

	project.game = gamelocation
	project.source = source

	return project
end

local function create_csx()
	local scripts = {
		"csx/using.csx",
		"csx/gml.csx",
		"csx/sprites.csx",
		"csx/sounds.csx",
		"csx/build.csx",
	}
	local c = {}
	for i = 1, #scripts do
		local content = luvi.bundle.readfile(scripts[i])
		c[#c+1] = '#line 1 "'..scripts[i]..'"\n'..content.."\n"
	end
	return table.concat(c)
end

local function build()
	local success, err = forceremove(bin)
	assert(success or err:starts("ENOENT"), "ERROR: Could not remove directory "..bin.."\n"..tostring(err))

	success, err = mkdir(bin)
	assert(success, "ERROR: Could not create directory "..bin.."\n"..tostring(err))

	for k, v in pairs(project.copy) do
		local from, to = path(project.game, v), path(bin, k)
		success, err = uv.fs_copyfile(from, to)
		assert(success, "ERROR: Could not copy file "..from.." to "..to.."\n"..tostring(err))
	end

	for k, v in pairs(project.juncture) do
		local from, to = path(project.game, v), path(bin, k)
		success, err = uv.fs_symlink(from, to, {
			junction = true
		})
		assert(success, "ERROR: Could not create juncture from "..from.." to "..to.."\n"..tostring(err))
	end

	local umtlogger
	if flags.verbose then
		umtlogger = function(err, data)
			if data then
				if data:starts("%RUNNER:") and not project.runner then
					local f = io.open(path(bin, ".runner"), "w+b")
					if f then
						local runner = data:gsub("^%%RUNNER:",""):gsub("\r?\n", "")..".exe"
						project.runner = path(project.game, runner)
						f:write(project.runner)
						f:close()
					end
				end
				io.write(data)
			end
		end
	else
		local shouldclear = false
		umtlogger = function(err, data)
			if data then
				if data:starts("%RUNNER:") and not project.runner then
					local f = io.open(path(bin, ".runner"), "w+b")
					if f then
						local runner = data:gsub("^%%RUNNER:",""):gsub("\r?\n", "")..".exe"
						project.runner = path(project.game, runner)
						f:write(project.runner)
						f:close()
					end
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
	local f = io.open(path(appdata, ".csx"), "w+b")
	assert(f, "ERROR: Failed to compile internal build scripts\nCouldn't create .csx")
	f:write(create_csx())
	f:close()
	local code = execute(path(appdata, "UndertaleModCli/UndertaleModCli.exe"), {
		args = {
			"load",
			path(project.game, project.data),
			"-v",
			"-s",
			path(appdata, ".csx"),
			"-o",
			path(bin, "data.win"),
		},
		env = {
			"SOURCE="..project.source
		}
	}, umtlogger)
	os.remove(path(appdata, ".csx"))
	assert(code == 0, "Build failed, aborting...")
end

local function create_patch()
	local code = execute(path(appdata, "xdelta3-3.1.0-x86_64.exe"), {
		args = {
			"-e",
			"-s",
			path(project.game, project.data),
			path(bin, "data.win"),
			path(bin, "patch.xdelta"),
		}
	}, function(err, data, stderr)
		if stderr and data then
			io.write(data)
		end
	end)
	assert(code == 0, "Failed to create .xdelta patch")
end

local function launch()
	if not project.runner then
		local f = assert(io.open(path(bin, ".runner"), "r+b"), "ERROR: Could not find a valid game runner\nPlease add a 'runner' property to project.json")
		project.runner = f:read("*all")
		f:close()
	end
	return execute(path(project.game, project.runner), {
		args = {
			"-game",
			path(bin, "data.win"),
		}
	})
end

local function help()
	io.write([[
Usage: ]]..exename..[[ <input> [options]
If input is not provided, the current directory will be used

Options:
	-b, --build            Build mod from input directory
	-l, --launch           Launch mod from input directory
	-v, --verbose          Detailed logs
	-x, --create-patch     Create .xdelta patch
	--version              Show version information
	-?, -h, --help         Show help and usage information
]])
	return 0
end

local function setflag(name)
	noflags = false
	if name == "?" or name == "h" or name == "help" then
		flags.help = true
		return false
	elseif name == "b" or name == "build" then
		flags.build = true
		return false
	elseif name == "l" or name == "launch" then
		flags.launch = true
		return false
	elseif name == "v" or name == "verbose" then
		flags.verbose = true
		return false
	elseif name == "x" or name == "create-patch" then
		flags.create_patch = true
		return false
	elseif name == "version" then
		flags.version = true
		return false
	else
		exit(1, "Unknown flag '"..name.."'")
	end
end

local function main()
	dependancies()
	if #args == 0 then
		return help()
	end
	while argi <= #args do
		if args[argi]:byte(1) == 45 then
			if args[argi]:byte(2) == 45 then
				setflag(args[argi]:sub(3))
			else
				for j = 2, #args[argi] do
					setflag(args[argi]:sub(j, j))
				end
			end
			table.remove(args, argi)
		else
			argi = argi + 1
		end
	end
	local source = args[1]
	if not source then
		source = "."
	end
	if noflags then
		print("No options provided. (Try '"..exename.." -?' for help information)")
		return 0
	end
	if flags.version then
		print("utsdk: "..MAJOR.."."..MINOR.."."..PATCH.."-"..(type(luvi.bundle.stat("main.lua").mtime) == "number" and luvi.bundle.stat("main.lua").mtime or "source"))
		print("umcli: "..umcli_version)
		print("luvi:  "..luvi.version)
		print("jit:   "..jit.version_num)
		return 0
	end
	if flags.help then
		return help()
	end
	project = readproject(source)
	if flags.build then
		build()
	end
	if flags.create_patch then
		create_patch()
	end
	if flags.launch then
		launch()
	end
end

os.exit(main())