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
                {variable = "position[1]", type = "Numberwheel", label = "X-Pos", cmd = ""},
                {variable = "position[2]", type = "Numberwheel", label = "Y-Pos", cmd = ""},
                {variable = "", type = "Button", label = "Move entities", cmd = 'editor.changeEditMode(components["Transforms"].editModes.move)'}
            })
        end
            
        if self.rotation ~= nil then
            table.iextend(self.__guiElements,{
                {variable = "rotation", type = "Numberwheel", label = "Angle", cmd = "", params = {speed = 1.0}},
                {variable = "", type = "Button", label = "Rotate entities", cmd = 'editor.changeEditMode(components["Transforms"].editModes.rotate)'}
            })
        end
        
        if self.offset ~= nil then 
            table.iextend(self.__guiElements,{
                {variable = "offset[1]", type = "Numberwheel", label = "X-Offset", cmd = ""},
                {variable = "offset[2]", type = "Numberwheel", label = "Y-Offset", cmd = ""},
                --{name = "Offset entities", type = "Button", id = 'editor.changeEditMode(components["Transforms"].editModes.offset)'}
            })
        end
        
        if self.scale ~= nil then 
            table.iextend(self.__guiElements,{
                {variable = "scale[1]", type = "Numberwheel", label = "X-Scale", cmd = "", params = {speed = 0.5}},
                {variable = "scale[2]", type = "Numberwheel", label = "Y-Scale", cmd = "", params = {speed = 0.5}},
                {variable = "keepAspect", type = "Checkbox", label = "Use X-scale for Y-scale too", cmd = ""},
                {variable = "", type = "Button", label = "Scale entities", cmd = 'editor.changeEditMode(components["Transforms"].editModes.scale)'}
            })
        end 

        self.__hidden = false
        self.__showInDetails = false
    end

    function Transforms:localToWorld(x, y)
        x, y = (x + self.offset[1]) * self.scale[1], (y + self.offset[2]) * self.scale[2]
        x, y = rotatePoint(x, y, self.rotation)
        return x + self.position[1], y + self.position[2]
    end 

    function Transforms:worldToLocal(x, y)
        x, y = x - self.position[1], y - self.position[2]
        x, y = rotatePoint(x, y, -self.rotation)
        return x / self.scale[1] - self.offset[1], y / self.scale[2] - self.offset[2]
    end

    function Transforms:renderStart()
        if self.keepAspect then self.scale[2] = self.scale[1] end
        love.graphics.push()
        if self.position ~= nil then love.graphics.translate(unpack(self.position)) end
        if self.rotation ~= nil then love.graphics.rotate(self.rotation) end
        if self.scale ~= nil then love.graphics.scale(unpack(self.scale)) end
        if self.offset ~= nil then love.graphics.translate(unpack(self.offset)) end
    end

    function Transforms:renderEnd()
        love.graphics.pop()

        if Transforms.static.showCenterMarkers then 
            local radius = 10.0 / camera.scale
            love.graphics.setColor(0, 0, 0, 255)
            love.graphics.setLineWidth(4.0 / camera.scale)
            love.graphics.circle("line", self.position[1], self.position[2], radius, 16)
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.setLineWidth(2.0/camera.scale)
            love.graphics.circle("line", self.position[1], self.position[2], radius, 16)
        end
    end 

    Transforms.static.__unique = true
    Transforms.static.__pickable = false

    Transforms.static.showCenterMarkers = true

    Transforms.static.__guiElements = {
        {variable = "showCenterMarkers", type = "Checkbox", label = "Show center markers", cmd = ""},
    }

    Transforms.editModes = {
        move = {description = "Move entities"},
        rotate = {description = "Rotate entities"},
        --offset = {description = "Offset entities"}, -- do i even want this?
        scale = {description = "Scale entities"}
    }

    -- Move mode
    function Transforms.editModes.move.onMouseDown(x, y, button)
        local mode = Transforms.editModes.move
        if button == "l" then 
            mode.entity = getEntityByGUID(gui.selectedEntities[1])
            if mode.entity then 
                mode.transforms = getComponentByType(mode.entity, "Transforms")
            end 
        end
    end

    function Transforms.editModes.move.onMouseMove(x, y, dx, dy)
        local mode = Transforms.editModes.move
        if mode.transforms then 
            mode.transforms.position = {mode.transforms.position[1] + dx / camera.scale, mode.transforms.position[2] + dy / camera.scale}
        end 
    end 

    function Transforms.editModes.move.onMouseUp(x, y, button)
        local mode = Transforms.editModes.move
        if button == "l" and mode.transforms then 
            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "Transforms").position = {' .. table.concat(mode.transforms.position, ", ") .. "}")
            mode.transforms = nil
            mode.entity = nil
        end
    end

    -- Rotate mode
    function Transforms.editModes.rotate.onMouseDown(x, y, button)
        local mode = Transforms.editModes.rotate
        if button == "l" then 
            mode.entity = getEntityByGUID(gui.selectedEntities[1])
            if mode.entity then 
                mode.transforms = getComponentByType(mode.entity, "Transforms")
                local wx, wy = camera.screenToWorld(x, y)
                mode.mouseAngleStart = math.atan2(wy - mode.transforms.position[2], wx - mode.transforms.position[1])
                mode.trafoRotStart = mode.transforms.rotation
            end 
        end
    end

    function Transforms.editModes.rotate.onMouseMove(x, y, dx, dy)
        local mode = Transforms.editModes.rotate
        if mode.transforms then 
            local wx, wy = camera.screenToWorld(x, y)
            local angle = math.atan2(wy - mode.transforms.position[2], wx - mode.transforms.position[1])
            mode.transforms.rotation = mode.trafoRotStart + angle - mode.mouseAngleStart
        end 
    end 

    function Transforms.editModes.rotate.onMouseUp(x, y, button)
        local mode = Transforms.editModes.rotate
        if button == "l" and mode.transforms then
            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "Transforms").rotation = ' .. tostring(mode.transforms.rotation)) 
            mode.transforms = nil
            mode.entity = nil
        end
    end

    -- Scale mode
    function Transforms.editModes.scale.getRelativeRotatedDistance(mx, my)
        local mode = Transforms.editModes.scale
        local wx, wy = camera.screenToWorld(mx, my)
        local relX, relY = wx - mode.transforms.position[1], wy - mode.transforms.position[2]

        local sinphi = math.sin(-mode.transforms.rotation)
        local cosphi = math.cos(-mode.transforms.rotation)
        local distX = cosphi * relX - sinphi * relY
        local distY = sinphi * relX + cosphi * relY

        return distX, distY
    end

    function Transforms.editModes.scale.onMouseDown(x, y, button)
        local mode = Transforms.editModes.scale
        if button == "l" then 
            mode.entity = getEntityByGUID(gui.selectedEntities[1])
            if mode.entity then 
                mode.transforms = getComponentByType(mode.entity, "Transforms")
                mode.startDistX, mode.startDistY = Transforms.editModes.scale.getRelativeRotatedDistance(x, y)
                mode.startScale = {unpack(mode.transforms.scale)}
            end 
        end
    end

    function Transforms.editModes.scale.onMouseMove(x, y, dx, dy)
        local mode = Transforms.editModes.scale
        if mode.transforms then 
            local distX, distY = Transforms.editModes.scale.getRelativeRotatedDistance(x, y)

            local facX, facY = distX / mode.startDistX, distY / mode.startDistY
            if mode.transforms.keepAspect then
                facX = math.max(facX, facY)
                facY = facX
            end 

            mode.transforms.scale = {mode.startScale[1] * facX, mode.startScale[2] * facY}
            if mode.transforms.keepAspect then mode.transforms.scale[2] = mode.transforms.scale[1] end
        end 
    end 

    function Transforms.editModes.scale.onMouseUp(x, y, button)
        local mode = Transforms.editModes.scale
        if button == "l" and mode.transforms then 
            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "Transforms").scale = {' .. table.concat(mode.transforms.scale, ", ") .. "}")
            mode.transforms = nil
            mode.entity = nil
        end
    end
end 