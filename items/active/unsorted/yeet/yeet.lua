require "/scripts/vec2.lua"

-- Credit where credit's due to Pygmyowl; while this code deviates
-- considerably from HoloRuler, holoruler.lua and holoRulerEff.lua
-- were handy references.

function init()
    initSelection()
    initTemplate()
    initDatacard()
    initProgress()
    self.workerId = config.getParameter("yeetWorkerId")
    self.guiIsOpen = false
    self.sendTemplate = true
    
    message.setHandler("yeetGUIClosed", guiClosedHandler)
    message.setHandler("yeetResetSelection", resetSelectionHandler)
    message.setHandler("yeetGetSelection", getSelectionHandler)
    message.setHandler("yeetSetSelection", setSelectionHandler)
    message.setHandler("yeetGetTemplate", getTemplateHandler)
    message.setHandler("yeetSetTemplate", setTemplateHandler)
    message.setHandler("yeetSetMode", setModeHandler)
    message.setHandler("yeetStartOperations", startOperationsHandler)
    message.setHandler("yeetWorkerFinished", workerFinishedHandler)
    message.setHandler("yeetGetProgress", getProgressHandler)
    message.setHandler("yeetSetProgress", setProgressHandler)
    message.setHandler("yeetGetHeartbeat", getHeartbeatHandler)
end

function initSelection()
    initLocalStorage("yeetSelection", setSelection)
end

function initTemplate()
    initLocalStorage("yeetTemplate", setTemplate)
end

function initDatacard()
    initLocalStorage("yeetDatacard", setDatacard)
end

function initProgress()
    initLocalStorage("yeetProgress", setProgress)
end

function initLocalStorage(parameter, setter)
    local stored = config.getParameter(parameter)
    if type(stored) == "table" then
        setter(stored)
    else
        setter({})
    end
end

function setSelection(params)
    if type(params) == "table" then self.selection = params end
    tellOverlay("selection", self.selection)
    activeItem.setInstanceValue("yeetSelection", self.selection)
end

function setTemplate(params)
    if type(params) == "table" then self.template = params end
    sb.logInfo("YEET setTemplate HIT: %s", self.template.name)
    activeItem.setInstanceValue("yeetTemplate", self.template)
    tellOverlay("text", self.template.name)
    self.sendTemplate = true
end

function setDatacard(params)
    if type(params) == "table" then self.datacard = params end
    activeItem.setInstanceValue("yeetDatacard", self.datacard)
end

function setProgress(params)
    sb.logInfo("YEET received progress report: %s", params)
    if type(params) == "table" then self.progress = params end
    activeItem.setInstanceValue("yeetProgress", self.progress)
end

function uninit()
    activeItem.setInstanceValue("yeetSelection", self.selection)
    activeItem.setInstanceValue("yeetTemplate", self.template)
    activeItem.setInstanceValue("yeetDatacard", self.datacard)
    activeItem.setInstanceValue("yeetProgress", self.progress)
end

function update(dt, fireMode, shiftHeld)
    tellOverlay("userPos", world.entityPosition(activeItem.ownerEntityId()))
end

function activate(fireMode, shiftHeld)
    if fireMode == "primary" then
        if shiftHeld then
            updateExtent()
        else
            updateOrigin()
        end
    else
        if shiftHeld then
            startOperations()
        else
            openGUI()
        end
    end
end

function openGUI()
    if not self.guiIsOpen then
        local configPath = "/interface/scripted/yeet/yeet.config"
        local owner = activeItem.ownerEntityId()
        local configData = root.assetJson(configPath)
        configData.ownerId = activeItem.ownerEntityId()
        configData.yeetSelection = self.selection
        configData.yeetTemplate = self.template
        configData.yeetDatacard = self.datacard
        activeItem.interact("ScriptPane", configData, owner)
        self.guiIsOpen = true
    end
end

function startOperations(operations)
    if type(operations) == "table" then
        self.operations = operations
    else
        self.operations = {}
        if self.selection.mode == "cut" then
            self.operations = {erase = true, save = true}
        end
        if self.selection.mode == "snarf" then
            self.operations = {save = true}
        end
        if self.selection.mode == "paste" then
            self.operations = {erase = true, restore = true}
        end
    end
    activeItem.setInstanceValue("yeetOperations", self.operations)
    local workerConfig = {}
    workerConfig.yeetSource = activeItem.ownerEntityId()
    workerConfig.yeetSelection = self.selection
    workerConfig.yeetTemplate = self.template
    workerConfig.yeetOperations = self.operations
    world.spawnStagehand(self.selection.origin, "yeetworker", workerConfig)
    setProgress({task = "Launching"})
    return self.progress
end

function tellOverlay(param, value)
    activeItem.setScriptedAnimationParameter(param, value)
end

function guiClosedHandler(messageName, entityIsLocal)
    self.guiIsOpen = false
end

function resetSelectionHandler(messageName, entityIsLocal)
    setSelection({})
end

function getSelectionHandler(messageName, entityIsLocal)
    return self.selection
end

function setSelectionHandler(messageName, entityIsLocal, params)
    setSelection(params)
end

function getTemplateHandler(messageName, entityIsLocal)
    return self.template
end

function setTemplateHandler(messageName, entityIsLocal, params)
    setTemplate(params)
    return getHeartbeatHandler(messageName, entityIsLocal)
end

function setModeHandler(messageName, entityIsLocal, params)
    self.selection.mode = params.mode
    activeItem.setInstanceValue("yeetSelection", self.selection)
    tellOverlay("selection", self.selection)
end

function startOperationsHandler(messageName, entityIsLocal, operations)
    startOperations(operations)
    return getHeartbeatHandler(messageName, entityIsLocal)
end

function workerFinishedHandler(messageName, entityIsLocal)
    sb.logInfo("YEET: worker ID %s finished", self.progress.workerId)
    setProgress({})
    self.sendTemplate = true
end

function getProgressHandler(messageName, entityIsLocal, params)
    return self.progress
end

function setProgressHandler(messageName, entityIsLocal, params)
    setProgress(params)
end

function getHeartbeatHandler(messageName, entityIsLocal)
    local template = nil
    if self.sendTemplate then
        template = self.template
        self.sendTemplate = false
    end
    return { selection = self.selection,
             template = template,
             progress = self.progress }
end

function updateOrigin(pos)
    self.selection.origin = pos or getAimPos()
    if self.selection.extent then
        if self.selection.distance then
            local o = self.selection.origin
            local d = self.selection.distance
            self.selection.extent = {o[1] + d[1], o[2] + d[2]}
        else
            self.selection.distance= world.distance(self.selection.extent,
                                                    self.selection.origin)
        end
    end
    tellOverlay("selection", self.selection)
    activeItem.setInstanceValue("yeetSelection", self.selection)
end

function updateExtent(pos)
    self.selection.extent = pos or getAimPos()
    if self.selection.origin then
        self.selection.distance = world.distance(self.selection.extent,
                                                 self.selection.origin)
    end
    tellOverlay("selection", self.selection)
    activeItem.setInstanceValue("yeetSelection", self.selection)
end

function getAimPos()
    local pos = activeItem.ownerAimPosition()
    return { math.floor(pos[1]), math.floor(pos[2]) }
end
