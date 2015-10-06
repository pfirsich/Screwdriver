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

		self.__hidden = false -- This is a way to hide components in the GUI (for custom userdata, which has to be part of the entity, but doesn't need to be edited in the editor)
		self.__showInDetails = false
	end

	Core.static.__unique = true
	Core.static.__pickable = false

	Core.static.showGrid = true
	Core.static.gridSpacing = 200
	Core.static.showNames = true 
	Core.static.showDetails = true
	Core.static.showEntityBorders = true
	Core.static.backgroundColor = {0, 0, 0, 255}

	Core.static.__guiElements = { -- background color
		--{id = "showDetails", name = "Show details", type = "Checkbox"},
		{variable = "showNames", type = "Checkbox", label = "Show names"},
		{variable = "showEntityBorders", type = "Checkbox", label = "Show entity borders"},
		{variable = "showGrid", type = "Checkbox", label = "Show grid"},
		{variable = "gridSpacing", type = "Numberwheel", label = "Grid spacing", params = {minValue = 1.0}},
		{variable = "backgroundColor", type = "Color", label = "Background color"},
	}



	local WithOptional = class()
	components["WithOptional"] = WithOptional

	function WithOptional:init(properties)
		self.mandatory = false
		self.hasOptional = false
		self.optional = true 
		addTable(self, properties)

		self.__guiElements = {
			{variable = "mandatory", type = "Checkbox", label = "Mandatory"}
		}

		if self.hasOptional then 
			table.iextend(self.__guiElements, {
				{variable = "optional", type = "Checkbox", label = "Optional"}
			})
		end 

		self.__hidden = false
		self.__showInDetails = false
	end 

	WithOptional.static.__unique = true 
	WithOptional.static.__pickable = false

	WithOptional.static.__guiElements = {}

end