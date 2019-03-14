local NN = require "src.neuralnet"
local CONF = require "conf"
local NeuralNetwork = NN.NeuralNetwork

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
		high_neuron = inputs + 1; -- Highest numbered neuron in the genome

		mutations = { -- The different chances of mutating a particular part of the genome
			["weights"] = CONF.Starting_Weights_Chance; -- Chance of changing the weights
			["connection"] = CONF.Starting_Connection_Chance; -- Chance of changing the connections (add a gene)
			["bias"] = CONF.Starting_Bias_Chance; -- Chance of connecting to the bias
			["split"] = CONF.Starting_Split_Chance; -- Chance of splitting a gene and adding a neuron
			["enable"] = CONF.Starting_Enable_Chance; -- Chance of enabling a gene
			["disable"] = CONF.Starting_Disable_Chance; -- Chance of disablign a gene
		}
	}

	setmetatable(o, Genome_mt)
	return o
end

function Genome:add_gene(from, to, weight)
	if from > to then return end

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

		if gene.to == to and gene.from == from then
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

		if math.random() < CONF.Reset_Weight_Chance then
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

	-- Must go to a bigger neuron
	if neuron2 < neuron1 then
		local tmp = neuron1
		neuron1 = neuron2
		neuron2 = tmp
	end

	-- Output cant be input
	if neuron1 >= CONF.MAX_NEURONS - self.num_outputs then
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

	local n1 = gene.from
	local n2 = self.high_neuron
	local n3 = gene.to

	local tmp
	if n1 > n2 then
		tmp = n1
		n1 = n2
		n2 = tmp
	end

	if n2 > n3 then
		tmp = n3
		n3 = n2
		n2 = tmp
	end

	local gene1 = gene:copy()
	gene1.from = n2
	gene1.to = n3
	gene1.weight = 1.0
	gene1.innovation = Get_Next_Innovation()
	gene1.enabled = true

	table.insert(self.genes, gene1)

	local gene2 = gene:copy()
	gene2.from = n1
	gene2.to = n2
	gene2.innovation = Get_Next_Innovation()
	gene2.enabled = true

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

	prob = self.mutations["split"]
	while prob > 0 do
		if math.random() < prob then
			self:mutate_neuron()
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
		neurons[CONF.MAX_NEURONS - o] = true
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
		genome_count = 0;
		generation = 0;
		max_innovations = 0;
		current_genome = 0;
		high_fitness = 0;
		total_fitness = 0;
		avg_fitness = 0;
	}

	setmetatable(o, Population_mt)
	return o
end

function Population:create_genomes(num, inputs, outputs)
	local genomes = self.genomes
	self.genome_count = num

	for i = 1, num do
		genomes[i] = Genome.new(inputs, outputs)
		genomes[i]:mutate()
	end
end

function Population:breed_genome(max_genome)
	local genomes = self.genomes
	max_genome = max_genome or #genomes

	local child

	if math.random() < CONF.Crossover_Chance then
		local g1 = genomes[math.random(1, max_genome)]
		local g2 = genomes[math.random(1, max_genome)]
		child = g1:crossover(g2)
	else
		local g = genomes[math.random(1, max_genome)]
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

	local count = math.floor(#self.genomes * (1 - CONF.GENOME_THRESHOLD))
	for _ = 1, count do
		table.remove(self.genomes) -- This removes the last (worst) genome
	end

	for i = 1, #self.genomes do
		self.genomes[i].fitness = 0
	end

	collectgarbage() -- Since we just freed a bunch of memory, best to do this now instead of letting it pile up
end

function Population:mate()
	local start_count = #self.genomes
	local count = self.genome_count - #self.genomes

	for _ = 1, count do
		table.insert(self.genomes, self:breed_genome(start_count))
	end

	self.generation = self.generation + 1
end

function Population:training_step(inputs, output_func, _, ...)
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
			return self.training_step
		else
			if genome.fitness > self.high_fitness then
				self.high_fitness = genome.fitness
			end

			self.total_fitness = self.total_fitness + genome.fitness
			self.avg_fitness = self.total_fitness / self.current_genome

			self.current_genome = self.current_genome + 1

			if self.current_genome <= #self.genomes then
				self.genomes[self.current_genome]:create_network()
				return self.training_step
			else
				return self.evolve
			end
		end
	else
		return self.evolve
	end
end

function Population:evolve(_, _, generation_step, ...)
	generation_step(self.avg_fitness, self.high_fitness, ...)
	self:kill_worst()
	self:mate()

	self.current_genome = 0
	self.high_fitness = 0
	self.avg_fitness = 0
	self.total_fitness = 0

	return self.training_step
end

function Population:start_training()
	-- First we need to calculate the fitnesses of every genome
	-- Then we need to kill off the worst of them
	-- Then we breed more
	-- Rinse and repeat!

	self.current_genome = 0
	return self.training_step
end

return {
	Gene = Gene;
	Genome = Genome;
	Population = Population;
}
