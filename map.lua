do 
	map  = {}
	map.entityFiles = {"entities.lua"}
	map.entities = {}

	mapStack = {cursor = 1}
	mapStack[1] = {"empty map on startup", map}

	-- pushes a copy of the current map object above the cursor
	function mapStack:push(label)
		editor.unsavedChanges = true
		self.cursor = self.cursor + 1
		self[self.cursor] = {label, tableDeepCopy(map)}
		for i = self.cursor + 1, #self do 
			self[i] = nil
		end 
		map = mapStack[self.cursor][2]
	end 

	-- sets the current map object to the one seeked to on the stack (absolute is false by default)
	function mapStack:seek(v, absolute)
		self.cursor = math.min(math.max(absolute and v or self.cursor + v, 1), #self)
		map = mapStack[self.cursor][2]
	end 

	function mapStack:print()
		for i = 1, #self do 
			gui.printConsole(tostring(i) .. ": " .. mapStack[i][1])
		end 
	end

	function dbg_getMapStackIndex(entity)
		local indices = {}
		for i = 1, #mapStack do 
			for j = 1, #mapStack[i][2].entities do 
				if mapStack[i][2].entities[j] == entity then 
					indices[#indices+1] = i
				end 
			end 
		end 
		assert(#indices == 1)
		return indices[1]
	end 
end 