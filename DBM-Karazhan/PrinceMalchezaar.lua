local mod = DBM:NewMod("Prince", "DBM-Karazhan")
local L   = mod:GetLocalizedStrings()

mod:SetRevision("20260801000000")
mod:SetCreatureID(15690)
mod:RegisterCombat("combat", 15690)
mod:SetUsedIcons(8, 7, 1) -- Иконки: 8 = Череп, 7 = Крест, 1 = Звезда

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)
mod:RegisterEventsInCombat(
	"SPELL_CAST_START 30852 305425 305443 305447",
	"SPELL_CAST_SUCCESS 305435",
	"SPELL_AURA_APPLIED 305433 305429 305428",
	"SPELL_AURA_APPLIED_DOSE 305428",
	"UNIT_HEALTH"
)

-- ============================================================================
-- ===                        ОБЫЧНЫЙ РЕЖИМ (10 ОБ)                        ===
-- ============================================================================
local warningInfernal    = mod:NewSpellAnnounce(37277, 2)
local timerInfernal      = mod:NewCDTimer(45, 37277) -- Метеоры / Инферналы
local timerNova          = mod:NewNextTimer(30, 30852) -- Кольцо тьмы

-- ============================================================================
-- ===                      ГЕРОИЧЕСКИЙ РЕЖИМ (10 ХМ)                      ===
-- ============================================================================
local warningRingOfDarkness          = mod:NewCastAnnounce(305425, 3)                         -- Кольцо мрака
local warnDevouringFlame              = mod:NewTargetNoFilterAnnounce(305433, 4)               -- Пожирающее Пламя
local specWarnDevouringFlameYou       = mod:NewSpecialWarningYou(305433, nil, nil, nil, 1, 2) -- Пожирающее Пламя на тебе
local yellDevouringFlame              = mod:NewYell(305433)                                    -- Крик Пожирающее Пламя
local warningCurseOfExhaustion        = mod:NewSpellAnnounce(305435, 2, nil, false)                 -- Проклятие истощения (выключено по умолчанию)
local warnVengefulCorruption          = mod:NewTargetAnnounce(305429, 3, nil, false)        -- Мстительная порча (выключено по умолчанию)
local specWarnVengefulCorruptionYou   = mod:NewSpecialWarningYou(305429, nil, nil, nil, 1, 2) -- Мстительная порча на тебе

local warnArcaneCleave                = mod:NewStackAnnounce(305428, 2, nil, false)            -- Чародейское рассечение (выключено по умолчанию)
local specWarnArcaneCleaveStack       = mod:NewSpecialWarningStack(305428, nil, 7, nil, nil, 1, 2) -- Чародейское рассечение (7+ стаков на себе)
local specWarnArcaneCleaveTaunt       = mod:NewSpecialWarningTaunt(305428, nil, nil, nil, 1, 2)    -- Затаунти с танка

local warnIceSpikeTarget              = mod:NewTargetAnnounce(305443, 3)                       -- Ледяной шип
local timerIceSpikeCD                 = mod:NewNextTimer(10, 305443)                             -- Ледяной шип

local warnCallOfTheDeadTarget         = mod:NewTargetAnnounce(305447, 4)                       -- Зов мертвых
local timerCallOfTheDeadCD            = mod:NewNextTimer(10, 305447)                             -- Зов мертвых

local timerRingOfDarkness            = mod:NewNextTimer(12, 305425)                             -- Кольцо мрака
local timerDevouringFlame             = mod:NewNextTimer(42, 305433)                             -- Пожирающее Пламя
local timerCurseOfExhaustion          = mod:NewNextTimer(20, 305435)                             -- Проклятие истощения
local timerVengefulCorruption         = mod:NewNextTimer(20, 305429)                             -- Мстительная порча
local berserkTimer                    = mod:NewBerserkTimer(900)                               -- Берсерк (15 мин)

mod:AddSetIconOption("SetIconOnDevouringFlame", 305433, true, 0, {8, 7})
mod:AddSetIconOption("SetIconOnIceSpike", 305443, true, 0, {1})
mod:AddSetIconOption("SetIconOnCallOfTheDead", 305447, true, 0, {1})
mod:AddRangeFrameOption(10)

local devouringFlameTargets = {}

-- ============================================================================
-- ===                            ОБЩИЕ АНОНСЫ                             ===
-- ============================================================================
local warnPhase                      = mod:NewAnnounce("WarnPhase", 2)

-- ============================================================================
-- ===                             ФУНКЦИИ МОДУЛЯ                           ===
-- ============================================================================

