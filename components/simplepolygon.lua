do
    local SimplePolygon = class()
    components["SimplePolygon"] = SimplePolygon

    function SimplePolygon:init(properties)
        self.imagePath = ""
        self.color = {255, 255, 255, 255}
        self.renderWholeTexture = false
        self.renderWireframe = false
        self.points = {}
        self.textureScaleKeepAspect = true
        self.textureScale = {1.0, 1.0}
        self.textureOffset = {0.0, 0.0}
        self.textureRotation = 0
        addTable(self, properties)

        self.__guiElements = {
            {variable = "", type = "Button", label = "Edit Vertices", cmd = 'editor.changeEditMode(components["SimplePolygon"].editModes.editPoints)'},
            {variable = "", type = "Button", label = "Edit Texture", cmd = 'editor.changeEditMode(components["SimplePolygon"].editModes.editTexture)'},
            {variable = "color", type = "Color", label = "Color", cmd = ""},
            {variable = "imagePath", type = "File", label = "Image", cmd = ""},
            {variable = "textureScale[1]", type = "Numberwheel", label = "X-Texture scale", cmd = ":remesh()", params = {speed = 0.5}},
            {variable = "textureScale[2]", type = "Numberwheel", label = "Y-Texture scale", cmd = ":remesh()", params = {speed = 0.5}},
            {variable = "textureScaleKeepAspect", type = "Checkbox", label = "Use X-scale for Y-scale too", cmd = ""},
            {variable = "textureOffset[1]", type = "Numberwheel", label = "X-Texture offset", cmd = ":remesh()"},
            {variable = "textureOffset[2]", type = "Numberwheel", label = "Y-Texture offset", cmd = ":remesh()"},
            {variable = "textureRotation", type = "Numberwheel", label = "Texture angle", cmd = ":remesh()", params = {speed = 1.0}},
            {variable = "renderWholeTexture", type = "Checkbox", label = "Render whole texture"},
            {variable = "renderWireframe", type = "Checkbox", label = "Render as wireframe (debug)"},
        }

        if #self.points > 0 then 
            self.__mesh = love.graphics.newMesh(#self.points / 2, nil, "triangles")
        else 
            editor.changeEditMode(components["SimplePolygon"].editModes.appendPoints, properties.entityGUID)
            gui.printConsole("New polygon entity created. Changed edit mode to append points mode!")
        end

        self.__hidden = false
    end

    function SimplePolygon:updateUserdataValues()
        self:loadImageFile()
        self:remesh()
    end 

    function SimplePolygon:loadImageFile()
        if self.imagePath ~= "" then 
            local attr, err = lfs.attributes(self.imagePath)
            if attr == nil then 
                error("Attributes of image file could not be checked - '" .. self.imagePath .. "': " .. err)
            end
            if attr.mode ~= "file" then 
                error("'" .. self.imagePath .. "' is not a file.")
            end
            
            self.__image = getImage(self.imagePath)
            self.__image:setWrap("repeat", "repeat")
            self.__mesh:setTexture(self.__image)
        end
    end 

    local function getCircleShape(x, y, r)
        local ret = {}
        local segments = 12
        for i = 1, segments do 
            local ri = i*2 - 1
            local angle = 2.0 * math.pi / segments * (i-1)
            ret[ri+0] = r * math.cos(angle) + x
            ret[ri+1] = r * math.sin(angle) + y
        end 
        return ret
    end

    local function getLineShape(fromX, fromY, toX, toY, margin, thickness)
        local dirX, dirY = toX - fromX, toY - fromY
        local dirLen = math.sqrt(dirX*dirX + dirY*dirY)
        local orthoDirX, orthoDirY = -dirY / dirLen, dirX / dirLen

        local ret = {}
        ret[1] = fromX + dirX / dirLen * margin + orthoDirX * thickness / 2
        ret[2] = fromY + dirY / dirLen * margin + orthoDirY * thickness / 2

        ret[3] = fromX + dirX / dirLen * margin - orthoDirX * thickness / 2
        ret[4] = fromY + dirY / dirLen * margin - orthoDirY * thickness / 2

        ret[5] = fromX + dirX / dirLen * (dirLen - margin) - orthoDirX * thickness / 2
        ret[6] = fromY + dirY / dirLen * (dirLen - margin) - orthoDirY * thickness / 2      

        ret[7] = fromX + dirX / dirLen * (dirLen - margin) + orthoDirX * thickness / 2
        ret[8] = fromY + dirY / dirLen * (dirLen - margin) + orthoDirY * thickness / 2

        return ret
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

    function SimplePolygon:initMesh()
        self.__mesh = love.graphics.newMesh(#self.points / 2, nil, "triangles")
        self:recenter()
        self:remesh()
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
        transforms.position = {transforms.position[1] + centerX, transforms.position[2] + centerY}
    end

    function SimplePolygon:remesh()
        if self.__mesh then 
            if self.textureScaleKeepAspect then self.textureScale[2] = self.textureScale[1] end 
            if #self.points >= 6 then 
                local tris = love.math.triangulate(self.points)
                local vertices = {}
                for _, tri in ipairs(tris) do
                    for i = 1, 6, 2 do 
                        local u, v 
                        if self.__image then 
                            u = tri[i+0] * self.textureScale[1] / self.__image:getWidth()
                            v = tri[i+1] * self.textureScale[2] / self.__image:getHeight()
                            u, v = rotatePoint(u, v, -self.textureRotation)
                            u = u + self.textureOffset[1] / self.__image:getWidth()
                            v = v + self.textureOffset[2] / self.__image:getHeight()
                        else 
                            u, v = 0.0, 0.0
                        end
                        local vertex = {tri[i], tri[i+1], u, v, 255, 255, 255, 255}
                        table.insert(vertices, vertex)
                    end
                end 
                self.__mesh:setVertices(vertices)
            end
        end
    end

    function SimplePolygon:renderStart()
        love.graphics.setColor(unpack(self.color))
        if self.renderWholeTexture and self.__image then 
            love.graphics.push()
            love.graphics.scale(1.0/self.textureScale[1], 1.0/self.textureScale[2])
            love.graphics.rotate(self.textureRotation)
            love.graphics.translate(-self.textureOffset[1], -self.textureOffset[2])
            love.graphics.draw(self.__image)
            love.graphics.pop()
        else 
            if #self.points >= 6 and self.__mesh then 
                if self.renderWireframe then love.graphics.setWireframe(true) end
                love.graphics.draw(self.__mesh)
                if self.renderWireframe then love.graphics.setWireframe(false) end
            end
        end
    end

    SimplePolygon.static.__unique = true
    SimplePolygon.static.__pickable = true

    SimplePolygon.static.__guiElements = {}

    SimplePolygon.editModes = {
        appendPoints = {description = "Append points to the polygon (initialization)", fixedSelection = true},
        editPoints = {description = "Left click on edge to add vertex, right click vertex to remove, drag&drop vertices to move", fixedSelection = true},
        editTexture = {description = "Left click to drag the texture, right click to rotate", fixedSelection = true},
    }

    function SimplePolygon:addPoint(x, y, index)
        local transforms = getComponentByType(getEntityByComponent(self), "Transforms")
        index = index ~= nil and index*2+1 or #self.points+1
        table.insert(self.points, index, y - transforms.position[2])
        table.insert(self.points, index, x - transforms.position[1])
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

    -- append mode
    function SimplePolygon.editModes.appendPoints.onEnter(entityGUID)
        components["Core"].static.showEntityBorders = true
        SimplePolygon.editModes.appendPoints.entityGUID = entityGUID
    end

    function SimplePolygon.editModes.appendPoints.onExit()
        getComponentByType(getEntityByGUID(SimplePolygon.editModes.appendPoints.entityGUID), "SimplePolygon"):initMesh()
    end 

    function SimplePolygon.editModes.appendPoints.onMouseDown(x, y, button)
        local mode = SimplePolygon.editModes.appendPoints
        if button == "l" then 
            mode.entity = getEntityByGUID(gui.selectedEntities[1])
            if mode.entity then 
                mode.polygon = getComponentByType(mode.entity, "SimplePolygon")
                if mode.polygon then 
                    local wx, wy = camera.screenToWorld(x, y)
                    cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "SimplePolygon"):addPoint(' .. wx .. ", " .. wy .. ')')
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
        if mode.entity then 
            mode.polygon = getComponentByType(mode.entity, "SimplePolygon")
            mode.transforms = getComponentByType(mode.entity, "Transforms")
            if mode.polygon then 
                local wx, wy = camera.screenToWorld(x, y)
                if #mode.entity.__shapes > 0 and pointInBBox(mode.entity.__shapes.bbox, wx, wy) then 
                    mode.shapeIndex = nil
                    for i, shape in ipairs(mode.entity.__shapes) do 
                        if pointInPolygon(shape, wx, wy) then 
                            mode.shapeIndex = i 
                            break 
                        end 
                    end 

                    if mode.shapeIndex then 
                        if button == "r" and mode.shapeIndex <= #mode.polygon.points/2 then 
                            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "SimplePolygon"):removePoint(' .. mode.shapeIndex .. ')')
                            mode.shapeIndex = nil
                        end 

                        if button == "l" and mode.shapeIndex > #mode.polygon.points/2 then 
                            local pointIndex = mode.shapeIndex - #mode.polygon.points/2
                            local args = wx .. ", " .. wy .. ", " .. pointIndex
                            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "SimplePolygon"):addPoint(' .. args .. ')')
                        end 
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
            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "SimplePolygon"):movePoint(' .. args .. ')')
        end 
        mode.shapeIndex = nil
    end 

    -- Texture mode
    function SimplePolygon.editModes.editTexture.onMouseDown(x, y, button) 
        local mode = SimplePolygon.editModes.editTexture
        mode.entity = getEntityByGUID(gui.selectedEntities[1])
        if mode.entity then 
            mode.polygon = getComponentByType(mode.entity, "SimplePolygon")
            mode.transforms = getComponentByType(mode.entity, "Transforms")

            if mode.transforms then 
                local wx, wy = camera.screenToWorld(x, y)
                mode.mouseAngleStart = math.atan2(wy - mode.transforms.position[2], wx - mode.transforms.position[1])
                mode.trafoRotStart = mode.polygon.textureRotation
            end

            if mode.polygon then 
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

            dx, dy = rotatePoint(dx, dy, -mode.polygon.textureRotation)
            if mode.polygon.textureScaleKeepAspect then mode.polygon.textureScale[2] = mode.polygon.textureScale[1] end 
            mode.polygon.textureOffset[1] = mode.polygon.textureOffset[1] - dx * mode.polygon.textureScale[1] / camera.scale 
            mode.polygon.textureOffset[2] = mode.polygon.textureOffset[2] - dy * mode.polygon.textureScale[2] / camera.scale 
            mode.polygon:remesh()
        end 

        if mode.rotate then 
            local wx, wy = camera.screenToWorld(x, y)
            local angle = math.atan2(wy - mode.transforms.position[2], wx - mode.transforms.position[1])
            mode.polygon.textureRotation = mode.trafoRotStart + angle - mode.mouseAngleStart
            mode.polygon:remesh()
        end 
    end 

    function SimplePolygon.editModes.editTexture.onMouseUp(x, y, button) 
        local mode = SimplePolygon.editModes.editTexture
        if mode.translate then 
            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "SimplePolygon").textureOffset = {' .. table.concat(mode.polygon.textureOffset, ", ") .. "}")
        end 
        if mode.rotate then 
            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "SimplePolygon").textureRotation = ' .. tostring(mode.polygon.textureRotation))
        end
        mode.translate = false
        mode.rotate = false
    end
end 