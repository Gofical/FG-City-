-- ZCity Optimized - Organism System
-- Lightweight health/stamina/injury system for Sandbox

hg.Organism = hg.Organism or {}
hg.Organism.Players = {}

-- Default organism state
local DEFAULT_ORGANISM = {
	health = 100,
	maxhealth = 100,
	armor = 0,
	maxarmor = 100,
	
	-- Status effects
	bleeding = false,
	bleed_rate = 0,
	broken_bones = {}, -- bone_name = severity (0-1)
	pain = 0,
	unconscious = false,
	
	-- Vitals
	stamina = 100,
	maxstamina = 100,
	hunger = 100,
	thirst = 100,
	radiation = 0,
	poisoned = false,
	poison_level = 0,
	
	-- Temperature
	body_temp = 37,
	
	-- Blood
	blood = 5000, -- ml
	blood_type = "O+",
	
	-- Metabolism
	metabolism = 1.0,
	
	-- Injuries (body part -> severity)
	injuries = {},
	
	-- Medications active
	medications = {},
	
	-- Network sync
	last_sync = 0,
	dirty = true,
}

-- Body parts for injury system
hg.Organism.BodyParts = {
	"head", "neck", "chest", "stomach",
	"left_arm", "right_arm",
	"left_leg", "right_leg",
	"left_hand", "right_hand",
	"left_foot", "right_foot",
}

hg.Organism.BodyPartBones = {
	head = "ValveBiped.Bip01_Head1",
	neck = "ValveBiped.Bip01_Neck1",
	chest = "ValveBiped.Bip01_Spine2",
	stomach = "ValveBiped.Bip01_Spine1",
	left_arm = "ValveBiped.Bip01_L_UpperArm",
	right_arm = "ValveBiped.Bip01_R_UpperArm",
	left_leg = "ValveBiped.Bip01_L_Thigh",
	right_leg = "ValveBiped.Bip01_R_Thigh",
	left_hand = "ValveBiped.Bip01_L_Hand",
	right_hand = "ValveBiped.Bip01_R_Hand",
	left_foot = "ValveBiped.Bip01_L_Foot",
	right_foot = "ValveBiped.Bip01_R_Foot",
}

-- Initialize organism for player
function hg.InitOrganism(ply)
	if not IsValid(ply) then return end
	if not hg.Config.GetBool("organism_enable") then return end
	
	local org = table.Copy(DEFAULT_ORGANISM)
	org.maxhealth = hg.Config.GetInt("organism_health")
	org.health = org.maxhealth
	org.maxstamina = hg.Config.GetInt("organism_stamina")
	org.stamina = org.maxstamina
	org.blood_type = table.Random({"A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"})
	
	hg.Organism.Players[ply] = org
	ply.organism = org
	
	if SERVER then
		hg.Net.SetPlayerVar(ply, "organism", org)
		hg.Organism.StartSync(ply)
	end
	
	hook.Run("ZC_OrganismInitialized", ply, org)
	return org
end

function hg.GetOrganism(ply)
	if not IsValid(ply) then return nil end
	return ply.organism or hg.Organism.Players[ply]
end

function hg.CleanupPlayer(ply)
	hg.Organism.Players[ply] = nil
	if SERVER then
		hg.TimerRemove("OrganismSync_" .. ply:EntIndex())
		hg.TimerRemove("OrganismThink_" .. ply:EntIndex())
	end
end

