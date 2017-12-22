local Class = require 'lib.hump.class'

return Class{
    init = function (self, filepath)
        self.filepath = filepath
        self:load(filepath)
    end,

    load = function (self, filepath)
        local data = require(filepath)
        self.width = data.width
        self.height = data.height
        self.tileWidth = data.tileWidth
        self.tileHeight = data.tileHeight
        self.imageFilepath = data.imageFilepath
        self.image = lg.newImage(self.imageFilepath)
        self.tiles = {}

        for _,t in pairs(data.tiles) do
            self.tiles[t.name] = lg.newQuad(t.x, t.y, self.tileWidth, self.tileHeight, self.width, self.height)
        end
    end,

    get = function (self, tilename)
        return self.image, self.tiles[tilename]
    end,
}