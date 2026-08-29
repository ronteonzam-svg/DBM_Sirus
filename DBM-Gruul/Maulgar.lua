local mod 	= 	DBM:NewMod("Maulgar", "DBM-Gruul");
local L		= 	mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 183 $"):sub(12, -3))
mod:SetCreatureID(18831)
mod:SetUsedIcons(8,7,6,5,4)

mod:RegisterCombat("combat", 18831)
mod:RegisterEventsInCombat(
	"SPELL_CAST_START 305221", -- 33131 (Олм: призыв собак)
	"SPELL_CAST_SUCCESS 16508 33129 33175 33237", -- 33147 (Слепоглаз)
	"SPELL_AURA_APPLIED 305216 305247 33238 33054 33173"
)

local isDispeller = select(2, UnitClass("player")) == "PRIEST" or select(2, UnitClass("player")) == "SHAMAN" or select(2, UnitClass("player")) == "MAGE"

mod:AddTimerLine(DBM_CORE_L.NORMAL_MODE)

local specWarnMelee                  = mod:NewSpecialWarningMove(33238, "Melee")

local timerWhirlCD                   = mod:NewCDTimer(55, 33238)
local timerWhirl                     = mod:NewTimer(15, "TimerWhirl", 33238)
local timerIntimidateCD              = mod:NewCDTimer(16, 16508)

-- === NORMAL ADDS === --
local timerSpellShieldCD             = mod:NewCDTimer(30, 33054, nil, nil, nil, 5)               -- Крош: чародейский щит
--local timerSummonFelhunterCD         = mod:NewCDTimer(30, 33131, nil, nil, nil, 1)               -- Олм: призыв собак
local timerDarkDecayCD               = mod:NewCDTimer(4, 33129, nil, "Tank|Healer", nil, 3)      -- Олм: темное разложение
--local timerGreatShieldCD             = mod:NewCDTimer(40, 33147, nil, "Healer", nil, 4)          -- Слепоглаз: великий щит
local timerPolymorphCD               = mod:NewCDTimer(40, 33173, nil, nil, nil, 3)               -- Кигглер: превращение
local timerArcaneShockCD             = mod:NewCDTimer(20, 33175, nil, "Tank", nil, 5)            -- Кигглер: чародейский шок
local warnArcaneExplosionSoon        = mod:NewSoonAnnounce(33237, 2)                             -- Кигглер
local timerArcaneExplosionCD         = mod:NewCDTimer(30, 33237, nil, nil, nil, 2)
-- === END NORMAL ADDS === --

mod:AddTimerLine(DBM_CORE_L.HEROIC_MODE)

local warnMight                      = mod:NewAnnounce("WarnMight", 2)

local specWarnShield                 = mod:NewSpecialWarningDispel(33054 or 305247, isDispeller)
local specWarnKickCleanse            = mod:NewSpecialWarning("KickNow", "-Melee")

local timerMight                     = mod:NewTargetTimer(60, 305216, "timerActive")
local timerMightCD                   = mod:NewCDTimer(65, 305216)

mod:AddBoolOption("WarnMight",true)
mod:AddBoolOption("AnnounceToChat",false)

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 18831, "High King Maulgar")
	if mod:IsDifficulty("heroic25") then
		timerMightCD:Start(5)
	else
		timerWhirlCD:Start(30 - delay)
		--timerSummonFelhunterCD:Start(15 - delay)
		timerDarkDecayCD:Start(-delay)
		timerArcaneShockCD:Start(-delay)
		timerArcaneExplosionCD:Start(-delay)
		warnArcaneExplosionSoon:Schedule(25 - delay)
	end
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 18831, "High King Maulgar", wipe)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(305221) then
		specWarnKickCleanse:Show(args.spellName)
--	elseif args:IsSpellID(33131) and self:IsDifficulty("normal25") then
--		timerSummonFelhunterCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(16508) then
		timerIntimidateCD:Start()
	elseif self:IsDifficulty("normal25") then
		if args:IsSpellID(33129) then -- темное разложение
			timerDarkDecayCD:Start()
--		elseif args:IsSpellID(33147) then -- великий щит
--			timerGreatShieldCD:Start()
		elseif args:IsSpellID(33175) then -- чародейский шок
			timerArcaneShockCD:Start()
		elseif args:IsSpellID(33237) then -- чародейский взрыв
			timerArcaneExplosionCD:Start()
			warnArcaneExplosionSoon:Schedule(25)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(305216) then
		local activeIcon
		for i = 1,40 do
			if UnitName("raid" .. i .. "target") == L.name then
				activeIcon = GetRaidTargetIndex("raid" .. i .. "targettarget")
			end
		end
		timerMightCD:Start()
		warnMight:Show(args.destName, activeIcon or "Interface\\Icons\\Inv_misc_questionmark")
		timerMight:Start(args.destName, activeIcon or "Interface\\Icons\\Inv_misc_questionmark")
		if self.Options.AnnounceToChat then
			SendChatMessage((activeIcon and ("{rt" .. activeIcon .. "} ") or "") .. args.destName .. " активен", "RAID")
		end
	elseif args:IsSpellID(305247) or args:IsSpellID(33054)then
		specWarnShield:Show()
		if args:IsSpellID(33054) and self:IsDifficulty("normal25") then
			timerSpellShieldCD:Start()
		end
	elseif args:IsSpellID(33173) and self:IsDifficulty("normal25") then -- превращение (Кигглер)
		if self:AntiSpam(3, "polyNormal") then
			timerPolymorphCD:Start()
		end
	elseif args:IsSpellID(33238) then
		timerWhirlCD:Start()
		timerWhirl:Start()
		specWarnMelee:Show()
	end
end