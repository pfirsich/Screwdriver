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
			end 
		end 
	end

	shortcut("lctrl+a,rctrl+a", "gui.entityList.selected = tableCopy(gui.entityList.tree.children)")
	shortcut("lctrl+d,rctrl+d", "gui.entityList.selected = {}")
	shortcut("lctrl+z,rctrl+z", "mapStack:seek(-1)")
	shortcut("lctrl+y,rctrl+y", "mapStack:seek(1)")
end