-- Damage handling
function hg.Organism.TakeDamage(ply, dmgInfo)
	local org = hg.GetOrganism(ply)
	if not org then return end
	
	local dmg = dmgInfo:GetDamage()
	local dmgType = dmgInfo:GetDamageType()
	local hitGroup = dmgInfo:GetHitGroup()
	local attacker = dmgInfo:GetAttacker()
	local inflictor = dmgInfo:GetInflictor()
	
	-- Apply armor
	if org.armor > 0 and bit.band(dmgType, DMG_BULLET + DMG_BUCKSHOT + DMG_SLASH + DMG_CLUB) ~= 0 then
		local absorb = dmg * hg.Config.GetFloat("damage_armor_absorption")
		absorb = math.min(absorb, org.armor)
		org.armor = org.armor - absorb
		dmg = dmg - absorb
		
		-- Armor damage effect
		if SERVER then
			hg.Net.SendEffect(ply:GetPos(), "ArmorImpact", {amount = absorb})
		end
	end
	
	-- Hitgroup multipliers
	local mult = 1.0
	if hitGroup == HITGROUP_HEAD then
		mult = hg.Config.GetFloat("damage_head_mult")
	elseif hitGroup == HITGROUP_LEFTARM or hitGroup == HITGROUP_RIGHTARM or
		   hitGroup == HITGROUP_LEFTLEG or hitGroup == HITGROUP_RIGHTLEG then
		mult = hg.Config.GetFloat("damage_limb_mult")
	end
	
	dmg = dmg * mult
	
	-- Apply damage
	org.health = math.max(0, org.health - dmg)
	org.pain = math.min(100, org.pain + dmg * 0.5)
	org.dirty = true
	
	-- Bleeding chance
	if hg.Config.GetBool("damage_realistic") and bit.band(dmgType, DMG_BULLET + DMG_BUCKSHOT + DMG_SLASH) ~= 0 then
		local bleedChance = hg.Config.GetFloat("organism_bleed_chance") * (dmg / 20)
		if math.random() < bleedChance then
			hg.Organism.ApplyBleeding(ply, hitGroup, dmg * 0.1)
		end
	end
	
	-- Fracture chance
	if hg.Config.GetBool("damage_realistic") and dmg > 30 then
		local fracChance = hg.Config.GetFloat("organism_fracture_chance") * (dmg / 50)
		if math.random() < fracChance then
			hg.Organism.ApplyFracture(ply, hitGroup)
		end
	end
	
	-- Unconscious check
	if org.health <= 0 then
		hg.Organism.Kill(ply, dmgInfo)
	elseif org.health < 20 or org.pain > 80 or org.blood < 2000 then
		if not org.unconscious and math.random() < 0.3 then
			hg.Organism.SetUnconscious(ply, true)
		end
	end
	
	-- Blood loss from damage
	if bit.band(dmgType, DMG_BULLET + DMG_BUCKSHOT + DMG_SLASH) ~= 0 then
		org.blood = math.max(0, org.blood - dmg * 10)
	end
	
	hg.Organism.MarkDirty(ply)
	
	hook.Run("ZC_OrganismDamaged", ply, dmg, dmgType, hitGroup, attacker, inflictor)
end

function hg.Organism.ApplyBleeding(ply, hitGroup, rate)
	local org = hg.GetOrganism(ply)
	if not org then return end
	
	local part = hg.Organism.HitGroupToBodyPart(hitGroup)
	org.bleeding = true
	org.bleed_rate = org.bleed_rate + (rate or 5)
	
	if SERVER then
		hg.Net.SendEffect(ply:GetPos(), "BleedStart", {part = part})
	end
end

function hg.Organism.ApplyFracture(ply, hitGroup)
	local org = hg.GetOrganism(ply)
	if not org then return end
	
	local part = hg.Organism.HitGroupToBodyPart(hitGroup)
	local bone = hg.Organism.BodyPartBones[part]
	
	if bone then
		org.broken_bones[bone] = (org.broken_bones[bone] or 0) + 0.5
		org.pain = math.min(100, org.pain + 20)
		
		if SERVER then
			hg.Net.SendEffect(ply:GetPos(), "Fracture", {bone = bone})
			ply:EmitSound("physics/body/body_medium_break" .. math.random(2, 4) .. ".wav", 75, 100, 0.5)
		end
	end
end

