-- ZCity Optimized - Inventory System
-- Lightweight grid-based inventory for Sandbox

hg.Inventory = hg.Inventory or {}
hg.Inventory.Players = {}

-- Item definitions (minimal set for sandbox)
hg.Inventory.Items = {
	-- Medical
	["medkit"] = {
		name = "Medical Kit",
		desc = "Restores 50 health",
		model = "models/items/healthkit.mdl",
		weight = 1.5,
		stack = 3,
		type = "medical",
		use = function(ply, item) hg.Organism.Heal(ply, 50) return true end,
	},
	["bandage"] = {
		name = "Bandage",
		desc = "Stops bleeding",
		model = "models/props_junk/garbage_gauze001a.mdl",
		weight = 0.1,
		stack = 10,
		type = "medical",
		use = function(ply, item) hg.Organism.StopBleeding(ply) return true end,
	},
	["painkillers"] = {
		name = "Painkillers",
		desc = "Reduces pain for 60 seconds",
		model = "models/props_lab/jar01b.mdl",
		weight = 0.2,
		stack = 5,
		type = "medical",
		use = function(ply, item) hg.Organism.ApplyMedication(ply, "painkiller", 60, 1) return true end,
	},
	["bloodbag"] = {
		name = "Blood Bag",
		desc = "Restores 1000 blood",
		model = "models/props_junk/garbage_bag001a.mdl",
		weight = 0.5,
		stack = 3,
		type = "medical",
		use = function(ply, item) hg.Organism.Heal(ply, 0, "blood") return true end,
	},
	
	-- Ammo
	["ammo_pistol"] = {
		name = "Pistol Ammo",
		desc = "9x19mm rounds",
		model = "models/items/boxsrounds.mdl",
		weight = 0.5,
		stack = 60,
		type = "ammo",
		ammo_type = "pistol",
		ammo_count = 30,
	},
	["ammo_rifle"] = {
		name = "Rifle Ammo",
		desc = "5.56x45mm rounds",
		model = "models/items/boxmrounds.mdl",
		weight = 0.8,
		stack = 60,
		type = "ammo",
		ammo_type = "smg1",
		ammo_count = 30,
	},
	["ammo_shotgun"] = {
		name = "Shotgun Ammo",
		desc = "12 gauge shells",
		model = "models/items/boxbuckshot.mdl",
		weight = 1.0,
		stack = 20,
		type = "ammo",
		ammo_type = "buckshot",
		ammo_count = 12,
	},
	["ammo_sniper"] = {
		name = "Sniper Ammo",
		desc = "7.62x51mm rounds",
		model = "models/items/boxmrounds.mdl",
		weight = 1.2,
		stack = 20,
		type = "ammo",
		ammo_type = "357",
		ammo_count = 10,
	},
	
	-- Weapons (spawn as entities)
	["weapon_pistol"] = {
		name = "Pistol",
		desc = "Standard sidearm",
		model = "models/weapons/w_pist_glock18.mdl",
		weight = 1.0,
		stack = 1,
		type = "weapon",
		weapon_class = "weapon_pistol",
	},
	["weapon_smg"] = {
		name = "SMG",
		desc = "Submachine gun",
		model = "models/weapons/w_smg1.mdl",
		weight = 2.5,
		stack = 1,
		type = "weapon",
		weapon_class = "weapon_smg1",
	},
	["weapon_shotgun"] = {
		name = "Shotgun",
		desc = "Pump action shotgun",
		model = "models/weapons/w_shotgun.mdl",
		weight = 3.5,
		stack = 1,
		type = "weapon",
		weapon_class = "weapon_shotgun",
	},
	["weapon_rifle"] = {
		name = "Assault Rifle",
		desc = "Standard assault rifle",
		model = "models/weapons/w_rif_ak47.mdl",
		weight = 3.8,
		stack = 1,
		type = "weapon",
		weapon_class = "weapon_ar2",
	},
	
	-- Consumables
	["water"] = {
		name = "Water Bottle",
		desc = "Restores 30 thirst",
		model = "models/props_junk/garbage_plasticbottle003a.mdl",
		weight = 0.5,
		stack = 5,
		type = "consumable",
		use = function(ply, item)
			local org = hg.GetOrganism(ply)
			if org then org.thirst = math.min(100, org.thirst + 30) end
			return true
		end,
	},
	["food"] = {
		name = "Canned Food",
		desc = "Restores 40 hunger",
		model = "models/props_junk/garbage_metalcan001a.mdl",
		weight = 0.4,
		stack = 5,
		type = "consumable",
		use = function(ply, item)
			local org = hg.GetOrganism(ply)
			if org then org.hunger = math.min(100, org.hunger + 40) end
			return true
		end,
	},
	
	-- Equipment
	["armor_light"] = {
		name = "Light Armor",
		desc = "Provides 30 armor",
		model = "models/props_junk/cardboard_box001a.mdl",
		weight = 3.0,
		stack = 1,
		type = "equipment",
		use = function(ply, item)
			local org = hg.GetOrganism(ply)
			if org then org.armor = math.min(100, org.armor + 30) end
			return true
		end,
	},
	["armor_heavy"] = {
		name = "Heavy Armor",
		desc = "Provides 75 armor",
		model = "models/props_junk/cardboard_box002a.mdl",
		weight = 8.0,
		stack = 1,
		type = "equipment",
		use = function(ply, item)
			local org = hg.GetOrganism(ply)
			if org then org.armor = math.min(100, org.armor + 75) end
			return true
		end,
	},
	
	-- Attachments
	["att_optic_reddot"] = {
		name = "Red Dot Sight",
		desc = "Improves accuracy",
		model = "models/props_lab/huladoll.mdl",
		weight = 0.2,
		stack = 1,
		type = "attachment",
		slot = "optic",
	},
	["att_suppressor"] = {
		name = "Suppressor",
		desc = "Reduces noise and muzzle flash",
		model = "models/props_c17/oildrum001.mdl",
		weight = 0.5,
		stack = 1,
		type = "attachment",
		slot = "muzzle",
	},
	["att_grip"] = {
		name = "Foregrip",
		desc = "Reduces recoil",
		model = "models/props_junk/wood_crate001a.mdl",
		weight = 0.3,
		stack = 1,
		type = "attachment",
		slot = "grip",
	},
	["att_laser"] = {
		name = "Laser Sight",
		desc = "Improves hip fire accuracy",
		model = "models/props_lab/tpplug.mdl",
		weight = 0.1,
		stack = 1,
		type = "attachment",
		slot = "tactical",
	},
}

