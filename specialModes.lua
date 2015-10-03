specialMode = nil

function callSpecialMode(funcName, ...)
	if specialMode then 
		if specialMode[funcName] then specialMode[funcName](...) end
		return true
	end 
	return false
end

-- Startup: Load or New file
startupMode = {}

function startupMode.enter()
	specialMode = startupMode
	startupMode.resize(love.window.getDimensions())
end 

function startupMode.resize(w, h)
	local centerMargin = 10
	startupMode.newButton:setParam("position", {w/2 - startupMode.newButton.width/2, h/2 - startupMode.newButton.height - centerMargin})
	startupMode.loadButton:setParam("position", {w/2 - startupMode.newButton.width/2, h/2 + centerMargin})
end

function startupMode.setupMapDirectory(mapPath)
	local path, file = paths.splitFile(mapPath)
	lfs.chdir(path)
	return file
end

function startupMode.load()
	startupMode.guiBase = kraid.widgets.Base()
	startupMode.newButton = kraid.widgets.Button{parent = startupMode.guiBase, width = 250, height = 60, text = "New map file", 
		onClicked = function() filebrowserMode.enter(
			function(path) -- chose file
				editor.saveMapFile(startupMode.setupMapDirectory(path))
				specialMode = nil
				love.resize(love.window.getDimensions()) -- in case the window got resized during the file browsing
			end,
			function() -- cancel 
				startupMode.enter()
			end)
		end}
	startupMode.loadButton = kraid.widgets.Button{	parent = startupMode.guiBase, width = 250, height = 60, text = "Load map file", 
		onClicked = function() filebrowserMode.enter(
			function(path) -- chose file
				editor.loadMapFile(startupMode.setupMapDirectory(path))
				specialMode = nil
				love.resize(love.window.getDimensions())
			end,
			function() -- cancel 
				startupMode.enter()
			end) 
		end}
	startupMode.resize(love.window.getDimensions())
end 

function startupMode.update()
	startupMode.guiBase:update()
end 

function startupMode.mousepressed(x, y, button)
	startupMode.guiBase:getGrandParent():setSubTree("focused", nil)
	startupMode.guiBase:mousePressed(x, y, button)
end 

function startupMode.mousereleased(x, y, button)
	startupMode.guiBase:mouseReleased(x, y, button)
end 

function startupMode.mousemoved(x, y, dx, dy)
	startupMode.guiBase:pickHovered(x, y)
	startupMode.guiBase:mouseMove(x, y, dx, dy)
end 

function startupMode.textinput(text)
	if startupMode.guiBase.focused then
		startupMode.guiBase.focused:textInput(text)
	end
end 

function startupMode.keypressed(key, isrepeat)
	if startupMode.guiBase.focused then
		startupMode.guiBase.focused:keyPressed(key, isrepeat)
	end
	loveBackend.cutCopyPaste(startupMode.guiBase)
end

function startupMode.draw()
	startupMode.guiBase:draw()
end

-- Filebrowser
-- TODO File information: size, last changed, numberwheel for preview size
filebrowserMode = {
	elementSpacing = 20,
	panelHeight = 200,
	nameHeight = 30
}

function filebrowserMode.getImage(path)

end

function filebrowserMode.cd(path)
	filebrowserMode.elements = {}
	filebrowserMode.selected = 0
	filebrowserMode.currentDir = path
	filebrowserMode.inputLine:setParam("text", "")
	filebrowserMode.inputLine:onChange()
	filebrowserMode.scrollBar:setParam("value", 0)

	for file in lfs.dir(path) do 
		if file ~= "." then 
			local attr, err = lfs.attributes(path .. "/" .. file)
			assert(attr, err)
			local element = {path = file, attr = attr, lastClicked = 0}
			
			if attr.mode == "file" then 
				local ext = paths.getExt(file):lower()
				-- list from here: http://openil.sourceforge.net/features.php (some missing)
				if ext == "png" or ext == "bmp" or ext == "jpg" or ext == "jpeg" or ext == "tga" then  
					element.image = getImage(path .. "/" .. file)
				end
			end
			table.insert(filebrowserMode.elements, element)
		end
	end

	table.sort(filebrowserMode.elements, function(a, b)
		if a.attr.mode == "directory" and b.attr.mode ~= "directory" then 
			return true
		elseif b.attr.mode == "directory" and a.attr.mode ~= "directory" then
			return false
		else
			return a.path:lower() < b.path:lower()
		end
	end)
	-- preload images
end 

