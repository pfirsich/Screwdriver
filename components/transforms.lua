do
    local Transforms = class()
    components["Transforms"] = Transforms

    function Transforms:init(properties)
        self.position = {0, 0}
        self.rotation = 0
        self.offset = {0, 0}
        self.scale = {1, 1}
        self.keepAspect = true
        addTable(self, properties)

        self.__guiElements = {}
        if self.position ~= nil then
            table.iextend(self.__guiElements,{
                {name = "X-Pos", type = "Numberwheel", id = "position[1]"},
                {name = "Y-Pos", type = "Numberwheel", id = "position[2]"},
                {name = "Move entities", type = "Button", id = 'editor.editMode = components["Transforms"].static.editModes.move'}
            })
        end
            
        if self.rotation ~= nil then
            table.iextend(self.__guiElements,{
                {name = "Angle", type = "Numberwheel", id = "rotation", params = {speed = 1.0}},
                {name = "Rotate entities", type = "Button", id = 'editor.editMode = components["Transforms"].static.editModes.rotate'}
            })
        end
        
        if self.offset ~= nil then 
            table.iextend(self.__guiElements,{
                {name = "X-Offset", type = "Numberwheel", id = "offset[1]"},
                {name = "Y-Offset", type = "Numberwheel", id = "offset[2]"},
                --{name = "Offset entities", type = "Button", id = 'editor.editMode = components["Transforms"].static.editModes.offset'}
            })
        end
        
        if self.scale ~= nil then 
            table.iextend(self.__guiElements,{
                {name = "X-Scale", type = "Numberwheel", id = "scale[1]", params = {speed = 0.5}},
                {name = "Y-Scale", type = "Numberwheel", id = "scale[2]", params = {speed = 0.5}},
                {name = "Keep aspect ratio", type = "Checkbox", id = "keepAspect"},
                {name = "Scale entities", type = "Button", id = 'editor.editMode = components["Transforms"].static.editModes.scale'}
            })
        end 

        self.__hidden = false
        self.__showInDetails = false
    end

    function Transforms:renderStart()
        if self.keepAspect then  -- this might not be at the right place
            if self.scale[1] ~= self.__lastScale then 
                self.scale[2] = self.scale[1]
                self.__lastScale = self.scale[1]
            end 

            if self.scale[2] ~= self.__lastScale then 
                self.scale[1] = self.scale[2]
                self.__lastScale = self.scale[1]
            end
        end 

        love.graphics.push()
        if self.position ~= nil then love.graphics.translate(unpack(self.position)) end
        if self.rotation ~= nil then love.graphics.rotate(self.rotation) end
        if self.scale ~= nil then love.graphics.scale(unpack(self.scale)) end
        if self.offset ~= nil then love.graphics.translate(unpack(self.offset)) end
    end

    function Transforms:renderEnd()
        love.graphics.pop()
    end 

    Transforms.static.unique = true
    Transforms.static.pickable = false

    Transforms.static.guiElements = {}

    Transforms.static.editModes = {
        move = {description = "Move entities"},
        rotate = {description = "Rotate entities"},
        --offset = {description = "Offset entities"}, -- do i even want this?
        scale = {description = "Scale entities"}
    }

    -- Move mode
    function Transforms.static.editModes.move.onMouseDown(x, y, button)
        local mode = Transforms.static.editModes.move
        if button == "l" then 
            mapStack:push() -- has to be executed before getEntityByGUID, so it has the current entity!
            mode.entity = getEntityByGUID(gui.selectedEntities[1])
            if mode.entity then 
                mode.transforms = getComponentByType(mode.entity, "Transforms")
            end 
        end
    end

    function Transforms.static.editModes.move.onMouseMove(x, y, dx, dy)
        local mode = Transforms.static.editModes.move
        if mode.transforms then 
            mode.transforms.position = {mode.transforms.position[1] + dx / camera.scale, mode.transforms.position[2] + dy / camera.scale}
            updateShape(mode.entity)
        end 
    end 

    function Transforms.static.editModes.move.onMouseUp(x, y, button)
        local mode = Transforms.static.editModes.move
        if button == "l" and mode.transforms then 
            mode.transforms = nil
            mode.entity = nil
        end
    end

    -- Rotate mode
    function Transforms.static.editModes.rotate.onMouseDown(x, y, button)
        local mode = Transforms.static.editModes.rotate
        if button == "l" then 
            mapStack:push() -- has to be executed before getEntityByGUID, so it has the current entity!
            mode.entity = getEntityByGUID(gui.selectedEntities[1])
            if mode.entity then 
                mode.transforms = getComponentByType(mode.entity, "Transforms")
                local wx, wy = camera.screenToWorld(x, y)
                mode.mouseAngleStart = math.atan2(wy - mode.transforms.position[2], wx - mode.transforms.position[1])
                mode.trafoRotStart = mode.transforms.rotation
            end 
        end
    end

    function Transforms.static.editModes.rotate.onMouseMove(x, y, dx, dy)
        local mode = Transforms.static.editModes.rotate
        if mode.transforms then 
            local wx, wy = camera.screenToWorld(x, y)
            local angle = math.atan2(wy - mode.transforms.position[2], wx - mode.transforms.position[1])
            mode.transforms.rotation = mode.trafoRotStart + angle - mode.mouseAngleStart
            updateShape(mode.entity)
        end 
    end 

    function Transforms.static.editModes.rotate.onMouseUp(x, y, button)
        local mode = Transforms.static.editModes.rotate
        if button == "l" and mode.transforms then 
            mode.transforms = nil
            mode.entity = nil
        end
    end

    -- Scale mode
    function Transforms.static.editModes.scale.getRelativeRotatedDistance(mx, my)
        local mode = Transforms.static.editModes.scale
        local wx, wy = camera.screenToWorld(mx, my)
        local relX, relY = wx - mode.transforms.position[1], wy - mode.transforms.position[2]

        local sinphi = math.sin(-mode.transforms.rotation)
        local cosphi = math.cos(-mode.transforms.rotation)
        local distX = cosphi * relX - sinphi * relY
        local distY = sinphi * relX + cosphi * relY

        return distX, distY
    end

    function Transforms.static.editModes.scale.onMouseDown(x, y, button)
        local mode = Transforms.static.editModes.scale
        if button == "l" then 
            mapStack:push() -- has to be executed before getEntityByGUID, so it has the current entity!
            mode.entity = getEntityByGUID(gui.selectedEntities[1])
            if mode.entity then 
                mode.transforms = getComponentByType(mode.entity, "Transforms")
                mode.startDistX, mode.startDistY = Transforms.static.editModes.scale.getRelativeRotatedDistance(x, y)
                mode.startScale = {unpack(mode.transforms.scale)}
            end 
        end
    end

    function Transforms.static.editModes.scale.onMouseMove(x, y, dx, dy)
        local mode = Transforms.static.editModes.scale
        if mode.transforms then 
            local distX, distY = Transforms.static.editModes.scale.getRelativeRotatedDistance(x, y)

            local facX, facY = distX / mode.startDistX, distY / mode.startDistY
            if mode.transforms.keepAspect then
                facX = math.max(facX, facY)
                facY = facX
            end 

            mode.transforms.scale = {mode.startScale[1] * facX, mode.startScale[2] * facY}

            updateShape(mode.entity)
        end 
    end 

    function Transforms.static.editModes.scale.onMouseUp(x, y, button)
        local mode = Transforms.static.editModes.scale
        if button == "l" and mode.transforms then 
            mode.transforms = nil
            mode.entity = nil
        end
    end
end 