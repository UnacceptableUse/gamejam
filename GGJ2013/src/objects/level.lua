
-- game levels

require("core/object")
require("objects/walltile")
require("objects/waterdrop")
require("objects/steam")

function hasBitFlag(set, flag)
    return set % (2*flag) >= flag
end

function removeBitFlag(set, flag)
    if set % (2*flag) >= flag then
        return set - flag
    end
    return set
end

Level = class("Level", Object)

function Level:__init(file, group)
    level = require("data/levels/" .. file)

    self.x = 0
    self.y = 0
    self.z = 0
    self.angle = 0

    self.tiles = ObjectGroup()
    self.spritebatches = {}
    self.quads = {}

    local meta_firstgid = 0

    for t = 1, #level.tilesets do
        local tileset = level.tilesets[t]
        local name = tileset.name

        if name == "meta" then
            meta_firstgid = tileset.firstgid
        end

        local image = resources.images["level_" .. name]
        if image then
            local batch = love.graphics.newSpriteBatch(image, level.width * level.height)
            self.spritebatches[name] = batch

            local tileset_tileheight = ((tileset.imageheight - (tileset.imageheight % level.tileheight)) / level.tileheight)
            local tileset_tilewidth = ((tileset.imagewidth - (tileset.imagewidth % level.tilewidth)) / level.tilewidth)
            for x = 0, tileset_tilewidth - 1 do
                for y = 0, tileset_tileheight - 1 do
                    local quad = love.graphics.newQuad(
                            x * (level.tilewidth + tileset.spacing),
                            y * (level.tileheight + tileset.spacing),
                            level.tilewidth,
                            level.tileheight,
                            image:getWidth(),
                            image:getHeight())
                    self.quads[tileset.firstgid + x + (y * tileset_tilewidth)] = {batch, quad}
                end
            end
        end
    end

    for l = 1, #level.layers do
        local layer = level.layers[l]
        if layer.visible or layer.name == "meta" then
            if layer.type == "objectgroup" then
                -- objectfactory:create()
                for i = 1, #layer.objects do
                    -- name, x, y, properties, type, width, height
                    local obj = layer.objects[i]
                    local cx, cy = obj.x + obj.width / 2, obj.y + obj.height / 2

                    local object = nil

                    if obj.type == "door" then
                        object = Door(obj.width > obj.height and 0 or math.pi / 2)
                        object.x = cx
                        object.y = cy
                        if obj.properties and obj.properties.locked then
                            object.locked = true
                        end
                    elseif obj.type == "trigger" or obj.type == "node" then
                        object = RectangleTrigger(obj.x, obj.y, obj.width, obj.height)
                        if obj.properties and obj.properties.to_level then
                            print("Creating level switch")
                            -- this is a level switch
                            object.onEnter = function()
                                print("Entering level switch")
                                main:fadeToLevel(obj.properties.to_level, obj.properties.location)
                            end
                        end
                        if obj.properties and obj.properties.disabled then
                            object.enabled = false
                        end
                    end

                    if obj.type == "waterdrop" then
                        object = WaterDrop()
                        object.x = cx
                        object.y = cy
                    end

                    if object then
                        object.name = obj.name
                        group:add(object)
                    else
                        print("Unhandled object type: " .. obj.type)
                    end

                end
            else
                for i = 0, level.height - 1 do
                    for j = 0, level.width - 1 do
                        local index = layer.data[1 + j + (i * level.width)]
                        if index ~= 0 then
                            if layer.name == "meta" then
                                index = index - meta_firstgid

                                -- wall tile
                                if index == 1 then
                                    group:add(WallTile(j * level.tilewidth, i * level.tileheight))
                                end
                            else

                                if not self.quads[index] then
                                    local flipX = hasBitFlag(index, 0x80000000)
                                    local flipY = hasBitFlag(index, 0x40000000)

                                    local realIndex = removeBitFlag(removeBitFlag(index, 0x40000000), 0x80000000)

                                    local quad = self.quads[realIndex]
                                    local x, y, w, h = quad[2]:getViewport()
                                    local flippedQuad = love.graphics.newQuad(
                                            x, y, w, h,
                                            quad[1]:getImage():getWidth(),
                                            quad[1]:getImage():getHeight())
                                    flippedQuad:flip(flipX, flipY)
                                    self.quads[index] = {quad[1], flippedQuad}
                                end

                                local quad = self.quads[index]
                                quad[1]:addq(quad[2], j * level.tilewidth, i * level.tileheight)
                            end
                        end
                    end
                end
            end
        end
    end
end

function Level:update(dt)
end

function Level:draw()
    love.graphics.setColor(255, 255, 255)
    for k, v in pairs(self.spritebatches) do
        love.graphics.draw(v)
    end
end