-- Register item
function hg.Inventory.RegisterItem(class, data)
	data.class = class
	hg.Inventory.Items[class] = data
end

function hg.Inventory.GetItem(class)
	return hg.Inventory.Items[class]
end

-- Create inventory for player
function hg.CreateInventory(ply)
	if not IsValid(ply) then return end
	if not hg.Config.GetBool("inventory_enable") then return end
	
	local inv = {
		slots = {},
		quickslots = {},
		weight = 0,
		maxweight = hg.Config.GetInt("inventory_max_weight"),
		slots_count = hg.Config.GetInt("inventory_slots"),
		quickslots_count = hg.Config.GetInt("inventory_quick_slots"),
		owner = ply,
		dirty = true,
		last_sync = 0,
	}
	
	-- Initialize quickslots
	for i = 1, inv.quickslots_count do
		inv.quickslots[i] = nil
	end
	
	hg.Inventory.Players[ply] = inv
	ply.inventory = inv
	
	if SERVER then
		hg.Net.SetPlayerVar(ply, "inventory", inv)
		hg.Inventory.StartSync(ply)
	end
	
	hook.Run("ZC_InventoryCreated", ply, inv)
	return inv
end

function hg.GetInventory(ply)
	if not IsValid(ply) then return nil end
	return ply.inventory or hg.Inventory.Players[ply]
end

function hg.CleanupInventory(ply)
	hg.Inventory.Players[ply] = nil
	if SERVER then
		hg.TimerRemove("InventorySync_" .. ply:EntIndex())
	end
end

-- Weight calculation
function hg.Inventory.CalculateWeight(inv)
	local weight = 0
	for slot, item in pairs(inv.slots) do
		local itemData = hg.Inventory.GetItem(item.class)
		if itemData then
			weight = weight + (itemData.weight * (item.count or 1))
		end
	end
	inv.weight = weight
	return weight
