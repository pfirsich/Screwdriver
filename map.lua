do 
	map = {}
	map.entityFiles = {}
	map.entities = {}

	mapStack = {cursor = 1}
	mapStack[1] = {label = "empty map on startup", map = tableDeepCopy(map)}

	-- pushes a copy of the current map object above the cursor
	function mapStack:push(label)
		self[self.cursor+1] = {label = label, map = tableDeepCopy(mapStack[self.cursor].map)}
		self.cursor = self.cursor + 1
		for i = self.cursor + 1, #self do self[i] = nil end 
	end 

	-- sets the current map object to the one seeked to on the stack (absolute is false by default)
	function mapStack:seek(v, absolute)
		self.cursor = math.min(math.max(absolute and v or self.cursor + v, 1), #self)
		map = tableDeepCopy(mapStack[self.cursor].map)
		updateUserdataValues()
	end 

	function mapStack:print()
		for i = 1, #self do 
			gui.printConsole(tostring(i) .. ": " .. mapStack[i].label)
		end 
	end
end 