require "src.utils"

local CONF = require "conf"

-- BULLET --

local Bullet = {}
local Bullet_mt = { __index = Bullet }
function Bullet:new(x, y, vx, vy)
	local o = {
		x = x;
		y = y;
		vx = vx;
		vy = vy;
		life = 100;
		alive = true;
	}
	
	setmetatable(o, Bullet_mt)
	return o
end

function Bullet:update(dt)
	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt

	self.life = self.life - 1
	if self.life <= 0 then
		self.alive = false
	end
end

function Bullet:draw()
	local R = 8
	local cx = self.x
	local cy = self.y
	local vx = self.vx
	local vy = self.vy

	local a
	if vx == 0 and vy == 0 then
		a = 0
	else
		a = math.atan2(vy, vx)
	end

	local sin = math.sin
	local cos = math.cos
	local pi = math.pi

	local pnts = {
		cx + R * cos(a + 0 * pi / 3), cy + R * sin(a + 0 * pi / 3),
		cx + R * cos(a + 2 * pi / 3), cy + R * sin(a + 2 * pi / 3),
		cx + R * cos(a + 4 * pi / 3), cy + R * sin(a + 4 * pi / 3)
	}

	love.graphics.setColor(CONF.BULLET_COLOR)
	love.graphics.polygon("fill", pnts)
end

-- PLAYER --

local Player = {}
local Player_mt = { __index = Player }
function Player:new()
	local o = {
		x = 0;
		y = 0;
		r = 16;
		fire_cooldown = 0;
	}
	
	setmetatable(o, Player_mt)
	return o
end

function Player:update(dt, world, input)
	local dx = 0
	local dy = 0

	local SPEED = 150

	if input.move_up    then dy = dy - SPEED end
	if input.move_down  then dy = dy + SPEED end
	if input.move_left  then dx = dx - SPEED end
	if input.move_right then dx = dx + SPEED end

	self.x = self.x + dx * dt
	self.y = self.y + dy * dt

	if self.fire_cooldown <= 0 then
		self.fire_cooldown = 10
		local firex = 0
		local firey = 0

		local FIRE_SPEED = 300
		
		if input.fire_up    then firey = firey - 1 end
		if input.fire_down  then firey = firey + 1 end
		if input.fire_left  then firex = firex - 1 end
		if input.fire_right then firex = firex + 1 end

		if firex ~= 0 or firey ~= 0 then
			local d = math.sqrt(math.sqrDist(0, 0, firex, firey))
			firex = FIRE_SPEED * firex / d
			firey = FIRE_SPEED * firey / d

			self:fire(firex, firey, world)
		end
	else
		self.fire_cooldown = self.fire_cooldown - 1
	end
end

function Player:fire(vx, vy, world)
	local bullet = Bullet:new(self.x, self.y, vx, vy)
	world:add_entity(bullet)	
end

function Player:draw()
	love.graphics.setColor(CONF.PLAYER_COLOR)
	love.graphics.circle("fill", self.x, self.y, self.r)
end

-- WORLD --

local World = {}
local World_mt = { __index = World }
function World:new(player)
	if player == nil then
		player = Player:new()
	end

	local o = {
		--[[
		Entities are expected to have the following prototype:
			(string) id
			(boolean) alive
			(function(dt, world)) update
			(function) draw
		--]]
		entities = {};

		player = player;
	}

	setmetatable(o, World_mt)

	--Return both world and player in case we made the player in the constructor
	return o, player
end

function World:update(dt, input)
	for _, e in ipairs(self.entities) do
		e:update(dt, self)
	end

	self.player:update(dt, self, input)
end

function World:add_entity(ent)
	local id = math.genuuid()
	ent.id = id

	table.insert(self.entities, ent)
end

function World:remove_entity(ent_or_id)
	local id = ent_or_id
	if type(id) == "table" then
		id = id.id
	end

	local pos = 0
	for p, e in ipairs(self.entities) do
		if e.id == id then
			pos = p
			break
		end
	end
	
	table.remove(self.entities, pos)
end

function World:draw()
	for _, e in ipairs(self.entities) do
		e:draw()
	end

	self.player:draw()
end

return {
	World = World;
	Player = Player;
	Bullet = Bullet;
}
