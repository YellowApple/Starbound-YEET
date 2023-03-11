require "/scripts/util.lua"

function init()
    self.selection = config.getParameter("yeetSelection") or {}
    self.datacard = newDatacard()
    local template = config.getParameter("yeetTemplate")
    if type(template) == "table" then setDatacardFromTemplate(template) end
    self.progress = config.getParameter("yeetProgress") or {}

    self.getSelectionPromise = nil
    self.getSelectionError = nil
    self.getProgressPromise = nil
    self.getProgressError = nil

    self.getHeartbeatPromise = nil
    self.getHeartbeatError = nil
    self.heartbeatDelay = 0
    self.newCardReady = false

    self.firstRun = true
    self.workerId = false
end

function update(dt)
    if everyOther() then return end
    firstRun()
    getHeartbeat()
    updateSelectionStatus()
    setStatus(generateStatusLine())
    maybeEnableYeetItButton()
end

----
-- Widget callbacks
----

function closeGUI()
    if self.progress.task then return end
    tellYEET("yeetGUIClosed")
    pane.dismiss()
end

function unfocusTextFields()
    widget.blur("txtTemplateName")
    widget.blur("txtTemplateDescription")
end

function selectMode(id)
    -- Why in the actual fuck is id a string when it's clearly a
    -- number in the JSON?  I hate Lua I hate JSON I hate it I hate it
    -- I hate it
    if id == "0" then self.selection.mode = "cut" end
    if id == "1" then self.selection.mode = "snarf" end
    if id == "2" then self.selection.mode = "paste" end
    tellYEET("yeetSetMode", {mode = self.selection.mode})
end

function setTemplateName()
    local text = widget.getText("txtTemplateName")
    self.datacard.parameters.shortdescription = text
    self.getHeartbeatPromise = tellYEET("yeetSetTemplate", dc2Template())
    self.heartbeatDelay = 60
end

function setTemplateDescription()
    local text = widget.getText("txtTemplateDescription")
    self.datacard.parameters.description = text
    self.getHeartbeatPromise = tellYEET("yeetSetTemplate", dc2Template())
    self.heartbeatDelay = 60
end

function touchTemplateDatacard()
    local handItem = player.swapSlotItem()
    sb.logInfo("YEETGUI touchTemplateDatacard HIT: %s", handItem)
    if type(handItem) == "table" then
        if handItem.name == "yeetcard" then
            setDatacard(handItem)
            updateTextFields()
        end
    else
        player.setSwapSlotItem(self.datacard)
    end
end

function clearTemplateDatacard(arg1, arg2)
    sb.logInfo("YEETGUI clearTemplateDatacard HIT: %s", arg1, arg2)
    setDatacard(nil)
end

function yeetIt()
    local operations = {}
    if self.selection.mode == "cut" then
        operations = {erase = true, save = true}
    end
    if self.selection.mode == "snarf" then
        operations = {save = true}
    end
    if self.selection.mode == "paste" then
        operations = {erase = true, restore = true}
    end
    self.getHeartbeatPromise = tellYEET("yeetStartOperations", operations)
end

function resetSelection()
    self.selection = {}
    widget.setChecked("btnsSelectMode.0", false)
    widget.setChecked("btnsSelectMode.1", false)
    widget.setChecked("btnsSelectMode.2", false)
    tellYEET("yeetResetSelection")
end

----
-- Event loop steps
----

function firstRun()
    if not self.firstRun then return end
    self.firstRun = false
    widget.setText("btnsSelectMode.0", "CUT")
    widget.setText("btnsSelectMode.1", "SNARF")
    widget.setText("btnsSelectMode.2", "PASTE")
    if self.selection.mode == "cut" then
        widget.setSelectedOption("btnsSelectMode", 0)
    end
    if self.selection.mode == "snarf" then
        widget.setSelectedOption("btnsSelectMode", 1)
    end
    if self.selection.mode == "paste" then
        widget.setSelectedOption("btnsSelectMode", 2)
    end
    setDatacardFromTemplate(config.getParameter("yeetTemplate"))
    updateTextFields()
    setStatus("Ready!")
end