end

function hg.Inventory.GetFreeWeight(inv)
	return inv.maxweight - inv.weight
end

function hg.Inventory.IsOverweight(inv)
	return inv.weight > inv.maxweight
end

-- Slot management
function hg.Inventory.FindSlot(inv, class, count)
	count = count or 1
	local itemData = hg.Inventory.GetItem(class)
	if not itemData then return nil end
	
	-- Try to stack
	if itemData.stack and itemData.stack > 1 then
		for slot, item in pairs(inv.slots) do
			if item.class == class and item.count < itemData.stack then
				local canAdd = itemData.stack - item.count
				if canAdd >= count then return slot, canAdd end
			end
		end
	end
	
	-- Find empty slot
	for i = 1, inv.slots_count do
		if not inv.slots[i] then return i, itemData.stack or 1 end
	end
	
	return nil
end

function hg.Inventory.AddItem(ply, class, count, itemData)
	local inv = hg.GetInventory(ply)
	if not inv then return false, "No inventory" end
	
	count = count or 1
	local itemDef = hg.Inventory.GetItem(class)
	if not itemDef then return false, "Invalid item" end
	
	-- Check weight
	local totalWeight = itemDef.weight * count
	if inv.weight + totalWeight > inv.maxweight then
		return false, "Overweight"
	end
	
	-- Find slot
	local slot, maxStack = hg.Inventory.FindSlot(inv, class, count)
	if not slot then return false, "Inventory full" end
	
	-- Add to existing stack or create new
	if inv.slots[slot] and inv.slots[slot].class == class then
		inv.slots[slot].count = inv.slots[slot].count + count
		if itemData then
			hg.TableMerge(inv.slots[slot].data or {}, itemData)
		end
	else
		inv.slots[slot] = {
			class = class,
			count = count,
			data = itemData or {},
			slot = slot,
		}
	end
	
	inv.weight = inv.weight + totalWeight
	inv.dirty = true
	
	hook.Run("ZC_ItemAdded", ply, class, count, slot)
	return true, slot
end

function hg.Inventory.RemoveItem(ply, slot, count)
	local inv = hg.GetInventory(ply)
	if not inv then return false end
	
	local item = inv.slots[slot]
	if not item then return false end
	
	count = count or item.count
	local itemDef = hg.Inventory.GetItem(item.class)
	
	if item.count <= count then
		inv.slots[slot] = nil
	else
		item.count = item.count - count
	end
	
	if itemDef then
		inv.weight = math.max(0, inv.weight - itemDef.weight * count)
	end
	
	inv.dirty = true
	
	hook.Run("ZC_ItemRemoved", ply, item.class, count, slot)
	return true, item.class, count
end

function hg.Inventory.MoveItem(ply, fromSlot, toSlot)
	local inv = hg.GetInventory(ply)
	if not inv then return false end
	
	if fromSlot == toSlot then return false end
	
	local fromItem = inv.slots[fromSlot]
	local toItem = inv.slots[toSlot]
	
	if not fromItem then return false end
	
	-- Swap or merge
	if toItem and toItem.class == fromItem.class then
		local itemDef = hg.Inventory.GetItem(fromItem.class)
		if itemDef and itemDef.stack > 1 then
			local canAdd = itemDef.stack - toItem.count
			if canAdd >= fromItem.count then
				toItem.count = toItem.count + fromItem.count
				inv.slots[fromSlot] = nil
				inv.dirty = true
				return true
			elseif canAdd > 0 then
				toItem.count = toItem.count + canAdd
				fromItem.count = fromItem.count - canAdd
				inv.dirty = true
				return true
			end
		end
	end
	
	-- Swap
	inv.slots[fromSlot], inv.slots[toSlot] = inv.slots[toSlot], inv.slots[fromSlot]
	if inv.slots[fromSlot] then inv.slots[fromSlot].slot = fromSlot end
	if inv.slots[toSlot] then inv.slots[toSlot].slot = toSlot end
	
	inv.dirty = true
	return true
end

