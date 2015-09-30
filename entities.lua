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

entityTypes["dummy"] = {
	label = "Test entity type",
	components = {
		{
			id = "core",
			componentType = "Core",
		}
	}
}