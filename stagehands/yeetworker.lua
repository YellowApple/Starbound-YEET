require "/scripts/yeet/TemplateMIAB.lua"

-- Credit where credit's due to Dr. Knifegun MD
-- (a.k.a. Dr. Pilchenstein); while this code deviates considerably
-- from MIAB, miab_basestore_(reader|printer).md were handy
-- references.

function init()
    self.source = config.getParameter("yeetSource") or nil
    self.selection = config.getParameter("yeetSelection") or {}
    self.inTemplate = config.getParameter("yeetTemplate") or {}
    self.saveParameters = config.getParameter("saveParameters") or {}
    self.outTemplate = {}
    self.outTemplate.timestamp = os.time()
    self.outTemplate.name = string.format("YEET Datacard %s", os.time())
    self.outTemplate.description = "Holds a bunch of construction data"
    self.outTemplate.kind = "miab"
    self.outTemplate.data = {}
    self.operations = config.getParameter("yeetOperations") or {}
    normalizeSelection()
    if self.operations.save then
        TemplateMIAB.init(self.outTemplate.name,
                          self.outTemplate.description,
                          self.outTemplate.timestamp)
        TemplateMIAB.loadSelection(self.selection)
    end
    if self.operations.restore then
        TemplateMIAB.loadTemplate(self.inTemplate)
    end
    self.progress = {}
    self.progress.task = "Initializing"
    self.progress.current = nil
    self.progress.max = nil
    self.progress.workerId = entity.id()
    message.setHandler("yeetWorkerGetProgress", getProgressHandler)

    self.supports = {}

    self.maxIterations = 100000
    self.iterations = self.maxIterations
    self.worker = coroutine.create(process)
end

function update()
    if coroutine.status(self.worker) == "dead" then croak(); return end
    local success, result = coroutine.resume(self.worker)
    sb.logInfo("YEET worker: coro success: %s; result: %s", success, result)
    -- TODO: actually do something with success and result
    if not success then
        sb.logError("YEET worker: coroutine exception: %s", result)
        self.progress.task = "Error"
        self.progress.current = nil
        self.progress.max = nil
    end
    tellYEET("yeetSetProgress", self.progress)
end

function croak()
    self.progress = {}
    tellYEET("yeetWorkerFinished")
    stagehand.die()
end

function process()
    processExistingEntities()
    processExistingObjects()
    processExistingTiles()
    sendTemplate()
    processNewTiles()
    cleanupSupports()
    processNewObjects()
    restoreEntities()
end

function processExistingEntities()
    self.progress.task = "Pre-processing entities"
    self.progress.current = 0
    local ids = world.entityQuery(self.selection.origin,
                                  self.selection.extent,
                                  { boundMode = "collisionarea",
                                    withoutEntityId = entity.id() })
    if ids then
        self.progress.max = #ids
        for _, id in pairs(ids) do
            if self.operations.save then saveEntity(id) end
            if self.operations.erase then eraseEntity(id) end
            self.progress.current = self.progress.current + 1
            maybeYield()
        end
    end
end

function processExistingObjects()
    self.progress.task = "Pre-processing objects"
    self.progress.current = 0
    local ids = world.objectQuery(self.selection.origin,
                                  self.selection.extent)
    if ids then
        self.progress.max = #ids -- FIXME: make sure this actually works
        for _, id in pairs(ids) do
            if self.operations.save then saveObject(id) end
            if self.operations.erase then eraseObject(id) end
            self.progress.current = self.progress.current + 1
            maybeYield()
        end
    end
end

function processExistingTiles()
    local xMin = self.selection.origin[1]
    local yMin = self.selection.origin[2]
    local dist = self.selection.distance
    local xMax = xMin + dist[1]
    local yMax = yMin + dist[2]
    self.progress.task = "Pre-processing tiles"
    self.progress.current = 0
    self.progress.max = (dist[1]+1) * (dist[2]+1)

    for y=yMax,yMin,-1 do -- top to bottom
        for x=xMin,xMax,1 do -- left to right
            if self.operations.save then
                saveTile({x,y})
                saveLiquid({x,y})
            end
            if self.operations.erase then
                eraseTile({x,y})
                eraseLiquid({x,y})
            end
            self.progress.current = self.progress.current + 1
            maybeYield()
        end
    end

    if self.operations.erase then
        self.progress.max = self.progress.max * 3
        -- We wish you a Merry Kludgemas...
        for n=5,0,-1 do
            -- sb.logInfo("YEET worker: waiting %s more ticks...", n)
            definitelyYield()
        end
        for y=yMax,yMin,-1 do
            for x=xMin,xMax,1 do
                eraseTile({x,y})
                maybeYield()
                self.progress.current = self.progress.current + 1
            end
        end
        -- ...and a Happy Kludge Year!
        for n=5,0,-1 do
            -- sb.logInfo("YEET worker: waiting %s more ticks...", n)
            definitelyYield()
        end
        for y=yMax,yMin,-1 do
            for x=xMin,xMax,1 do
                eraseTile({x,y})
                maybeYield()
                self.progress.current = self.progress.current + 1
            end
        end
    end
