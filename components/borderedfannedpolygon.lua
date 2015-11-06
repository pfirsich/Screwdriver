require "borderedFannedPolygons_simple"

do
    local BorderedFannedPolygon = class(components["SimplePolygon"])
    components["BorderedFannedPolygon"] = BorderedFannedPolygon

    function BorderedFannedPolygon:init(properties)
    	-- HAX HAX HAX HAX
        -- SimplePolygon's constructor is not called because we don't want to enter the appendPoints editMode, if we create this component from a file
        -- also only two properties from there are used here anyways
        -- components["SimplePolygon"].init(self, {})
        self.renderWireframe = false
        self.points = {}

        self.baseColor = {255, 255, 255, 255}
        self.borderColor = {255, 255, 255, 255}
        self.baseImagePath = ""
        self.borderImagePath = ""
        self.borderThickness = 1
        self.blendThickness = 1
        self.textureTransforms = {
            scale = {1.0, 1.0},
            offset = {0.0, 0.0},
            rotation = 0,
        }

        self.fanImagePath = ""
        self.fanOffset = 0
        self.fanHeight = 50 -- HAX HAX HAX. Setting this when an image is loaded resets values loaded from a file.
        self.fanTextureScale = 1.0
        self.fanEdgeMask = {}
    	addTable(self, properties)

        local remeshOnChange = function() 
            -- this should never fail, since it is only called when all of these sub calls will succeed
            getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "BorderedFannedPolygon"):remesh() 
        end
        self.__guiElements = {
            {variable = "", type = "Button", label = "Edit Vertices", cmd = 'simulateShortcut("q")'},
            {variable = "", type = "Button", label = "Edit Texture", cmd = 'simulateShortcut("w")'},
            {variable = "", type = "Button", label = "Edit fan edges", cmd = 'simulateShortcut("h")'},
            {type = "Line"},
            {variable = "baseImagePath", type = "File", label = "Base image"},
            {variable = "baseColor", type = "Color", label = "Base color"},
            {variable = "borderImagePath", type = "File", label = "Border image"},
            {variable = "borderColor", type = "Color", label = "Border color"},
            {variable = "borderThickness", type = "Numberwheel", label = "Border thickness", params = {minValue = 1, speed = 5.0, onChange = remeshOnChange}},
            {variable = "blendThickness", type = "Numberwheel", label = "Blend thickness", params = {minValue = 1, speed = 5.0, onChange = remeshOnChange}},
            {type = "Line"},
            {variable = "textureTransforms.scale[1]", type = "Numberwheel", label = "X-Texture scale", params = {speed = 0.5, onChange = remeshOnChange}},
            {variable = "textureTransforms.scale[2]", type = "Numberwheel", label = "Y-Texture scale", params = {speed = 0.5, onChange = remeshOnChange}},
            {variable = "textureTransforms.offset[1]", type = "Numberwheel", label = "X-Texture offset", params = {speed = 5.0, onChange = remeshOnChange}},
            {variable = "textureTransforms.offset[2]", type = "Numberwheel", label = "Y-Texture offset", params = {speed = 5.0, onChange = remeshOnChange}},
            {variable = "textureTransforms.rotation", type = "Numberwheel", label = "Texture angle", params = {speed = 1.0, onChange = remeshOnChange}},
            {type = "Line"},
            {variable = "fanImagePath", type = "File", label = "Fan image"},
            {variable = "fanOffset", type = "Numberwheel", label = "Fan offset", params = {speed = 5.0, onChange = remeshOnChange}},
            {variable = "fanHeight", type = "Numberwheel", label = "Fan height", params = {speed = 5.0, onChange = remeshOnChange}},
            {variable = "fanTextureScale", type = "Numberwheel", label = "Fan texture scale", params = {speed = 0.5, onChange = remeshOnChange}},
            {type = "Line"},
            {variable = "renderWireframe", type = "Checkbox", label = "Render as wireframe (debug)"},
        }

        if #self.points == 0 then 
            editor.changeEditMode(BorderedFannedPolygon.editModes.appendPoints)
            gui.printConsole("New polygon entity created. Changed edit mode to append points mode!")
        end
    end

    function BorderedFannedPolygon:updateUserdataValues()
        self:loadImageFiles()
        self:remesh()
    end 

    function BorderedFannedPolygon:loadImageFiles()
        if self.baseImagePath ~= "" then 
            self.__baseImage = getImage(self.baseImagePath)
            if self.__baseImage then self.__baseImage:setWrap("repeat", "repeat") end
        end

        if self.borderImagePath ~= "" then 
            self.__borderImage = getImage(self.borderImagePath)
            if self.__borderImage then self.__borderImage:setWrap("repeat", "repeat") end
        end

        if self.fanImagePath ~= "" then 
            local img = getImage(self.fanImagePath)
            if img and img ~= self.__fanImage then 
                img:setWrap("repeat", "clamp")
                if self.__fanMesh then self.__fanMesh:setTexture(img) end
            end 
            self.__fanImage = img 
        end 
    end


    function BorderedFannedPolygon:remesh()
        if #self.points >= 6 and self.buildMesh then 
            local imgWidth, imgHeight = 1, 1
            if self.__baseImage then 
                imgWidth, imgHeight = imgWidth + self.__baseImage:getWidth(), imgHeight + self.__baseImage:getHeight()
            end 
            if self.__borderImage then 
                imgWidth, imgHeight = imgWidth + self.__borderImage:getWidth(), imgHeight + self.__borderImage:getHeight()
            end 
            if self.__baseImage and self.__borderImage then 
                imgWidth, imgHeight = imgWidth / 2.0, imgHeight / 2.0
            end 
            
            local vertices = buildPolygonGeometry(self.points, self.borderThickness, self.blendThickness)
            for i = 1, #vertices do
                local vertex = vertices[i] 
                vertex[3], vertex[4] = transformTexCoords(vertex[1], vertex[2], imgWidth, imgHeight, self.textureTransforms)
            end 
            self.__mesh = love.graphics.newMesh(vertices, nil, "triangles")

            if self.__fanImage then 
                local fanVertices = buildFanGeometry(self.points, self.fanOffset, self.fanHeight, self.fanEdgeMask)
                for i = 1, #fanVertices do fanVertices[i][3] = fanVertices[i][3] / self.__fanImage:getWidth() * self.fanTextureScale end
                self.__fanMesh = #fanVertices > 1 and love.graphics.newMesh(fanVertices, self.__fanImage, "triangles") or nil
            end 
        end
    end 

    function BorderedFannedPolygon:getShapes()
        if editor.editMode == BorderedFannedPolygon.editModes.editFanEdges then 
            local ret = {}
            if #self.points >= 6 then
                for i = 1, #self.points, 2 do 
                    local ni = i + 2
                    if ni > #self.points then ni = 1 end
                    table.insert(ret, getLineShape(self.points[i], self.points[i+1], self.points[ni], self.points[ni+1], 0, 20.0/camera.scale))
                end 
            end 
            return ret
        else 
            return components["SimplePolygon"].getShapes(self)
        end 
    end 

    local borderedFannedShader = love.graphics.newShader([[
        extern Image baseTexture;
        extern Image borderTexture;
        extern vec4 baseColor;
        extern vec4 borderColor;

        vec4 effect(vec4 blend, Image unused, vec2 textureCoords, vec2 screenCoords) {
            return vec4(mix(Texel(baseTexture, textureCoords) * baseColor, Texel(borderTexture, textureCoords) * borderColor, blend));
        }
    ]])

    function BorderedFannedPolygon:renderStart()
        if self.renderWireframe then love.graphics.setWireframe(true) end
        
        if self.__mesh then 
            love.graphics.setShader(borderedFannedShader)
            if self.__baseImage then borderedFannedShader:send("baseTexture", self.__baseImage) end
            if self.__borderImage then borderedFannedShader:send("borderTexture", self.__borderImage) end
            borderedFannedShader:send("baseColor", table.map(self.baseColor, function(v) return v/255 end))
            borderedFannedShader:send("borderColor", table.map(self.borderColor, function(v) return v/255 end))
            love.graphics.draw(self.__mesh)
            love.graphics.setShader()
        end

        if self.__fanMesh then 
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.draw(self.__fanMesh)
        end 
        if self.renderWireframe then love.graphics.setWireframe(false) end
    end

    function BorderedFannedPolygon:getTextureTransformsToEdit()
        return "textureTransforms"
    end

    BorderedFannedPolygon.static.__unique = true
    BorderedFannedPolygon.static.__pickable = true

    BorderedFannedPolygon.static.__guiElements = {}

    BorderedFannedPolygon.editModes = {
        appendPoints = components["SimplePolygon"].editModes.appendPoints,
        editPoints = components["SimplePolygon"].editModes.editPoints,
        editTexture = components["SimplePolygon"].editModes.editTexture,
        editFanEdges = {description = "Left click to add a fan to an edge, right click to remove it.", fixedSelection = true},
    }

    function BorderedFannedPolygon.editModes.editFanEdges.onMouseDown(x, y, button)
        BorderedFannedPolygon.editModes.editFanEdges.onMouseMove(x, y, 0, 0)
    end 

    function BorderedFannedPolygon.editModes.editFanEdges.onMouseMove(x, y, dx, dy)
        if love.mouse.isDown("l") or love.mouse.isDown("r") then 
            local mode = BorderedFannedPolygon.editModes.editFanEdges
            mode.entity = getEntityByGUID(gui.selectedEntities[1])
            if mode.entity and mode.entity.__pickableComponent then 
                mode.polygon = getComponentById(mode.entity, mode.entity.__pickableComponent)
                if mode.polygon and mode.polygon.fanEdgeMask then 
                    local wx, wy = camera.screenToWorld(x, y)
                    mode.shapeIndex = pickShapeFromEntity(wx, wy, mode.entity)
                    if mode.shapeIndex then 
                        mode.polygon.fanEdgeMask[mode.shapeIndex] = love.mouse.isDown("r")
                        mode.polygon:remesh()
                    end 
                end 
            end 
        end
    end 

    function BorderedFannedPolygon.editModes.editFanEdges.onMouseUp(x, y, button) 
        local mode = BorderedFannedPolygon.editModes.editFanEdges
        if (button == "l" or button == "r") and mode.polygon and mode.polygon.fanEdgeMask then 
            local str = "{" 
            for i, v in pairs(mode.polygon.fanEdgeMask) do 
                if v == true then str = str .. "[" .. i .. "] = true, " end
            end 
            str = str .. "}"
            cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "'..mode.polygon.componentType..'").fanEdgeMask = ' .. str)
        end 
    end 
end

