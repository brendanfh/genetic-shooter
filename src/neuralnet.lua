-- Simple neural network implementation (perceptron)

local Neuron = {}
function Neuron.new()
	local o = {
		value = 0;
		inputs = {};
		dirty = false; -- Means that the value of the neuron has to be recalculated
	}
	return o
end


-- Every node has a ID which is used as the key to the neurons array

local NeuralNetwork = {}
local NeuralNetwork_mt = { __index = NeuralNetwork }

function NeuralNetwork.new(num_inputs, num_outputs)
	local o = {
		neurons = {};
		num_inputs = num_inputs;
		num_outputs = num_outputs;
		next_neuron = num_inputs + num_outputs + 1;
	}

	-- 1 to num_inputs are input nodes
	for i = 1, num_inputs do
		o.neurons[i] = Neuron.new()
	end

	-- num_inputs + 1 to num_inputs + num_outputs are output nodes
	for i = num_inputs + 1, num_inputs + num_outputs do
		o.neurons[i] = Neuron.new()
	end

	setmetatable(o, NeuralNetwork_mt)
	return o
end

function NeuralNetwork:add_connection(from, to, weight, id)
	local neurons = self.neurons

	if type(from) == "table" then
		assert(from.to ~= from.from, "NEURON GOING TO ITSELF")
		table.insert(neurons[from.to].inputs, from)
	else
		table.insert(neurons[to].inputs, {
			to = to;
			from = from;
			weight = weight;
			id = id;
		})
	end
end

function NeuralNetwork:add_neuron()
	self.neurons[self.next_neuron] = Neuron.new()
	self.next_neuron = self.next_neuron + 1
	return self.next_neuron - 1
end

function NeuralNetwork:create_neuron(num)
	if self.next_neuron < num then
		self.next_neuron = num + 1 -- Makes sure the next neuron won't override previous neurons
	end

	self.neurons[num] = Neuron.new()
end

function NeuralNetwork:has_neuron(num)
	return self.neurons[num] ~= nil
end

function NeuralNetwork:activate(inputs)
	local ns = self.neurons

	for i = 1, self.num_inputs do
		assert(inputs[i] ~= nil, "INPUT WAS NIL")
		self.neurons[i].value = inputs[i]
	end

	for i, _ in pairs(ns) do
		if i > self.num_inputs then
			ns[i].dirty = true
		end
	end

	-- Iterate backwards since the hidden nodes are going to be at the end of the array
	for i, _ in pairs(ns) do
		if ns[i].dirty then
			self:activate_neuron(i)
		end
	end
end

function NeuralNetwork:activate_neuron(neuron)
	local n = self.neurons[neuron]

	if not n.dirty then return end

	if #n.inputs > 0 then
		local sum = 0
		for i = 1, #n.inputs do
			local e = n.inputs[i]
			if self.neurons[e.from].dirty then
				self:activate_neuron(e.from)
			end

			sum = sum + self.neurons[e.from].value * e.weight
		end

		n.value = math.sigmoid(sum)
	else
		n.value = 0
	end

	n.dirty = false
end

function NeuralNetwork:get_outputs()
	local ret = {}

	for i = 1, self.num_outputs do
		ret[i] = self.neurons[i + self.num_inputs].value
	end

	return ret
end

return {
	NeuralNetwork = NeuralNetwork;
	Neuron = Neuron;
}
