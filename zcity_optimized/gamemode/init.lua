-- ZCity Optimized - Server Init
-- Lightweight Sandbox-compatible gamemode core

zb = zb or {}
hg = hg or {}

-- Derive from Sandbox for maximum compatibility
DeriveGamemode("sandbox")

-- Core version
zb.Version = "2.0.0"
zb.BuildDate = "2026-11-16"

-- Network strings (minimal set)
util.AddNetworkString("ZC_OrganismSync")
util.AddNetworkString("ZC_InventorySync")
util.AddNetworkString("ZC_MovementSync")
util.AddNetworkString("ZC_EquipmentSync")
util.AddNetworkString("ZC_Effect")
util.AddNetworkString("ZC_Hitmarker")
util.AddNetworkString("ZC_EntVar")
util.AddNetworkString("ZC_Net_")

-- Load core libraries first
include("zcity_optimized/gamemode/libraries/sh_util.lua")
include("zcity_optimized/gamemode/libraries/sh_net.lua")
include("zcity_optimized/gamemode/libraries/sh_config.lua")

-- Load systems
include("zcity_optimized/gamemode/systems/sh_organism.lua")
include("zcity_optimized/gamemode/systems/sh_inventory.lua")
include("zcity_optimized/gamemode/systems/sh_movement.lua")
include("zcity_optimized/gamemode/systems/sh_equipment.lua")

-- Load weapons
include("zcity_optimized/gamemode/weapons/sh_base.lua")
include("zcity_optimized/gamemode/weapons/weapon_pistol.lua")
include("zcity_optimized/gamemode/weapons/weapon_rifle.lua")

-- Load client files
AddCSLuaFile("zcity_optimized/gamemode/cl_init.lua")
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

-- Sandbox: Don't block spawns for admins/singleplayer
hook.Add("PlayerSpawnObject", "ZC_SandboxAllow", function(ply)
	if game.SinglePlayer() or ply:IsAdmin() then return true end
end)

hook.Add("PlayerSpawnSENT", "ZC_SandboxAllow", function(ply)
	if game.SinglePlayer() or ply:IsAdmin() then return true end
end)

hook.Add("PlayerSpawnSWEP", "ZC_SandboxAllow", function(ply)
	if game.SinglePlayer() or ply:IsAdmin() then return true end
end)

hook.Add("PlayerGiveSWEP", "ZC_SandboxAllow", function(ply)
	if game.SinglePlayer() or ply:IsAdmin() then return true end
end)

hook.Add("PlayerSpawnVehicle", "ZC_SandboxAllow", function(ply)
	if game.SinglePlayer() or ply:IsAdmin() then return true end
end)

hook.Add("PlayerSpawnNPC", "ZC_SandboxAllow", function(ply)
	if game.SinglePlayer() or ply:IsAdmin() then return true end
end)

hook.Add("PlayerSpawnProp", "ZC_SandboxAllow", function(ply)
	if game.SinglePlayer() or ply:IsAdmin() then return true end
end)

hook.Add("PlayerSpawnEffect", "ZC_SandboxAllow", function(ply)
	if game.SinglePlayer() or ply:IsAdmin() then return true end
end)

hook.Add("PlayerSpawnRagdoll", "ZC_SandboxAllow", function(ply)
	if game.SinglePlayer() or ply:IsAdmin() then return true end
end)

-- Noclip for admins
hook.Add("PlayerNoClip", "ZC_AdminNoclip", function(ply, desired)
	if desired == false then return true end
	if ply:IsAdmin() then return true end
	return false
end)

-- Initialize organism for all players
hook.Add("PlayerInitialSpawn", "ZC_InitOrganism", function(ply)
	timer.Simple(0.5, function()
		if IsValid(ply) then
			hg.InitOrganism(ply)
			hg.CreateInventory(ply)
			hg.Movement.Init(ply)
			hg.Equipment.Init(ply)
		end
	end)
end)

-- Cleanup on disconnect
hook.Add("PlayerDisconnected", "ZC_Cleanup", function(ply)
	hg.CleanupPlayer(ply)
	hg.CleanupInventory(ply)
	hg.Movement.Cleanup(ply)
	hg.Equipment.Cleanup(ply)
end)

print("[ZCity Optimized] Server core loaded v" .. zb.Version)