function hg.Organism.HitGroupToBodyPart(hitGroup)
	local map = {
		[HITGROUP_HEAD] = "head",
		[HITGROUP_CHEST] = "chest",
		[HITGROUP_STOMACH] = "stomach",
		[HITGROUP_LEFTARM] = "left_arm",
		[HITGROUP_RIGHTARM] = "right_arm",
		[HITGROUP_LEFTLEG] = "left_leg",
		[HITGROUP_RIGHTLEG] = "right_leg",
		[HITGROUP_GEAR] = "stomach",
	}
	return map[hitGroup] or "chest"
end

function hg.Organism.SetUnconscious(ply, state)
	local org = hg.GetOrganism(ply)
	if not org then return end
	
	org.unconscious = state
	
	if state then
		ply:SetMoveType(MOVETYPE_OBSERVER)
		ply:Spectate(OBS_MODE_IN_EYE)
		if SERVER then
			ply:ChatPrint("You have fallen unconscious!")
		end
	else
		ply:UnSpectate()
		ply:SetMoveType(MOVETYPE_WALK)
	end
	
	hg.Organism.MarkDirty(ply)
end

function hg.Organism.Kill(ply, dmgInfo)
	local org = hg.GetOrganism(ply)
	if not org then return end
	
	org.health = 0
	org.unconscious = false
	
	if SERVER then
		ply:Kill()
	end
	
	hook.Run("ZC_OrganismDied", ply, dmgInfo)
end

-- Healing
function hg.Organism.Heal(ply, amount, healType)
	local org = hg.GetOrganism(ply)
	if not org then return end
	
	healType = healType or "health"
	
	if healType == "health" then
		org.health = math.min(org.maxhealth, org.health + amount)
	elseif healType == "armor" then
		org.armor = math.min(org.maxarmor, org.armor + amount)
	elseif healType == "blood" then
		org.blood = math.min(5000, org.blood + amount)
	elseif healType == "stamina" then
		org.stamina = math.min(org.maxstamina, org.stamina + amount)
	end
	
	org.dirty = true
	hg.Organism.MarkDirty(ply)
end

function hg.Organism.StopBleeding(ply, bodyPart)
	local org = hg.GetOrganism(ply)
	if not org then return end
	
	if bodyPart then
		-- Specific body part
		local bone = hg.Organism.BodyPartBones[bodyPart]
		if bone and org.broken_bones[bone] then
			org.broken_bones[bone] = math.max(0, org.broken_bones[bone] - 0.25)
			if org.broken_bones[bone] <= 0 then
				org.broken_bones[bone] = nil
			end
		end
	else
		-- Full stop
		org.bleeding = false
		org.bleed_rate = 0
	end
	
	org.dirty = true
	hg.Organism.MarkDirty(ply)
end

function hg.Organism.ApplyMedication(ply, medType, duration, strength)
	local org = hg.GetOrganism(ply)
	if not org then return end
	
	org.medications[medType] = {
		type = medType,
		start = CurTime(),
		duration = duration,
		strength = strength or 1,
	}
	
	hg.Organism.MarkDirty(ply)
end

