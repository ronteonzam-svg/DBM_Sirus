local mod = DBM:NewMod("The Twin Val'kyr", "DBM-Coliseum")
local L   = mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(34497, 34496)
mod:SetMinCombatTime(30)
mod:SetUsedIcons(1, 2, 3, 4)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)
mod:RegisterEventsInCombat(
	"SPELL_CAST_START 66046 67206 67207 67208 66058 67182 67183 67184 65875 67303 67304 67305 65876 67306 67307 67308",
	"SPELL_AURA_APPLIED 65724 67213 67214 67215 65748 67216 67217 67218 65950 67296 67297 67298 66001 67281 67282 67283 67246 65879 65916 67244 67245 67248 67249 67250 65874 67256 67257 67258 65858 67259 67260 67261"
	,
	"SPELL_AURA_REMOVED 65874 67256 67257 67258 65858 67259 67260 67261",
	"SPELL_INTERRUPT"
)

mod:SetBossHealthInfo(
	34497, L.Fjola,
	34496, L.Eydis
)

local warnSpecial         = mod:NewAnnounce("WarnSpecialSpellSoon", 3)
local warnTouchDebuff     = mod:NewAnnounce("WarningTouchDebuff", 2, 66823)
local warnPoweroftheTwins = mod:NewAnnounce("WarningPoweroftheTwins2", 4, nil, "Healer")

local specWarnSpecial           = mod:NewSpecialWarning("SpecWarnSpecial") --Change Color, No voice ideas for this
local specWarnSpecialInstruction = mod:NewSpecialWarning("SpecWarnSpecialInstruction")
local specWarnSwitch            = mod:NewSpecialWarning("SpecWarnSwitchTarget", nil, nil, nil, 1, 2, nil, nil, 65875)
local specWarnKickNow           = mod:NewSpecialWarning("SpecWarnKickNow", "HasInterrupt", nil, nil, 1, 2, nil, nil,
	65875)
local specWarnPoweroftheTwins   = mod:NewSpecialWarningDefensive(65916, "Tank", nil, 2, 1, 2)
local specWarnEmpoweredDarkness = mod:NewSpecialWarningYou(65724) --No voice ideas for this
local specWarnEmpoweredLight    = mod:NewSpecialWarningYou(65748) --No voice ideas for this

local enrageTimer     = mod:NewBerserkTimer(360)
local timerSpecial    = mod:NewTimer(45, "TimerSpecialSpell", "Interface\\Icons\\INV_Enchant_EssenceMagicLarge", nil, nil
	, 6)
local timerHeal       = mod:NewCastTimer(15, 65875, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)
local timerLightTouch = mod:NewTargetTimer(20, 65950, nil, false, 2, 3)
local timerDarkTouch  = mod:NewTargetTimer(20, 66001, nil, false, 2, 3)
--local timerAchieve    = mod:NewAchievementTimer(180, 3815)

local timerAnubRoleplay = mod:NewTimer(47.5, "TimerAnubRoleplay", 43827, nil, nil, 6)

mod:AddBoolOption("SpecialWarnOnDebuff", false, "announce")
mod:AddBoolOption("SetIconOnDebuffTarget", false)
mod:AddInfoFrameOption(nil, true)
mod.localization.options.InfoFrame = L.InfoFrameOption or mod.localization.options.InfoFrame
mod:AddBoolOption("InfoFrameSetPoint", false, "misc")
mod:AddBoolOption("HealthFrame", false)

local lightEssence, darkEssence = DBM:GetSpellInfo(65686), DBM:GetSpellInfo(65684)
local debuffTargets = {}
mod.vb.debuffIcon = 1

local updateInfoFrame

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 34497, "The Twin Val'kyr")
	self.vb.usedSpecials = {
		vortexLight = false,
		vortexDark = false,
		pactLight = false,
		pactDark = false
	}
	self.vb.activeSpecial = nil
	self.vb.lastRaidColor = L.None
	self.vb.lastCatcherColor = L.None
	if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(L.name or "Валь'киры-близнецы")
		DBM.InfoFrame:Show(7, "function", updateInfoFrame, false, false)
		if self.Options.InfoFrameSetPoint then
			local frame = _G["DBMInfoFrame"]
			if frame then
				frame:ClearAllPoints()
				frame:SetPoint("CENTER", UIParent, "CENTER", -250, -100)
			end
		end
	end
	timerSpecial:Start(-delay)
	warnSpecial:Schedule(40 - delay)
	--timerAchieve:Start(-delay)
	if self:IsHeroic() then
		enrageTimer:Start(360 - delay)
	else
		enrageTimer:Start(480 - delay)
	end
	self.vb.debuffIcon = 1
