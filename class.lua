-- This generates a class with an optional base.
-- The generated class can be instanced by calling it, which calls the class:init() method of it.
-- (Document static!)
-- For an example usage see the gui.internal.Stack class.
function class(base)
    local cls = {}
    cls.__index = cls
    cls.static = base and gui.internal.tableDeepCopy(base.static) or {}

    return setmetatable(cls, {
        __index = base,

        __call = function(c, ...)
            local self = setmetatable({}, c)
            if self.init then self:init(...) end
            return self
        end
    })
end
