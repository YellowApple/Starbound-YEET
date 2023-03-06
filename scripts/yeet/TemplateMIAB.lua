-- Credit where credit's due to Dr. Knifegun MD
-- (a.k.a. Dr. Pilchenstein); while this code deviates considerably
-- from MIAB, miab_basestore_blueprint.lua was a handy reference.

local T = {}

function T.init(name, description, timestamp, icon)
    T.shortDescription = name or "Building Printer"
    T.description = description or "A device that will construct a " ..
        "building from its internal blueprint"
    T.timestamp = timestamp or os.time()
    T.inventoryIcon = icon or "/objects/basestorage/" ..
        "miab_basestore_printer/inventoryicons/_base.png"
    T.recipeGroup = {"plain"}
    
    T.boundingBoxSize = {0,0}
    T.blocksTable = {}
    T.nextBlockId = 1
    T.liquidTable = {}
    T.layoutTableBackground = {}
    T.layoutTableForeground = {}
    T.layoutTableBackgroundMods = {}
    T.layoutTableForegroundMods = {}
    T.layoutTableBackgroundColours = {}
    T.layoutTableForegroundColours = {}
    T.objectTable = {}
    T.configTable = {}
end

function T.loadSelection(selection)
    local s = T.normalizeSelection(selection)
    T.boundingBoxSize = s.distance
end

function T.loadItemDescriptor(descriptor)
    T.init()
    if type(descriptor) ~= "table" then return end
    if type(descriptor.parameters) ~= "table" then return end
    local params = descriptor.parameters.miab_basestore_blueprint
    T.boundingBoxSize = params.boundingBoxSize
    T.blocksTable = params.blocksTable
    T.nextBlockId = params.nextBlockId
    T.liquidTable = params.liquidTable
    T.layoutTableBackground = params.layoutTableBackground
    T.layoutTableForeground = params.layoutTableForeground
    T.layoutTableBackgroundMods = params.layoutTableBackgroundMods
    T.layoutTableForegroundMods = params.layoutTableForegroundMods
    T.layoutTableBackgroundColours = params.layoutTableBackgroundColours
    T.layoutTableForegroundColours = params.layoutTableForegroundColours
    T.objectTable = params.objectTable
    T.configTable = params.configTable
end

function T.loadTemplate(t)
    T.init()
    if type(t) ~= "table" then return end
    if t.name then T.shortDescription = t.name end
    if t.description then T.description = t.description end
    if t.timestamp then T.timestamp = t.timestamp end
    if t.icon then T.inventoryIcon = t.icon end
    if type(t.data) == "table" then
        T.boundingBoxSize = t.data.boundingBoxSize
        T.blocksTable = t.data.blocksTable
        T.nextBlockId = t.data.nextBlockId
        T.liquidTable = t.data.liquidTable
        T.layoutTableBackground = t.data.layoutTableBackground
        T.layoutTableForeground = t.data.layoutTableForeground
        T.layoutTableBackgroundMods = t.data.layoutTableBackgroundMods
        T.layoutTableForegroundMods = t.data.layoutTableForegroundMods
        T.layoutTableBackgroundColours = t.data.layoutTableBackgroundColours
        T.layoutTableForegroundColours = t.data.layoutTableForegroundColours
        T.objectTable = t.data.objectTable
        T.configTable = t.data.configTable
    end
end

function T.export()
    return {
        boundingBoxSize = T.boundingBoxSize,
        blocksTable = T.blocksTable,
        nextBlockId = T.nextBlockId,
        liquidTable = T.liquidTable,
        layoutTableBackground = T.layoutTableBackground,
        layoutTableForeground = T.layoutTableForeground,
        layoutTableBackgroundMods = T.layoutTableBackgroundMods,
        layoutTableForegroundMods = T.layoutTableForegroundMods,
        layoutTableBackgroundColours = T.layoutTableBackgroundColours,
        layoutTableForegroundColours = T.layoutTableForegroundColours,
        objectTable = T.objectTable,
        configTable = T.configTable
    }
end

----
-- Readers
----

function T.readTileMats(pos)
    if not T.validPosition(pos, "readTileMats") then return end
    local x = tostring(pos[1])
    local y = tostring(pos[2])
    local mats = {}

    local bmatTable = T.layoutTableBackground
    if type(bmatTable[y]) == "table" then
        mats.bg = T.matName(bmatTable[y][x])
    end

    local fmatTable = T.layoutTableForeground
    if type(fmatTable[y]) == "table" then
        mats.fg = T.matName(fmatTable[y][x])
    end

    return mats
