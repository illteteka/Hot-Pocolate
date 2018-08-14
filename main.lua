--[[
	HOT POCOLATE <3 made with love by Ill Teteka, 2018

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
-]]

lg = love.graphics

is_PC = (love.system.getOS() ~= "HorizonNX")
game_loaded = false
loading_stage = 0

debug_mode = false

screensaver = false
sc_timer = 31
sc_dir = "up"

scr_w, scr_h = 1280, 720 --love.window.getDesktopDimensions(1)

if screensaver then
	love.mouse.setVisible(false)
	love.window.setFullscreen(true)
end

math.randomseed(os.time())

bg    = {}
front = {}

function love.load()

	love.window.setMode(scr_w,scr_h)
	if is_PC then
		love.window.setTitle("Hot Pocolate : TACTILE ENTERTAINABLE ADORNMENT")
	end
	
	bg_location = love.filesystem.getDirectoryItems("bg")
	fr_location = love.filesystem.getDirectoryItems("front")
	
	-- If we're running on PC, we only load .png files, Love can't open .gif files natively
	local i
	for i = #bg_location, 1, -1 do
		if (is_PC and string.find(bg_location[i], "png") == nil) then
			table.remove(bg_location, i)
		end
	end
	
	for i = #fr_location, 1, -1 do
		if (is_PC and string.find(fr_location[i], "png") == nil) then
			table.remove(fr_location, i)
		end
	end
	
	bg_len = #bg_location
	fr_len = #fr_location
	
	loading_step = 0  -- loading counter
	loading_index = 1
	load_name = ""
	
	ball_img = lg.newImage("ball.png")
	heart_img = lg.newImage("heart.png")
	loadback_img = lg.newImage("loadback.png")
	loadfront_img = lg.newImage("loadfront.png")
	
end

-- HELPER FUNCTIONS

function lengthdir_x(length,dir)
	return math.cos(dir) * length
end

function lengthdir_y(length,dir)
	return -math.sin(dir) * length
end

-- Returns either 1 or -1 randomly
function negative()
	if math.random(2) == 1 then
		return -1
	else
		return 1
	end
end

function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

-- Returns a table of loadgif tables
function loaddir(dir, file)

	local storage = {}
	
	local spd = 1
	if string.find(file, "-") ~= nil then
		spd = string.sub(file, string.find(file, "-") + 1, string.len(file))
	end

	storage = loadgif(dir .. "/" .. file, spd)
	
	return storage

end

-- Loads every image in a directory into a table
-- Mult is a speed divisor to change the gif speed playback
function loadgif(dir, mult)
	
	local gif = {}
	local files = love.filesystem.getDirectoryItems(dir)
	local ss -- retrieve speed from this string
	for i = 1, #files do
		gif[i] = lg.newImage(dir .. "/" .. files[i])
		ss = files[i]
	end
	
	gif.name = dir
	
	local spd = string.sub(ss, string.find(ss, "-") + 1, string.len(ss) - 5)
	gif.speed = math.floor(60 * spd) * mult
	
	return gif

end

-- END HELPER FUNCTIONS

-- LOVE INPUT

function love.mousemoved( x, y, dx, dy, istouch )
	-- Exit the screensaver
	if screensaver and (math.abs(dx) > 40 or math.abs(dy) > 40) then
		love.event.quit()
	end
end

function love.gamepadpressed(joystick, button)

	if game_loaded then
		if (button == "a") or (button == "dpleft") or (button == "dpup") or (button == "dpright") or (button == "dpdown") or (button == "l") or (button == "zl") then
			stepbpm()
			fire()
		end
		
		if (button == "r") then
			debug_box = not debug_box
		end
		
		if (button == "leftstick") or (button == "rightstick") then
			crazy = true
		end
	end
	
end

function love.gamepadreleased(joystick, button)

	if game_loaded then
		if (button == "leftstick") or (button == "rightstick") then
			crazy = false
		end
	end

