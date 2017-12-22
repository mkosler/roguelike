local Class = require 'lib.hump.class'

local function expandWalls(self, generatedMap)
    self.grid = {}

    for i = 0, (generatedMap.width * generatedMap.height) - 1 do
        local j = (i * 2) + (generatedMap.width * 2 * math.floor(i / generatedMap.width))
        local c, x, y = generatedMap.grid[i], i % generatedMap.width, math.floor(i / generatedMap.width)

        self.grid[j] = { visited = c.visited, room = c.room }
        self.grid[j + 1] = { visited = generatedMap.adjacency[i][i + 1] }
        self.grid[j + self.width] = { visited = generatedMap.adjacency[i][i + generatedMap.width] }
        self.grid[j + self.width + 1] = { visited = c.room }
    end
end

return Class{
    init = function (self, generatedMap)
        self.width = generatedMap.width * 2
        self.height = generatedMap.height * 2
        self.start = {
            x = generatedMap.start.x * 2,
            y = generatedMap.start.y * 2
        }

        expandWalls(self, generatedMap)
    end,

    getIndex = function (self, x, y)
        return (y * self.width) + x
    end,

    get = function (self, x, y)
        local i = x
        if y then i = self:getIndex(x, y) end

        return self.grid[i]
    end,

    render = function (self, cellWidth, cellHeight)
        self.canvas = lg.newCanvas(self.width * cellWidth, self.height * cellHeight)
        self.canvas:renderTo(function ()
            self:draw(cellWidth, cellHeight)
        end)
    end,

    draw = function (self, cellWidth, cellHeight)
        lg.push('all')
        for i = 0, (self.width * self.height) - 1 do
            local c = self.grid[i]
            local x = i % self.width
            local y = math.floor(i / self.width)

            lg.push('all')
            lg.translate(x * cellWidth, y * cellHeight)
            if c.visited then
                local i,q = ASSETS['tiles']:get('floor')
                lg.draw(i, q, 0, 0)
            else
                local i,q = ASSETS['tiles']:get('wall')
                lg.draw(i, q, 0, 0)
            end
            lg.pop()
        end
        lg.pop()
    end,

    __tostring = function(self)
        local s = 'Map:\n'
        for i = 0, (self.width * self.height) - 1 do
            local c = self.grid[i]
            s = s .. string.format('\t%d (%d, %d): %s | %s\n', i, i % self.width, math.floor(i / self.width), tostring(c.visited), tostring(c.room))
        end

        return s
    end,    
}