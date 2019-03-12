local NN = require "src.neuralnet"
local NeuralNetwork = NN.NeuralNetwork

-- Globals
local Starting_Weights_Chance = 0.25
local Starting_Connection_Chance = 2.0
local Starting_Bias_Chance = 0.4
local Starting_Split_Chance = 0.5
local Starting_Enable_Chance = 0.2
local Starting_Disable_Chance = 0.4

local Reset_Weight_Chance = 0.9
local Crossover_Chance = 0.75

-- Need a global-ish innovation number, since that depends on the whole training, not just a single genome
local Current_Innovation = 1

local function Get_Next_Innovation()
	local tmp = Current_Innovation
	Current_Innovation = Current_Innovation + 1
	return tmp
end

-- N.E.A.T. genetic algorithm

local Gene = {}
local Gene_mt = { __index = Gene }

function Gene.new()
	local o = {
		to = 0;
		from = 0;
		weight = 0;
		enabled = true;
		innovation = 0;
	}

	setmetatable(o, Gene_mt)
	return o
end

function Gene:copy()
	local new = Gene.new()

	new.to = self.to
	new.from = self.from
	new.weight = self.weight
	new.enabled = self.enabled
	new.innovation = self.innovation

	return new
end


-- Genome class --

local Genome = {}
local Genome_mt = { __index = Genome }

function Genome.new(inputs, outputs)
	local o = {
		num_inputs = inputs + 1; -- We need one bias neuron that will always be 1
		num_outputs = outputs;
		genes = {};
		fitness = 0;
		network = {}; -- Neural Network
		high_neuron = inputs + outputs + 1; -- Highest numbered neuron in the genome

		mutations = { -- The different chances of mutating a particular part of the genome
			["weights"] = Starting_Weights_Chance; -- Chance of changing the weights
			["connection"] = Starting_Connection_Chance; -- Chance of changing the connections (add a gene)
			["bias"] = Starting_Bias_Chance; -- Chance of connecting to the bias
			["split"] = Starting_Split_Chance; -- Chance of splitting a gene and adding a neuron
			["enable"] = Starting_Enable_Chance; -- Chance of enabling a gene
			["disable"] = Starting_Disable_Chance; -- Chance of disablign a gene
		}
	}

	setmetatable(o, Genome_mt)
	return o
end

function Genome:add_gene(from, to, weight)
	local gene = Gene.new()
	gene.weight = weight
	gene.from = from
	gene.to = to
	gene.innovation = Get_Next_Innovation()

	table.insert(self.genes, gene)
end

function Genome:copy()
	local newG = Genome.new(self.num_inputs - 1, self.num_outputs)
	for g = 1, #self.genes do
		table.insert(newG.genes, self.genes[g]:copy())
	end

	newG.high_neuron = self.high_neuron

	for mut_name, val in pairs(self.mutations) do
		newG.mutations[mut_name] = val
	end

	return newG
end

function Genome:create_network()
	local net = NeuralNetwork.new(self.num_inputs, self.num_outputs)

	for i = 1, #self.genes do
		local gene = self.genes[i]
		print("----------------------")
		print(gene.innovation, gene.from, gene.to, gene.weight)

		if gene.enabled then
			if not net:has_neuron(gene.to) then
				net:create_neuron(gene.to)
			end

			net:add_connection(gene)

			if not net:has_neuron(gene.from) then
				net:create_neuron(gene.from)
			end
		end
	end

	self.network = net
end

function Genome:has_gene(from, to)
	for i = 1, #self.genes do
		local gene = self.genes[i]

		if (gene.to == to and gene.from == from)
			or (gene.to == from and gene.from == to) then
			return true
		end
	end

	return false
end

-- Randomly changes the genes (weights)
function Genome:mutate_weights()
	local change = 0.2

	for i = 1, #self.genes do
		local gene = self.genes[i]

		if math.random() < Reset_Weight_Chance then
			gene.weight = gene.weight + math.random() * change * 2 - change -- (-change, change)
		else
			gene.weight = math.random() * 4 - 2 -- Randomly change it to be in (-2, 2)
		end
	end
end

