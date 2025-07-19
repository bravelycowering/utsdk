---@diagnostic disable: undefined-field, need-check-nil, param-type-mismatch, assign-type-mismatch
local uv = require "uv"
local luvi = require "luvi"
local fs = require "lib.fs"
require "love.jitsetup"
require "love.callbacks"
require "love.filesystem"
love.filesystem.init(arg[0])
love.filesystem.setFused(pcall(love.filesystem.setSource, uv.exepath()))
if not love.filesystem.isFused() then
	love.filesystem.setSource(luvi.bundle.base)
end
require "love.data"
require "love.thread"
require "love.timer"
require "love.event"
require "love.keyboard"
require "love.joystick"
require "love.mouse"
require "love.touch"
require "love.sound"
require "love.system"
require "love.audio"
require "love.image"
require "love.video"
require "love.font"
require "love.window"
require "love.graphics"
require "love.math"
require "love.physics"

love.createhandlers()

local dwidth, dheight = love.window.getDesktopDimensions()
local wwidth, wheight = 640, 480

if dwidth > wwidth * 2 and dheight > wheight * 2 then
	wwidth, wheight = 1280, 960
end

love.window.setTitle(fs.exename)
love.window.setMode(wwidth, wheight, {
	resizable = true,
})

love.timer.step()

require "gui.main"

-- Main loop time.
while true do
	-- Process events.
	if love.event then
		love.event.pump()
		for name, a,b,c,d,e,f,g,h in love.event.poll() do
			if name == "quit" then
				if c or not love.quit or not love.quit() then
					return a or 0, b
				end
			end
			love.handlers[name](a,b,c,d,e,f,g,h)
		end
	end

	-- Call update and draw
	if love.update then love.update() end -- will pass 0 if love.timer is disabled

	if love.graphics and love.graphics.isActive() then
		love.graphics.origin()
		love.graphics.clear(love.graphics.getBackgroundColor())

		if love.draw then love.draw() end

		love.graphics.present()
	end

	if love.timer then love.timer.sleep(0.001) end
end