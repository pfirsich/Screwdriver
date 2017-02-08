do
    local Sprite = class()
    components["Sprite"] = Sprite

    function Sprite:init(properties)
        self.imagePath = "" -- find test image!
        self.color = {255, 255, 255, 255}
        addTable(self, properties)

        self.__guiElements = {
            {variable = "imagePath", type = "File", label = "Image"},
            {variable = "", type = "Button", label = "Reload Image", cmd = 'getComponentByType(getEntityByGUID(gui.selectedEntities[1]), "Sprite"):reloadImage()'},
            {variable = "color", type = "Color", label = "Color"},
        }
    end

    function Sprite:reloadImage()
        if self.imagePath ~= "" then
            getImage(self.imagePath, true)
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
        if self.imagePath ~= "" then
            love.graphics.setColor(unpack(self.color))
            love.graphics.draw(getImage(self.imagePath))
        end
    end

    function Sprite:renderEnd()
        love.graphics.setColor(255, 255, 255, 255)
    end

    Sprite.static.__unique = true
    Sprite.static.__pickable = true

    Sprite.static.__guiElements = {}

end