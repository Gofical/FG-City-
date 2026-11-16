-- ZCity Optimized - Shared Core
-- Minimal shared definitions for Sandbox compatibility

GM.Name = "ZCity Optimized"
GM.Author = "Optimized Fork"
GM.Email = "N/A"
GM.Website = "N/A"

-- Team setup (minimal)
TEAM_UNASSIGNED = 1000
TEAM_SPECTATOR = 1001
TEAM_PLAYER = 1

team.SetUp(TEAM_PLAYER, "Players", Color(100, 200, 100))
team.SetUp(TEAM_SPECTATOR, "Spectators", Color(150, 150, 150))
team.SetUp(TEAM_UNASSIGNED, "Unassigned", Color(100, 100, 100))

-- Global tables
zb = zb or {}
hg = hg or {}

zb.Version = "2.0.0"
zb.CROUND = "sandbox"
zb.ROUND_STATE = 0

-- ConVars (minimal set)
hg.ConVars = hg.ConVars or {}

if SERVER then
	CreateConVar("hg_potatopc", "0", FCVAR_ARCHIVE, "Low graphics mode")
	CreateConVar("hg_realistic_damage", "1", FCVAR_ARCHIVE, "Realistic damage system")
	CreateConVar("hg_enable_organism", "1", FCVAR_ARCHIVE, "Enable organism system")
	CreateConVar("hg_enable_inventory", "1", FCVAR_ARCHIVE, "Enable inventory system")
	CreateConVar("hg_enable_movement", "1", FCVAR_ARCHIVE, "Enable movement system")
else
	hg.ConVars.potatopc = GetConVar("hg_potatopc")
	hg.ConVars.realistic_damage = GetConVar("hg_realistic_damage")
	hg.ConVars.enable_organism = GetConVar("hg_enable_organism")
	hg.ConVars.enable_inventory = GetConVar("hg_enable_inventory")
	hg.ConVars.enable_movement = GetConVar("hg_enable_movement")
end

-- Utility functions
function hg.GetConVar(name)
	return hg.ConVars[name]
end

function hg.ConVarBool(name)
	local cv = hg.ConVars[name]
	return cv and cv:GetBool() or false
end

-- Color helpers
hg.Colors = {
	White = Color(255, 255, 255),
	Black = Color(0, 0, 0),
	Red = Color(255, 50, 50),
	Green = Color(50, 255, 50),
	Blue = Color(50, 150, 255),
	Yellow = Color(255, 255, 50),
	Gray = Color(128, 128, 128),
	DarkGray = Color(64, 64, 64),
}

-- Math helpers
function hg.LerpColor(t, from, to)
	return Color(
		Lerp(t, from.r, to.r),
		Lerp(t, from.g, to.g),
		Lerp(t, from.b, to.b),
		Lerp(t, from.a, to.a)
	)
end

function hg.ApproachAngle(cur, target, inc)
	local diff = math.AngleDifference(target, cur)
	if math.abs(diff) < inc then return target end
	return cur + math.Clamp(diff, -inc, inc)
end

-- String helpers
function hg.FormatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", mins, secs)
end

function hg.CommaNumber(num)
	local formatted = tostring(math.floor(num))
	local k = 3
	while k < #formatted do
		formatted = formatted:sub(1, -k-1) .. "," .. formatted:sub(-k)
		k = k + 4
	end
	return formatted
end

-- Table helpers
function hg.TableCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		if istable(v) then
			copy[k] = hg.TableCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

function hg.TableMerge(dest, src)
	for k, v in pairs(src) do
		if istable(v) and istable(dest[k]) then
			hg.TableMerge(dest[k], v)
		else
			dest[k] = v
		end
	end
end

-- Entity helpers
function hg.IsValidEntity(ent)
	return IsValid(ent) and ent:EntIndex() > 0
end

function hg.GetPlayerBySteamID(steamid)
	for _, ply in ipairs(player.GetAll()) do
		if ply:SteamID() == steamid then return ply end
	end
	return nil
end

-- Damage type helpers
DMG_ZC_BULLET = DMG_BULLET
DMG_ZC_MELEE = DMG_CLUB
DMG_ZC_EXPLOSION = DMG_BLAST
DMG_ZC_FIRE = DMG_BURN
DMG_ZC_POISON = DMG_POISON
DMG_ZC_BLEED = bit.bor(DMG_GENERIC, 0x10000000) -- Custom

-- Bone helpers
hg.BoneCache = {}
function hg.GetBoneID(ent, boneName)
	local key = ent:GetModel() .. ":" .. boneName
	if hg.BoneCache[key] then return hg.BoneCache[key] end
	
	local bone = ent:LookupBone(boneName)
	hg.BoneCache[key] = bone
	return bone
end

-- Effect helpers
function hg.CreateEffect(name, pos, ang, scale)
	local effect = EffectData()
	effect:SetOrigin(pos or vector_origin)
	effect:SetAngles(ang or angle_zero)
	effect:SetScale(scale or 1)
	util.Effect(name, effect, true, true)
end

-- Net message helpers (shared)
if SERVER then
	function hg.NetMessage(name, data, recipients)
		net.Start(name)
		if data then
			for k, v in pairs(data) do
				net.WriteType(v)
			end
		end
		if recipients then
			net.Send(recipients)
		else
			net.Broadcast()
		end
	end
	
	function hg.NetMessagePly(ply, name, data)
		net.Start(name)
		if data then
			for k, v in pairs(data) do
				net.WriteType(v)
			end
		end
		net.Send(ply)
	end
else
	function hg.SendToServer(name, data)
		net.Start(name)
		if data then
			for k, v in pairs(data) do
				net.WriteType(v)
			end
		end
		net.SendToServer()
	end
end

-- Debug print
function hg.Print(...)
	local args = {...}
	local str = "[ZCity] "
	for i, v in ipairs(args) do
		str = str .. tostring(v) .. (i < #args and "\t" or "")
	end
	print(str)
end

function hg.DebugPrint(...)
	if GetConVar("developer"):GetInt() > 0 then
		hg.Print(...)
	end
end