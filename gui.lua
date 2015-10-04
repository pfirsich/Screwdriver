do 
	kraid = require "kraidGUI"
	loveBackend = require "kraidGUILove"

	local function widgetExecCliCmd(widget) 
		if widget.cliCmd then cliExec(widget.cliCmd) end 
	end 

	local function widgetExecCliCmd_nostack(widget)
		if widget.cliCmd then cliExec_nostack(widget.cliCmd) end 
	end

	local function collapseSiblings(self) 
		if not self.collapsed then
			for _, sibling in ipairs(self.parent.children) do
				if sibling ~= self and sibling.type == "Category" then
					sibling:setParam("collapsed", true)
				end
			end
		end
	end 

	local function collapseRearrangeSceneWindow(self) 
		collapseSiblings(self)
		gui.sceneWindowLayout:arrange()
		gui.sceneWindowScrollBar:onChange()
	end 

	local function collapseRearrangePropertyWindow(self) 
		collapseSiblings(self)
		gui.propertyWindowLayout:arrange()
		gui.propertyWindowScrollBar:onChange()
	end 

	function setupGUI()
		local gui = {}
		loveBackend.init(kraid)

		gui.base = kraid.widgets.Base()

		-- DIALOGS
		-- Notice
		local dialogNoticeWindow = kraid.widgets.Window{parent = gui.base, width = 400, height = 100, visible = false, resizable = false}
		local dialogNoticeLabel = kraid.widgets.Label{parent = dialogNoticeWindow, position = {5, 35}}
		local dialogNoticeOK = kraid.widgets.Button{parent = dialogNoticeWindow, width = 120, height = 30, text = "OK", 
									position = {dialogNoticeWindow.width/2 - 60, 60}, onClicked = function() dialogNoticeWindow:setParam("visible", false) end}
		function gui.dialogNotice(title, text) 
			dialogNoticeLabel:setParam("text", text)

			dialogNoticeWindow:setParam("visible", true)
			dialogNoticeWindow:setParam("text", title)
			dialogNoticeWindow:setParam("width", math.max(400, dialogNoticeLabel.width+10))
			local pos = {love.window.getWidth()/2 - dialogNoticeWindow.width/2, love.window.getHeight()/2 - dialogNoticeWindow.height/2}
			dialogNoticeWindow:setParam("position", pos)
		end 

		-- Yes/No Question
		local dialogQuestionWindow = kraid.widgets.Window{parent = gui.base, width = 400, height = 100, visible = false, resizable = false}
		local dialogQuestionLabel = kraid.widgets.Label{parent = dialogQuestionWindow, position = {5, 35}}
		local dialogQuestionButtonCB = 	function(self) 
											dialogQuestionWindow:setParam("visible", false)
											cliExec(self.cliCmd)
										end
		local dialogQuestionYes = kraid.widgets.Button{parent = dialogQuestionWindow, width = 120, height = 30, text = "Yes", 
									position = {15, 60}, cliCmd = "", onClicked = dialogQuestionButtonCB}
		local dialogQuestionNo = kraid.widgets.Button{parent = dialogQuestionWindow, width = 120, height = 30, text = "No", 
									position = {dialogQuestionWindow.width - 15 - 120, 60}, cliCmd = "", onClicked = dialogQuestionButtonCB}
		function gui.dialogQuestion(title, text, yesCmd, noCmd)
			dialogQuestionLabel:setParam("text", text)

			dialogQuestionWindow:setParam("visible", true)
			dialogQuestionWindow:setParam("text", title)
			dialogQuestionWindow:setParam("width", math.max(400, dialogQuestionLabel.width+10))
			local pos = {love.window.getWidth()/2 - dialogQuestionWindow.width/2, love.window.getHeight()/2 - dialogQuestionWindow.height/2}
			dialogQuestionWindow:setParam("position", pos)
			
			dialogQuestionYes.cliCmd = yesCmd
			dialogQuestionNo.cliCmd = noCmd
		end 

		-- Text input
		local dialogQuestionStringWindow = kraid.widgets.Window{parent = gui.base, width = 400, height = 120, visible = false, resizable = false}
		local dialogQuestionStringLabel = kraid.widgets.Label{parent = dialogQuestionStringWindow, position = {5, 35}}
		local dialogQuestionStringInput = kraid.widgets.LineInput{parent = dialogQuestionStringWindow, position = {5, 55}}

		local dialogQuestionStringButtonCB = function(self) 
			dialogQuestionStringWindow:setParam("visible", false)
			cliExec(dialogQuestionWindow.cmd:gsub(dialogQuestionWindow.placeholder, dialogQuestionStringInput.text))
		end

		local dialogQuestionStringOK = kraid.widgets.Button{parent = dialogQuestionStringWindow, width = 120, height = 30, text = "OK", 
									position = {15, 85}, onClicked = dialogQuestionStringButtonCB}
		local dialogQuestionStringCancel = kraid.widgets.Button{parent = dialogQuestionStringWindow, width = 120, height = 30, text = "Cancel", 
									position = {dialogQuestionStringWindow.width - 15 - 120, 85}, onClicked = function() dialogQuestionStringWindow:setParam("visible", false) end}
		function gui.dialogQuestionString(title, text, cmd, placeholder) 
			dialogQuestionStringLabel:setParam("text", text)
			dialogQuestionStringInput:setParam("text", "")

			dialogQuestionStringWindow:setParam("visible", true)
			dialogQuestionStringWindow:setParam("text", title)
			dialogQuestionStringWindow:setParam("width", math.max(400, dialogQuestionStringLabel.width+10))
			dialogQuestionStringInput:setParam("width", dialogQuestionStringWindow.width - 10)
			local pos = {love.window.getWidth()/2 - dialogQuestionStringWindow.width/2, 
						love.window.getHeight()/2 - dialogQuestionStringWindow.height/2}
			dialogQuestionStringWindow:setParam("position", pos)

			dialogQuestionWindow.placeholder = placeholder or "%%INPUT%%"
			dialogQuestionWindow.cmd = cmd
		end 

		function gui.selectEntities(guidList)
			local selection = {}
			-- i dont just assign guidList to gui.selectedEntities, because guidList could contain GUIDs not currently in use
			local selectedGUIDs = {}
			for _, guid in ipairs(guidList) do 
				for _, element in ipairs(gui.entityList.tree.children) do 
					if element.entity.guid == guid then 
						table.insert(selection, element)
						table.insert(selectedGUIDs, guid)
					end 
				end
			end 
			gui.entityList:setParam("selected", selection)

			local selectionChanged = not gui.selectedEntities or #gui.selectedEntities ~= #selectedGUIDs
			if not selectionChanged then 
				for i = 1, #gui.selectedEntities do 
					if gui.selectedEntities[i] ~= selectedGUIDs[i] then selectionChanged = true end
				end 
			end 
			gui.selectedEntities = selectedGUIDs

			if selectionChanged and #gui.entityList.selected == 1 then 
				rebuildPropertyGUIElements(gui.entityList.selected[1].entity)
			end 
		end 

		-- Scene Window
		gui.sceneWindow = kraid.widgets.Window{parent = gui.base, text = "Scene", width = 280, minWidth = 80} -- width has to be passed so close button is at the right position from the start
		gui.sceneWindow.summon = function(self)
			self:setParam("visible", true)
			self:setParam("width", self.width)
			self:setParam("height", love.window.getHeight() - 200)
			self:setParam("position", {0, 0})
		end

		gui.sceneWindowScroll = kraid.widgets.Base{parent = gui.sceneWindow, position = {0, 0}, width = 250}
		gui.sceneWindowScrollBar = kraid.widgets.Scrollbar{parent = gui.sceneWindow, vertical = true}

		gui.sceneWindowScrollBar:setParam("onChange", function(self)
			local contentHeight = select(4, gui.sceneWindowScroll:getChildrenBBox())
			local overlap = math.max(0, contentHeight - gui.sceneWindow.height)
			gui.sceneWindowScroll:setParam("position", {0, -overlap * self.value})
			gui.sceneWindowScrollBar.scrubberLength = (gui.sceneWindowScrollBar.height - 40) * math.min(1, gui.sceneWindowScrollBar.height / (contentHeight - 20))
		end)

		gui.sceneWindowLayout = kraid.layouts.LineLayout(gui.sceneWindowScroll, {["spacing"] = 5, ["padding"] = 5, ["padding-top"] = 30, ["padding-right"] = 5 + gui.sceneWindowScrollBar.width})

		gui.sceneWindowLayout:newLine()
		gui.entityTypesListLabel = kraid.widgets.Label{parent = gui.sceneWindowScroll, text = "Entity types"}
		gui.sceneWindowLayout:addWidget(gui.entityTypesListLabel)

		gui.sceneWindowLayout:newLine()
		gui.entityTypesList = kraid.widgets.TreeView{parent = gui.sceneWindowScroll, height = 200, minWidth = 50, multiSelect = false}
		gui.sceneWindowLayout:addWidget(gui.entityTypesList)

		gui.sceneWindowLayout:newLine()
		gui.entityCreateInstanceButton = kraid.widgets.Button{parent = gui.sceneWindowScroll, height = 30, minWidth = 50, text = "Create Instance",
											cliCmd = 'editor.createEntity(gui.selectedEntityType)',
											onClicked = widgetExecCliCmd}
		gui.sceneWindowLayout:addWidget(gui.entityCreateInstanceButton)

		gui.sceneWindowLayout:newLine({["spacing-vertical"] = 20})
		gui.setCustomEntitiesFile = kraid.widgets.Button{parent = gui.sceneWindowScroll, height = 30, minWidth = 50, text = "Add & Load entity file",
											cliCmd = 'editor.loadEntityFile("<path>")', 
											onClicked = function(self) 
												filebrowserMode.enter(function(path) 
													cliExec(self.cliCmd:gsub("<path>", path))
													exitSpecialMode()
												end)
											end}
		gui.sceneWindowLayout:addWidget(gui.setCustomEntitiesFile)

		gui.sceneWindowLayout:newLine()
		gui.entityListLabel = kraid.widgets.Label{parent = gui.sceneWindowScroll, text = "Entities"}
		gui.sceneWindowLayout:addWidget(gui.entityListLabel)

		gui.sceneWindowLayout:newLine()
		gui.entityList = kraid.widgets.TreeView{parent = gui.sceneWindowScroll, height = 300, minWidth = 50}
		gui.sceneWindowLayout:addWidget(gui.entityList)

		gui.sceneWindowLayout:newLine()
		gui.entityUpButton = kraid.widgets.Button{parent = gui.sceneWindowScroll, height = 30, minWidth = 50, text = "Up",
											cliCmd = 'editor.entityUp(gui.selectedEntities)', onClicked = widgetExecCliCmd}
		gui.sceneWindowLayout:addWidget(gui.entityUpButton)
		gui.entityDownButton = kraid.widgets.Button{parent = gui.sceneWindowScroll, height = 30, minWidth = 50, text = "Down",
											cliCmd = 'editor.entityDown(gui.selectedEntities)', onClicked = widgetExecCliCmd}
		gui.sceneWindowLayout:addWidget(gui.entityDownButton)

		gui.sceneWindowLayout:newLine()
		gui.entityFocusButton = kraid.widgets.Button{parent = gui.sceneWindowScroll, height = 30, minWidth = 50, text = "Focus camera",
											cliCmd = 'editor.focusCamera(gui.selectedEntities)', onClicked = widgetExecCliCmd_nostack}
		gui.sceneWindowLayout:addWidget(gui.entityFocusButton)

		gui.sceneWindowLayout:newLine({["spacing-vertical"] = 20})
		gui.entityRemoveButton = kraid.widgets.Button{parent = gui.sceneWindowScroll, height = 30, minWidth = 50, text = "Remove entity",
												cliCmd = 'editor.removeEntities(gui.selectedEntities)',
												onClicked = widgetExecCliCmd}
		gui.sceneWindowLayout:addWidget(gui.entityRemoveButton)

		gui.sceneWindow:setParam("onResize", function(window) 
			gui.sceneWindowScroll:setParam("width", window.width)
			gui.sceneWindowScrollBar:setParam("length", window.height - 25)
			gui.sceneWindowScrollBar:setParam("position", {window.width - gui.sceneWindowScrollBar.width, 25})
			gui.sceneWindowScrollBar:onChange()

			gui.sceneWindowLayout:arrange() 
		end)

		-- property window
		gui.propertyWindow = kraid.widgets.Window{parent = gui.base, text = "Properties", width = 280}
		gui.propertyWindow.summon = function(self)
			self:setParam("visible", true)
			self:setParam("width", self.width)
			self:setParam("height", love.window.getHeight() - 200)
			self:setParam("position", {love.window.getWidth() - self.width, 0})
		end 

		gui.propertyWindowLabel = kraid.widgets.Label{parent = gui.propertyWindow, text = "No entity selected.", position = {5, 30}}

		gui.propertyWindowScroll = kraid.widgets.Base{parent = gui.propertyWindow, position = {0, 0}, width = 250}
		gui.propertyWindowScrollBar = kraid.widgets.Scrollbar{parent = gui.propertyWindow, vertical = true}

		gui.propertyWindowScrollBar:setParam("onChange", function(self)
			local contentHeight = select(4, gui.propertyWindowScroll:getChildrenBBox())
			local overlap = math.max(0, contentHeight - gui.sceneWindow.height)
			gui.propertyWindowScroll:setParam("position", {0, -overlap * self.value})
			gui.propertyWindowScrollBar.scrubberLength = (gui.propertyWindowScrollBar.height - 40) * math.min(1, gui.propertyWindowScrollBar.height / (contentHeight - 20))
		end)

		gui.propertyWindowLayout = kraid.layouts.LineLayout(gui.propertyWindowScroll, {["spacing"] = 5, ["padding"] = 5, ["padding-top"] = 30, ["padding-right"] = 5 + gui.propertyWindowScrollBar.width})

		gui.propertyWindow:setParam("onResize", function(self) 
			gui.propertyWindowScroll:setParam("width", self.width)
			gui.propertyWindowScrollBar:setParam("length", self.height - 25)
			gui.propertyWindowScrollBar:setParam("position", {self.width - gui.propertyWindowScrollBar.width, 25})
			gui.propertyWindowScrollBar:onChange()

			gui.propertyWindowLayout:arrange()
		end)

		-- CLI window
		gui.consoleWindow = kraid.widgets.Window{parent = gui.base, text = "Console", width = love.window.getWidth()}
		gui.consoleWindow.summon = function(self)
			self:setParam("visible", true)
			self:setParam("width", love.window.getWidth())
			self:setParam("height", 200)
			self:setParam("position", {0, love.window.getHeight() - self.height})
		end 

		gui.consoleOutput = kraid.widgets.Label{parent = gui.consoleWindow, text = "", position = {0, 25}}

		gui.consoleInput = kraid.widgets.LineInput{parent = gui.consoleWindow}
		gui.consoleWindowScrollBar = kraid.widgets.Scrollbar{parent = gui.consoleWindow, vertical = true, value = 1.0}

		gui.consoleWindowScrollBar:setParam("onChange", function() 
			local diff = math.max(0, gui.consoleOutput.height - (gui.consoleWindow.height - gui.consoleInput.height - 25))
			gui.consoleOutput:setParam("position", {0, -diff * gui.consoleWindowScrollBar.value + 25})
			gui.consoleWindowScrollBar.scrubberLength = (gui.consoleWindowScrollBar.height - 40) * math.min(1, gui.consoleWindowScrollBar.height / gui.consoleOutput.height)
			local lines = select(2, gui.consoleOutput.text:gsub('\n', '\n')) + 1
			gui.consoleWindowScrollBar:setParam("scrollDelta", 1.0/lines)
		end)

		gui.consoleOutput.addLine = function(self, line)
			gui.consoleOutput:setParam("text", gui.consoleOutput.text .. "\n" .. line)
			gui.consoleWindowScrollBar:setParam("value", 1.0)
			gui.consoleWindowScrollBar:onChange()
		end

		gui.printConsole = function(line) gui.consoleOutput:addLine(tostring(line)) end

		gui.consoleInput.keyPressed = function(self, key, isrepeat)
			kraid.widgets.LineInput.keyPressed(self, key, isrepeat)

			if key == "return" then 
				local ret = cliExec(self.text)
				self:setParam("text", "")
				if ret ~= nil then 
					gui.consoleOutput:addLine(tostring(ret))
				end
			end
		end

		gui.consoleWindow:setParam("onResize", function(self) 
			gui.consoleInput:setParam("position", {0, self.height - gui.consoleInput.height})
			gui.consoleInput:setParam("width", self.width - gui.consoleWindowScrollBar.width) 
			gui.consoleWindowScrollBar:setParam("position", {self.width - gui.consoleWindowScrollBar.width, 25})
			gui.consoleWindowScrollBar:setParam("length", self.height - 25)
			gui.consoleWindowScrollBar:onChange()
		end)

		-- Summon buttons
		local summonButtonW, summonButtonH = 180, 15
		gui.summonSceneWindow = kraid.widgets.Button{	parent = gui.base, text = "Summon scene window", 
													width = summonButtonW, height = summonButtonH, 
													onClicked = function() gui.sceneWindow:summon() end}
		gui.summonPropertyWindow = kraid.widgets.Button{	parent = gui.base, text = "Summon property window", 
														width = summonButtonW, height = summonButtonH, 
														onClicked = function() gui.propertyWindow:summon() end}
		gui.summonConsoleWindow = kraid.widgets.Button{	parent = gui.base, text = "Summon console window", 
														width = summonButtonW, height = summonButtonH, 
														onClicked = function() gui.consoleWindow:summon() end}

		return gui
	end

	local function findElementWidgets(parent, id)
		local widgets = {}
		for _, category in ipairs(parent.children) do
			if category.type == "Category" then 
				for _, widget in ipairs(category.children) do 
					if widget.elementId == id then 
						table.insert(widgets, widget)
					end
				end 
			end 
		end 
		return widgets
	end

	local function updateElement(parentWidget, element)
		local widgets = findElementWidgets(parentWidget, element.id)
		for _, widget in ipairs(widgets) do 
			local varString = (widget.target or "") .. '.' .. element.variable
			if element.type == "Checkbox" then
				if widget.type == "Checkbox" then 
					widget.checked = eval("return " .. varString)
					widget.cliCmd = varString .. " = " .. tostring(not widget.checked)
				end
			elseif element.type == "String" then 
				if widget.type == "LineInput" then 
					local newText = eval("return " .. varString)
					-- only set text if it has changed to avoid resetting the cursor
					if newText ~= widget.text then widget:setParam("text", newText) end 
					widget.cliCmd = varString .. ' = "' .. widget.text .. '"'
				end
			elseif element.type == "Numberwheel" then 
				if widget.type == "Numberwheel" then 
					widget.value = eval("return " .. varString)
					widget.numberInputLine.text = string.format(widget.format, widget.value)
					widget.cliCmd = varString .. " = " .. tostring(widget.value)
				end
			elseif element.type == "File" then 
				if widget.type == "Label" then 
					widget.text = element.label .. ": " .. eval("return " .. varString)
				end 
			end
		end
	end

	local function createElementWidgets(parent, element, target)
		parent.layout:newLine()
		if element.type == "Checkbox" then 
			local checkbox = kraid.widgets.Checkbox{parent = parent, target = target, elementId = element.id, onChecked = widgetExecCliCmd}
			parent.layout:addWidget(checkbox)
			local label = kraid.widgets.Label{parent = parent, text = element.label, elementId = element.id}
			parent.layout:addWidget(label)
		elseif element.type == "String" then
			local label = kraid.widgets.Label{parent = parent, text = element.label, elementId = element.id}
			parent.layout:addWidget(label)
			local input = kraid.widgets.LineInput{parent = parent, elementId = element.id, target = target, cliCmd = "", minWidth = 20}
			parent.layout:addWidget(input)

			input:setParam("onChange", function(self) eval(self.target .. "." .. element.variable .. ' = "' .. self.text .. '"') end)
			input:setParam("keyPressed", function(self, key, isrepeat)
				kraid.widgets.LineInput.keyPressed(self, key, isrepeat)
				if key == "return" then cliExec(self.cliCmd) end
			end)
		elseif element.type == "Numberwheel" then 
			local label = kraid.widgets.Label{parent = parent, text = element.label, elementId = element.id}
			parent.layout:addWidget(label)
			local params = element.params or {speed = 10.0}
			local numberWheel = kraid.widgets.Numberwheel{parent = parent, elementId = element.id, target = target, cliCmd = "", 
														speed = params.speed, minValue = params.minValue, maxValue = params.maxValue}

			numberWheel:setParam("onChange", function(self, value) eval(self.target .. "." .. element.variable .. " = " .. tostring(value)) end)
			numberWheel:setParam("mouseReleased", function(self, x, y, button) 
				if self.blownUp and button == "l" then cliExec(self.cliCmd) end
				kraid.widgets.Numberwheel.mouseReleased(self, x, y, button)
			end)

			numberWheel.numberInputLine:setParam("keyPressed", function(self, key, isrepeat)
				kraid.widgets.LineInput.keyPressed(self, key, isrepeat)
				if key == "return" then cliExec(numberWheel.cliCmd) end
			end)
			parent.layout:addWidget(numberWheel)
		elseif element.type == "Button" then 
			local button = kraid.widgets.Button{parent = parent, text = element.label, elementId = element.id, minWidth = 30, height = 25, onClicked = widgetExecCliCmd}
			button.cliCmd = element.cmd 
			if element.cmd:sub(1,1) == "." or element.cmd:sub(1,1) == ":" then 
				button.cliCmd = target .. element.cmd
			else 
				button.cliCmd = element.cmd
			end 
			parent.layout:addWidget(button)
		elseif element.type == "File" then 
			local label = kraid.widgets.Label{parent = parent, target = target, elementId = element.id, minWidth = 40}
			parent.layout:addWidget(label)

			local cmd = target .. '.' .. element.variable .. ' = <path>'
			local button = kraid.widgets.Button{parent = parent, text = "..", elementId = element.id, width = 20, height = 20, cliCmd = cmd, 
				onClicked = function(self)
					filebrowserMode.enter(function(path)
						cliExec(self.cliCmd:gsub("<path>", '"' .. path .. '"'))
						exitSpecialMode() 
					end)
				end}
			parent.layout:addWidget(button)
		else
		    error("Unsupported gui element type '" .. element.type .. "'")
		end
		parent.layout:arrange()
		parent:setParam("inflatedHeight", select(4, parent:getChildrenBBox()) + 10)
	end

	function rebuildPropertyGUIElements(entity)
		print("REBUILD")
		local uncollapsedCategory = nil
		for _, category in ipairs(gui.propertyWindowScroll.children) do
			if category.type == "Category" then 
				if not category.collapsed then uncollapsedCategory = category.text; break end
			end 
		end 

		gui.propertyWindowScroll.children = {}
		gui.propertyWindowLayout.lines = {}

		for _, component in ipairs(entity.components) do 
			if not component.__hidden then 
				for _, element in ipairs(component.__guiElements) do 
					element.id = component.id .. "/" .. (element.variable or "") .. "/" .. (element.cmd or "")

					local cat = nil 
					for i, widget in ipairs(gui.propertyWindowScroll.children) do 
						if widget.type == "Category" and widget.text == (element.__category or component.componentType) then 
							cat = widget
							break
						end 
					end 

					if cat == nil then 
						gui.propertyWindowLayout:newLine()
						cat = kraid.widgets.Category{parent = gui.propertyWindowScroll, text = component.componentType, minWidth = 50, 
														collapsed = true, onCollapse = collapseRearrangePropertyWindow}
						if uncollapsedCategory == cat.text then cat:setParam("collapsed", false) end
						gui.propertyWindowLayout:addWidget(cat)

						cat.layout = kraid.layouts.LineLayout(cat, {["spacing"] = 5, ["padding"] = 10, ["padding-top"] = 40})
						cat:setParam("onResize", function(self) self.layout:arrange() end)
					end 

					createElementWidgets(cat, element, 'getComponentById(getEntityByGUID(gui.selectedEntities[1]), "' .. component.id ..  '")')
				end
				gui.propertyWindowLayout:arrange()
			end 
		end 
	end

	function updateGUI()
		-- update entity types list
		local entityTypesList = {}
		for k, v in pairs(entityTypes) do 
			table.insert(entityTypesList, {text = v.label, entityType = k})
		end 

		if #entityTypesList ~= #gui.entityTypesList.tree.children then 
			gui.entityTypesList:setParam("tree", {children = entityTypesList})
			if #entityTypesList > 0 then gui.entityTypesList.selected = {entityTypesList[1]} end 
		end

		gui.selectedEntityType = #gui.entityTypesList.selected > 0 and gui.entityTypesList.selected[1].entityType or nil

		-- update entity list
		local entityList = {}
		for i = #map.entities, 1, -1 do
			local coreComp = getComponentByType(map.entities[i], "Core")
			assert(coreComp, "Every entity has to have a 'Core' component!")
			assert(coreComp.name, "Every 'Core' component should have a name attribute")
			local name = coreComp.name .. " (guid: " .. tostring(map.entities[i].guid) .. ") " .. (coreComp.hidden and "(hidden)" or "")
			table.insert(entityList, {text = name, entity = map.entities[i]})
		end

		local selectedGUIDs = table.map(gui.entityList.selected, function(selected) return selected.entity.guid end)
		gui.entityList:setParam("tree", {children = entityList})
		gui.selectEntities(selectedGUIDs)

		-- Property and scene window + gui elements from component descriptions
		-- global property gui elements
		-- rebuild on init and on loadEntityFile

		-- update selected entity properties
		if #gui.entityList.selected == 0 then 
			gui.propertyWindowLabel:setParam("visible", true)
			gui.propertyWindowLabel:setParam("text", "No entity selected.")
			gui.propertyWindowScroll:setParam("visible", false)
		elseif #gui.entityList.selected > 1 then 
			gui.propertyWindowLabel:setParam("visible", true)
			gui.propertyWindowLabel:setParam("text", "More than one entity selected.\nCLI should still work.")
			gui.propertyWindowScroll:setParam("visible", false)
		else 
			gui.propertyWindowLabel:setParam("visible", false)
			gui.propertyWindowScroll:setParam("visible", true)

			local entity = gui.entityList.selected[1].entity

			for _, component in ipairs(entity.components) do 
				if not component.__hidden then 
					for _, element in ipairs(component.__guiElements) do 
						updateElement(gui.propertyWindowScroll, element)
					end
				end
			end
		end -- selected entity properties
	end -- setupGUI
end -- do 