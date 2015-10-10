entityTypes["Core only"] = {
	label = "Test entity type",
	components = {
		{
			id = "core",
			componentType = "Core",
		}
	}
}

entityTypes["Sprite + Transforms"] = {
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

entityTypes["polygon"] = {
	label = "Polygon",
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
			id = "polygon",
			componentType = "SimplePolygon",
		}
	}
}