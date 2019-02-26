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
