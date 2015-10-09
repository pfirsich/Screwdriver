do
    local Sprite = class()
    components["Sprite"] = Sprite

    function Sprite:init(properties)
        self.imagePath = "" -- find test image!
        self.color = {255, 255, 255, 255}
        addTable(self, properties)

        self.__guiElements = {
            {variable = "color", type = "Color", label = "Color"},
            {variable = "imagePath", type = "File", label = "Image"},
        }

        self.__hidden = false
        self.__showInDetails = false
    end

    function Sprite:updateUserdataValues()
        self:loadImageFile()
    end 

    function Sprite:loadImageFile()
        if self.imagePath ~= "" then 
            local attr, err = lfs.attributes(self.imagePath)
            if attr == nil then 
                error("Attributes of image file could not be checked - '" .. self.imagePath .. "': " .. err)
            end
            if attr.mode ~= "file" then 
                error("'" .. self.imagePath .. "' is not a file.")
            end
            
            self.__image = getImage(self.imagePath)
        end
    end 

    function Sprite:getShapes()
        if self.__image then 
            local w, h = self.__image:getWidth(), self.__image:getHeight()
            return {{0, 0,   0, h,   w, h,   w, 0}}
        end
        return {}
    end

    function Sprite:renderStart()
        if self.__image then 
            love.graphics.setColor(unpack(self.color))
            love.graphics.draw(self.__image)
        end
    end

    function Sprite:renderEnd()
        love.graphics.setColor(255, 255, 255, 255)
    end 

    Sprite.static.__unique = true
    Sprite.static.__pickable = true

    Sprite.static.__guiElements = {}

end 