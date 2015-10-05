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
require "specialModes"
require "colorpicker"

function love.resize(w, h)
	if callSpecialMode("resize", w, h) then return end

	local oldVisible = gui.sceneWindow.visible 
	gui.sceneWindow:toggle()
	gui.sceneWindow:setParam("visible", oldVisible)

	oldVisible = gui.propertyWindow.visible 
	gui.propertyWindow:toggle()
	gui.propertyWindow:setParam("visible", oldVisible)
	
	oldVisible = gui.consoleWindow.visible 
	gui.consoleWindow:toggle()
	gui.consoleWindow:setParam("visible", oldVisible)

	local center = love.window.getWidth() / 2
	local buttonW = gui.toggleSceneWindow.width
	gui.toggleSceneWindow:setParam("position", {center - buttonW * 1.5, 0})
	gui.togglePropertyWindow:setParam("position", {center - buttonW * 0.5, 0})
	gui.toggleConsoleWindow:setParam("position", {center + buttonW * 0.5, 0})
end

function love.load(arg) 
	gui = setupGUI()
	rebuildGlobalComponentGUIElements()
	updateGUI()
	love.resize(love.window.getWidth(), love.window.getHeight())

	gridShader = love.graphics.newShader([[
		uniform float cameraScale;
		uniform vec2 cameraPos;
		uniform float spacing = 100.0;
		uniform vec4 gridColor = vec4(0.7, 0.7, 0.7, 1.0); 

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
		    return mix(vec4(0.0), gridColor, vec4(clamp(gridVal, 0.0, 1.0)));
		}
	]])

	checkersShader = love.graphics.newShader([[
		#define PI2 6.2831853 
		
		// Number of squares per axis per color (5 => 5 white and 5 black squares)
		uniform float countX = 5.0; 
		uniform float countY = 5.0; 

		const vec3 color1 = vec3(0.0, 0.0, 0.0);
		const vec3 color2 = vec3(1.0, 1.0, 1.0);

		vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
			float val = step(0.0, sin(textureCoords.x*PI2*countX) * sin(textureCoords.y*PI2*countY));
			return vec4(mix(color1, color2, vec3(val)), 1.0);
		}
	]])

	local pixelImageData = love.image.newImageData(1, 1)
	pixelImageData:setPixel(0, 0, 255, 255, 255, 255)
	pixelImage = love.graphics.newImage(pixelImageData)

	love.keyboard.setKeyRepeat(true)

	filebrowserMode.load()
	startupMode.load()

	-- start
	if arg[2] then 
		local path, file = paths.splitFile(arg[2])
		lfs.chdir(path)
		editor.loadMapFile(file)
	else
		--lfs.chdir("media")
		--editor.loadMapFile("test.map")
		startupMode.enter()
	end
end

function love.quit()
	local inMode, q = callSpecialMode("quit")
	if inMode then return q end 

	if editor.unsavedChanges then 
		gui.dialogQuestion("Quit?", "This map has unsaved changes. Really quit?", "love.quit = nil; love.event.push('quit')", "")
		return true
	end
end 

function love.update()
	if callSpecialMode("update") then return end

	-- updateGUI has to be in front of :update(), because update builds the linearizedTree for TreeView widgets in there and updateGUI updates the selected list continuously
	updateGUI()
	gui.base:update()

	if gui.base.hovered and gui.base.hovered.cliCmd then 
		local suffix = ""
		if gui.base.hovered.type == "LineInput" then suffix = " - Press <enter> to apply changes" end
		gui.consoleWindow:setParam("text", "Console - Hovering: '" .. gui.base.hovered.cliCmd .. "'" .. suffix)
	else 
		gui.consoleWindow:setParam("text", "Console")
	end 

	local title = editor.currentMapFile and editor.currentMapFile .. " - Screwdriver" or "Screwdriver"
	love.window.setTitle((editor.unsavedChanges and "*" or "") .. title)

	-- if a single entity is selected (only way to have an entity be modified by edit modes or the gui), update its shape
	if #gui.selectedEntities == 1 then 
		updateShape(getEntityByGUID(gui.selectedEntities[1]))
	end 
end

function love.mousepressed(x, y, button)
	if callSpecialMode("mousepressed", x, y, button) then return end

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

		if button == "l" and not editor.editMode.fixedSelection then 
			if #editor.hoveredEntities > 0 then 					
				local ctrl = love.keyboard.isDown("lctrl") and editor.editMode == editor.defaultEditMode
				if love.keyboard.isDown("lalt") and #gui.selectedEntities == 1 then -- step down selection
					if ctrl then 
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
			else 
				gui.selectEntities({})
			end
		end
		
		if #gui.selectedEntities > 0 and editor.editMode.onMouseDown then 		
			editor.editMode.onMouseDown(x, y, button)
		end
	end
