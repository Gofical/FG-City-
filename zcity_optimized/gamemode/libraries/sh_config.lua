-- ZCity Optimized - Configuration System
-- Lightweight config with validation and defaults

hg.Config = hg.Config or {}
hg.Config.Values = {}
hg.Config.Defaults = {}
hg.Config.Validators = {}
hg.Config.Callbacks = {}

-- Define a config value
function hg.Config.Define(key, default, validator, help, min, max)
	hg.Config.Defaults[key] = default
	hg.Config.Values[key] = default
	hg.Config.Validators[key] = validator
	hg.Config.Callbacks[key] = hg.Config.Callbacks[key] or {}
	
	if SERVER then
		local flags = FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY
		CreateConVar("zc_" .. key, tostring(default), flags, help or "", min, max)
		cvars.AddChangeCallback("zc_" .. key, function(cvar, old, new)
			hg.Config.OnConVarChanged(key, old, new)
		end, "ZC_Config_" .. key)
	else
		hg.Config.Values[key] = GetConVar("zc_" .. key):GetFloat()
	end
end

-- Get config value
function hg.Config.Get(key)
	return hg.Config.Values[key]
end

function hg.Config.GetBool(key)
	return hg.Config.Values[key] == true or hg.Config.Values[key] == 1
end

function hg.Config.GetInt(key)
	return math.floor(hg.Config.Values[key] or 0)
end

function hg.Config.GetFloat(key)
	return tonumber(hg.Config.Values[key]) or 0
end

function hg.Config.GetString(key)
	return tostring(hg.Config.Values[key] or "")
end

-- Set config value (server only)
function hg.Config.Set(key, value)
	if not SERVER then return false end
	
	local validator = hg.Config.Validators[key]
	if validator and not validator(value) then
		hg.DebugPrint("Config validation failed for " .. key)
		return false
	end
	
	local old = hg.Config.Values[key]
	hg.Config.Values[key] = value
	
	RunConsoleCommand("zc_" .. key, tostring(value))
	
	hg.Config.FireCallbacks(key, old, value)
	return true
end

-- Register callback
function hg.Config.OnChange(key, callback, id)
	id = id or "default"
	hg.Config.Callbacks[key][id] = callback
end

function hg.Config.RemoveCallback(key, id)
	id = id or "default"
	hg.Config.Callbacks[key][id] = nil
end

function hg.Config.FireCallbacks(key, old, new)
	for id, callback in pairs(hg.Config.Callbacks[key] or {}) do
		local ok, err = pcall(callback, old, new)
		if not ok then
			ErrorNoHalt("[ZC Config] Callback error for " .. key .. ": " .. err .. "\n")
		end
	end
end

function hg.Config.OnConVarChanged(key, old, new)
	local numVal = tonumber(new)
	if numVal then new = numVal end
	
	hg.Config.Values[key] = new
	hg.Config.FireCallbacks(key, old, new)
end

-- Reset to defaults
function hg.Config.Reset(key)
	if key then
		local default = hg.Config.Defaults[key]
		if default ~= nil then
			hg.Config.Set(key, default)
		end
	else
		for k, v in pairs(hg.Config.Defaults) do
			hg.Config.Set(k, v)
		end
	end
end

-- Export/Import
function hg.Config.Export()
	local data = {}
	for k, v in pairs(hg.Config.Values) do
		data[k] = v
	end
	return util.TableToJSON(data, true)
end

function hg.Config.Import(json)
	local data = util.JSONToTable(json)
	if not data then return false end
	
	for k, v in pairs(data) do
		if hg.Config.Defaults[k] ~= nil then
			hg.Config.Set(k, v)
		end
	end
	return true
end

-- Save/Load from file
function hg.Config.SaveToFile(path)
	path = path or "zcity_optimized/config.json"
	file.CreateDir("zcity_optimized")
	file.Write(path, hg.Config.Export())
end

function hg.Config.LoadFromFile(path)
	path = path or "zcity_optimized/config.json"
	if not file.Exists(path, "DATA") then return false end
	
	local json = file.Read(path, "DATA")
	return hg.Config.Import(json)
end

-- ============================================
-- Core Configuration Definitions
-- ============================================

-- Organism System
hg.Config.Define("organism_enable", 1, function(v) return v == 0 or v == 1 end, "Enable organism system")
hg.Config.Define("organism_health", 100, function(v) return v > 0 end, "Base health")
hg.Config.Define("organism_regen_rate", 0.5, function(v) return v >= 0 end, "Health regen per second")
hg.Config.Define("organism_regen_delay", 10, function(v) return v >= 0 end, "Seconds before regen starts")
hg.Config.Define("organism_bleed_chance", 0.3, function(v) return v >= 0 and v <= 1 end, "Chance to bleed on damage")
hg.Config.Define("organism_fracture_chance", 0.1, function(v) return v >= 0 and v <= 1 end, "Chance to fracture on heavy damage")
hg.Config.Define("organism_stamina", 100, function(v) return v > 0 end, "Base stamina")
hg.Config.Define("organism_stamina_regen", 15, function(v) return v >= 0 end, "Stamina regen per second")
hg.Config.Define("organism_hunger_rate", 0.05, function(v) return v >= 0 end, "Hunger loss per second")
hg.Config.Define("organism_thirst_rate", 0.08, function(v) return v >= 0 end, "Thirst loss per second")

