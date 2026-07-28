local mod = DBM:NewMod("Zluker", "DBM-Karazhan")
local L   = mod:GetLocalizedStrings()

mod:SetRevision("20260728030400")
mod:SetCreatureID(10055, 100552, 100555)
mod:RegisterCombat("yell", L.YellZluker)
mod:SetUsedIcons(8)

mod:RegisterEvents(
	"SPELL_CAST_START 305535 305537",
	"SPELL_CAST_SUCCESS 305537 305540",
	"SPELL_SUMMON 305537",
	"SPELL_CAST_FAILED 305537",
	"CHAT_MSG_MONSTER_YELL"
)

local timerMagicCD     = mod:NewCDTimer(46, 305535)
local timerMagicCast   = mod:NewCastTimer(5, 305535, nil, nil, nil, 2)
local timerSummonCD    = mod:NewCDTimer(73, 305540)
local timerCombatStart = mod:NewCombatTimer(80)

-- Prominent special warnings in the center of the screen
local specWarnGravityDefianceYou       = mod:NewSpecialWarningRun(305537, nil, "SpecWarn305537run", nil, 4, 2)
local specWarnGravityDefianceTargetYou = mod:NewSpecialWarning("SpecWarnGravityDefianceTargetYou", nil, nil, nil, 1, 2, nil, 305537, 305537)
local warnGravityDefiance              = mod:NewTargetAnnounce(305537, 3, nil, true, "warnGravityDefiance")
local specWarnMagicCast                = mod:NewSpecialWarning("SpecWarnMagicCast", nil, nil, nil, 3, 2, nil, 305535, 305535)

mod:AddSetIconOption("SetIconOnGravityTarget", 305537, true, 0, { 8 })

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if L.YellBarnes and msg:find(L.YellBarnes, 1, true) then
		self.isLongRP = false
		self.timerStarted = false
	elseif L.YellMonkey and msg:find(L.YellMonkey, 1, true) then
		if not self.timerStarted then
			self.isLongRP = true
			self.timerStarted = true
			timerCombatStart:Start(73)
		end
	elseif L.YellGalindra and msg:find(L.YellGalindra, 1, true) then
		if not self.timerStarted and not self.isLongRP then
			self.timerStarted = true
			timerCombatStart:Start(17)
		end
	end
end

function mod:OnCombatStart()
	timerCombatStart:Stop()
	timerMagicCD:Start(46)
	timerSummonCD:Start(72)
	self.gravityTargetName = nil
	self.isLongRP = nil
	self.timerStarted = nil
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(305535) then
		timerMagicCD:Start()
		timerMagicCast:Start()
		specWarnMagicCast:Show()
		specWarnMagicCast:Play("jump")
	elseif args:IsSpellID(305537) then
		self:ScheduleMethod(0.05, "CheckGravityTarget", args.sourceGUID)
	end
end

function mod:CheckGravityTarget(sourceGUID)
	local targetname, targetuid = self:GetBossTarget(sourceGUID)
	if not targetname then return end
	if targetuid and self:IsTanking(targetuid) then
		return
	end
	self:GravityTarget(targetname)
end

function mod:GravityTarget(targetname)
	if not targetname then return end
	if targetname == UnitName("player") then
		if self:IsMelee() and not self:IsHealer() then
			specWarnGravityDefianceYou:Show()
		else
			specWarnGravityDefianceTargetYou:Show()
		end
	else
		warnGravityDefiance:Show(targetname)
	end
	if self.Options.SetIconOnGravityTarget then
		self.gravityTargetName = targetname
		self:SetIcon(targetname, 8, 3)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(305537) and self.gravityTargetName then
		self:RemoveIcon(self.gravityTargetName)
		self.gravityTargetName = nil
	elseif args:IsSpellID(305540) then
		timerSummonCD:Start(73)
	end
end
mod.SPELL_SUMMON = mod.SPELL_CAST_SUCCESS
mod.SPELL_CAST_FAILED = mod.SPELL_CAST_SUCCESS
