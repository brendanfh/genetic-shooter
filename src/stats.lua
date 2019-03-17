
local Stats = {}
local Stats_mt = { __index = Stats }

function Stats.new(data)
	data = data or {}

	local o = {
		data = data;

		max = 0;
		min = 0;
		rng = 0;
		avg = 0;
		stddev = 0;
	}

	setmetatable(o, Stats_mt)
	return o
end

function Stats:add_point(d)
	table.insert(self.data, d)
end

function Stats:clear()
	self.data = {}
end

function Stats:calculate()
	if #self.data == 0 then
		self.max = 0
		self.min = 0
		self.avg = 0
		self.stddev = 0
		self.rng = 0
		return
	end

	local sum = 0
	self.max = nil
	self.min = nil
	for _, v in ipairs(self.data) do
		if self.max == nil then
			self.max = v
		else
			if v > self.max then
				self.max = v
			end
		end

		if self.min == nil then
			self.min = v
		else
			if v < self.min then
				self.min = v
			end
		end

		sum = sum + v
	end

	self.avg = sum / #self.data
	self.rng = self.max - self.min

	local diff_sum = 0
	for _, v in ipairs(self.data) do
		diff_sum = diff_sum + (self.avg - v) ^ 2
	end
	self.stddev = diff_sum / #self.data
end

function Stats:get_points(x, y, w, h)
	self:calculate()

	local low = y + h

	local delta
	if #self.data == 1 then
		delta = 0
	else
		delta = w / (#self.data - 1)
	end

	local points = {}

	for i, v in ipairs(self.data) do
		table.insert(points, { (i - 1) * delta + x, low - h * ((v - self.min) / self.rng) })
	end

	return points
end

return {
	Stats = Stats;
}
