desktop_mode = true -- for desktop debugging (not playing lmao)
math.randomseed(os.clock())
-- todo:
-- full vr functionality

shapes = {
    { -- Z
        {0,0,0},
        {1,0,0},
        {-1,-1,0},
        {0,-1,0},
    },
    { -- L
        {0,0,0},
        {1,0,0},
        {-1,0,0},
        {-1,-1,0},
    },
    { -- O (2x2 bounding cube)
        {0,0,0},
        {1,0,0},
        {1,1,0},
        {0,1,0},
    },
    { -- S
        {0,0,0},
        {-1,0,0},
        {1,-1,0},
        {0,-1,0},
    },
    { -- I (4x4 bounding cube)
        {0,0,-1},
        {1,0,-1},
        {-1,0,-1},
        {2,0,-1},
    },
    { -- J
        {0,0,0},
        {1,0,0},
        {-1,0,0},
        {1,-1,0},
    },
    { -- T
        {0,0,0},
        {1,0,0},
        {-1,0,0},
        {0,-1,0},
    },
    
    -- 3D exclusive pieces
    { -- Left screw (2x2 bounding cube)
        {0,1,-1},
        {1,1,-1},
        {0,1,0},
        {0,0,0},
    },
    { -- Right screw (2x2 bounding cube)
        {0,1,-1},
        {1,1,-1},
        {1,1,0},
        {1,0,0},
    },
    { -- Spike (2x2 bounding cube)
        {0,1,-1},
        {1,1,-1},
        {0,0,0},
        {0,1,0},
    },
    
}

