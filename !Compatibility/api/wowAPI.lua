--Cache global variables
local _G = _G
local assert = assert
local date = date
local pairs = pairs
local tonumber = tonumber
local type = type
local unpack = unpack
local format, gsub, lower, match, upper = string.format, string.gsub, string.lower, string.match, string.upper
local getn = table.getn
--WoW API
local GetQuestGreenRange = GetQuestGreenRange
local GetRealZoneText = GetRealZoneText
local IsInInstance = IsInInstance
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local UnitLevel = UnitLevel
--WoW Variables
local DUNGEON_DIFFICULTY1 = DUNGEON_DIFFICULTY1
local TIMEMANAGER_AM = gsub(TIME_TWELVEHOURAM, "^.-(%w+)$", "%1")
local TIMEMANAGER_PM = gsub(TIME_TWELVEHOURPM, "^.-(%w+)$", "%1")
--Libs
local LBC = LibStub("LibBabble-Class-3.0"):GetLookupTable()
local LBZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()

CLASS_SORT_ORDER = {
	"WARRIOR",
	"PALADIN",
	"PRIEST",
	"SHAMAN",
	"DRUID",
	"ROGUE",
	"MAGE",
	"WARLOCK",
	"HUNTER"
}
MAX_CLASSES = getn(CLASS_SORT_ORDER)

LOCALIZED_CLASS_NAMES_MALE = {}
LOCALIZED_CLASS_NAMES_FEMALE = {}

CLASS_ICON_TCOORDS = {
	["WARRIOR"] = {0, 0.25, 0, 0.25},
	["MAGE"] = {0.25, 0.49609375, 0, 0.25},
	["ROGUE"] = {0.49609375, 0.7421875, 0, 0.25},
	["DRUID"] = {0.7421875, 0.98828125, 0, 0.25},
	["HUNTER"] = {0, 0.25, 0.25, 0.5},
	["SHAMAN"] = {0.25, 0.49609375, 0.25, 0.5},
	["PRIEST"] = {0.49609375, 0.7421875, 0.25, 0.5},
	["WARLOCK"] = {0.7421875, 0.98828125, 0.25, 0.5},
	["PALADIN"] = {0, 0.25, 0.5, 0.75}
}

QuestDifficultyColors = {
	["impossible"] = {r = 1.00, g = 0.10, b = 0.10},
	["verydifficult"] = {r = 1.00, g = 0.50, b = 0.25},
	["difficult"] = {r = 1.00, g = 1.00, b = 0.00},
	["standard"] = {r = 0.25, g = 0.75, b = 0.25},
	["trivial"] = {r = 0.50, g = 0.50, b = 0.50},
	["header"] = {r = 0.70, g = 0.70, b = 0.70}
}

function HookScript(frame, scriptType, handler)
	assert(type(frame) == "table" and frame.GetScript and type(scriptType) == "string" and type(handler) == "function", "Usage: HookScript(frame, \"type\", function)")

	local original_scipt = frame:GetScript(scriptType)
	if original_scipt then
		frame:SetScript(scriptType, function(...)
			local original_return = {original_scipt(unpack(arg))}
			handler(unpack(arg))

			return unpack(original_return)
		end)
	else
		frame:SetScript(scriptType, handler)
	end
end

function hooksecurefunc(arg1, arg2, arg3)
	local isMethod = type(arg1) == "table" and type(arg2) == "string" and type(arg1[arg2]) == "function" and type(arg3) == "function"
	assert(isMethod or (type(arg1) == "string" and type(_G[arg1]) == "function" and type(arg2) == "function"), "Usage: hooksecurefunc([table,] \"functionName\", hookfunc)")

	if not isMethod then
		arg1, arg2, arg3 = _G, arg1, arg2
	end

	local original_func = arg1[arg2]

	arg1[arg2] = function(...)
		local original_return = {original_func(unpack(arg))}
		arg3(unpack(arg))

		return unpack(original_return)
	end
end

--[[	issecurevariable([table], variable)
	Returns 1, nil for undefined variables. This is because an undefined variable is secure since you have not tainted it.
	Returns 1, nil for all untainted variables (i.e. Blizzard variables).
	Returns nil for any global variable that is hooked insecurely (tainted), even unprotected ones like UnitName().
	Returns nil for all user defined global variables.
	If a table is passed first, it checks table.variable (e.g. issecurevariable(PlayerFrame, "Show") checks PlayerFrame["Show"] or PlayerFrame.Show (they are the same thing)).
]]
function issecurevariable(t, var)
--	assert(type(t) == "table" and type(var) == "string", "Usage: issecurevariable([table,] \"variable\")")
	return
