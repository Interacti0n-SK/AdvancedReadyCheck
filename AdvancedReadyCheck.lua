-- Create the main frame
local ReadyCheck = CreateFrame("Frame", "MyRaidInfoAddonFrame", UIParent)
ReadyCheck:Hide() -- Hide the frame initially
ReadyCheck:SetSize(750, 415) -- Set the size of the frame
ReadyCheck:SetPoint("CENTER") -- Set the position of the frame
ReadyCheck:SetMovable(true) -- Allow the frame to be moved
ReadyCheck:EnableMouse(true) -- Enable mouse interaction

-- Apply ElvUI styling if ElvUI is loaded
--if IsAddOnLoaded("ElvUI") then
    -- Ensure ElvUI is correctly imported and used here TODO
--else
    -- Default Blizzard UI styling
    ReadyCheck:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    ReadyCheck:SetBackdropColor(0, 0, 0, 0.9) -- Set the background color to black with alpha 0.9
--end

-- Create a title for the frame
ReadyCheck.title = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ReadyCheck.title:SetPoint("TOP", 0, -10)
ReadyCheck.title:SetFont(ReadyCheck.title:GetFont(), 15)
ReadyCheck.title:SetText("Advanced Ready Check")

-- Create a FontString to display the remaining time
ReadyCheck.timeRemaining = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
ReadyCheck.timeRemaining:SetPoint("TOPRIGHT", ReadyCheck, "TOPRIGHT", -50, -10)
ReadyCheck.timeRemaining:SetFont(ReadyCheck.timeRemaining:GetFont(), 15)
ReadyCheck.timeRemaining:SetText("Ready Check Finished")

-- Define column positions
local columnPositions = {
    ready = 25,
    role = 80,
    name = 120,
    class = 250,
    personalBuffs = 300,
	raidBuffs = 500
}

-- Create header line for column titles
local headers = {
    ready = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
    role = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
    name = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
    class = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
    personalBuffs = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
}

headers.ready:SetPoint("TOPLEFT", columnPositions.ready-17, -50)
headers.ready:SetFont(headers.ready:GetFont(), 15)
headers.ready:SetText("Ready")

headers.role:SetPoint("TOPLEFT", columnPositions.role-10, -50)
headers.role:SetFont(headers.role:GetFont(), 15)
headers.role:SetText("Role")

headers.name:SetPoint("TOPLEFT", columnPositions.name+25, -50)
headers.name:SetFont(headers.name:GetFont(), 15)
headers.name:SetText("Name")

headers.class:SetPoint("TOPLEFT", columnPositions.class-10, -50)
headers.class:SetFont(headers.class:GetFont(), 15)
headers.class:SetText("Class")

headers.personalBuffs:SetPoint("TOPLEFT", columnPositions.personalBuffs, -50)
headers.personalBuffs:SetFont(headers.personalBuffs:GetFont(), 15)
headers.personalBuffs:SetText("Food Buff")

-- Create lines for raid member information
ReadyCheck.lines = {}

for i = 1, 10 do
    ReadyCheck.lines[i] = {
        ready = ReadyCheck:CreateTexture(nil, "OVERLAY"),
        role = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
        name = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
        class = ReadyCheck:CreateTexture(nil, "OVERLAY"),
        personalBuffs = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
    }
    for key, element in pairs(ReadyCheck.lines[i]) do
        if key == "ready" or key == "class" then
            element:SetSize(20, 20)
		else 
			element:SetFont(element:GetFont(), 15)
        end
        element:SetPoint("TOPLEFT", columnPositions[key], -80 - (i - 1) * 25)
    end
end

-- Create a close button
ReadyCheck.closeButton = CreateFrame("Button", nil, ReadyCheck, "UIPanelCloseButton")
ReadyCheck.closeButton:SetPoint("TOPRIGHT", -5, -5)
ReadyCheck.closeButton:SetScript("OnClick", function() ReadyCheck:Hide() end)

-- Register for events
ReadyCheck:RegisterEvent("READY_CHECK")
ReadyCheck:RegisterEvent("READY_CHECK_CONFIRM")
ReadyCheck:RegisterEvent("READY_CHECK_FINISHED")
ReadyCheck:RegisterEvent("PLAYER_REGEN_DISABLED")
ReadyCheck:RegisterEvent("GROUP_ROSTER_UPDATE")
ReadyCheck:RegisterEvent("UNIT_CONNECTION")
ReadyCheck:RegisterEvent("INSPECT_READY")
ReadyCheck:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

local raidInfo = {}
local readyCheckEndTime
local inspectedPlayers = {}

