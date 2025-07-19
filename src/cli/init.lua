local input = require "lib.input"
local json = require "lib.json"
local fs = require "lib.fs"

local function deltarunePreset(project, chnum)
	project.game = {
		"C:/Program Files (x86)/Steam/steamapps/common/DELTARUNE",
		"C:/Program Files/Steam/steamapps/common/DELTARUNE",
	}
	project.copy = {
		["audiogroup1.dat"] = "chapter"..chnum.."_windows/audiogroup1.dat",
	}
	project.link = {
		["lang"] = "chapter"..chnum.."_windows/lang",
		["mus"] = "mus",
	}
	project.output = ".bin"
	project.data = "chapter"..chnum.."_windows/data.win"
end

local function init(source)
	local project = {}
	print("Would you like to use a preset?")
	print("    1 - Deltarune Chapter 1")
	print("    2 - Deltarune Chapter 2")
	print("    3 - Deltarune Chapter 3")
	print("    4 - Deltarune Chapter 4")
	print("    9 - Undertale")
	print("    0 - Deltarune Chapter Select")
	io.write("Press enter to use custom settings, or type a preset number: ")
	local preset = input.select {"1", "2", "3", "4", "9", "0", string.byte "\n", string.byte "\r"}
	if preset == "1" then
		deltarunePreset(project, preset)
	elseif preset == "2" then
		deltarunePreset(project, preset)
	elseif preset == "3" then
		deltarunePreset(project, preset)
		project.link.vid = "chapter3_windows/vid"
	elseif preset == "4" then
		deltarunePreset(project, preset)
	elseif preset == "0" then
		project.game = {
			"C:/Program Files (x86)/Steam/steamapps/common/DELTARUNE",
			"C:/Program Files/Steam/steamapps/common/DELTARUNE",
		}
		project.copy = {
			["audiogroup1.dat"] = "audiogroup1.dat",
		}
		project.link = {
			chapter1_windows = "chapter1_windows",
			chapter2_windows = "chapter2_windows",
			chapter3_windows = "chapter3_windows",
			chapter4_windows = "chapter4_windows",
			mus = "mus"
		}
		project.data = "data.win"
		project.output = ".bin"
	elseif preset == "9" then
		project.game = {
			"C:/Program Files (x86)/Steam/steamapps/common/Undertale",
			"C:/Program Files/Steam/steamapps/common/Undertale",
		}
		project.copy = {}
		project.link = {}
		project.data = "data.win"
		project.output = ".bin"
	else
		project.game = {}
		while #project.game == 0 do
			print("\nPlease enter the path to the folder the game is contained in")
			print("You may enter multiple possible paths by separating them by a semicolon")
			io.write("Path(s): ")
			project.game = {}
			for m in input.prompt():gmatch("[^;]+") do
				project.game[#project.game+1] = m
			end
		end
		print("\nPlease enter the name of the game's data file")
		print("Leaving this blank will use the default")
		io.write("Data file location: ")
		project.data = input.prompt()
		if #project.data == 0 then
			project.data = "data.win"
		end
		project.output = ".bin"
		project.link = {}
		project.copy = {}
		print("\nIf the game has external assets such as music or video files, you may need to configure project.json to copy or link these files upon build.")
	end
	print("\nAND WHAT ABOUT THE CREATOR")
	io.write("Your own name: ")
	local author = input.prompt()
	if #author > 0 then
		project.author = author
	end
	fs.write(fs.path(source, "project.json"), json.stringify(project))
end

return init