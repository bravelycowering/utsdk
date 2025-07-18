local luvi = require "luvi"
local uv = require "uv"
local json = require "lib.json"
local util = require "lib.util"
local fs = require "lib.fs"
local log = require "lib.log"

local version = require "cli.version"
local launch = require "cli.launch"
local create_patch = require "cli.create_patch"
local dependancies = require "cli.dependancies"
local build = require "cli.build"

local assert = log.assert

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
		local p = paths[i]
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
		log.error("INTERNAL ERROR: EXE NOT FOUND\n"..exe.."\n\nplease report this to bravelycowering")
		os.exit(1)
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

local bin = ".bin"

local exename = uv.exepath():gsub("^.+[%/%\\]", ""):gsub("%.[^%.]+$", "")
local appdata = path(os.getenv("appdata"), "UndertaleModdingSDK")

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
	assert(json.type(project.output) == "string", "ERROR: Incorrectly formatted project.json\n\"bin\" must be a path to the output folder")
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

local function help()
	io.write([[
Usage: ]]..exename..[[ <source> [options]
If source is not provided, the current directory will be used

Options:
	-b, --build            Build mod from source directory
	-l, --launch           Launch mod from source directory
	-v, --verbose          Detailed logs
	-x, --create-patch     Create .xdelta patch
	--version              Show version information
	-?, -h, --help         Show help and usage information
]])
	return 0
end

local function main()
	if #arg == 0 then
		return help()
	end
	local source = args[1]
	if not source then
		source = "."
	end
	if flags.version then
		dependancies()
		print("utsdk: "..version.utsdk)
		print("UndertaleModCli: "..version.umcli)
		print("xdelta: "..version.xdelta)
		print("luvi:  "..version.luvi)
		print("jit:   "..version.jit)
		return 0
	end
	if flags.help then
		return help()
	end
	local did_nothing = true
	local project = readproject(source)
	if flags.build then
		did_nothing = false
		dependancies()
		build(project)
	end
	if flags.create_patch then
		did_nothing = false
		dependancies()
		create_patch(project)
	end
	if flags.launch then
		did_nothing = false
		launch(project)
	end
	if did_nothing then
		print("No options provided. (Try '"..exename.." -?' for help information)")
		return 0
	end
end

os.exit(main())