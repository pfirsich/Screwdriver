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
	Core.static.gridSpacing = 200
	Core.static.showNames = true 
	Core.static.showDetails = true

	Core.static.guiElements = { -- background color, grid color/spacing
		{id = "showGrid", name = "Show grid", type = "Checkbox"},
		{id = "gridSpacing", name = "Grid spacing", type = "Numberwheel", params = {minValue = 1.0}},
		{id = "showNames", name = "Show names", type = "Checkbox"},
		{id = "showDetails", name = "Show details", type = "Checkbox"},
	}

	components["Core"] = Core


	local WithOptional = class()

	function WithOptional:init(properties)
		self.mandatory = false
		self.hasOptional = false
		self.optional = true 
		addTable(self, properties)

		self.__guiElements = {
			{id = "mandatory", name = "Mandatory", type = "Checkbox"},
		}

		if self.hasOptional then 
			table.iextend(self.__guiElements, {
				{id = "optional", name = "Optional", type = "Checkbox"}
			})
		end 

		self.__unique = true
		self.__pickable = false
		self.__hidden = false
		self.__showInDetails = false
	end 

	WithOptional.static.guiElements = {}

	components["WithOptional"] = WithOptional
end