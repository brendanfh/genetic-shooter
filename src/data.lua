local CONF = require "conf"
local gen_mod = require "src.genetics"
local Population = gen_mod.Population

local save_file_safe = false

local function file_exists(path)
	local file = io.open(path, "r")
	if file ~= nil then
		file:close()
		return true
	else
		return false
	end
end

function Population:save(path)
	local real_path = path .. "_GEN_" .. tostring(self.generation)

	if file_exists(real_path) and not save_file_safe then
		local e = 1
		local tmp

		repeat
			tmp = path .. "_" .. tostring(e)
			e = e + 1
		until not file_exists(tmp .. "_GEN_1")

		real_path = tmp .. "_GEN_" .. tostring(self.generation)

		-- Override the configured save file since it already exists
		CONF.SAVE_FILE = tmp
		save_file_safe = true
	end

	local file = io.open(real_path, "w")

	file:write(self.genome_count .. "\n")
	file:write(self.generation .. "\n")
	file:write("0\n")

	for _, genome in ipairs(self.genomes) do
		file:write((genome.num_inputs - 1).. " " .. genome.num_outputs .. " " .. genome.high_neuron .. "\n")
		file:write(genome.mutations["weights"] .. " ")
		file:write(genome.mutations["connection"] .. " ")
		file:write(genome.mutations["bias"] .. " ")
		file:write(genome.mutations["split"] .. " ")
		file:write(genome.mutations["enable"] .. " ")
		file:write(genome.mutations["disable"] .. "\n")

		file:write(#genome.genes .. "\n")

		for _, gene in ipairs(genome.genes) do
			file:write(gene.weight .. " " .. gene.from .. " " .. gene.to .. " " .. gene.innovation .. "\n")
		end
	end

	file:close()
end

function Population.load(path)
	local file = io.open(path, "r")

	local pop = Population.new()

	pop.genome_count = file:read("*n")
	pop.generation = file:read("*n")
	pop.current_genome = file:read("*n")

	for i = 1, pop.genome_count do
		local ins, outs = file:read("*n", "*n")
		pop:create_empty_genome(ins, outs)

		local genome = pop.genomes[i]
		genome.high_neuron = file:read("*n")
		genome.mutations["weights"] = file:read("*n")
		genome.mutations["connection"] = file:read("*n")
		genome.mutations["bias"] = file:read("*n")
		genome.mutations["split"] = file:read("*n")
		genome.mutations["enable"] = file:read("*n")
		genome.mutations["disable"] = file:read("*n")

		local num_genes = file:read("*n")

		for _ = 1, num_genes do
			local from, to, weight, innov
			weight = file:read("*n")
			from = file:read("*n")
			to = file:read("*n")
			innov = file:read("*n")

			genome:add_gene(from, to, weight, innov)
		end
	end

	file:close()

	return pop
end