function filebrowserMode.enter(loadCB, cancelCB) -- always passes paths relative to the lfs.currentdir()
	specialMode = filebrowserMode
	filebrowserMode.okButton:setParam("onClicked", function() 
		local path = filebrowserMode.pathLabel.text:sub(7)
		local attr, err = lfs.attributes(path)
		if attr and attr.mode == "directory" then 
			filebrowserMode.cd(path)
		else
			local relative = paths.makeRelative(lfs.currentdir(), path)
			print("File:", path, "Relative:", relative)
			loadCB(relative) 
		end
	end)
	filebrowserMode.cancelButton:setParam("onClicked", cancelCB)
	filebrowserMode.resize(love.window.getDimensions())
	-- lfs.currentdir() instead of "." lets the filebrowser handle all paths absolutely. 
	-- This is necessary to normalize paths starting with .. (or having them relatively in the front)
	filebrowserMode.cd(lfs.currentdir()) 
end 

function filebrowserMode.resize(w, h)
	local margin = 10
	local buttonY = h - margin - filebrowserMode.okButton.height
	filebrowserMode.cancelButton:setParam("position", {w - margin - filebrowserMode.cancelButton.width, buttonY})
	filebrowserMode.okButton:setParam("position", {filebrowserMode.cancelButton.position[1] - margin - filebrowserMode.okButton.width, buttonY})
	filebrowserMode.inputLine:setParam("position", {margin, h - margin - filebrowserMode.inputLine.height})
	filebrowserMode.inputLine:setParam("width", filebrowserMode.okButton.position[1] - margin * 2)
	filebrowserMode.pathLabel:setParam("position", {margin, filebrowserMode.inputLine.position[2] - margin - filebrowserMode.pathLabel.height})
	local buttonTop = filebrowserMode.okButton.position[2] - margin
	filebrowserMode.previewSizeWheel:setParam("position", {filebrowserMode.okButton.position[1], buttonTop - filebrowserMode.previewSizeWheel.height})
	filebrowserMode.previewSizeWheel:setParam("maxValue", love.window.getWidth() - filebrowserMode.elementSpacing*2 - filebrowserMode.scrollBar.width)
	filebrowserMode.previewSizeWheel:setParam("value", filebrowserMode.previewSizeWheel.value) -- to clamp it
	local labelY = filebrowserMode.previewSizeWheel.position[2] + filebrowserMode.previewSizeWheel.height/2 - filebrowserMode.previewSizeLabel.height/2
	filebrowserMode.sizeLabel:setParam("position", {margin, labelY})
	filebrowserMode.lastChangedLabel:setParam("position", {margin + 200, labelY})
	filebrowserMode.previewSizeLabel:setParam("position", {filebrowserMode.previewSizeWheel.position[1] - filebrowserMode.previewSizeLabel.width, labelY})
	filebrowserMode.panelHeight = h - (filebrowserMode.previewSizeWheel.position[2] - margin)
	filebrowserMode.scrollBar:setParam("position", {w - filebrowserMode.scrollBar.width, 0})
	filebrowserMode.scrollBar:setParam("length", h - filebrowserMode.panelHeight)
end

function filebrowserMode.load()
	filebrowserMode.guiBase = kraid.widgets.Base()

	local theme = filebrowserMode.guiBase.theme
	local darkTextLabelTheme = {Label = theme.Label, colors = tableDeepCopy(theme.colors)}
	darkTextLabelTheme.colors.text = {130, 130, 130, 255}

	filebrowserMode.okButton = kraid.widgets.Button{parent = filebrowserMode.guiBase, width = 200, height = 50, text = "OK"}
	filebrowserMode.cancelButton = kraid.widgets.Button{parent = filebrowserMode.guiBase, width = 200, height = 50, text = "Cancel"}
	filebrowserMode.pathLabel = kraid.widgets.Label{parent = filebrowserMode.guiBase}
	filebrowserMode.scrollBar = kraid.widgets.Scrollbar{parent = filebrowserMode.guiBase, vertical = true}
	filebrowserMode.inputLine = kraid.widgets.LineInput{parent = filebrowserMode.guiBase}
	filebrowserMode.sizeLabel = kraid.widgets.Label{parent = filebrowserMode.guiBase, text = "Size: ", theme = darkTextLabelTheme}
	filebrowserMode.lastChangedLabel = kraid.widgets.Label{parent = filebrowserMode.guiBase, text = "Last changed: ", theme = darkTextLabelTheme}
	filebrowserMode.previewSizeLabel = kraid.widgets.Label{parent = filebrowserMode.guiBase, text = "Preview size: "}
	filebrowserMode.previewSizeWheel = kraid.widgets.Numberwheel{parent = filebrowserMode.guiBase, speed = 5.0, minValue = 60, value = 200}

	filebrowserMode.inputLine:setParam("onChange", function(self)
		filebrowserMode.pathLabel:setParam("text", "Path: " .. paths.normalize(filebrowserMode.currentDir .. "/" .. self.text))
		for i, element in ipairs(filebrowserMode.elements) do 
			if element.path == self.text then 
				filebrowserMode.selected = i
				-- focus element
				local elemFrom = element.y - filebrowserMode.scroll * filebrowserMode.scrollBar.value
				local elemTo = elemFrom + filebrowserMode.previewSize + filebrowserMode.nameHeight

				local viewHeight = love.window.getHeight() - filebrowserMode.panelHeight
				if elemTo > viewHeight then 
					-- elemTo = viewTo = viewFrom + viewHeight = viewHeight - filebrowserMode.scroll * filebrowserMode.scrollBar.value
					filebrowserMode.scrollBar.value = filebrowserMode.scrollBar.value - (viewHeight - elemTo) / filebrowserMode.scroll
				elseif elemFrom < 0 then 
					filebrowserMode.scrollBar.value = filebrowserMode.scrollBar.value + elemFrom / filebrowserMode.scroll
				end 

				local attr, err = lfs.attributes(filebrowserMode.currentDir .. "/" .. element.path)
				assert(attr)
				filebrowserMode.sizeLabel:setParam("text", "Size: " .. bytesToString(attr.size))
				filebrowserMode.lastChangedLabel:setParam("text", "Last changed: " .. os.date("%d.%m.%Y %X", attr.modification))
			end 
		end 
	end)

	filebrowserMode.resize(love.window.getDimensions())
