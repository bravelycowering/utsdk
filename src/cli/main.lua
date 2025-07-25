local uv = require "uv"
local json = require "lib.json"
local fs = require "lib.fs"
local log = require "lib.log"

local version = require "cli.version"

local launch = require "cli.launch"
local create_patch = require "cli.create_patch"
local dependancies = require "cli.dependancies"
local build = require "cli.build"
local init = require "cli.init"

local assert = log.assert

local function readproject(source)
	local pfile, success, err
	pfile, err = fs.read(source.."/project.json")
	assert(pfile, "ERROR: Could not read project file\n"..tostring(err))

	local project
	success, project = xpcall(json.parse, function(e) err = e end, pfile)
	assert(success, "ERROR: Could not parse project file\n"..tostring(err))

	assert(type(project) == "table" and json.type(project) == "table", "ERROR: Incorrectly formatted project.json\ni dont feel like writing an error message for this one")
	assert(json.type(project.game) == "array", "ERROR: Incorrectly formatted project.json\n\"game\" must be an array of paths")
	assert(json.type(project.copy) == "table", "ERROR: Incorrectly formatted project.json\n\"copy\" must be an object containing files to copy")
	assert(json.type(project.link) == "table", "ERROR: Incorrectly formatted project.json\n\"link\" must be an object containing files to create links")
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
Usage: ]]..fs.exename..[[ <source> [options]
If source is not provided, the current directory will be used

Options:
	-b, --build            Build mod from source directory
	-l, --launch           Launch mod from source directory
	-v, --verbose          Detailed logs
	-x, --create-patch     Create .xdelta patch
	--init                 Create new project at source directory
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
	local do_nothing = not (flags.build or flags.create_patch or flags.launch)
	if flags.init then
		init(source)
		if do_nothing then
			return 0
		end
	end
	if do_nothing then
		print("No options provided. (Try '"..fs.exename.." -?' for help information)")
		return 0
	end
	local project = readproject(source)
	if flags.build then
		dependancies()
		build(project)
	end
	if flags.create_patch then
		dependancies()
		create_patch(project)
	end
	if flags.launch then
		launch(project)
	end
end

os.exit(main())