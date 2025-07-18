local uv = require "uv"

local util = {}

function util.confirm()
	local yes = false
	local stdin = uv.new_tty(0, true)
	uv.tty_set_mode(stdin, "raw")
	stdin:read_start(function(err, data)
		if not data then return end
		if data:lower() == "y" then
			print("Y")
			yes = true
			uv.tty_set_mode(stdin, "normal")
			stdin:close()
		elseif data:lower() == "n" then
			print("N")
			uv.tty_set_mode(stdin, "normal")
			stdin:close()
		elseif data:byte(1) == 3 then
			os.exit(0)
		end
	end)
	uv.run()
	return yes
end

function util.select(options)
	local option = nil
	local stdin = uv.new_tty(0, true)
	uv.tty_set_mode(stdin, "raw")
	stdin:read_start(function(err, data)
		if not data then return end
		for i = 1, #options do
			local selected = false
			if type(options[i]) == "number" then
				selected = data:byte(1) == options[i] and #data == 1
			else
				selected = data == options[i]
			end
			if selected then
				option = options[i]
				print(data)
				uv.tty_set_mode(stdin, "normal")
				stdin:close()
			end
		end
		if data:byte(1) == 3 then
			os.exit(0)
		end
	end)
	uv.run()
	return option
end

function util.prompt()
	local input = nil
	local stdin = uv.new_tty(0, true)
	stdin:read_start(function(err, data)
		if not data then return end
		input = data:gsub("\r?\n$", "")
		stdin:close()
	end)
	uv.run()
	return input
end

return util