local roleIcons = {
    TANK = INLINE_TANK_ICON,
    HEALER = INLINE_HEALER_ICON,
    DAMAGER = INLINE_DAMAGER_ICON,
    NONE = "",
}

local statusTextures = {
    ready = "Interface\\RAIDFRAME\\ReadyCheck-Ready",
    notReady = "Interface\\RAIDFRAME\\ReadyCheck-NotReady",
    pending = "Interface\\RAIDFRAME\\ReadyCheck-Waiting"
}

local classIcons = {
    WARRIOR = "Interface\\Icons\\ClassIcon_Warrior",
    PALADIN = "Interface\\Icons\\ClassIcon_Paladin",
    HUNTER = "Interface\\Icons\\ClassIcon_Hunter",
    ROGUE = "Interface\\Icons\\ClassIcon_Rogue",
    PRIEST = "Interface\\Icons\\ClassIcon_Priest",
    DEATHKNIGHT = "Interface\\Icons\\ClassIcon_DeathKnight",
    SHAMAN = "Interface\\Icons\\ClassIcon_Shaman",
    MAGE = "Interface\\Icons\\ClassIcon_Mage",
    WARLOCK = "Interface\\Icons\\ClassIcon_Warlock",
    MONK = "Interface\\Icons\\ClassIcon_Monk",
    DRUID = "Interface\\Icons\\ClassIcon_Druid",
}

local function GetUnitFromGUID(guid)
    for _, unitId in ipairs({
        "player", "target", "focus", 
        "party1", "party2", "party3", "party4", 
        "raid1", "raid2", "raid3", "raid4", "raid5", "raid6", "raid7", "raid8", "raid9", "raid10",
        "raid11", "raid12", "raid13", "raid14", "raid15", "raid16", "raid17", "raid18", "raid19", "raid20",
        "raid21", "raid22", "raid23", "raid24", "raid25", "raid26", "raid27", "raid28", "raid29", "raid30",
        "raid31", "raid32", "raid33", "raid34", "raid35", "raid36", "raid37", "raid38", "raid39", "raid40",
        "boss1", "boss2", "boss3", "boss4"
    }) do
        if UnitGUID(unitId) == guid then
            return unitId
        end
    end
    return nil
end

local function QueueInspect(unitName)
    if CanInspect(unitName) then
        NotifyInspect(unitName)
    else
        -- Queue the inspection
        inspectedPlayers[unitName] = true
    end
end

local function UpdatePlayerSpecialization()
    -- Update the player's specialization immediately
    local specID = GetSpecialization()
    if specID then
        local _, _, _, specIcon = GetSpecializationInfo(specID)
        raidInfo[UnitName("player")] = raidInfo[UnitName("player")] or {}
        raidInfo[UnitName("player")].specIcon = specIcon
        for i, line in ipairs(ReadyCheck.lines) do
            if line.name and line.name:GetText() == UnitName("player") then
                line.class:SetTexture(specIcon)
                break
            end
        end
    end
end

local function OnInspectReady(guid)
    local unit = GetUnitFromGUID(guid)
    if unit then
        local specID = GetInspectSpecialization(unit)
        ClearInspectPlayer()
        if specID then
            local _, _, _, specIcon = GetSpecializationInfoByID(specID)
            local name = UnitName(unit)
            if name then
                raidInfo[name] = raidInfo[name] or {}
                raidInfo[name].specIcon = specIcon
                local index = nil
                for i = 1, 10 do
                    if ReadyCheck.lines[i] and ReadyCheck.lines[i].name:GetText() == name then
                        index = i
                        break
                    end
                end
                if index then
                    ReadyCheck.lines[index].class:SetTexture(specIcon)
                end
            end
        end
    end
end

