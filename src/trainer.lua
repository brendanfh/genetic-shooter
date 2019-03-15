local CONF = require "conf"

local Trainer = {}
local Trainer_mt = { __index = Trainer }

function Trainer.new(population, world, input)
	local o = {
		world = world;
		player = world.player;
		input = input;
		population = population;

		population_step = nil;
		after_inputs_func = nil;
		generation_step_func = nil;

		speed = 1;
		max_speed = 60;
	}

	setmetatable(o, Trainer_mt)
	return o
end

function Trainer:initialize_training()
	self.world:spawn_enemies(1)

	self.population_step = self.population:start_training()

	self.after_inputs_func = function(...)
		return self:after_inputs(...)
	end

	self.pre_evolution_func = function(...)
		return self:pre_evolution(...)
	end

	self.post_evolution_func = function(...)
		return self:post_evolution(...)
	end
end

function Trainer:get_inputs()
	local dists = self.player:get_distances(self.world)

	local inputs = {}
	for i = 1, 16 do
		local v1 = dists[i * 2]
		local v2 = dists[(i * 2 + 1) % 32]
		local v3 = dists[(i * 2 - 1) % 32]

		inputs[i] = 1 - ((0.5 * v1 + 0.25 * v2 + 0.25 * v3) / (CONF.ENEMY_SIZE * CONF.PLAYER_VISION_DISTANCE))
	end

	return inputs
end

function Trainer:after_inputs(inputs, dt, _, gen_stats)
	-- Make sure the player is considered alive at the start of every turn
	self.player.alive = true

	if inputs[1] > 0.35 then self.input:keydown("w")     else self.input:keyup("w") end
	if inputs[2] > 0.35 then self.input:keydown("s")     else self.input:keyup("s") end
	if inputs[3] > 0.35 then self.input:keydown("a")     else self.input:keyup("a") end
	if inputs[4] > 0.35 then self.input:keydown("d")     else self.input:keyup("d") end
	if inputs[5] > 0.35 then self.input:keydown("up")    else self.input:keyup("up") end
	if inputs[6] > 0.35 then self.input:keydown("down")  else self.input:keyup("down") end
	if inputs[7] > 0.35 then self.input:keydown("left")  else self.input:keyup("left") end
	if inputs[8] > 0.35 then self.input:keydown("right") else self.input:keyup("right") end

	local last_x     = self.player.x
	local last_y     = self.player.y
	local last_kills = self.player.kills

	self.world:update(dt, self.input)

	local fitness = 0

	local dist = math.sqrt(math.sqrDist(last_x, last_y, self.player.x, self.player.y))
	fitness = fitness + dist * CONF.POINTS_PER_MOVEMENT

	fitness = fitness + (self.player.shot and CONF.POINTS_PER_BULLET or 0)
	self.player.shot = false

	if self.player.kills ~= last_kills then
		fitness = fitness + CONF.POINTS_PER_KILL * (self.player.kills - last_kills)
	end

	if not self.player.alive or self.world:get_count{ "Enemy" } == 0 then
		self.world:kill_all{ "Bullet", "Enemy" }

		if self.player.alive then
			fitness = fitness + CONF.POINTS_PER_ROUND_END
			self.world:next_round()
		else
			gen_stats:add_point(self.population.genomes[self.population.current_genome].fitness)
			self.world:reset()
		end

		self.world:spawn_enemies(self.world.round)
	end

	return fitness, self.player.alive
end

function Trainer:pre_evolution(avg, high, _, stats, _)
	stats:add_point(avg)
	self.population:save(CONF.SAVE_FILE)

	print("FINISHED GENERATION: " .. self.population.generation .. " | Stats: ")
	print("        Average: " .. tostring(avg))
	print("        Highest: " .. tostring(high))
	print("--------------------------------------------------------------------")
end

function Trainer:post_evolution(_, _, gen_stats)
	gen_stats:clear()
end

function Trainer:update(...)
	local inputs = self:get_inputs()

	for _ = 1, self.speed do
		self.population_step = self.population_step(
			self.population,
			inputs,
			self.after_inputs_func,
			{ self.pre_evolution_func, self.post_evolution_func },
			...
		)
	end
end

function Trainer:change_speed(delta)
	self.speed = self.speed + delta

	if self.speed < 1 then
		self.speed = 1
	end

	if self.speed > self.max_speed then
		self.speed = self.max_speed
	end
end

return {
	Trainer = Trainer;
}
