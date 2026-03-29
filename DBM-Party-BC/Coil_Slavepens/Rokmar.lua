local mod   = DBM:NewMod(571, "DBM-Party-BC", 4, 260)
local L     = mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(17991)
mod:SetModelID(17729)
mod:SetModelOffset(-3, 0, -0.8)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
    "SPELL_AURA_APPLIED 31956 38801 34970"
)

-- Объявления (announce)
local WarnFrenzy    = mod:NewSpellAnnounce(34970)

-- Специальное предупреждение для хилера
local specWarnWound = mod:NewSpecialWarningTarget(38801, "Healer", nil, nil, 1, 7)

-- Таймер следующего наложения Mortal Wound (38801)
-- NewCDTimer(секунд, spellId) — таймер типа "cooldown/next cast"
local timerWound    = mod:NewCDTimer(10, 38801)

-- ──────────────────────────────────────────────
-- Вспомогательная функция для зацикленного таймера
-- ──────────────────────────────────────────────
local function scheduleWoundLoop(self)
    -- Запускаем бар на 10 секунд
    timerWound:Start(10)
    -- Через 10 секунд вызываем себя снова (автоперезапуск)
    self:Schedule(10, scheduleWoundLoop, self)
end

-- ──────────────────────────────────────────────
-- Начало боя
-- ──────────────────────────────────────────────
function mod:OnCombatStart(delay)
    -- Стартуем таймер с учётом уже прошедшего времени пулла
    timerWound:Start(10 - delay)
    -- Запускаем петлю перезапуска через (10 - delay) секунд
    self:Schedule(10 - delay, scheduleWoundLoop, self)
end

-- ──────────────────────────────────────────────
-- Конец боя — отменяем всё запланированное
-- ──────────────────────────────────────────────
function mod:OnCombatEnd()
    self:Unschedule(scheduleWoundLoop, self)
    timerWound:Stop()
end

-- ──────────────────────────────────────────────
-- Обработчик событий боя
-- ──────────────────────────────────────────────
function mod:SPELL_AURA_APPLIED(args)
    if args:IsSpellID(31956, 38801) then
        specWarnWound:Show(args.destName)
        specWarnWound:Play("healfull")

        -- При реальном наложении 38801 синхронизируем таймер:
        -- отменяем текущую петлю и стартуем заново от этого момента
        if args.spellId == 38801 then
            self:Unschedule(scheduleWoundLoop, self)
            timerWound:Start(10)
            self:Schedule(10, scheduleWoundLoop, self)
        end
    elseif args.spellId == 34970 then
        WarnFrenzy:Show(args.destName)
    end
end
