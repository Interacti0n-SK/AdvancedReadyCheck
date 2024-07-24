-- Library
local LGIST = LibStub:GetLibrary("LibGroupInSpecT-1.0")

-- Create the main frame
local ReadyCheck = CreateFrame("Frame", "MyAddonFrame", UIParent)
ReadyCheck:Hide() -- Hide the frame initially
ReadyCheck:SetSize(750, 415) -- Set the size of the frame
ReadyCheck:SetPoint("CENTER") -- Set the position of the frame
ReadyCheck:SetMovable(true) -- Allow the frame to be moved
ReadyCheck:EnableMouse(true) -- Enable mouse interaction

ReadyCheck:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
ReadyCheck:SetBackdropColor(0, 0, 0, 0.9) -- Set the background color to black with alpha 0.9


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
	flask = 310,
	food = 350,
	raidBuffs = 500
}

-- Create header line for column titles
local headers = {
    ready = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
    role = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
    name = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
    class = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
    flask = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
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

headers.flask:SetPoint("TOPLEFT", columnPositions.flask-10, -50)
headers.flask:SetFont(headers.flask:GetFont(), 15)
headers.flask:SetText("Flask/Food")

-- Create lines for raid member information
ReadyCheck.lines = {}

-- Create fonts or textures in lines that store data
for i = 1, 10 do
    ReadyCheck.lines[i] = {
        ready = ReadyCheck:CreateTexture(nil, "OVERLAY"),
        role = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
        name = ReadyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
        class = ReadyCheck:CreateTexture(nil, "OVERLAY"),
		flask = ReadyCheck:CreateTexture(nil, "OVERLAY"),
		food = ReadyCheck:CreateTexture(nil, "OVERLAY"),
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
ReadyCheck:RegisterEvent("UNIT_AURA")

-- Register for callbacks
LGIST.RegisterCallback(ReadyCheck, "GroupInSpecT_Update", "UpdateHandler")
LGIST.Registercallback(ReadyCheck, "GroupInSpecT_Remove", "RemoveHandler")

-- List of paths for Role Icons
local roleIcons = {
    TANK = INLINE_TANK_ICON,
    HEALER = INLINE_HEALER_ICON,
    DAMAGER = INLINE_DAMAGER_ICON,
    NONE = "",
}

-- List of paths for Status Icons
local statusTextures = {
    ready = "Interface\\RAIDFRAME\\ReadyCheck-Ready",
    notReady = "Interface\\RAIDFRAME\\ReadyCheck-NotReady",
    pending = "Interface\\RAIDFRAME\\ReadyCheck-Waiting"
}

-- List of paths for Class Icons
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

-- List of Flask Buffs IDs (int5 str4 agi3 spirit2 stam1)
local flaskBuffs = {
    [105689] = "Interface\\Icons\\trade_alchemy_potione3", -- Flask of Spring Blossoms (AGI)
    [105691] = "Interface\\Icons\\trade_alchemy_potione5", -- Flask of the Warm Sun (INT)
    [105693] = "Interface\\Icons\\trade_alchemy_potione2", -- Flask of the Falling Leafs (Spirit)
    [105694] = "Interface\\Icons\\trade_alchemy_potione1", -- Flask of the Earth (STAM)
    [105696] = "Interface\\Icons\\trade_alchemy_potione4", -- Flask of Winter's Bite (STR)
}

-- List of Food Buffs IDs		
local foodBuffs = {

}

local raidInfo = {}
local readyCheckEndTime
local numGroupMembers = 0

local function UpdateBuff(unit)

		-- Check for buffs
        for j = 1, 40 do
            local buff = select(11, UnitBuff(name, j))
			--Flask Buffs
            if buff and flaskBuffs[buff] then
                raidInfo[unit].flask = flaskBuffs[buff]
                break
            end  

			-- Fodd Buffs
			
			-- Raid Buffs
        end
		
		local num = 0
		for i = 1, numGroupMembers do
			local name = GetRaidRosterInfo(i)
			if name == raidInfo[unit].name then
				num = i
				break
			end
		end
		
		local line = ReadyCheck.lines[num]
		if line then
			-- Flask
            if raidInfo[name].flask then
                line.flask:SetTexture(raidInfo[name].flask)
            else
                line.flask:SetTexture(statusTextures["notReady"])
            end
			-- Food
			if raidInfo[name].food then
				line.food:SetTexture(raidInfo[name].food)
			else
				line.food:SetTexture(statusTextures["notReady"])
			end
		end

end

local function UpdateRaidInfo(unit)
	local numRaidMembers = GetNumGroupMembers()
	if numRaidMembers > numGroupMembers then
		numGroupMembers = numGroupMembers + 1
	elseif numRaidMembers < numGroupMembers then
		numGroupMembers = numGroupMembers - 1
	end
	
		local num = 0
		for i = 1, numGroupMembers do
			local name = GetRaidRosterInfo(i)
			if name == raidInfo[unit].name then
				num = i
				break
			end
		end
		
		local online = UnitIsConnected(unit)
		local role = UnitGroupRolesAssigned(raidInfo[unit].name)
		
		-- Fill frame with data
        local line = ReadyCheck.lines[num]
        if line then
			-- Ready
            if not online then
                line.ready:SetTexture(statusTextures["notReady"])
            end
			-- Role
            line.role:SetFormattedText("%s", roleIcons[role])
			-- Name
            line.name:SetText(raidInfo[unit].name)
			-- Class / Spec
            if raidInfo[unit].spec_icon then
                line.class:SetTexture(raidInfo[unit].spec_icon)
            else
                line.class:SetTexture(classIcons[raidInfo[unit].class])
            end
        end
end

local function OnUnitAura(event, unitId)
    if ReadyCheck:IsShown() then
        UpdateRaidInfo()
    end
end

local function ResetReadyStatus()
	local numRaidMembers = GetNumGroupMembers()
	if numRaidMembers <= 10 then
		for i, line in ipairs(ReadyCheck.lines) do
				if i > numRaidMembers then
					break
				end
				line.ready:SetTexture(statusTextures["pending"])
		end
	end
end

local function OnReadyCheck(initiator, timeLeft)
	local numRaidMembers = GetNumGroupMembers()
	if numRaidMembers <= 10 then
		ResetReadyStatus()
		UpdateRaidInfo()
		for i, line in ipairs(ReadyCheck.lines) do
			if line.name and line.name:GetText() == initiator then
				line.ready:SetTexture(statusTextures["ready"])
				break
			end
		end
		ReadyCheck:Show()
		readyCheckEndTime = GetTime() + timeLeft
	end
end

local function OnReadyCheckConfirm(unit, ready)
	local numRaidMembers = GetNumGroupMembers()
	if numRaidMembers <= 10 then
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
end

local function OnReadyCheckFinished()	
	local numRaidMembers = GetNumGroupMembers()
	if numRaidMembers <= 10 then
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
end

local function OnPlayerRegenDisabled()
    if ReadyCheck:IsShown() then
        ReadyCheck:Hide()
    end
end

local function OnGroupRosterUpdate()
    if ReadyCheck:IsShown() then
        UpdateRaidInfo()
    end
end

local function OnUnitConnection(unit)
    if ReadyCheck:IsShown() then
        UpdateRaidInfo()
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

-- Fired when info changes
function ReadyCheck:UpdateHandler(event, guid, unit, info)
	if info then
		raidInfo[unit] = info
		UpdateRaidInfo(unit)
	end
end

-- Fired when member leaves party
function ReadyCheck:RemoveHandler(event, guid)
  -- guid no longer a group member
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
	elseif event == "UNIT_AURA" then
        OnUnitAura(...)
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
		UpdateRaidInfo()
        ReadyCheck:Show()
    end
end