end 

function bytesToString(bytes)
	if bytes > 1024 then -- KB range
		if bytes > 1024*1024 then -- MB range
			if bytes > 1024*1024*1024 then -- GB range
				return string.format("%.2fGB", bytes/1024/1024/1024)
			end 
			return string.format("%.2fMB", bytes/1024/1024)
		end 
		return string.format("%.2fKB", bytes/1024)
	end
	return tostring(bytes) .. "Bytes"
end

function filebrowserMode.mousepressed(x, y, button)
	filebrowserMode.guiBase:getGrandParent():setSubTree("focused", nil)
	filebrowserMode.guiBase:mousePressed(x, y, button)

	if y < love.window.getHeight() - filebrowserMode.panelHeight then 
		filebrowserMode.scrollBar:onMouseDown(x, y, button)

		if button == "l" then 
			filebrowserMode.selected = 0
			filebrowserMode.sizeLabel:setParam("text", "Size: ")
			filebrowserMode.lastChangedLabel:setParam("text", "Last changed: ")

			for i, element in ipairs(filebrowserMode.elements) do 
				local ey = element.y - filebrowserMode.scroll * filebrowserMode.scrollBar.value
				if x > element.x and x < element.x + filebrowserMode.previewSize and 
					y > ey and y < ey + filebrowserMode.previewSize + filebrowserMode.nameHeight then 

					filebrowserMode.inputLine:setParam("text", element.path)
					filebrowserMode.inputLine:onChange()
					if love.timer.getTime() - element.lastClicked < 0.5 then -- default windows double click delay
						filebrowserMode.okButton:onClicked()
					end
					element.lastClicked = love.timer.getTime()
				end  
			end 

			if filebrowserMode.selected == 0 then 
				filebrowserMode.inputLine:setParam("text", "")
				filebrowserMode.inputLine:onChange()
			end
		end
	end 
end 

function filebrowserMode.mousereleased(x, y, button)
	filebrowserMode.guiBase:mouseReleased(x, y, button)
end 

function filebrowserMode.mousemoved(x, y, dx, dy)
	filebrowserMode.guiBase:pickHovered(x, y)
	filebrowserMode.guiBase:mouseMove(x, y, dx, dy)
end 

function filebrowserMode.textinput(text)
	if filebrowserMode.guiBase.focused then
		filebrowserMode.guiBase.focused:textInput(text)
	end
end 

function filebrowserMode.keypressed(key, isrepeat)
	if filebrowserMode.guiBase.focused then
		filebrowserMode.guiBase.focused:keyPressed(key, isrepeat)
	end
	loveBackend.cutCopyPaste(filebrowserMode.guiBase)
end

function filebrowserMode.update()
	filebrowserMode.previewSize = filebrowserMode.previewSizeWheel.value
	local cursorX, cursorY = filebrowserMode.elementSpacing, filebrowserMode.elementSpacing
	for i, element in ipairs(filebrowserMode.elements) do 
		element.x, element.y = cursorX, cursorY

		cursorX = cursorX + filebrowserMode.previewSize + filebrowserMode.elementSpacing
		if i < #filebrowserMode.elements and cursorX + filebrowserMode.previewSize + filebrowserMode.elementSpacing > love.window.getWidth() - filebrowserMode.scrollBar.width then 
			cursorX = filebrowserMode.elementSpacing
			cursorY = cursorY + filebrowserMode.previewSize + filebrowserMode.nameHeight + filebrowserMode.elementSpacing
		end
	end 
	cursorY = cursorY + filebrowserMode.previewSize + filebrowserMode.nameHeight + filebrowserMode.elementSpacing

	filebrowserMode.scroll = math.max(0, cursorY - (love.window.getHeight() - filebrowserMode.panelHeight))
	filebrowserMode.scrollBar.scrubberLength = (filebrowserMode.scrollBar.height - 40) * math.min(1, filebrowserMode.scrollBar.height / cursorY)
	filebrowserMode.guiBase:update()
