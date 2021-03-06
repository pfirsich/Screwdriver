do
	shortcuts = {}
	function shortcut(keys, cmd, usestack)
		shortcuts[#shortcuts+1] =  {keys, cmd, usestack or false}
	end

	function isPressed(keys)
		local delim = keys:find(",", 1, true)
		if delim == nil then
			local pressed = true
			for key in string.gmatch(keys, "([^%+]+)") do
				pressed = love.keyboard.isDown(key) and pressed
			end
			return pressed
		else
			return isPressed(keys:sub(1, delim-1)) or isPressed(keys:sub(delim+1))
		end
	end

	function checkAndExecShortcuts()
		for _, shortcut in ipairs(shortcuts) do
			if isPressed(shortcut[1]) then
				if shortcut[3] then
					cliExec(shortcut[2])
				else
					cliExec_nostack(shortcut[2])
				end
				break
			end
		end
	end

	function getShortcut(keys)
		for _, shortcut in ipairs(shortcuts) do
			for str in string.gmatch(shortcut[1], "([^,]+)") do
				if str == keys then
					return shortcut
				end
			end
		end
	end

	function simulateShortcut(keys)
		local shortcut = getShortcut(keys)
		if shortcut then
			if shortcut[3] then
				cliExec(shortcut[2])
			else
				cliExec_nostack(shortcut[2])
			end
		end
	end

	function printShortcut(keys)
		local shortcut = getShortcut(keys)
		if shortcut then
			gui.printConsole("keys: " .. shortcut[1] .. ", uses map stack: " .. tostring(shortcut[3]) .. ", command: " .. shortcut[2])
		else
			gui.printConsole("No shortcut found matching this key combination.")
		end
	end

	shortcut("lctrl+a,rctrl+a", "gui.selectEntities(table.map(map.entities, function(entity) return entity.guid end))")
	shortcut("lalt+a,ralt+a", "gui.selectEntities({})")
	shortcut("lctrl+z,rctrl+z", "mapStack:seek(-1)")
	shortcut("lctrl+y,rctrl+y", "mapStack:seek(1)")
	shortcut("lctrl+f,rctrl+f", "editor.focusCamera(gui.selectedEntities)")
	shortcut("lctrl+lalt", "editor.snapMouseToGrid()")
	shortcut("capslock", 'toggle(components["Core"].static, "showMouseWorldPosition")', false)

	shortcut("lctrl+s,rctrl+s", 'editor.saveMap()')
	shortcut("f1", 'gui.sceneWindow:toggle()')
	shortcut("f2", 'gui.propertyWindow:toggle()')
	shortcut("f3", 'gui.consoleWindow:toggle()')

	-- use the stack for these, since onEnter and onExit could change something in the map object
	shortcut(" ", "editor.changeEditMode(editor.defaultEditMode)", true)
	shortcut("t", 'editor.changeEditMode(components["Transforms"].editModes.move)', true)
	shortcut("r", 'editor.changeEditMode(components["Transforms"].editModes.rotate)', true)
	shortcut("e", 'editor.changeEditMode(components["Transforms"].editModes.scale)', true)
	shortcut("q", 'editor.changeEditMode(components["SimplePolygon"].editModes.editPoints)', true)
	shortcut("w", 'editor.changeEditMode(components["SimplePolygon"].editModes.editTexture)', true)
	shortcut("h", 'editor.changeEditMode(components["BorderedFannedPolygon"].editModes.editFanEdges)', true)

	shortcut("tab", 'toggle(components["Core"].static, "showEntityBorders"); toggle(components["Core"].static, "showNames")', true)
	shortcut("c", 'toggle(components["Transforms"].static, "showCenterMarkers")', true)
	shortcut("g", 'toggle(components["Core"].static, "showGrid")', true)
	shortcut("pageup", "editor.entityUp(gui.selectedEntities)", true)
	shortcut("pagedown", "editor.entityDown(gui.selectedEntities)", true)
	shortcut("delete", "editor.removeEntities(gui.selectedEntities)", true)
	shortcut("lctrl+d,rctrl+d", "editor.duplicateEntities(gui.selectedEntities)", true)
end