function hg.Inventory.UseItem(ply, slot)
	local inv = hg.GetInventory(ply)
	if not inv then return false end
	
	local item = inv.slots[slot]
	if not item then return false end
	
	local itemDef = hg.Inventory.GetItem(item.class)
	if not itemDef or not itemDef.use then return false end
	
	local success = itemDef.use(ply, item)
	if success then
		hg.Inventory.RemoveItem(ply, slot, 1)
	end
	
	return success
end

function hg.Inventory.DropItem(ply, slot, count)
	local inv = hg.GetInventory(ply)
	if not inv then return false end
	
	local success, class, removedCount = hg.Inventory.RemoveItem(ply, slot, count)
	if not success then return false end
	
	-- Spawn entity
	local itemDef = hg.Inventory.GetItem(class)
	local ent = ents.Create("zc_item")
	if IsValid(ent) then
		ent:SetPos(ply:GetShootPos() + ply:GetAimVector() * 50)
		ent:SetAngles(ply:EyeAngles())
		ent:Spawn()
		ent:SetItemClass(class, removedCount)
		ent:GetPhysicsObject():SetVelocity(ply:GetAimVector() * 200 + Vector(0, 0, 100))
	end
	
	return true
end

function hg.Inventory.SetQuickslot(ply, quickslot, invSlot)
	local inv = hg.GetInventory(ply)
	if not inv then return false end
	
	if quickslot < 1 or quickslot > inv.quickslots_count then return false end
	
	if invSlot == 0 or invSlot == nil then
		inv.quickslots[quickslot] = nil
	else
		if not inv.slots[invSlot] then return false end
		inv.quickslots[quickslot] = invSlot
	end
	
	inv.dirty = true
	return true
end

function hg.Inventory.UseQuickslot(ply, quickslot)
	local inv = hg.GetInventory(ply)
	if not inv then return false end
	
	local invSlot = inv.quickslots[quickslot]
	if not invSlot then return false end
	
	return hg.Inventory.UseItem(ply, invSlot)
end

-- Give weapon from inventory
function hg.Inventory.GiveWeapon(ply, slot)
	local inv = hg.GetInventory(ply)
	if not inv then return false end
	
	local item = inv.slots[slot]
	if not item then return false end
	
	local itemDef = hg.Inventory.GetItem(item.class)
	if not itemDef or itemDef.type ~= "weapon" then return false end
	
	-- Check if already have
	if hg.HasWeapon(ply, itemDef.weapon_class) then return false end
	
	hg.GiveWeapon(ply, itemDef.weapon_class)
	hg.Inventory.RemoveItem(ply, slot, 1)
	
	return true
end

-- Ammo handling
function hg.Inventory.GiveAmmo(ply, slot)
	local inv = hg.GetInventory(ply)
	if not inv then return false end
	
	local item = inv.slots[slot]
	if not item then return false end
	
	local itemDef = hg.Inventory.GetItem(item.class)
	if not itemDef or itemDef.type ~= "ammo" then return false end
	
	ply:GiveAmmo(itemDef.ammo_count, itemDef.ammo_type, true)
	hg.Inventory.RemoveItem(ply, slot, 1)
	
	return true
end

-- Network sync
function hg.Inventory.StartSync(ply)
	if not SERVER then return end
	
	local timerName = "InventorySync_" .. ply:EntIndex()
	hg.TimerRemove(timerName)
	
	timer.Create(timerName, 1 / hg.Config.GetInt("net_inventory_sync_rate"), 0, function()
		if not IsValid(ply) then
			hg.TimerRemove(timerName)
			return
		end
		hg.Inventory.Sync(ply)
	end)
end

function hg.Inventory.Sync(ply, full)
	local inv = hg.GetInventory(ply)
	if not inv or (not inv.dirty and not full) then return end
	
	local data = {
		full = full and 1 or 0,
		w = math.floor(inv.weight * 10) / 10,
		mw = inv.maxweight,
		sc = inv.slots_count,
		qsc = inv.quickslots_count,
		slots = {},
		qs = {},
	}
	
	for slot, item in pairs(inv.slots) do
		data.slots[slot] = {
			c = item.class,
			n = item.count,
			d = item.data or {},
		}
	end
	
	for qs, slot in pairs(inv.quickslots) do
		data.qs[qs] = slot
	end
	
	hg.Net.SendPly(ply, "InventorySync", data)
	inv.dirty = false
	inv.last_sync = CurTime()
