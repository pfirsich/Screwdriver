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

	local function bindCheckboxToVariable(checkbox, tbl, key)
		checkbox:setParam("checked", tbl[key])
		checkbox:setParam("onChecked", function(self) 
			tbl[key] = self.checked
		end)
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
		-- %INPUT% will be replaced with the entered text in cmd
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

		gui.sceneWindowLayout:newLine({["spacing-vertical"] = 20})
		gui.entityCreateInstanceButton = kraid.widgets.Button{parent = gui.sceneWindowScroll, height = 30, minWidth = 50, text = "Create Instance",
											cliCmd = 'editor.createEntity(gui.selectedEntityType)',
											onClicked = widgetExecCliCmd}
		gui.sceneWindowLayout:addWidget(gui.entityCreateInstanceButton)

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
												cliCmd = 'gui.dialogQuestion("Remove?", "Are you sure you want to remove the selected entities?", "editor.removeEntities(gui.selectedEntities)", "")',
												onClicked = widgetExecCliCmd}
		gui.sceneWindowLayout:addWidget(gui.entityRemoveButton)

		-- Maybe move this to a component?
		gui.sceneWindowLayout:newLine()
		gui.sceneFileCategory = kraid.widgets.Category{parent = gui.sceneWindowScroll, text = "File", minWidth = 50, onCollapse = collapseRearrangeSceneWindow}
		gui.sceneWindowLayout:addWidget(gui.sceneFileCategory)

		gui.sceneFileCategoryLayout = kraid.layouts.LineLayout(gui.sceneFileCategory, {["spacing"] = 5, ["padding"] = 10, ["padding-top"] = 40})

		gui.sceneFileCategoryLayout:newLine()
		gui.setCustomEntitiesFile = kraid.widgets.Button{parent = gui.sceneFileCategory, height = 30, minWidth = 50, text = "Add & Load entity file"}
		gui.sceneFileCategoryLayout:addWidget(gui.setCustomEntitiesFile)

		gui.sceneFileCategoryLayout:newLine()
		gui.loadFileButton = kraid.widgets.Button{parent = gui.sceneFileCategory, height = 30, minWidth = 50, text = "Load map file"}
		gui.sceneFileCategoryLayout:addWidget(gui.loadFileButton)

		gui.sceneFileCategoryLayout:newLine()
		gui.saveButton = kraid.widgets.Button{parent = gui.sceneFileCategory, height = 30, minWidth = 50, text = "Save"}
		gui.sceneFileCategoryLayout:addWidget(gui.saveButton)
		gui.saveAsButton = kraid.widgets.Button{parent = gui.sceneFileCategory, height = 30, minWidth = 50, text = "Save As"}
		gui.sceneFileCategoryLayout:addWidget(gui.saveAsButton)

		gui.sceneFileCategoryLayout:arrange()
		local sceneFileCatBBox = {gui.sceneFileCategory:getChildrenBBox()}
		gui.sceneFileCategory:setParam("inflatedHeight", sceneFileCatBBox[4] + 10)

		gui.sceneFileCategory:setParam("onResize", function(cat) gui.sceneFileCategoryLayout:arrange() end)
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

		gui.propertyWindowScroll = kraid.widgets.Base{parent = gui.propertyWindow, position = {0, 0}, width = 250}
		gui.propertyWindowScrollBar = kraid.widgets.Scrollbar{parent = gui.propertyWindow, vertical = true}

		gui.propertyWindowScrollBar:setParam("onChange", function(self)
			local contentHeight = select(4, gui.propertyWindowScroll:getChildrenBBox())
			local overlap = math.max(0, contentHeight - gui.sceneWindow.height)
			gui.propertyWindowScroll:setParam("position", {0, -overlap * self.value})
			gui.propertyWindowScrollBar.scrubberLength = (gui.propertyWindowScrollBar.height - 40) * math.min(1, gui.propertyWindowScrollBar.height / (contentHeight - 20))
		end)

		gui.propertyWindowLayout = kraid.layouts.LineLayout(gui.propertyWindowScroll, {["spacing"] = 5, ["padding"] = 5, ["padding-top"] = 30, ["padding-right"] = 5 + gui.propertyWindowScrollBar.width})

		gui.propertyWindowLayout:newLine()
		gui.propertyWindowLabel = kraid.widgets.Label{parent = gui.propertyWindowScroll, text = "No entity selected."}
		gui.propertyWindowLayout:addWidget(gui.propertyWindowLabel)

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

		gui.consoleOutput = kraid.widgets.Label{parent = gui.consoleWindow, text = "This \n is a test \n boy", position = {0, 25}}

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

		local inputKeyPressedCB = gui.consoleInput.keyPressed
		gui.consoleInput.keyPressed = function(self, key, isrepeat)
			inputKeyPressedCB(self, key, isrepeat)

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

		-- update entity list
		local updateEntityList = false
		if #map.entities ~= #gui.entityList.tree.children then 
			updateEntityList = true 
		else 
			for i = 1, #map.entities do 
				local coreComp = getComponentByType(map.entities[#map.entities - i + 1], "Core")
				assert(coreComp, "Every entity has to have a 'Core' component!")
				assert(coreComp.name, "Every 'Core' component should have a name attribute")

				if coreComp.name ~= gui.entityList.tree.children[i].text then 
					updateEntityList = true 
					break 
				end 
			end 
		end 

		if updateEntityList then 
			local entityList = {}
			for i = #map.entities, 1, -1 do 
				local coreComp = getComponentByType(map.entities[i], "Core")
				assert(coreComp, "Every entity has to have a 'Core' component!")
				assert(coreComp.name, "Every 'Core' component should have a name attribute")
				table.insert(entityList, {text = coreComp.name, entity = map.entities[i]})
			end

			local newSelection = {}
			for _, selected in ipairs(gui.entityList.selected) do
				for _, element in ipairs(entityList) do 
					if element.entity == selected.entity then 
						newSelection[#newSelection+1] = element
					end 
				end  
			end 

			gui.entityList:setParam("tree", {children = entityList})
			gui.entityList:setParam("selected", newSelection)	
		end 

		-- update global component gui elements
		for name, component in pairs(components) do 
			local cat = nil 
			for i, widget in ipairs(gui.sceneWindowScroll.children) do 
				if widget.type == "Category" and widget.text == name then 
					cat = widget 
					break
				end 
			end 

			if cat == nil then 
				gui.sceneWindowLayout:newLine()
				cat = kraid.widgets.Category{parent = gui.sceneWindowScroll, text = name, minWidth = 50, collapsed = true, onCollapse = collapseRearrangeSceneWindow}
				gui.sceneWindowLayout:addWidget(cat)

				cat.layout = kraid.layouts.LineLayout(cat, {["spacing"] = 5, ["padding"] = 10, ["padding-top"] = 40})
				cat:setParam("onResize", function(self) self.layout:arrange() end)
			end 

			for key, element in pairs(component.static.guiElements) do 
				local widgets = {}
				for _, widget in ipairs(cat.children) do 
					if widget.elementId == key then 
						widgets[#widgets+1] = widget
					end
				end 

				if #widgets == 0 then -- create widgets
					cat.layout:newLine()
					if element.type == "Checkbox" then 
						local checkbox = kraid.widgets.Checkbox{parent = cat, elementId = key}
						bindCheckboxToVariable(checkbox, component.static, key)
						cat.layout:addWidget(checkbox)
						local label = kraid.widgets.Label{parent = cat, text = element.name, elementId = key}
						cat.layout:addWidget(label)
					elseif element.type == "String" then 

					end

					cat.layout:arrange()
					cat:setParam("inflatedHeight", select(4, cat:getChildrenBBox()) + 10)
				else -- update values 
					for _, widget in ipairs(widgets) do 
						if element.type == "Checkbox" and widget.type == "Checkbox" then 
							widget:setParam("checked", component.static[key])
						elseif element.type == "String" then 

						end
					end 
				end
			end 
		end 
	end
end