end

function tContains(table, item)
	local index = 1

	while table[index] do
		if item == table[index] then
			return 1
		end
		index = index + 1
	end

	return
end

function UnitAura(unit, i, filter)
	assert((type(unit) == "string" or type(unit) == "number") and (type(i) == "string" or type(i) == "number"), "Usage: UnitAura(\"unit\", index [, filter])")

	if not filter or match(filter, "(HELPFUL)") then
		local name, rank, aura, count, duration, maxDuration = UnitBuff(unit, i, filter)
		return name, rank, aura, count, nil, duration or 0, maxDuration or 0
	else
		local name, rank, aura, count, dType, duration, maxDuration = UnitDebuff(unit, i, filter)
		return name, rank, aura, count, dType, duration or 0, maxDuration or 0
	end
end

function BetterDate(formatString, timeVal)
	local dateTable = date("*t", timeVal)
	local amString = (dateTable.hour >= 12) and "PM" or "AM"

	--First, we'll replace %p with the appropriate AM or PM.
	formatString = gsub(formatString, "^%%p", amString)	--Replaces %p at the beginning of the string with the am/pm token
	formatString = gsub(formatString, "([^%%])%%p", "%1"..amString) -- Replaces %p anywhere else in the string, but doesn't replace %%p (since the first % escapes the second)

	return date(formatString, timeVal)
end

function GetQuestDifficultyColor(level)
	local levelDiff = level - UnitLevel("player")
	if levelDiff >= 5 then
		return QuestDifficultyColors["impossible"]
	elseif levelDiff >= 3 then
		return QuestDifficultyColors["verydifficult"]
	elseif levelDiff >= -2 then
		return QuestDifficultyColors["difficult"]
	elseif -levelDiff <= GetQuestGreenRange() then
		return QuestDifficultyColors["standard"]
	else
		return QuestDifficultyColors["trivial"]
	end
end

function FillLocalizedClassList(tab, female)
	assert(type(tab) == "table", "Usage: FillLocalizedClassList(classTable[, isFemale])")

	for _, engClass in ipairs(CLASS_SORT_ORDER) do
		if female then
			tab[engClass] = LBC[engClass]
		else
			tab[engClass] = LBC[gsub(lower(engClass), "^%l", upper)]
		end
	end

	return true
end

FillLocalizedClassList(LOCALIZED_CLASS_NAMES_MALE)
FillLocalizedClassList(LOCALIZED_CLASS_NAMES_FEMALE, true)

local zoneInfo = {
	-- Battlegrounds
	[LBZ["Warsong Gulch"]] = {mapID = 443, maxPlayers = 10},
	[LBZ["Arathi Basin"]] = {mapID = 461, maxPlayers = 15},
	[LBZ["Alterac Valley"]] = {mapID = 401, maxPlayers = 40},

	-- Raids
	[LBZ["Zul'Gurub"]] = {mapID = 309, maxPlayers = 20},
	[LBZ["Onyxia's Lair"]] = {mapID = 249, maxPlayers = 40},
	[LBZ["Molten Core"]] = {mapID = 409, maxPlayers = 40},
	[LBZ["Ruins of Ahn'Qiraj"]] = {mapID = 509, maxPlayers = 20},
	[LBZ["Temple of Ahn'Qiraj"]] = {mapID = 531, maxPlayers = 40},
	[LBZ["Blackwing Lair"]] = {mapID = 469, maxPlayers = 40},
	[LBZ["Naxxramas"]] = {mapID = 533, maxPlayers = 40},
}

local mapByID = {}
for mapName in pairs(zoneInfo) do
	mapByID[zoneInfo[mapName].mapID] = mapName
end

local function GetMaxPlayersByType(instanceType, zoneName)
	if instanceType == "none" then
		return 40
	elseif instanceType == "party" then
		return 5
	elseif instanceType == "arena" then
		return 5
	elseif zoneName ~= "" and zoneInfo[zoneName] then
		if instanceType == "pvp" then
			return zoneInfo[zoneName].maxPlayers
		elseif instanceType == "raid" then
			return zoneInfo[zoneName].maxPlayers
		end
	else
		return 0
	end
end

