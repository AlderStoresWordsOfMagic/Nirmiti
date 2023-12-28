-- Nirmiti: Sanskrit for "creation". --
-- Peer through the lines, and let it spark your creativity. --

-- Kudos to Chrono Vortex, plus Vertaalfout and Commander Julk, for being the source of most of this Lua. --



-- [/// CORE LOGIC ///] --
-- [The heart and soul of Nirmiti.] --

-- [Namespace definition.] --

mods.nirmiti = {}

-- [Maximum value of a signed 32-bit integer field, used in some checks.]

local INT_MAX = 2147483647

-- [FUNCTION - Empty function, does nothing.]

function mods.nirmiti.pass()
end

-- [FUNCTION - Iterator function used to loop through tables, as HS Lua lacks one.] --

local vter = mods.nirmiti.vter

function mods.nirmiti.vter(cvec)
    local i = -1
    local n = cvec:size()
    return function()
        i = i + 1
        if i < n then return cvec[i] end
    end
end

-- [FUNCTION - It keeps things from exploding. It creates an empty table for some things, but... I dunno what things lack and need a table.]

local userdata_table = mods.nirmiti.userdata_table

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

-- [/// CUSTOM XML PARSERS ///] --
-- [The missing link.] --