function mod:ClearTargetIcon()
	if self.targetIconName then
		self:RemoveIcon(self.targetIconName)
		self.targetIconName = nil
	end
	self:UnscheduleMethod("HandleTargetSpell")
end

function mod:HandleTargetSpell(announce, duration, optionName)
	local targetname = self:GetBossTarget(15690) or UnitName("boss1target")
	if targetname then
		self.targetIconName = targetname
		announce:Show(targetname)
		if self.Options[optionName] then
			self:SetIcon(targetname, 1, duration)
		end
	end
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	table.wipe(devouringFlameTargets)
	self:ClearTargetIcon()
	self:UnscheduleMethod("SetDevouringFlameIcons")
	self:UnscheduleMethod("RestartVengefulCorruptionTimer")
	DBM:FireCustomEvent("DBM_EncounterStart", 15690, "Prince Malchezaar")

	if self:IsDifficulty("heroic10") then
		-- --- 10 ХМ ---
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(10)
		end
		timerRingOfDarkness:Start(12 - delay)
		timerCurseOfExhaustion:Start(20 - delay)
		timerVengefulCorruption:Start(20 - delay)
		berserkTimer:Start(-delay)
	else
		-- --- 10 ОБ ---
		timerInfernal:Start()
		timerNova:Start(35)
	end
end

function mod:OnCombatEnd(wipe)
	table.wipe(devouringFlameTargets)
	self:ClearTargetIcon()
	self:UnscheduleMethod("SetDevouringFlameIcons")
	self:UnscheduleMethod("RestartVengefulCorruptionTimer")
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	DBM:FireCustomEvent("DBM_EncounterEnd", 15690, "Prince Malchezaar", wipe)
end

function mod:SetDevouringFlameIcons()
	if self.Options.SetIconOnDevouringFlame then
		local icon = 8
		for _, name in ipairs(devouringFlameTargets) do
			self:SetIcon(name, icon, 3)
			icon = icon - 1
		end
	end
	local stage = self:GetStage()
	if stage == 2 then
		timerDevouringFlame:Start(42)
	elseif stage == 3 then
		timerDevouringFlame:Start(10)
	elseif stage == 5 then
		timerDevouringFlame:Start(28)
	elseif stage == 6 then
		timerDevouringFlame:Start(42)
	end
	table.wipe(devouringFlameTargets)
end

