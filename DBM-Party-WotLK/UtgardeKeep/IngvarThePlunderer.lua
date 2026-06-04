local mod	= DBM:NewMod("IngvarThePlunderer", "DBM-Party-WotLK", 10)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(23980, 23954)
mod:SetUsedIcons(8)

mod:RegisterCombat("combat")
mod:RegisterKill("yell", L.YellCombatEnd)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 42723 42669 59706 59709 42708 42729 59708 59734",
	"SPELL_AURA_APPLIED 42730 59735",
	"SPELL_AURA_REMOVED 42730 59735",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_DIED",
	"UNIT_SPELLCAST_SUCCEEDED boss1 target focus"
)

local warningWoeStrike	= mod:NewTargetNoFilterAnnounce(42730, 2, nil, "RemoveCurse", 2)

local specWarnStaggeringRoar	= mod:NewSpecialWarningCast(42708, nil, nil, nil, 1, 2)
local specWarnDreadfulRoar		= mod:NewSpecialWarningCast(42729, nil, nil, nil, 1, 2)
local specWarnSmash		= mod:NewSpecialWarningDodge(42723, "Tank", nil, nil, 1, 2)
local specWarnAxe		= mod:NewSpecialWarningDodge(42748, nil, nil, nil, 2, 2)
local specWarnAxeReturn	= mod:NewSpecialWarning("SpecWarnAxeReturn", "Melee", nil, nil, 1, nil, nil, 42748, 42748)
specWarnAxeReturn.icon	= select(3, GetSpellInfo(42748))

local timerSmash		= mod:NewCastTimer(3, 42723)
local timerSmashCD		= mod:NewCDTimer(13, 42723)
local timerWoeStrike	= mod:NewTargetTimer(10, 42723, nil, "RemoveCurse", nil, 5, nil, DBM_COMMON_L.CURSE_ICON)
local timerAxeReturn	= mod:NewTimer(8, "TimerAxeReturn", 42748, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 42748)

mod:AddSetIconOption("WoeStrikeIcon", 42730, true, false, {8})

function mod:OnCombatStart()
	self:SetStage(1)
	timerSmashCD:Start(15)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(42723, 42669, 59706, 59709) then
		specWarnSmash:Show()
		specWarnSmash:Play("shockwave")
		timerSmash:Start()
		timerSmashCD:Start()
	elseif args:IsSpellID(42708, 59708) then
		specWarnStaggeringRoar:Show()
		specWarnStaggeringRoar:Play("stopcast")
	elseif args:IsSpellID(42729, 59734) then
		specWarnDreadfulRoar:Show()
		specWarnDreadfulRoar:Play("stopcast")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(42730, 59735) then
		warningWoeStrike:Show(args.destName)
		timerWoeStrike:Start(args.destName)
		if self.Options.WoeStrikeIcon then
			self:SetIcon(args.destName, 8, 10)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(42730, 59735) then
		timerWoeStrike:Cancel()
		if self.Options.WoeStrikeIcon then
			self:RemoveIcon(args.destName)
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 23954 then--Only trigger kill for unit_died if he dies in phase 2 with at least one player alive, otherwise it's an auto wipe.
		if DBM:NumRealAlivePlayers() > 0 and self.vb.phase == 2 then
			DBM:EndCombat(self)
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellIngvarPhase2 or msg:find(L.YellIngvarPhase2) then
		self:SetStage(2)
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(uId, spellName, _, _, spellId)
	if spellName == GetSpellInfo(42863) or spellId == 42863 then -- Scourge Resurrection
		if self:AntiSpam(3, "Resurrection") then
			self:SetStage(2)
		end
	elseif spellName == GetSpellInfo(42748) or spellId == 42748 or spellName == "Теневой топор" then
		if self:AntiSpam(2, "ShadowAxe") then
			timerAxeReturn:Start()
			specWarnAxe:Show()
			DBM:PlaySoundFile("Interface\\AddOns\\DBM-Core\\sounds\\AirHorn.ogg")
			specWarnAxeReturn:Schedule(8)
		end
	end
end