-- Randomly adds a new gene (connection)
function Genome:mutate_connections(connect_to_bias)
	local neuron1 = self:get_random_neuron(true) -- Could be Input
	local neuron2 = self:get_random_neuron(false) -- NOT an input

	if connect_to_bias then
		neuron1 = self.num_inputs -- This is going to be the id of the bias neuron
	end

	-- Cant go to itself
	if neuron1 == neuron2 then
		return
	end

	-- Output cant be input
	if (neuron1 > self.num_inputs and neuron1 <= self.num_inputs + self.num_outputs) then
		return
	end

	-- Cant both be inputs
	if neuron1 <= self.num_inputs and neuron2 <= self.num_inputs then
		return
	end

	-- Cant go to input
	if neuron2 <= self.num_inputs then
		return
	end

	if self:has_gene(neuron1, neuron2) then
		return
	end

	local weight = math.random() * 4 - 2
	assert(neuron1 ~= neuron2, "IN MUTATE CONNECTIONS")
	self:add_gene(neuron1, neuron2, weight)
end

-- Randomly splits a gene into 2 (adding a neuron in the process)
function Genome:mutate_neuron()
	if #self.genes == 0 then
		return
	end

	self.high_neuron = self.high_neuron + 1

	-- Get a random gene
	local gene = self.genes[math.random(1, #self.genes)]

	-- Skip the gene if it is not enabled
	if not gene.enabled then
		return
	end

	-- Disable the gene beacause we are about to add other to replace it
	gene.enabled = false

	local gene1 = gene:copy()
	gene1.from = self.high_neuron
	gene1.weight = 1.0
	gene1.innovation = Get_Next_Innovation()
	gene1.enabled = true

	assert(gene1.from ~= gene1.to, "IN MUTATE NEURON")

	table.insert(self.genes, gene1)

	local gene2 = gene:copy()
	gene2.to = self.high_neuron
	gene2.innovation = Get_Next_Innovation()
	gene2.enabled = true

	assert(gene2.from ~= gene2.to, "IN MUTATE NEURON")

	table.insert(self.genes, gene2)
end

-- Randomly turns on or off a gene, depending on the parameter
function Genome:mutate_enabled(enabled)
	local possible = {}
	for _, gene in ipairs(self.genes) do
		if gene.enabled == enabled then
			table.insert(possible, gene)
		end
	end

	if #possible == 0 then
		return
	end

	local gene = possible[math.random(1, #possible)]
	gene.enabled = not gene.enabled
end

function Genome:mutate()
	-- Randomize the rate that mutations can happen
	for mut_name, rate in pairs(self.mutations) do
		if math.random() < 0.5 then
			self.mutations[mut_name] = 0.96 * rate -- Slightly decrease rate
		else
			self.mutations[mut_name] = 1.04 * rate -- Slightly increase rate
		end
	end

	if math.random() < self.mutations["weights"] then
		self:mutate_weights()
	end

	-- Randomly use the mutation functions above to create a slightly different genome
	local prob = self.mutations["connection"]
	while prob > 0 do
		if math.random() < prob then
			self:mutate_connections(false)
		end

		prob = prob - 1
	end

	prob = self.mutations["bias"]
	while prob > 0 do
		if math.random() < prob then
			self:mutate_connections(true)
		end

		prob = prob - 1
	end

	prob = self.mutations["split"]
	while prob > 0 do
		if math.random() < prob then
			self:mutate_neuron()
		end

		prob = prob - 1
	end

	prob = self.mutations["enable"]
	while prob > 0 do
		if math.random() < prob then
			self:mutate_enabled(true)
		end

		prob = prob - 1
	end

	prob = self.mutations["disable"]
	while prob > 0 do
		if math.random() < prob then
			self:mutate_enabled(false)
		end

		prob = prob - 1
	end
end

function Genome:get_random_neuron(can_be_input)
	local genes = self.genes

	local neurons = {}

	if can_be_input then
		for i = 1, self.num_inputs do
			neurons[i] = true
		end
	end

	for o = 1, self.num_outputs do
		neurons[o + self.num_inputs] = true
	end

	for i = 1, #genes do
		if can_be_input or genes[i].to then
			neurons[genes[i].to] = true
		end
		if can_be_input or genes[i].from then
			neurons[genes[i].from] = true
		end
	end

	-- This array is not necessarily continuous, so we have to count them in a horrible way
	local cnt = 0
	for _, _ in pairs(neurons) do
		cnt = cnt + 1
	end

	local choice = math.random(1, cnt)

	-- Also, we have to index them in a horrible way (probably will change this later)

	for k, _ in pairs(neurons) do
		choice = choice - 1

		if choice == 0 then
			return k
		end
	end

	return 0
end

function Genome:crossover(other)
	-- Need to make sure that this instance has the better fitness
	local genome1 = self
	local genome2 = other

	if genome1.fitness < genome2.fitness then
		local tmp = genome1
		genome1 = genome2
		genome2 = tmp
	end

	local child = Genome.new(genome1.num_inputs - 1, genome1.num_outputs)

	-- Create a list of all the innovation numbers for the 2nd (worse) genome
	local innov2 = {}
	for i = 1, #genome2.genes do
		local gene = genome2.genes[i]
		innov2[gene.innovation] = gene
	end

	-- Create a list of the better innovation numbers, with a change of keeping the "bad" innovation
	for i = 1, #genome1.genes do
		local gene1 = genome1.genes[i]
		local gene2 = innov2[gene1.innovation]

		if gene2 ~= nil and math.random() > 0.5 and gene2.enabled then
			table.insert(child.genes, gene2:copy())
		else
			table.insert(child.genes, gene1:copy())
		end
	end

	child.high_neuron = math.max(genome1.high_neuron, genome2.high_neuron)

	return child
end

-- Population class --

local Population = {}
local Population_mt = { __index = Population }

function Population.new()
	local o = {
		genomes = {};
		generation = 0;
		current_genome = 0;
		high_fitness = 0;
		avg_fitness = 0;
	}

	setmetatable(o, Population_mt)
	return o
end

function Population:create_genomes(num, inputs, outputs)
	local genomes = self.genomes

	for i = 1, num do
		genomes[i] = Genome.new(inputs, outputs)
		genomes[i]:mutate()
	end
end

function Population:breed_genome()
	local genomes = self.genomes
	local child

	if math.random() < Crossover_Chance then
		local g1 = genomes[math.random(1, #genomes)]
		local g2 = genomes[math.random(1, #genomes)]
		child = g1:crossover(g2)
	else
		local g = genomes[math.random(1, #genomes)]
		child = g:copy()
	end

	child:mutate()

	return child
end

function Population:kill_worst()
	-- This might be backwards
	table.sort(self.genomes, function(a, b)
		return a.fitness > b.fitness
	end)

	local count = math.floor(3 * #self.genomes / 4)
	for _ = 1, count do
		table.remove(self.genomes) -- This removes the last (worst) genome
	end

	for i = 1, #self.genomes do
		self.genomes[i].fitness = 0
	end

	collectgarbage() -- Since we just freed a bunch of memory, best to do this now instead of letting it pile up
end

function Population:mate()
	local count = #self.genomes * 3

	-- Double the population size
	for _ = 1, count do
		table.insert(self.genomes, self:breed_genome())
	end


	self.generation = self.generation + 1
end

function Population:evolve()
	local evolve_test, finish_evolve

	-- First we need to calculate the fitnesses of every genome
	self.current_genome = 0
	function evolve_test(inputs, output_func, ...)
		if self.current_genome == 0 then
			self.current_genome = 1
			self.genomes[self.current_genome]:create_network()
		end

		if self.current_genome <= #self.genomes then
			-- Assumes genome has network generated
			local genome = self.genomes[self.current_genome]
			inputs[#inputs + 1] = 1 -- Bias neuron

			genome.network:activate(inputs)

			local outputs = genome.network:get_outputs()
			local fitness_change, cont = output_func(outputs, ...)

			genome.fitness = genome.fitness + fitness_change

			if cont then
				return evolve_test
			else
				self.current_genome = self.current_genome + 1
				if self.current_genome <= #self.genomes then
					self.genomes[self.current_genome]:create_network()
					return evolve_test
				else
					return finish_evolve
				end
			end
		else
			return finish_evolve
		end
	end

	-- Then we need to kill off the worst of them
	-- Then we breed more
	-- Rinse and repeat!
	function finish_evolve()
		self:kill_worst()
		self:mate()

		self.current_genome = 0
		return evolve_test
	end

	return evolve_test
end

return {
	Gene = Gene;
	Genome = Genome;
	Population = Population;
}