end

function love.mousereleased(x, y, button)
	if callSpecialMode("mousereleased", x, y, button) then return end

	gui.base:mouseReleased(x, y, button)
	camera.dragged = false
	
	if #gui.selectedEntities > 0 and editor.editMode.onMouseUp then 		
		editor.editMode.onMouseUp(x, y, button)
	end
end

function love.mousemoved(x, y, dx, dy)
	if callSpecialMode("mousemoved", x, y, dx, dy) then return end

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

	if #gui.selectedEntities > 0 and editor.editMode.onMouseMove then 
		editor.editMode.onMouseMove(x, y, dx, dy) 
	end
end

function love.textinput(text)
	if callSpecialMode("textinput", text) then return end

	if gui.base.focused then
		gui.base.focused:textInput(text)
	end
end

function love.keypressed(key, isrepeat)
	if callSpecialMode("keypressed", key, isrepeat) then return end

	if gui.base.focused then
		gui.base.focused:keyPressed(key, isrepeat)
	end
	loveBackend.cutCopyPaste(gui.base)
		
	-- only execute shortcuts if nothing is focused or the focused element doesn't process key press events
	if not gui.base.focused or gui.base.focused.keyPressed == kraid.widgets.Base.keyPressed then 
		checkAndExecShortcuts()
	end
end

function love.draw()
	-- For some reason the screen doesn't clear on some systems. This is dirty, but it works. I am deeply sorry.
	components["Core"].static.backgroundColor[4] = 255
	love.graphics.setColor(components["Core"].static.backgroundColor)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

	if callSpecialMode("draw") then return end

	if components["Core"].static.showGrid then 
		local bgColor = table.map(components["Core"].static.backgroundColor, function(v) return v/255 end)
		local bgLuminance = math.sqrt(0.299*bgColor[1]*bgColor[1] + 0.587*bgColor[2]*bgColor[2] + 0.114*bgColor[3]*bgColor[3])
		local gridColor = {1.0 - bgLuminance, 1.0 - bgLuminance, 1.0 - bgLuminance, 1.0}

		love.graphics.setShader(gridShader)
		gridShader:send("cameraScale", camera.scale)
		gridShader:send("cameraPos", {camera.position[1] - love.window.getWidth()/2/camera.scale, camera.position[2] + love.window.getHeight()/2/camera.scale})
		gridShader:send("spacing", components["Core"].static.gridSpacing)
		gridShader:send("gridColor", gridColor)
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
		love.graphics.setLineWidth(5.0/camera.scale)
		for _, guid in ipairs(gui.selectedEntities) do 
			local entity = getEntityByGUID(guid) 
			if entity and entity.__pickableComponent and entity.__shapes then 
				local x, y = entity.__shapes.bbox[1], entity.__shapes.bbox[2]
				local w, h = entity.__shapes.bbox[3] - entity.__shapes.bbox[1], entity.__shapes.bbox[4] - entity.__shapes.bbox[2]
				love.graphics.rectangle("line", x, y, w, h)
			end 
		end 
		love.graphics.setLineWidth(1)

		love.graphics.setColor(255, 255, 255, 255)
		if components["Core"].static.showNames then
			for _, entity in ipairs(map.entities) do
				if entity.__pickableComponent then -- TODO: check for __shapes. Check is left out, so the program actually crashes if there are no shapes at this point (because it shouldn't happen) 
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
		end
	camera.pop()

	local modeDescription = "Mode: " .. editor.editMode.description .. (editor.editMode.fixedSelection and " (selection fixed)" or "")
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
		entity.__shapes = getComponentById(entity, entity.__pickableComponent):getShapes()

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
	gui.consoleOutput:addLine("(not pushed) >> " .. cmd)
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
		-- every change to the map object is thrown away and cmd is applied to the topmost element on the mapStack
		-- then another working copy map is created
		-- if any divergences occur it will be immediately noticable by changes not showing up
		editor.unsavedChanges = true
		mapStack:push(cmd)
		map = mapStack[mapStack.cursor].map
		local ret = f()
		updateShapes() -- do this first to make sure that the mapStack has the properly updated shapes
		map = tableDeepCopy(mapStack[mapStack.cursor].map)
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