end

function mod:OnCombatEnd()
	DBM:FireCustomEvent("DBM_EncounterStart", 34497, "The Twin Val'kyr")
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
	local frame = _G["DBMInfoFrame"]
	if frame then
		frame:ClearAllPoints()
		frame:SetPoint(DBM.Options.InfoFramePoint, UIParent, DBM.Options.InfoFramePoint, DBM.Options.InfoFrameX, DBM.Options.InfoFrameY)
	end
end

function mod:ClearActiveSpecial()
	self.vb.activeSpecial = nil
end

function mod:CheckAndResetCycle()
	if self.vb.usedSpecials.vortexLight and self.vb.usedSpecials.vortexDark and self.vb.usedSpecials.pactLight and self.vb.usedSpecials.pactDark then
		self.vb.usedSpecials.vortexLight = false
		self.vb.usedSpecials.vortexDark = false
		self.vb.usedSpecials.pactLight = false
		self.vb.usedSpecials.pactDark = false
	end
end

do
	local function SpecialAbility()
		timerSpecial:Start()
		warnSpecial:Schedule(40)
	end

	function mod:SPELL_CAST_START(args)
		if args:IsSpellID(66046, 67206, 67207, 67208) then -- Light Vortex
			self.vb.usedSpecials.vortexLight = true
			self.vb.activeSpecial = "vortexLight"
			self.vb.lastRaidColor = L.Light
			self.vb.lastCatcherColor = L.Dark
			self:CheckAndResetCycle()
			specWarnSpecialInstruction:Show(L.Raid .. L.Light .. " |cffffffff/|r " .. L.Catchers .. L.Dark)
			self:UnscheduleMethod("ClearActiveSpecial")
			self:ScheduleMethod(5, "ClearActiveSpecial")
			SpecialAbility()
		elseif args:IsSpellID(66058, 67182, 67183, 67184) then -- Dark Vortex
			self.vb.usedSpecials.vortexDark = true
			self.vb.activeSpecial = "vortexDark"
			self.vb.lastRaidColor = L.Dark
			self.vb.lastCatcherColor = L.Light
			self:CheckAndResetCycle()
			specWarnSpecialInstruction:Show(L.Raid .. L.Dark .. " |cffffffff/|r " .. L.Catchers .. L.Light)
			self:UnscheduleMethod("ClearActiveSpecial")
			self:ScheduleMethod(5, "ClearActiveSpecial")
			SpecialAbility()
		elseif args:IsSpellID(65875, 67303, 67304, 67305) then -- Twin's Pact
			self.vb.usedSpecials.pactDark = true
			self.vb.activeSpecial = "pactDark"
			self.vb.lastRaidColor = L.Light
			self.vb.lastCatcherColor = L.Dark
			self:CheckAndResetCycle()
			specWarnSpecialInstruction:Show(L.Raid .. L.Light .. " |cffffffff/|r " .. L.Catchers .. L.Dark)
			timerHeal:Start()
			SpecialAbility()
			if self:GetUnitCreatureId("target") == 34497 then -- if lightbane, then switch to darkbane
				specWarnSwitch:Show()
				specWarnSwitch:Play("changetarget")
			end
		elseif args:IsSpellID(65876, 67306, 67307, 67308) then -- Light Pact
			self.vb.usedSpecials.pactLight = true
			self.vb.activeSpecial = "pactLight"
			self.vb.lastRaidColor = L.Dark
			self.vb.lastCatcherColor = L.Light
			self:CheckAndResetCycle()
			specWarnSpecialInstruction:Show(L.Raid .. L.Dark .. " |cffffffff/|r " .. L.Catchers .. L.Light)
			timerHeal:Start()
			SpecialAbility()
			if self:GetUnitCreatureId("target") == 34496 then -- if darkbane, then switch to lightbane
				specWarnSwitch:Show()
				specWarnSwitch:Play("changetarget")
			end
		end
	end
end

