do
	local Core = class()

	function Core:init(properties)
		self.hidden = false
		self.name = "You will never see this (hopefully)"
		addTable(self, properties)

		self.__guiElements = {
			{name = "Name", type = "string", params = {"name"}},
			{name = "Hidden", type = "Checkbox", params = {"hidden"}},
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
		showGrid = {name = "Show grid", type = "Checkbox", params = {}},
		showNames = {name = "Show names", type = "Checkbox", params = {}},
		showDetails = {name = "Show details", type = "Checkbox", params = {}},
	}

	components["Core"] = Core
end