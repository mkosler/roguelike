local Gamestate = require 'lib.hump.gamestate'
local Timer = require 'lib.hump.timer'
local Tileset = require 'src.tileset'

lg, lm = love.graphics, love.math
DEBUG = true

function love.load()
    lg.setDefaultFilter('nearest', 'nearest')

    ASSETS = {
        ['tiles'] = Tileset('assets/tiles'),
    }
    PALETTE = {
        ['black'] = { 0, 0, 0 },
        ['dark-blue'] = { 29, 43, 83 },
        ['dark-purple'] = { 126, 37, 83 },
        ['dark-green'] = { 0, 135, 81 },
        ['brown'] = { 171, 82, 54 },
        ['dark-gray'] = { 95, 87, 79 },
        ['light-gray'] = { 194, 195, 199 },
        ['white'] = { 255, 241, 232 },
        ['red'] = { 255, 0, 77 },
        ['orange'] = { 255, 163, 0 },
        ['yellow'] = { 255, 246, 39 },
        ['green'] = { 0, 228, 54 },
        ['blue'] = { 41, 172, 255 },
        ['indigo'] = { 131, 118, 156 },
        ['pink'] = { 255, 119, 168 },
        ['peach'] = { 255, 204, 170 },
    }
    CONTROLS = {
        left = { 'a', 'left', 'kp4' },
        right = { 'd', 'right', 'kp6' },
        up = { 'w', 'up', 'kp8' },
        down = { 's', 'down', 'kp2' }
    }
    STATES = {
        ['play-state'] = require 'src.states.play-state'
    }

    Gamestate.registerEvents()
    Gamestate.switch(STATES['play-state'])
end

function love.update(dt)
    Timer.update(dt)
end

function love.keypressed(key)
    if DEBUG and key == 'escape' then love.event.quit() end
end