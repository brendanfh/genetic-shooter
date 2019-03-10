local CONF = require "conf"

local world_mod = require "src.world"
local Input = require "src.input"

local World = world_mod.World
local Enemy = world_mod.Enemy

local world, player
local input
function love.load()
	world, player = World:new()
	for i = 1, 100 do
		local enemy = Enemy:new(math.random(800), math.random(600))
		world:add_entity(enemy)
	end

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

	love.graphics.setColor(0, 0, 0)
	love.graphics.printf(tostring(love.timer.getFPS()) .. " FPS", 0, 0, 800, "center")
end
