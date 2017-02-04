entityTypes["Core only"] = {
	label = "Core only",
	components = {
		{
			id = "core",
			componentType = "Core",
		}
	}
}

entityTypes["Sprite + Transforms"] = {
	label = "Sprite + Transforms",
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

entityTypes["metadataPoly"] = {
	label = "Polygon with Metadata",
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
		},
		{
			id = "isEnemy",
			label = "Enemy",
			componentType = "MetadataBoolean",
		},
		{
			id = "destructible",
			label = "Destructible",
			componentType = "MetadataBoolean",
		},
	}
}

entityTypes["fancy polygon"] = {
	label = "Fancy Polygon",
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
			componentType = "BorderedFannedPolygon",
		},
	}
}