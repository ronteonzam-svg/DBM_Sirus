local mod = DBM:NewMod("Jaraxxus", "DBM-Coliseum")
local L   = mod:GetLocalizedStrings()

local CL  = DBM_COMMON_L

mod:SetRevision("20260219000000")
mod:SetMinSyncRevision(7007)
mod:SetCreatureID(34780)
mod:SetMinCombatTime(30)
mod:SetUsedIcons(7, 8)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 66532 66963 66964 66965",
	"SPELL_CAST_SUCCESS 66228 67106 67107 67108 67901 67902 67903 66258 66269 67898 67899 67900 66263 66264 67103 67104 67105 68404 68405 68406 66197 68123 68124 68125",
	"SPELL_AURA_APPLIED 67051 67050 67049 66237 66197 68123 68124 68125 66334 67905 67906 67907 66532 66963 66964 66965 66228 67106 67107 67108",
	"SPELL_AURA_APPLIED_DOSE 66228 67106 67107 67108",
	"SPELL_AURA_REMOVED_DOSE 66228 67106 67107 67108",
	"SPELL_AURA_REMOVED 67051 67050 67049 66237",
	"SPELL_DAMAGE 66877 67070 67071 67072 66496 68716 68717 68718",
	"SPELL_MISSED 66877 67070 67071 67072 66496 68716 68717 68718",
	"SPELL_HEAL",
	"SPELL_PERIODIC_HEAL"
)


local warnPortalSoon            = mod:NewSoonAnnounce(66269, 3)
local warnVolcanoSoon           = mod:NewSoonAnnounce(66258, 3)
local warnFlame                 = mod:NewTargetAnnounce(66197, 4)
local warnFlesh                 = mod:NewTargetNoFilterAnnounce(66237, 4, nil, "Healer")

local specWarnFlame             = mod:NewSpecialWarningRun(66877, nil, nil, 2, 4, 2)
local specWarnFlameGTFO         = mod:NewSpecialWarningMove(66877, nil, nil, 2, 4, 2)
local specWarnFlesh             = mod:NewSpecialWarningYou(66237, nil, nil, nil, 1, 2)
local specWarnKiss              = mod:NewSpecialWarningCast(66334, "SpellCaster", nil, 2, 1, 2)
local specWarnFelInferno        = mod:NewSpecialWarningMove(66496, nil, nil, nil, 1, 2)
local SpecWarnFelFireball       = mod:NewSpecialWarningInterrupt(66532, "HasInterrupt", nil, 2, 1, 2)
local SpecWarnFelFireballDispel = mod:NewSpecialWarningDispel(66532, "RemoveMagic", nil, 2, 1, 2)

local specWarnNetherPower       = mod:NewSpecialWarningCount(67009, nil, nil, nil, 1, 2)

local timerCombatStart          = mod:NewCombatTimer(20)                         --roleplay for first pull 34
local timerFlame                = mod:NewTargetTimer(8, 66197, nil, nil, nil, 3)
local timerFlameCD              = mod:NewCDTimer(30, 66197, nil, nil, nil, 3)
local timerNetherPowerCD        = mod:NewCDTimer(42.5, 67009, nil, nil, nil, 5, nil, CL.MAGIC_ICON)
local timerFlesh                = mod:NewTargetTimer(12, 66237, nil, "Healer", 2, 5, nil, CL.HEALER_ICON)
local timerFleshCD              = mod:NewCDTimer(23, 66237, nil, "Healer", 2, 5, nil, CL.HEALER_ICON)
local timerPortalCD             = mod:NewCDTimer(120, 66269, nil, nil, nil, 1)
local timerVolcanoCD            = mod:NewCDTimer(120, 66258, nil, nil, nil, 1)

local enrageTimer               = mod:NewBerserkTimer(600)

mod:AddSetIconOption("LegionFlameIcon", 66197, true, 0, { 7 })
mod:AddSetIconOption("IncinerateFleshIcon", 66237, true, 0, { 8 })
mod:AddInfoFrameOption(66237, true)
mod:RemoveOption("HealthFrame")
mod:AddBoolOption("IncinerateShieldFrame", false, "misc")

mod.vb.fleshCount = 0
mod.vb.netherPowerStacks = 0
local incinerateFleshTargetName

local function PortalLoop(self)
	if self:IsInCombat() then
		timerPortalCD:Start(120)
		warnPortalSoon:Schedule(115)
		self:Schedule(120, PortalLoop, self)
	end