game = {
    piece = {
        shape = {
            {0,0,0},
            {1,0,0},
            {-1,-1,0},
            {0,-1,0}
        },
        x=2,
        y=2,
        z=1,
        rot_center={0,0,0},

        new_piece = function(self,id)
            self.shape = {}
            for i=1,#shapes[id] do
                self.shape[i] = {shapes[id][i][1],shapes[id][i][2],shapes[id][i][3]}
            end

            self.x = 3
            self.y = 3
            self.z = 1

            self.rot_center = {0,0,0}
            if(id == 5 or id >= 8) then
                self.rot_center = {0.5,0.5,-0.5}
            end

            if(self:check_collision()) then
                game.over = true
            end
        end,

        rotate = function(self,dir)
            local o_shape = {}

            local dx,dy,dz = self.rot_center[1],self.rot_center[2],self.rot_center[3]

            if(dir == "up") then
                for i=1,#self.shape do
                    o_shape[i] = {self.shape[i][1],self.shape[i][2],self.shape[i][3]}
                    self.shape[i] = {self.shape[i][1],self.shape[i][3]-dz+dy,-(self.shape[i][2]-dy)+dz}
                end
            end
            if(dir == "down") then
                for i=1,#self.shape do
                    o_shape[i] = {self.shape[i][1],self.shape[i][2],self.shape[i][3]}
                    self.shape[i] = {self.shape[i][1],-(self.shape[i][3]-dz)+dy,self.shape[i][2]-dy+dz}
                end
            end
            if(dir == "left") then
                for i=1,#self.shape do
                    o_shape[i] = {self.shape[i][1],self.shape[i][2],self.shape[i][3]}
                    self.shape[i] = {self.shape[i][3]-dz+dx,self.shape[i][2],-(self.shape[i][1]-dx)+dz}
                end
            end
            if(dir == "right") then
                for i=1,#self.shape do
                    o_shape[i] = {self.shape[i][1],self.shape[i][2],self.shape[i][3]}
                    self.shape[i] = {-(self.shape[i][3]-dz)+dx,self.shape[i][2],self.shape[i][1]-dx+dz}
                end
            end
            if(dir == "ccw") then
                for i=1,#self.shape do
                    o_shape[i] = {self.shape[i][1],self.shape[i][2],self.shape[i][3]}
                    self.shape[i] = {self.shape[i][2]-dy+dx,-(self.shape[i][1]-dx)+dy,self.shape[i][3]}
                end
            end
            if(dir == "cw") then
                for i=1,#self.shape do
                    o_shape[i] = {self.shape[i][1],self.shape[i][2],self.shape[i][3]}
                    self.shape[i] = {-(self.shape[i][2]-dy)+dx,self.shape[i][1]-dx+dy,self.shape[i][3]}
                end
            end

            if(self:check_collision()) then
                for i=1,#self.shape do
                    self.shape[i] = {o_shape[i][1],o_shape[i][2],o_shape[i][3]}
                end
            end
        end,

        draw = function(self)
            for _,cube in pairs(self.shape) do
                lovr.graphics.setColor(0.6,0.6,1,1)
                local bx,by,bz = getGameCoordinates(cube[1]+self.x,cube[2]+self.y,cube[3]+self.z)
                lovr.graphics.box("fill",bx,by,bz,1/9,1/9,1/9)
            end

            -- ghost piece
            for _,cube in pairs(self.shape) do
                lovr.graphics.setColor(0.6,0.6,1,0.3)
                local bx,by,bz = getGameCoordinates(cube[1]+self.x,cube[2]+self.y,cube[3]+math.max(self:calc_ghost_z(),self.z))
                lovr.graphics.box("fill",bx,by,bz,1/12,1/12,1/12)
            end
        end,

        check_collision = function(self,xo,yo,zo)
            for i=1,#self.shape do
                local cx,cy,cz = self.shape[i][1]+self.x+(xo or 0),self.shape[i][2]+self.y+(yo or 0),self.shape[i][3]+self.z+(zo or 0)
                if(cx < 1 or cx > game.board.width or
                   cy < 1 or cy > game.board.height or
                             cz > game.board.depth) then
                    return true
                end
                if(cz >= 1) then
                    if(game.board[cz][cy][cx].solid) then
                        return true
                    end
                end
            end
            return false
        end,

        drop = function(self)
            self.z = self.z + 1
            if(self:check_collision()) then
                self.z = self.z - 1
                self:place()
                return true
            end
        end,

        move = function(self,x,y)
            self.x = self.x + x
            self.y = self.y + y
            if(self:check_collision()) then
                self.x = self.x - x
                self.y = self.y - y
            end
        end,
        
        place = function(self)
            for _,cube in pairs(self.shape) do
                local cx,cy,cz = cube[1]+self.x,cube[2]+self.y,cube[3]+self.z
                if(cz <= 0) then
                    game.over = true
                    return true
                end
                game.board[cz][cy][cx].solid = true
            end

            self:new_piece(game.next_piece)
            game.next_piece = math.floor(math.random() * #shapes) + 1
            -- clear planes
            game.board:clear_full_planes()
        end,

        calc_ghost_z = function(self)
            local gzo = 0
            while(not self:check_collision(0,0,gzo)) do
                gzo = gzo + 1
            end
            return self.z + gzo - 1
        end,
    },
    board = {
        reset = function(self,w,h,d)
            for z=1,d do
                self[z] = {}
                for y=1,h do
                    self[z][y] = {}
                    for x=1,w do
                        self[z][y][x] = {solid=false}
                        if(z > 9 and math.random() < 1) then
                            --self[z][y][x].solid = true  -- debug
                        end
                    end
                end
            end
            self.width = w
            self.height = h
            self.depth = d
        end,

        clear_full_planes = function(self)
            local w,h,d = self.width,self.height,self.depth
            local plane_count = 0
            for z=d,1,-1 do
                local is_plane_full = true
                for y=1,h do
                    for x=1,w do
                        is_plane_full = is_plane_full and self[z][y][x].solid
                    end
                end
                if(is_plane_full) then
                    game.planes = game.planes + 1
                    plane_count = plane_count + 1
                    for z2=z,1,-1 do
                        for y=1,h do
                            for x=1,w do
                                if(z2 == 1) then
                                    self[z2][y][x].solid = false
                                else
                                    self[z2][y][x].solid = self[z2-1][y][x].solid
                                end
                                if(z2 == z) then
                                    local cx,cy,cz = getGameCoordinates(x,y,z)
                                    table.insert(game.particle_cubes,{x=cx,y=cy,z=cz,rx=math.random()*3,ry=math.random()*3,rz=math.random()*3,r=0,rotspd=math.random()*2+1,xv=math.random()*2-1,yv=math.random()*2-0.5,zv=math.random()*2-1})
                                end
                            end
                        end
                    end
                end
            end
            game.score = game.score + ({[0]=0,100,300,900,2700})[plane_count]
        end,

        draw = function(self)
            -- quick experiment: can I draw a box with negative size to invert it?
            lovr.graphics.setColor(0,0,0,0.5)
            -- answer: no lmfao
            lovr.graphics.box("line",0,0.5 - 1/16,-0.75, (game.board.width)*-1/8, (game.board.depth)*-1/8, (game.board.height)*-1/8)

            for z=1,self.depth do
                for y=1,self.height do
                    for x=1,self.width do
                        lovr.graphics.setColor(getHeightColour(z))
                        local bx, by, bz = getGameCoordinates(x,y,z)
                        if(self[z][y][x].solid) then lovr.graphics.box("fill",bx,by,bz,1/9,1/9,1/9) end
                    end
                end
            end
        end,

        draw_next_piece = function(self,x,y,z)
            for _,cube in pairs(shapes[game.next_piece]) do
                lovr.graphics.setColor(0.6,0.6,1,1)
                local bx,by,bz = (cube[1])*1/8+x,(cube[3])*-1/8+y,(cube[2])*1/8+z
                lovr.graphics.box("fill",bx,by,bz,1/9,1/9,1/9)
            end
        end
    },
    hardDropTimer = 0,
    isDropHeld = false,
    gravity_timer = 1,
    planes = 0,
    next_piece = 3,
    calc_grav = function(self)
        return 2 / 1.1^(1 + self.planes / 10)
    end,
    reset = function(self)
        self.board:reset(6,6,10)
        game.piece:new_piece(math.floor(math.random() * #shapes) + 1)
        self.next_piece = math.floor(math.random() * #shapes) + 1
        self.gravity_timer = self:calc_grav()
        self.planes = 0
        self.score = 0
        self.particle_cubes = {}
    end,
}
function getGameCoordinates(x,y,z)
    return ((x-0.5)-game.board.width/2)/8,-(z-game.board.depth/2)/8+0.5,((y-0.5)-game.board.height/2)/8-0.75
end

function getHeightColour(z)
    local perc = (1-((z-1)/(game.board.depth-1))) -- math.sqrt to account for weird colour math
    return 0.5+perc,0.7-(perc^2)*0.5,1-perc,1
end

function lovr.load()
    require("lighting")
    game:reset()
    lovr.graphics.setLineWidth(4) -- might not work on all GPUs

    small_font = lovr.graphics.newFont(36)

    skybox = lovr.graphics.newTexture({
        left="wall.png",
        right="wall.png",
        top="ceiling.png",
        bottom="floor.png",
        front="wall.png",
        back="wall.png"
    })
end

function lovr.keypressed(keycode, scancode, rept)
    local keyMappings = {
        left="j",
        forward="i",
        right="l",
        back="k",

        rotleft="f",
        rotright="h",
        rotup="t",
        rotdown="g",
        rotccw="r",
        rotcw="y",

        drop="space"
    }
	if(not rept and not game.over and desktop_mode) then
		if(keycode == keyMappings.left) then
			game.piece:move(-1,0)
		elseif(keycode == keyMappings.right) then
			game.piece:move(1,0)
		elseif(keycode == keyMappings.forward) then
			game.piece:move(0,-1)
		elseif(keycode == keyMappings.back) then
			game.piece:move(0,1)
        end

        if(keycode == keyMappings.rotleft) then
			game.piece:rotate("left")
		elseif(keycode == keyMappings.rotright) then
			game.piece:rotate("right")
		elseif(keycode == keyMappings.rotup) then
			game.piece:rotate("up")
		elseif(keycode == keyMappings.rotdown) then
			game.piece:rotate("down")
        elseif(keycode == keyMappings.rotccw) then
			game.piece:rotate("ccw")
		elseif(keycode == keyMappings.rotcw) then
			game.piece:rotate("cw")
        end

        if(keycode == keyMappings.drop) then
            game.hardDropTimer = 0
            game.isDropHeld = not game.piece:drop()
        end
	end
end

function lovr.keyreleased(keycode, scancode)
    if(keycode == "space" and desktop_mode) then
        game.isDropHeld = false

        if(game.hardDropTimer < 0.25) then
            while(not game.piece:drop()) do game.score = game.score + 5 end -- a bit hacky
            game.score = game.score - 5
        end
    end
end
dirTimers = {left=0,right=0,up=0,down=0,rl=0,ru=0,rd=0,rr=0,rccw=0,rcw=0,drop=0}
function lovr.update(dt)
    lightingShader:send('lightPos', {0,3,4})

    -- Specular lighting stuff (I don't know what this means)
    if(lovr.headset) then 
        hx,hy,hz = lovr.headset.getPosition()
        lightingShader:send('viewPos',{hx,hy,hz})
    end

    --controller
	for i, hand in ipairs(lovr.headset.getHands()) do
        local das = 0.3
        local arr = 0.05
		if(hand == "hand/left") then
			local tx,ty = lovr.headset.getAxis(hand,"thumbstick")
            if(tx < -0.5) then
                if(dirTimers.left == 0) then
                    game.piece:move(-1,0)
                end
                dirTimers.left = dirTimers.left + dt
                if(dirTimers.left > das) then
                    game.piece:move(-1,0)
                    dirTimers.left = dirTimers.left - arr
                end
            else dirTimers.left = 0 end

            if(tx > 0.5) then
                if(dirTimers.right == 0) then
                    game.piece:move(1,0)
                end
                dirTimers.right = dirTimers.right + dt
                if(dirTimers.right > das) then
                    game.piece:move(1,0)
                    dirTimers.right = dirTimers.right - arr
                end
            else dirTimers.right = 0 end

            if(-ty < -0.5) then
                if(dirTimers.up == 0) then
                    game.piece:move(0,-1)
                end
                dirTimers.up = dirTimers.up + dt
                if(dirTimers.up > das) then
                    game.piece:move(0,-1)
                    dirTimers.up = dirTimers.up - arr
                end
            else dirTimers.up = 0 end

            if(-ty > 0.5) then
                if(dirTimers.down == 0) then
                    game.piece:move(0,1)
                end
                dirTimers.down = dirTimers.down + dt
                if(dirTimers.down > das) then
                    game.piece:move(0,1)
                    dirTimers.down = dirTimers.down - arr
                end
            else dirTimers.down = 0 end
		end
		if(hand == "hand/right") then
			local tx,ty = lovr.headset.getAxis(hand,"thumbstick")

            if(tx < -0.5) then
                if(dirTimers.rl == 0) then
                    game.piece:rotate("left")
                    dirTimers.rl = 1
                end
            else dirTimers.rl = 0 end
            if(tx > 0.5) then
                if(dirTimers.rr == 0) then
                    game.piece:rotate("right")
                    dirTimers.rr = 1
                end
            else dirTimers.rr = 0 end
            if(-ty < -0.5) then
                if(dirTimers.ru == 0) then
                    game.piece:rotate("up")
                    dirTimers.ru = 1
                end
            else dirTimers.ru = 0 end
            if(-ty > 0.5) then
                if(dirTimers.rd == 0) then
                    game.piece:rotate("down")
                    dirTimers.rd = 1
                end
            else dirTimers.rd = 0 end
            
            if(lovr.headset.isDown(hand,"b")) then
                if(dirTimers.rccw == 0) then
                    game.piece:rotate("ccw")
                    dirTimers.rccw = 1
                end
            else dirTimers.rccw = 0 end
            if(lovr.headset.isDown(hand,"a")) then
                if(dirTimers.rcw == 0) then
                    game.piece:rotate("cw")
                    dirTimers.rcw = 1
                end
            else dirTimers.rcw = 0 end

            if(lovr.headset.isDown(hand,"trigger") or lovr.headset.getAxis(hand,"trigger") > 0.75) then
                
                if(dirTimers.drop == 0) then
                    dirTimers.drop = 1
                    game.hardDropTimer = 0
                    game.isDropHeld = not game.piece:drop()
                end
            else
                if(dirTimers.drop == 1) then
                    game.isDropHeld = false

                    if(game.hardDropTimer < 0.25) then
                        while(not game.piece:drop()) do game.score = game.score + 5 end -- a bit hacky
                        game.score = game.score - 5
                    end
                end
                dirTimers.drop = 0
            end
		end
	end

    -- for the combo drop key
    if(game.isDropHeld) then
        game.hardDropTimer = game.hardDropTimer + dt
        if(game.hardDropTimer > 0.35) then
            if(game.piece:drop()) then
                game.isDropHeld = false
            else
                game.score = game.score + 3
            end
            game.hardDropTimer = 0.25
            game.gravity_timer = game:calc_grav()
        end
    end

    -- gravity
    if(not game.over) then
        game.gravity_timer = game.gravity_timer - dt
        if(game.gravity_timer <= 0) then
            game.gravity_timer = game.gravity_timer + game:calc_grav()
            game.piece:drop()
        end
    end

    for i,cube in ipairs(game.particle_cubes) do

        cube.x = cube.x + cube.xv * dt
        cube.y = cube.y + cube.yv * dt
        cube.z = cube.z + cube.zv * dt
        cube.r = cube.r + cube.rotspd * dt

        cube.yv = cube.yv - 2*dt
        if(cube.y <= -5) then
            table.remove(game.particle_cubes,i)
        end
    end
end

function lovr.draw()
    lovr.graphics.setColor(1,1,1,1)
    lovr.graphics.skybox(skybox)
    lovr.graphics.setShader(lightingShader)
    game.board:draw()
    game.board:draw_next_piece(0.3,1.25-1/16,-1.25)
    game.piece:draw()

    lovr.graphics.setShader() -- reset the shader
    lovr.graphics.setFont(small_font)
    lovr.graphics.setColor(0,0,0,1)
    lovr.graphics.print("Planes: "..game.planes.."\nScore: "..game.score,-0.1,1.25,-1.25,0.15,-math.pi/4,1,0,0,0,"right")

    -- particle cubes
    lovr.graphics.setColor(0.6,0.6,1,1)
    for i,cube in ipairs(game.particle_cubes) do
        lovr.graphics.cube("fill",cube.x,cube.y,cube.z,1/9,cube.r,cube.rx,cube.ry,cube.rz)
    end
    lovr.graphics.setColor(0.5,0.5,0.5,1)
    lovr.graphics.plane("fill",0,-0.2,0,5,5,math.pi/2,1,0,0)
end