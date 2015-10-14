do
    local SimplePolygon = class()
    components["SimplePolygon"] = SimplePolygon

    function SimplePolygon:init(properties)
        self.imagePath = ""
        self.color = {255, 255, 255, 255}
        self.renderWholeTexture = false
        self.renderWireframe = false
        self.points = {}
        self.textureTransforms = {
            scale = {1.0, 1.0},
            offset = {0.0, 0.0},
            rotation = 0,
        }
        addTable(self, properties)

        local remeshOnChange = function() self:remesh() end
        self.__guiElements = {
            {variable = "", type = "Button", label = "Edit Vertices", cmd = 'editor.changeEditMode(components["SimplePolygon"].editModes.editPoints)'},
            {variable = "", type = "Button", label = "Edit Texture", cmd = 'editor.changeEditMode(components["SimplePolygon"].editModes.editTexture)'},
            {variable = "color", type = "Color", label = "Color"},
            {variable = "imagePath", type = "File", label = "Image"},
            {variable = "textureTransforms.scale[1]", type = "Numberwheel", label = "X-Texture scale", params = {speed = 0.5, onChange = remeshOnChange}},
            {variable = "textureTransforms.scale[2]", type = "Numberwheel", label = "Y-Texture scale", params = {speed = 0.5, onChange = remeshOnChange}},
            {variable = "textureTransforms.offset[1]", type = "Numberwheel", label = "X-Texture offset", params = {onChange = remeshOnChange}},
            {variable = "textureTransforms.offset[2]", type = "Numberwheel", label = "Y-Texture offset", params = {onChange = remeshOnChange}},
            {variable = "textureTransforms.rotation", type = "Numberwheel", label = "Texture angle", params = {speed = 1.0, onChange = remeshOnChange}},
            {variable = "renderWholeTexture", type = "Checkbox", label = "Render whole texture"},
            {variable = "renderWireframe", type = "Checkbox", label = "Render as wireframe (debug)"},
        }

        if #self.points == 0 then 
            editor.changeEditMode(components["SimplePolygon"].editModes.appendPoints)
            gui.printConsole("New polygon entity created. Changed edit mode to append points mode!")
        end
        -- otherwise the next call to updateUserdataValues will call remesh and initialize the mesh
    end

    function SimplePolygon:updateUserdataValues()
        -- load image first so image dimensions are available for proper texture coordinate calculation
        self:loadImageFile()
        self:remesh()
    end 

    function SimplePolygon:loadImageFile()
        if self.imagePath ~= "" then 
            self.__image = getImage(self.imagePath)
            if self.__image then 
                self.__image:setWrap("repeat", "repeat")
                if self.__mesh then self.__mesh:setTexture(self.__image) end
            end
        end
    end 

    function SimplePolygon:recenter()
        local centerX, centerY = 0, 0
        for i = 1, #self.points, 2 do 
            centerX = centerX + self.points[i+0] 
            centerY = centerY + self.points[i+1]
        end 
        centerX = centerX / #self.points * 2
        centerY = centerY / #self.points * 2

        for i = 1, #self.points, 2 do 
            self.points[i+0] = self.points[i+0] - centerX
            self.points[i+1] = self.points[i+1] - centerY
        end 

        local transforms = getComponentByType(getEntityByComponent(self), "Transforms")
        if transforms then 
            transforms.position = {transforms.position[1] + centerX, transforms.position[2] + centerY}
        end
    end

    function SimplePolygon:remesh()
        if #self.points >= 6 then 
            local tris = love.math.triangulate(self.points)
            local vertices = {}
            for _, tri in ipairs(tris) do
                for i = 1, 6, 2 do 
                    local u, v 
                    if self.__image then 
                        u = tri[i+0] * self.textureTransforms.scale[1] / self.__image:getWidth()
                        v = tri[i+1] * self.textureTransforms.scale[2] / self.__image:getHeight()
                        u, v = rotatePoint(u, v, -self.textureTransforms.rotation)
                        u = u + self.textureTransforms.offset[1] / self.__image:getWidth()
                        v = v + self.textureTransforms.offset[2] / self.__image:getHeight()
                    else 
                        u, v = 0.0, 0.0
                    end
                    local vertex = {tri[i], tri[i+1], u, v, 255, 255, 255, 255}
                    table.insert(vertices, vertex)
                end
            end 

            if self.__mesh == nil then 
                self.__mesh = love.graphics.newMesh(#self.points / 2, self.__image, "triangles")
            end
            self.__mesh:setVertices(vertices)
        end
    end

    function SimplePolygon:getShapes()
        local ret = {}
        if editor.editMode == SimplePolygon.editModes.appendPoints or editor.editMode == SimplePolygon.editModes.editPoints then 
            local radius = 10/camera.scale
            for i = 1, #self.points, 2 do 
                table.insert(ret, getCircleShape(self.points[i], self.points[i+1], radius))
            end 

            if #self.points >= 6 then
                for i = 1, #self.points, 2 do 
                    local ni = i + 2
                    if ni > #self.points then ni = 1 end
                    table.insert(ret, getLineShape(self.points[i], self.points[i+1], self.points[ni], self.points[ni+1], radius, 8.0/camera.scale))
                end 
            end 
        else 
            if #self.points >= 6 then 
                ret = {{unpack(self.points)}}
            end 
        end 
        return ret
    end

    function SimplePolygon:renderStart()
        love.graphics.setColor(unpack(self.color))
        if self.renderWholeTexture and self.__image then 
            love.graphics.push()
            love.graphics.scale(1.0/self.textureTransforms.scale[1], 1.0/self.textureTransforms.scale[2])
            love.graphics.rotate(self.textureTransforms.rotation)
            love.graphics.translate(-self.textureTransforms.offset[1], -self.textureTransforms.offset[2])
            love.graphics.draw(self.__image)
            love.graphics.pop()
        else 
            if self.__mesh then 
                if self.renderWireframe then love.graphics.setWireframe(true) end
                love.graphics.draw(self.__mesh)
                if self.renderWireframe then love.graphics.setWireframe(false) end
            end
        end
    end

    function SimplePolygon:addPoint(x, y, index) -- in local coordinates
        index = index ~= nil and index*2+1 or #self.points+1
        table.insert(self.points, index, y)
        table.insert(self.points, index, x)
    end

    function SimplePolygon:removePoint(index)
        table.remove(self.points, index*2 - 1)
        table.remove(self.points, index*2 - 1)
    end 

    function SimplePolygon:movePoint(index, x, y) -- index is point index, x and y are absolute in world space
        local i = index * 2 - 1
        self.points[i+0] = x
        self.points[i+1] = y
    end

    function SimplePolygon:getTextureTransformsToEdit()
        return "textureTransforms"
    end

    SimplePolygon.static.__unique = true
    SimplePolygon.static.__pickable = true

    SimplePolygon.static.__guiElements = {}

    SimplePolygon.editModes = {
        appendPoints = {description = "Append points to the polygon (initialization)", fixedSelection = true},
        editPoints = {description = "Left click on edge to add vertex, right click vertex to remove, drag&drop vertices to move", fixedSelection = true},
        editTexture = {description = "Left click to drag the texture, right click to rotate", fixedSelection = true},
    }

    -- append mode
    function SimplePolygon.editModes.appendPoints.onEnter()
        components["Core"].static.showEntityBorders = true
    end

    function SimplePolygon.editModes.appendPoints.onExit()
        -- This might go wrong, if another entity is created and the first one didn't have any points appended
        local entity = getEntityByGUID(gui.selectedEntities[1])
        if entity and entity.__pickableComponent then 
            local polygon = getComponentById(entity, entity.__pickableComponent)
            if polygon and polygon.recenter and polygon.remesh then 
                polygon:recenter()
                polygon:remesh()
            end
        end
    end 

    function SimplePolygon.editModes.appendPoints.onMouseDown(x, y, button)
        local mode = SimplePolygon.editModes.appendPoints
        if button == "l" then 
            mode.entity = getEntityByGUID(gui.selectedEntities[1])
            if mode.entity and mode.entity.__pickableComponent then 
                mode.polygon = getComponentById(mode.entity, mode.entity.__pickableComponent)
                if mode.polygon and mode.polygon.addPoint then 
                    x, y = camera.screenToWorld(x, y)
                    local transforms = getComponentByType(mode.entity, "Transforms")
                    if transforms then 
                        x, y = transforms:worldToLocal(x, y)
                    end
                    cliExec('local entity = getEntityByGUID(gui.selectedEntities[1]); getComponentById(entity, entity.__pickableComponent):addPoint(' .. x .. ", " .. y .. ')')
                end 
            end 
        end
    end

    -- edit points
    function SimplePolygon.editModes.editPoints.onEnter()
        components["Core"].static.showEntityBorders = true
    end


    function SimplePolygon.editModes.editPoints.onMouseDown(x, y, button) 
        local mode = SimplePolygon.editModes.editPoints
        mode.entity = getEntityByGUID(gui.selectedEntities[1])
        if mode.entity and mode.entity.__pickableComponent then 
            mode.polygon = getComponentById(mode.entity, mode.entity.__pickableComponent)
            mode.transforms = getComponentByType(mode.entity, "Transforms")
            if mode.polygon and mode.polygon.removePoint and mode.polygon.addPoint and mode.polygon.movePoint then 
                local wx, wy = camera.screenToWorld(x, y)
                mode.shapeIndex = pickShapeFromEntity(wx, wy, mode.entity)
                if mode.shapeIndex then 
                    if button == "r" and mode.shapeIndex <= #mode.polygon.points/2 then 
                        cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "'..mode.polygon.componentType..'"):removePoint(' .. mode.shapeIndex .. ')')
                        mode.shapeIndex = nil
                    end 

                    if button == "l" and mode.shapeIndex > #mode.polygon.points/2 then 
                        local pointIndex = mode.shapeIndex - #mode.polygon.points/2
                        if mode.transforms then 
                            x, y = mode.transforms:worldToLocal(wx, wy)
                        end
                        local args = x .. ", " .. y .. ", " .. pointIndex
                        cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "'..mode.polygon.componentType..'"):addPoint(' .. args .. ')')
                    end 
                end 
            end 
        end 
    end 

    function SimplePolygon.editModes.editPoints.onMouseMove(x, y, dx, dy)
        local mode = SimplePolygon.editModes.editPoints
        if mode.shapeIndex and mode.shapeIndex <= #mode.polygon.points/2 then 
            if mode.transforms then 
                dx = dx / mode.transforms.scale[1]
                dy = dy / mode.transforms.scale[2]
                dx, dy = rotatePoint(dx, dy, -mode.transforms.rotation)
            end 

            local i = mode.shapeIndex * 2 - 1
            mode.polygon.points[i+0] = mode.polygon.points[i+0] + dx / camera.scale
            mode.polygon.points[i+1] = mode.polygon.points[i+1] + dy / camera.scale
            mode.polygon:remesh()
        end 
    end 

    function SimplePolygon.editModes.editPoints.onMouseUp(x, y, button)
        local mode = SimplePolygon.editModes.editPoints
        if button == "l" and mode.shapeIndex and mode.shapeIndex <= #mode.polygon.points/2 then 
            local i = mode.shapeIndex * 2 - 1
            local args = mode.shapeIndex .. ", " .. mode.polygon.points[i+0] .. ", " .. mode.polygon.points[i+1]
            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "'..mode.polygon.componentType..'"):movePoint(' .. args .. ')')
        end 
        mode.shapeIndex = nil
    end 

    -- Texture mode
    function SimplePolygon.editModes.editTexture.onEnter(x, y, transformsKey)
        SimplePolygon.editModes.editTexture.transformsKey = transformsKey
    end

    function SimplePolygon.editModes.editTexture.onMouseDown(x, y, button) 
        local mode = SimplePolygon.editModes.editTexture
        mode.entity = getEntityByGUID(gui.selectedEntities[1])
        if mode.entity and mode.entity.__pickableComponent then 
            mode.transforms = getComponentByType(mode.entity, "Transforms")
            mode.polygon = getComponentById(mode.entity, mode.entity.__pickableComponent)

            if mode.polygon and mode.polygon.getTextureTransformsToEdit then 
                mode.transformsKey = mode.polygon:getTextureTransformsToEdit()

                if mode.transforms then 
                    local wx, wy = camera.screenToWorld(x, y)
                    mode.mouseAngleStart = math.atan2(wy - mode.transforms.position[2], wx - mode.transforms.position[1])
                    mode.trafoRotStart = mode.polygon[mode.transformsKey].rotation
                end

                local wx, wy = camera.screenToWorld(x, y)
                if button == "l" then mode.translate = true end
                if button == "r" then mode.rotate = true end
            end 
        end 
    end 

    function SimplePolygon.editModes.editTexture.onMouseMove(x, y, dx, dy)
        local mode = SimplePolygon.editModes.editTexture
        if mode.translate then 
            if mode.transforms then  
                dx = dx / mode.transforms.scale[1]
                dy = dy / mode.transforms.scale[2]
                dx, dy = rotatePoint(dx, dy, -mode.transforms.rotation)
            end

            dx, dy = rotatePoint(dx, dy, -mode.polygon[mode.transformsKey].rotation)
            mode.polygon[mode.transformsKey].offset[1] = mode.polygon[mode.transformsKey].offset[1] - dx * mode.polygon[mode.transformsKey].scale[1] / camera.scale 
            mode.polygon[mode.transformsKey].offset[2] = mode.polygon[mode.transformsKey].offset[2] - dy * mode.polygon[mode.transformsKey].scale[2] / camera.scale 
            mode.polygon:remesh()
        end 

        if mode.rotate then 
            local wx, wy = camera.screenToWorld(x, y)
            local angle = math.atan2(wy - mode.transforms.position[2], wx - mode.transforms.position[1])
            mode.polygon[mode.transformsKey].rotation = mode.trafoRotStart + angle - mode.mouseAngleStart
            mode.polygon:remesh()
        end 
    end 

    function SimplePolygon.editModes.editTexture.onMouseUp(x, y, button) 
        local mode = SimplePolygon.editModes.editTexture
        if mode.translate then 
            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "'..mode.polygon.componentType..'").'..mode.transformsKey..'.offset = {' .. table.concat(mode.polygon[mode.transformsKey].offset, ", ") .. "}")
        end 
        if mode.rotate then 
            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "'..mode.polygon.componentType..'").'..mode.transformsKey..'.rotation = ' .. tostring(mode.polygon[mode.transformsKey].rotation))
        end
        mode.translate = false
        mode.rotate = false
    end
end 