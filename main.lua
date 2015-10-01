require "class"
require "gui"
require "components"
require "entities"
require "editor"
require "misc"
require "binds"
require "map"

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

	love.keyboard.setKeyRepeat(true)
end

function love.update()
	-- updateGUI has to be in front of :update(), because update builds the linearizedTree for TreeView widgets in there and updateGUI updates the selected list continuously
	updateGUI()
	gui.base:update()
end

function love.mousepressed(x, y, button)
	gui.base:mousePressed(x, y, button)
end

function love.mousereleased(x, y, button)
	gui.base:mouseReleased(x, y, button)
end

function widgetToString(widget)
	return widget.type .. (widget.text and " (" .. widget.text .. ")" or "")
end

function love.mousemoved(x, y, dx, dy)
	-- these are two different things, because I want every event to be completely symmetric and behave the same no matter where it was called
	gui.base:pickHovered(x, y)
	gui.base:mouseMove(x, y, dx, dy)

	if gui.base.hovered and gui.base.hovered.cliCmd then 
		gui.consoleWindow:setParam("text", "Console - Hovering: '" .. gui.base.hovered.cliCmd .. "'")
	else 
		gui.consoleWindow:setParam("text", "Console")
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
	gui.base:draw()

	if gui.base.hovered == nil then
		-- in editor view, not hovering GUI elements
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