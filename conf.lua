function love.conf(t)
	t.window.title = "Maching Learning Game"

	-- Window will be small since the graphics are not very important
	t.window.width = 640
	t.window.height = 480

	t.window.vsync = true

	t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = false
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
end

local KEYMAP = {
	MOVE_UP    = "w";
	MOVE_DOWN  = "s";
	MOVE_LEFT  = "a";
	MOVE_RIGHT = "d";
	FIRE_UP    = "up";
	FIRE_DOWN  = "down";
	FIRE_LEFT  = "left";
	FIRE_RIGHT = "right";
}

local BACK_COLOR = { 0.8, 0.8, 0.8 }
local PLAYER_COLOR = { 0.3, 0.3, 0.7 }
local ENEMY_COLOR = { 1, 0, 0 }
local BULLET_COLOR = { 0.6, 0.6, 1.0 }

return {
	KEYS = KEYMAP;

	BACK_COLOR = BACK_COLOR;
	PLAYER_COLOR = PLAYER_COLOR;
	ENEMY_COLOR = ENEMY_COLOR;
	BULLET_COLOR = BULLET_COLOR;
}
