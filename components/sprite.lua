do
    local Sprite = class()

    function Sprite:init(properties)
        self.imagePath = "" -- find test image!
        self.color = {255, 255, 255, 255}
        addTable(self, properties)
        self:loadImage()

        self.__guiElements = {
            {id = "imagePath", type = "String", name = "Image path"},
            {id = "loadImage", type = "Button", name = "Load Image"}
        }

        self.__unique = true
        self.__pickable = false
        self.__hidden = false
        self.__showInDetails = false
    end

    function Sprite:loadImage()
        if love.filesystem.isFile(self.imagePath) then 
            gui.printConsole("Image loaded.")
            self.__image = love.graphics.newImage(self.imagePath)
            self.lastImagePath = self.imagePath
        end 
    end

    function Sprite:renderStart()
        if self.__image then 
            love.graphics.setColor(unpack(self.color))
            love.graphics.draw(self.__image)

            love.graphics.setLineWidth(3)
            love.graphics.setColor(0, 255, 0, 255)
            if Sprite.static.showImageBorders then 
                love.graphics.rectangle("line", 0, 0, self.__image:getWidth(), self.__image:getHeight())
            end 
            love.graphics.setLineWidth(1)
        end
    end

    function Sprite:renderEnd()
        love.graphics.setColor(255, 255, 255, 255)
    end 

    Sprite.static.showImageBorders = true

    Sprite.static.guiElements = {
        {id = "showImageBorders", type = "Checkbox", name = "Show image borders"}
    }

    components["Sprite"] = Sprite
end 