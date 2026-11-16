-- ZCity Optimized - Utility Library
-- Optimized shared utility functions

-- Vector/Vector2 helpers
function hg.VectorToString(vec, precision)
	precision = precision or 2
	return string.format("%.%df, %.%df, %.%df", precision, precision, precision, vec.x, vec.y, vec.z)
end

function hg.AngleToString(ang, precision)
	precision = precision or 1
	return string.format("%.%df, %.%df, %.%df", precision, precision, precision, ang.p, ang.y, ang.r)
end

function hg.VecRandom(min, max)
	return Vector(
		math.Rand(min.x, max.x),
		math.Rand(min.y, max.y),
		math.Rand(min.z, max.z)
	)
end

function hg.VecLerp(t, from, to)
	return Vector(
		Lerp(t, from.x, to.x),
		Lerp(t, from.y, to.y),
		Lerp(t, from.z, to.z)
	)
end

function hg.AngLerp(t, from, to)
	return Angle(
		LerpAngle(t, from, to).p,
		LerpAngle(t, from, to).y,
		LerpAngle(t, from, to).r
	)
end

-- Distance helpers (squared for performance)
function hg.DistToSqr(pos1, pos2)
	local dx = pos1.x - pos2.x
	local dy = pos1.y - pos2.y
	local dz = pos1.z - pos2.z
	return dx*dx + dy*dy + dz*dz
end

function hg.DistTo(pos1, pos2)
	return math.sqrt(hg.DistToSqr(pos1, pos2))
end

function hg.InRange(pos1, pos2, range)
	return hg.DistToSqr(pos1, pos2) <= range * range
end

-- Angle helpers
function hg.AngleDiff(a1, a2)
	local diff = math.AngleDifference(a1, a2)
	return math.abs(diff)
end

function hg.NormalizeAngle(ang)
	ang.p = math.NormalizeAngle(ang.p)
	ang.y = math.NormalizeAngle(ang.y)
	ang.r = math.NormalizeAngle(ang.r)
	return ang
end

-- Trace helpers (cached)
hg.TraceCache = {}

function hg.TraceLine(start, endpos, filter, mask)
	local key = tostring(start) .. tostring(endpos) .. tostring(filter) .. tostring(mask)
	-- Don't cache traces as they're frame-dependent
	
	local tr = util.TraceLine({
		start = start,
		endpos = endpos,
		filter = filter,
		mask = mask or MASK_SOLID,
	})
	return tr
end

function hg.TraceHull(start, endpos, mins, maxs, filter, mask)
	local tr = util.TraceHull({
		start = start,
		endpos = endpos,
		mins = mins,
		maxs = maxs,
		filter = filter,
		mask = mask or MASK_SOLID,
	})
	return tr
end

function hg.TraceEntity(ent, start, endpos, mask)
	return util.TraceEntity({
		start = start,
		endpos = endpos,
		mask = mask or MASK_SOLID,
		filter = ent,
	}, ent)
end

-- Entity helpers
function hg.GetEntitiesInSphere(pos, radius, class)
	local ents = ents.FindInSphere(pos, radius)
	if class then
		local filtered = {}
		for _, ent in ipairs(ents) do
			if ent:GetClass() == class then
				table.insert(filtered, ent)
			end
		end
		return filtered
	end
	return ents
end

function hg.GetPlayersInSphere(pos, radius)
	local all = player.GetAll()
	local result = {}
	local r2 = radius * radius
	for _, ply in ipairs(all) do
		if IsValid(ply) and ply:GetPos():DistToSqr(pos) <= r2 then
			table.insert(result, ply)
		end
	end
	return result
end

function hg.FindInCone(pos, dir, angle, range, filter)
	local results = {}
	local cosAngle = math.cos(math.rad(angle))
	local range2 = range * range
	
	for _, ent in ipairs(ents.GetAll()) do
		if filter and filter(ent) then continue end
		if ent:GetPos():DistToSqr(pos) > range2 then continue end
		
		local toEnt = (ent:GetPos() - pos):GetNormalized()
		if dir:Dot(toEnt) >= cosAngle then
			table.insert(results, ent)
		end
	end
	
	return results
end

-- Player helpers
function hg.IsPlayerAlive(ply)
	return IsValid(ply) and ply:Alive() and ply:Team() ~= TEAM_SPECTATOR and ply:Team() ~= TEAM_UNASSIGNED
end

function hg.GetAlivePlayers()
	local result = {}
	for _, ply in ipairs(player.GetAll()) do
		if hg.IsPlayerAlive(ply) then
			table.insert(result, ply)
		end
	end
	return result
end

function hg.GetRandomAlivePlayer()
	local alive = hg.GetAlivePlayers()
	if #alive > 0 then return alive[math.random(#alive)] end
	return nil
end

