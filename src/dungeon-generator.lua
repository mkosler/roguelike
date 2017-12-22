local function getIndex(self, x, y)
    return (y * self.width) + x
end

local function getCoords(self, i)
    return i % self.width, math.floor(i / self.width)
end

local function get(self, x, y)
    local i = x
    if y then i = getIndex(self, x, y) end

    return self.grid[i]
end

local function setAdjacency(self, x1, y1, x2, y2)
    local i, j = x1, y1
    if x2 and y2 then
        i, j = getIndex(self, x1, y1), getIndex(self, x2, y2)
    end

    self.adjacency[i][j] = true
    self.adjacency[j][i] = true
end

local function areAdjacent(self, x1, y1, x2, y2)
    local i, j = x1, y1
    if x2 and y2 then
        i, j = getIndex(self, x1, y1), getIndex(self, x2, y2)
    end

    return self.adjacency[i][j]
end

local function getAllAdjacents(self, x, y)
    local i, n = x, {}
    if y then i = getIndex(self, x, y) end

    for j = 0, (self.width * self.height) - 1 do
        if self.adjacency[i][j] then
            local x, y = getCoords(self, j)
            table.insert(n, { i = j, x = x, y = y })
        end
    end

    return n
end

local function addRoom(self, x, y, w, h)
    if x + w > self.width or y + h > self.height then
        return
    end

    local region = {}
    for nx = 0, w - 1 do
        for ny = 0, h - 1 do
            local c = get(self, x + nx, y + ny)
            table.insert(region, getIndex(self, x + nx, y + ny))
            c.visited = true
            c.room = nx < w - 1 and ny < h - 1

            if nx > 0 then setAdjacency(self, x + nx, y + ny, x + nx - 1, y + ny) end
            if nx < w - 1 then setAdjacency(self, x + nx, y + ny, x + nx + 1, y + ny) end
            if ny > 0 then setAdjacency(self, x + nx, y + ny, x + nx, y + ny - 1) end
            if ny < h - 1 then setAdjacency(self, x + nx, y + ny, x + nx, y + ny + 1) end
        end
    end
    table.insert(self.regions, region)
end

local function overlap(r1, r2)
    return r1.x < r2.x + r2.w and
           r2.x < r1.x + r1.w and
           r1.y < r2.y + r2.h and
           r2.y < r1.y + r1.h
end

local function fillRooms(self, attempts, minWidth, maxWidth, minHeight, maxHeight)
    attempts = attempts or 200
    minWidth = minWidth or 5
    maxWidth = maxWidth or 7
    minHeight = minHeight or minWidth
    maxHeight = maxHeight or maxWidth

    local rooms = {}

    while attempts > 0 do
        attempts = attempts - 1

        local r = {
            x = lm.random(1, (self.width * 2) - 1),
            y = lm.random(1, (self.height * 2) - 1),
            w = lm.random(minWidth, maxWidth),
            h = lm.random(minHeight, maxHeight)
        }

        local noOverlap = true
        for _,v in pairs(rooms) do
            if overlap(r, v) then
                noOverlap = false
                break
            end
        end

        if noOverlap and r.x + r.w <= self.width and r.y + r.h <= self.height then
            table.insert(rooms, r)
        end
    end

    for _,r in pairs(rooms) do
        addRoom(self, r.x, r.y, r.w, r.h)
    end

    local start = rooms[lm.random(#rooms)]
    self.start = { x = start.x, y = start.y }
end

local function getNeighbors(self, x, y, func)
    func = func or function () return true end
    local n = {}

    if y - 1 >= 0 and func(self, x, y - 1) then
        table.insert(n, { i = getIndex(self, x, y - 1), x = x, y = y - 1 })
    end

    if x + 1 < self.width and func(self, x + 1, y) then
        table.insert(n, { i = getIndex(self, x + 1, y), x = x + 1, y = y })
    end

    if y + 1 < self.height and func(self, x, y + 1) then
        table.insert(n, { i = getIndex(self, x, y + 1), x = x, y = y + 1 })
    end

    if x - 1 >= 0 and func(self, x - 1, y) then
        table.insert(n, { i = getIndex(self, x - 1, y), x = x - 1, y = y })
    end

    return n
end

local function backtracker(self)
    for i = 0, (self.width * self.height) - 1 do
        local c, x, y = get(self, i), getCoords(self, i)

        if not c.visited then
            local regions, stack = {}, {}
            c.visited = true

            repeat
                local neighbors = getNeighbors(self, x, y, function (self, x, y)
                    return not get(self, x, y).visited
                end)

                if #neighbors > 0 then
                    local n = neighbors[lm.random(#neighbors)]
                    table.insert(regions, n.i)
                    table.insert(stack, { x = x, y = y })
                    setAdjacency(self, x, y, n.x, n.y)
                    c, x, y = get(self, n.i), n.x, n.y
                    c.visited = true
                else
                    local n = table.remove(stack)
                    c, x, y = get(self, n.x, n.y), n.x, n.y
                end
            until #stack == 0

            table.insert(self.regions, regions)
        end
    end
end

local function inRegion(region, index)
    for _,i in pairs(region) do
        if index == i then return true end
    end
    return false
end

local function getConnectors(self, region)
    local conns = {}

    for _,i in ipairs(region) do
        local neighbors = getNeighbors(self, getCoords(self, i))
        for _,n in pairs(neighbors) do
            local ni = getIndex(self, n.x, n.y)
            if not inRegion(region, ni) then
                table.insert(conns, { i, ni })
            end
        end
    end

    return conns
end

local function unify(r1, r2)
    local r = {}
    for _,v in pairs(r1) do table.insert(r, v) end
    for _,v in pairs(r2) do table.insert(r, v) end
    return r
end

local function connectRegions(self)
    if #self.regions == 1 then return end

    repeat
        local ri = lm.random(#self.regions)
        local r = self.regions[ri]
        local conns = getConnectors(self, r)
        local door = conns[lm.random(#conns)]
        local x1, y1 = getCoords(self, door[1])
        setAdjacency(self, door[1], door[2])

        local doorIndex, doorRegion = nil, nil
        for i,dr in pairs(self.regions) do
            for _,v in pairs(dr) do
                if v == door[2] then
                    doorIndex = i
                    doorRegion = dr
                    break
                end
            end

            if doorIndex ~= nil then break end
        end

        self.regions[ri] = unify(r, doorRegion)
        table.remove(self.regions, doorIndex)
    until #self.regions == 1
end

local function fillDeadEnds(self)
    local found = false

    repeat
        found = false

        for i = 0, (self.width * self.height) - 1 do
            if get(self, i).visited then
                local n = getAllAdjacents(self, i)

                if #n == 2 then
                    self.grid[i].visited = false
                    found = true
                    for _,v in pairs(n) do
                        local j = getIndex(self, v.x, v.y)
                        if i ~= j then
                            self.adjacency[i][j] = false
                            self.adjacency[j][i] = false
                        end
                    end
                end
            end
        end
    until not found
end

return function(width, height, options)
    local self = {
        width = width,
        height = height,
        grid = {},
        adjacency = {},
        regions = {}
    }

    for i = 0, (width * height) - 1 do
        self.grid[i] = { visited = false }
        self.adjacency[i] = {}

        for j = 0, (width * height) - 1 do
            self.adjacency[i][j] = i == j
        end
    end

    fillRooms(self)
    backtracker(self)
    connectRegions(self)
    fillDeadEnds(self)

    return self
end