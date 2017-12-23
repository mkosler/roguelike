local Camera = require 'lib.hump.camera'
local Player = require 'src.entities.player'
local Utils = require 'src.utils'
local Signal = require 'lib.hump.signal'
local Dungeon = require 'src.dungeon'
local generateDungeon = require 'src.dungeon-generator'
local sampleMap = require 'src.sample-map'

return {
    init = function (self)
        self.camera = Camera.new()
        self.camera:zoom(2)
    end,

    enter = function (self, prev)
        self.map = Dungeon(generateDungeon(20, 20))
        -- self.map = Dungeon(sampleMap)
        self.map:render(16, 16)
        self.player = Player(self.map.start.x, self.map.start.y)
        self.entities = {
            self.player
        }
    end,

    leave = function (self)
        self.player = nil
        self.entities = nil
    end,

    update = function (self, dt)
        self.camera:lookAt(self.player.pos.x * 16, self.player.pos.y * 16)
    end,

    draw = function (self)
        self.camera:attach()
        lg.draw(self.map.canvas)
        Utils.foreach(self.entities, 'draw', 16, 16)
        if self.map.path then
            lg.push('all')
            lg.setColor(PALETTE['red'])
            for _,p in ipairs(self.map.path) do
                lg.push()
                lg.translate(p.x * 16, p.y * 16)
                lg.rectangle('fill', 4, 4, 8, 8)
                lg.pop()
            end
            lg.pop()
        end
        self.camera:detach()

        lg.push('all')
        lg.setColor(PALETTE['peach'])
        lg.print('FPS: '..tostring(love.timer.getFPS()), 5, 5)
        lg.pop()

    end,

    keypressed = function (self, key)
        if DEBUG then
            if key == '=' then
                self.camera:zoom(2)
            elseif key == '-' then
                self.camera:zoom(0.5)
            elseif key == 'space' then
                print(self.map)
            end
        end

        for sig,v in pairs(CONTROLS) do
            for _,k in pairs(v) do
                if key == k then
                    Signal.emit('key', sig, self.map)
                end
            end
        end
    end,

    mousepressed = function (self, x, y, button)
        x, y = self.camera:worldCoords(x, y)

        Signal.emit('mouse',
            math.floor(x / 16),
            math.floor(y / 16),
            button,
            self.player)
    end,
}