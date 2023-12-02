--[[ Main core stuff ]]-- =========================================================

physics = require "physics"
physics.start()
system.activate( "multitouch" )


--[[ To read the CSV file(s) ]]-- =========================================================

io.output():setvbuf("no")
display.setStatusBar(display.HiddenStatusBar)

require "extensions.string"
require "extensions.io"
require "extensions.table"
require "extensions.math"
require "extensions.display"



--[[ Parameters ]]-- =========================================================

local cx     = display.contentCenterX
local cy     = display.contentCenterY
local fullw  = display.actualContentWidth
local fullh  = display.actualContentHeight
local left   = cx - fullw/2
local right  = cx + fullw/2
local top    = cy - fullh/2
local bottom = cy + fullh/2
local screenX = display.contentWidth
local screenY = display.contentHeight
local leftMove, rightMove = false, false
local TestyBackground = display.newRect( cx, cy, 3*screenX, 3*screenY)
TestyBackground.fill = {0.5,0.7,1}
local velocity = 0
playingStatus = false
local holdingLeft, holdingRight = false, false
physics.setGravity(0,10)
local doubleJump = true
local levelchosen = ""


--[[ Choose Level ]]-- =========================================================

local function levelSelected(event)
    if (event.phase == "began") then
        levelchosen = event.target.name
        PreBuild()
        StartPlaying()
        BuildTheLevel()
        levelchosen = "Loader"
        playingStatus = true
    end
end



--[[ PreBuild ]]-- =========================================================

function PreBuild()
    --[[ Buttons ]]-- =========================================================

    buttonLeft = display.newRect( screenX/1024, cy, 2*cx, screenY )
    buttonRight = display.newRect( screenX - (screenX/1024), cy, 2*cx, screenY )
    buttonRight.fill = {1,0,0}
    buttonLeft.fill = {0,1,0}
    
    
    
    --[[ DevGround ]]-- =========================================================

    local ground = display.newRect( cx, screenY-30, 3*(buttonLeft.x + buttonRight.x), 60 )
    physics.addBody( ground, "static", { density=1.0, friction=100, bounce=0} )

    local groundTwo =display.newRect( cx, screenY-80, (buttonLeft.x + buttonRight.x), 180 )
    physics.addBody( groundTwo, "static", { density=1.0, friction=10000, bounce=-300000} )



    --[[ Last Stuff Overlays ]]-- =========================================================

    moveLeft =display.newImageRect( 'Assets/UI/arrowLeft.png', 150, 100 )
    moveRight =display.newImageRect( 'Assets/UI/arrowRight.png', 150, 100 )
    -- playButton = display.newRect( cx-100, cy-100, 200, 200 )
    -- playButton.fill, playButton.alpha = {1,1,0},1
    moveLeft.x, moveLeft.y = cx+650,screenY-(cy/2.5)
    moveRight.x, moveRight.y = cx-650,screenY-(cy/2.5)
    moveLeft.name,moveRight.name = "left","right"
end



--[[ Game Code ]]-- =========================================================

