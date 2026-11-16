-- ZCity Optimized - Equipment System
-- Weapon attachments, clothing, and gear for Sandbox

hg.Equipment = hg.Equipment or {}
hg.Equipment.Players = {}

-- Equipment slots
hg.Equipment.Slots = {
	"head", "face", "eyes", "ears", "mask",
	"body", "vest", "backpack", "belt",
	"hands", "gloves",
	"legs", "kneepads", "boots",
	"primary", "secondary", "melee", "grenade",
}

-- Slot categories
hg.Equipment.Categories = {
	head = "clothing",
	face = "clothing",
	eyes = "clothing",
	ears = "clothing",
	mask = "clothing",
	body = "clothing",
	vest = "armor",
	backpack = "storage",
	belt = "storage",
	hands = "clothing",
	gloves = "clothing",
	legs = "clothing",
	kneepads = "armor",
	boots = "clothing",
	primary = "weapon",
	secondary = "weapon",
	melee = "weapon",
	grenade = "weapon",
}

-- Equipment definitions
hg.Equipment.Items = {
	-- Headgear
	["helmet_basic"] = {
		name = "Basic Helmet",
		desc = "Light head protection",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "head",
		weight = 1.0,
		armor = 10,
		armor_hitgroups = {HITGROUP_HEAD},
		bonemerge = "models/player/items/humans/helmet.mdl",
	},
	["helmet_tactical"] = {
		name = "Tactical Helmet",
		desc = "Medium head protection with NVG mount",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "head",
		weight = 2.0,
		armor = 25,
		armor_hitgroups = {HITGROUP_HEAD},
		bonemerge = "models/player/items/humans/helmet_tactical.mdl",
	},
	["cap"] = {
		name = "Baseball Cap",
		desc = "Casual headwear",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "head",
		weight = 0.2,
		armor = 0,
		bonemerge = "models/player/items/humans/cap.mdl",
	},
	
	-- Face/Eye protection
	["glasses_tactical"] = {
		name = "Tactical Glasses",
		desc = "Eye protection",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "eyes",
		weight = 0.1,
		armor = 2,
		armor_hitgroups = {HITGROUP_HEAD},
		bonemerge = "models/player/items/humans/glasses_tactical.mdl",
	},
	["nvg"] = {
		name = "Night Vision Goggles",
		desc = "See in the dark",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "eyes",
		weight = 0.5,
		armor = 0,
		special = "nvg",
		bonemerge = "models/player/items/humans/nvg.mdl",
	},
	["mask_gas"] = {
		name = "Gas Mask",
		desc = "Protects from gas and smoke",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "mask",
		weight = 0.8,
		armor = 5,
		armor_hitgroups = {HITGROUP_HEAD},
		special = "gas_immunity",
		bonemerge = "models/player/items/humans/gasmask.mdl",
	},
	["mask_balaclava"] = {
		name = "Balaclava",
		desc = "Face covering",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "mask",
		weight = 0.2,
		armor = 2,
		armor_hitgroups = {HITGROUP_HEAD},
		bonemerge = "models/player/items/humans/balaclava.mdl",
	},
	
	-- Body armor
	["vest_light"] = {
		name = "Light Vest",
		desc = "Light torso protection",
		model = "models/props_junk/cardboard_box001a.mdl",
		slot = "vest",
		weight = 3.0,
		armor = 30,
		armor_hitgroups = {HITGROUP_CHEST, HITGROUP_STOMACH},
		bonemerge = "models/player/items/humans/vest_light.mdl",
	},
	["vest_heavy"] = {
		name = "Heavy Vest",
		desc = "Heavy torso protection with plates",
		model = "models/props_junk/cardboard_box002a.mdl",
		slot = "vest",
		weight = 8.0,
		armor = 75,
		armor_hitgroups = {HITGROUP_CHEST, HITGROUP_STOMACH},
		bonemerge = "models/player/items/humans/vest_heavy.mdl",
	},
	["plate_carrier"] = {
		name = "Plate Carrier",
		desc = "Modular plate carrier",
		model = "models/props_junk/cardboard_box002a.mdl",
		slot = "vest",
		weight = 5.0,
		armor = 50,
		armor_hitgroups = {HITGROUP_CHEST, HITGROUP_STOMACH},
		storage = 4, -- Extra quickslots
		bonemerge = "models/player/items/humans/plate_carrier.mdl",
	},
	
	-- Backpacks
	["backpack_small"] = {
		name = "Small Backpack",
		desc = "+6 inventory slots",
		model = "models/props_junk/cardboard_box001a.mdl",
		slot = "backpack",
		weight = 1.0,
		storage = 6,
		bonemerge = "models/player/items/humans/backpack_small.mdl",
	},
	["backpack_large"] = {
		name = "Large Backpack",
		desc = "+12 inventory slots",
		model = "models/props_junk/cardboard_box002a.mdl",
		slot = "backpack",
		weight = 2.5,
		storage = 12,
		bonemerge = "models/player/items/humans/backpack_large.mdl",
	},
	["backpack_assault"] = {
		name = "Assault Pack",
		desc = "+8 slots, quick access",
		model = "models/props_junk/cardboard_box002a.mdl",
		slot = "backpack",
		weight = 2.0,
		storage = 8,
		quick_access = true,
		bonemerge = "models/player/items/humans/backpack_assault.mdl",
	},
	
	-- Belts
	["belt_tactical"] = {
		name = "Tactical Belt",
		desc = "+4 quickslots",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "belt",
		weight = 0.5,
		quickslots = 4,
		bonemerge = "models/player/items/humans/belt_tactical.mdl",
	},
	["belt_rigger"] = {
		name = "Rigger Belt",
		desc = "+2 quickslots, holster",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "belt",
		weight = 0.8,
		quickslots = 2,
		holster = true,
		bonemerge = "models/player/items/humans/belt_rigger.mdl",
	},
	
	-- Gloves
	["gloves_tactical"] = {
		name = "Tactical Gloves",
		desc = "Hand protection",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "gloves",
		weight = 0.2,
		armor = 3,
		armor_hitgroups = {HITGROUP_LEFTARM, HITGROUP_RIGHTARM},
		bonemerge = "models/player/items/humans/gloves_tactical.mdl",
	},
	
	-- Kneepads
	["kneepads_tactical"] = {
		name = "Tactical Kneepads",
		desc = "Knee protection",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "kneepads",
		weight = 0.5,
		armor = 5,
		armor_hitgroups = {HITGROUP_LEFTLEG, HITGROUP_RIGHTLEG},
		bonemerge = "models/player/items/humans/kneepads.mdl",
	},
	
	-- Boots
	["boots_tactical"] = {
		name = "Tactical Boots",
		desc = "Foot protection, quiet movement",
		model = "models/props_junk/metal_paintcan001a.mdl",
		slot = "boots",
		weight = 1.0,
		armor = 3,
		armor_hitgroups = {HITGROUP_LEFTLEG, HITGROUP_RIGHTLEG},
		special = "quiet_step",
		bonemerge = "models/player/items/humans/boots_tactical.mdl",
	},
}

