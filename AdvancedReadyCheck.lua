-- Initialize the main frame
local ReadyCheck = _G["MyRaidInfoAddonFrame"]
ReadyCheck:Hide()

-- Define column positions
local columnPositions = {
    ready = 25,
    role = 80,
    name = 120,
    class = 250,
    consumes = 300,
    flask = 300,
    food = 330,
    raidBuffs = 500
}

-- Retrieve and setup header and close button
local title = ReadyCheck.title
local timeRemaining = ReadyCheck.timeRemaining
local headers = {
    ready = _G["MyRaidInfoAddonFrameHeaderReady"],
    role = _G["MyRaidInfoAddonFrameHeaderRole"],
    name = _G["MyRaidInfoAddonFrameHeaderName"],
    class = _G["MyRaidInfoAddonFrameHeaderClass"],
    consumes = _G["MyRaidInfoAddonFrameHeaderConsumes"]
}
local closeButton = ReadyCheck.closeButton

-- Initialize lines
ReadyCheck.lines = {}
for i = 1, 10 do
    ReadyCheck.lines[i] = {
        ready = ReadyCheck:CreateTexture(nil, "OVERLAY"),
        role = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
        name = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
        class = ReadyCheck:CreateTexture(nil, "OVERLAY"),
        flask = ReadyCheck:CreateTexture(nil, "OVERLAY"),
        food = ReadyCheck:CreateTexture(nil, "OVERLAY"),
        consumes = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
    }
    for key, element in pairs(ReadyCheck.lines[i]) do
        if key == "ready" or key == "class" or key == "flask" or key == "food" then
            element:SetSize(20, 20)
        else
            element:SetFont(element:GetFont(), 15)
        end
        element:SetPoint("TOPLEFT", columnPositions[key], -80 - (i - 1) * 25)
    end
end

-- Define icons and textures
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

local flaskBuffs = {
    105689, -- Flask of Spring Blossoms
    105691, -- Flask of the Warm Sun
    105693, -- Flask of the Falling Leafs
    105694, -- Flask of the Earth
    105696, -- Flask of Winter's Bite
}

local foodBuffs = {}

local raidInfo = {}
local readyCheckEndTime
local inspectedPlayers = {}

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
        inspectedPlayers[unitName] = true
    end
end

local function UpdatePlayerSpecialization()
    local specID = GetSpecialization()
    if specID then
        local _, _, _, specIcon = GetSpecializationInfo(specID)
        raidInfo[UnitName("player")] = raidInfo[UnitName("player")] or {}
        raidInfo[UnitName("player")].specIcon = specIcon
    end
end

local function GetPlayerInfo(unitId)
    local name = UnitName(unitId)
    local role = UnitGroupRolesAssigned(unitId)
    local class = select(2, UnitClass(unitId))
    local classColor = select(1, GetClassColor(class))
    local specIcon = GetSpecializationInfo(GetSpecialization() or 0)
    local isReady = GetReadyCheckStatus(unitId)
    local flask = nil
    local food = nil
    local buffs = { UnitBuff(unitId, 1) }
    
    for _, buffID in ipairs(flaskBuffs) do
        if UnitBuff(unitId, GetSpellInfo(buffID)) then
            flask = true
            break
        end
    end
    
    for _, buff in pairs(buffs) do
        if buff then
            food = true
            break
        end
    end
    
    return {
        name = name,
        role = role,
        class = class,
        classColor = classColor,
        specIcon = specIcon,
        isReady = isReady,
        flask = flask,
        food = food
    }
end

local function UpdateReadyCheck()
    for unitId in pairs(raidInfo) do
        local playerInfo = GetPlayerInfo(unitId)
        local line = ReadyCheck.lines[unitId]
        
        if playerInfo then
            line.ready:SetTexture(statusTextures[playerInfo.isReady])
            line.role:SetTexture(roleIcons[playerInfo.role] or "")
            line.name:SetText(playerInfo.name)
            line.class:SetTexture(classIcons[playerInfo.class] or "")
            line.flask:SetTexture(playerInfo.flask and "Interface\\Icons\\Trade_Brewing" or "")
            line.food:SetTexture(playerInfo.food and "Interface\\Icons\\INV_Misc_Food_73" or "")
            line.consumes:SetText((playerInfo.flask and "Flask" or "") .. " " .. (playerInfo.food and "Food" or ""))
        end
    end
end

local function DisplayRaidInfo()
    local numMembers = GetNumGroupMembers()
    if numMembers > 0 then
        for i = 1, numMembers do
            local unitId = "raid"..i
            local name = UnitName(unitId)
            if name then
                raidInfo[name] = GetPlayerInfo(unitId)
                QueueInspect(unitId)
            end
        end
        UpdateReadyCheck()
    end
end

-- Event handling
local function OnEvent(self, event, ...)
    if event == "READY_CHECK" then
        readyCheckEndTime = GetTime() + 30
        UpdatePlayerSpecialization()
        DisplayRaidInfo()
        ReadyCheck:Show()
    elseif event == "READY_CHECK_CONFIRM" or event == "READY_CHECK_CANCEL" then
        ReadyCheck:Hide()
    elseif event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_AURA" then
        UpdateReadyCheck()
    end
end

-- Event frame setup
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("READY_CHECK")
eventFrame:RegisterEvent("READY_CHECK_CONFIRM")
eventFrame:RegisterEvent("READY_CHECK_CANCEL")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:SetScript("OnEvent", OnEvent)

-- Slash command to toggle the frame
SLASH_ARC1 = "/arc"
SlashCmdList["ARC"] = function()
    if ReadyCheck:IsShown() then
        ReadyCheck:Hide()
    else
        DisplayRaidInfo()
        ReadyCheck:Show()
    end
end
