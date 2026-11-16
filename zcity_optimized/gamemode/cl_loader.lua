-- ZCity Optimized - Client Loader
-- Loads all client-side files

local function LoadClientFiles()
	local files = {
		// Core
		"zcity_optimized/gamemode/shared.lua",
		"zcity_optimized/gamemode/cl_init.lua",
		
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
		
		// UI
		"zcity_optimized/gamemode/ui/cl_inventory.lua",
		"zcity_optimized/gamemode/ui/cl_hud.lua",
	}
	
	for _, file in ipairs(files) do
		include(file)
	end
	
	print("[ZC Client] All client files loaded")
end

LoadClientFiles()

// Console command to reload
concommand.Add("zc_reload_cl", function()
	LoadClientFiles()
	chat.AddText(Color(100, 200, 100), "[ZC] Client reloaded")
end)