end 

function filebrowserMode.drawFolder(ex, ey)
	love.graphics.setColor(170, 170, 170, 255)
	love.graphics.rectangle("line", ex, ey, filebrowserMode.previewSize, filebrowserMode.previewSize)

	local leftRightMargin = filebrowserMode.previewSize * 0.2
	local aspectRatio = 1.7
	local w, h = filebrowserMode.previewSize - leftRightMargin * 2
	local h = w / aspectRatio
	local x = ex + leftRightMargin
	local y = ey + filebrowserMode.previewSize / 2 - h/2
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("line", x, y, w, h)

	local bottomWidth = 0.3 * w
	local topWidth = 0.25 * w
	local widthDiff = bottomWidth - topWidth
	local startLeft = 0.05 * w
	local height = 0.1 * h
	love.graphics.polygon("line", 
		x + startLeft, y,
		x + startLeft + bottomWidth, y,
		x + startLeft + bottomWidth - widthDiff/2, y - height,
		x + startLeft + widthDiff/2, y - height
	)
end	

function filebrowserMode.drawFile(ex, ey)
	love.graphics.setColor(170, 170, 170, 255)
	love.graphics.rectangle("line", ex, ey, filebrowserMode.previewSize, filebrowserMode.previewSize)

	local width = 0.5 * filebrowserMode.previewSize
	local height = 1.41 * width
	local x, y = ex + filebrowserMode.previewSize/2 - width/2, ey + filebrowserMode.previewSize/2 - height/2
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("line", x, y, width, height)

	local lines = 5
	local lineMargin = 0.85 * width
	local lineYOffset = 0.22 * height
	local lineFactor = (height - lineYOffset * 2) / (lines-1)
	for i = 1, lines do 
		local ly = y + lineYOffset + (i-1) * lineFactor
		love.graphics.line(x + lineMargin, ly, x + width - lineMargin, ly)
	end 
end 

function filebrowserMode.draw()
	local font = love.graphics.getFont()
	for i, element in ipairs(filebrowserMode.elements) do 
		love.graphics.setScissor(0, 0, love.window.getWidth(), love.window.getHeight())
		local y = element.y - filebrowserMode.scroll * filebrowserMode.scrollBar.value

		if element.image then 
			local scalex = filebrowserMode.previewSize / element.image:getWidth()
			local scaley = filebrowserMode.previewSize / element.image:getHeight()
			local ix = element.x + filebrowserMode.previewSize/2 - scalex * element.image:getWidth()/2
			local iy = y + filebrowserMode.previewSize/2 - scaley * element.image:getHeight()/2
			local scale = math.min(scalex, scaley)
			love.graphics.draw(element.image, ix, iy, 0, scale, scale)
		else 
			if element.attr.mode == "directory" then 
				love.graphics.setColor(170, 170, 170, 255)
				filebrowserMode.drawFolder(element.x, y)
			else 
				filebrowserMode.drawFile(element.x, y)
			end
		end

		if i == filebrowserMode.selected then 
			love.graphics.setColor(255, 255, 0, 255)
			love.graphics.rectangle("line", element.x, y, filebrowserMode.previewSize, filebrowserMode.previewSize + filebrowserMode.nameHeight)
		end

		love.graphics.setColor(100, 100, 100, 100)
		love.graphics.rectangle("line", element.x, y + filebrowserMode.previewSize, filebrowserMode.previewSize, filebrowserMode.nameHeight)
		local textX = element.x + filebrowserMode.previewSize/2 - font:getWidth(element.path)/2
		local textY = y + filebrowserMode.previewSize + filebrowserMode.nameHeight/2 - font:getHeight(element.path)/2
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setScissor(element.x, y + filebrowserMode.previewSize, filebrowserMode.previewSize, filebrowserMode.nameHeight)
		love.graphics.print(element.path, textX, textY)
	end 

	love.graphics.setScissor(0, 0, love.window.getWidth(), love.window.getHeight())
	love.graphics.setColor(filebrowserMode.guiBase.theme.colors.background)
	love.graphics.rectangle("fill", 0, love.window.getHeight() - filebrowserMode.panelHeight, love.window.getWidth(), filebrowserMode.panelHeight)
	filebrowserMode.guiBase:draw()
end