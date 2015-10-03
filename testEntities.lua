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

entityTypes["everything"] = {
	label = "All components",
	components = {
		{
			id = "core",
			componentType = "Core",
		},
		{	
			id = "transforms",
			componentType = "Transforms",
		},
		{
			id = "sprite",
			componentType = "Sprite",
			imagePath = "pfirsich.png"
		}
	}
}