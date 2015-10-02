do
	editor = {}
	editor.defaultEditMode = {description = "Default mode"}
	editor.editMode = editor.defaultEditMode
	editor.hoveredEntities = {}

	local entityCounter = 1

	function editor.createEntity(type)
		local entity = {
			type = type,
			shapes = {},
			guid = entityCounter,
			components = {},
		}
		entityCounter = entityCounter + 1

		-- component uniqueness and only one pickable component is a requirement to make picking a lot less problematic (multiple draws/transforms would be a pain)
		local created = {}
		for _, component in ipairs(entityTypes[type].components) do 
			if components[component.componentType].static.unique and created[component.componentType] then 
				error("Component '" .. component.componentType .. "' can not be added to an entity more than once.")
			end 

			if components[component.componentType].static.pickable and entity.pickableComponent ~= nil then 
				error("Only one pickable component can be added to an entity.")
			end 

			if component.componentType == "Core" then 
				component.name = type
			end

			local componentObject = components[component.componentType](component)
			created[component.componentType] = true
			if components[component.componentType].static.pickable then 
				entity.pickableComponent = componentObject
			end

			table.insert(entity.components, componentObject) 
		end 

		table.insert(map.entities, entity)
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
		local totalBBox = {math.huge, math.huge, -math.huge, -math.huge}
		for _, guid in ipairs(selected) do 
			local entityBBox = getEntityByGUID(guid).shapes.bbox
			totalBBox[1] = math.min(totalBBox[1], entityBBox[1])
			totalBBox[2] = math.min(totalBBox[2], entityBBox[2])
			totalBBox[3] = math.max(totalBBox[3], entityBBox[3])
			totalBBox[4] = math.max(totalBBox[4], entityBBox[4])
		end 
		camera.position = {(totalBBox[1] + totalBBox[3])/2, (totalBBox[2] + totalBBox[4])/2}
		local winW, winH = love.window.getWidth(), love.window.getHeight()
		camera.setScale(math.min(winW / (totalBBox[3] - totalBBox[1]), winH / (totalBBox[4] - totalBBox[2])) * 0.5)
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

	
end