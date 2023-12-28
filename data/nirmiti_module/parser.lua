if not mods.nirmiti.implementedParser then
mods.nirmiti.implementedParser = true

-- [/// CORE IMPORTS ///] --

local node_children = mods.nirmiti.node_children
local node_get_value_default = mods.nirmiti.node_get_value_default

local tagsBlueprintsParsed = mods.nirmiti.tagsBlueprintsParsed
local tagsBlueprintsParsers = mods.nirmiti.tagsBlueprintsParsers

-- [/// MAIN XML PARSER ///] --
-- [Iterate through all entries in blueprints and run parsers for custom tags.] --

script.on_load(function()
    local blueprintFiles = {
        "data/blueprints.xml",
        "data/dlcBlueprints.xml",
    }
    for _, file in ipairs(blueprintFiles) do
        local doc = RapidXML.xml_document(file)
        for bpNode in node_children(doc:first_node("FTL") or doc) do
            local customTags = tagsBlueprintsParsers[bpNode:name()]
            if (customTags) then
                local bpName = node_get_value_default(bpNode:first_attribute("name"), "UNKNOWN_NAME")
                for childNode in node_children(bpNode) do
                    for tagName, tagParser in pairs(customTags) do
                        if childNode:name() == "nirmiti-"..tagName then
                            tagsBlueprintsParsed[bpName.."-"..tagName] = tagParser(childNode, bpName)
                        end
                    end
                end
            end
        end
        doc:clear()
    end
    tagsBlueprintsParsers = nil -- Don't need the parsers anymore after they've been run
end)

end
