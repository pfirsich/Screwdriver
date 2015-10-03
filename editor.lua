do
	editor = {}
	editor.defaultEditMode = {description = "Default mode"}
	editor.editMode = editor.defaultEditMode
	editor.hoveredEntities = {}

	local entityCounter = 1

	function editor.createEntity(type)
		local entity = {
			type = type,
			__shapes = {}, -- underscore prefix so it won't be saved in the map file
			guid = entityCounter,
			components = {},
		}
		entityCounter = entityCounter + 1

		-- component uniqueness and only one pickable component is a requirement to make picking a lot less problematic (multiple draws/transforms would be a pain)
		local created = {}
		local ids = {}
		for _, component in ipairs(entityTypes[type].components) do 
			if ids[component.id] then 
				error("Multiple components with the same id: " .. component.id)
			end 
			ids[component.id] = true

			if components[component.componentType].static.unique and created[component.componentType] then 
				error("Component '" .. component.componentType .. "' can not be added to an entity more than once.")
			end 

			if components[component.componentType].static.pickable and entity.__pickableComponent ~= nil then 
				error("Only one pickable component can be added to an entity.")
			end 

			if component.componentType == "Core" then 
				component.name = type
			end

			local componentObject = components[component.componentType](component)
			created[component.componentType] = true
			if components[component.componentType].static.pickable then 
				entity.__pickableComponent = componentObject
			end

			table.insert(entity.components, componentObject) 
		end 

		table.insert(map.entities, entity)
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
				totalBBox[1] = math.min(totalBBox[1], entityBBox[1])
				totalBBox[2] = math.min(totalBBox[2], entityBBox[2])
				totalBBox[3] = math.max(totalBBox[3], entityBBox[3])
				totalBBox[4] = math.max(totalBBox[4], entityBBox[4])
			end 
			camera.position = {(totalBBox[1] + totalBBox[3])/2, (totalBBox[2] + totalBBox[4])/2}
			local winW, winH = love.window.getWidth(), love.window.getHeight()
			camera.setScale(math.min(winW / (totalBBox[3] - totalBBox[1]), winH / (totalBBox[4] - totalBBox[2])) * 0.5)
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

	-- both paths should be absolute
	local function makePathRelative(basePath, path)
		return path
	end

	-- it's not pretty that these functions call functtions from the gui module, but it's handy to have these as easily bindable functions
	function editor.saveMapFile(path)
		file, err = io.open(path, "w")
		if file == nil then 
			gui.dialogNotice("Error!", "Error while opening file: " .. tostring(err))
		else 
			local function writeTable(tbl, depth)
			    for key, value in pairs(tbl) do
			    	if type(key) ~= "string" or key:sub(1,2) ~= "__" then 
			    		file:write(string.rep("\t", depth))
			    		if type(key) ~= "number" then  
			    			file:write(key .. " = ")
			    		end

			    		local t = type(value)
			    		if t == "table" then
				            file:write("{\n")
				            writeTable(value, depth + 1)
				            file:write(string.rep("\t", depth) .. "},\n")
				        elseif t == "string" then 
				        	file:write('"' .. value .. '",\n')
				        elseif t == "boolean" or t == "number" then 
				        	file:write(tostring(value) .. ",\n")
				        end
			    	end 			        
			    end
			end 

			file:write("return {\n")
			writeTable(map, 1)
			file:write("}\n")
			file:close()
			
			editor.currentMapFile = path
			editor.unsavedChanges = false
		end
	end

	function editor.loadEntityFile(path)
		path = lfs.currentdir() .. "/" .. path
		f, err = loadfile(path)
		if f == nil then 
			gui.dialogNotice("Error!", "Error while opening/parsing entity file: " .. tostring(err))
		else 
			f()
			table.insert(map.entityFiles, path)
		end 
		table.insert(map.entityFiles, path)
	end 

	function editor.loadMapFile(path)
		f, err = loadfile(path)
		if f == nil then 
			gui.dialogNotice("Error!", "Error while opening/parsing file: " .. tostring(err))
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
				local entity = editor.createEntity(tableEntity.type)
				for _, fileComponent in ipairs(tableEntity.components) do 
					local comp = getComponentById(entity, fileComponent.id)
					if comp == nil then 
						error("Current entity type description seems to mismatch the one of the saved map for entity of type '" .. entity.type .. "'")
					else 
						for propertyKey, v in pairs(comp) do 
							if type(propertyKey) ~= "string" or propertyKey:sub(1,2) ~= "__" then 
								comp[propertyKey] = fileComponent[propertyKey]
							end  
						end
					end 
				end 
			end 

			mapStack.cursor = 1
			for i = 1, #mapStack do 
				mapStack[i] = nil
			end 
			mapStack[1] = {label = path, map = tableDeepCopy(map)}

			updateShapes()

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