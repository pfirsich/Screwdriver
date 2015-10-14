do 
	local wrappedIndex = function(table, i) return (i-1) % #table + 1 end
	local getWrapped = function(table, i) return table[(i-1) % #table + 1] end

	local function moveEdges(polygon, amount)
		local eroded = {}
		for i = 1, #polygon, 2 do 
			local x, y = polygon[i], polygon[i+1]

			local prev_x, prev_y = getWrapped(polygon, i-2), getWrapped(polygon, i-1)
			local next_x, next_y = getWrapped(polygon, i+2), getWrapped(polygon, i+3)
			
			local prev_normal_x, prev_normal_y = -(prev_y - y), prev_x - x  
			local next_normal_x, next_normal_y = -(y - next_y), x - next_x
			
			local prev_norm = math.sqrt(prev_normal_x*prev_normal_x + prev_normal_y*prev_normal_y)
			local next_norm = math.sqrt(next_normal_x*next_normal_x + next_normal_y*next_normal_y)
			
			-- This is needed because non-right angles lead to "mixing" of translations. 
			-- Moving along one normal then also leads to moving along the other (but not in the right direction)
			-- and as a result the distance of the new and old edges is neither constant nor equal to "amount"
			local cosgamma = ( (prev_normal_x*next_normal_x) + (prev_normal_y*next_normal_y) ) / (prev_norm * next_norm)
			local cosgammahalf = math.sqrt((1+cosgamma)/2)
			
			local normal_x = prev_normal_x / prev_norm + next_normal_x / next_norm
			local normal_y = prev_normal_y / prev_norm + next_normal_y / next_norm
			
			local normal_norm = math.sqrt(normal_x*normal_x + normal_y*normal_y)
			
			normal_x = normal_x / normal_norm * amount / cosgammahalf
			normal_y = normal_y / normal_norm * amount / cosgammahalf
			
			eroded[#eroded+1] = x + normal_x
			eroded[#eroded+1] = y + normal_y
		end
		return eroded
	end

	function buildPolygonGeometry(polygon, borderThickness, blendThickness)
		local vertices = {}

		local textureScale = 0.003
		-- TODO: custom texture transforms (for each texture)
		local function pushVert(x, y, blend) vertices[#vertices+1] = {x, y, x * textureScale, y * textureScale, blend, blend, blend, blend} end

		local function pushStripe(inner, outer, innerBlend, outerBlend)
			for i = 1, #outer, 2 do
				local iNext = wrappedIndex(outer, i+2)
				pushVert(outer[i],     outer[i+1],     outerBlend)
				pushVert(inner[i],     inner[i+1],     innerBlend)
				pushVert(inner[iNext], inner[iNext+1], innerBlend)

				pushVert(outer[i],     outer[i+1],     outerBlend)
				pushVert(inner[iNext], inner[iNext+1], innerBlend)
				pushVert(outer[iNext], outer[iNext+1], outerBlend)
			end
		end

		local baseCenter = love.math.triangulate(polygon)
		for tri = 1, #baseCenter do
			for vertex = 1, #baseCenter[tri], 2 do 
				pushVert(baseCenter[tri][vertex], baseCenter[tri][vertex+1], 0) -- 0 => all base texture
			end
		end

		local borderPolygon = moveEdges(polygon, -borderThickness)
		local blendPolygon = moveEdges(polygon, -borderThickness - blendThickness)

		-- border part
		pushStripe(borderPolygon, polygon, 255, 255)

		-- blend part
		pushStripe(blendPolygon, borderPolygon, 0, 255)
		return vertices
	end

	function buildFanGeometry(polygon, fanStart, fanHeight, textureWidth, textureScale, edgeMask)
		local fanVertices = {}

		local fanStartPolygon = moveEdges(polygon, fanStart)
		local fanEndPolygon = moveEdges(polygon, fanStart + fanHeight)

		local u, uNext = 0, 0
		for i = 1, #fanEndPolygon, 2 do 
			local iNext = wrappedIndex(fanEndPolygon, i+2)

			local dx, dy = fanStartPolygon[i] - fanStartPolygon[iNext], fanStartPolygon[i+1] - fanStartPolygon[iNext+1]
			local len = math.sqrt(dx*dx + dy*dy)
			uNext = uNext + len / textureWidth * textureScale

			if not edgeMask or not edgeMask[(i+1)/2] then 
				fanVertices[#fanVertices+1] = {fanEndPolygon[i],       fanEndPolygon[i+1],       u,     0.0}
				fanVertices[#fanVertices+1] = {fanStartPolygon[i],     fanStartPolygon[i+1],     u,     1.0}
				fanVertices[#fanVertices+1] = {fanStartPolygon[iNext], fanStartPolygon[iNext+1], uNext, 1.0}

				fanVertices[#fanVertices+1] = {fanEndPolygon[i],       fanEndPolygon[i+1],       u,     0.0}
				fanVertices[#fanVertices+1] = {fanStartPolygon[iNext], fanStartPolygon[iNext+1], uNext, 1.0}
				fanVertices[#fanVertices+1] = {fanEndPolygon[iNext],   fanEndPolygon[iNext+1],   uNext, 0.0}
			end

			u = uNext
		end 

		return fanVertices
	end
end