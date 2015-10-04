do -- Hax
	ColorpickerWidget = kraid.internal.class(kraid.widgets.Base)

	local theme = {name = "Custom for picker"}
	theme.Colorpicker = {}

	function ColorpickerWidget:init(params)
		self.type = "Colorpicker"
		self.position = {0, 0}
		self.width = 300
		self.height = 200
		self.color = {255, 0, 0, 255}
		params.theme = theme

		self.numberWheels = {}
		for i = 1, 4 do 
			local onChange = function(nw, value)
				self.color[i] = value
				if self.onChange then self:onChange(self.color) end
			end
			self.numberWheels[i] = kraid.widgets.Numberwheel{parent = nil, minValue = 0, maxValue = 255, speed = 5.0, onChange = onChange,
															width = 150, height = 25, value = self.color[i], format = "%d"}
		end 

		kraid.widgets.Base.init(self, params)
	    kraid.internal.callThemeFunction(self, "init")

	    for i = 1, 4 do 
			self.numberWheels[i]:setParam("parent", self)
		end 
	end

	function ColorpickerWidget:setColor(color)
		for i = 1, 4 do 
			self.numberWheels[i]:setParam("value", color[i])
			self.color[i] = color[i]
		end
	end

	local xGradientShader = love.graphics.newShader([[
		uniform vec4 from = vec4(0.0, 0.0, 0.0, 1.0);
		uniform vec4 to = vec4(1.0, 1.0, 1.0, 1.0);

		vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
			return mix(from, to, vec4(textureCoords.x));
		}
	]])

	theme.Colorpicker.margin = 5
	theme.Colorpicker.spacing = 50

	function theme.Colorpicker.init(self)
		for i = 1, 4 do 
			self.numberWheels[i].position = {theme.Colorpicker.margin, theme.Colorpicker.margin + theme.Colorpicker.spacing * (i-1)}
		end
	end

	function drawCheckerRect(x, y, w, h)
		local checkerSize = 10
		local countX, countY = w / checkerSize, h / checkerSize
		checkersShader:send("countX", countX)
	    checkersShader:send("countY", countY)
	    love.graphics.draw(pixelImage, x, y, 0, w, h)
	end

	function theme.Colorpicker.draw(self)
        for i = 1, #self.children do
            self.children[i]:draw()
        end

		love.graphics.push()
		love.graphics.translate(unpack(kraid.internal.origin()))
	        local x = self.numberWheels[1].width + theme.Colorpicker.margin * 2
	        local y = theme.Colorpicker.margin / 2
	        local w = self.width - x - theme.Colorpicker.margin
	        local h = self.height - theme.Colorpicker.margin

	        love.graphics.setShader(checkersShader)
	        drawCheckerRect(x, y, w, h)
			
	      	local spacing = theme.Colorpicker.spacing - self.numberWheels[1].height
	        for i = 1, 4 do 
	        	local y = theme.Colorpicker.margin + i * self.numberWheels[1].height + spacing * (i-1) + 2
	        	drawCheckerRect(theme.Colorpicker.margin, y, self.numberWheels[1].width, 10)
	        end

	        love.graphics.setShader()
			love.graphics.setColor(self.color)
	        love.graphics.draw(pixelImage, x, y, 0, w, h)

	        love.graphics.setShader(xGradientShader)
	        for i = 1, 4 do 
	        	local from = table.map(self.color, function(v) return v/255 end)
	        	local to = table.map(self.color, function(v) return v/255 end)
	        	from[i] = 0
	        	to[i] = 1

	        	xGradientShader:send("from", from)
	        	xGradientShader:send("to", to)

	        	local y = theme.Colorpicker.margin + i * self.numberWheels[1].height + spacing * (i-1) + 2
	        	love.graphics.draw(pixelImage, theme.Colorpicker.margin, y, 0, self.numberWheels[1].width, 10)
	        end
	        love.graphics.setShader()
		love.graphics.pop()
        
	end
end