-- Think loop
function hg.Organism.Think(ply)
	local org = hg.GetOrganism(ply)
	if not org then return end
	
	local now = CurTime()
	local dt = FrameTime()
	
	if SERVER then
		dt = engine.TickInterval()
	end
	
	-- Health regen
	if org.health > 0 and org.health < org.maxhealth then
		if not org.last_damage or now - org.last_damage > hg.Config.GetInt("organism_regen_delay") then
			local regen = hg.Config.GetFloat("organism_regen_rate") * dt
			if org.hunger > 50 and org.thirst > 50 then
				regen = regen * 1.5
			end
			org.health = math.min(org.maxhealth, org.health + regen)
		end
	end
	
	-- Stamina regen
	if org.stamina < org.maxstamina then
		local moving = ply:KeyDown(IN_SPEED) and ply:GetVelocity():Length2D() > 50
		local regenMult = moving and 0.2 or 1.0
		if org.hunger < 30 or org.thirst < 30 then regenMult = regenMult * 0.5 end
		
		org.stamina = math.min(org.maxstamina, org.stamina + hg.Config.GetFloat("organism_stamina_regen") * dt * regenMult)
	end
	
	-- Hunger/Thirst
	org.hunger = math.max(0, org.hunger - hg.Config.GetFloat("organism_hunger_rate") * dt)
	org.thirst = math.max(0, org.thirst - hg.Config.GetFloat("organism_thirst_rate") * dt)
	
	-- Starvation/thirst damage
	if org.hunger <= 0 then
		org.health = math.max(0, org.health - 0.5 * dt)
	end
	if org.thirst <= 0 then
		org.health = math.max(0, org.health - 1 * dt)
	end
	
	-- Bleeding
	if org.bleeding and org.bleed_rate > 0 then
		local bloodLoss = org.bleed_rate * dt
		org.blood = math.max(0, org.blood - bloodLoss)
		org.health = math.max(0, org.health - bloodLoss * 0.01)
		
		-- Natural clotting
		org.bleed_rate = math.max(0, org.bleed_rate - 0.5 * dt)
		if org.bleed_rate <= 0 then
			org.bleeding = false
		end
	end
	
	-- Poison
	if org.poisoned and org.poison_level > 0 then
		org.health = math.max(0, org.health - org.poison_level * dt)
		org.poison_level = math.max(0, org.poison_level - 0.1 * dt)
		if org.poison_level <= 0 then
			org.poisoned = false
		end
	end
	
	-- Medications
	for medType, med in pairs(org.medications) do
		if now - med.start > med.duration then
			org.medications[medType] = nil
		else
			-- Apply medication effects
			if medType == "painkiller" then
				org.pain = math.max(0, org.pain - med.strength * 5 * dt)
			elseif medType == "stimulant" then
				org.stamina = math.min(org.maxstamina, org.stamina + med.strength * 10 * dt)
			elseif medType == "coagulant" then
				org.bleed_rate = math.max(0, org.bleed_rate - med.strength * 2 * dt)
			end
		end
	end
	
	-- Pain decay
	org.pain = math.max(0, org.pain - 2 * dt)
	
	-- Unconscious recovery
	if org.unconscious and org.health > 30 and org.pain < 50 and org.blood > 2500 then
		if math.random() < 0.01 * dt then
			hg.Organism.SetUnconscious(ply, false)
		end
	end
	
	-- Temperature regulation
	if org.body_temp < 36 then
		org.body_temp = math.min(37, org.body_temp + 0.1 * dt)
	elseif org.body_temp > 38 then
		org.body_temp = math.max(37, org.body_temp - 0.1 * dt)
	end
	
	org.dirty = true
end

function hg.Organism.MarkDirty(ply)
	local org = hg.GetOrganism(ply)
	if org then org.dirty = true end
end

-- Network sync
function hg.Organism.StartSync(ply)
	if not SERVER then return end
	
	local timerName = "OrganismSync_" .. ply:EntIndex()
	hg.TimerRemove(timerName)
	
	timer.Create(timerName, 1 / hg.Config.GetInt("net_organism_sync_rate"), 0, function()
		if not IsValid(ply) then
			hg.TimerRemove(timerName)
			return
		end
		hg.Organism.Sync(ply)
	end)
	
	local thinkTimer = "OrganismThink_" .. ply:EntIndex()
	timer.Create(thinkTimer, 0.1, 0, function()
		if not IsValid(ply) then
			hg.TimerRemove(thinkTimer)
			return
		end
		hg.Organism.Think(ply)
	end)
end

