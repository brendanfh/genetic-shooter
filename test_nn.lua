require "src.utils"
local NN = require "src.neuralnet"
local NeuralNetwork = NN.NeuralNetwork

local net = NeuralNetwork.new(4, 4)

net:activate({ 0, 1, 0, 1 })
local tmp = net:get_outputs()
for k, v in ipairs(tmp) do
	print(k, v)
end

net:add_connection(1, 5, 1, 0)
net:add_connection(2, 5, 1, 0)
net:add_connection(3, 5, 1, 0)
net:add_connection(4, 5, 1, 1)

net:activate({ 1, 1, 1, 1 })
tmp = net:get_outputs()
for k, v in ipairs(tmp) do
	print(k, v)
end