end

function sendTemplate()
    if self.operations.save then
        --TemplateMIAB.logMIABFiles()
        self.outTemplate.data = TemplateMIAB.export()
        sb.logInfo("YEET worker: output template: %s", self.outTemplate)
        tellYEET("yeetSetTemplate", self.outTemplate)
    end
end

function processNewTiles()
    local xMin = self.selection.origin[1]
    local yMin = self.selection.origin[2]
    local dist = self.selection.distance
    local xMax = xMin + dist[1]
    local yMax = yMin + dist[2]
    self.progress.task = "Processing tiles"
    self.progress.current = 0
    self.progress.max = (dist[1]+1) * (dist[2]+1)

    for y=yMin,yMax,1 do -- bottom to top
        for x=xMin,xMax,1 do -- left to right
            if self.operations.restore then
                restoreTile({x,y})
                restoreLiquid({x,y})
            end
            self.progress.current = self.progress.current + 1
            maybeYield()
        end
    end
end

function cleanupSupports()
    self.progress.task = "Cleaning up supports"
    self.progress.current = 0
    self.progress.max = #self.supports

    for i,p in ipairs(self.supports) do
        world.damageTiles({p}, "background", p, "blockish", 10000, 0)
        self.progress.current = self.progress.current + 1
        maybeYield()
    end
end

function processNewObjects()
    local xMin = self.selection.origin[1]
    local yMin = self.selection.origin[2]
    local dist = self.selection.distance
    local xMax = xMin + dist[1]
    local yMax = yMin + dist[2]
    self.progress.task = "Processing objects"
    self.progress.current = 0
    self.progress.max = (dist[1]+1) * (dist[2]+1)

    for y=yMin,yMax,1 do
        for x=xMin,xMax,1 do
            if self.operations.restore then restoreObject({x,y}) end
            self.progress.current = self.progress.current + 1
            maybeYield()
        end
    end
end

function restoreEntities()
    -- FIXME: implement
end

function saveEntity(id)
    -- FIXME: implement
end

function eraseEntity(id)
    local eType = world.entityType(id)
    if eType == "player" then
        sb.logError("YEET worker: player is in the way!")
        croak()
        definitelyYield()
        return
    end
    if eType == "monster" then
        world.sendEntityMessage(id, "despawn")
    end
end

function saveObject(id)
    if not id then return end
    local pos = world.entityPosition(id)
    local obj = {}
    obj.name = world.entityName(id)
    obj.direction = world.callScriptedEntity(id, "object.direction") or 1
    if world.containerSize(id) then
        obj.contents = world.containerItems(id)
    end

    -- These are all kind of hacky, and are based on the logic in
    -- miab_basestore_blueprint.lua.  It doesn't look like there's an
    -- easy way to simply get *all* object parameters, so instead we
    -- have to resort to trying all the ones we know about and want to
    -- preserve.
    --
    -- First, we see if the object is MIAB-aware and uses MIAB's
    -- particular approach for this:
    obj.data = world.callScriptedEntity(id, "miab_jsonParameters") or {}
    -- Then, we loop through a list of JSON parameters we both know
    -- about and care about preserving.  If modders want to tell YEET
    -- how to preserve their items' parameters, the easiest way -
    -- thanks to this approach - would be to create a
    -- stagehands/yeetworker.stagehand.patch that adds the parameter
    -- names to the saveParameters array.
    for i,p in ipairs(self.saveParameters) do
        obj.data[p] = world.getObjectParameter(id, p)
    end
    -- Lastly, this is where I would put logic to save crafting table
    -- upgrades.  However, that's a royal pain in the ass to do, and
    -- will almost certainly break for modded crafting tables anyway,
    -- so I'll need to come up with something later (FIXME: come up
    -- with something later).

    -- sb.logInfo("YEET worker: saving object %s: %s", id, obj)
    TemplateMIAB.writeObject(relativePos(pos), obj)
end

function eraseObject(id)
    local pos = world.entityPosition(id)
    if world.isTileProtected(pos) then return end
    local needsCleanup = false
    if not self.operations.drop then
        if world.containerSize(id) then world.containerTakeAll(id) end
        local breakDrop = world.getObjectParameter(id, "breakDropOptions")
        if breakDrop then needsCleanup = true end
    end
    -- sb.logInfo("YEET worker: breaking object %s", id)
    world.breakObject(id, not self.operations.drop)
    --if needsCleanup then
    local drops = world.itemDropQuery(pos, 5.0)
    for _, d in pairs(drops) do
        -- sb.logInfo("YEET worker: taking dropped item %s", d)
        world.takeItemDrop(d)
    end
    --end
end

function restoreObject(pos)
    local tPos = relativePos(pos)
    local obj = TemplateMIAB.readObject(tPos)
    if not obj.name then return end
    -- sb.logInfo("YEET worker: placing object: %s", obj)
    if world.placeObject(obj.name, pos, obj.direction, obj.data) then
        local ids = world.objectQuery(pos, 0.0)
        for _,id in pairs(ids) do
            if world.entityName(id) == obj.name then
                if obj.contents then
                    for _,i in pairs(obj.contents) do
                        world.containerAddItems(id, i)
                    end
                end
            end
        end
    end
