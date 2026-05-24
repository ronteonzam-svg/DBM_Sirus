local mod   = DBM:NewMod("Bjarngrin", "DBM-Party-WotLK", 6)
local L     = mod:GetLocalizedStrings()

mod:SetRevision("20260331000000")
mod:SetCreatureID(28586)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
    "SPELL_CAST_SUCCESS 53790 53791 53792",
    "SPELL_AURA_APPLIED 52027"
)

--[[
    =============================================
    ОПОВЕЩЕНИЯ
    =============================================
]]

-- Вихрь (optionDefault=true — включено по умолчанию для ВСЕХ ролей)
local warningWhirlwind      = mod:NewSpellAnnounce(52027, 3)
local specWarnWhirlwind     = mod:NewSpecialWarningRun(52027, "Tank", nil, nil, 4, 2)

-- Стойки
local warnDefStance         = mod:NewSpellAnnounce(53790, 2)
local warnBerserkStance     = mod:NewSpellAnnounce(53791, 3)
local warnBattleStance      = mod:NewSpellAnnounce(53792, 2)

--[[
    =============================================
    ТАЙМЕРЫ
    colorType:
      2 = AoE   (красный)    — урон по области
      6 = Stage (жёлтый)     — переключение стоек
    =============================================
]]

-- Таймеры стоек (тип 6 = Фаза)
local timerDefStance        = mod:NewTimer(22, "DefStance",     53790, nil, nil, 6)
local timerBerserkStance    = mod:NewTimer(22, "BerserkStance", 53791, nil, nil, 6)
local timerBattleStance     = mod:NewTimer(22, "BattleStance",  53792, nil, nil, 6)

-- Таймер Вихря (тип 2 = AoE, обратный отсчёт с 5 сек)
local timerWhirlwind        = mod:NewTimer(15, "WhirlwindSoon", 52027, nil, nil, 2, nil, nil, 5, 5)

--[[
    =============================================
    ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
    =============================================
]]

local function StopAllStanceTimers()
    timerDefStance:Stop()
    timerBerserkStance:Stop()
    timerBattleStance:Stop()
end

--[[
    =============================================
    СОБЫТИЯ
    =============================================
]]

function mod:OnCombatStart(delay)
    timerDefStance:Start(22 - delay)
end

function mod:SPELL_AURA_APPLIED(args)
    if args:IsSpellID(52027) then
        timerWhirlwind:Stop()
        if self.Options.SpecWarn52027run then
            specWarnWhirlwind:Show()
            specWarnWhirlwind:Play("runout")
        else
            warningWhirlwind:Show()
        end
    end
end

function mod:SPELL_CAST_SUCCESS(args)
    if args:IsSpellID(53790) then
        warnDefStance:Show()
        StopAllStanceTimers()
        timerDefStance:Start()
    elseif args:IsSpellID(53791) then
        warnBerserkStance:Show()
        StopAllStanceTimers()
        timerBerserkStance:Start()
        timerWhirlwind:Start(15)
    elseif args:IsSpellID(53792) then
        warnBattleStance:Show()
        StopAllStanceTimers()
        timerBattleStance:Start()
    end
end