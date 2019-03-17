require "src.utils"

local CONF = require "conf"

-- BULLET --

local Bullet = {}
local Bullet_mt = { __index = Bullet }
Bullet.ENTITY_TYPE = "Bullet"

function Bullet.new(x, y, vx, vy)
	local o = {
		x = x;
		y = y;
		vx = vx;
		vy = vy;
		life = 1.5;
		alive = true;
	}

	setmetatable(o, Bullet_mt)
	return o
end

function Bullet:update(dt, world)
	world:move_entity(self, self.vx * dt, self.vy * dt)

	self.life = self.life - dt
	if self.life <= 0 then
		world:remove_entity(self)
	end
end

function Bullet:collide(other, _, _, world)
	if other.ENTITY_TYPE == "Enemy" then
		other.alive = false
		world:remove_entity(other)
		world:remove_entity(self)

		-- Reward the player a kill
		world.player.kills = world.player.kills + 1
	end
end

function Bullet:get_rect()
	local R = 8 * .5
	return { self.x - R, self.y - R, R * 2, R * 2 }
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
Player.ENTITY_TYPE = "Player"

function Player.new()
	local o = {
		x = 400;
		y = 300;
		r = 20;
		alive = true;
		fire_cooldown = 0;

		distances = {};
		shot = false;
		kills = 0;
	}

	setmetatable(o, Player_mt)
	return o
end

function Player:update(dt, world, input)
	local dx = 0
	local dy = 0

	local SPEED = CONF.PLAYER_SPEED

	if input.move_up    then dy = dy - SPEED end
	if input.move_down  then dy = dy + SPEED end
	if input.move_left  then dx = dx - SPEED end
	if input.move_right then dx = dx + SPEED end

	world:move_entity(self, dx * dt, dy * dt)

	if self.fire_cooldown <= 0 then
		local firex = 0
		local firey = 0

		local FIRE_SPEED = 300

		if input.fire_up    then firey = firey - 1 end
		if input.fire_down  then firey = firey + 1 end
		if input.fire_left  then firex = firex - 1 end
		if input.fire_right then firex = firex + 1 end

		if firex ~= 0 or firey ~= 0 then
			self.fire_cooldown = .1

			local d = math.sqrt(math.sqrDist(0, 0, firex, firey))
			firex = FIRE_SPEED * firex / d
			firey = FIRE_SPEED * firey / d

			self:fire(firex, firey, world)
		end
	else
		self.fire_cooldown = self.fire_cooldown - dt
	end

	self.distances = self:get_distances(world)
end

function Player:fire(vx, vy, world)
	local bullet = Bullet.new(self.x, self.y, vx, vy)
	self.shot = true
	world:add_entity(bullet)
end

function Player:get_rect()
	return { self.x - self.r, self.y - self.r, self.r * 2, self.r * 2 }
end

function Player:collide(other, dx, dy, world)
	if other.ENTITY_TYPE == "Wall" then
		self.x = self.x - dx
		self.y = self.y - dy
	end
end

function Player:get_distances(world)
	local ret = {}

	for i = 0, CONF.PLAYER_VISION_SEGMENTS - 1 do
		local a = i * 2 * math.pi / CONF.PLAYER_VISION_SEGMENTS
		local dx = math.cos(a) * CONF.ENEMY_SIZE
		local dy = math.sin(a) * CONF.ENEMY_SIZE

		local hit_entity = false
		for j = 1, CONF.PLAYER_VISION_DISTANCE do
			if hit_entity then break end

			local tx = self.x + dx * j
			local ty = self.y + dy * j

			for _, e in ipairs(world.entities) do
				if (e.ENTITY_TYPE == "Enemy" or e.ENTITY_TYPE == "Wall") and math.rectcontains(e:get_rect(), tx, ty) then
					local ent_rect = e:get_rect()

					local toggle = false
					for _ = 0, 20 do
						dx = dx / 2
						dy = dy / 2
						tx = tx - dx
						ty = ty - dy

						if math.rectcontains(ent_rect, tx, ty) == toggle then
							dx = dx * -1
							dy = dy * -1
							toggle = not toggle
						end
					end

					local d = math.sqrt(math.sqrDist(self.x, self.y, tx, ty))

					if e.ENTITY_TYPE == "Wall" then
						d = -d
					end

					table.insert(ret, d)
					hit_entity = true
					break
				end
			end
		end

		if not hit_entity then
			table.insert(ret, CONF.PLAYER_VISION_DISTANCE * CONF.ENEMY_SIZE)
		end
	end

	return ret
end

function Player:draw()
	love.graphics.setColor(CONF.PLAYER_COLOR)
	love.graphics.circle("fill", self.x, self.y, self.r)

	love.graphics.setColor(CONF.PLAYER_VISION_COLOR)
	for i = 0, CONF.PLAYER_VISION_SEGMENTS - 1 do
		local a = i * 2 * math.pi / CONF.PLAYER_VISION_SEGMENTS
		local dx = math.cos(a)
		local dy = math.sin(a)

		love.graphics.line(
			self.x, self.y,
			self.x + dx * CONF.PLAYER_VISION_DISTANCE * CONF.ENEMY_SIZE,
			self.y + dy * CONF.PLAYER_VISION_DISTANCE * CONF.ENEMY_SIZE
		)

		if math.abs(self.distances[i + 1]) > 0 then
			local d = math.abs(self.distances[i + 1])
			love.graphics.circle("fill", self.x + dx * d, self.y + dy * d, 8)
		end
	end
