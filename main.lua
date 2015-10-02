require "class"
require "gui"
require "components"
require "entities"
require "editor"
require "misc"
require "binds"
require "map"
require "camera"
require "lfs"

function love.resize(w, h)
	local oldVisible = gui.sceneWindow.visible 
	gui.sceneWindow:summon()
	gui.sceneWindow:setParam("visible", oldVisible)

	oldVisible = gui.propertyWindow.visible 
	gui.propertyWindow:summon()
	gui.propertyWindow:setParam("visible", oldVisible)
	
	oldVisible = gui.consoleWindow.visible 
	gui.consoleWindow:summon()
	gui.consoleWindow:setParam("visible", oldVisible)

	local center = love.window.getWidth() / 2
	local buttonW = gui.summonSceneWindow.width
	gui.summonSceneWindow:setParam("position", {center - buttonW * 1.5, 0})
	gui.summonPropertyWindow:setParam("position", {center - buttonW * 0.5, 0})
	gui.summonConsoleWindow:setParam("position", {center + buttonW * 0.5, 0})
end

function love.load() 
	gui = setupGUI()
	updateGUI()
	love.resize(love.window.getWidth(), love.window.getHeight())

	gridShader = love.graphics.newShader([[
		uniform float cameraScale;
		uniform vec2 cameraPos;
		uniform float spacing = 100.0;

		const float thickness = 1.0;
		//const float smoothness = 2.0;

		float gridFunc(float coord, float thickness) {
			return 1.0 - step(1.0/spacing*thickness, coord);
			//return smoothstep(highEdge - 1.0/spacing*smoothness, highEdge, coord);
		}

		vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
			vec2 realCoords = (screenCoords + cameraPos * cameraScale * vec2(1.0, -1.0)) / spacing / cameraScale;
			float gridVal = gridFunc(fract(realCoords.x), thickness/cameraScale) + gridFunc(fract(realCoords.y), thickness/cameraScale);
			float originMarkerFactor = 1.5;
			gridVal += gridFunc(abs(realCoords.x), thickness*originMarkerFactor/cameraScale) + gridFunc(abs(realCoords.y), thickness*originMarkerFactor/cameraScale);
		    return mix(vec4(0.0), vec4(0.7), vec4(clamp(gridVal, 0.0, 1.0)));
		}
	]])

	love.keyboard.setKeyRepeat(true)

	editor.loadMapFile("test.map")

	-- startup
	-- editor.createEntity("everything")
	-- editor.createEntity("everything")
	-- editor.createEntity("everything")
	-- editor.createEntity("everything")
	-- map.entities[1].components[2].position[1] =  400
	-- map.entities[2].components[2].position[1] = -400
	-- map.entities[3].components[2].position[2] =  400
	-- map.entities[4].components[2].position[2] = -400
	-- updateShapes()
end

function love.update()
	-- updateGUI has to be in front of :update(), because update builds the linearizedTree for TreeView widgets in there and updateGUI updates the selected list continuously
	updateGUI()
	gui.base:update()

	if gui.base.hovered and gui.base.hovered.cliCmd then 
		gui.consoleWindow:setParam("text", "Console - Hovering: '" .. gui.base.hovered.cliCmd .. "'")
	else 
		gui.consoleWindow:setParam("text", "Console")
	end 

	local title = editor.currentMapFile and editor.currentMapFile .. " - Screwdriver" or "Screwdriver"
	love.window.setTitle((editor.unsavedChanges and "*" or "") .. title)
end