end

function love.gamepadaxis( joystick, axis, value )
	
	if game_loaded then
		if (axis == "leftx") or (axis == "rightx") then
			joystick_x = value * 10
		end
		
		if (axis == "lefty") or (axis == "righty") then
			joystick_y = value * 10
		end
	end
	
end

function love.keypressed(key)

	if game_loaded then
	
		if (key == "r") and debug_mode then
			debug_box = not debug_box
		end

		if (key == "space") then
			stepbpm()
			fire()
		end
		
		if (key == "left") or (key == "a") then
			joystick_x = -10
		end
		
		if (key == "right") or (key == "d") then
			joystick_x = 10
		end
		
		if (key == "up") or (key == "w") then
			joystick_y = -10
		end
		
		if (key == "down") or (key == "s") then
			joystick_y = 10
		end
	
	end

end

function love.keyreleased(key)
	if game_loaded then
	
		if (key == "left") or (key == "a") then
			joystick_x = 0
		end
		
		if (key == "right") or (key == "d") then
			joystick_x = 0
		end
		
		if (key == "up") or (key == "w") then
			joystick_y = 0
		end
		
		if (key == "down") or (key == "s") then
			joystick_y = 0
		end
	
	end
end

-- END LOVE INPUT

function startHP()

	pong = false    -- True when playing pong
	pong_screen = 0 -- Counts # of screens pong has lived through
	
	rollAll(false, true)
	bg_frame = 1
	fr_frame = 1
	
	start = 0
	bpm = 120
	
	tt = love.timer.getTime()
	tt_last = tt
	was_stepped = false
	
	bpm1 = 0
	bpm2 = 0
	bpm3 = 0
	bpm4 = 0
	bpm5 = ""
	beatScale = 0
	
	player_x = scr_w/2
	player_y = scr_h/2
	player_w = 100
	player_h = 100
	
	px = {player_x, player_x, player_x}
	py = {player_y, player_y, player_y}
	follow_tick = 0
	
	ball_x = (scr_w/2)-16
	ball_y = math.floor(scr_h*0.6)
	ball_can_hit = true
	ball_count = 0
	ball_lose = 3
	
	ball_spd = 6
	
	ball_alpha = 0
	
	bx_v = 0
	by_v = -ball_spd
	
	joystick_x = 0
	joystick_y = 0
	
	jx_l = 0
	jy_l = 0
	
	movement = "reflect"
	
	crazy = false
	crazy_frame = 0
	
	-- init breakout vars
	breakout = genBreakout()
	breakout_move = 0
	
	-- init galaga vars
	galaga = genGalaga()
	galaga_phase = "intro"
	galaga_angle = 0
	galaga_length = 1
	galaga_x = 0
	galaga_y = 0
	galaga_dir = negative()
	g_can_fire = false
	g_bullets = genBullets()
	gbx = 0
	gby = 0
	gcount = 0
	ghealth = 5
	glose = false
	
	debug_box = false

end

function fire()
	if movement == "galaga" and g_can_fire then
		gbx = player_x + player_w/2
		gby = player_y
		g_can_fire = false
	end
end

function resetBall()
	ball_spd = 6
	ball_can_hit = true
	
	ball_x = (scr_w/2)-16
	ball_y = math.floor(scr_h*0.6)
	
	bx_v = 0
	by_v = -ball_spd
end

-- GAMEPLAY GENERATORS

