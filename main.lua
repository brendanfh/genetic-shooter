local CONF = require "conf"

local world_mod = require "src.world"
local Input = require "src.input"
local Gen = require "src.genetics"
require "src.data"
local Trainer = (require "src.trainer").Trainer
local Stats = (require "src.stats").Stats

local World = world_mod.World
local Wall = world_mod.Wall
local Population = Gen.Population

local world
local input
local pop
local trainer
local pop_stats
local gen_stats

local ui_font
local fitness_font

function love.load()
	math.randomseed(os.time())

	world = World.new()

	local wall1 = Wall.new(-20, -20, 840, 20)
	local wall2 = Wall.new(-20, 600, 840, 20)
	local wall3 = Wall.new(-20, 0, 20, 600)
	local wall4 = Wall.new(800, 0, 20, 600)
	world:add_entity(wall1)
	world:add_entity(wall2)
	world:add_entity(wall3)
	world:add_entity(wall4)

	input = Input:new()

	if CONF.LOAD_FILE == "" then
		pop = Population.new()
		pop:create_genomes(CONF.POPULATION_SIZE, 16, 8)
	else
		pop = Population.load(CONF.LOAD_FILE)
	end

	pop_stats = Stats.new()
	gen_stats = Stats.new()

	trainer = Trainer.new(pop, world, input)
	trainer:initialize_training()

	love.graphics.setBackgroundColor(CONF.BACK_COLOR)
	ui_font = love.graphics.newFont(24)
	fitness_font = love.graphics.newFont(32)
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

	if love.keyboard.isDown "z" then
		trainer:change_speed(-1)
	end

	if love.keyboard.isDown "x" then
		trainer:change_speed(1)
	end

	trainer:update(dt, pop_stats, gen_stats)
	--world:update(dt, input)
end

local function plot_fitness(x, y, scale)
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.scale(scale, scale)

	love.graphics.setColor(0, 0, 0, 0.4)
	love.graphics.rectangle("fill", -20, -20, 680, 340)

	love.graphics.setFont(fitness_font)
	love.graphics.setColor(CONF.FONT_COLOR)

	love.graphics.printf("Average fitness: " .. math.floor(pop.avg_fitness), 0, 0, 640, "left")
	love.graphics.printf("Highest fitness: " .. math.floor(pop.high_fitness), 0, 32, 640, "left")

	local points = pop_stats:get_points(0, 120, 640, 200)

	love.graphics.setColor(0, 0, 1)
	for _, v in ipairs(points) do
		love.graphics.circle("fill", v[1], v[2], 8)
	end

	love.graphics.pop()
end

local function plot_generation(x, y, scale)
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.scale(scale, scale)

	love.graphics.setColor(0, 0, 0, 0.4)
	love.graphics.rectangle("fill", -20, -20, 680, 340)

	love.graphics.setFont(fitness_font)
	love.graphics.setColor(CONF.FONT_COLOR)

	love.graphics.printf("Fitness over Genome", 0, 0, 640, "left")

	local points = gen_stats:get_points(0, 60, 640, 260)

	love.graphics.setColor(1, 0, 0)
	for _, v in ipairs(points) do
		love.graphics.circle("fill", v[1], v[2], 8)
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

	for _, v in pairs(net.neurons) do
		local c = v.value
		local r = c < 0 and -c or 0
		local b = c > 0 and c or 0
		local g = 0

		if v.value == 0 then
			r = 0.3
			g = 0.3
			b = 0.3
		end

		love.graphics.setColor(r, g, b)
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
			if conn.weight * other.value> 0 then
				col = { 0, 0, 1 }
			end

			local mag = math.abs(other.value)
			col[1] = col[1] * mag
			col[2] = col[2] * mag
			col[3] = col[3] * mag

			love.graphics.setColor(col)
			love.graphics.setLineWidth(math.sigmoid(conn.weight) * 2)
			love.graphics.line(x1, y1, x2, y2)
		end
	end

	love.graphics.setLineWidth(2)
	love.graphics.pop()
end

function love.draw()
	love.graphics.setScissor(0, 0, 820, 620)
	world:draw()
	love.graphics.setScissor()

	love.graphics.setColor(CONF.FONT_COLOR)
	love.graphics.setFont(ui_font)
	love.graphics.printf(tostring(love.timer.getFPS()) .. " FPS", 16, 640, 800, "left")
	love.graphics.printf("Generation: " .. pop.generation, 16, 640 + 32, 800, "left")
	love.graphics.printf("Genome: " .. pop.current_genome, 16, 640 + 64, 800, "left")
	if pop.genomes[pop.current_genome] ~= nil then
		love.graphics.printf("Fitness: " .. math.floor(pop.genomes[pop.current_genome].fitness), 16, 640 + 96, 800, "left")

		draw_network(pop.genomes[pop.current_genome].network, 1200 - 350, 32, 1 / 2)
	end

	plot_fitness(1200 - 350, 352, 1 / 2)
	plot_generation(1200 - 350, 600, 1 / 2)
end
