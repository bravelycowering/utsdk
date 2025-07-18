local uv = require "uv"

local fs = {}

function fs.readdir(dname)
	local success, err, dir
	dir, err = uv.fs_opendir(dname)
	if not dir then return dir, err end
	local entries = {}
	repeat
		success = uv.fs_readdir(dir)
		if success then
			for i = 1, #success do
				entries[#entries+1] = success[i]
			end
		end
	until not success
	uv.fs_closedir(dir)
	return entries
end

function fs.read(fname)
	local contents
	local f = io.open(fname, "rb")
	if not f then
		return nil, "Could not open file "..fname
	end
	contents = f:read("*all")
	f:close()
	return contents
end

function fs.write(fname, contents)
	local f = io.open(fname, "w+b")
	if not f then
		return nil, "Could not open file "..fname
	end
	f:write(contents)
	f:close()
end

function fs.copyfile(from, to)
	return uv.fs_copyfile(from, to)
end

function fs.junction(from, to)
	return uv.fs_symlink(from, to, { junction = true })
end

function fs.delete(fname, recursive)
	local stat, err = fs.stat(fname)
	if stat then
		if stat.type == "directory" then
			if recursive then
				for index, file in ipairs(fs.readdir(fname)) do
					local success, err = fs.delete(fs.path(fname, file.name), true)
					if not success then
						return success, err
					end
				end
			end
			return uv.fs_rmdir(fname)
		else
			return uv.fs_unlink(fname)
		end
	end
	return true
end

function fs.stat(fname)
	return uv.fs_lstat(fname)
end

function fs.mkdir(dname)
	local result, err = uv.fs_mkdir(dname, 0)
	if err and err:starts("EEXIST") then
		result, err = true, ""
	end
	return result, err
end

function fs.exists(fname, ftype)
	local stat = fs.stat(fname)
	if ftype == nil then
		return stat ~= nil
	elseif ftype == "file" then
		return stat and stat.type == "file"
	elseif ftype == "directory" then
		return stat and stat.type == "directory"
	elseif ftype == "link" then
		return stat and stat.type == "link"
	end
	return false
end

function fs.path(...)
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

function fs.getenvpath(name)
	if fs.exists(name, "file") then
		return name
	end
	for m in os.getenv("PATH"):gmatch("[^;]+") do
		if string.match(name, "%.[^.]+$") then
			local p = fs.path(m, name)
			if fs.exists(p, "file") then
				return p
			end
		else
			for e in os.getenv("PATHEXT"):gmatch("[^;]+") do
				local p = fs.path(m, name + e)
				if fs.exists(p, "file") then
					return p
				end
			end
		end
	end
end

function fs.execute(exe, options, l, dontcheck)
	local path = dontcheck and exe or fs.getenvpath(exe)
	if not path then return end
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

fs.exename = uv.exepath():gsub("^.+[%/%\\]", ""):gsub("%.[^%.]+$", "")
fs.appdata = fs.path(os.getenv("appdata"), "UndertaleModdingSDK")

return fs