local mod   = DBM:NewMod("NovosTheSummoner", "DBM-Party-WotLK", 4)
local L     = mod:GetLocalizedStrings()

mod:SetRevision("20260207010000")
mod:SetCreatureID(26631)

mod:RegisterCombat("yell", L.YellPull)
mod:RegisterKill("yell", L.YellKill)
mod:SetWipeTime(25)

mod:RegisterEventsInCombat(
    "SPELL_CAST_SUCCESS 59856 59854",
    "SPELL_AURA_APPLIED 59856 59854",
    "CHAT_MSG_MONSTER_YELL",
    "UNIT_DIED"
)

local WarnCrystalHandler        = mod:NewAnnounce("WarnCrystalHandler", 2, 59910)
local warnPhase2                = mod:NewPhaseAnnounce(2)
local warnCurseTarget           = mod:NewTargetAnnounce(59856)

local specwarnCurse             = mod:NewSpecialWarningDispel(59856, "RemoveCurse")
local specwarnSnow              = mod:NewSpecialWarningMove(59854)

local timerCrystalHandler       = mod:NewTimer(40, "timerCrystalHandler", 59910, nil, nil, 1, DBM_COMMON_L.DAMAGE_ICON)
local timerNextCurse            = mod:NewCDTimer(20, 59856)

mod.vb.CrystalHandlers = 4  
mod.vb.DeadHandlers = 0      
mod.vb.Phase2YellDetected = false

function mod:OnCombatStart(delay)
    self:SetStage(1)
    timerCrystalHandler:Start(26-delay)
    self.vb.CrystalHandlers = 4
    self.vb.DeadHandlers = 0
    self.vb.Phase2YellDetected = false
end

local function TryTriggerPhase2(self)
    if self:GetStage() ~= 2 and self.vb.DeadHandlers >= 4 and self.vb.Phase2YellDetected then
        self:SetStage(2)
        warnPhase2:Show()
        timerCrystalHandler:Stop()
    end
end

function mod:UNIT_DIED(args)
    local cid = self:GetCIDFromGUID(args.destGUID)
    if cid == 26627 then -- Хрустальный укротитель
        self.vb.DeadHandlers = self.vb.DeadHandlers + 1
        TryTriggerPhase2(self)
    end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
    if msg == L.HandlerYell then
        if self.vb.CrystalHandlers > 0 then
            self.vb.CrystalHandlers = self.vb.CrystalHandlers - 1
        end
        WarnCrystalHandler:Show(self.vb.CrystalHandlers)
        if self:GetStage() == 1 then
            timerCrystalHandler:Start()
        end
    elseif (msg == L.Phase2_1) or (msg == L.Phase2_2) then
        self.vb.Phase2YellDetected = true
        TryTriggerPhase2(self)
    end
end

function mod:SPELL_CAST_SUCCESS(args)
    if args.spellId == 59856 then
        warnCurseTarget:Show(args.destName)
        specwarnCurse:Show()
        timerNextCurse:Start()
    elseif args.spellId == 59854 and self:AntiSpam(1,2) then
        specwarnSnow:Show()
    end
end
mod.SPELL_AURA_APPLIED = mod.SPELL_CAST_SUCCESS
