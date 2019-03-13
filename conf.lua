-- Window will be small since the graphics are not very important
local WINDOW_WIDTH = 800
local WINDOW_HEIGHT = 600

function love.conf(t)
	t.window.title = "Maching Learning Game"

	t.window.width = WINDOW_WIDTH
	t.window.height = WINDOW_HEIGHT

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

return {
	WINDOW_WIDTH = WINDOW_WIDTH;
	WINDOW_HEIGHT = WINDOW_HEIGHT;
	KEYS = KEYMAP;

	BACK_COLOR = { 0.8, 0.8, 0.8 };
	PLAYER_COLOR = { 0.3, 0.3, 0.7 };
	ENEMY_COLOR = { 1.0, 0.0, 0.0 };
	BULLET_COLOR = { 0.6, 0.6, 1.0 };

	PLAYER_VISION_SEGMENTS = 32;
	PLAYER_VISION_DISTANCE = 20;

	ENEMY_SIZE = 14;

	MAX_NEURONS = 1024;
}