-- Weapon helpers
function hg.GetActiveWeapon(ply)
	if not IsValid(ply) then return nil end
	return ply:GetActiveWeapon()
end

function hg.HasWeapon(ply, class)
	if not IsValid(ply) then return false end
	for _, wep in ipairs(ply:GetWeapons()) do
		if IsValid(wep) and wep:GetClass() == class then
			return true, wep
		end
	end
	return false, nil
end

function hg.GiveWeapon(ply, class, ammo)
	if not IsValid(ply) then return nil end
	local wep = ply:Give(class)
	if IsValid(wep) and ammo then
		ply:GiveAmmo(ammo, wep:GetPrimaryAmmoType(), true)
	end
	return wep
end

-- Ammo helpers
function hg.GetAmmoCount(ply, ammoType)
	if not IsValid(ply) then return 0 end
	return ply:GetAmmoCount(ammoType)
end

function hg.SetAmmo(ply, ammoType, count)
	if not IsValid(ply) then return end
	ply:SetAmmo(count, ammoType)
end

-- Effect helpers (optimized)
hg.EffectQueue = {}

function hg.QueueEffect(name, data)
	table.insert(hg.EffectQueue, {name = name, data = data, time = CurTime()})
end

function hg.ProcessEffectQueue()
	if #hg.EffectQueue == 0 then return end
	
	local now = CurTime()
	for i = #hg.EffectQueue, 1, -1 do
		local effect = hg.EffectQueue[i]
		if effect.time <= now then
			local effectData = EffectData()
			for k, v in pairs(effect.data) do
				effectData["Set" .. k:sub(1,1):upper() .. k:sub(2)](effectData, v)
			end
			util.Effect(effect.name, effectData, true, true)
			table.remove(hg.EffectQueue, i)
		end
	end
end

if SERVER then
	hook.Add("Tick", "ZC_ProcessEffects", hg.ProcessEffectQueue)
end

-- Sound helpers
function hg.PlaySoundAt(pos, sound, volume, pitch)
	sound.Play(sound, pos, 75, pitch or 100, volume or 1)
end

function hg.EmitSound(ent, sound, volume, pitch, level)
	if not IsValid(ent) then return end
	ent:EmitSound(sound, level or 75, pitch or 100, volume or 1)
end

-- Model helpers
hg.ModelCache = {}

function hg.PreloadModel(model)
	if hg.ModelCache[model] then return true end
	if not util.IsValidModel(model) then return false end
	hg.ModelCache[model] = true
	return true
end

function hg.PreloadModels(models)
	for _, model in ipairs(models) do
		hg.PreloadModel(model)
	end
end

-- Particle helpers
function hg.CreateParticleSystem(ent, name, attach, offset)
	if not IsValid(ent) then return end
	ent:CreateParticleEffect(name, attach or PATTACH_ABSORIGIN_FOLLOW, offset)
end

-- Timer helpers (named timers to prevent duplicates)
function hg.TimerSimple(name, delay, func)
	timer.Create("ZC_" .. name, delay, 1, func)
end

function hg.TimerRemove(name)
	timer.Remove("ZC_" .. name)
end

function hg.TimerExists(name)
	return timer.Exists("ZC_" .. name)
end

function hg.TimerPause(name)
	timer.Pause("ZC_" .. name)
end

function hg.TimerResume(name)
	timer.UnPause("ZC_" .. name)
end

-- Hook helpers
function hg.AddHook(event, name, func)
	hook.Add(event, "ZC_" .. name, func)
end

function hg.RemoveHook(event, name)
	hook.Remove(event, "ZC_" .. name)
end

-- ConVar helpers
function hg.CreateConVar(name, default, flags, help, min, max)
	flags = flags or FCVAR_ARCHIVE + FCVAR_REPLICATED
	return CreateConVar("hg_" .. name, default, flags, help, min, max)
end

function hg.GetConVar(name)
	return GetConVar("hg_" .. name)
end

function hg.GetConVarFloat(name)
	local cv = hg.GetConVar(name)
	return cv and cv:GetFloat() or 0
end

function hg.GetConVarInt(name)
	local cv = hg.GetConVar(name)
	return cv and cv:GetInt() or 0
end

function hg.GetConVarBool(name)
	local cv = hg.GetConVar(name)
	return cv and cv:GetBool() or false
end

-- Networking helpers (shared)
hg.NetMessages = {}

function hg.RegisterNetMessage(name, handler)
	hg.NetMessages[name] = handler
	if SERVER then
		util.AddNetworkString("ZC_" .. name)
	end
end

if SERVER then
	function hg.SendNetMessage(ply, name, ...)
		net.Start("ZC_" .. name)
		local args = {...}
		for _, v in ipairs(args) do
			net.WriteType(v)
		end
		if ply then net.Send(ply) else net.Broadcast() end
	end
