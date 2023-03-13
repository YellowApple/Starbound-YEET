require "/scripts/vec2.lua"

-- Credit where credit's due to Pygmyowl; while this code deviates
-- considerably from HoloRuler, holoruler.lua and holoRulerEff.lua
-- were handy references.

function init()
    -- FIXME: make these configurable
    self.pointImage = "/items/active/unsorted/yeet/markers.png:<variant>"
    self.pointColor = {255,0,255,255}
    self.textImage = "/interface/minburn.png:<char>"
    self.textColor = {255,255,0,255}
    self.lineColor = {255,0,255,255}
    self.origin = {}
    self.extent = {}
    self.userPos = {}
end

function uninit()
    localAnimator.clearDrawables()
end

function update()
    if shouldRedraw() then updateOverlay() end
end

function shouldRedraw()
    local newSelection = animationConfig.animationParameter("selection")
    if type(newSelection) ~= "table" then newSelection = {} end
    local newOrigin = newSelection.origin
    if type(newOrigin) ~= "table" then newOrigin = {} end
    local newExtent = newSelection.extent
    if type(newExtent) ~= "table" then newExtent = {} end
    local newMode = newSelection.mode
    local newText = animationConfig.animationParameter("text")
    local newUserPos = animationConfig.animationParameter("userPos")
    if type(newUserPos) ~= "table" then newUserPos = {} end

    local redraw = false

    if self.origin[1] ~= newOrigin[1] then
        redraw = true
        self.origin = newOrigin
    end
    if self.origin[2] ~= newOrigin[2] then
        redraw = true
        self.origin = newOrigin
    end
    if self.extent[1] ~= newExtent[1] then
        redraw = true
        self.extent = newExtent
    end
    if self.extent[2] ~= newExtent[2] then
        redraw = true
        self.extent = newExtent
    end
    if self.mode ~= newMode then
        redraw = true
        self.mode = newMode
    end
    if self.text ~= newText then
        redraw = true
        self.text = newText
    end
    if self.userPos[1] ~= newUserPos[1] then
        redraw = true
        self.userPos = newUserPos
    end
    if self.userPos[2] ~= newUserPos[2] then
        redraw = true
        self.userPos = newUserPos
    end

    return redraw
end

function updateOverlay()
    localAnimator.clearDrawables()
    if self.origin then updatePoint(self.origin, 1) end
    if self.extent then updatePoint(self.extent, 2) end
    if self.origin and self.extent then
        updateBox(self.origin, self.extent)
        if self.origin[1] and self.origin[2] then
            updateText({self.origin[1], self.origin[2]-1}, self.text)
        end
        local modeLine = "Mode: %s"
        if self.origin[1] and self.extent[2] then
            updateText({self.origin[1], self.extent[2]+2},
                modeLine:format(self.mode))
        end
    end
    if self.userPos then
        updateText({self.userPos[1], self.userPos[2]-4},
            "      LMB: set origin")
        updateText({self.userPos[1], self.userPos[2]-5},
            "Shift+LMB: set extent")
        updateText({self.userPos[1], self.userPos[2]-6},
            "      RMB: open GUI")
        updateText({self.userPos[1], self.userPos[2]-7},
            "Shift+RMB: YEET it!")
    end
end

function updatePoint(point, image)
    if type(point) ~= "table" then return end
    if point[1] and point[2] then
        local image = self.pointImage:gsub("<variant>", image)
        localAnimator.addDrawable({image = image,
                                   fullbright = true,
                                   position = point,
                                   centered = false,
                                   color = self.pointColor}, "overlay")
    end
end

function updateText(origin, text)
    if type(origin) ~= "table" then return end
    if type(text) ~= "string" then return end
    text = text:sub(1,40)  -- Let's limit the line length for now
    local validChars = "[a-zA-Z0-9%.%:%,%;%(%*%!%?%}%^%)%#%$%{%%%&%-%+" ..
        "%@%'%\"%[%]%<%>%/%\\%|%s]"
    local x = origin[1]
    local y = origin[2]
    if not (x and y) then return end
    for char in text:gmatch(validChars) do
        if char ~= " " then
            local image = self.textImage:gsub("<char>", char)
            localAnimator.addDrawable({image = image,
                                       fullbright = true,
                                       position = {x,y},
                                       centered = true,
                                       color = self.textColor}, "overlay")
        end
        x = x + 1
    end
end

function updateBox(origin, extent)
    if type(origin) ~= "table" then return end
    if type(extent) ~= "table" then return end
    if origin[1] and origin[2] and extent[1] and extent[2] then
        local distance = world.distance(extent, origin)
        local left = 0
        local right = distance[1]
        local bottom = 0
        local top = distance[2]

        if right > 0 then right = right + 1 else left = left + 1 end
        if top > 0 then top = top + 1 else bottom = bottom + 1 end
        
        updateLine(origin, {left,bottom}, {right,bottom})
        updateLine(origin, {left,top}, {right,top})
        updateLine(origin, {left,bottom}, {left,top})
        updateLine(origin, {right,bottom}, {right,top})

        if self.mode == "cut" then
            -- X marks the spot
            updateLine(origin, {left,bottom}, {right,top})
            updateLine(origin, {left,top}, {right,bottom})
        end

        if self.mode == "snarf" then
            -- UPloading to the YEET
            updateLine(origin, {left,bottom}, {right/2,top})
            updateLine(origin, {right/2,top}, {right,bottom})
        end

        if self.mode == "paste" then
            -- DOWNloading from the YEET
            updateLine(origin, {left,top}, {right/2,bottom})
            updateLine(origin, {right/2,bottom}, {right,top})
        end
    end
end

function offsetDistance(distance)
    if distance < 0 then
        return distance - 1
    else
        return distance
    end
end

function updateLine(origin, startPoint, endPoint)
    localAnimator.addDrawable({line = {startPoint, endPoint},
                               fullbright = true,
                               width = 1,
                               color = self.lineColor,
                               position = origin}, "overlay")
end