function mod:RestartVengefulCorruptionTimer()
	local stage = self:GetStage()
	if stage == 1 then
		timerVengefulCorruption:Start(20)
	elseif stage == 2 then
		timerVengefulCorruption:Start(15)
	elseif stage == 4 then
		timerVengefulCorruption:Start(9)
	elseif stage == 6 then
		timerVengefulCorruption:Start(10)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	-- Крик босса отслеживается только в 10 ОБ
	if self:IsDifficulty("normal10") then
		if self:GetStage() == 1 and (msg == L.DBM_PRINCE_YELL_INF1 or msg == L.DBM_PRINCE_YELL_INF2) then
			warningInfernal:Show()
			timerInfernal:Start()
		elseif self:GetStage() == 2 and msg == L.DBM_PRINCE_YELL_P3 then
			self:SetStage(3)
			warnPhase:Show(L.Phase3)
			warningInfernal:Show()
			timerInfernal:Start(15)
			timerNova:Start()
		elseif self:GetStage() == 1 and msg == L.DBM_PRINCE_YELL_P2 then
			self:SetStage(2)
			warnPhase:Show(L.Phase2)
		elseif self:GetStage() == 3 and (msg == L.DBM_PRINCE_YELL_INF1 or msg == L.DBM_PRINCE_YELL_INF2) then
			timerInfernal:Start(17)
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(30852) then
		if self:IsDifficulty("heroic10") then
			timerNova:Start(13)
		else
			timerNova:Start()
		end
	elseif args:IsSpellID(305425) then
		warningRingOfDarkness:Show()
		timerRingOfDarkness:Start(12)
	elseif args:IsSpellID(305443) then
		timerIceSpikeCD:Start(10)
		self:UnscheduleMethod("HandleTargetSpell")
		self:ScheduleMethod(0.1, "HandleTargetSpell", warnIceSpikeTarget, 3, "SetIconOnIceSpike")
	elseif args:IsSpellID(305447) then
		timerCallOfTheDeadCD:Start(10)
		self:UnscheduleMethod("HandleTargetSpell")
		self:ScheduleMethod(0.1, "HandleTargetSpell", warnCallOfTheDeadTarget, 4, "SetIconOnCallOfTheDead")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(305435) then
		warningCurseOfExhaustion:Show()
		local stage = self:GetStage()
		if stage == 1 or stage == 4 then
			timerCurseOfExhaustion:Start(20)
		elseif stage == 2 then
			timerCurseOfExhaustion:Start(30)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(305433) then
		table.insert(devouringFlameTargets, args.destName)
		warnDevouringFlame:CombinedShow(0.1, args.destName)
		if args:IsPlayer() then
			specWarnDevouringFlameYou:Show()
			yellDevouringFlame:Yell()
		end
		self:UnscheduleMethod("SetDevouringFlameIcons")
		self:ScheduleMethod(0.1, "SetDevouringFlameIcons")
	elseif args:IsSpellID(305429) then
		warnVengefulCorruption:CombinedShow(0.1, args.destName)
		if args:IsPlayer() then
			specWarnVengefulCorruptionYou:Show()
		end
		self:UnscheduleMethod("RestartVengefulCorruptionTimer")
		self:ScheduleMethod(0.1, "RestartVengefulCorruptionTimer")
	elseif args:IsSpellID(305428) then
		local amount = args.amount or 1
		if amount >= 7 then
			if args:IsPlayer() then
				specWarnArcaneCleaveStack:Show(amount)
				specWarnArcaneCleaveStack:Play("stackhigh")
			else
				local _, _, _, _, _, _, expireTime = DBM:UnitDebuff("player", args.spellName)
				local remaining = expireTime and (expireTime - GetTime())
				if self:IsTank() and not UnitIsDeadOrGhost("player") and (not remaining or remaining < 9) then
					specWarnArcaneCleaveTaunt:Show(args.destName)
					specWarnArcaneCleaveTaunt:Play("tauntboss")
				else
					warnArcaneCleave:Show(args.destName, amount)
				end
			end
		else
			warnArcaneCleave:Show(args.destName, amount)
		end
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:UNIT_HEALTH(uId)
	if self:GetUnitCreatureId(uId) == 15690 then
		local stage = self:GetStage()
		if stage and stage ~= 0 then
			local hp = DBM:GetBossHPByUnitID(uId)
			if hp then
				if self:IsDifficulty("heroic10") then
					-- --- 10 ХМ: Смена 6 фаз по % ХП ---
					if stage == 1 and hp <= 85 then
						self:SetStage(2)
						warnPhase:Show(L.Phase2)
						timerRingOfDarkness:Start(12)
						timerDevouringFlame:Start(42)
						timerCurseOfExhaustion:Cancel()
						timerCurseOfExhaustion:Start(30)
						timerVengefulCorruption:Cancel()
						timerVengefulCorruption:Start(15)
					elseif stage == 2 and hp <= 40 then
						self:SetStage(3)
						warnPhase:Show(L.Phase3)
						timerRingOfDarkness:Cancel()
						timerNova:Start(13)
						timerDevouringFlame:Cancel()
						timerDevouringFlame:Start(10)
						timerCurseOfExhaustion:Cancel()
						timerVengefulCorruption:Cancel()
					elseif stage == 3 and hp <= 30 then
						self:SetStage(4)
						warnPhase:Show(L.Phase4)
						timerNova:Cancel()
						timerDevouringFlame:Cancel()
						timerCurseOfExhaustion:Start(20)
						timerVengefulCorruption:Start(9)
						timerIceSpikeCD:Start(10)
					elseif stage == 4 and hp <= 20 then
						self:SetStage(5)
						warnPhase:Show(L.Phase5)
						timerDevouringFlame:Start(28)
						timerCurseOfExhaustion:Cancel()
						timerVengefulCorruption:Cancel()
						timerIceSpikeCD:Cancel()
						self:ClearTargetIcon()
						timerCallOfTheDeadCD:Start(10)
					elseif stage == 5 and hp <= 10 then
						self:SetStage(6)
						warnPhase:Show(L.Phase6)
						timerRingOfDarkness:Start(12)
						timerDevouringFlame:Cancel()
						timerDevouringFlame:Start(42)
						timerVengefulCorruption:Start(10)
						timerCallOfTheDeadCD:Cancel()
						self:ClearTargetIcon()
					end
				else
					-- --- 10 ОБ: Смена 3 фаз по % ХП ---
					if stage == 1 and hp <= 60 then
						self:SetStage(2)
						warnPhase:Show(L.Phase2)
					elseif stage == 2 and hp <= 30 then
						self:SetStage(3)
						warnPhase:Show(L.Phase3)
					end
				end
			end
		elseif stage == 0 then
			self:SetStage(1)
		end
	end
end
