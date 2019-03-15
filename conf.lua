-- Window will be small since the graphics are not very important
local WINDOW_WIDTH = 1200
local WINDOW_HEIGHT = 800

local love = love or {}
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
	-- GENERAL PROPERTIES
	LOAD_FILE = "./saved/TERM_1_GEN_14";
	SAVE_FILE = "./saved/TERM";

	WINDOW_WIDTH = WINDOW_WIDTH;
	WINDOW_HEIGHT = WINDOW_HEIGHT;
	KEYS = KEYMAP;

	-- COLOR PROPERTIES

	BACK_COLOR = { 0.1, 0.1, 0.15 };
	FONT_COLOR = { 1.0, 1.0, 1.0 };

	PLAYER_COLOR = { 0.7, 0.7, 0.96 };
	PLAYER_VISION_COLOR = { 0.7, 0.7, 0.7 };
	ENEMY_COLOR = { 1.0, 0.0, 0.0 };
	BULLET_COLOR = { 0.6, 0.6, 1.0 };

	-- BEHAVIOR PROPERTIES

	PLAYER_VISION_SEGMENTS = 32;
	PLAYER_VISION_DISTANCE = 20;

	ENEMY_SIZE = 14;

	-- GENETIC PROPERTIES

	MAX_NEURONS = 1024;
	GENOME_THRESHOLD = 1 / 5;
	POPULATION_SIZE = 100;

	Starting_Weights_Chance = 0.25;
	Starting_Connection_Chance = 2.0;
	Starting_Bias_Chance = 0.2;
	Starting_Split_Chance = 0.5;
	Starting_Enable_Chance = 0.2;
	Starting_Disable_Chance = 0.4;

	Reset_Weight_Chance = 0.9;
	Crossover_Chance = 0.75;

	-- REWARD / PUNISHMENT PROPERTIES

	POINTS_PER_KILL = 100;
	POINTS_PER_ROUND_END = 1000;
	POINTS_PER_BULLET = -1;
	POINTS_PER_MOVEMENT = 1;
}
