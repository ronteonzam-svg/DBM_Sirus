local mod   = DBM:NewMod("Loken", "DBM-Party-WotLK", 6)
local L     = mod:GetLocalizedStrings()

mod:SetRevision("20260329000000")
mod:SetCreatureID(28923)


mod:RegisterCombat("combat")


mod:RegisterEventsInCombat(
    "SPELL_CAST_START 52960 59835"
)


local warningNova   = mod:NewSpellAnnounce(52960, 3)


local timerNovaCD   = mod:NewCDTimer(20, 52960, nil, nil, nil, 2)  -- 30 → 20
--local timerAchieve    = mod:NewAchievementTimer(120, 1867)


function mod:OnCombatStart(delay)
    timerNovaCD:Start(20-delay) 
    if not self:IsDifficulty("normal5") then
    --  timerAchieve:Start(-delay)
    end
end


function mod:SPELL_CAST_START(args)
    if args:IsSpellID(52960, 59835) then
        warningNova:Show()
        timerNovaCD:Start()
    end
end