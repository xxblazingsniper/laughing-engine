require "libs/binser"
require "libs/LUBE"
suit = require "libs/suit"

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function isBlockAtLocation(x, y)
	for i,v in ipairs(map) do
		if v.body:getX() == x and v.body:getY() == y then
			return i, true
		end
	end
	return false
end

function love.load()
 	blockSize = {x = 50, y = 50}

	--physics
	love.physics.setMeter(100) --the height of a meter our worlds will be 64px
	world = love.physics.newWorld(0, 9.81*100, true) --create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81

	map = {} --Array containing arrays that contain x and y screen cordinate values for the blocks
	mapgen = {length = 100, depth = 50} --the length and depth of the map in blocks, as required by the map generator

	require "images"

	cam = {x = 0, y = 0}
	player = {} --Setup player physics
	player.body = love.physics.newBody(world, (mapgen.length*blockSize.x)/2, -400, "dynamic")
	player.shape = love.physics.newRectangleShape(45, 140)
	player.fixture = love.physics.newFixture(player.body, player.shape, 1)
	player.fixture:setFriction(0.8)
	player.body:setFixedRotation(true)
	player.health = 100
	player.inventory = {}

	jumpCooldown = 0.5 --jump cooldown in seconds
	jumpCountdown = 0 --counter for said jump, don't touch
	atMenu = true

	totalHealth = 100
end
local creativeChk = {text = ""}
local ipInput = {text = ""}
local mapLengthInput = {text = "100"}
function love.update(dt) --dt = delta time, used for framerate-independent timing
	if not atMenu then
		world:update(dt)
		if jumpCountdown > 0 then
			jumpCountdown = jumpCountdown - dt
		end
		if love.keyboard.isDown("w") or love.keyboard.isDown(" ") then
			--jump
			if jumpCountdown <= 0 then
				player.body:applyForce(0, -10000)
				jumpCountdown = jumpCooldown
			end
		elseif love.keyboard.isDown("s") then
			--crouch
		end
		if love.keyboard.isDown("a") then
			player.body:applyForce(-1000, 0)
			playerMirrored = false
		elseif love.keyboard.isDown("d") then
			player.body:applyForce(1000, 0)
			playerMirrored = true
		end
		cam.x, cam.y = love.graphics.getWidth() /2 - player.body:getX() - 25, love.graphics.getHeight() /2 - player.body:getY() - 25

		if player.body:getY() > mapgen.depth*blockSize.y or player.health <= 0 then
			player.body:setX((mapgen.length*blockSize.x)/2)
			player.body:setY(-400)
			player.health = totalHealth
		end
	else
		serverIP = suit.Input(ipInput, 125,50,200,30)
    	suit.Label("Server IP", {align="left"}, 50,50,75,30)
		if suit.Button("Join Server (WIP)", 50,100, 150,30).hit then
			--require "client"
        	atMenu = false
    	end
		suit.Checkbox(creativeChk, 125, 200, 30, 30)
		suit.Label("Creative", {align="left"}, 50,200,75,30)
		creativeMode = creativeChk.checked
		suit.Input(mapLengthInput, 125,250,200,30)
    	suit.Label("Map Length", {align="left"}, 50,250,75,30)
		mapgen.length = tonumber(mapLengthInput.text)
		if suit.Button("Host Server", 50,300, 150,30).hit then
			require "mapgen"
        	atMenu = false
    	end
	end
end

function love.draw()
	if not atMenu then
		love.graphics.setBackgroundColor(135, 206, 235)
		for i,v in ipairs(map) do
			if v.sprite == images.grass then
				love.graphics.draw(v.sprite, v.body:getX() + cam.x, v.body:getY() + cam.y - 9) --grass block is a bit taller than the rest of the blocks
			else
				love.graphics.draw(v.sprite, v.body:getX() + cam.x, v.body:getY() + cam.y) --draw blocks
			end
		end
		if not playerMirrored then
			love.graphics.draw(images.player, player.body:getX() + cam.x + 25, player.body:getY() + cam.y + 25, player.body:getAngle(), 1, 1, images.player:getWidth()/2, images.player:getHeight()/2)
		else
			love.graphics.draw(images.player, player.body:getX() + cam.x + 25, player.body:getY() + cam.y + 25, player.body:getAngle(), -1, 1, images.player:getWidth()/2, images.player:getHeight()/2)
		end
		if not creativeMode then
			love.graphics.draw(images.health4, 50, love.graphics.getHeight() -50)
			love.graphics.draw(images.hunger4, 125, love.graphics.getHeight() -50)
		end
	else
		suit.draw()
	end
end



function love.mousepressed( x, y, button, istouch )
	x, y = x - 25, y - 25
	xRound, yRound = blockSize.x*round(x/blockSize.x, 0), blockSize.y*round(y/blockSize.y, 0)
	camXRound, camYRound = blockSize.x*round(cam.x/blockSize.x, 0), blockSize.y*round(cam.y/blockSize.y, 0)
	if button == 1  and not atMenu  and not isBlockAtLocation(xRound - camXRound, yRound - camYRound) then
		table.insert(map, {body = love.physics.newBody(world, xRound - camXRound, yRound - camYRound, "static"), shape = love.physics.newRectangleShape(blockSize.x, blockSize.y)})
		map[table.maxn(map)].fixture = love.physics.newFixture(map[table.maxn(map)].body, map[table.maxn(map)].shape)
		map[table.maxn(map)].fixture:setFriction(1)
		map[table.maxn(map)].sprite = images.stone
	elseif button == 2 and not atMenu then
		i, present = isBlockAtLocation(xRound - camXRound, yRound - camYRound)
		if present then
			map[i].body:destroy()
			table.remove(map, i)
		end
	end
end

function love.textinput(t)
    suit.textinput(t)
end

function love.keypressed(key)
    suit.keypressed(key)
end
