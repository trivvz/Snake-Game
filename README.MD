# Snake Game

## Snake game made in Lua [LOVE framework](https://love2d.org/)

### Whole project is based on CS50 youtube videos: [part 1](https://youtu.be/ld_xcXdRez4), [part 2](https://youtu.be/UOzRK3p26Dw)

### Original project files are available in [Colton's repository](https://github.com/coltonoscopy/snake50)

### List of major changes in comparison to original version:

- all tiles are now rendered from sprite sheet file instead of plain colored squares
    - in order this to work there is now some code to handle specific rotation of snake images basing on direction of movement of each tile
    - there are also linking tiles which provide smooth transition between snake tiles during turns
    - added TILE_SNAKE_TAIL in order to render it using different image
    - starting snake is now 3 tiles long to avoid graphical glitches as only snake body has curved variants
    - added 5 graphic variants of stone obstacle which are picked randomly during level initialization
    - all tile images were created from scratch in GIMP (maybe with a little visual help from Google Graphics =) )

- starting cell row is now restricted from stone generation to avoid risk of instant collision with snake after game start

- added option to mute/unmute music using M key

- added option to switch drawing of grid lines using L key


- new level treshold function changed to cubic one in order to make the transition less frequent

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
changed from:
```
if score > level * math.ceil(level / 2) * 3 then
```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
to:
```
if score > (level + 1) * (level + 1) * level + 5 then
```


- SNAKE_SPEED changed from:

```
-- time in seconds that the snake moves one tile
SNAKE_SPEED = math.max(0.01, 0.11 - (level * 0.01))
```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
to:
```
-- time in seconds that the snake moves one tile
SNAKE_SPEED = math.max(0.02, 0.1 - (level * 0.005))
```