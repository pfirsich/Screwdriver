function inArray(array, elem) 
	for _, e in ipairs(array) do 
		if e == elem then return true end 
	end 
	return false
end 

function tableCopy(from)
    local to = {} 
    for k, v in pairs(from) do 
        to[k] = v
    end 
    return to
end 

function rotatePoint(x, y, angle)
    local sinphi = math.sin(angle)
    local cosphi = math.cos(angle)
    local nx = cosphi * x - sinphi * y
    local ny = sinphi * x + cosphi * y
    return nx, ny
end

function tableDeepCopy(tbl)
    local ret = {}
    for k, v in pairs(tbl) do
        if type(tbl[k]) == "table" then
            ret[k] = tableDeepCopy(tbl[k])
        else
            ret[k] = tbl[k]
        end
    end
    setmetatable(ret, getmetatable(tbl))
    return ret
end

function table.iextend(to, from)
    for i = 1, #from do 
        table.insert(to, from[i])
    end 
end

function table.map(tbl, func)
    local ret = {}
    for k, v in pairs(tbl) do 
        ret[k] = func(v)
    end 
    return ret
end  

function foreach(tbl, func)
    for k, v in pairs(tbl) do 
        func(v)
    end 
end

function toggle(tbl, key)
    tbl[key] = not tbl[key]
end

function eval(str) 
    f, err = loadstring(str)
    if f == nil then 
        error(err .. " - String: '" .. str .. "'")
    end 
    return f()
end

function tostringArray(tbl)
    return "{" .. table.concat(tbl, ", ") .. "}"
end

function string.split(str, sep)
    sep = sep or "%s" -- whitespace
    local ret = {}
    for match in string.gmatch(str, "([^" .. sep .. "]+)") do
        ret[#ret+1] = match
    end
    return ret
end

function string.splitLast(str, sep)
    local before, after = str:match("(.+)" .. sep .. "([^" .. sep .. "]+)")
    if before == nil then 
        return "", str
    else 
        return before, after
    end
end 

function newImage(path) 
    local file = assert(io.open(path, "rb"))
    local filedata = love.filesystem.newFileData(file:read("*all"), path)
    file:close()
    return love.graphics.newImage(filedata)
end

do 
    local imageMap = {}
    function getImage(path)
        local img = imageMap[path]
        if img == nil then
            imageMap[path] = newImage(path)
            return imageMap[path]
        else 
            return img 
        end
    end
end

paths = {
    splitFile = function(origPath) -- origPath has to point to a file sensible results!
        local path, file = string.splitLast(origPath, "/")
        return path == "" and "." or path, file
    end, 

    getExt = function(path)
        local rest, ext = string.splitLast(path, "%.")
        return ext
    end, 

    normalize = function(path)
        local parts = string.split(path:gsub("\\", "/"), "/")
        local i = 1
        while i <= #parts do 
            if parts[i] == ".." then 
                i = i - 1
                table.remove(parts, i) -- remove the part before this
                table.remove(parts, i) -- remove this part
            elseif parts[i] == "." then 
                table.remove(parts, i)
            else
                i = i + 1
            end
        end 
        return table.concat(parts, "/")
    end,

    makeRelative = function(basePath, path) -- both have to be absolute and path has to point to a file!
        baseParts = string.split(paths.normalize(basePath), "/")
        parts = string.split(paths.normalize(path), "/")

        local partIndex = 1
        local retParts = {}
        local matching = true
        for i = 1, #baseParts do 
            if i > #parts or parts[i] ~= baseParts[i] then matching = false end 
            if matching then 
                partIndex = i
            else 
                retParts[#retParts+1] = ".."
            end
        end

        for i = partIndex + 1, #parts do 
            retParts[#retParts+1] = parts[i]
        end
        return table.concat(retParts, "/")
    end
}

function printTableShallow(name, t)
    print("--- " .. name .. "(" .. tostring(t) .. "):")
    for k, v in pairs(t) do 
        print("\t" .. k .. " = " .. tostring(v))
    end
end

function printTable(t) -- from here: https://coronalabs.com/blog/2014/09/02/tutorial-printing-table-contents/  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end