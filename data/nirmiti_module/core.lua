-- Nirmiti: Sanskrit for "creation". --
-- Peer through the lines, and let it spark your creativity. --

-- Kudos to Chrono Vortex, plus Vertaalfout and Commander Julk, for being the source of most of this Lua. --



-- [/// CORE LOGIC ///] --
-- [The heart and soul of Nirmiti.] --

if not mods then mods = {} end
if not mods.nirmiti then -- Only implement the core if the namespace isn't defined yet.

-- [Namespace definition.] --

mods.nirmiti = {}

-- [Maximum value of a signed 32-bit integer field, used in some checks.]

local INT_MAX = 2147483647

-- [FUNCTION - Empty function, does nothing.]

function mods.nirmiti.pass()
end

-- [FUNCTION - Iterator function used to loop through tables, as HS Lua lacks one.] --

function mods.nirmiti.vter(cvec)
    local i = -1
    local n = cvec:size()
    return function()
        i = i + 1
        if i < n then return cvec[i] end
    end
end

-- [FUNCTION - It keeps things from exploding. It creates an empty table for some things, but... I dunno what things lack and need a table.]

function mods.nirmiti.userdata_table(userdata, tableName)
    if not userdata.table[tableName] then
        userdata.table[tableName] = {}
    end
    return userdata.table[tableName]
end

-- [FUNCTION - Copy a table recursively.]

function mods.nirmiti.table_copy_deep(value, cache, promises, copies)
    cache = cache or {}
    promises = promises or {}
    copies = copies or {}
    local copy
    if type(value) == 'table' then
        if (cache[value]) then
            copy = cache[value]
        else
            promises[value] = promises[value] or {}
            copy = {}
            for k, v in next, value, nil do
                local nKey = promises[k] or mods.vertexutil.table_copy_deep(k, cache, promises, copies)
                local nValue = promises[v] or mods.vertexutil.table_copy_deep(v, cache, promises, copies)
                copies[nKey] = type(k) == "table" and k or nil
                copies[nValue] = type(v) == "table" and v or nil
                copy[nKey] = nValue
            end
            local mt = getmetatable(value)
            if mt then
                setmetatable(copy, mt.__immutable and mt or mods.vertexutil.table_copy_deep(mt, cache, promises, copies))
            end
            cache[value] = copy
        end
    else
        copy = value
    end
    for k, v in pairs(copies) do
        if k == cache[v] then
            copies[k] = nil
        end
    end
    local function correctRec(tbl)
        if type(tbl) ~= "table" then return tbl end
        if copies[tbl] and cache[copies[tbl]] then
            return cache[copies[tbl]]
        end
        local new = {}
        for k, v in pairs(tbl) do
            local oldK = k
            k, v = correctRec(k), correctRec(v)
            if k ~= oldK then
                tbl[oldK] = nil
                new[k] = v
            else
                tbl[k] = v
            end
        end
        for k, v in pairs(new) do
            tbl[k] = v
        end
        return tbl
    end
    correctRec(copy)
    return copy
end

-- [/// PARSER LOGIC ///] --
-- [Used to help parse XML.] --

-- [FUNCTION - Convert string boolean to LUA boolean. Same XML boolean conversion as used in HS.] --

function mods.nirmiti.parse_xml_bool(s)
    return s == "true" or s == "True" or s == "TRUE"
end

-- [FUNCTION - Iterator function used to loop through a node's children.] --

do
    local function node_iter(parent, child)
        if child == "Start" then return parent:first_node() end
        return child:next_sibling()
    end

    mods.nirmiti.node_children = function(parent)
        if not parent then error("Invalid node to node_children iterator!", 2) end
        return node_iter, parent, "Start"
    end
end

-- [FUNCTION - Get the value of a node and throw an error if it doesn't exist.] --

function mods.nirmiti.node_get_value(node, errorMsg)
    if not node then error(errorMsg, 2) end
    local ret = node:value()
    if not ret then error(errorMsg, 2) end
    return ret
end

-- [FUNCTION - Get the value of a node and return a default value if it doesn't exist.] --

function mods.nirmiti.node_get_value_default(node, default)
    if not node then return default end
    local ret = node:value()
    if not ret then return default end
    return ret
end

-- [FUNCTION - Get the number value of a node and throw an error if it doesn't exist or isn't a valid number.] --

function mods.nirmiti.node_get_number(node, errorMsg)
    if not node then error(errorMsg, 2) end
    local ret = tonumber(node:value())
    if not ret then error(errorMsg, 2) end
    return ret
end

-- [FUNCTION - Get the number value of a node and return a default value if it doesn't exist or isn't a valid number.] --

function mods.nirmiti.node_get_number_default(node, default)
    if not node then return default end
    local ret = tonumber(node:value())
    if not ret then return default end
    return ret
end

-- [FUNCTION - Get the boolean value of a node and return a default value if it doesn't exist or isn't a valid boolean.] --

function mods.nirmiti.node_get_bool_default(node, default)
    if not node then return default end
    local ret = node:value()
    if not ret then return default end
    return mods.nirmiti.parse_xml_bool(ret)
end

end