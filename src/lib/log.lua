local log = {}

local RESET = "\x1b[0m"

local RED = "\x1b[91m"
local YELLOW = "\x1b[93m"
local GREEN = "\x1b[92m"
local GRAY = "\x1b[90m"

function log.print(...)
	print(...)
end

function log.error(...)
	io.write(RED)
	print(...)
	io.write(RESET)
end

function log.warning(...)
	io.write(YELLOW)
	print(...)
	io.write(RESET)
end

function log.success(...)
	io.write(GREEN)
	print(...)
	io.write(RESET)
end

function log.info(...)
	io.write(GRAY)
	print(...)
	io.write(RESET)
end

function log.assert(v, msg, code)
	if v then
		return v
	else
		log.error(msg)
		os.exit(code, true)
	end
end

function log.throw(src, name, message, index)
	-- this function will find the line number and column in string 'src'
	-- based on the integer 'index', as well as find two lines before and after.
	-- it will then display these lines, highlight what went wrong, and exit
	-- immediately.
	-- since there will be no runtime errors, there is no need for a stack trace.
	-- so all that extra space can be used to show a snippet of the code that
	-- failed to compile.

	local l1, l2, l3, l4, l5
	local line = 1
	local col = -1
	local last = 1
	local i = 1
	while i <= index do
		if string.byte(src, i) ~= 13 then
			col = col + 1
		end
		if string.byte(src, i) == 10 then
			l1 = l2
			l2 = {last, i-1}
			last = i+1
			col = -1
			line = line + 1
		end
		i = i + 1
	end
	while i <= #src do
		if string.byte(src, i) == 10 then
			if not l3 then
				l3 = {last, i-1}
			elseif not l4 then
				l4 = {last, i-1}
			elseif not l5 then
				l5 = {last, i-1}
				break
			end
			last = i+1
		end
		i = i + 1
	end
	if not l3 then
		l3 = {last, i-1}
	elseif not l4 then
		l4 = {last, i-1}
	elseif not l5 then
		l5 = {last, i-1}
	end
	log.print("error at ", name, ":", line, ":", col)
	log.print(log.red(message))
	if l1 then
		log.print("    ", log.gray(line-2), "\t", log.gray(src:sub(unpack(l1))))
	end
	if l2 then
		log.print("    ", log.gray(line-1), "\t", log.gray(src:sub(unpack(l2))))
	end
	if l3 then
		log.print(log.red("  > "), line, "\t", src:sub(unpack(l3)))
		log.print("        ", log.red(string.rep("~", col).."^"))
	end
	if l4 then
		log.print("    ", log.gray(line+1), "\t", log.gray(src:sub(unpack(l4))))
	end
	if l5 then
		log.print("    ", log.gray(line+2), "\t", log.gray(src:sub(unpack(l5))))
	end
	os.exit(1, true)
end

return log