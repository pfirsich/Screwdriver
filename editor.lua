do
	editor = {}

	local entityCounter = 1

	function editor.createEntity(type)
		local entity = {
			type = type,
			shapes = {},
			guid = entityCounter,
			components = {},
		}
		entityCounter = entityCounter + 1

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
		gui.printConsole("<to be implemented>")
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