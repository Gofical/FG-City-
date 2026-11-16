-- ZCity Optimized - Server Loader
-- Loads all server-side files and registers network strings

local function LoadServerFiles()
	local files = {
		// Core
		"zcity_optimized/gamemode/init.lua",
		"zcity_optimized/gamemode/shared.lua",
		
		// Libraries
		"zcity_optimized/gamemode/libraries/sh_util.lua",
		"zcity_optimized/gamemode/libraries/sh_net.lua",
		"zcity_optimized/gamemode/libraries/sh_config.lua",
		
		// Systems
		"zcity_optimized/gamemode/systems/sh_organism.lua",
		"zcity_optimized/gamemode/systems/sh_inventory.lua",
		"zcity_optimized/gamemode/systems/sh_movement.lua",
		"zcity_optimized/gamemode/systems/sh_equipment.lua",
		
		// Weapons
		"zcity_optimized/gamemode/weapons/sh_base.lua",
		"zcity_optimized/gamemode/weapons/weapon_pistol.lua",
		"zcity_optimized/gamemode/weapons/weapon_rifle.lua",
	}
	
	for _, file in ipairs(files) do
		include(file)
	end
	
	print("[ZC Server] All server files loaded")
end

// Network strings (must be registered before include)
util.AddNetworkString("ZC_OrganismSync")
util.AddNetworkString("ZC_InventorySync")
util.AddNetworkString("ZC_MovementSync")
util.AddNetworkString("ZC_EquipmentSync")
util.AddNetworkString("ZC_Effect")
util.AddNetworkString("ZC_Hitmarker")
util.AddNetworkString("ZC_EntVar")

// Console command to reload
concommand.Add("zc_reload_sv", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end
	LoadServerFiles()
	if IsValid(ply) then
		ply:ChatPrint("[ZC] Server reloaded")
	else
		print("[ZC] Server reloaded (console)")
	end
end)

LoadServerFiles()

// Cleanup on shutdown
hook.Add("ShutDown", "ZC_Cleanup", function()
	for _, ply in ipairs(player.GetAll()) do
		hg.CleanupPlayer(ply)
		hg.CleanupInventory(ply)
		hg.Movement.Cleanup(ply)
		hg.Equipment.Cleanup(ply)
	end
end)