end

function saveTile(pos)
    local bgMat = world.material(pos, "background")
    local fgMat = world.material(pos, "foreground")
    local bgMod = world.mod(pos, "background")
    local fgMod = world.mod(pos, "foreground")
    local bgColor = world.materialColor(pos, "background")
    local fgColor = world.materialColor(pos, "foreground")

    if bgMat and string.find(bgMat, "metamaterial:") then bgMat = nil end
    if fgMat and string.find(fgMat, "metamaterial:") then fgMat = nil end
    -- sb.logInfo("YEET worker: saving tile %s (%s,%s)", pos, bgMat, fgMat)
    p = relativePos(pos)
    TemplateMIAB.writeTileMats(p, {bg = bgMat, fg = fgMat})
    TemplateMIAB.writeTileMods(p, {bg = bgMod, fg = fgMod})
    TemplateMIAB.writeTileColors(p, {bg = bgColor, fg = fgColor})
end

function eraseTile(pos)
    if world.isTileProtected(pos) then return end
    local h = 0
    if self.operations.drop then h = 1000 end
    world.damageTiles({pos}, "background", pos, "blockish", 10000, h)
    world.damageTiles({pos}, "foreground", pos, "blockish", 10000, h)
end

function restoreTile(pos)
    if world.isTileProtected(pos) then return end
    local tPos = relativePos(pos)
    local mats = TemplateMIAB.readTileMats(tPos)
    local mods = TemplateMIAB.readTileMods(tPos)
    local colors = TemplateMIAB.readTileColors(tPos)

    -- sb.logInfo("YEET worker: restoring tile %s %s", tPos, mats)

    if type(mats) ~= "table" then mats = {} end
    if type(mods) ~= "table" then mods = {} end
    if type(colors) ~= "table" then colors = {} end

    if mats.bg then
        world.placeMaterial(pos, "background", mats.bg)
    else
        world.placeMaterial(pos, "background", "glass")
        table.insert(self.supports, pos)
        -- sb.logInfo("YEET worker: placed support at %s", pos)
    end

    if mats.fg then world.placeMaterial(pos, "foreground", mats.fg) end
    if mods.bg then world.placeMod(pos, "background", mods.bg) end
    if mods.fg then world.placeMod(pos, "foreground", mods.fg) end
    if colors.bg then world.setMaterialColor(pos, "background", colors.bg) end
    if colors.fg then world.setMaterialColor(pps, "foreground", colors.fg) end
end

function saveLiquid(pos)
    TemplateMIAB.writeLiquid(relativePos(pos), world.liquidAt(pos))
end

function eraseLiquid(pos)
    if world.isTileProtected(pos) then return end
    if self.operations.drop then
        local liquid = world.liquidAt(pos)
        if liquid then
            local json = root.liquidConfig(liquid[1])
            if json then
                local amount = math.ceil(liquid[2])
                world.spawnItem(json.config.itemDrop, pos, amount, {})
            end
        end
    end
    --sb.logInfo("YEET worker: erasing liquid %s", pos)
    world.destroyLiquid(pos)
end

function restoreLiquid(pos)
    if world.isTileProtected(pos) then return end
    local tPos = relativePos(pos)
    local lqd = TemplateMIAB.readLiquid(relativePos(pos))
    if type(lqd) == "table" then world.spawnLiquid(pos, lqd[1], lqd[2]) end
end

function normalizeSelection()
    -- MIAB blueprints assume the origin to be the bottom-left, so
    -- we'll internally make the same assumption to maximize
    -- compatibility.
    --
    -- TODO: if I ever get around to WEdit compatibility, it'd be
    -- worth verifying if WEdit makes the same assumption.
    local originX = self.selection.origin[1]
    local originY = self.selection.origin[2]
    local extentX = self.selection.extent[1]
    local extentY = self.selection.extent[2]

    if originX > extentX then
        self.selection.origin[1] = extentX
        self.selection.extent[1] = originX
    end
    if originY > extentY then
        self.selection.origin[2] = extentY
        self.selection.extent[2] = originY
    end

    self.selection.distance = world.distance(self.selection.extent,
                                             self.selection.origin)
end

function relativePos(pos)
    local x = math.floor(pos[1] - self.selection.origin[1])
    local y = math.floor(pos[2] - self.selection.origin[2])
    return {x,y}
end

function maybeYield(retval)
    self.iterations = self.iterations - 1
    if self.iterations < 1 then
        coroutine.yield(retval)
        self.iterations = self.maxIterations
    end
end

function definitelyYield(retval)
    coroutine.yield(retval)
    self.iterations = self.maxIterations
end

function getProgressHandler(messageName, entityIsLocal)
    return self.progress
end

function tellYEET(message, params)
    if world.entityExists(self.source) then
        return world.sendEntityMessage(self.source, message, params)
    else
        sb.logWarn("YEET worker: source entity no longer exists!")
    end
end
