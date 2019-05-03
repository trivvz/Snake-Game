TILE_SIZE = 32
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

MAX_TILES_X =  WINDOW_WIDTH / TILE_SIZE
MAX_TILES_Y =  math.floor(WINDOW_HEIGHT / TILE_SIZE)

-- tiles
TILE_EMPTY = 0
TILE_SNAKE_HEAD = 1
TILE_SNAKE_BODY = 2
TILE_SNAKE_TAIL = 3
TILE_SNAKE_TURN_1 = 4
TILE_SNAKE_TURN_2 = 5
TILE_SNAKE_TURN_3 = 6
TILE_SNAKE_TURN_4 = 7
TILE_APPLE = 8
TILE_STONE_1 = 9
TILE_STONE_2 = 10
TILE_STONE_3 = 11
TILE_STONE_4 = 12
TILE_STONE_5 = 13

-- snake moving directions
RIGHT = 1
UP = 2
LEFT = 3
DOWN = 4

local level = 1

-- time in seconds that the snake moves one tile
SNAKE_SPEED = math.max(0.02, 0.1 - (level * 0.005))

-- load modules
local Img = require "Img"
local Sounds = require "Sounds"
local Fonts = require "Fonts"

-- declare booleans
local isGameOver = false
local isGameStart = true
local isNewLevel = true
local isDrawLines = true

local score = 0
local lives = 3

-- declare grids
local tileGrid = {}
local rotationGrid = {}

-- declare snake variables
local snakeX, snakeY
local snakeMoving = RIGHT
local snakeTimer = 0 -- provides discrete snake movement

-- snake data structure
local snakeTiles = {}

function love.load()
    love.window.setTitle("Snake")

    -- set window size
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false
    })

    -- get seed for RNG
    math.randomseed(os.time())

    -- tune the audio
    Sounds.musicSound:setLooping(true)
    Sounds.musicSound:setVolume(0.1)
    Sounds.musicSound:play()
    Sounds.deathSound:setVolume(0.65)
    Sounds.gameOverSound:setVolume(0.65)

    -- generate a grid with snake, stone obstacles and apple
    initializeGrid()
    -- generate an empty rotationGrid
    initializeRotationGrid()
    -- create a snake
    initializeSnake()

    tileGrid[snakeTiles[1][2]][snakeTiles[1][1]] = TILE_SNAKE_HEAD
    rotationGrid[snakeTiles[1][2]][snakeTiles[1][1]] = snakeMoving
end

function love.keypressed(key)
    
    -- quit game at any time with ESC key
    if key == "escape" then
        love.event.quit()
    end

    -- mute/unmute music at any time using M key
    if key == 'm' then
        if Sounds.musicSound:isPlaying() then
            Sounds.musicSound:pause()
        else
            Sounds.musicSound:play()
        end
    end

    -- turn on/off drawing grid lines using L key
    if key == 'l' then
        if not isGameStart then
            if isDrawLines then
                isDrawLines = false
            else
                isDrawLines = true
            end
        end
    end
    
    -- handling of snake movement
    -- KNOWN BUG: too quick player input could
    -- result in player death as snakeMoving is
    -- updating a couple of times between drawing
    -- new frames
    if not isGameOver and not isNewLevel then
        if key == "left" and snakeMoving ~= RIGHT then
            snakeMoving = LEFT
        elseif key == "right" and snakeMoving ~= LEFT then
            snakeMoving = RIGHT
        elseif key == "up" and snakeMoving ~= DOWN then
            snakeMoving = UP
        elseif key == "down" and snakeMoving ~= UP then
            snakeMoving = DOWN
        end
    end

    if isNewLevel then
        if key == "space" then
            isNewLevel = false
        end
    end

    if isGameOver or isGameStart then
        if key == "enter" or key == "return" then
            score = 0
            level = 1
            lives = 3
            initializeGrid()
            initializeRotationGrid()
            initializeSnake()
            isGameOver = false
            isGameStart = false
        end
    end