end

function T.readTileMods(pos)
    if not T.validPosition(pos, "readTileMods") then return end
    local x = tostring(pos[1])
    local y = tostring(pos[2])
    local mods = {}

    local bmodTable = T.layoutTableBackgroundMods
    if type(bmodTable[y]) == "table" then
        mods.bg = T.matName(bmodTable[y][x])
    end

    local fmodTable = T.layoutTableForegroundMods
    if type(fmodTable[y]) == "table" then
        mods.fg = T.matName(fmodTable[y][x])
    end

    return mods
end

function T.readTileColors(pos)
    if not T.validPosition(pos, "readTileColors") then return end
    local x = tostring(pos[1])
    local y = tostring(pos[2])
    local colors = {}

    -- Entirely off topic: back in high school (maybe freshman or
    -- sophomore year?  It's all a blur...) I wanted to be all edgy
    -- and cool, so I started using British spellings instead of
    -- American spellings on all my English essays.  My teacher
    -- consistently marked them as misspellings.  Back then I thought
    -- it was ridiculous, but now with the wisdom of age I and my
    -- keyboard's "U" key understand that my teacher did absolutely
    -- nothing wrong and that my teenage sense of "edgy and cool" was
    -- - like in many other cases throughout my youth - just weird and
    -- kinda cringy.
    --
    -- That's what youth is for, though: to push boundaries and make
    -- mistakes.  If you're a child or teenager reading this comment:
    -- now's your time to be weird and cringy.  You're gonna fuck up
    -- every once in awhile (hell, probably a lot more often than
    -- that), and that's life.  There will be *so many moments*
    -- leading up to (and bleeding into!) adulthood that you'll
    -- reflect upon and stay up at night thinking "oh god I was so
    -- fucking stupid back then lol", and that's a *good* thing!
    -- Every time you regret something you did when you were younger,
    -- it's your mind - your soul - reminding you that you've grown as
    -- a person.  Cherish those moments now and in the future; to make
    -- a mistake and learn from it is better than to have never made
    -- the mistake at all.
    local bcolorTable = T.layoutTableBackgroundColours
    if type(bcolorTable[y]) == "table" then
        colors.bg = bcolorTable[y][x]
    end

    local fcolorTable = T.layoutTableForegroundColours
    if type(fcolorTable[y]) == "table" then
        colors.fg = fcolorTable[y][x]
    end

    return colors
end

function T.readLiquid(pos)
    if not T.validPosition(pos, "readLiquid") then return end
    local x = tostring(pos[1])
    local y = tostring(pos[2])

    if type(T.liquidTable[y]) == "table" then
        return T.liquidTable[y][x]
    else
        return nil
    end
end

function T.readObject(pos)
    if not T.validPosition(pos, "readObject") then return end
    local x = tostring(pos[1])
    local y = tostring(pos[2])
    local obj = {}

    if type(T.objectTable[y]) == "table" then
        if type(T.objectTable[y][x]) == "table" then
            local o = T.objectTable[y][x]
            obj.name = o.name
            obj.direction = o.facing
            obj.contents = o.contents
            obj.data = o.jsonParameters
        end
    end

    return obj
end

----
-- Writers
----

function T.writeTileMats(pos, mats)
    if type(pos) ~= "table" then
        sb.logError("YEET writeTileMats: invalid pos %s", pos)
        return nil
    end
    if type(mats) ~= "table" then
        mats = {}
    end
    local x = tostring(pos[1])
    local y = tostring(pos[2])
    
    if type(T.layoutTableBackground[y]) ~= "table" then
        T.layoutTableBackground[y] = {}
    end
    T.layoutTableBackground[y][x] = T.matId(mats.bg)
    
    if type(T.layoutTableForeground[y]) ~= "table" then
        T.layoutTableForeground[y] = {}
    end
    T.layoutTableForeground[y][x] = T.matId(mats.fg)
end

function T.writeTileMods(pos, mods)
    if type(pos) ~= "table" then
        sb.logError("YEET writeTileMods: invalid pos %s", pos)
        return nil
    end
    if type(mods) ~= "table" then
        mods = {}
    end
    local x = tostring(pos[1])
    local y = tostring(pos[2])

    if type(T.layoutTableBackgroundMods[y]) ~= "table" then
        T.layoutTableBackgroundMods[y] = {}
    end
    T.layoutTableBackgroundMods[y][x] = T.matId(mods.bg)

    if type(T.layoutTableForegroundMods[y]) ~= "table" then
        T.layoutTableForegroundMods[y] = {}
    end
    T.layoutTableForegroundMods[y][x] = T.matId(mods.fg)
end

function T.writeTileColors(pos, colors)
    if type(pos) ~= "table" then
        sb.logError("YEET writeTileColors: invalid pos %s", pos)
        return nil
    end
    if type(colors) ~= "table" then
        colors = {}
    end
    if colors.bg < 1 then colors.bg = nil end
    if colors.fg < 1 then colors.fg = nil end
    local x = tostring(pos[1])
    local y = tostring(pos[2])

    if type(T.layoutTableBackgroundColours[y]) ~= "table" then
        T.layoutTableBackgroundColours[y] = {}
    end
    T.layoutTableBackgroundColours[y][x] = colors.bg

    if type(T.layoutTableForegroundColours[y]) ~= "table" then
        T.layoutTableForegroundColours[y] = {}
    end
    T.layoutTableForegroundColours[y][x] = colors.fg
end

function T.writeLiquid(pos, liquid)
    if type(pos) ~= "table" then
        sb.logError("YEET writeLiquid: invalid pos %s", pos)
        return nil
    end
    local x = tostring(math.floor(pos[1]))
    local y = tostring(math.floor(pos[2]))

    if type(T.liquidTable[y]) ~= "table" then
        T.liquidTable[y] = {}
    end
    T.liquidTable[y][x] = liquid
end

function T.writeObject(pos, obj)
    if not T.validPosition(pos, "writeObject") then return end
    local x = tostring(pos[1])
    local y = tostring(pos[2])

    if type(T.objectTable[y]) ~= "table" then
        T.objectTable[y] = {}
    end
    T.objectTable[y][x] = { name = obj.name,
                            facing = obj.direction,
                            contents = obj.contents,
                            jsonParameters = obj.data }
end

----
-- Deleters
----

-- It ain't clear how well MIAB behaves if there are outright gaps in
-- table entries, so in the tile mat/mod/color deletion functions we
-- overwrite it with nothing instead.
--
-- YEET's own native format (should I ever get around to implementing
-- it) will support "sparse" tables as an explicit goal (in fact, one
-- goal is to support outright non-rectangular templates, so its
-- tables would likely be flat coordinate lists instead of
-- two-dimensional tables).

