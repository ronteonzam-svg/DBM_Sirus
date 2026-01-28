local mod	= DBM:NewMod("Broggok", "DBM-Party-BC", 2, 256)

mod:SetRevision("20260128000000")
mod:SetCreatureID(17380)
mod:SetModelID(19372)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
    "SPELL_CAST_SUCCESS 30916, 30917, 38459" -- Проверить таймер Ядовитого удара в обычке(30917)
)

local timerPoisonCloud  = mod:NewCDTimer(20, 30916)
local timerPoisonBolt   = mod:NewCDTimer(6, 38459)

function mod:SPELL_CAST_SUCCESS(args)
    if args:IsSpellID(30916) then
        timerPoisonCloud:Start()
    elseif args:IsSpellID(38459) then
        timerPoisonBolt:Start()
    end
end
