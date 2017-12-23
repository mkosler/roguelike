local Class = require 'lib.hump.class'
local Utils = require 'src.utils'
local Signal = require 'lib.hump.signal'

local function expandWalls(self, generatedMap)
    self.grid = {}
    self.adjacency = {}

    for i = 0, (generatedMap.width * generatedMap.height) - 1 do
        local j = (i * 2) + (generatedMap.width * 2 * math.floor(i / generatedMap.width))
        local c, x, y = generatedMap.grid[i], i % generatedMap.width, math.floor(i / generatedMap.width)

        self.grid[j] = { visited = c.visited, room = c.room }
        self.grid[j + 1] = { visited = generatedMap.adjacency[i][i + 1] }
        self.grid[j + self.width] = { visited = generatedMap.adjacency[i][i + generatedMap.width] }
        self.grid[j + self.width + 1] = { visited = c.room }
    end

    for i = 0, (self.width * self.height) - 1 do
        self.adjacency[i] = {}
        for j = 0, (self.width * self.height) - 1 do
            self.adjacency[i][j] = false
        end
    end

    for i = 0, (self.width * self.height) - 1 do
        if self.grid[i].visited then
            if i % self.width > 0 and i > self.width - 1 then self.adjacency[i][i - self.width - 1] = self.grid[i - self.width - 1].visited end -- northwest
            if i > self.width - 1 then self.adjacency[i][i - self.width] = self.grid[i - self.width].visited end -- north
            if i % self.width < self.width - 1 and i > self.width - 1 then self.adjacency[i][i - self.width + 1] = self.grid[i - self.width + 1].visited end -- northeast
            if i % self.width > 0 then self.adjacency[i][i - 1] = self.grid[i - 1].visited end -- west
            if i % self.width < self.width - 1 then self.adjacency[i][i + 1] = self.grid[i + 1].visited end -- east
            if i % self.width > 0 and i < (self.width * self.height) - self.width then self.adjacency[i][i + self.width - 1] = self.grid[i + self.width - 1].visited end -- southwest
            if i < (self.width * self.height) - self.width then self.adjacency[i][i + self.width] = self.grid[i + self.width].visited end -- south
            if i % self.width < self.width - 1 and i < (self.width * self.height) - self.width then self.adjacency[i][i + self.width + 1] = self.grid[i + self.width + 1].visited end -- southeast
        end
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
        self.path = nil

        expandWalls(self, generatedMap)

        self.signals = {
            Signal.register('mouse', function (x, y, button, player)
                self.path = self:pathfind(player.pos.x, player.pos.y, x, y)
                player:moveAlongPath(self.path)
            end)
        }
    end,

    getIndex = function (self, x, y)
        return (y * self.width) + x
    end,

    getCoords = function (self, i)
        return i % self.width, math.floor(i / self.width)
    end,

    get = function (self, x, y)
        local i = x
        if y then i = self:getIndex(x, y) end

        return self.grid[i]
    end,

    getAdjacents = function (self, x, y)
        local i = x
        if y then i = self:getIndex(x, y) end

        local result = {}
        for j = 0, (self.width * self.height) - 1 do
            if self.adjacency[i][j] then table.insert(result, j) end
        end
        return result
    end,

    render = function (self, cellWidth, cellHeight)
        self.canvas = lg.newCanvas(self.width * cellWidth, self.height * cellHeight)
        self.canvas:renderTo(function ()
            self:draw(cellWidth, cellHeight)
        end)
    end,

    heuristic = function (self, sx, sy, gx, gy)
        if not gx and not gy then
            gx, gy = self:getCoords(sy)
            sx, sy = self:getCoords(sx)
        end

        return math.sqrt(((sx - gx) * (sx - gx)) + ((sy - gy) * (sy - gy)))
    end,

    findMinimum = function (self, dist, set)
        local minKey, minValue = 0, math.huge
        for k,v in ipairs(dist) do
            if set:has(k) and v < minValue then
                minKey = k
                minValue = v
            end
        end
        return minKey
    end,

    pathfind = function (self, sx, sy, gx, gy)
        local count = 0
        local start, goal = sx, sy
        if gx and gy then
            start, goal = self:getIndex(sx, sy), self:getIndex(gx, gy)
        end
        -- print('pathfind', start, sx, sy, goal, gx, gy)

        local unvisited = Utils.Set()
        local dist = {}
        local prev = {}
        for i = 0, (self.width * self.height) - 1 do
            dist[i] = math.huge
            if self.grid[i].visited then unvisited:insert(i) end
        end
        dist[start] = 0

        while not unvisited:empty() do
            count = count + 1
            local current = self:findMinimum(dist, unvisited)
            unvisited:remove(current)
            -- print('size', unvisited:size(), current, self:getCoords(current))

            if current == goal then
                local path, x, y = {}, nil, nil
                while prev[current] do
                    x, y = self:getCoords(current)
                    table.insert(path, 1, { i = current, x = x, y = y })
                    current = prev[current]
                end
                x, y = self:getCoords(current)
                table.insert(path, 1, { i = current, x = x, y = y })
                return path
            end

            local neighbors = self:getAdjacents(current)
            -- print('neighbors', table.concat(neighbors, ', '))
            for _,n in pairs(neighbors) do
                if unvisited:has(n) then
                    local altDist = dist[current] + self:heuristic(current, n)
                    if altDist < dist[n] then
                        -- print('new dist', n, altDist)
                        dist[n] = altDist
                        prev[n] = current
                    end
                end
            end
        end
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