end

function love.update(dt)
    if not isGameOver and not isNewLevel then
        snakeTimer = snakeTimer + dt

        -- save current snake head coords for later use
        local priorHeadX, priorHeadY = snakeX, snakeY

        -- move the snake in one of 4 directions
        -- while blocking the opposite move

        if snakeTimer >= SNAKE_SPEED then
            if snakeMoving == UP then
                if snakeY <= 1 then
                    snakeY = MAX_TILES_Y
                else
                    snakeY = snakeY - 1
                end
            elseif snakeMoving == DOWN then
                if snakeY >= MAX_TILES_Y then
                    snakeY = 1
                else
                    snakeY = snakeY + 1
                end
            elseif snakeMoving == LEFT then
                if snakeX <= 1 then
                    snakeX = MAX_TILES_X
                else
                    snakeX = snakeX - 1
                end
            else
                if snakeX >= MAX_TILES_X then
                    snakeX = 1
                else
                    snakeX = snakeX + 1
                end
            end

            -- push a new head element onto the snake data structure
            table.insert(snakeTiles, 1, {snakeX, snakeY, snakeMoving})

            -- if there is collision with stone or rest of the snake
            if tileGrid[snakeY][snakeX] == TILE_SNAKE_BODY or
               tileGrid[snakeY][snakeX] == TILE_SNAKE_TAIL or
               tileGrid[snakeY][snakeX] == TILE_STONE_1 or
               tileGrid[snakeY][snakeX] == TILE_STONE_2 or
               tileGrid[snakeY][snakeX] == TILE_STONE_3 or
               tileGrid[snakeY][snakeX] == TILE_STONE_4 or
               tileGrid[snakeY][snakeX] == TILE_STONE_5 then
                
                -- player loses one live
                lives = lives - 1

                
                if lives > 0 then
                    -- death sequence
                    isNewLevel = true
                    clearSnake()
                    initializeSnake()
                    Sounds.deathSound:play()
                else
                    -- game over sequence
                    isGameOver = true
                    Sounds.gameOverSound:play()
                end

            -- if snake is eating an apple
            elseif tileGrid[snakeY][snakeX] == TILE_APPLE then
                -- increase score and generate a new apple

                score = score + 1
                Sounds.appleSound:play()
                
                -- function changed to cubic so levels are now changed
                -- less freuqently which was really annoying
                -- OLD ONE: if score > level * math.ceil(level / 2) * 3 then
                if score > (level + 1) * (level + 1) * level + 5 then
                    -- promote player to the next level
                    level = level + 1
                    Sounds.newLevelSound:play()
                    isNewLevel = true -- display new level screen

                    -- increase snake speed
                    SNAKE_SPEED = math.max(0.01, 0.11 - (level * 0.01))

                    -- generate a new grid with more stones
                    initializeGrid()

                    -- clear rotation grid
                    initializeRotationGrid()


                    initializeSnake()
                    return
                end

                -- generate a new apple
                generateObstacle(TILE_APPLE)
            
            -- otherwise, pop the snake tail and earse from the grid
            else
                local tail = snakeTiles[#snakeTiles]
                tileGrid[tail[2]][tail[1]] = TILE_EMPTY
                table.remove(snakeTiles)
            end

            if not isGameOver and not isNewLevel then

                local headMoving = snakeTiles[1][3] -- should be the same as snakeMoving var
                local priorHeadMoving = snakeTiles[2][3]
                -- set the correct turn tile for the 2nd piece of snake (tile just after
                -- the head) if there was a turn (so snakeTiles[n][3] and snakeTiles[n+1][3]
                -- will be different) the are 4 possible directions of snake head movement
                -- and in each case the 2nd tile has to be moving in one of two directions
                if headMoving ~= priorHeadMoving then
                    if headMoving == LEFT then
                        if priorHeadMoving == UP then
                            tileGrid[priorHeadY][priorHeadX] = TILE_SNAKE_TURN_1
                        elseif priorHeadMoving == DOWN then
                            tileGrid[priorHeadY][priorHeadX] = TILE_SNAKE_TURN_2
                        end
                    elseif headMoving == DOWN then
                        if priorHeadMoving == RIGHT then
                            tileGrid[priorHeadY][priorHeadX] = TILE_SNAKE_TURN_1
                        elseif priorHeadMoving == LEFT then
                            tileGrid[priorHeadY][priorHeadX] = TILE_SNAKE_TURN_4
                        end
                    elseif headMoving ==  UP then
                        if priorHeadMoving == RIGHT then
                            tileGrid[priorHeadY][priorHeadX] = TILE_SNAKE_TURN_2
                        elseif priorHeadMoving == LEFT then
                            tileGrid[priorHeadY][priorHeadX] = TILE_SNAKE_TURN_3
                        end
                    else -- elseif headMoving == RIGHT then
                        if priorHeadMoving == DOWN then
                            tileGrid[priorHeadY][priorHeadX] = TILE_SNAKE_TURN_3
                        elseif priorHeadMoving == UP then
                            tileGrid[priorHeadY][priorHeadX] = TILE_SNAKE_TURN_4
                        end
                    end

                -- if there was no turn set the prior head value to a body value
                else tileGrid[priorHeadY][priorHeadX] = TILE_SNAKE_BODY
                end

                -- make the last snake tile its tail
                local tail = snakeTiles[#snakeTiles]
                tileGrid[tail[2]][tail[1]] = TILE_SNAKE_TAIL

                -- update the view with the next snake head location
                tileGrid[snakeY][snakeX] = TILE_SNAKE_HEAD
                rotationGrid[snakeY][snakeX] = snakeMoving
            end
            
            snakeTimer = 0
        end
    end
end

function love.draw()
    if isGameStart then
        drawStartScreen()
    else
        drawGrid()
        drawStats()

        if isNewLevel then
            drawNewLevel()
        elseif isGameOver then
            drawGameOver()
        end
    end
end

function drawStartScreen()
    -- display game start screen
    love.graphics.setFont(Fonts.hugeFont)
    love.graphics.printf("SNAKE", 0, WINDOW_HEIGHT / 2 - 64, WINDOW_WIDTH, "center")

    love.graphics.setFont(Fonts.largeFont)
    love.graphics.printf("Press Enter to start", 0,
                         WINDOW_HEIGHT / 2 + 64, WINDOW_WIDTH, "center")
                         
    love.graphics.setFont(Fonts.normalFont)
    love.graphics.printf("Press L to switch drawing lines", 0,
                         WINDOW_HEIGHT / 2 + 168, WINDOW_WIDTH, "center")
    love.graphics.printf("Press M to mute music", 0,
                         WINDOW_HEIGHT / 2 + 192, WINDOW_WIDTH, "center")
end

function drawGameOver()
    -- display game over screen
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Fonts.hugeFont)
    love.graphics.printf("GAME OVER", 0, WINDOW_HEIGHT / 2 - 64, WINDOW_WIDTH, "center")
    love.graphics.setFont(Fonts.largeFont)
    love.graphics.printf("Press Enter to restart", 0,
                         WINDOW_HEIGHT / 2 + 64, WINDOW_WIDTH, "center")
end

function drawNewLevel()
    -- display game over screen
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Fonts.hugeFont)
    love.graphics.printf("LEVEL " .. tostring(level), 0,
                         WINDOW_HEIGHT / 2 - 64, WINDOW_WIDTH, "center")
    love.graphics.setFont(Fonts.largeFont)
    love.graphics.printf("Press Space to start", 0,
                         WINDOW_HEIGHT / 2 + 64, WINDOW_WIDTH, "center")
