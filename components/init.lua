components = {}

function addTable(tbl, add)
	for k, v in pairs(add) do 
		tbl[k] = v
	end 
end 

-- TODO: Metadata-Components: MetadataString, MetadataNumber, MetadataChoice 

require "components.core"
require "components.transforms"
require "components.sprite"