local function DisplayRaidInfo()
    local numRaidMembers = GetNumGroupMembers()
    
    -- Ensure we have enough lines for all raid members
    for i = 1, numRaidMembers do
        if not ReadyCheck.lines[i] then
            ReadyCheck.lines[i] = {
                ready = ReadyCheck:CreateTexture(nil, "OVERLAY"),
                role = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
                name = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
                class = ReadyCheck:CreateTexture(nil, "OVERLAY"),
                personalBuffs = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
            }
            for key, element in pairs(ReadyCheck.lines[i]) do
                if key == "ready" or key == "class" then
                    element:SetSize(25, 25)
				else
					element:SetFont(element:GetFont(), 15)
                end
                element:SetPoint("TOPLEFT", columnPositions[key], -80 - (i - 1) * 25)
            end
        end
    end

    for i = 1, numRaidMembers do
        local name, _, _, _, _, class, _, online = GetRaidRosterInfo(i)
        local role = UnitGroupRolesAssigned(name)
        
        if name == UnitName("player") then
            -- Update player specialization immediately
            UpdatePlayerSpecialization()
        else
            -- Queue inspection for other players
            QueueInspect(name)
        end

        raidInfo[name] = raidInfo[name] or {}
        raidInfo[name].name = name
        raidInfo[name].class = class
        raidInfo[name].role = role
        raidInfo[name].personalBuffs = raidInfo[name].personalBuffs or "No Buff"

        local line = ReadyCheck.lines[i]
        
        -- Ensure line is initialized
        if line then
            line.role:SetFormattedText("%s", roleIcons[raidInfo[name].role])
            line.name:SetText(raidInfo[name].name)
			line.personalBuffs:SetText(raidInfo[name].personalBuffs)
			if raidInfo[name].specIcon then
				line.class:SetTexture(raidInfo[name].specIcon)
			else
				line.class:SetTexture(classIcons[raidInfo[name].class])
			end
			if online == nil then
				line.ready:SetTexture(statusTextures["notReady"])
			end
        end
    end
end

local function ResetReadyStatus()
	local numRaidMembers = GetNumGroupMembers()
    for i, line in ipairs(ReadyCheck.lines) do
			if i > numRaidMembers then
				break
			end
            line.ready:SetTexture(statusTextures["pending"])
    end
end

local function OnReadyCheck(initiator, timeLeft)
    ResetReadyStatus()
	DisplayRaidInfo()
    for i, line in ipairs(ReadyCheck.lines) do
        if line.name and line.name:GetText() == initiator then
            line.ready:SetTexture(statusTextures["ready"])
            break
        end
    end
    ReadyCheck:Show()
    readyCheckEndTime = GetTime() + timeLeft
end

local function OnReadyCheckConfirm(unit, ready)
    local name = GetUnitName(unit, true)
	local isReady = ""
	if ready then
		isReady = "ready"
	else
		isReady = "notReady"
	end
    for i, line in ipairs(ReadyCheck.lines) do
        if line.name and line.name:GetText() == name then
            line.ready:SetTexture(statusTextures[isReady])
            break
        end
    end
end

local function OnReadyCheckFinished()	
	local numRaidMembers = GetNumGroupMembers()
    for i, line in ipairs(ReadyCheck.lines) do
			if i > numRaidMembers then
				break
			end
            if line.ready:GetTexture() == statusTextures["pending"] then
				line.ready:SetTexture(statusTextures["notReady"])
			end
    end
    readyCheckEndTime = nil
    ReadyCheck.timeRemaining:SetText("Ready Check Finished")
end

local function OnPlayerRegenDisabled()
    if ReadyCheck:IsShown() then
        ReadyCheck:Hide()
    end
end

local function OnGroupRosterUpdate()
    if ReadyCheck:IsShown() then
        DisplayRaidInfo()
    end
end

local function OnUnitConnection(unit)
    if ReadyCheck:IsShown() then
        DisplayRaidInfo()
    end
end

local function UpdateTimeRemaining()
    if readyCheckEndTime then
        local timeLeft = math.max(0, math.floor(readyCheckEndTime - GetTime()))
        ReadyCheck.timeRemaining:SetText(string.format("Time Remaining: %d seconds", timeLeft))
        if timeLeft <= 0 then
            OnReadyCheckFinished()
        end
    end
end

ReadyCheck:SetScript("OnEvent", function(self, event, ...)
    if event == "READY_CHECK" then
        OnReadyCheck(...)
    elseif event == "READY_CHECK_CONFIRM" then
        OnReadyCheckConfirm(...)
    elseif event == "READY_CHECK_FINISHED" then
        OnReadyCheckFinished()
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnPlayerRegenDisabled()
    elseif event == "GROUP_ROSTER_UPDATE" then
        OnGroupRosterUpdate()
    elseif event == "UNIT_CONNECTION" then
        OnUnitConnection(...)
    elseif event == "INSPECT_READY" then
        OnInspectReady(...)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        UpdatePlayerSpecialization()
    end
end)

ReadyCheck:SetScript("OnUpdate", function(self, elapsed)
    UpdateTimeRemaining()
end)

ReadyCheck:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)

ReadyCheck:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        self:StopMovingOrSizing()
    end
end)

-- Define the slash command function
SLASH_ARC1 = "/arc"
SlashCmdList["ARC"] = function()
    if ReadyCheck:IsShown() then
        ReadyCheck:Hide()
    else
		DisplayRaidInfo()
        ReadyCheck:Show()
    end
end