function T.deleteTileMats(pos)
    if type(pos) ~= "table" then
        sb.logError("YEET deleteTileMats: invalid pos %s", pos)
        return nil
    end
    T.writeTileMats(pos, {})
end

function T.deleteTileMods(pos)
    if type(pos) ~= "table" then
        sb.logError("YEET deleteTileMods: invalid pos %s", pos)
        return nil
    end
    T.writeTileMods(pos, {})
end

function T.deleteTileColors(pos)
    if type(pos) ~= "table" then
        sb.logError("YEET deleteTileColors: invalid pos %s", pos)
        return nil
    end
    T.writeTileColors(pos, {})
end

function T.deleteLiquid(pos)
    if type(pos) ~= "table" then
        sb.logError("YEET writeLiquid: invalid pos %s", pos)
        return nil
    end
    T.writeLiquid(pos, nil)
end

function T.deleteObject(pos)
    if not T.validPosition(pos, "deleteObject") then return end
    local x = tostring(pos[1])
    local y = tostring(pos[2])
    if type(T.objectTable[y]) ~= "table" then return end
    T.objectTable[y][x] = nil
    if T.tableIsEmpty(T.objectTable[y]) then T.objectTable[y] = nil end
end

----
-- MIAB-specific serialization
----

function T.logMIABFiles()
    local itemName = string.format("yeetMIAB-%s", T.timestamp)
    T.logMIABRecipe(itemName)
    T.logMIABPlayerConfig(itemName)
    T.logMIABObject(itemName)
end

function T.logMIABRecipe(itemName)
    local params = {}
    params.tag = itemName
    params.folder = "assets/user/recipes"
    params.filename = string.format("%s.recipe", itemName)
    params.content = {
        input = {
            {item = titaniumbar, count = 10},
            {item = money, count = 400}
        },
        output = {item = itemName, count = 1},
        groups = T.recipeGroup
    }
    T.logMIABFile(params)
end

function T.logMIABPlayerConfig(itemName)
    local params = {}
    params.tag = itemName
    params.folder = "assets/user"
    params.filename = "player.config.patch"
    params.content = {
        op = "add",
        path = "/defaultBlueprints/tier1/-",
        value = {item = itemName}
    }
    T.logMIABPatch(params)
end