do
	local function resetDebuff(self)
		self.vb.debuffIcon = 1
	end

	local function warnDebuff(self)
		warnTouchDebuff:Show(table.concat(debuffTargets, "<, >"))
		table.wipe(debuffTargets)
		self:Unschedule(resetDebuff)
		self:Schedule(5, resetDebuff, self)
	end

	local function showPowerWarning(self, cid)
		local target = self:GetBossTarget(cid)
		if not target then return end
		if target == UnitName("player") then
			specWarnPoweroftheTwins:Show()
		else
			warnPoweroftheTwins:Show(target)
		end
	end

	local shieldValues = {
		[65874] = 175000,
		[65858] = 175000,
		[67257] = 300000,
		[67260] = 300000,
		[67256] = 700000,
		[67259] = 700000,
		[67261] = 1200000,
		[67258] = 1200000,
	}
	local showShieldHealthBar, hideShieldHealthBar, shieldedBoss
	local frame = CreateFrame("Frame") -- using a separate frame avoids the overhead of the DBM event handlers which are not meant to be used with frequently occuring events like all damage events...
	local shieldedMob
	local absorbRemaining = 0
	local maxAbsorb = 0

	local twipe = table.wipe
	local lines, sortedLines = {}, {}
	local function addLine(key, value)
		-- sort by insertion order
		lines[key] = value
		sortedLines[#sortedLines + 1] = key
	end

	local function getShieldHP()
		return math.max(1, math.floor(absorbRemaining / maxAbsorb * 100))
	end

	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:SetScript("OnEvent", function(self, _, _, subEvent, _, _, _, destGUID, _, _, ...)
		if shieldedMob == destGUID then
			local absorbed
			if subEvent == "SWING_MISSED" then
				absorbed = select(2, ...)
			elseif subEvent == "RANGE_MISSED" or subEvent == "SPELL_MISSED" or subEvent == "SPELL_PERIODIC_MISSED" then
				absorbed = select(5, ...)
			end
			if absorbed then
				absorbRemaining = absorbRemaining - absorbed
			end
		end
	end)

	function showShieldHealthBar(self, mob, shieldName, absorb)
		shieldedMob = mob
		absorbRemaining = absorb
		maxAbsorb = absorb
		DBM.BossHealth:RemoveBoss(getShieldHP)
		DBM.BossHealth:AddBoss(getShieldHP, shieldName)
		self:Schedule(15, hideShieldHealthBar)
	end

	function hideShieldHealthBar()
		DBM.BossHealth:RemoveBoss(getShieldHP)
	end

	function updateInfoFrame()
		twipe(lines)
		twipe(sortedLines)
		if not mod.vb.usedSpecials then
			return lines, sortedLines
		end
		
		local raidLine = L.Raid .. (mod.vb.lastRaidColor or L.None)
		addLine(raidLine, "")
		
		local catcherLine = L.Catchers .. (mod.vb.lastCatcherColor or L.None)
		addLine(catcherLine, "")
		
		addLine(" ", "")
		
		local function addAbilityLine(displayName, isUsed, isDarkColor, isActiveShield, isShield)
			local leftText
			local rightText = ""
			if isActiveShield and shieldedBoss then
				local colorHex = isDarkColor and "9932CD" or "FFCC00"
				local percent = getShieldHP()
				local percentColor
				if percent > 70 then
					percentColor = "00FF00" -- Green
				elseif percent > 30 then
					percentColor = "FFFF00" -- Yellow
				else
					percentColor = "FF0000" -- Red
				end
				leftText = "|cff" .. colorHex .. displayName .. "|r: |cff" .. percentColor .. percent .. "%|r"
			elseif isUsed then
				if isShield then
					leftText = "|cff808080" .. displayName .. ": 0%|r"
				else
					leftText = "|cff808080" .. displayName .. "|r"
				end
			else
				local colorHex = isDarkColor and "9932CD" or "FFCC00"
				leftText = "|cff" .. colorHex .. displayName .. "|r"
			end
			addLine(leftText, rightText)
		end
		addAbilityLine(L.VortexLight, mod.vb.usedSpecials.vortexLight, false, false, false)
		addAbilityLine(L.VortexDark, mod.vb.usedSpecials.vortexDark, true, false, false)
		addAbilityLine(L.PactLight, mod.vb.usedSpecials.pactLight, true, mod.vb.activeSpecial == "pactLight", true)
		addAbilityLine(L.PactDark, mod.vb.usedSpecials.pactDark, false, mod.vb.activeSpecial == "pactDark", true)
		return lines, sortedLines
	end

	--[[
	function mod:SetTestAbsorb(amount, isPercent)
		if isPercent then
			if maxAbsorb == 0 then
				maxAbsorb = 100000
			end
			absorbRemaining = maxAbsorb * (amount / 100)
		else
			absorbRemaining = amount
		end
	end
	--]]

	function mod:SPELL_AURA_APPLIED(args)
		if args:IsPlayer() and args:IsSpellID(65724, 67213, 67214, 67215) then -- Empowered Darkness
			specWarnEmpoweredDarkness:Show()
		elseif args:IsPlayer() and args:IsSpellID(65748, 67216, 67217, 67218) then -- Empowered Light
			specWarnEmpoweredLight:Show()
		elseif args:IsSpellID(65950, 67296, 67297, 67298) then -- Touch of Light
			if args:IsPlayer() and self.Options.SpecialWarnOnDebuff then
				specWarnSpecial:Show()
			end
			timerLightTouch:Start(args.destName)
			if self.Options.SetIconOnDebuffTarget then
				self:SetIcon(args.destName, self.vb.debuffIcon, 15)
			end
			self.vb.debuffIcon = self.vb.debuffIcon + 1
			debuffTargets[#debuffTargets + 1] = args.destName
			self:Unschedule(warnDebuff)
			self:Schedule(0.9, warnDebuff, self)
		elseif args:IsSpellID(66001, 67281, 67282, 67283) then -- Touch of Darkness
			if args:IsPlayer() and self.Options.SpecialWarnOnDebuff then
				specWarnSpecial:Show()
			end
			timerDarkTouch:Start(args.destName)
			if self.Options.SetIconOnDebuffTarget then
				self:SetIcon(args.destName, self.vb.debuffIcon)
			end
			self.vb.debuffIcon = self.vb.debuffIcon - 1
			debuffTargets[#debuffTargets + 1] = args.destName
			self:Unschedule(warnDebuff)
			self:Schedule(0.75, warnDebuff, self)
		elseif args:IsSpellID(67246, 65879, 65916, 67244) or args:IsSpellID(67245, 67248, 67249, 67250) then -- Power of the Twins
			self:Schedule(0.1, showPowerWarning, self, args:GetDestCreatureID())
		elseif args:IsSpellID(65874, 67256, 67257, 67258) then -- Shield of Darkness
			shieldedBoss = args.destName
			showShieldHealthBar(self, args.destGUID, args.spellName, shieldValues[args.spellId] or 0)
			if self.vb.activeSpecial ~= "pactDark" then
				self.vb.activeSpecial = "pactDark"
				self.vb.usedSpecials.pactDark = true
				self:CheckAndResetCycle()
			end
		elseif args:IsSpellID(65858, 67259, 67260, 67261) then -- Shield of Lights
			shieldedBoss = args.destName
			showShieldHealthBar(self, args.destGUID, args.spellName, shieldValues[args.spellId] or 0)
			if self.vb.activeSpecial ~= "pactLight" then
				self.vb.activeSpecial = "pactLight"
				self.vb.usedSpecials.pactLight = true
				self:CheckAndResetCycle()
			end
		end
	end

	function mod:SPELL_AURA_REMOVED(args)
		if args:IsSpellID(65874, 67256, 67257, 67258) or args:IsSpellID(65858, 67259, 67260, 67261) then -- Shield of Darkness/Lights
			shieldedBoss = nil
			specWarnKickNow:Show()
			specWarnKickNow:Play("kickcast")
			self.vb.activeSpecial = nil
			hideShieldHealthBar()
		elseif args:IsSpellID(65950, 67296, 67297, 67298) then -- Touch of Light
			timerLightTouch:Stop(args.destName)
			if self.Options.SetIconOnDebuffTarget then
				self:RemoveIcon(args.destName)
			end
		elseif args:IsSpellID(66001, 67281, 67282, 67283) then -- Touch of Darkness
			timerDarkTouch:Stop(args.destName)
			if self.Options.SetIconOnDebuffTarget then
				self:RemoveIcon(args.destName)
			end
		end
	end
end

function mod:SPELL_INTERRUPT(args)
	if type(args.extraSpellId) == "number" and
		(
		args.extraSpellId == 65875 or args.extraSpellId == 67303 or args.extraSpellId == 67304 or args.extraSpellId == 67305 or
			args.extraSpellId == 65876 or args.extraSpellId == 67306 or args.extraSpellId == 67307 or args.extraSpellId == 67308) then
		timerHeal:Cancel()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.AnubRP or msg:find(L.AnubRP) then
		timerAnubRoleplay:Start()
	end
end
