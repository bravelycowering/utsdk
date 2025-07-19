local input = require "lib.input"

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
	project.bin = ".bin"
	project.data = "chapter"..chnum.."_windows/data.win"
end

local function init()
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
		project.bin = ".bin"
		project.link = {}
		project.data = "data.win"
	elseif preset == "9" then
		project.game = {
			"C:/Program Files (x86)/Steam/steamapps/common/Undertale",
			"C:/Program Files/Steam/steamapps/common/Undertale",
		}
		project.copy = {}
		project.link = {}
		project.bin = ".bin"
		project.data = "data.win"
	else

	end
end

return init