local CONF = require "conf"
local KEYS = CONF.KEYS

-- INPUT --

local Input = {}
function Input.new()
	local o = {
		move_up    = false;
		move_down  = false;
		move_left  = false;
		move_right = false;
		fire_up    = false;
		fire_down  = false;
		fire_left  = false;
		fire_right = false;
	}

	local mt = { __index = Input }
	setmetatable(o, mt)

	return o
end

function Input:keydown(key)
	if     key == KEYS.MOVE_UP    then self.move_up    = true
	elseif key == KEYS.MOVE_DOWN  then self.move_down  = true
	elseif key == KEYS.MOVE_LEFT  then self.move_left  = true
	elseif key == KEYS.MOVE_RIGHT then self.move_right = true
	elseif key == KEYS.FIRE_UP    then self.fire_up    = true
	elseif key == KEYS.FIRE_DOWN  then self.fire_down  = true
	elseif key == KEYS.FIRE_LEFT  then self.fire_left  = true
	elseif key == KEYS.FIRE_RIGHT then self.fire_right = true
	end
end

function Input:keyup(key)
	if     key == KEYS.MOVE_UP    then self.move_up    = false
	elseif key == KEYS.MOVE_DOWN  then self.move_down  = false
	elseif key == KEYS.MOVE_LEFT  then self.move_left  = false
	elseif key == KEYS.MOVE_RIGHT then self.move_right = false
	elseif key == KEYS.FIRE_UP    then self.fire_up    = false
	elseif key == KEYS.FIRE_DOWN  then self.fire_down  = false
	elseif key == KEYS.FIRE_LEFT  then self.fire_left  = false
	elseif key == KEYS.FIRE_RIGHT then self.fire_right = false
	end
end

return Input
