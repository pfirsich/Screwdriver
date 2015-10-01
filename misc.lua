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

function foreach(tbl, func)
    for k, v in pairs(tbl) do 
        func(v)
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