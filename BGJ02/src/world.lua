require("util/helper")

World = class("World")

function areUserData(uA, uB, typeA, typeB)
    return (uA.__name == typeA and uB.__name == typeB) or (uA.__name == typeB and uB.__name == typeA)
end

function World:beginContact(a, b, coll)
    local uA = a:getUserData()
    local uB = b:getUserData()
    
    -- print("collision : " .. uA.__name .. " / " .. uB.__name)
    if areUserData(uA, uB, "Bullet", "Asteroid") then
        if uA.__name == "Asteroid" then
            uA:scheduleCrush()
            uB:kill()
        else
            uB:scheduleCrush()
            uA:kill()
        end
    elseif areUserData(uA, uB, "ShipPlayer", "Asteroid") or areUserData(uA, uB, "ShipAI", "Asteroid") then
        if uA.__name == "Asteroid" then
            uA:scheduleCrush()
            uB:hitByAsteroid(uA)
        else
            uB:scheduleCrush()
            uA:hitByAsteroid(uB)
        end
    elseif areUserData(uA, uB, "Powerup", "Asteroid") then
        if uA.__name == "Powerup" then
            uA:perform()
        else
            uB:perform()
        end

    end
end

function World:endContact(a, b, coll)
end

function World:preSolve(a, b, coll)
end

function World:postSolve(a, b, coll)
end

function World:__init()
    self.entities = {}
    self.newAsteroids = {}

    love.physics.setMeter(64)
    self.physicsWorld = love.physics.newWorld(0, 0, false)
    self.physicsWorld:setCallbacks(function(a, b, coll) self:beginContact(a, b, coll) end,
                                   function(a, b, coll) self:endContact(a, b, coll) end,
                                   function(a, b, coll) self:preSolve(a, b, coll) end,
                                   function(a, b, coll) self:postSolve(a, b, coll) end)
    self.physicsObjects = {}
end

function World:add(entity)
    table.insert(self.entities, entity)
    entity.world = self

    if entity.physicsObject ~= nil then
        entity:enablePhysics()
    end
end

function World:addNewAsteroid(asteroid)
    if asteroid.__name == "Asteroid" then
        table.insert(self.newAsteroids, asteroid)
        self:add(asteroid) 
    end
end

function World:clear()
    for k,v in pairs(self.entities) do
        v:kill()
    end
end

function World:remove(entity)
    for k,v in pairs(self.entities) do
        if v == entity then 
            self.entities[k] = nil 
            entity.world = nil
            if entity.physicsObject and entity.physicsObject.body then entity.physicsObject.body:destroy() end
        end
    end

    if entity.__name == "Asteroid" then
        for k,v in pairs(self.newAsteroids) do
            if v == entity then 
                self.newAsteroids[k] = nil 
            end
        end
    end
end

function World:update(dt)
    for k, v in pairs(self.entities) do
        v:update(dt)
    end

    self.physicsWorld:update(dt)
end

function World:draw()
    for k, v in pairs(self.entities) do
        v:draw()
    end
end

function World:drawNewAsteroids()
    for k, v in pairs(self.newAsteroids) do
        if not v:finishedBeingTransparent() then
            v:drawTransparent()
        else
            self.newAsteroids[k] = nil
        end
    end
end

function World:findByType(typename) 
    l = {}
    for k, v in pairs(self.entities) do
        if v.__name == typename then table.insert(l, v) end
    end
    return l
end
