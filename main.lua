require "class"
require "gui"
require "components"
require "entities"
require "editor"
require "misc"
require "binds"
require "map"
require "camera"

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

	-- take into account camera.scale, camera.position and make lines through origin thicker
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
	end
end

function love.mousereleased(x, y, button)
	gui.base:mouseReleased(x, y, button)
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
	camera.scale = math.pow(1.07, camera.zoomLevel) 

	if components["Core"].static.showGrid then 
		love.graphics.setShader(gridShader)
		gridShader:send("cameraScale", camera.scale)
		gridShader:send("cameraPos", {camera.position[1] - love.window.getWidth()/2/camera.scale, camera.position[2] + love.window.getHeight()/2/camera.scale})
		gridShader:send("spacing", components["Core"].static.gridSpacing)
		love.graphics.rectangle("fill", 0, 0, love.window.getWidth(), love.window.getHeight())
		love.graphics.setShader()
	end

	camera.push()
		love.graphics.rectangle("fill", 0, 0, 100, 100)
		love.graphics.rectangle("fill", 200, 200, 100, 100)
	camera.pop()
	gui.base:draw()
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
