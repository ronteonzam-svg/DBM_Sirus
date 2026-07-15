local mod = DBM:NewMod("Zluker", "DBM-Karazhan")
local L   = mod:GetLocalizedStrings()

mod:SetRevision("20260713234500")
mod:SetCreatureID(10055, 100552, 100555)
mod:RegisterCombat("yell", L.YellZluker)
mod:SetUsedIcons(8)

mod:RegisterEvents(
	"SPELL_CAST_START 305535 305537",
	"SPELL_CAST_SUCCESS 305537",
	"SPELL_CAST_FAILED 305537",
	"CHAT_MSG_MONSTER_YELL"
)

local timerMagicCD     = mod:NewCDTimer(46, 305535)
local timerMagicCast   = mod:NewCastTimer(5, 305535, nil, nil, nil, 2)
--local timerCombatStart = mod:NewCombatTimer(42)

-- Prominent special warnings in the center of the screen
local specWarnGravityDefianceYou       = mod:NewSpecialWarningRun(305537, nil, "SpecWarn305537run", nil, 4, 2)
local specWarnGravityDefianceTargetYou = mod:NewSpecialWarning("SpecWarnGravityDefianceTargetYou", nil, nil, nil, 1, 2, nil, 305537, 305537)
local warnGravityDefiance              = mod:NewTargetAnnounce(305537, 3, false, "warnGravityDefiance")
local specWarnMagicCast                = mod:NewSpecialWarning("SpecWarnMagicCast", nil, nil, nil, 3, 2, nil, 305535, 305535)

mod:AddSetIconOption("SetIconOnGravityTarget", 305537, true, 0, { 8 })

--Таймер до запуска. Непонятно иногда 79 секунд, иногда около 30-40
--[[
function mod:CHAT_MSG_MONSTER_YELL(msg)
	if L.YellPull and (msg == L.YellPull or msg:find(L.YellPull)) then
		timerCombatStart:Start()
	end
end
--]]

function mod:OnCombatStart()
	timerMagicCD:Start(66)
	self.gravityTargetName = nil
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(305535) then
		timerMagicCD:Start()
		timerMagicCast:Start()
		specWarnMagicCast:Show()
		specWarnMagicCast:Play("jump")
	elseif args:IsSpellID(305537) then
		self:BossTargetScanner(args.sourceGUID, "GravityTarget", 0.01, 10)
	end
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
	end
end
mod.SPELL_CAST_FAILED = mod.SPELL_CAST_SUCCESS
