local CONF = require "conf"
local world_mod = require "src.world"
local Input = require "src.input"
local Gen = require "src.genetics"
require "src.data"
local Trainer = (require "src.trainer").Trainer

local World = world_mod.World
local Wall = world_mod.Wall
local Population = Gen.Population

local world, input, pop, trainer

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

trainer = Trainer.new(pop, world, input)
trainer:initialize_training()
trainer.max_speed = 360
trainer:change_speed(360)

while pop.generation <= 100 do
	trainer:update(1 / 60)
end
