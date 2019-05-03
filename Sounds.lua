-- Sounds.lua

return {
    appleSound = love.audio.newSource("sound/apple.wav", "static"),
    newLevelSound = love.audio.newSource("sound/newlevel.wav", "static"),
    musicSound = love.audio.newSource("sound/music.mp3", "static"),
    deathSound = love.audio.newSource("sound/death.wav", "static"),
    gameOverSound = love.audio.newSource("sound/gameover.wav", "static"),
}