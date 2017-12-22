local Class = require 'lib.hump.class'
local Vector = require 'lib.hump.vector'
local Signal = require 'lib.hump.signal'
local Timer = require 'lib.hump.timer'

return Class{
    init = function (self, x, y)
        x = x or 0
        y = y or 0
        self.pos = Vector(x, y)
        self.width = 16
        self.height = 16
        self.moving = false

        self.signals = {
            Signal.register('key', function (key, map)
                if self.moving then return end

                local nv = Vector()
                local x, y = math.floor(self.pos.x), math.floor(self.pos.y)

                if key == 'left' and map:get(x - 1, y).visited then nv.x = -1
                elseif key == 'right' and map:get(x + 1, y).visited then nv.x = 1
                elseif key == 'up' and map:get(x, y - 1).visited then nv.y = -1
                elseif key == 'down' and map:get(x, y + 1).visited then nv.y = 1
                end

                if nv:len2() > 0 then
                    self.moving = true
                    Timer.tween(0.5, self.pos, { x = self.pos.x + nv.x, y = self.pos.y + nv.y }, 'linear', function ()
                        self.moving = false
                    end)
                end
            end),
        }
    end,

    draw = function (self, cellWidth, cellHeight)
        lg.push('all')
        lg.setColor(PALETTE['orange'])
        lg.translate(self.pos.x * cellWidth, self.pos.y * cellHeight)
        lg.rectangle('fill', 1, 1, self.width - 2, self.height - 2)
        lg.pop()
    end,
}