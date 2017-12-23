local Class = require 'lib.hump.class'

return {
    foreach = function (t, f, ...)
        for _,v in ipairs(t) do
            if type(f) == 'string' then
                v[f](v, ...)
            else
                f(v, ...)
            end
        end
    end,

    map = function (t, f, ...)
        local nt = {}

        for _,v in ipairs(t) do
            table.insert(nt, f(v, ...))
        end

        return nt
    end,

    dist = function (x1, y1, x2, y2)
        return math.sqrt(((x1 - x2) * (x1 - x2)) + ((y1 - y2) * (y1 - y2)))
    end,

    Set = Class{
        init = function (self)
            self.data = {}
            self.count = 0
        end,

        insert = function (self, item)
            if not self.data[item] then self.count = self.count + 1 end
            self.data[item] = true
        end,

        remove = function (self, item)
            if self.data[item] then self.count = self.count - 1 end
            self.data[item] = nil
        end,

        has = function (self, item)
            return self.data[item]
        end,

        size = function (self)
            return self.count
        end,

        empty = function (self)
            return self:size() == 0
        end,
    },
}