local CONF = require "conf"

local world_mod = require "src.world"
local Input = require "src.input"
local Gen = require "src.genetics"

local World = world_mod.World
local Enemy = world_mod.Enemy
local Wall = world_mod.Wall
local Population = Gen.Population

local world, player
local input
local pop
local pop_update

local enemy_spawn = { 100, 100 }
local enemy
function love.load()
	world, player = World.new()
	enemy = Enemy.new(unpack(enemy_spawn))
	world:add_entity(enemy)

	local wall1 = Wall.new(-20, -20, 840, 20)
	local wall2 = Wall.new(-20, 600, 840, 20)
	local wall3 = Wall.new(-20, 0, 20, 600)
	local wall4 = Wall.new(800, 0, 20, 600)
	world:add_entity(wall1)
	world:add_entity(wall2)
	world:add_entity(wall3)
	world:add_entity(wall4)

	input = Input:new()

	pop = Population.new()
	pop:create_genomes(100, 16, 8)
	pop_update = pop:evolve()

	love.graphics.setBackgroundColor(CONF.BACK_COLOR)
end

function love.keypressed(key)
	input:keydown(key)
end

function love.keyreleased(key)
	input:keyup(key)
end

local function network_input(ins, dt)
	player.alive = true
	for _, v in ipairs(ins) do
		--print(v)
	end
	if ins[1] > 0.5 then input:keydown("w") else input:keyup("w") end
	if ins[2] > 0.5 then input:keydown("s") else input:keyup("s") end
	if ins[3] > 0.5 then input:keydown("a") else input:keyup("a") end
	if ins[4] > 0.5 then input:keydown("d") else input:keyup("d") end
	if ins[5] > 0.5 then input:keydown("left") else input:keyup("left") end
	if ins[6] > 0.5 then input:keydown("right") else input:keyup("right") end
	if ins[7] > 0.5 then input:keydown("up") else input:keyup("up") end
	if ins[8] > 0.5 then input:keydown("down") else input:keyup("down") end


	world:update(dt, input)

	local fitness = 0.5

	if not player.alive or not enemy.alive then
		world:remove_entity(enemy)
		enemy = Enemy.new(math.random(800), math.random(600))
		world:add_entity(enemy)

		player.x = 400
		player.y = 300

		if not enemy.alive then
			fitness = fitness + 1000
		end
	end

	return fitness, player.alive
end

function love.update(dt)
	if love.keyboard.isDown "escape" then
		love.event.quit()
	end

	for _ = 1, 30 do
		local dists = player:get_distances(world)
		pop_update = pop_update(dists, network_input, dt)
	end
end

function love.draw()
	world:draw()

	love.graphics.setColor(0, 0, 0)
	--love.graphics.printf(tostring(love.timer.getFPS()) .. " FPS", 0, 0, 800, "center")
	if pop.genomes[pop.current_genome] ~= nil then
		love.graphics.printf(pop.generation .. " Generation | " .. pop.current_genome .. " Genome | " .. (pop.genomes[pop.current_genome].fitness) .. " Fitness", 0, 0, 800, "center")
	end
end
