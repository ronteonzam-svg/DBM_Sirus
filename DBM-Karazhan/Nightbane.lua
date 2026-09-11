local mod = DBM:NewMod("Nightbane", "DBM-Karazhan")
local L   = mod:GetLocalizedStrings()
local CL  = DBM_COMMON_L

mod:SetRevision("20210502220000") -- fxpw check 202206151120000
mod:SetCreatureID(17225)
--mod:RegisterCombat("yell", L.DBM_NB_YELL_PULL)
mod:RegisterCombat("combat", 17225)
mod:SetUsedIcons(6, 7, 8)

mod:RegisterEvents(
	"SPELL_CAST_START 305375 305377 305386",
	"SPELL_CAST_SUCCESS 305392",
	"SPELL_AURA_APPLIED 305382 305388",
	"SPELL_AURA_REMOVED 305388",
	"CHAT_MSG_MONSTER_EMOTE"
-- "UNIT_HEALTH"
)

-- local warningBone			= mod:NewSpellAnnounce(37098, 3)
-- local warningFearSoon		= mod:NewSoonAnnounce(36922, 2)
-- local warningFear			= mod:NewSpellAnnounce(36922, 3)
-- local warningAsh			= mod:NewTargetAnnounce(30130, 2, nil, false)
-- local WarnAir				= mod:NewAnnounce("DBM_NB_AIR_WARN", 2, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
-- local WarnNBDown1			= mod:NewAnnounce("DBM_NB_DOWN_WARN", 2, nil, nil, false)
-- local WarnNBDown2			= mod:NewAnnounce("DBM_NB_DOWN_WARN2", 3, nil, nil, false)
--
-- local specWarnCharred		= mod:NewSpecialWarningMove(30129)
--
-- local timerNightbane		= mod:NewTimer(34, "timerNightbane", "Interface\\Icons\\Ability_Mount_Undeadhorse")
-- local timerAirPhase			= mod:NewTimer(57, "timerAirPhase", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
-- local timerFearCD			= mod:NewNextTimer(31.5, 36922)
-- local timerFear				= mod:NewCastTimer(1.5, 36922)
--
-- mod:AddBoolOption("PrewarnGroundPhase", true, "announce")
--
-- function mod:CHAT_MSG_MONSTER_EMOTE(msg)
-- 	if msg == L.DBM_NB_EMOTE_PULL then
-- 		timerNightbane:Start()
-- 	end
-- end
--
-- function mod:SPELL_CAST_START(args)
-- 	if args:IsSpellID(36922) then
-- 		warningFearSoon:Cancel()
-- 		warningFear:Show()
-- 		timerFear:Start()
-- 		timerFearCD:Start()
-- 		warningFearSoon:Schedule(29)
-- 	end
-- end
--
--
-- function mod:SPELL_AURA_APPLIED(args)
-- 	if args:IsSpellID(30129) and args:IsPlayer() then
-- 		specWarnCharred:Show()
-- 	elseif args:IsSpellID(30130) then
-- 		warningAsh:Show(args.destName)
-- 	end
-- end
--
-- function mod:CHAT_MSG_MONSTER_YELL(msg)
-- 	if msg == L.DBM_NB_YELL_AIR then
-- 		WarnAir:Show()
-- 		timerAirPhase:Start()
-- 		if self.Options.PrewarnGroundPhase then
-- 			WarnNBDown1:Cancel()
-- 			WarnNBDown2:Cancel()
-- 			WarnNBDown1:Schedule(42)
-- 			WarnNBDown2:Schedule(52)
-- 		end
-- --[[	elseif msg == L.DBM_NB_YELL_GROUND or msg == L.DBM_NB_YELL_GROUND2 then
-- 		timerAirPhase:Update(43, 57)--this may not be needed--]]
-- 	end
-- end

local warnPyromancer = mod:NewTargetAnnounce(305382, 3)
-- local warnSound						= mod:NewSoundAnnounce()

local specWarnPyromancer = mod:NewSpecialWarningYou(305382, nil, nil, nil, 1, 3)

local timerGrievingFireCD = mod:NewNextTimer(13, 305375, nil, nil, nil, 2)
local timerConflCD        = mod:NewNextTimer(30, 305377, nil, nil, nil, 3, nil, CL.TANK_ICON)
local timerPyromancerCD   = mod:NewNextTimer(61.8, 305382, nil, nil, nil, 3)
local timerCallCD         = mod:NewNextTimer(125, 305386, nil, nil, nil, 6)
local timerDarkWaveCD     = mod:NewNextTimer(20, 305392, nil, nil, nil, 2)
local timerGroundPhase    = mod:NewTimer(21.7, "timerGroundPhase", "Interface\\Icons\\Ability_Mount_Undeadhorse", nil, nil, 6)
local timerNightbane      = mod:NewTimer(27.7, "timerNightbane", "Interface\\Icons\\Ability_Mount_Undeadhorse", nil, nil, 6)


local pyromancerTargets = {}
mod.vb.alivePyromancers = 0
mod.vb.groundPhase      = 0
mod.vb.conflCount       = 0
mod.vb.isAirPhase       = false
mod.vb.isPyroFirst      = true
mod.vb.isStart          = true

mod:AddBoolOption("RemoveWeaponOnMindControl", true)
mod:AddSetIconOption("SetIconOnPyromancer", 305382, true, true, { 6, 7, 8 })
mod:AddBoolOption("AnnouncePyromancerIcons", true)

function mod:LandingFinished()
	self.vb.isAirPhase = false
	timerDarkWaveCD:Cancel()
end

function mod:OnCombatStart(delay)
	DBM:FireCustomEvent("DBM_EncounterStart", 17225, "Nightbane")
	if self:IsDifficulty("heroic10") and self.vb.isStart then
		local d = delay or 0
		timerGrievingFireCD:Start(13 - d)
		timerConflCD:Start(30 - d)
		timerPyromancerCD:Start(61.8 - d)
		timerCallCD:Start(125 - d)
		table.wipe(pyromancerTargets)
		self.vb.groundPhase = 0
		self.vb.alivePyromancers = 0
		self.vb.conflCount = 0
		self.vb.isAirPhase = false
		self.vb.isPyroFirst = true
		self.vb.isStart = false
	end
end

function mod:OnCombatEnd(wipe)
	self:UnscheduleMethod("LandingFinished")
	self.vb.isAirPhase = false
	DBM:FireCustomEvent("DBM_EncounterEnd", 17225, "Nightbane", wipe)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(305375) then
		timerGrievingFireCD:Start()
	elseif args:IsSpellID(305377) then
		self.vb.conflCount = self.vb.conflCount + 1
		if self.vb.conflCount < 3 then
			timerConflCD:Start()
		end
	elseif args:IsSpellID(305386) then
		self.vb.isAirPhase = true
		timerGrievingFireCD:Cancel()
		timerConflCD:Cancel()
		timerDarkWaveCD:Start(20)
		if UnitAura("player", L.Pyromancer, nil, "HARMFUL") or
			UnitAura("player", L.Hypothermia, nil, "HARMFUL") and self.Options.RemoveWeaponOnMindControl then
			-- if self:IsWeaponDependent("player") then
				PickupInventoryItem(16)
				PutItemInBackpack()
				PickupInventoryItem(17)
				PutItemInBackpack()
			if select(2, UnitClass("player")) == "HUNTER" then
				PickupInventoryItem(18)
				PutItemInBackpack()
			end
		end
		table.wipe(pyromancerTargets)
		self.vb.isPyroFirst = true
		self.vb.groundPhase = 0
		self.vb.alivePyromancers = 0
		self.vb.conflCount = 0
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(305392) then
		if self.vb.isAirPhase then
			timerDarkWaveCD:Start(20)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(305382) then
		if args:IsPlayer() then
			specWarnPyromancer:Show()
		end
		pyromancerTargets[#pyromancerTargets + 1] = args.destName
		if #pyromancerTargets >= 3 and self.vb.isPyroFirst then
			warnPyromancer:Show(table.concat(pyromancerTargets, "<, >"))
			if self.Options.SetIconOnPyromancer then
				table.sort(pyromancerTargets, function(v1, v2) return DBM:GetRaidSubgroup(v1) < DBM:GetRaidSubgroup(v2) end)
				local pyroIcons = 8
				for _, v in ipairs(pyromancerTargets) do
					if self.Options.AnnouncePyromancerIcons then
						SendChatMessage(L.PyromancerIconSet:format(pyroIcons, v), "RAID")
					end
					self:SetIcon(v, pyroIcons)
					pyroIcons = pyroIcons - 1
				end
			end
			self.vb.isPyroFirst = false
		end
	elseif args:IsSpellID(305388) then
		self.vb.alivePyromancers = self.vb.alivePyromancers + 1
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(305388) then
		self:RemoveIcon(args.destName)
		if self.vb.groundPhase == self.vb.alivePyromancers - 1 then
			self:UnscheduleMethod("LandingFinished")
			self:ScheduleMethod(21.7, "LandingFinished")
			timerGroundPhase:Start(21.7)
			timerGrievingFireCD:Start(35)
			timerConflCD:Start(52)
			timerPyromancerCD:Start(83.8)
			timerCallCD:Start(147)
			self.vb.conflCount = 0
		else
			self.vb.groundPhase = self.vb.groundPhase + 1
		end
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if msg == L.DBM_NB_EMOTE_PULL then
		timerNightbane:Start()
		self.vb.isStart = true
	end
end
