do
	local Core = class()

	function Core:init(properties)
		self.hidden = false
		self.name = "You will never see this (hopefully)"
		addTable(self, properties)

		self.__guiElements = {
			{id = "name", name = "Name", type = "String"},
			{id = "hidden", name = "Hidden", type = "Checkbox"},
		}

		self.__unique = true
		self.__pickable = false
		self.__hidden = false
		self.__showInDetails = false
	end

	Core.static.showGrid = true
	Core.static.showNames = true 
	Core.static.showDetails = true

	Core.static.guiElements = {
		{id = "showGrid", name = "Show grid", type = "Checkbox"},
		{id = "showNames", name = "Show names", type = "Checkbox"},
		{id = "showDetails", name = "Show details", type = "Checkbox"},
	}

	components["Core"] = Core
end