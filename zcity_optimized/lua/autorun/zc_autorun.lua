-- ZCity Optimized - Sandbox Addon Autorun
-- Loads ZCity systems as a Sandbox addon

if not ZC_OPTIMIZED_LOADED then
	ZC_OPTIMIZED_LOADED = true
	print("[ZC Optimized] Loading as Sandbox addon...")
	
	// Create global tables early
	zb = zb or {}
	hg = hg or {}
	
	// Load shared files first
	include("zcity_optimized/gamemode/shared.lua")
	include("zcity_optimized/gamemode/libraries/sh_util.lua")
	include("zcity_optimized/gamemode/libraries/sh_net.lua")
	include("zcity_optimized/gamemode/libraries/sh_config.lua")
	include("zcity_optimized/gamemode/systems/sh_organism.lua")
	include("zcity_optimized/gamemode/systems/sh_inventory.lua")
	include("zcity_optimized/gamemode/systems/sh_movement.lua")
	include("zcity_optimized/gamemode/systems/sh_equipment.lua")
	include("zcity_optimized/gamemode/weapons/sh_base.lua")
	include("zcity_optimized/gamemode/weapons/weapon_pistol.lua")
	include("zcity_optimized/gamemode/weapons/weapon_rifle.lua")
	
	if SERVER then
		// Network strings
		util.AddNetworkString("ZC_OrganismSync")
		util.AddNetworkString("ZC_InventorySync")
		util.AddNetworkString("ZC_MovementSync")
		util.AddNetworkString("ZC_EquipmentSync")
		util.AddNetworkString("ZC_Effect")
		util.AddNetworkString("ZC_Hitmarker")
		util.AddNetworkString("ZC_EntVar")
		util.AddNetworkString("ZC_Net_")
		
		// AddCSLuaFile for client
		AddCSLuaFile("zcity_optimized/gamemode/shared.lua")
		AddCSLuaFile("zcity_optimized/gamemode/libraries/sh_util.lua")
		AddCSLuaFile("zcity_optimized/gamemode/libraries/sh_net.lua")
		AddCSLuaFile("zcity_optimized/gamemode/libraries/sh_config.lua")
		AddCSLuaFile("zcity_optimized/gamemode/systems/sh_organism.lua")
		AddCSLuaFile("zcity_optimized/gamemode/systems/sh_inventory.lua")
		AddCSLuaFile("zcity_optimized/gamemode/systems/sh_movement.lua")
		AddCSLuaFile("zcity_optimized/gamemode/systems/sh_equipment.lua")
		AddCSLuaFile("zcity_optimized/gamemode/weapons/sh_base.lua")
		AddCSLuaFile("zcity_optimized/gamemode/weapons/weapon_pistol.lua")
		AddCSLuaFile("zcity_optimized/gamemode/weapons/weapon_rifle.lua")
		AddCSLuaFile("zcity_optimized/gamemode/ui/cl_inventory.lua")
		AddCSLuaFile("zcity_optimized/gamemode/ui/cl_hud.lua")
		AddCSLuaFile("zcity_optimized/lua/autorun/zc_autorun.lua")
		
		// Sandbox compatibility - don't block spawns
		local function AllowSandbox(ply)
			if game.SinglePlayer() or ply:IsAdmin() then return true end
		end
		
		hook.Add("PlayerSpawnObject", "ZC_SandboxAllow", AllowSandbox)
		hook.Add("PlayerSpawnSENT", "ZC_SandboxAllow", AllowSandbox)
		hook.Add("PlayerSpawnSWEP", "ZC_SandboxAllow", AllowSandbox)
		hook.Add("PlayerGiveSWEP", "ZC_SandboxAllow", AllowSandbox)
		hook.Add("PlayerSpawnVehicle", "ZC_SandboxAllow", AllowSandbox)
		hook.Add("PlayerSpawnNPC", "ZC_SandboxAllow", AllowSandbox)
		hook.Add("PlayerSpawnProp", "ZC_SandboxAllow", AllowSandbox)
		hook.Add("PlayerSpawnEffect", "ZC_SandboxAllow", AllowSandbox)
		hook.Add("PlayerSpawnRagdoll", "ZC_SandboxAllow", AllowSandbox)
		
		hook.Add("PlayerNoClip", "ZC_AdminNoclip", function(ply, desired)
			if desired == false then return true end
			if ply:IsAdmin() then return true end
			return false
		end)
		
		// Initialize systems on spawn
		hook.Add("PlayerInitialSpawn", "ZC_InitSystems", function(ply)
			timer.Simple(0.5, function()
				if IsValid(ply) then
					hg.InitOrganism(ply)
					hg.CreateInventory(ply)
					hg.Movement.Init(ply)
					hg.Equipment.Init(ply)
				end
			end)
		end)
		
		hook.Add("PlayerDisconnected", "ZC_CleanupSystems", function(ply)
			hg.CleanupPlayer(ply)
			hg.CleanupInventory(ply)
			hg.Movement.Cleanup(ply)
			hg.Equipment.Cleanup(ply)
		end)
		
		print("[ZC Optimized] Server addon loaded")
	else
		// Client includes
		include("zcity_optimized/gamemode/cl_init.lua")
		include("zcity_optimized/gamemode/ui/cl_inventory.lua")
		include("zcity_optimized/gamemode/ui/cl_hud.lua")
		
		print("[ZC Optimized] Client addon loaded")
	end
	
	print("[ZC Optimized] Addon fully loaded v2.0.0")
end

// Console commands for addon
concommand.Add("zc_reload", function(ply)
	if SERVER then
		if IsValid(ply) and not ply:IsAdmin() then return end
		ZC_OPTIMIZED_LOADED = nil
		include("zcity_optimized/lua/autorun/zc_autorun.lua")
		if IsValid(ply) then ply:ChatPrint("[ZC] Reloaded") end
	else
		ZC_OPTIMIZED_LOADED = nil
		include("zcity_optimized/lua/autorun/zc_autorun.lua")
		chat.AddText(Color(100, 200, 100), "[ZC] Reloaded")
	end
end)