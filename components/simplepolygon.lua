-- SimplePolygon
-- boolean für ganze textur statt polygon rendern
-- editModes
--     appendPoints - fixedSelection = true, no shapes
--     editPoints - fixedSelection = true, shapes = edges and vertices. vertices and edges should have the same size (independent of camera.scale)
--         left click on edges adds points
--         drag&drop points
--         right click removes points
--     editTextures - fixedSelection = true, shapes = polygon
--         drag&drop move
--         rotate around center
--         scale around center

do
    local SimplePolygon = class()
    components["SimplePolygon"] = SimplePolygon

    function SimplePolygon:init(properties)
        self.imagePath = ""
        self.color = {255, 255, 255, 255}
        self.renderWholeTexture = false
        self.points = {}
        addTable(self, properties)
        if self.imagePath ~= "" then self:loadImageFile(self.imagePath) end

        self.__guiElements = {
            {variable = "", type = "Button", label = "Append Points", cmd = 'editor.editMode = components["SimplePolygon"].editModes.appendPoints'},
            {variable = "", type = "Button", label = "Edit Points", cmd = 'editor.editMode = components["SimplePolygon"].editModes.editPoints'},
            {variable = "color", type = "Color", label = "Color", cmd = ""},
            {variable = "imagePath", type = "File", label = "Image", cmd = ""},
            {variable = "", type = "Button", label = "Load Image", cmd = ":loadImageFile()"},
            {variable = "renderWholeTexture", type = "Checkbox", label = "Render whole texture"},
        }

        self.__hidden = false
    end

    function SimplePolygon:loadImageFile()
        local attr, err = lfs.attributes(self.imagePath)
        if attr == nil then 
            error("Attributes of image file could not be checked - '" .. self.imagePath .. "': " .. err)
        end
        if attr.mode ~= "file" then 
            error("'" .. self.imagePath .. "' is not a file.")
        end
        
        self.__image = getImage(self.imagePath)
        self.__image:setWrap("repeat", "repeat")
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

    function SimplePolygon:renderStart()
        love.graphics.setColor(unpack(self.color))
        if self.__image then 
        else 
        	if #self.points >= 6 then 
        		love.graphics.polygon("fill", self.points)
        		love.graphics.setColor(0, 0, 0, 255)
        		love.graphics.setLineWidth(4.0/camera.scale)
        		love.graphics.circle("line", 0, 0, 15 / camera.scale, 12)
        		love.graphics.setColor(255, 255, 255, 255)
        		love.graphics.setLineWidth(2.0/camera.scale)
        		love.graphics.circle("line", 0, 0, 15 / camera.scale, 12)
        	end
        end
    end

    SimplePolygon.static.__unique = true
    SimplePolygon.static.__pickable = true

    SimplePolygon.static.__guiElements = {}

    SimplePolygon.editModes = {
    	appendPoints = {description = "Append points to the polygon (initialization)", fixedSelection = true},
    	editPoints = {description = "Left click on edge to add vertex, right click vertex to remove, drag&drop vertices to move", fixedSelection = true}
	}

	function SimplePolygon:addPoint(x, y, index)
    	local transforms = getComponentByType(getEntityByComponent(self), "Transforms")
    	index = index ~= nil and index*2+1 or #self.points+1
		table.insert(self.points, index, y - transforms.position[2])
		table.insert(self.points, index, x - transforms.position[1])
		self:recenter()
	end

	function SimplePolygon:removePoint(index)
		table.remove(self.points, index*2 - 1)
		table.remove(self.points, index*2 - 1)
		self:recenter()
	end 

	function SimplePolygon:movePoint(index, x, y) -- index is point index, x and y are absolute in world space
		local i = index * 2 - 1
		self.points[i+0] = x
    	self.points[i+1] = y
    	self:recenter()
	end

	-- append mode
	-- on enter: entityborders on
    function SimplePolygon.editModes.appendPoints.onMouseDown(x, y, button)
        local mode = SimplePolygon.editModes.appendPoints
        if button == "l" then 
            mode.entity = getEntityByGUID(gui.selectedEntities[1])
            if mode.entity then 
                mode.polygon = getComponentByType(mode.entity, "SimplePolygon")
                if mode.polygon then 
                	local wx, wy = camera.screenToWorld(x, y)
                	cliExec('getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "SimplePolygon"):addPoint(' .. wx .. ", " .. wy .. ')')
        			print(tostringArray(mode.polygon.points))
                end 
            end 
        end
    end

    -- edit points
    function SimplePolygon.editModes.editPoints.onMouseDown(x, y, button) 
    	local mode = SimplePolygon.editModes.editPoints
    	mode.entity = getEntityByGUID(gui.selectedEntities[1])
    	if mode.entity then 
    		mode.polygon = getComponentByType(mode.entity, "SimplePolygon")
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
        					print(tostringArray(mode.polygon.points))
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
    		local i = mode.shapeIndex * 2 - 1
    		mode.polygon.points[i+0] = mode.polygon.points[i+0] + dx / camera.scale
    		mode.polygon.points[i+1] = mode.polygon.points[i+1] + dy / camera.scale
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
end 