end

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 34780, "Lord Jaraxxus")
	if self.Options.IncinerateShieldFrame then
		DBM.BossHealth:Show(L.name)
		DBM.BossHealth:AddBoss(34780, L.name)
	end
	self.vb.fleshCount = 0
	self.vb.netherPowerStacks = 0
	self.vb.netherPowerPlayVoice = false
	timerPortalCD:Start(20 - delay)
	warnPortalSoon:Schedule(15 - delay)
	self:Schedule(20 - delay, PortalLoop, self)
	timerVolcanoCD:Start(82 - delay)
	warnVolcanoSoon:Schedule(77 - delay)
	timerNetherPowerCD:Start(15 - delay)
	timerFleshCD:Start(14 - delay)
	timerFlameCD:Start(20 - delay)
	enrageTimer:Start(-delay)
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 34780, "Lord Jaraxxus", wipe)
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
	DBM.BossHealth:Clear()
	self:Unschedule(PortalLoop)
end

local setIncinerateTarget, clearIncinerateTarget, updateInfoFrame
local diffMaxAbsorb = { heroic25 = 85000, heroic10 = 40000, normal25 = 60000, normal10 = 30000 }
do
	local incinerateTarget
	local healed = 0
	local maxAbsorb = diffMaxAbsorb[DBM:GetCurrentInstanceDifficulty()] or 0

	local twipe = table.wipe
	local lines, sortedLines = {}, {}
	local function addLine(key, value)
		lines[key] = value
		sortedLines[#sortedLines + 1] = key
	end

	local function getShieldHP()
		return math.max(1, math.floor(healed / maxAbsorb * 100))
	end

	function mod:SPELL_HEAL(_, _, _, destGUID, _, _, _, _, _, _, _, absorbed)
		if destGUID == incinerateTarget then
			healed = healed + (absorbed or 0)
		end
	end

	mod.SPELL_PERIODIC_HEAL = mod.SPELL_HEAL

	function setIncinerateTarget(_, target, name)
		incinerateTarget = target
		healed = 0
		DBM.BossHealth:RemoveBoss(getShieldHP)
		DBM.BossHealth:AddBoss(getShieldHP, L.IncinerateTarget:format(name))
	end

	function clearIncinerateTarget(self, name)
		DBM.BossHealth:RemoveBoss(getShieldHP)
		healed = 0
		if self.Options.IncinerateFleshIcon then
			self:RemoveIcon(name)
		end
	end

	updateInfoFrame = function()
		twipe(lines)
		twipe(sortedLines)
		if incinerateFleshTargetName then
			addLine(incinerateFleshTargetName, getShieldHP() .. "%")
		end
		return lines, sortedLines
	end
end

local function warnNetherPower(self)
	specWarnNetherPower:Show(self.vb.netherPowerStacks)
	if self.vb.netherPowerPlayVoice and self.vb.netherPowerStacks > 0 then
		specWarnNetherPower:Play("dispelboss")
	end
	self.vb.netherPowerPlayVoice = false
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(66532, 66963, 66964, 66965) and self:CheckInterruptFilter(args.sourceGUID, false, true) then -- Fel Fireball (track cast for interupt, only when targeted)
		SpecWarnFelFireball:Show(args.sourceName)
		SpecWarnFelFireball:Play("kickcast")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(66228, 67106, 67107, 67108) then -- Nether Power
		timerNetherPowerCD:Start()
	elseif args:IsSpellID(67901, 67902, 67903, 66258) then -- Infernal Volcano
		timerVolcanoCD:Start()
		warnVolcanoSoon:Schedule(110)
	--elseif args:IsSpellID(66263, 66264, 66269, 67103, 67104, 67105, 67898, 67899, 67900, 68404, 68405, 68406) then -- Nether Portal
	--	timerPortalCD:Start()
	--	warnPortalSoon:Schedule(110)
	--	print("|cff00ff00[DBM Debug]|r Врата пустоты сработали! ID заклинания: " .. tostring(args.spellId))
	elseif args:IsSpellID(66197, 68123, 68124, 68125) then -- Legion Flame
		warnFlame:Show(args.destName)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(67051, 67050, 67049, 66237) then -- Incinerate Flesh
		self.vb.fleshCount = self.vb.fleshCount + 1
		timerFlesh:Start(args.destName)
		timerFleshCD:Start()
		if self.Options.IncinerateFleshIcon then
			self:SetIcon(args.destName, 8, 15)
		end
		if args:IsPlayer() then
			specWarnFlesh:Show()
			specWarnFlesh:Play("targetyou")
		else
			warnFlesh:Show(args.destName)
		end
		if self.Options.InfoFrame and not DBM.InfoFrame:IsShown() then
			incinerateFleshTargetName = args.destName
			DBM.InfoFrame:SetHeader(args.spellName)
			DBM.InfoFrame:Show(6, "function", updateInfoFrame, false, true)
		end
		setIncinerateTarget(self, args.destGUID, args.destName)
	elseif args:IsSpellID(66197, 68123, 68124, 68125) then -- Legion Flame ids 66199, 68126, 68127, 68128 (second debuff) do the actual damage. First 2 seconds are trigger debuff only.
		timerFlame:Start(args.destName)
		timerFlameCD:Start()
		if args:IsPlayer() then
			specWarnFlame:Show()
			specWarnFlame:Play("runout")
			specWarnFlame:ScheduleVoice(1.5, "keepmove")
		end
		if self.Options.LegionFlameIcon then
			self:SetIcon(args.destName, 7, 8)
		end
	elseif args:IsSpellID(66334, 67905, 67906, 67907) and args:IsPlayer() then
		specWarnKiss:Show()
		specWarnKiss:Play("stopcast")
	elseif args:IsSpellID(66532, 66963, 66964, 66965) then -- Fel Fireball (announce if tank gets debuff for dispel)
		SpecWarnFelFireballDispel:Show(args.destName)
		SpecWarnFelFireballDispel:Play("helpdispel")
	elseif args:IsSpellID(66228, 67106, 67107, 67108) then
		local diff = DBM:GetCurrentInstanceDifficulty()
		local stacks = (diff == "heroic25" or diff == "normal25") and 10 or 5
		self.vb.netherPowerStacks = args.amount or stacks
		self.vb.netherPowerPlayVoice = true
		self:Unschedule(warnNetherPower)
		self:Schedule(0.15, warnNetherPower, self)
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpellID(66228, 67106, 67107, 67108) then
		self.vb.netherPowerStacks = args.amount or 1
		self.vb.netherPowerPlayVoice = true
		self:Unschedule(warnNetherPower)
		self:Schedule(0.15, warnNetherPower, self)
	end
end

function mod:SPELL_AURA_REMOVED_DOSE(args)
	if args:IsSpellID(66228, 67106, 67107, 67108) then
		local amount = args.amount or 0
		if not self.vb.netherPowerStacks or amount < self.vb.netherPowerStacks then
			self.vb.netherPowerStacks = amount
			self:Unschedule(warnNetherPower)
			self:Schedule(0.15, warnNetherPower, self)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(67051, 67050, 67049, 66237) then -- Incinerate Flesh
		self.vb.fleshCount = self.vb.fleshCount - 1
		if self.Options.InfoFrame and self.vb.fleshCount == 0 then
			DBM.InfoFrame:Hide()
		end
		timerFlesh:Stop(args.destName)
		if self.Options.IncinerateFleshIcon then
			self:RemoveIcon(args.destName)
		end
		clearIncinerateTarget(self, args.destName)
	elseif args:IsSpellID(66228, 67106, 67107, 67108) then
		self.vb.netherPowerStacks = 0
		self:Unschedule(warnNetherPower)
		self:Schedule(0.15, warnNetherPower, self)
	end
end

function mod:SPELL_DAMAGE(_, _, _, destGUID, _, _, spellId)
	if (spellId == 66877 or spellId == 67070 or spellId == 67071 or spellId == 67072) and destGUID == UnitGUID("player") and
		self:AntiSpam(3, 1) then -- Legion Flame
		specWarnFlameGTFO:Show()
		specWarnFlameGTFO:Play("runaway")
	elseif (spellId == 66496 or spellId == 68716 or spellId == 68717 or spellId == 68718) and destGUID == UnitGUID("player")
		and self:AntiSpam(3, 1) then -- Fel Inferno
		specWarnFelInferno:Show()
		specWarnFelInferno:Play("runaway")
	end
end

mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Pull20 or msg:find(L.Pull20) then
		timerCombatStart:Start()
	end
end