end

function drawStats()
    -- display score, level and remaining lives
    love.graphics.setFont(Fonts.largeFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Score: " .. tostring(score), 10, 10)
    love.graphics.printf("Level: " .. tostring(level), -10, 10, WINDOW_WIDTH, "right")
    -- lives are now displayed using images
    -- love.graphics.printf("Lives: " .. tostring(lives), 0, 10, WINDOW_WIDTH, "center")

    -- draw lost lives images
    for i = 0, 2 do
        drawQuadImage(Img.heartImg,
                      WINDOW_WIDTH / 2 - 1.7 * TILE_SIZE+ i * TILE_SIZE + 5 * i,
                      TILE_SIZE / 2, 0, 0.25)
    end

    -- draw remaining lives images
    -- (same img with different transparency and also overlapping with lost lives)
    for i = 0, lives - 1 do
        drawQuadImage(Img.heartImg,
                      WINDOW_WIDTH / 2 - 1.7 * TILE_SIZE + i * TILE_SIZE + 5 * i,
                      TILE_SIZE / 2, 0, 0.5)
    end

    -- draw music on/off image
    if Sounds.musicSound:isPlaying() then
        drawQuadImage(Img.musicOnImg, WINDOW_WIDTH - 3 * TILE_SIZE, 2 * TILE_SIZE, 0, 0.75)
    else
        drawQuadImage(Img.musicOffImg, WINDOW_WIDTH - 3 * TILE_SIZE, 2 * TILE_SIZE, 0, 0.75)
    end
end


function drawGrid()
    -- draw grid depending on type of tile saved in tileGrid table
    -- very possibly this could be done in less clunky way =)
    local index = 0

    for y = 1, MAX_TILES_Y do
        for x = 1, MAX_TILES_X do
            if tileGrid[y][x] == TILE_EMPTY and isDrawLines then
                -- change color for white with 15% transparency for the grid
                love.graphics.setColor(1, 1, 1, .15)
                drawTile("line", (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)

            elseif tileGrid[y][x] == TILE_APPLE then
                drawTileImage(Img.appleImg, x, y)

            elseif tileGrid[y][x] == TILE_STONE_1 then
                drawTileImage(Img.stone1Img, x, y)

            elseif tileGrid[y][x] == TILE_STONE_2 then
                drawTileImage(Img.stone2Img, x, y)
            
            elseif tileGrid[y][x] == TILE_STONE_3 then
                drawTileImage(Img.stone3Img, x, y)

            elseif tileGrid[y][x] == TILE_STONE_4 then
                drawTileImage(Img.stone4Img, x, y)

            elseif tileGrid[y][x] == TILE_STONE_5 then
                drawTileImage(Img.stone5Img, x, y)

            elseif tileGrid[y][x] == TILE_SNAKE_HEAD then
                drawSnake(Img.snakeHeadImg, x, y, rotationGrid[y][x])

            elseif tileGrid[y][x] == TILE_SNAKE_BODY then
                drawSnake(Img.snakeBodyImg, x, y, rotationGrid[y][x])

            elseif tileGrid[y][x] == TILE_SNAKE_TAIL then
                drawSnake(Img.snakeTailImg, x, y, snakeTiles[#snakeTiles - 1][3])

            elseif tileGrid[y][x] == TILE_SNAKE_TURN_1 then
                drawTileImage(Img.snakeTurn1Img, x, y)

            elseif tileGrid[y][x] == TILE_SNAKE_TURN_2 then
                drawTileImage(Img.snakeTurn2Img, x, y)

            elseif tileGrid[y][x] == TILE_SNAKE_TURN_3 then
                drawTileImage(Img.snakeTurn3Img, x, y)

            elseif tileGrid[y][x] == TILE_SNAKE_TURN_4 then
                drawTileImage(Img.snakeTurn4Img, x, y)
            end
        end
    end
end


function drawTile(mode, x, y)
    -- draw tile as plain or contour square
    love.graphics.rectangle(mode, x, y, TILE_SIZE, TILE_SIZE)
end

function drawQuadImage(quad, x, y, rotation, transparency)
    -- draw quad from spriteSheet with optional rotation or transparency
    rotation = rotation or 0 -- default value is 0
    transparency = transparency or 1 -- default value is 1
    love.graphics.setColor(1, 1, 1, transparency)
    love.graphics.draw(Img.spriteSheet, quad, x, y, rotation)
end

function drawTileImage(image, x, y)
    -- draw non-transparent tiles
    drawQuadImage(image, (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)
end

function drawSnake(image, x, y, movementDirection)
    -- since img is rotated around its top left corner we need
    -- to change coordinates depending on movement direction
    -- which is saved in rotationGrid
    if movementDirection == DOWN then
        drawQuadImage(image, (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE, 0)
    elseif movementDirection == UP then
        -- note that rotation has to be in radians
        drawQuadImage(image, (x + 0) * TILE_SIZE, (y - 0) * TILE_SIZE, math.pi)
    elseif movementDirection == LEFT then
        drawQuadImage(image, (x - 0) * TILE_SIZE, (y - 1) * TILE_SIZE, math.pi / 2)
    else
        drawQuadImage(image, (x - 1) * TILE_SIZE, (y - 0) * TILE_SIZE, -math.pi / 2)
    end
end


function pickRandomStone()
    -- picks one of the n graphic variants of a stone obstacle
    local STONES = {
        TILE_STONE_1,
        TILE_STONE_2,
        TILE_STONE_3,
        TILE_STONE_4,
        TILE_STONE_5,
    }
    return STONES[math.random(#STONES)]
end


function generateObstacle(obstacle, isStone)
    -- generate static element in random location (apple or stone)
    local isStone = isStone or false -- default value is false
    local obstacleX, obstacleY

    repeat
        obstacleX = math.random(MAX_TILES_X)
        -- prevent STONES from generating in the 1st row
        if isStone then obstacleY = math.random(2, MAX_TILES_Y)
        else obstacleY = math.random(MAX_TILES_Y)
        end
        
    until tileGrid[obstacleY][obstacleX] == TILE_EMPTY

    tileGrid[obstacleY][obstacleX] = obstacle
end

function clearSnake()
    -- clear tileGrid from old snake after losing a live
    -- note that it's not needed when moving to a new level,
    -- because it also initializes grid which clears the old snake aswell
    for k, elem in pairs(snakeTiles) do
        if k > 1 then tileGrid[elem[2]][elem[1]] = TILE_EMPTY end
    end
end

function initializeSnake()
    -- create a new snake 3 tiles long
    snakeX, snakeY = 3, 1
    snakeMoving = RIGHT
    snakeTiles = {
        {snakeX, snakeY, snakeMoving},
        {snakeX - 1, snakeY, snakeMoving},
        {snakeX - 2, snakeY, snakeMoving},
    }
    tileGrid[snakeTiles[1][2]][snakeTiles[1][1]] = TILE_SNAKE_HEAD
    tileGrid[snakeTiles[2][2]][snakeTiles[2][1]] = TILE_SNAKE_BODY
    tileGrid[snakeTiles[3][2]][snakeTiles[3][1]] = TILE_SNAKE_TAIL
end

function initializeGrid()
    tileGrid = {}

    for y = 1, MAX_TILES_Y do

        table.insert(tileGrid, {})

        for x = 1, MAX_TILES_X do
            table.insert(tileGrid[y], TILE_EMPTY)
        end
    end

    -- generate a n number of stones depending on level value
    for i = 1, math.min(50, level * 2) do
        generateObstacle(pickRandomStone(), true)
    end

    generateObstacle(TILE_APPLE)
end

function initializeRotationGrid()
    -- create rotation grid in order to correctly rotate
    -- snake head, body and tail
    for y = 1, MAX_TILES_Y do

        table.insert(rotationGrid, {})

        for x = 1, MAX_TILES_X do
            table.insert(rotationGrid[y], 0)
        end
    end
end