function GetInstanceInfo()
	local inInstance, instanceType = IsInInstance()
	if not inInstance then return end

	local name = GetRealZoneText()

	local difficulty = 1
	local difficultyName = DUNGEON_DIFFICULTY1
	local maxPlayers = GetMaxPlayersByType(instanceType, name)

	difficultyName = format("%d %s", maxPlayers, difficultyName)

	return name, instanceType, difficulty, difficultyName, maxPlayers
end

function GetCurrentMapAreaID()
	if not IsInInstance() then return end
	local zoneName = GetRealZoneText()

	if zoneName ~= "" and zoneInfo[zoneName] then
		return zoneInfo[zoneName].mapID
	else
		return 0
	end
end

function GetMapNameByID(id)
	assert(type(id) == "string" or type(id) == "number", format("Bad argument #1 to \"GetMapNameByID\" (number expected, got %s)", id and type(id) or "no value"))

	return mapByID[tonumber(id)]
end

local arrow
function GetPlayerFacing()
	if not arrow then
		local obj = Minimap
		for i = 1, obj:GetNumChildren() do
			local child = select(i, obj:GetChildren())
			if child and child.GetModel and child:GetModel() == "interface\\minimap\\minimaparrow.m2" then
				arrow = child
				break
			end
		end
	end

	return arrow and arrow:GetFacing()
end

function ToggleFrame(frame)
	if frame:IsShown() then
		HideUIPanel(frame)
	else
		ShowUIPanel(frame)
	end
end

local function OnOrientationChanged(self, orientation)
	self.texturePointer.verticalOrientation = orientation == "VERTICAL"

	if self.texturePointer.verticalOrientation then
		self.texturePointer:SetPoint("BOTTOMLEFT", self)
	else
		self.texturePointer:SetPoint("LEFT", self)
	end
end

local function OnSizeChanged(self, width, height)
	self.texturePointer.width = width
	self.texturePointer.height = height
	self.texturePointer:SetWidth(width)
	self.texturePointer:SetHeight(height)
end

local function OnValueChanged(self, value)
	local _, max = self:GetMinMaxValues()

	if self.texturePointer.verticalOrientation then
		self.texturePointer:SetHeight(self.texturePointer.height * (value / max))
	else
		self.texturePointer:SetWidth(self.texturePointer.width * (value / max))
	end
end

function CreateStatusBarTexturePointer(statusbar)
	assert(type(statusbar) == "table", format("Bad argument #1 to \"CreateStatusBarTexturePointer\" (table expected, got %s)", statusbar and type(statusbar) or "no value"))
	assert(statusbar.GetObjectType and statusbar:GetObjectType() == "StatusBar", "Bad argument #1 to \"CreateStatusBarTexturePointer\" (statusbar object expected)")

	local f = statusbar:CreateTexture()
	f.width = statusbar:GetWidth()
	f.height = statusbar:GetHeight()
	f.vertical = statusbar:GetOrientation() == "VERTICAL"
	f:SetWidth(f.width)
	f:SetHeight(f.height)

	if f.verticalOrientation then
		f:SetPoint("BOTTOMLEFT", statusbar)
	else
		f:SetPoint("LEFT", statusbar)
	end

	statusbar.texturePointer = f

	statusbar:SetScript("OnSizeChanged", OnSizeChanged)
	statusbar:SetScript("OnValueChanged", OnValueChanged)

	hooksecurefunc(statusbar, "SetOrientation", OnOrientationChanged)

	return f
end

local threatColors = {
	[0] = {0.69, 0.69, 0.69},
	[1] = {1, 1, 0.47},
	[2] = {1, 0.6, 0},
	[3] = {1, 0, 0}
}

function GetThreatStatusColor(statusIndex)
	if not (type(statusIndex) == "number" and statusIndex >= 0 and statusIndex < 4) then
		statusIndex = 0
	end

	return threatColors[statusIndex][1], threatColors[statusIndex][2], threatColors[statusIndex][3]
end

function GetThreatStatus(currentThreat, maxThreat)
	assert(type(currentThreat) == "number" and type(maxThreat) == "number", "Usage: GetThreatStatus(currentThreat, maxThreat)")

	if not maxThreat or maxThreat == 0 then
		maxThreat = 0
		maxThreat = 1
	end

	local threatPercent = currentThreat / maxThreat * 100

	if threatPercent >= 100 then
		return 3, threatPercent
	elseif threatPercent < 100 and threatPercent >= 80 then
		return 2, threatPercent
	elseif threatPercent < 80 and threatPercent >= 50 then
		return 1, threatPercent
	else
		return 0, threatPercent
	end
end