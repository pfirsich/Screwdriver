do
    local Transforms = class()

    function Transforms:init(properties)
        self.position = {0, 0}
        self.rotation = 0
        self.offset = {0, 0}
        self.scale = {1, 1}
        self.anchorXYScale = true
        addTable(self, properties)

        self.__guiElements = {}
        if self.position ~= nil then
            table.iextend(self.__guiElements,{
                {name = "X-Pos", type = "Numberwheel", id = "position[1]"},
                {name = "Y-Pos", type = "Numberwheel", id = "position[2]"}
            })
        end
            
        if self.rotation ~= nil then
            table.insert(self.__guiElements, {name = "Angle", type = "Numberwheel", id = "rotation", params = {speed = 1.0}})
        end
        
        if self.offset ~= nil then 
            table.iextend(self.__guiElements,{
                {name = "X-Offset", type = "Numberwheel", id = "offset[1]"},
                {name = "Y-Offset", type = "Numberwheel", id = "offset[2]"}
            })
        end
        
        if self.scale ~= nil then 
            table.iextend(self.__guiElements,{
                {name = "X-Scale", type = "Numberwheel", id = "scale[1]", params = {speed = 0.5}},
                {name = "Y-Scale", type = "Numberwheel", id = "scale[2]", params = {speed = 0.5}},
                {name = "Anchor X- and Y-Scale", type = "Checkbox", id = "anchorXYScale"}
            })
        end

        self.__unique = true
        self.__pickable = false
        self.__hidden = false
        self.__showInDetails = false
    end

    function Transforms:renderStart()
        if self.anchorXYScale then  -- this might not be at the right place
            if self.scale[1] ~= self.__lastScale then 
                self.scale[2] = self.scale[1]
                self.__lastScale = self.scale[1]
            end 

            if self.scale[2] ~= self.__lastScale then 
                self.scale[1] = self.scale[2]
                self.__lastScale = self.scale[1]
            end
        end 

        love.graphics.push()
        if self.position ~= nil then love.graphics.translate(unpack(self.position)) end
        if self.rotation ~= nil then love.graphics.rotate(self.rotation) end
        if self.scale ~= nil then love.graphics.scale(unpack(self.scale)) end
        if self.offset ~= nil then love.graphics.translate(unpack(self.offset)) end
    end

    function Transforms:renderEnd()
        love.graphics.pop()
    end 

    Transforms.static.guiElements = {}

    components["Transforms"] = Transforms
end 