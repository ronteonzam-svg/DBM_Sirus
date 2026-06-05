local mod   = DBM:NewMod("Loken", "DBM-Party-WotLK", 6)
local L     = mod:GetLocalizedStrings()

mod:SetRevision("20260605000000")
mod:SetCreatureID(28923)


mod:RegisterCombat("combat")


mod:RegisterEventsInCombat(
    "SPELL_CAST_START 52960 59835",
    "SPELL_CAST_SUCCESS 52921"
)


local warningNova				= mod:NewSpellAnnounce(52960, 3)
local warningArcaneLightning	= mod:NewSpellAnnounce(52921, 2)

local timerNovaCD				= mod:NewCDTimer(20, 52960, nil, nil, nil, 2)  -- 30 → 20
local timerArcaneLightningCD	= mod:NewCDTimer(15, 52921, nil, nil, nil, 3)
--local timerAchieve    = mod:NewAchievementTimer(120, 1867)


function mod:OnCombatStart(delay)
    timerNovaCD:Start(20-delay)
    timerArcaneLightningCD:Start(15-delay)
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


function mod:SPELL_CAST_SUCCESS(args)
    if args:IsSpellID(52921) then
        warningArcaneLightning:Show()
        timerArcaneLightningCD:Start()
    end
end