function love.mousepressed(x, y, button)
	gui.base:mousePressed(x, y, button)

	if gui.base.hovered == nil then -- in editor view, not hovering GUI elements
		if button == "m" then -- drag camera
			camera.dragged = true
			camera.dragStartCamera = {camera.position[1], camera.position[2]}
			camera.dragStartMouse = {x, y}
		elseif button == "wd" then 
			camera.zoomLevel = camera.zoomLevel - 1
		elseif button == "wu" then 
			camera.zoomLevel = camera.zoomLevel + 1
		end

		if button == "l" then 
			if #editor.hoveredEntities > 0 then 					
				local ctrl = love.keyboard.isDown("lctrl") and editor.editMode == editor.defaultEditMode
				if love.keyboard.isDown("lalt") and #gui.selectedEntities == 1 then -- step down selection
					if ctrl then 
						print("select all hovered")
						gui.selectEntities(editor.hoveredEntities)
					else 
						-- if alt is pressed and only one entity is selected every new click selects an object below it
						-- if the current selected object is not hovered too, select the topmost hovered object
						local selectedHoveredIndex = nil
						for i, guid in ipairs(editor.hoveredEntities) do 
							if isEntitySelected(getEntityByGUID(guid)) then 
								selectedHoveredIndex = i 
								break 
							end
						end 

						if selectedHoveredIndex == nil then 
							selectedHoveredIndex = #editor.hoveredEntities
						else 
							selectedHoveredIndex = selectedHoveredIndex - 1
							if selectedHoveredIndex < 1 then selectedHoveredIndex = #editor.hoveredEntities end
						end 
						gui.selectEntities({editor.hoveredEntities[selectedHoveredIndex]})
					end
				else -- select topmost
					if ctrl then 
						table.insert(gui.selectedEntities, editor.hoveredEntities[#editor.hoveredEntities])
						gui.selectEntities(gui.selectedEntities)
					else 
						gui.selectEntities({editor.hoveredEntities[#editor.hoveredEntities]})
					end
				end
				if editor.editMode.onMouseDown then editor.editMode.onMouseDown(x, y, button) end
			else 
				gui.selectEntities({})
			end
		end
	end
end

function love.mousereleased(x, y, button)
	gui.base:mouseReleased(x, y, button)
	if editor.editMode.onMouseUp then editor.editMode.onMouseUp(x, y, button) end
	camera.dragged = false
end

function widgetToString(widget)
	return widget.type .. (widget.text and " (" .. widget.text .. ")" or "")
end

function love.mousemoved(x, y, dx, dy)
	gui.base:pickHovered(x, y)
	gui.base:mouseMove(x, y, dx, dy)

	if camera.dragged then 
		local gdx, gdy = x - camera.dragStartMouse[1], y - camera.dragStartMouse[2]
		camera.position = {camera.dragStartCamera[1] - gdx / camera.scale, camera.dragStartCamera[2] - gdy / camera.scale}
	end

	if gui.base.hovered == nil then 
		editor.hoveredEntities = pickEntities(camera.screenToWorld(x, y))
	else 
		editor.hoveredEntities = {}
	end 

	if editor.editMode.onMouseMove then editor.editMode.onMouseMove(x, y, dx, dy) end
end

function love.textinput(text)
	if gui.base.focused then
		gui.base.focused:textInput(text)
	end
end

function love.keypressed(key, isrepeat)
	if gui.base.focused then
		gui.base.focused:keyPressed(key, isrepeat)
	end

	if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
		if gui.base.focused and gui.base.focused.type == "LineInput" then
			if key == "x" then
				love.system.setClipboardText(gui.base.focused:cut())
			end
			if key == "c" then
				love.system.setClipboardText(gui.base.focused:selected())
			end
			if key == "v" then
				gui.base.focused:paste(love.system.getClipboardText())
			end
		end
	end

	checkAndExecShortcuts()
end

function love.draw()
	if components["Core"].static.showGrid then 
		love.graphics.setShader(gridShader)
		gridShader:send("cameraScale", camera.scale)
		gridShader:send("cameraPos", {camera.position[1] - love.window.getWidth()/2/camera.scale, camera.position[2] + love.window.getHeight()/2/camera.scale})
		gridShader:send("spacing", components["Core"].static.gridSpacing)
		love.graphics.rectangle("fill", 0, 0, love.window.getWidth(), love.window.getHeight())
		love.graphics.setShader()
	end

	camera.push()
		for _, entity in ipairs(map.entities) do
			local hovered = false
			for _, guid in ipairs(editor.hoveredEntities) do 
				if guid == entity.guid then hovered = true end 
			end 

			if not getComponentByType(entity, "Core").hidden then 
				for i = 1, #entity.components do 
					if entity.components[i].color then entity.components[i].color[4] = hovered and 200 or 255 end
					if entity.components[i].renderStart then entity.components[i]:renderStart() end
				end 

				for i = #entity.components, 1, -1 do
					if entity.components[i].renderEnd then entity.components[i]:renderEnd() end
				end 
			end
		end 

		if components["Core"].static.showEntityBorders then 
			love.graphics.setLineWidth(3.0/camera.scale)
			for _, entity in ipairs(map.entities) do
				if entity.__pickableComponent then 
					for _, shape in ipairs(entity.__shapes) do 
						love.graphics.setColor(0, 255, 0, 255)
						love.graphics.polygon("line", shape)

						love.graphics.setColor(255, 0, 0, 255)
						for i = 1, #shape, 2 do 
							--love.graphics.circle("fill", shape[i], shape[i+1], 10.0/camera.scale, 12)
						end 
					end 
				end
			end
			love.graphics.setLineWidth(1)
		end 

		love.graphics.setColor(255, 255, 0, 255)
		love.graphics.setLineWidth(3.0/camera.scale)
		for _, guid in ipairs(gui.selectedEntities) do 
			local entity = getEntityByGUID(guid) 
			if entity then 
				local x, y = entity.__shapes.bbox[1], entity.__shapes.bbox[2]
				local w, h = entity.__shapes.bbox[3] - entity.__shapes.bbox[1], entity.__shapes.bbox[4] - entity.__shapes.bbox[2]
				love.graphics.rectangle("line", x, y, w, h)
			end 
		end 
		love.graphics.setLineWidth(1)

		love.graphics.setColor(255, 255, 255, 255)
		if components["Core"].static.showNames then
			for _, entity in ipairs(map.entities) do
				local nameScale = 1.5 / camera.scale
				local name = getComponentByType(entity, "Core").name
				local width, height = love.graphics.getFont():getWidth(name) * nameScale, love.graphics.getFont():getHeight() * nameScale
				local x = (entity.__shapes.bbox[1] + entity.__shapes.bbox[3] - width) / 2
				local y = (entity.__shapes.bbox[2] + entity.__shapes.bbox[4] - height) / 2
				
				local shadowOffset = 2
				love.graphics.setColor(0, 0, 0, 255)
				love.graphics.print(name, x + shadowOffset, y + shadowOffset, 0, nameScale, nameScale)
				love.graphics.setColor(255, 255, 255, 255)
				love.graphics.print(name, x, y, 0, nameScale, nameScale)
			end 
		end
	camera.pop()

	local modeDescription = "Mode: " .. editor.editMode.description
	local winW, winH = love.window.getDimensions()
	local textW, textH = love.graphics.getFont():getWidth(modeDescription), love.graphics.getFont():getHeight()
	local shadowOffset = 2
	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.print(modeDescription, (winW - textW)/2 + shadowOffset, 20 + shadowOffset)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print(modeDescription, (winW - textW)/2, 20)

	gui.base:draw()
end

function isEntitySelected(entity)
	for _, guid in ipairs(gui.selectedEntities) do 
		if entity.guid == guid then return true end 
	end 
	return false
end 

function pointInBBox(bbox, x, y)
	return x > bbox[1] and x < bbox[3] and y > bbox[2] and y < bbox[4]
end

-- Disclaimer: this algorithm is sexy af
function pointInPolygon(polygon, x, y) -- from here: http://geomalgorithms.com/a03-_inclusion.html 
	assert(#polygon % 2 == 0)
	local function isLeft(fromx, fromy, tox, toy, x, y)
		local dirx, diry = tox - fromx, toy - fromy
		local px, py = x - fromx, y - fromy
		return dirx * py - diry * px -- cross product
	end

	local windings = 0
	for i = 1, #polygon, 2 do 
		local ni = i + 2
		if ni > #polygon then ni = 1 end 

		if polygon[i+1] <= y then 
			if polygon[ni+1] > y and isLeft(polygon[i], polygon[i+1], polygon[ni], polygon[ni+1], x, y) > 0 then 
				windings = windings + 1 
			end 
		else
			if polygon[ni+1] <= y and isLeft(polygon[i], polygon[i+1], polygon[ni], polygon[ni+1], x, y) < 0 then 
				windings = windings - 1 
			end
		end 
	end 
	return windings ~= 0
end

function pickEntities(x, y)
	local picked = {}
	for _, entity in ipairs(map.entities) do 
		if #entity.__shapes > 0 and pointInBBox(entity.__shapes.bbox, x, y) then 
			for _, shape in ipairs(entity.__shapes) do 
				if pointInPolygon(shape, x, y) then 
					table.insert(picked, entity.guid)
					break
				end 
			end 
		end
	end 
	return picked
end

function transformPoint(transforms, x, y)
	-- offset and scale 
	x = (x + transforms.offset[1]) * transforms.scale[1]
	y = (y + transforms.offset[2]) * transforms.scale[2]

	-- rotate
	local sinphi = math.sin(transforms.rotation)
	local cosphi = math.cos(transforms.rotation)
	local nx = cosphi * x - sinphi * y
	local ny = sinphi * x + cosphi * y

	-- translate and return
	return nx + transforms.position[1], ny + transforms.position[2]
end 

function updateShape(entity)
	if entity.__pickableComponent then 
		entity.__shapes = entity.__pickableComponent:getShapes()

		local transforms = getComponentByType(entity, "Transforms")
		local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
		if transforms then 
			for _, shape in ipairs(entity.__shapes) do 
				for i = 1, #shape, 2 do 
					shape[i], shape[i+1] = transformPoint(transforms, shape[i], shape[i+1])
					minX, minY = math.min(minX, shape[i]), math.min(minY, shape[i+1])
					maxX, maxY = math.max(maxX, shape[i]), math.max(maxY, shape[i+1])
				end 
			end 
		end 

		entity.__shapes.bbox = {minX, minY, maxX, maxY}
	end
end

function updateShapes()
	for _, entity in ipairs(map.entities) do 
		updateShape(entity)
	end
end

-- does not push the changes to the mapstack (mostly used for actions that don't affect the map state)
function cliExec_nostack(cmd) 
	gui.consoleOutput:addLine(">> " .. cmd)
	local f, err = loadstring(cmd)
	if f == nil then 
		gui.consoleOutput:addLine("ERROR: " .. err)
	else 
		return f() -- If this results in an error, the program WILL crash! No fix in sight.
	end
end

function cliExec(cmd)
	gui.consoleOutput:addLine(">> " .. cmd)
	local f, err = loadstring(cmd)
	if f == nil then 
		gui.consoleOutput:addLine("ERROR: " .. err)
	else 
		mapStack:push(cmd)
		local ret = f()
		updateShapes()
		return ret
	end
end 

function exec(file)
	gui.consoleOutput:addLine(">> FILE: " .. file)
	local f, err = loadfile(file)
	if f == nil then 
		gui.consoleOutput:addLine("ERROR: " .. err)
	else 
		return f()
	end
end