function StartPlaying()



    --[[ Player ]]-- =========================================================

    -- Load the sheets

    player = display.newRect( cx, cy, 100, 70)
    player.name = "real"
    player.fill = {1,1,0}
    playerVx, playerVy = 0, 0
    physics.addBody( player )
    player.isFixedRotation=true

    

    --[[ Testy Animation ]]-- =========================================

    local TestyFrameSize =
    {
        width = 605,
        height = 344,
        numFrames = 143
    }

    local TestySheet = graphics.newImageSheet( "Assets/Sprites/Testy.png", TestyFrameSize )

    -- sequences table
    local TestySequences = {
        {
            name="idle",
            frames= { 1 }, -- frame indexes of animation, in image sheet
            time = 100,
            loopCount = 1        -- Optional ; default is 0
        },
        {
            name="hit",
            frames= { 131, 131 }, -- frame indexes of animation, in image sheet
            time = 100,
            loopCount = 1        -- Optional ; default is 0
        },
        {
            name="blink",
            frames= { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }, -- frame indexes of animation, in image sheet
            time = 100,
            loopCount = 1        -- Optional ; default is 0
        },
        {
            name="startrun",
            frames= { 12, 13, 14, 15, 16, 17, 18 }, -- frame indexes of animation, in image sheet
            time = 100,
            loopCount = 1        -- Optional ; default is 0
        },
        {
            name="run",
            frames= { 27, 28, 29 }, -- frame indexes of animation, in image sheet
            time = 300,
            loopCount = 999        -- Optional ; default is 0
        },
        {
            name="dash",
            frames= { 40, 41, 42, 43, 44, 45, 46, 47, 48 }, -- frame indexes of animation, in image sheet
            time = 100,
            loopCount = 1        -- Optional ; default is 0
        },
        {
            name="jump",
            frames= { 53, 54 }, -- frame indexes of animation,   in image sheet
            time = 100,
            loopCount = 1        -- Optional ; default is 0 
        },
        {
            name="startJump",
            frames= { 66, 67, 68, 69, 70 }, -- frame indexes of animation, in image sheet
            time = 100,
            loopCount = 1        -- Optional ; default is 0
        },
        {
            name="fall",
            frames= { 79, 80 }, -- frame indexes of animation, in image sheet
            time = 100,
            loopCount = 1     -- Optional ; default is 0
        },
        {
            name="startFall",
            frames= { 92, 93, 94, 95 }, -- frame indexes of animation, in image sheet
            time = 100,
            loopCount = 1        -- Optional ; default is 0
        },
        {
            name="highjump",
            frames= { 105, 106 }, -- frame indexes of animation, in image sheet
            time = 100,
            loopCount = 0        -- Optional ; default is 0
        },
        {
            name="startHighjump",
            frames= { 54, 105, 106 }, -- frame indexes of animation, in image sheet
            time = 100,
            loopCount = 1        -- Optional ; default is 0
        }
    }

    local newPlayer = display.newSprite( TestySheet, TestySequences )


    newPlayer:play()
    newPlayer.xScale, newPlayer.yScale = 0.3,0.3
    player.alpha = 0


    --[[ Main Level Functions ]]-- =========================================================

    -- Jumping

    local jumps = 1

    local function jumpAgain()
        if playingStatus then
            if doubleJump then
                jumps = 2
            else
                jumps = 1
            end
        end
    end

    local function Jump(event)
        if(event.phase == "began") then
            if playingStatus then
                if (holdingLeft == false) then
                    if jumps ~= 0 then
                        player:setLinearVelocity(0,-300)
                        newPlayer:setSequence("jump")
                        newPlayer:play("jump")
                        jumps = jumps - 1
                    else
                        if (playerVy == 0) then
                            jumpAgain()
                        end
                    end
                end
            end
        end
    end

    -- Moving left and right with dynamic velocity

    local function MovingRight()
        if playingStatus then
            player.x = player.x - (velocity)
        end
    end

    local function MovingLeft()
        if playingStatus then
            player.x = player.x + (velocity)
        end
    end

    local function RunAnim()
        if playingStatus then
            newPlayer:setSequence("run")
            newPlayer:play("run")
        end
    end

    velocity = 0

    local function VelocityChanger()
        if playingStatus then
            if(holdingLeft or holdingRight)then
                if(velocity < 7)then
                    velocity = velocity + 0.15
                elseif(velocity < 10)then
                    velocity = velocity + 0.25
                elseif(velocity < 30)then
                    velocity = velocity + 0.35
                end
            end
        end 
    end

    local function deccelerate()
        local i = 7
        while ( i ~= 0 ) do
            velocity = velocity - velocity/2
            i = i -1
        end
        velocity = 0
    end

    -- Buttons "touching" function(s) and to call moving left and right

    local function ConfirmTouch(event)
        if playingStatus then
            if(event.phase == "moved" or event.phase == "began")then
                if (event.target.name == "left") then
                    holdingLeft = true
                    moveLeft.alpha=1
                elseif (event.target.name == "right") then
                    holdingRight = true
                    moveRight.alpha=1
                end
                RunAnim()
                print("touched")
            end
            
            if(event.phase == "ended")then
                if (event.target.name == "left") then
                    holdingLeft = false
                elseif (event.target.name == "right") then
                    holdingRight = false
                end
                deccelerate()
                newPlayer:setSequence("idle")
                newPlayer:play()
            end
        end
    end

    local function PressAndHold()
        if playingStatus then
            if(holdingLeft) then
                MovingLeft()
                VelocityChanger()
            elseif(holdingRight) then
                MovingRight()
                VelocityChanger()
            end
        end
    end

    local function falling()
        if playingStatus then
            -- Falling animation
            if (velocity == 0) then
                if (playerVy >= 0) then
                    newPlayer:setSequence("fall")
                    newPlayer:play("fall")
                end
                if (playerVy <= 0) then
                    newPlayer:setSequence("jump")
                    newPlayer:play("jump")
                end
                if (playerVy == 0) then
                    newPlayer:setSequence("idle")
                    newPlayer:play("idle")
                end
            end
        end
    end

    local function WhenPlaying()
        if playingStatus then
            newPlayer.x,newPlayer.y=player.x,(player.y - 8 )
            playerVx, playerVy = player:getLinearVelocity()
            -- 
            if (playerVx == 0) then
                timer.performWithDelay( 200, falling )
            end
        end
    end

    -- Turning left and right

    local function turnLeft()
        if playingStatus then
            newPlayer.xScale=0.3
        end
    end

    local function turnRight()
        if playingStatus then
            newPlayer.xScale=-0.3
        end
    end

    --[[ Delays And Listeners ]]-- =========================================================
    
    timer.performWithDelay( 1000, VelocityChanger)
    timer.performWithDelay( 1000, deccelerates )
    timer.performWithDelay( 300, RunAnim )
    Runtime:addEventListener("enterFrame", PressAndHold)
    Runtime:addEventListener("enterFrame", WhenPlaying)
    moveRight:addEventListener("touch", ConfirmTouch)
    moveLeft:addEventListener("touch", ConfirmTouch)
    moveLeft:addEventListener("touch", turnLeft)
    moveRight:addEventListener("touch", turnRight)  
    buttonRight:addEventListener("touch", Jump)