function T.logMIABObject(itemName)
    local params = {}
    params.tag = itemName
    params.folder = "assets/user/objects"
    params.filename = string.format("%s.object", itemName)
    params.content = {
        objectName = itemName,
        rarity = "Common",
        description = T.description,
        shortdescription = T.shortDescription,
        race = "generic",
        category = "tool",
        price = 1,
        printable = false,
        inventoryIcon = T.inventoryIcon,
        orientations = {
            {image = "/objects/basestorage/miab_basestore_printer/miab_basestore_printer.png:<color>.<frame>",
             imagePosition = {-8,0},
             frames = 5,
             animationCycle = 1,
             spaceScan = 0.1,
             direction = "right"}
        },
        animation = "/objects/basestorage/miab_basestore_printer/miab_basestore_printer.animation",
        animationParts = {
            normal_operation_image = "/objects/basestorage/miab_basestore_printer/miab_basestore_printer.png",
            printer_icon = "/objects/basestorage/miab_basestore_printer/miab_basestore_icons.png"
        },
        animationPosition = {-8,0},
        scripts = {
            "/objects/basestorage/miab_basestore_printer/miab_basestore_print_activator.lua",
            "/scripts/basestorage/miab_basestore_printer.lua",
            "/scripts/basestorage/miab_basestore_blueprint.lua",
            "/scripts/basestorage/miab_basestore_util.lua"
        },
        scriptDelta = 5,
        miab_printer_offset = {1,0},
        miab_basestore_blueprint = T.export()
    }
    T.logMIABFile(params)
end

function T.logMIABFile(params)
    sb.logInfo(
        "\n-------------------------------------------\n" ..
        "-- miab file serialisation begins\n" ..
        "-- tag: %s\n-- target folder: %s\n-- target filename: %s\n" ..
        "-- save as %s in %s\n" ..
        "-------------------------------------------\n%s\n" ..
        "-------------------------------------------\n" ..
        "-- miab file serialisation ends\n" ..
        "-------------------------------------------\n",
        params.tag, params.folder, params.filename, params.folder,
        params.filename, sb.printJson(params.content, 0)
    )
end

function T.logMIABPatch(params)
    sb.logInfo(
        "\n-------------------------------------------\n" ..
        "-- miab file serialisation begins\n" ..
        "-- tag: %s\n-- target folder: %s\n-- target filename: %s\n" ..
        "-- if %s does not exist in %s, save as %s in %s\n" ..
        "-------------------------------------------\n%s\n" ..
        "-------------------------------------------\n" ..
        "-- miab file serialisation ends\n" ..
        "-------------------------------------------\n" ..
        "-- if %s already exists in %s, insert after first line\n" ..
        "-------------------------------------------\n%s,\n" ..
        "-------------------------------------------\n" ..
        "-- miab file serialisation ends\n" ..
        "-------------------------------------------\n",
        params.tag, params.folder, params.filename, params.filename,
        params.folder, params.folder, params.filename,
        {sb.printJson(params.content, 1)}, params.filename, params.folder,
        sb.printJson(params.content, 1)
    )
end

----
-- Helpers
----

function T.matId(name)
    name = name or "miab_scaffold"
    local id = T.blocksTable[name]
    if not id then
        T.blocksTable[name] = T.nextBlockId
        id = T.nextBlockId
        T.nextBlockId = T.nextBlockId + 1
    end
    return id
end

function T.matName(id)
    for n,i in pairs(T.blocksTable) do
        if i == id then
            if n == "miab_scaffold" then return nil else return n end
        end
    end
end

function T.validPosition(pos, context)
    if type(pos) ~= "table" then
        sb.logError("YEET %s: invalid position %s", context, pos)
        return false
    end
    return true
end

function T.normalizeSelection(selection)
    local s = {}
    if type(selection) == "table" then s = selection end
    if type(s.origin) ~= "table" then s.origin = {0,0} end
    if type(s.extent) ~= "table" then s.extent = {0,0} end
    
    local originX = s.origin[1]
    local originY = s.origin[2]
    local extentX = s.extent[1]
    local extentY = s.extent[2]

    if originX > extentX then
        s.origin[1] = extentX
        s.extent[1] = originX
    end
    if originY > extentY then
        s.origin[2] = extentY
        s.extent[2] = originY
    end

    s.distance = world.distance(s.extent, s.origin)
    return s
end

function T.tableIsEmpty(tbl)
    if type(tbl) ~= "table" then return true end
    for any,thing in pairs(t) do
        return false
    end
    return true
end

----
-- Export it!
----

TemplateMIAB = T
return T