end

-- Client receive
if CLIENT then
	hg.Net.RegisterClient("InventorySync", function(data)
		local ply = LocalPlayer()
		local inv = hg.GetInventory(ply)
		if not inv then
			inv = {slots = {}, quickslots = {}}
			ply.inventory = inv
			hg.Inventory.Players[ply] = inv
		end
		
		if data.full then
			inv.slots = {}
			inv.quickslots = {}
		end
		
		inv.weight = data.w
		inv.maxweight = data.mw
		inv.slots_count = data.sc
		inv.quickslots_count = data.qsc
		
		if data.slots then
			for slot, item in pairs(data.slots) do
				inv.slots[tonumber(slot)] = {
					class = item.c,
					count = item.n,
					data = item.d,
					slot = tonumber(slot),
				}
			end
		end
		
		if data.qs then
			for qs, slot in pairs(data.qs) do
				inv.quickslots[tonumber(qs)] = tonumber(slot)
			end
		end
		
		hook.Run("ZC_InventoryUpdated", ply, inv)
	end)
end

-- Console commands
if SERVER then
	concommand.Add("zc_inv_give", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local class = args[1]
		local count = tonumber(args[2]) or 1
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and target:IsPlayer() then
			hg.Inventory.AddItem(target, class, count)
			ply:ChatPrint("Gave " .. count .. "x " .. class .. " to " .. target:Name())
		else
			hg.Inventory.AddItem(ply, class, count)
			ply:ChatPrint("Gave " .. count .. "x " .. class .. " to self")
		end
	end)
	
	concommand.Add("zc_inv_clear", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and target:IsPlayer() then
			target.inventory = {slots = {}, quickslots = {}, weight = 0}
			hg.Inventory.StartSync(target)
			ply:ChatPrint("Cleared " .. target:Name() .. "'s inventory")
		else
			ply.inventory = {slots = {}, quickslots = {}, weight = 0}
			hg.Inventory.StartSync(ply)
			ply:ChatPrint("Cleared own inventory")
		end
	end)
	
	concommand.Add("zc_inv_debug", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and target:IsPlayer() then
			PrintTable(hg.GetInventory(target) or {})
		else
			PrintTable(hg.GetInventory(ply) or {})
		end
	end)
end

-- Item entity
if SERVER then
	local ENT = {}
	ENT.Type = "anim"
	ENT.Base = "base_gmodentity"
	ENT.PrintName = "ZC Item"
	ENT.Author = "ZCity Optimized"
	ENT.Spawnable = false
	ENT.AdminSpawnable = false
	
	function ENT:SetupDataTables()
		self:NetworkVar("String", 0, "ItemClass")
		self:NetworkVar("Int", 0, "ItemCount")
	end
	
	function ENT:SetItemClass(class, count)
		self:SetItemClass(class)
		self:SetItemCount(count or 1)
		
		local itemDef = hg.Inventory.GetItem(class)
		if itemDef and itemDef.model then
			self:SetModel(itemDef.model)
		else
			self:SetModel("models/props_junk/cardboard_box001a.mdl")
		end
		
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
		end
	end
	
	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		
		local class = self:GetItemClass()
		local count = self:GetItemCount()
		
		local success = hg.Inventory.AddItem(activator, class, count)
		if success then
			self:EmitSound("items/ammo_pickup.wav", 50, 100, 0.5)
			self:Remove()
		else
			activator:ChatPrint("Inventory full or overweight!")
		end
	end
	
	scripted_ents.Register(ENT, "zc_item")
end

hook.Add("PlayerSpawn", "ZC_InventorySpawn", function(ply)
	timer.Simple(0.1, function()
		if IsValid(ply) and not hg.GetInventory(ply) then
			hg.CreateInventory(ply)
		end
	end)
end)

hook.Add("PlayerDeath", "ZC_InventoryDeath", function(ply)
	-- Drop all items on death (optional)
	-- local inv = hg.GetInventory(ply)
	-- if inv then
	-- 	for slot, item in pairs(inv.slots) do
	-- 		hg.Inventory.DropItem(ply, slot)
	-- 	end
	-- end
end)

print("[ZC Inventory] Inventory system loaded")