end



--[[ Level Builder ]]-- =========================================================

function BuildTheLevel()
        
    --[[ Level Loader ]]-- =========================================================

    -- Load CSV file as table of tables, where each sub-table is a row
    local lines = io.readFileTable( levelchosen, system.ResourceDirectory )

    local rows = {}

    for i=1, #lines do	
        rows[#rows+1] = string.fromCSV(lines[i])
    end

    -- Debug step to see what we extracted from the CSV file
    table.print_r(rows)

    -- Top of your code:
    local curRow = 0
    local forLooper = 0
    local id = 0
    local rectTable = {} -- for keeping references on created rectangles

    -- Triangle parameters
    local upL   = { 0,25, 0,75, 50,25,  }
    local downL = { 0,0, 0,50, 50,50, }
    local upR   = { 0,0, 0,50, -50,0, }
    local downR = { 0,-50, 0,50, -50,50, }
    local vert  = {}

    -- [[ Actual Loader Function ]]-- =========================================================

    function buildLevel()
        curRow = 0
        forLooper = 1
        curRow = curRow + 1

        if( curRow <= #rows ) then
            table.print_r(rows[curRow])
            forLooper = tonumber((rows[1][1]))
            
            while (forLooper>=1) do

                -- In your loop:

                -- Create 'id' to make array assortment easier
                id=forLooper+1
                if not rows[id] then break end -- this new line will stop the loop if index is nil
                                            
                -- Make the Blocks
                    rectID = rows[id][1]
                    xOffset = ((tonumber(rows[id][2]))*50) - (tonumber(rows[1][2])) -- This offest for X-values will be set by the map data in 1,2
                    yOffset = ((tonumber(rows[id][3]))*50) - (tonumber(rows[1][3])) -- This offest for Y-values will be set by the map data in 1,3
                

                -- Select type of triangle orientation
                if( (tostring(rows[id][7])) == "upL" ) then
                    vert = upL
                end
                if( (tostring(rows[id][7])) == "downL" ) then
                    vert = downL
                end
                if( (tostring(rows[id][7])) == "upR" ) then
                    vert = upR
                end
                if( (tostring(rows[id][7])) == "downR" ) then
                    vert = downR
                end

                -- If the blocks are triangles
                if( (tostring(rows[id][6])) == "triangle") then
                    -- rectTable[rectID] = display.newImage( "images/Tiles/triangleDownLeft.png" )
                    rectTable[rectID] = display.newPolygon( xOffset, yOffset, vert )
                    rectTable[rectID]:setFillColor(rows[id][4], 0, 0)
                    if ((tostring(rows[id][5])) == "1") then
                        physics.addBody( rectTable[rectID], "static", { density=1.0, friction=100, bounce=-10, shape=vert } )
                        rectTable[rectID].anchorX, rectTable[rectID].anchorY = 0,0
                        rectTable[rectID].x, rectTable[rectID].y = rectTable[rectID].x - 25, rectTable[rectID].y - 25
                    end
                end
                
                -- If the blocks are rectangles
                if( (tostring(rows[id][6])) == "square") then
                    rectTable[rectID] = display.newRect(xOffset, yOffset, 50, 50)
                    rectTable[rectID]:setFillColor(rows[id][4], 0, 0)
                    if ((tostring(rows[id][5])) == "1") then
                        physics.addBody( (rectTable[rectID]), "static", { density=1.0, friction=100, bounce=-10} )
                    end
                end
                -- Repeat until finished CSV
                forLooper = forLooper-1
            end
        end
    end    
end



--[[ Load Start Screen ]]-- =========================================================

local flatOverlay = display.newRect( 2*screenX, 2.5*screenY, 5*screenX, 5*screenY )
flatOverlay.fill, flatOverlay.alpha = {0,0,0},1
local playButton = display.newRect( cx-100, cy-100, 200, 200 )
playButton.fill, playButton.alpha = {1,0,0},1
local playButtonLabel = display.newText( "Start", playButton.x, playButton.y,  native.systemFont, 16 )


-- Detects if a level is being played

numLevels = 2

local function LevelSelect()
    -- playingStatus = true
    local levela = display.newRect( cx - 75, cy, 40, 40 )
    local levelb = display.newRect( cx + 75, cy, 40, 40 )
    levela.fill, levelb.fill = {0,0,0}, {0,0,0}
    local levelaB = display.newText( "level1", levela.x, levela.y,  native.systemFont, 13 )
    local levelbB = display.newText( "level2", levelb.x, levelb.y,  native.systemFont, 13 )
    levela.name,levelb.name = "1","2"
            
    levela:addEventListener("touch", levelSelected)
end

local function StartLevel(event)
    if (event.phase == "began")then
        playButton.alpha=0
        flatOverlay.alpha=0
        playButtonLabel.alpha=0
        display.remove( playButtonLabel )
        display.remove( playButton )
        display.remove( flatOverlay )
        LevelSelect()
    end
end



--[[ Listeners ]]-- =========================================================

playButton:addEventListener("touch", StartLevel)
-- button:addEventListener( "touch" , buildLevel)