else
	function hg.SendNetMessage(name, ...)
		net.Start("ZC_" .. name)
		local args = {...}
		for _, v in ipairs(args) do
			net.WriteType(v)
		end
		net.SendToServer()
	end
end

-- File/JSON helpers
function hg.SaveJSON(path, data)
	local json = util.TableToJSON(data, true)
	file.Write("zcity_optimized/" .. path, json)
end

function hg.LoadJSON(path, default)
	local fullPath = "zcity_optimized/" .. path
	if not file.Exists(fullPath, "DATA") then return default end
	local json = file.Read(fullPath, "DATA")
	local data = util.JSONToTable(json)
	return data or default
end

-- Math easing functions
hg.Easing = {}

function hg.Easing.Linear(t) return t end
function hg.Easing.InQuad(t) return t * t end
function hg.Easing.OutQuad(t) return t * (2 - t) end
function hg.Easing.InOutQuad(t) return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t end
function hg.Easing.InCubic(t) return t * t * t end
function hg.Easing.OutCubic(t) return (t - 1) ^ 3 + 1 end
function hg.Easing.InOutCubic(t) return t < 0.5 and 4 * t * t * t or (t - 1) * (2 * t - 2) * (2 * t - 2) + 1 end
function hg.Easing.OutElastic(t)
	if t == 0 then return 0 end
	if t == 1 then return 1 end
	return math.pow(2, -10 * t) * math.sin((t - 0.1) * 5 * math.pi) + 1
end
function hg.Easing.OutBounce(t)
	if t < 1/2.75 then return 7.5625 * t * t end
	if t < 2/2.75 then return 7.5625 * (t - 1.5/2.75) * (t - 1.5/2.75) + 0.75 end
	if t < 2.5/2.75 then return 7.5625 * (t - 2.25/2.75) * (t - 2.25/2.75) + 0.9375 end
	return 7.5625 * (t - 2.625/2.75) * (t - 2.625/2.75) + 0.984375
end

-- Interpolation helpers
function hg.LerpClamp(t, from, to)
	return Lerp(math.Clamp(t, 0, 1), from, to)
end

function hg.Approach(cur, target, inc)
	if cur < target then return math.min(cur + inc, target) end
	if cur > target then return math.max(cur - inc, target) end
	return target
end

function hg.ApproachVector(cur, target, inc)
	return Vector(
		hg.Approach(cur.x, target.x, inc),
		hg.Approach(cur.y, target.y, inc),
		hg.Approach(cur.z, target.z, inc)
	)
end

-- Color interpolation
function hg.ColorLerp(t, from, to)
	return Color(
		Lerp(t, from.r, to.r),
		Lerp(t, from.g, to.g),
		Lerp(t, from.b, to.b),
		Lerp(t, from.a, to.a)
	)
end

-- Random helpers
function hg.RandomFloat(min, max)
	return math.Rand(min, max)
end

function hg.RandomInt(min, max)
	return math.random(min, max)
end

function hg.RandomChoice(tbl)
	return tbl[math.random(#tbl)]
end

function hg.Shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

-- Bit operations
function hg.HasFlag(value, flag)
	return bit.band(value, flag) == flag
end

function hg.SetFlag(value, flag)
	return bit.bor(value, flag)
end

function hg.ClearFlag(value, flag)
	return bit.band(value, bit.bnot(flag))
end

-- String formatting
function hg.FormatNumber(num, decimals)
	decimals = decimals or 0
	if num >= 1e9 then return string.format("%." .. decimals .. "fB", num / 1e9) end
	if num >= 1e6 then return string.format("%." .. decimals .. "fM", num / 1e6) end
	if num >= 1e3 then return string.format("%." .. decimals .. "fK", num / 1e3) end
	return tostring(num)
end

function hg.FormatBytes(bytes)
	if bytes >= 1099511627776 then return string.format("%.2f TB", bytes / 1099511627776) end
	if bytes >= 1073741824 then return string.format("%.2f GB", bytes / 1073741824) end
	if bytes >= 1048576 then return string.format("%.2f MB", bytes / 1048576) end
	if bytes >= 1024 then return string.format("%.2f KB", bytes / 1024) end
	return bytes .. " B"
end

-- Performance monitoring
hg.PerfStats = {}

function hg.StartPerf(name)
	hg.PerfStats[name] = SysTime()
end

function hg.EndPerf(name)
	if not hg.PerfStats[name] then return 0 end
	local elapsed = (SysTime() - hg.PerfStats[name]) * 1000 -- ms
	hg.PerfStats[name] = nil
	return elapsed
end

function hg.GetPerfStats()
	local stats = {}
	for name, startTime in pairs(hg.PerfStats) do
		stats[name] = (SysTime() - startTime) * 1000
	end
	return stats
end