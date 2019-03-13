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

local update_speed = 30

local fitness_font

local stored_fitnesses = {}

local enemies = {}
function love.load()
	world, player = World.new()
	local enemy = Enemy.new(0, 0)
	table.insert(enemies, enemy)
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
	pop:create_genomes(96, 16, 8)
	pop_update = pop:evolve()

	love.graphics.setBackgroundColor(CONF.BACK_COLOR)
	fitness_font = love.graphics.newFont(24)
end

function love.keypressed(key)
	input:keydown(key)
end

function love.keyreleased(key)
	input:keyup(key)
end

local function get_random_pos()
	local x = math.random(100) + math.random(100) + 600 * (math.random(2) - 1)
	local y = math.random(100) + math.random(100) + 500 * (math.random(2) - 1)
	return x, y
end

local function network_input(ins, dt)
	player.alive = true
	if ins[1] > 0.35 then input:keydown("w") else input:keyup("w") end
	if ins[2] > 0.35 then input:keydown("s") else input:keyup("s") end
	if ins[3] > 0.35 then input:keydown("a") else input:keyup("a") end
	if ins[4] > 0.35 then input:keydown("d") else input:keyup("d") end
	if ins[5] > 0.35 then input:keydown("left") else input:keyup("left") end
	if ins[6] > 0.35 then input:keydown("right") else input:keyup("right") end
	if ins[7] > 0.35 then input:keydown("up") else input:keyup("up") end
	if ins[8] > 0.35 then input:keydown("down") else input:keyup("down") end

	local last_x = player.x
	local last_y = player.y

	world:update(dt, input)

	local fitness = math.sqrt(math.sqrDist(last_x, last_y, player.x, player.y))
	fitness = fitness - (player.shot and 1 or 0)

	local enemies_alive = 0
	for _, v in ipairs(enemies) do
		if v.alive then
			enemies_alive = enemies_alive + 1
		else
			if not v.__tagged then
				v.__tagged = true
				fitness = fitness + 400
			end
		end
	end

	if not player.alive or enemies_alive == 0 then
		for _, v in ipairs(enemies) do
			world:remove_entity(v)
		end

		enemies = {}

		for _ = 1, math.ceil((pop.generation + 1) / 10) do
			local enemy = Enemy.new(get_random_pos())
			world:add_entity(enemy)
			table.insert(enemies, enemy)
		end

		if player.alive then
			fitness = fitness + 2000
		else
			player.x = 400
			player.y = 300
		end
	end

	return fitness, player.alive
end

local function generation_step(avg_fitness, _, _)
	table.insert(stored_fitnesses, avg_fitness)
end

function love.update(dt)
	if love.keyboard.isDown "escape" then
		love.event.quit()
	end

	if love.keyboard.isDown "z" then
		update_speed = update_speed - 1
		if update_speed < 1 then
			update_speed = 1
		end
	end

	if love.keyboard.isDown "x" then
		update_speed = update_speed + 1
		if update_speed > 60 then
			update_speed = 60
		end
	end

	for _ = 1, update_speed do
		local dists = player:get_distances(world)

		local inputs = {}
		for i = 1, 16 do
			local v1 = dists[i * 2]
			local v2 = dists[(i * 2 + 1) % 32]
			local v3 = dists[(i * 2 - 1) % 32]

			inputs[i] = 1 - ((0.5 * v1 + 0.25 * v2 + 0.25 * v3) / (CONF.ENEMY_SIZE * CONF.PLAYER_VISION_DISTANCE))
		end

		pop_update = pop_update(inputs, network_input, generation_step, dt)
	end
end

local function plot_fitness(x, y, scale)
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.scale(scale, scale)

	love.graphics.setColor(0, 0, 0, 0.4)
	love.graphics.rectangle("fill", -20, -20, 440, 240)

	love.graphics.setFont(fitness_font)
	love.graphics.setColor(1, 1, 1)

	love.graphics.printf("Average fitness: " .. math.floor(pop.avg_fitness), 0, 0, 400, "left")
	love.graphics.printf("Highest fitness: " .. math.floor(pop.high_fitness), 0, 20, 400, "left")

	local highest = 0
	for _, v in ipairs(stored_fitnesses) do
		if v > highest then
			highest = v
		end
	end

	local width = 400 / (#stored_fitnesses)

	love.graphics.setColor(0, 0, 1)
	for i, v in ipairs(stored_fitnesses) do
		if v < 0 then
			v = 0
		end
		love.graphics.circle("fill", (i - 1) * width, 200 - v * 100 / highest, 8)
	end

	love.graphics.pop()
end

local function draw_network(net, x, y, scale)
	if net == nil then return end

	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.scale(scale, scale)

	love.graphics.setColor(0, 0, 0, 0.4)
	love.graphics.rectangle("fill", -20, -20, 680, 600)

	love.graphics.setColor(1, 1, 1)

	for _, v in pairs(net.neurons) do
		love.graphics.rectangle("fill", v.x, v.y, 24, 24)
	end

	for _, neuron in pairs(net.neurons) do
		local ins = neuron.inputs

		local x1 = neuron.x + 12
		local y1 = neuron.y + 12
		for _, conn in pairs(ins) do
			local other = net.neurons[conn.from]
			local x2 = other.x + 12
			local y2 = other.y + 12

			local col = { 1, 0, 0 }
			if conn.weight > 0 then
				col = { 0, 0, 1 }
			end

			love.graphics.setColor(col)
			love.graphics.setLineWidth(math.sigmoid(conn.weight) * 2)
			love.graphics.line(x1, y1, x2, y2)
		end
	end

	love.graphics.setLineWidth(2)
	love.graphics.pop()
end

function love.draw()
	world:draw()

	love.graphics.setColor(0, 0, 0)
	love.graphics.printf(tostring(love.timer.getFPS()) .. " FPS", 0, 0, 800, "left")
	love.graphics.printf("Generation: " .. pop.generation, 0, 32, 800, "left")
	love.graphics.printf("Genome: " .. pop.current_genome, 0, 64, 800, "left")
	if pop.genomes[pop.current_genome] ~= nil then
		love.graphics.printf("Fitness: " .. math.floor(pop.genomes[pop.current_genome].fitness), 0, 96, 800, "left")

		draw_network(pop.genomes[pop.current_genome].network, 580, 0, 1 / 3)
	end

	plot_fitness(250, 0, 3 / 4)
end