function hg.Equipment.RegisterItem(class, data)
	data.class = class
	hg.Equipment.Items[class] = data
end

function hg.Equipment.GetItem(class)
	return hg.Equipment.Items[class]
end

function hg.Equipment.Init(ply)
	if not IsValid(ply) then return end
	
	local eq = {
		slots = {},
		bonemerges = {},
		stats = {
			armor = 0,
			armor_hitgroups = {},
			storage = 0,
			quickslots = 0,
			holster = false,
			specials = {},
		},
		dirty = true,
	}
	
	hg.Equipment.Players[ply] = eq
	ply.equipment = eq
	
	if SERVER then
		hg.Net.SetPlayerVar(ply, "equipment", eq)
		hg.Equipment.StartSync(ply)
	end
	
	hook.Run("ZC_EquipmentInitialized", ply, eq)
	return eq
end

function hg.Equipment.Get(ply)
	if not IsValid(ply) then return nil end
	return ply.equipment or hg.Equipment.Players[ply]
end

function hg.Equipment.Cleanup(ply)
	-- Remove bonemerges
	local eq = hg.Equipment.Get(ply)
	if eq and eq.bonemerges then
		for _, ent in pairs(eq.bonemerges) do
			if IsValid(ent) then ent:Remove() end
		end
	end
	
	hg.Equipment.Players[ply] = nil
	if SERVER then
		hg.TimerRemove("EquipmentSync_" .. ply:EntIndex())
	end
end

function hg.Equipment.CanEquip(ply, class, slot)
	local eq = hg.Equipment.Get(ply)
	if not eq then return false end
	
	local item = hg.Equipment.GetItem(class)
	if not item then return false end
	if item.slot ~= slot then return false end
	
	-- Check if slot is occupied
	if eq.slots[slot] then return false end
	
	-- Check weight (optional)
	-- local inv = hg.GetInventory(ply)
	-- if inv and inv.weight + item.weight > inv.maxweight then return false end
	
	return true
