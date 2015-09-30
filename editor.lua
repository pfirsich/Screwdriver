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

		for _, component in ipairs(entityTypes[type].components) do 
			if component.componentType == "Core" then 
				component.name = type .. " " .. tostring(entity.guid)
			end
			local componentObject = components[component.componentType](component)
			table.insert(entity.components, componentObject) 
		end 

		table.insert(map.entities, entity)
	end

	function editor.entityUp(selected)
		for i = #map.entities, 1, -1 do
			for _, element in ipairs(selected) do 
				if map.entities[i].guid == element.entity.guid then 
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
			for _, element in ipairs(selected) do 
				if map.entities[i].guid == element.entity.guid then 
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
			for _, element in ipairs(selected) do 
				for index, entity in ipairs(map.entities) do 
					if entity.guid == element.entity.guid then 
						table.remove(map.entities, index)
					end 
				end 
			end 
		end 
	end

	
end