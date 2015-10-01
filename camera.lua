 do
    camera = {position = {0, 0}, zoomLevel = 0, scale = 1.0, zoomBase = 1.07}

    function camera.push(scale)
        camera.scale = math.pow(camera.zoomBase, camera.zoomLevel)

        love.graphics.push()
        -- Center Screen
        love.graphics.translate(love.window.getWidth()/2, love.window.getHeight()/2)
        -- Here I swap scale and translate, so I can scale the translation myself and floor the values, to prevent sub-pixel-flickering around the edges
        local tx = -math.floor(camera.position[1] * camera.scale)
        local ty = -math.floor(camera.position[2] * camera.scale)
        love.graphics.translate(tx, ty)
        -- FIXME: flickering on edges caused by pixel positions not being whole numbers after scaling (see math.floor in translate). ?
        love.graphics.scale(camera.scale, camera.scale)
    end

    function camera.setScale(scale)
        camera.zoomLevel = math.log(scale) / math.log(camera.zoomBase)
    end 

    function camera.screenToWorld(x, y)
        -- Relative to Center
        x = x - love.window.getWidth()/2
        y = y - love.window.getHeight()/2
        -- Scaling
        x = x/camera.scale
        y = y/camera.scale
        -- translation
        x = camera.position[1] + x
        y = camera.position[2] + y
        return x, y
    end

    function camera.worldToScreen(x, y)
        return  x * camera.scale - math.floor(camera.position[1] * camera.scale) + love.window.getWidth()/2,
                y * camera.scale - math.floor(camera.position[2] * camera.scale) + love.window.getHeight()/2 
    end 

    camera.pop = love.graphics.pop
end
