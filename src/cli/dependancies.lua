local fs = require "lib.fs"
local util = require "lib.util"
local version = require "cli.version"

local checked_dependancies = false

local function dependancies()
	if checked_dependancies then return end
	local xdelta3_missing = true
	local umcli_missing = true
	local umcli_wanted_version = "1.0.0+473b731a8d16b75ac889972466470dc05d9c90ed"
	if fs.exists(fs.appdata, "directory") then
		if fs.exists(fs.path(fs.appdata, "UndertaleModCli"), "directory") and fs.exists(fs.path(fs.appdata, "UndertaleModCli/UndertaleModCli.exe"), "file") then
			umcli_missing = false
			fs.execute(fs.path(fs.appdata, "UndertaleModCli/UndertaleModCli.exe"), { args = { "--version" } }, function(err, data)
				if not data then return end
				local v = data:gsub("%s+", "")
				if #v > 0 then
					version.umcli = v
				end
			end)
			if version.umcli ~= umcli_wanted_version then
				umcli_missing = true
			end
		else
			umcli_missing = true
		end
		if fs.exists(fs.path(fs.appdata, "xdelta3-3.1.0-x86_64.exe"), "file") then
			version.xdelta = "3.1.0"
		end
		xdelta3_missing = version.xdelta == "none"
	else
		fs.mkdir(fs.appdata)
	end
	if umcli_missing or xdelta3_missing then
		if version.umcli == "none" or xdelta3_missing then
			print("\n"..fs.exename.." is missing the following binaries and needs them to function properly\n")
		else
			print("There is an update available for the following binaries")
		end
		if umcli_missing then
			print("    UndertaleModCli (https://github.com/UnderminersTeam/UndertaleModTool/)")
		end
		if xdelta3_missing then
			print("    xdelta (https://github.com/jmacd/xdelta-gpl)")
		end
		print("\nWould you like to download them now? (Y/N) ")
		if util.confirm() then
			if umcli_missing then
				print("Downloading UndertaleModCli...")
				fs.execute("curl", {
					args = {
						"https://github.com/UnderminersTeam/UndertaleModTool/releases/download/0.8.2.0/UTMT_CLI_v0.8.2.0-Windows.zip",
						"-o", fs.path(fs.appdata, "UndertaleModCli.zip"), "-f", "-L"
					}
				}, nil, true)
				print("Unzipping UndertaleModCli...")
				fs.mkdir(fs.path(fs.appdata, "UndertaleModCli"))
				fs.execute("tar", {
					args = {
						"-xf", fs.path(fs.appdata, "UndertaleModCli.zip"),
					},
					cwd = fs.path(fs.appdata, "UndertaleModCli"),
				}, nil, true)
				fs.delete(fs.path(fs.appdata, "UndertaleModCli.zip"))
			end
			if xdelta3_missing then
				print("Downloading xdelta3...")
				fs.execute("curl", {
					args = {
						"https://github.com/jmacd/xdelta-gpl/releases/download/v3.1.0/xdelta3-3.1.0-x86_64.exe.zip",
						"-o", fs.path(fs.appdata, "xdelta3.zip"), "-f", "-L"
					}
				}, nil, true)
				print("Unzipping xdelta3...")
				fs.execute("tar", {
					args = {
						"-xf", fs.path(fs.appdata, "xdelta3.zip"),
					},
					cwd = fs.appdata,
				}, nil, true)
				fs.delete(fs.path(fs.appdata, "xdelta3.zip"))
			end
		else
			os.exit(0)
		end
	end
	checked_dependancies = true
end

return dependancies