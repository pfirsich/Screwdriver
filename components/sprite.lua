do
    local Sprite = class()
    components["Sprite"] = Sprite

    function Sprite:init(properties)
        self.imagePath = "" -- find test image!
        self.color = {255, 255, 255, 255}
        addTable(self, properties)
        if self.imagePath ~= "" then self:loadImage(self.imagePath) end

        self.__guiElements = {
            {id = "imagePath", type = "String", name = "Image path"},
            {id = "%COMPONENT%:loadImage()", type = "Button", name = "Load Image"}
            --{id = "loadImage", type = "File", name = "Image path"},
        }

        self.__hidden = false
        self.__showInDetails = false
    end

    function Sprite:loadImage(path)
        local attr, err = lfs.attributes(self.imagePath)
        if attr == nil then 
            error("Attributes of image file could not be checked - '" .. self.imagePath .. "': " .. err)
        end
        if attr.mode ~= "file" then 
            error("'" .. self.imagePath .. "' is not a file.")
        end
        
        self.__image = getImage(self.imagePath)
        gui.printConsole("Image loaded.")
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

    Sprite.static.unique = true
    Sprite.static.pickable = true

    Sprite.static.guiElements = {}

end 