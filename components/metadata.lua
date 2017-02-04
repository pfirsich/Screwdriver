do
    local MetadataBoolean = class()
    components["MetadataBoolean"] = MetadataBoolean

    function MetadataBoolean:init(properties)
        self.label = "Metadata Name"
        self.value = false
        addTable(self, properties)

        self.__guiElements = {
            {variable = "value", type = "Checkbox", label = self.label},
        }
    end

    MetadataBoolean.static.__unique = false
    MetadataBoolean.static.__pickable = false
    MetadataBoolean.static.__guiElements = {}

    -----------------------

    local MetadataString = class()
    components["MetadataString"] = MetadataString

    function MetadataString:init(properties)
        self.label = "Metadata Name"
        self.value = "<empty>"
        addTable(self, properties)

        self.__guiElements = {
            {variable = "value", type = "String", label = self.label, callback = ""},
        }
    end

    MetadataString.static.__unique = false
    MetadataString.static.__pickable = false
    MetadataString.static.__guiElements = {}

    -----------------------

    local MetadataNumber = class()
    components["MetadataNumber"] = MetadataNumber

    function MetadataNumber:init(properties)
        self.label = "Metadata Name"
        self.value = 0.0
        addTable(self, properties)

        self.__guiElements = {
            {variable = "value", type = "Numberwheel", label = self.label},
        }
    end

    MetadataNumber.static.__unique = false
    MetadataNumber.static.__pickable = false
    MetadataNumber.static.__guiElements = {}
end