function genBreakout()
	
	local width, height = 0, 0
	local xx, yy
	local last
	local count = 1
	local bo = {}
	local global_width = 0
	
	-- Load new gifs into a cache
	for yy = 1, 2 do
	
		for xx = 1, 5 do
		
			bo[count] = {}
			local im = bg[math.random(1, #bg)]
			bo[count].image = im[math.random(1, #im)]
			bo[count].x = width
			bo[count].y = height
			bo[count].w = bo[count].image:getWidth()
			bo[count].h = bo[count].image:getHeight()
			bo[count].on = true
			width = width + bo[count].image:getWidth()
			global_width = global_width + bo[count].image:getWidth()
			last = bo[count]
			count = count + 1
		
		end
		
		width = 0
		height = height + last.image:getHeight()
	
	end
	
	bo.width = math.floor(global_width/14)
	
	return bo

end

function genGalaga()

	local gl = {}
	local width = 0
	local height = 0
	
	-- Load new gifs into a cache
	for i = 1, 10 do
		gl[i] = {}
		local im = bg[math.random(1, #bg)]
		gl[i].image = im[math.random(1, #im)]
		gl[i].w = gl[i].image:getWidth()
		gl[i].h = gl[i].image:getHeight()
		
		if gl[i].w > width then
			width = gl[i].w
		end
		
		if gl[i].h > height then
			height = gl[i].h
		end
		
		gl[i].on = true
	end
	
	-- Center the images
	for i = 1, 10 do
		gl[i].x = (scr_w/2) - (width/2)
		gl[i].y = (scr_h/2) - (height/2) - 140
	end
	
	gl.width = width
	gl.height = height
	
	return gl

end

function genBullets()
	local b = {}
	
	-- Load bullets for the enemy
	for i = 1, 4 do
		b[i] = {}
		b[i].x = 0
		b[i].y = 0
		b[i].on = false
	end
	
	return b
end

-- END GAMEPLAY GENERATORS

-- CORE GAMEPLAY

function rollAll(bo, playertrigger)
	if not debug_box then
	-- Freeze current screen in debug mode
	pong_screen = pong_screen + 1
	bg_gif = bg[math.random(1, #bg)]
	bg_frame = 1
	end
	
	if playertrigger then
	-- Only change the player's gif if they initiated rollAll
	fr_gif = front[math.random(1, #front)]
	fr_frame = 1
	player_w = fr_gif[1]:getWidth()
	player_h = fr_gif[1]:getHeight()
	end
	
	local b = math.random(100)
	local c = math.random(5)
	if b == 1 and bo then
	
		-- Randomly call breakout or galaga
		local ra = math.random(2)
		if ra == 1 then
			pong = false
			breakout = genBreakout()
			resetBall()
			ball_count = 0
			ball_alpha = 0
			ball_lose = 3
			breakout_move = 0
			movement = "breakout"
		else
			pong = false
			galaga = genGalaga()
			movement = "galaga"
			galaga_phase = "intro"
			galaga_angle = 0
			galaga_length = 1
			galaga_x = 0
			galaga_y = 0
			galaga_dir = negative()
			g_can_fire = false
			g_bullets = genBullets()
			gbx = 0
			gby = 0
			gcount = 0
			ghealth = 5
			glose = false
		end
		
	elseif c == 1 and movement == "reflect" then
		--Start pong
		pong = true
		pong_screen = 0
	end
end

function stepbpm(auto)

	-- Start beat syncing 1 second after player stops inputs
	if (not auto) or screensaver then
		beatScale = beatScale + 1
		if beatScale > 3 then beatScale = 0 end
		tt_last = tt + 1
	end
	
	-- Calculate BPM every 4 inputs
	if (bpm1 == 0) then
		start = tt
		bpm1 = start
	elseif (bpm2 == 0) then
		bpm2 = tt - bpm1
	elseif (bpm3 == 0) then
		bpm3 = tt - bpm1 - bpm2
	elseif (bpm4 == 0) then -- add in between if distance between 3 and 1 is too big, reset
		bpm4 = tt - bpm1 - bpm2 - bpm3
		bpm5 = bpm2 .. " " .. bpm3 .. " " .. bpm4
		bpm = 60/((bpm2 + bpm3 + bpm4) / 3)
		
		bpm1 = 0
		bpm2 = 0
		bpm3 = 0
		bpm4 = 0
		
		rollAll(true, (not auto) or screensaver)
		
	end

end

-- END CORE GAMEPLAY

function love.update(dt)
	
	-- Loading screen
	if not game_loaded then
		
		if loading_step % 2 == 0 then
			local file
			
			if loading_stage == 0 and bg_location[loading_index] ~= nil then
				file = bg_location[loading_index]
			else
				if loading_stage ~= 2 and bg_location[loading_index] == nil then
					loading_index = 1
					loading_stage = 1
				end
				
				file = fr_location[loading_index]
				
				if fr_location[loading_index] == nil then
					loading_stage = 2
					startHP()
					game_loaded = true
					loadback_img = nil
					loadfront_img = nil
				end
			end
			
			loadname = file
			
			-- Calls loadgif on every folder of a directory
			if (loading_stage ~= 2) then
				if loading_stage == 0 then
					table.insert(bg, loaddir("bg", file, is_PC))
				elseif loading_stage == 1 then
					table.insert(front, loaddir("front", file, is_PC))
				end
			end
			
			loading_index = loading_index + 1
		end
		
		loading_step = loading_step + 1
	
	else
		-- Update millisecond timer (more accurate than Lua's native timer)
		tt = love.timer.getTime()
		
		ball_spd = math.min(ball_spd, 10)
		
		-- AI for screensaver
		if screensaver then
			sc_timer = sc_timer + 1
			if sc_timer > 30 then
				local dir = math.random(4)
				
				if movement == "reflect" then
					if dir == 1 then
						sc_dir = "up"
					elseif dir == 2 then
						sc_dir = "down"
					elseif dir == 3 then
						sc_dir = "left"
					else
						sc_dir = "right"
					end
				else
				
					if ball_x < player_x then
						sc_dir = "left"
					else
						sc_dir = "right"
					end
				
				end
				fire()
				sc_timer = 0
			end
			
			if sc_dir == "up" then
				joystick_y = -10
			elseif sc_dir == "down" then
				joystick_y = 10
			elseif sc_dir == "left" then
				joystick_x = -10
			elseif sc_dir == "right" then
				joystick_x = 10
			end
		end
		-- End AI for screensaver
		
		-- Quit pong after 8 screen refreshes
		if pong_screen > 8 then
			pong = false
		end
		
		-- Record previous positions for ghosting effect
		if follow_tick == 0 then
			for i = 3, 2, -1 do
				px[i] = px[i-1]
				py[i] = py[i-1]
			end
			
			px[1] = player_x
			py[1] = player_y
		end
		
		follow_tick = follow_tick + 1
		if follow_tick > 4 then follow_tick = 0 end
		-- End position recorder
		
		if pong then
			ball_x = ball_x + bx_v
			ball_y = ball_y + by_v
			
			if (CheckCollision(player_x, player_y, player_w, player_h, ball_x, ball_y, 32, 32)) then
				by_v = -math.abs(by_v)
				bx_v = negative() * ball_spd
				ball_spd = ball_spd * 1.01
				ball_can_hit = true
			end
			
			-- Wall collisions
			if (ball_y < 0) then
				ball_y = 0
				by_v = by_v * -1
				bx_v = negative() * ball_spd
				ball_spd = ball_spd * 1.1
				ball_can_hit = true
			elseif (ball_y > scr_h - 32) then
				ball_y = scr_h - 32
				by_v = by_v * -1
				bx_v = negative() * ball_spd
				ball_spd = ball_spd * 1.1
				ball_can_hit = true
			end
			
			if (ball_x < 0) then
				ball_x = 0
				bx_v = bx_v * -1
				ball_can_hit = true
			elseif (ball_x > scr_w - 32) then
				ball_x = scr_w - 32
				bx_v = bx_v * -1
				ball_can_hit = true
			end
		end
		
		if (movement == "breakout") then
			ball_x = ball_x + bx_v
			ball_y = ball_y + by_v
			
			-- If the player wins breakout
			if (ball_count == 10) then
				movement = "reflect"
				ball_alpha = 1
			end
			
			if (CheckCollision(player_x, player_y, player_w, player_h, ball_x, ball_y, 32, 32)) then
				by_v = -math.abs(by_v)
				bx_v = negative() * ball_spd
				ball_spd = ball_spd * 1.01
				ball_can_hit = true
			end
			
			-- Check collisions with breakout members
			for i = 1, 10 do
				if breakout[i].on and ball_can_hit and (CheckCollision(breakout[i].x + breakout.width, breakout[i].y, breakout[i].w, breakout[i].h, ball_x, ball_y, 32, 32)) then
					by_v = math.abs(by_v)
					bx_v = negative() * ball_spd
					ball_spd = ball_spd * 1.01
					breakout[i].on = false
					ball_can_hit = false
					ball_count = ball_count + 1
				end
			end
			
			-- Wall collisions
			if (ball_y < 0) then
				ball_y = 0
				by_v = by_v * -1
				bx_v = negative() * ball_spd
				ball_spd = ball_spd * 1.1
				ball_can_hit = true
			elseif (ball_y > scr_h + 32) then
				ball_lose = ball_lose - 1
				resetBall()
			end
			
			if (ball_x < 0) then
				ball_x = 0
				bx_v = bx_v * -1
				ball_can_hit = true
			elseif (ball_x > scr_w - 32) then
				ball_x = scr_w - 32
				bx_v = bx_v * -1
				ball_can_hit = true
			end
			
			-- When the player loses breakout
			if ball_lose == 0 then
				movement = "reflect"
				resetBall()
				ball_alpha = 1
				breakout_move = 200
			end
			
		end
		
		-- Reduce screen flash a little
		if (crazy) and (crazy_frame == 0) then
			rollAll(false, true)
		end
		
		crazy_frame = crazy_frame + 1
		
		if (crazy_frame > 2) then
			crazy_frame = 0
		end
		-- End reduce screen flashing
		
		-- Sync bpm automatically
		if (tt > tt_last + (59/bpm)) then
			tt_last = tt
			stepbpm(true)
		end
		
		if math.abs(joystick_x) > 9 then
		jx_l = joystick_x
		end
		if math.abs(joystick_y) > 9 then
		jy_l = joystick_y
		end
		
		-- Galaga losing animation
		if glose then
			for i = 2, 10 do
				galaga[i].x = (scr_w/2) - galaga.width/2  + lengthdir_x(galaga_length, galaga_angle + (360 / 9) * (i - 2))
				galaga[i].y = (scr_h/2)  - galaga.height/2 + lengthdir_y(galaga_length, galaga_angle + (360 / 9) * (i - 2)) - 140
			end
			
			galaga_angle = galaga_angle + 0.5
			
			galaga_y = galaga_y - 6
			
			if galaga_y < -600 then
				glose = false
				movement = "reflect"
			end
		end
		-- End galaga losing animation
		
		if movement == "galaga" then
			-- Update galaga member positions
			for i = 2, 10 do
				if galaga[i].on then
				galaga[i].x = (scr_w/2) - galaga.width/2  + lengthdir_x(galaga_length, galaga_angle + (360 / 9) * (i - 2))
				galaga[i].y = (scr_h/2)  - galaga.height/2 + lengthdir_y(galaga_length, galaga_angle + (360 / 9) * (i - 2)) - 140
				else
					galaga[i].y = galaga[i].y - 1
				end
			end
				
			-- Galaga has two phases, intro and start
			if galaga_phase == "intro" then
			
				-- Grow out of center and speed up
				galaga_angle = galaga_angle + 6
				
				if galaga_length < 130 then
					galaga_length = galaga_length + 0.25
				else
					galaga_phase = "start"
					g_can_fire = true
				end
				
			elseif galaga_phase == "start" then
			
				-- Slowly cycle around while moving horizontally
				galaga_angle = galaga_angle + 0.01
				galaga_x = galaga_x + galaga_dir * 4
				
				local yeah = (scr_w/2) -- quick maths
				
				if (galaga_x < -yeah+150) or (galaga_x > yeah-150)then
					galaga_dir = galaga_dir * -1
				end
				
				-- When the player wins galaga
				if gcount > 9 then
					movement = "reflect"
				end
				
				-- AI for the enemy shooting
				for i = 1, 4 do
					if not g_bullets[i].on then
						local c = math.random(100)
						if c == 2 then
							g_bullets[i].on = true
							g_bullets[i].x = galaga[1].x + (galaga[1].w/2) +galaga_x
							g_bullets[i].y = galaga[1].y + galaga_y
						end
					else
						g_bullets[i].y = g_bullets[i].y + 13
						
						if (CheckCollision(player_x, player_y, player_w, player_h, g_bullets[i].x, g_bullets[i].y, 32, 32)) then
							ghealth = ghealth - 1
							g_bullets[i].on = false
						end
						
						if g_bullets[i].y > scr_h + 32 then
							g_bullets[i].on = false
						end
					end
				end
				-- End enemy shooting AI
				
				-- Trigger player losing
				if ghealth < 1 then
					glose = true
				end
				
				-- Player shooting controls
				if not g_can_fire then
				
					for i = 1, 10 do
						if galaga[i].on and (not g_can_fire) and (CheckCollision(galaga[i].x + galaga_x, galaga[i].y + galaga_y, galaga[i].w, galaga[i].h, gbx, gby, 32, 32)) then
							g_can_fire = true
							gcount = gcount + 1
							galaga[i].on = false
						end
					end
				
					gby = gby - 12
					if gby < -32 then
						g_can_fire = true
					end
				end
				
			end
			
			-- Don't let angle exceed 360
			if galaga_angle > 360 then galaga_angle = galaga_angle - 360 end
			
		end
		
		if movement == "reflect" then
			joystick_x = jx_l
			joystick_y = jy_l
		end
		
		-- Update player position
		player_x = player_x + joystick_x
		player_y = player_y + joystick_y
		
		-- Force player to the bottom of the screen during boss battles
		if movement == "breakout" or movement == "galaga" then
			joystick_y = 0
			player_y = scr_h
		end
		
		-- Force player within bounds
		if (player_y < 0) then
			player_y = 0
			if movement == "reflect" then joystick_y = joystick_y * -1 end
		elseif (player_y > scr_h - fr_gif[1]:getHeight()) then
			player_y = scr_h - (fr_gif[1]:getHeight())
			if movement == "reflect" then joystick_y = joystick_y * -1 end
		end
		
		if (player_x < 0) then
			player_x = 0
			if movement == "reflect" then joystick_x = joystick_x * -1 end
		elseif (player_x > scr_w - fr_gif[1]:getWidth()) then
			player_x = scr_w - (fr_gif[1]:getWidth())
			if movement == "reflect" then joystick_x = joystick_x * -1 end
		end
		-- End player within bounds
	end

end

function love.draw()

	if not game_loaded then
	
		lg.print("Now loading " .. loadname .. ".gif", 90, 85)
		--lg.print("loaded ".. (#bg + #front) .."/" .. (bg_len + fr_len), 100, 100+40)
		
		-- Draw loading bar
		local xconst, yconst
		xconst = scr_w-256
		yconst = (scr_h-524)/2
		lg.draw(loadback_img, xconst, yconst)
		lg.setScissor(0, 0, scr_w, (yconst + ((#bg + #front) / (bg_len + fr_len))*524))
		lg.draw(loadfront_img, xconst, yconst)
		lg.setScissor(0, 0, scr_w, scr_h)
	
	else
		-- Loop gifs
		if (bg_frame > #bg_gif) then
			bg_frame = 1
		end
		
		bg_frame = bg_frame + (1/bg_gif.speed)
		
		if (fr_frame > #fr_gif) then
			fr_frame = 1
		end
		
		fr_frame = fr_frame + (1/fr_gif.speed)
		-- End loop gifs

		if bg_gif[math.floor(bg_frame)] ~= nil then
		
			local this_frame = bg_gif[math.floor(bg_frame)]
			local ww, hh = this_frame:getWidth(), this_frame:getHeight()
		
			-- Tile bg on the screen
			for w = 0, scr_w, ww do
				for h = 0, scr_h, hh do
					lg.draw(this_frame, w, h)
				end
			end
			
		end
		
		-- Draw breakout
		for i = 1, 10 do
			if breakout[i].image ~= nil and breakout[i].on and (movement == "breakout" or breakout_move ~= 0) then
				local yy = breakout[i].y
				
				if (breakout_move ~= 0) then
					breakout_move = math.max(breakout_move-0.2, 0)
					yy = breakout_move - 200
				end
				
				lg.draw(breakout[i].image, breakout[i].x + breakout.width, yy)
			end
		end
		
		-- Draw player gif
		if fr_gif[math.floor(fr_frame)] ~= nil then
			for i = beatScale, 1, -1 do
			lg.draw(fr_gif[math.floor(fr_frame)], px[i], py[i])
			end
			lg.draw(fr_gif[math.floor(fr_frame)], player_x, player_y)
		end
		
		if pong then
			lg.draw(ball_img, ball_x, ball_y)
		end
		
		-- Draw ball in breakout
		if movement == "breakout" then
			if ball_can_hit == false then lg.setColor(1,1,1,0.5) end
			lg.draw(ball_img, ball_x, ball_y)
			
			lg.setColor(1,1,1,0.8)
			for i = ball_lose, 1, -1 do
				lg.draw(ball_img, scr_w - 80 - (40 * i), scr_h - 120)
			end
		end
		
		-- Draw the galaga lose animation
		if glose then
			for i = 10, 1, -1 do
				if galaga[i].image ~= nil and galaga[i].on then
					lg.draw(galaga[i].image, galaga_x + galaga[i].x, galaga_y + galaga[i].y)
				end
			end
		end
		
		-- Draw galaga
		if movement == "galaga" then
			for i = 10, 1, -1 do
				if galaga[i].image ~= nil and galaga[i].on then
					lg.draw(galaga[i].image, galaga_x + galaga[i].x, galaga_y + galaga[i].y)
				end
			end
			
			for i = 1, 4 do
				if g_bullets[i].on then
					lg.draw(heart_img, g_bullets[i].x, g_bullets[i].y)
				end
			end
			
			if (not g_can_fire) and (galaga_phase == "start") then
				lg.draw(ball_img, gbx, gby)
			end
			
			lg.setColor(1,1,1,0.8)
			for i = ghealth, 1, -1 do
				lg.draw(heart_img, scr_w - 80 - (40 * i), scr_h - 120)
			end
			lg.setColor(1,1,1,1)
		end
		
		-- Fade ball out when the player loses breakout
		if ball_alpha ~= 0 then
		ball_alpha = math.max(ball_alpha - 0.005, 0)
		lg.setColor(1,1,1,ball_alpha)
		lg.draw(ball_img, ball_x, ball_y)
		end
		lg.setColor(1,1,1,1)
		
		if debug_mode then
		lg.print(bpm,  100, 50+30)
		lg.print(bpm1,  100, 50+30+30)
		lg.print(bpm2,  100, 50+30+60)
		lg.print(bpm3,  100, 50+30+90)
		lg.print(bpm5,  20, 50+30+120)
		end
		
		if debug_box then
		lg.setColor(0,0,0,1)
		lg.rectangle("fill",16,16,180,48)
		lg.setColor(1,1,1,1)
		lg.print(fr_gif.name, 18, 18)
		lg.print(bg_gif.name, 18, 18+16)
		end
	end

end