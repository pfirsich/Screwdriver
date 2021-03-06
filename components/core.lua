do
	local Core = class()
	components["Core"] = Core

	function Core:init(properties)
		self.hidden = false
		self.locked = false
		self.name = "You will never see this (hopefully)"
		addTable(self, properties)

		self.__guiElements = {
			{variable = "name", type = "String", label = "Name", callback = ""},
			{variable = "hidden", type = "Checkbox", label = "Hidden", callback = ""},
			{variable = "locked", type = "Checkbox", label = "Locked", callback = ""},
		}
	end

	Core.static.__unique = true
	Core.static.__pickable = false

	Core.static.showGrid = true
	Core.static.gridSpacing = 200
	Core.static.showNames = true
	Core.static.showDetails = true
	Core.static.showEntityBorders = true
	Core.static.backgroundColor = {0, 0, 0, 255}
	Core.static.showMouseWorldPosition = false

	Core.static.__guiElements = { -- background color
		--{id = "showDetails", name = "Show details", type = "Checkbox"},
		{variable = "showNames", type = "Checkbox", label = "Show names"},
		{variable = "showEntityBorders", type = "Checkbox", label = "Show entity borders"},
		{variable = "showGrid", type = "Checkbox", label = "Show grid"},
		{variable = "gridSpacing", type = "Numberwheel", label = "Grid spacing", params = {minValue = 1.0}},
		{variable = "backgroundColor", type = "Color", label = "Background color"},
	}
end