entityTypes = {}

function getComponentByType(entity, type) 
	for _, component in ipairs(entity.components) do 
		if component.componentType == type then 
			return component 
		end
	end
	return nil
end

function getComponentById(entity, id)
	for _, component in ipairs(entity.components) do 
		if component.id == id then 
			return component 
		end
	end 
	return nil
end

function getEntityByGUID(guid) 
	for i = 1, #map.entities do 
		if map.entities[i].guid == guid then return map.entities[i] end 
	end
	return nil
end 

function foreachEntity(func)
	for i = 1, #map.entities do 
		if map.entities[i].guid == guid then func(map.entities[i]) end 
	end
end 

function foreachSelected(func)
	for i = #map.entities, 1, -1 do
		for _, guid in ipairs(gui.selectedEntities) do 
			if map.entities[i].guid == guid then 
				func(map.entities[i])
			end 
		end 
	end
end

entityTypes["dummy"] = {
	label = "Test entity type",
	components = {
		{
			id = "core",
			componentType = "Core",
		}
	}
}

entityTypes["withopt"] = {
	label = "Test dummy with optional",
	components = {
		{
			id = "core",
			componentType = "Core",
		},
		{	
			id = "optional",
			componentType = "WithOptional",
			hasOptional = true,
		}
	}
}

entityTypes["withoutopt"] = {
	label = "Test dummy without optional",
	components = {
		{
			id = "core",
			componentType = "Core",
		},
		{	
			id = "optional",
			componentType = "WithOptional",
			hasOptional = false,
		}
	}
}