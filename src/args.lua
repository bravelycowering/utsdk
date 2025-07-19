_G.flags = {
	help = false,
	build = false,
	launch = false,
	verbose = false,
	create_patch = false,
	version = false,
	init = false,
}

_G.arg = {[0]=args[0]}

local i = 1

local function setflag(name)
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
	elseif name == "init" then
		flags.init = true
		return false
	else
		print("Unknown option '"..name.."'")
		os.exit(1)
	end
end

while i <= #args do
	arg[#arg+1] = args[i]
	if args[i]:byte(1) == 45 then
		if args[i]:byte(2) == 45 then
			setflag(args[i]:sub(3))
		else
			for j = 2, #args[i] do
				setflag(args[i]:sub(j, j))
			end
		end
		table.remove(args, i)
	else
		i = i + 1
	end
end