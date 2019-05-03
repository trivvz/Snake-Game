-- Img.lua

-- load spriteSheet
local spriteSheet = love.graphics.newImage("tiles.png")

local function genQuad(x, y, quadSize)
    quadSize = quadSize or TILE_SIZE -- TILE_SIZE is default
    return love.graphics.newQuad(x * TILE_SIZE, y * TILE_SIZE, quadSize, quadSize, spriteSheet:getDimensions())
end

return {
    spriteSheet = spriteSheet,
    musicOffImg = genQuad(3, 1, 2 * TILE_SIZE),
    musicOnImg = genQuad(3, 3, 2 * TILE_SIZE),
    appleImg = genQuad(0, 3),
    heartImg = genQuad(4, 0),
    snakeHeadImg = genQuad(0, 0),
    snakeBodyImg = genQuad(0, 1),
    snakeTailImg = genQuad(0, 2),
    snakeTurn1Img = genQuad(1, 1),
    snakeTurn2Img = genQuad(2, 1),
    snakeTurn3Img = genQuad(1, 2),
    snakeTurn4Img = genQuad(2, 2),
    stone1Img = genQuad(0, 4),
    stone2Img = genQuad(1, 3),
    stone3Img = genQuad(2, 3),
    stone4Img = genQuad(1, 4),
    stone5Img = genQuad(2, 4), 
}