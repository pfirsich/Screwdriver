do
    local Sprite = class()
    components["Sprite"] = Sprite

    function Sprite:init(properties)
        self.imagePath = "" -- find test image!
        self.color = {255, 255, 255, 255}
        addTable(self, properties)
        self:loadImage()

        self.__guiElements = {
            {id = "imagePath", type = "String", name = "Image path"},
            {id = "%COMPONENT%:loadImage()", type = "Button", name = "Load Image"}
        }

        self.__hidden = false
        self.__showInDetails = false
    end

    function Sprite:getShapes()
        if self.__image then 
            local w, h = self.__image:getWidth(), self.__image:getHeight()
            return {{0, 0,   0, h,   w, h,   w, 0}}
        end
    end

    function Sprite:loadImage()
        if love.filesystem.isFile(self.imagePath) then 
            gui.printConsole("Image loaded.")
            self.__image = love.graphics.newImage(self.imagePath)
        end 
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