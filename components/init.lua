components = {}

function addTable(tbl, add)
	for k, v in pairs(add) do 
		tbl[k] = v
	end 
end 

-- TODO: MetadataBoolean, MetadataString, MetadataNumber, MetadataChoice (choices = list of id-label pairs)
-- Maybe leave these out, since there just a single gui element and adocate implementing own components for games, which can include these
-- MetadataEntity? Draws connections (on-off-able) and has an edit mode to connect entities (maybe a dropdown?)

-- FancyPolygon (two texture with configurable transition and a fan texture (e.g. for grass))	

require "components.core"
require "components.transforms"
require "components.sprite"
require "components.simplepolygon"