end

function hg.Equipment.Equip(ply, class, slot)
	local eq = hg.Equipment.Get(ply)
	if not eq then return false end
	
	if not hg.Equipment.CanEquip(ply, class, slot) then return false end
	
	local item = hg.Equipment.GetItem(class)
	
	-- Unequip current if any
	if eq.slots[slot] then
		hg.Equipment.Unequip(ply, slot)
	end
	
	-- Equip new
	eq.slots[slot] = {
		class = class,
		equipped = CurTime(),
	}
	
	-- Apply stats
	hg.Equipment.ApplyItemStats(ply, item, true)
	
	-- Create bonemerge
	if item.bonemerge and CLIENT then
		hg.Equipment.CreateBonemerge(ply, slot, item.bonemerge)
	end
	
	eq.dirty = true
	
	hook.Run("ZC_EquipmentEquipped", ply, class, slot, item)
	return true
end

function hg.Equipment.Unequip(ply, slot)
	local eq = hg.Equipment.Get(ply)
	if not eq then return false end
	
	local current = eq.slots[slot]
	if not current then return false end
	
	local item = hg.Equipment.GetItem(current.class)
	if not item then return false end
	
	-- Remove stats
	hg.Equipment.ApplyItemStats(ply, item, false)
	
	-- Remove bonemerge
	if item.bonemerge and eq.bonemerges[slot] then
		if IsValid(eq.bonemerges[slot]) then
			eq.bonemerges[slot]:Remove()
		end
		eq.bonemerges[slot] = nil
	end
	
	eq.slots[slot] = nil
	eq.dirty = true
	
	hook.Run("ZC_EquipmentUnequipped", ply, current.class, slot, item)
	return true, current.class
end

function hg.Equipment.ApplyItemStats(ply, item, add)
	local eq = hg.Equipment.Get(ply)
	if not eq or not item then return end
	
	local mult = add and 1 or -1
	
	-- Armor
	if item.armor and item.armor > 0 then
		eq.stats.armor = eq.stats.armor + item.armor * mult
		if item.armor_hitgroups then
			for _, hg in ipairs(item.armor_hitgroups) do
				eq.stats.armor_hitgroups[hg] = (eq.stats.armor_hitgroups[hg] or 0) + item.armor * mult
			end
		end
	end
	
	-- Storage
	if item.storage then
		eq.stats.storage = eq.stats.storage + item.storage * mult
	end
	
	-- Quickslots
	if item.quickslots then
		eq.stats.quickslots = eq.stats.quickslots + item.quickslots * mult
	end
	
	-- Holster
	if item.holster then
		eq.stats.holster = add
	end
	
	// Specials
	if item.special then
		if add then
			eq.stats.specials[item.special] = true
		else
			eq.stats.specials[item.special] = nil
		end
	end
	
	// Update organism armor
	local org = hg.GetOrganism(ply)
	if org then
		org.armor = math.max(0, eq.stats.armor)
		hg.Organism.MarkDirty(ply)
	end
	
	// Update inventory slots
	local inv = hg.GetInventory(ply)
	if inv then
		inv.maxweight = hg.Config.GetInt("inventory_max_weight") + eq.stats.storage
		inv.quickslots_count = hg.Config.GetInt("inventory_quick_slots") + eq.stats.quickslots
		hg.Inventory.MarkDirty(ply)
	end
end

function hg.Equipment.CreateBonemerge(ply, slot, model)
	local eq = hg.Equipment.Get(ply)
	if not eq then return end
	
	if eq.bonemerges[slot] and IsValid(eq.bonemerges[slot]) then
		eq.bonemerges[slot]:Remove()
	end
	
	local ent = ClientsideModel(model, RENDERGROUP_OPAQUE)
	if IsValid(ent) then
		ent:SetParent(ply)
		ent:AddEffects(EF_BONEMERGE)
		ent:AddEffects(EF_BONEMERGE_FASTCULL)
		ent:SetNoDraw(false)
		eq.bonemerges[slot] = ent
	end
end

function hg.Equipment.GetTotalArmor(ply)
	local eq = hg.Equipment.Get(ply)
	if not eq then return 0 end
	return eq.stats.armor
end

function hg.Equipment.GetArmorForHitgroup(ply, hitgroup)
	local eq = hg.Equipment.Get(ply)
	if not eq then return 0 end
	return eq.stats.armor_hitgroups[hitgroup] or 0
end

