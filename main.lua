local CONF = require "conf"

local world_mod = require "src.world"
local Input = require "src.input"

local World = world_mod.World

local world, player
local input
function love.load()
	world, player = World:new()

	input = Input:new()

	love.graphics.setBackgroundColor(CONF.BACK_COLOR)
end

function love.keypressed(key)
	input:keydown(key)	
end

function love.keyreleased(key)
	input:keyup(key)
end

function love.update(dt)
	if love.keyboard.isDown "escape" then
		love.event.quit()
	end
	
	world:update(dt, input)
end

function love.draw()
	world:draw()
end