-- Damage System
hg.Config.Define("damage_realistic", 1, function(v) return v == 0 or v == 1 end, "Realistic damage multipliers")
hg.Config.Define("damage_head_mult", 2.5, function(v) return v > 0 end, "Headshot multiplier")
hg.Config.Define("damage_limb_mult", 0.7, function(v) return v > 0 end, "Limb damage multiplier")
hg.Config.Define("damage_armor_absorption", 0.8, function(v) return v >= 0 and v <= 1 end, "Armor damage absorption")
hg.Config.Define("damage_fall_mult", 1.0, function(v) return v >= 0 end, "Fall damage multiplier")

-- Movement System
hg.Config.Define("movement_enable", 1, function(v) return v == 0 or v == 1 end, "Enable advanced movement")
hg.Config.Define("movement_sprint_mult", 1.5, function(v) return v > 0 end, "Sprint speed multiplier")
hg.Config.Define("movement_crouch_mult", 0.4, function(v) return v > 0 and v < 1 end, "Crouch speed multiplier")
hg.Config.Define("movement_prone_mult", 0.15, function(v) return v >= 0 and v < 1 end, "Prone speed multiplier")
hg.Config.Define("movement_stamina_drain", 8, function(v) return v >= 0 end, "Stamina drain per second while sprinting")
hg.Config.Define("movement_jump_power", 200, function(v) return v > 0 end, "Jump power")
hg.Config.Define("movement_step_height", 18, function(v) return v > 0 end, "Step height")

-- Inventory System
hg.Config.Define("inventory_enable", 1, function(v) return v == 0 or v == 1 end, "Enable inventory system")
hg.Config.Define("inventory_max_weight", 50, function(v) return v > 0 end, "Max carry weight (kg)")
hg.Config.Define("inventory_slots", 24, function(v) return v > 0 end, "Number of inventory slots")
hg.Config.Define("inventory_quick_slots", 6, function(v) return v > 0 end, "Quick access slots")

-- Weapon System
hg.Config.Define("weapon_attachment_system", 1, function(v) return v == 0 or v == 1 end, "Enable weapon attachments")
hg.Config.Define("weapon_jam_chance", 0.001, function(v) return v >= 0 and v <= 1 end, "Weapon jam chance per shot")
hg.Config.Define("weapon_overheat_enable", 1, function(v) return v == 0 or v == 1 end, "Enable weapon overheating")
hg.Config.Define("weapon_dirt_enable", 1, function(v) return v == 0 or v == 1 end, "Enable weapon dirt/degradation")

-- Visuals
hg.Config.Define("visual_blood_enable", 1, function(v) return v == 0 or v == 1 end, "Enable blood effects")
hg.Config.Define("visual_ragdoll_enable", 1, function(v) return v == 0 or v == 1 end, "Enable custom ragdolls")
hg.Config.Define("visual_shell_enable", 1, function(v) return v == 0 or v == 1 end, "Enable shell casings")
hg.Config.Define("visual_impact_enable", 1, function(v) return v == 0 or v == 1 end, "Enable bullet impacts")
hg.Config.Define("visual_potatopc", 0, function(v) return v == 0 or v == 1 end, "Low graphics mode")

-- Gameplay
hg.Config.Define("gameplay_friendly_fire", 0, function(v) return v == 0 or v == 1 end, "Enable friendly fire")
hg.Config.Define("gameplay_team_balance", 1, function(v) return v == 0 or v == 1 end, "Auto team balance")
hg.Config.Define("gameplay_respawn_time", 5, function(v) return v >= 0 end, "Respawn delay (seconds)")
hg.Config.Define("gameplay_round_time", 600, function(v) return v > 0 end, "Round time (seconds)")

-- Performance
hg.Config.Define("perf_max_ragdolls", 20, function(v) return v >= 0 end, "Max ragdolls")
hg.Config.Define("perf_max_shells", 100, function(v) return v >= 0 end, "Max shell casings")
hg.Config.Define("perf_max_decals", 500, function(v) return v >= 0 end, "Max decals")
hg.Config.Define("perf_cleanup_interval", 30, function(v) return v > 0 end, "Cleanup interval (seconds)")

-- Network
hg.Config.Define("net_organism_sync_rate", 10, function(v) return v > 0 end, "Organism sync per second")
hg.Config.Define("net_inventory_sync_rate", 5, function(v) return v > 0 end, "Inventory sync per second")
hg.Config.Define("net_effect_compress", 1, function(v) return v == 0 or v == 1 end, "Compress effect data")

-- Load saved config on init
if SERVER then
	timer.Simple(1, function()
		hg.Config.LoadFromFile()
	end)
end

print("[ZC Config] Configuration system loaded")