function hg.Equipment.HasSpecial(ply, special)
	local eq = hg.Equipment.Get(ply)
	if not eq then return false end
	return eq.stats.specials[special] == true
end

-- Network sync
function hg.Equipment.StartSync(ply)
	if not SERVER then return end
	
	local timerName = "EquipmentSync_" .. ply:EntIndex()
	hg.TimerRemove(timerName)
	
	timer.Create(timerName, 1, 0, function()
		if not IsValid(ply) then
			hg.TimerRemove(timerName)
			return
		end
		hg.Equipment.Sync(ply)
	end)
end

function hg.Equipment.Sync(ply)
	local eq = hg.Equipment.Get(ply)
	if not eq or not eq.dirty then return end
	
	local data = {
		slots = {},
		stats = {
			a = eq.stats.armor,
			st = eq.stats.storage,
			qs = eq.stats.quickslots,
			hl = eq.stats.holster and 1 or 0,
		},
	}
	
	for slot, item in pairs(eq.slots) do
		data.slots[slot] = item.class
	end
	
	// Specials
	local specials = {}
	for k, _ in pairs(eq.stats.specials) do
		table.insert(specials, k)
	end
	data.stats.sp = specials
	
	hg.Net.SendPly(ply, "EquipmentSync", data)
	eq.dirty = false
end

if CLIENT then
	hg.Net.RegisterClient("EquipmentSync", function(data)
		local ply = LocalPlayer()
		local eq = hg.Equipment.Get(ply)
		if not eq then
			eq = {slots = {}, bonemerges = {}, stats = {}}
			ply.equipment = eq
			hg.Equipment.Players[ply] = eq
		end
		
		// Clear old bonemerges
		for _, ent in pairs(eq.bonemerges or {}) do
			if IsValid(ent) then ent:Remove() end
		end
		eq.bonemerges = {}
		
		eq.slots = data.slots or {}
		eq.stats.armor = data.stats.a or 0
		eq.stats.storage = data.stats.st or 0
		eq.stats.quickslots = data.stats.qs or 0
		eq.stats.holster = data.stats.hl == 1
		eq.stats.specials = {}
		
		if data.stats.sp then
			for _, sp in ipairs(data.stats.sp) do
				eq.stats.specials[sp] = true
			end
		end
		
		// Create bonemerges
		for slot, class in pairs(eq.slots) do
			local item = hg.Equipment.GetItem(class)
			if item and item.bonemerge then
				hg.Equipment.CreateBonemerge(ply, slot, item.bonemerge)
			end
		end
		
		// Update inventory
		local inv = hg.GetInventory(ply)
		if inv then
			inv.maxweight = hg.Config.GetInt("inventory_max_weight") + eq.stats.storage
			inv.quickslots_count = hg.Config.GetInt("inventory_quick_slots") + eq.stats.quickslots
		end
	end)
end

// Console commands
if SERVER then
	concommand.Add("zc_eq_give", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local class = args[1]
		local slot = args[2]
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and target:IsPlayer() then
			hg.Equipment.Equip(target, class, slot)
			ply:ChatPrint("Equipped " .. class .. " on " .. target:Name())
		else
			hg.Equipment.Equip(ply, class, slot)
			ply:ChatPrint("Equipped " .. class .. " on self")
		end
	end)
	
	concommand.Add("zc_eq_remove", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local slot = args[1]
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and target:IsPlayer() then
			hg.Equipment.Unequip(target, slot)
			ply:ChatPrint("Unequipped " .. slot .. " from " .. target:Name())
		else
			hg.Equipment.Unequip(ply, slot)
			ply:ChatPrint("Unequipped " .. slot .. " from self")
		end
	end)
	
	concommand.Add("zc_eq_debug", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and target:IsPlayer() then
			PrintTable(hg.Equipment.Get(target) or {})
		else
			PrintTable(hg.Equipment.Get(ply) or {})
		end
	end)
end

hook.Add("PlayerSpawn", "ZC_EquipmentSpawn", function(ply)
	timer.Simple(0.1, function()
		if IsValid(ply) and not hg.Equipment.Get(ply) then
			hg.Equipment.Init(ply)
		end
	end)
end)

hook.Add("PlayerDeath", "ZC_EquipmentDeath", function(ply)
	// Optionally drop equipment on death
	// local eq = hg.Equipment.Get(ply)
	// if eq then
	// 	for slot, item in pairs(eq.slots) do
	// 		hg.Equipment.Unequip(ply, slot)
	// 	end
	// end
end)

print("[ZC Equipment] Equipment system loaded")