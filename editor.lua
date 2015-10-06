do
	editor = {}
	editor.defaultEditMode = {description = "Default mode"}
	editor.editMode = editor.defaultEditMode
	editor.hoveredEntities = {}

	local entityCounter = 0

	function editor.changeEditMode(mode, ...)
		if editor.editMode.onExit then editor.editMode.onExit(mode) end 
		if mode.onEnter then mode.onEnter(...) end
		editor.editMode = mode
		updateShapes() -- update shapes to make sure mode dependent shapes are now correct
	end

	function editor.createEntity(type, componentProperties)
		if type == nil then 
			gui.printConsole("No entity type selected.")
			return
		end

		entityCounter = entityCounter + 1
		local entity = {
			type = type,
			__shapes = {}, -- underscore prefix so it won't be saved in the map file
			guid = entityCounter,
			components = {},
		}

		-- component uniqueness and only one pickable component is a requirement to make picking a lot less problematic (multiple draws/transforms would be a pain)
		local created = {}
		local ids = {}
		for i, component in ipairs(entityTypes[type].components) do 
			if ids[component.id] then 
				error("Multiple components with the same id: " .. component.id)
			end 
			ids[component.id] = true

			if components[component.componentType].static.__unique and created[component.componentType] then 
				error("Component '" .. component.componentType .. "' can not be added to an entity more than once.")
			end 

			if components[component.componentType].static.__pickable and entity.__pickableComponent ~= nil then 
				error("Only one pickable component can be added to an entity.")
			end 

			local pass = tableDeepCopy(component)
			if component.componentType == "Core" and component.name == nil then pass.name = type end
			-- HAX HAX HAX HAX HAX
			if componentProperties then pass.fromMapFile = true end -- e.g. so edit modes that are initiated on entity creation are not entered
			pass.entityGUID = entity.guid

			if componentProperties then 
				-- addTable only works properly if number and order of components still matches the entity type
				-- This check should be enough to make sure most of the time, but is by no means sufficient for all cases
				if component.id ~= componentProperties[i].id then 
					error("Current entity type description seems to mismatch the one of the saved map for entity of type '" .. entity.type .. "'")
				end
				addTable(pass, componentProperties[i]) 
			end 

			local componentObject = components[component.componentType](pass)
			created[component.componentType] = true
			if components[component.componentType].static.__pickable then 
				-- I have to save the id because saving a reference would cause the object to be duplicated when deep-copied (therefore destroying the reference)
				entity.__pickableComponent = componentObject.id 
			end

			table.insert(entity.components, componentObject) 
		end 
		assert(getComponentByType(entity, "Core"), "Every component has to have a Core component!")
		table.insert(map.entities, entity)
		gui.selectEntities({entity.guid})
		return entity
	end

	function editor.entityUp(selected)
		for i = #map.entities, 1, -1 do
			for _, guid in ipairs(selected) do 
				if map.entities[i].guid == guid then 
					if i < #map.entities then 
						map.entities[i], map.entities[i+1] = map.entities[i+1], map.entities[i]
						break
					end
				end 
			end 
		end
	end 

	function editor.entityDown(selected)
		for i = 1, #map.entities do
			for _, guid in ipairs(selected) do 
				if map.entities[i].guid == guid then 
					if i > 1 then 
						map.entities[i], map.entities[i-1] = map.entities[i-1], map.entities[i]
						break
					end
				end 
			end 
		end
	end

	function editor.focusCamera(selected) 
		if #selected > 0 then 
			local totalBBox = {math.huge, math.huge, -math.huge, -math.huge}
			for _, guid in ipairs(selected) do 
				local entityBBox = getEntityByGUID(guid).__shapes.bbox
				if entityBBox then 
					totalBBox[1] = math.min(totalBBox[1], entityBBox[1])
					totalBBox[2] = math.min(totalBBox[2], entityBBox[2])
					totalBBox[3] = math.max(totalBBox[3], entityBBox[3])
					totalBBox[4] = math.max(totalBBox[4], entityBBox[4])
				end
			end 
			if totalBBox[1] ~= math.huge and totalBBox[2] ~= math.huge and totalBBox[3] ~= -math.huge and totalBBox[4] ~= -math.huge then
				camera.position = {(totalBBox[1] + totalBBox[3])/2, (totalBBox[2] + totalBBox[4])/2}
				local winW, winH = love.window.getWidth(), love.window.getHeight()
				camera.setScale(math.min(winW / (totalBBox[3] - totalBBox[1]), winH / (totalBBox[4] - totalBBox[2])) * 0.5)
			end
		end
	end

	function editor.removeEntities(selected) 
		if #selected == 0 then 
			gui.printConsole("none selected")
		else 
			for _, guid in ipairs(selected) do 
				for index, entity in ipairs(map.entities) do 
					if entity.guid == guid then 
						table.remove(map.entities, index)
					end 
				end 
			end 
		end 
	end

	-- it's not pretty that these functions call functtions from the gui module, but it's handy to have these as easily bindable functions
	function editor.saveMapFile(path)
		file, err = io.open(path, "w")
		if file == nil then 
			error("Error while opening file: " .. tostring(err))
		else 
			local function writeTable(tbl, depth)
			    for key, value in pairs(tbl) do
			    	local kType = type(key)
			    	local vType = type(value)
			    	if (kType == "number" or (kType == "string" and key:sub(1,2) ~= "__")) and 
			    	   (vType == "table" or vType == "string" or vType == "boolean" or vType == "number") then 
				    	if kType == "string" then 
				    		file:write(string.rep("\t", depth) .. '["' .. key .. '"] = ')
				    	elseif kType == "number" then 
				    		file:write(string.rep("\t", depth))
				    	end 

				    	if vType == "table" then
				            file:write("{\n")
				            writeTable(value, depth + 1)
				            file:write(string.rep("\t", depth) .. "},\n")
				        elseif vType == "string" then 
				        	file:write('"' .. value .. '",\n')
				        elseif vType == "boolean" or vType == "number" then 
				        	file:write(tostring(value) .. ",\n")
				        end	
				    end		        
			    end
			end 

			file:write("return {\n")
			writeTable(map, 1)
			writeTable({componentStatics = table.map(components, function(c) return c.static end)}, 1)
			file:write("}\n")
			file:close()
			
			editor.currentMapFile = path
			editor.unsavedChanges = false
		end
	end

	function editor.loadEntityFile(path)
		print("entityfile: ", path)

		f, err = loadfile(path)
		if f == nil then 
			error("Error while opening/parsing entity file: " .. tostring(err))
		else 
			f()
			table.insert(map.entityFiles, path)
			rebuildGlobalComponentGUIElements()
			updateEntityTypesList()
		end 
	end 

	function editor.loadMapFile(path)
		f, err = loadfile(path)
		if f == nil then 
			error("Error while opening/parsing file: " .. tostring(err))
		else 
			local fileTable = f()
			map = {}

			map.entityFiles = {}
			entityTypes = {}
			for _, path in ipairs(fileTable.entityFiles) do 
				editor.loadEntityFile(path)
			end 

			map.entities = {}
			entityCounter = 0
			for _, tableEntity in ipairs(fileTable.entities) do 
				editor.createEntity(tableEntity.type, tableEntity.components)
			end 
			updateUserdataValues()
			updateShapes()

			for componentType, statics in pairs(fileTable.componentStatics) do 
				for variable, value in pairs(statics) do 
					components[componentType].static[variable] = value
				end 
			end 

			mapStack.cursor = 1
			for i = 1, #mapStack do 
				mapStack[i] = nil
			end 
			mapStack[1] = {label = path, map = tableDeepCopy(map)}

			-- focus whole map
			editor.focusCamera(table.map(map.entities, function(entity) return entity.guid end))

			editor.currentMapFile = path
			editor.unsavedChanges = false
		end
	end 

	function editor.saveMap() 
		if editor.currentMapFile then 
			editor.saveMapFile(editor.currentMapFile)
		else
			editor.saveMapAs() 
		end 
	end 

	function editor.saveMapAs()
		gui.dialogQuestionString("Save map", lfs.currentdir() .. "\\", 'editor.saveMapFile(lfs.currentdir() .. "/%INPUT%")')
	end

	function editor.loadMap()
		gui.dialogQuestionString("Load map", lfs.currentdir() .. "\\", 'editor.loadMapFile(lfs.currentdir() .. "/%INPUT%")')
	end
end