end

-- ENEMY --

local Enemy = {}
local Enemy_mt = { __index = Enemy }
Enemy.ENTITY_TYPE = "Enemy"

function Enemy.new(x, y)
	local o = {
		x = x;
		y = y;
		size = CONF.ENEMY_SIZE;
		alive = true;
	}

	setmetatable(o, Enemy_mt)
	return o
end

function Enemy:update(dt, world)
	local player = world.player

	local a = math.atan2(player.y - self.y, player.x - self.x)
	local dx = math.cos(a)
	local dy = math.sin(a)

	local SPEED = CONF.ENEMY_SPEED
	world:move_entity(self, dx * dt * SPEED, dy * dt * SPEED)
end

function Enemy:get_rect()
	return { self.x - self.size, self.y - self.size, self.size * 2, self.size * 2 }
end

function Enemy:collide(other, dx, dy, world)
	-- if other.ENTITY_TYPE == "Enemy" then
	-- 	self.x = self.x - dx
	-- 	self.y = self.y - dy
	-- end

	if other.ENTITY_TYPE == "Player" then
		other.alive = false
		world:remove_entity(self)
	end
end

function Enemy:draw()
	love.graphics.setColor(CONF.ENEMY_COLOR)
	love.graphics.rectangle("fill", unpack(self:get_rect()))
end


-- Wall class --

local Wall = {}
local Wall_mt = { __index = Wall }
Wall.ENTITY_TYPE = "Wall"

function Wall.new(x, y, w, h)
	local o = {
		x = x;
		y = y;
		w = w;
		h = h;
	}

	setmetatable(o, Wall_mt)
	return o
end

function Wall:update(dt)
end

function Wall:draw()
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", unpack(self:get_rect()))
end

function Wall:get_rect()
	return { self.x, self.y, self.w, self.h }
end

function Wall:collide(other, dx, dy, world)
end


-- WORLD --

local World = {}
local World_mt = { __index = World }
function World.new(player)
	if player == nil then
		player = Player.new()
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
		round = 1;
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

	-- if self:get_count{ "Enemy" } == 0 and self.player.alive then
	-- 	self:next_round()
	-- 	self:spawn_enemies(self.round)
	-- end
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

	if pos == 0 then return end

	table.remove(self.entities, pos)
end

-- Assumes ent has x, y and get_rect
function World:move_entity(ent, dx, dy)
	ent.x = ent.x + dx
	if math.rectintersects(self.player:get_rect(), ent:get_rect()) then
		ent:collide(self.player, dx, 0, self)
	end
	for _, e in ipairs(self.entities) do
		if e.id ~= ent.id then
			if math.rectintersects(e:get_rect(), ent:get_rect()) then
				ent:collide(e, dx, 0, self)
			end
		end
	end

	ent.y = ent.y + dy
	if math.rectintersects(self.player:get_rect(), ent:get_rect()) then
		ent:collide(self.player, dx, 0, self)
	end
	for _, e in ipairs(self.entities) do
		if e.id ~= ent.id then
			if math.rectintersects(e:get_rect(), ent:get_rect()) then
				ent:collide(e, 0, dy, self)
			end
		end
	end
end

function World:get_count(types)
	local cnt = 0
	for _, v in ipairs(self.entities) do
		if table.contains(types, v.ENTITY_TYPE) then
			cnt = cnt + 1
		end
	end

	return cnt
end

function World:kill_all(types)
	local i = 0

	-- Because we are deleting from the list as we go, we have to
	-- do this iteratively
	repeat
		i = i + 1

		if self.entities[i] ~= nil then
			if table.contains(types, self.entities[i].ENTITY_TYPE) then
				self:remove_entity(self.entities[i])
				i = i - 1
			end
		end
	until i == #self.entities
end

function World:spawn_enemies(count)
	for _ = 1, count do
		local found = false
		local x, y
		repeat
			local vert = math.random(2) > 1
			local tmp = math.random(2) > 1
			x = math.random(vert and 100 or 800) + (vert and (tmp and 600 or 0) or 0)

			vert = not vert
			tmp = math.random(2) > 1
			y = math.random(vert and 100 or 600) + (vert and (tmp and 400 or 0) or 0)

			if math.sqrDist(self.player.x, self.player.y, x, y) > 80 * 80 then
				found = true
			end
		until found

		local enemy = Enemy.new(x, y)
		self:add_entity(enemy)
	end
end

function World:next_round()
	self.round = self.round + 1
end

function World:reset()
	self.round = 1
	self.player.x = 400
	self.player.y = 300
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
	Enemy = Enemy;
	Bullet = Bullet;
	Wall = Wall;
}
