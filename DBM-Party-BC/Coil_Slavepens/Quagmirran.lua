local mod   = DBM:NewMod(572, "DBM-Party-BC", 4, 260)
local L     = mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(17942)

mod:SetModelID(18224)
mod:SetModelOffset(-2, 0.4, -1)
mod:RegisterCombat("combat")

-- 39340: Первый через 33 с, затем каждые 24 с.
local timerSpell39340 = mod:NewCDTimer(24, 39340)

-- 38153: Первый через 25 с, затем каждые 22 с.
local timerSpell38153 = mod:NewCDTimer(22, 38153)

mod:RegisterEventsInCombat(
    "SPELL_CAST_SUCCESS 39340",
    "SPELL_CAST_SUCCESS 38153"
    -- "SPELL_CAST_SUCCESS 32055"
)

function mod:OnCombatStart(delay)
    timerSpell39340:Start(33 - delay)
    timerSpell38153:Start(25 - delay)
    -- timerSpell32055:Start(20 - delay)
end

function mod:OnCombatEnd()
    timerSpell39340:Stop()
    timerSpell38153:Stop()
    -- timerSpell32055:Stop()
end

function mod:SPELL_CAST_SUCCESS(args)
    if args.spellId == 39340 then
        timerSpell39340:Start()
    elseif args.spellId == 38153 then
        timerSpell38153:Start()
    end
end