function hg.Organism.Sync(ply)
	local org = hg.GetOrganism(ply)
	if not org or not org.dirty then return end
	
	-- Compress data for network
	local data = {
		h = math.floor(org.health),
		mh = math.floor(org.maxhealth),
		a = math.floor(org.armor),
		ma = math.floor(org.maxarmor),
		bl = org.bleeding and 1 or 0,
		br = math.floor(org.bleed_rate * 10) / 10,
		p = math.floor(org.pain),
		unc = org.unconscious and 1 or 0,
		s = math.floor(org.stamina * 10) / 10,
		ms = math.floor(org.maxstamina),
		hg = math.floor(org.hunger * 10) / 10,
		th = math.floor(org.thirst * 10) / 10,
		rad = math.floor(org.radiation * 10) / 10,
		psn = org.poisoned and 1 or 0,
		psnl = math.floor(org.poison_level * 10) / 10,
		bld = math.floor(org.blood),
		tmp = math.floor(org.body_temp * 10) / 10,
	}
	
	-- Only send broken bones if changed
	if next(org.broken_bones) then
		data.bb = {}
		for bone, sev in pairs(org.broken_bones) do
			data.bb[bone] = math.floor(sev * 10) / 10
		end
	end
	
	hg.Net.SendPly(ply, "OrganismSync", data)
	org.dirty = false
	org.last_sync = CurTime()
end

-- Client receive
if CLIENT then
	hg.Net.RegisterClient("OrganismSync", function(data)
		local ply = LocalPlayer()
		local org = hg.GetOrganism(ply)
		if not org then
			org = table.Copy(DEFAULT_ORGANISM)
			ply.organism = org
			hg.Organism.Players[ply] = org
		end
		
		org.health = data.h or org.health
		org.maxhealth = data.mh or org.maxhealth
		org.armor = data.a or org.armor
		org.maxarmor = data.ma or org.maxarmor
		org.bleeding = data.bl == 1
		org.bleed_rate = data.br or org.bleed_rate
		org.pain = data.p or org.pain
		org.unconscious = data.unc == 1
		org.stamina = data.s or org.stamina
		org.maxstamina = data.ms or org.maxstamina
		org.hunger = data.hg or org.hunger
		org.thirst = data.th or org.thirst
		org.radiation = data.rad or org.radiation
		org.poisoned = data.psn == 1
		org.poison_level = data.psnl or org.poison_level
		org.blood = data.bld or org.blood
		org.body_temp = data.tmp or org.body_temp
		
		if data.bb then
			org.broken_bones = data.bb
		end
	end)
end

-- Console commands
if SERVER then
	concommand.Add("zc_org_heal", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and target:IsPlayer() then
			hg.Organism.Heal(target, tonumber(args[1]) or 100)
			ply:ChatPrint("Healed " .. target:Name())
		else
			hg.Organism.Heal(ply, tonumber(args[1]) or 100)
			ply:ChatPrint("Healed self")
		end
	end)
	
	concommand.Add("zc_org_damage", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and target:IsPlayer() then
			local dmg = DamageInfo()
			dmg:SetDamage(tonumber(args[1]) or 10)
			dmg:SetDamageType(DMG_BULLET)
			dmg:SetAttacker(ply)
			dmg:SetInflictor(ply)
			dmg:SetHitGroup(HITGROUP_CHEST)
			hg.Organism.TakeDamage(target, dmg)
			ply:ChatPrint("Damaged " .. target:Name())
		end
	end)
	
	concommand.Add("zc_org_debug", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and target:IsPlayer() then
			local org = hg.GetOrganism(target)
			if org then
				PrintTable(org)
			end
		else
			PrintTable(hg.GetOrganism(ply) or {})
		end
	end)
end

hook.Add("EntityTakeDamage", "ZC_OrganismDamage", function(ent, dmgInfo)
	if ent:IsPlayer() then
		hg.Organism.TakeDamage(ent, dmgInfo)
	end
end)

hook.Add("PlayerDeath", "ZC_OrganismDeath", function(ply)
	local org = hg.GetOrganism(ply)
	if org then
		org.health = 0
		org.unconscious = false
		hg.Organism.MarkDirty(ply)
	end
end)

hook.Add("PlayerSpawn", "ZC_OrganismSpawn", function(ply)
	timer.Simple(0.1, function()
		if IsValid(ply) and not hg.GetOrganism(ply) then
			hg.InitOrganism(ply)
		end
	end)
end)

print("[ZC Organism] Organism system loaded")