function getHeartbeat()
    if self.heartbeatDelay > 0 then
        self.heartbeatDelay = self.heartbeatDelay - 1
        return
    end
    local promise = self.getHeartbeatPromise
    if promise then
        if promise:finished() then
            if promise:succeeded() then
                local result = promise:result()
                if type(result) == "table" then
                    self.selection = result.selection or {}
                    self.progress = result.progress or {}
                    if self.newCardReady then
                        self.newCardReady = false
                    else
                        setDatacardFromTemplate(result.template)
                    end
                else
                    self.selection = {}
                    self.progress = {}
                    if self.newCardReady then
                        self.newCardReady = false
                    else
                        setDatacardFromTemplate(nil)
                    end
                end
                updateTextFields()
                self.getHeartbeatError = nil
                self.getHeartbeatPromise = tellYEET("yeetGetHeartbeat")
            else
                self.getHeartbeatError = promise:error()
                if self.newCardReady then
                    -- Retry sending the template
                    self.getHeartbeatPromise = tellYEET("yeetSetTemplate",
                                                        dc2Template())
                else
                    self.getHeartbeatPromise = tellYEET("yeetGetHeartbeat")
                end
            end
        end
    else
        self.getHeartbeatPromise = tellYEET("yeetGetHeartbeat")
    end
end

function updateSelectionStatus()
    local originText = formatPoint(self.selection.origin)
    local extentText = formatPoint(self.selection.extent)
    local distanceText = formatSize(self.selection.distance)
    local statusText = string.format("%s -> %s | %s", originText,
                                     extentText, distanceText)
    widget.setText("lblSelectionStatus", statusText)
end

function maybeEnableYeetItButton()
    if readyToYeet() then
        widget.setButtonEnabled("btnYeetIt", true)
    else
        widget.setButtonEnabled("btnYeetIt", false)
    end
end

----
-- Helpers
----

function updateTextFields()
    local params = self.datacard.parameters
    widget.setText("txtTemplateName", params.shortdescription or "")
    widget.setText("txtTemplateDescription", params.description or "")
end

function readyToYeet()
    if self.getHeartbeatError then return false end
    if self.progress.task then return false end
    if not self.selection.origin then return false end
    if not self.selection.extent then return false end
    if not self.selection.distance then return false end
    if not self.selection.mode then return false end
    if self.selection.mode == "paste" then
        local params = self.datacard.parameters
        if not params.templateKind then return false end
        if type(params.templateData) ~= "table" then return false end
    end
    return true
end

function formatPoint(p)
    if type(p) == "table" then
        return string.format("(%s,%s)", p[1], p[2])
    else
        return "(?,?)"
    end
end

function formatSize(s)
    if type(s) == "table" then
        local s1 = s[1]
        local s2 = s[2]
        if s[1] < 0 then s1 = s1 - 1 else s1 = s1 + 1 end
        if s[2] < 0 then s2 = s2 - 1 else s2 = s2 + 1 end
        return string.format("%sx%s", s1, s2)
    else
        return "?x?"
    end
end

function tellYEET(message, params)
    if world.entityExists(pane.sourceEntity()) then
        return world.sendEntityMessage(pane.sourceEntity(), message, params)
    else
        -- Apparently sending a message to a nonexistent entity will
        -- outright crash Starbound; go figure.
        sb.logWarn("YEETGUI tellYEET: source entity no longer exists!")
    end
end

function setStatus(status)
    widget.setText("lblStatusLine", status)
end

function generateStatusLine()
    if self.getHeartbeatError then
        return string.format("YEET comm error: %s", self.getHeartbeatError)
    end
    if self.progress.task then
        return string.format("%s (%s/%s)", self.progress.task,
                             self.progress.current, self.progress.max)
    end
    if readyToYeet() then
        return "Ready!"
    end
end

function everyOther()
    local old = self.everyOther
    self.everyOther = not self.everyOther
    return old
end

function newDatacard()
    local shortdescription = string.format("YEET Datacard %s", os.time())
    local description = "Holds a bunch of construction data"
    return { name = "yeetcard",
             count = 1,
             parameters = { shortdescription = shortdescription,
                            description = description,
                            timestamp = os.time(),
                            templateKind = "miab",
                            templateData = {} } }
end

function setDatacard(descriptor)
    if type(descriptor) ~= "table" then descriptor = newDatacard() end
    local ts = descriptor.parameters.timestamp or os.time()
    descriptor.parameters.timestamp = ts
    self.datacard = descriptor
    widget.setItemSlotItem("itmTemplateDatacard", self.datacard)
    self.newCardReady = true
    self.getHeartbeatPromise = tellYEET("yeetSetTemplate", dc2Template())
end

function setDatacardFromTemplate(template)
    if type(template) ~= "table" then return end
    template.timestamp = template.timestamp or 0
    self.datacard.parameters.shortdescription = template.name
    self.datacard.parameters.description = template.description
    self.datacard.parameters.timestamp = template.timestamp
    self.datacard.parameters.templateKind = template.kind
    self.datacard.parameters.templateData = template.data
    widget.setItemSlotItem("itmTemplateDatacard", self.datacard)
end

function dc2Template()
    local params = self.datacard.parameters
    return { name = params.shortdescription,
             description = params.description,
             timestamp = params.timestamp,
             kind = params.templateKind,
             data = params.templateData }
end
