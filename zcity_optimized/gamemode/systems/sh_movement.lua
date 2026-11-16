-- ZCity Optimized - Movement System
-- Advanced movement for Sandbox (prone, lean, sprint, etc.)

hg.Movement = hg.Movement or {}
hg.Movement.Players = {}

-- Movement states
hg.Movement.States = {
	IDLE = 0,
	WALK = 1,
	RUN = 2,
	SPRINT = 3,
	CROUCH = 4,
	PRONE = 5,
	CLIMB = 6,
	VAULT = 7,
	SLIDE = 8,
}

-- Lean directions
hg.Movement.Lean = {
	NONE = 0,
	LEFT = 1,
	RIGHT = 2,
}

-- Default movement data
local DEFAULT_MOVEMENT = {
	state = hg.Movement.States.IDLE,
	lean = hg.Movement.Lean.NONE,
	lean_target = hg.Movement.Lean.NONE,
	lean_progress = 0,
	
	-- Speeds
	walk_speed = 150,
	run_speed = 250,
	sprint_speed = 350,
	crouch_speed = 80,
	prone_speed = 30,
	
	-- Stamina
	stamina = 100,
	max_stamina = 100,
	stamina_drain = 8,
	stamina_regen = 15,
	
	-- Jump
	jump_power = 200,
	jump_cooldown = 0,
	
	-- Slide
	sliding = false,
	slide_time = 0,
	slide_speed = 0,
	slide_cooldown = 0,
	
	-- Vault
	vaulting = false,
	vault_time = 0,
	vault_height = 0,
	
	-- Prone
	prone_transition = 0,
	was_prone = false,
	
	-- Step
	step_time = 0,
	step_side = 0,
	
	-- View bob
	bob_time = 0,
	bob_intensity = 0,
}

function hg.Movement.Init(ply)
	if not IsValid(ply) then return end
	if not hg.Config.GetBool("movement_enable") then return end
	
	local mov = table.Copy(DEFAULT_MOVEMENT)
	mov.walk_speed = ply:GetWalkSpeed()
	mov.run_speed = ply:GetRunSpeed()
	mov.max_stamina = hg.Config.GetInt("organism_stamina")
	mov.stamina = mov.max_stamina
	mov.sprint_speed = mov.run_speed * hg.Config.GetFloat("movement_sprint_mult")
	mov.crouch_speed = mov.walk_speed * hg.Config.GetFloat("movement_crouch_mult")
	mov.prone_speed = mov.walk_speed * hg.Config.GetFloat("movement_prone_mult")
	mov.stamina_drain = hg.Config.GetFloat("movement_stamina_drain")
	mov.jump_power = hg.Config.GetFloat("movement_jump_power")
	
	hg.Movement.Players[ply] = mov
	ply.movement = mov
	
	-- Set initial speeds
	ply:SetWalkSpeed(mov.walk_speed)
	ply:SetRunSpeed(mov.run_speed)
	ply:SetJumpPower(mov.jump_power)
	ply:SetCrouchedWalkSpeed(hg.Config.GetFloat("movement_crouch_mult"))
	
	if SERVER then
		hg.Net.SetPlayerVar(ply, "movement", mov)
		hg.Movement.StartSync(ply)
	end
	
	hook.Run("ZC_MovementInitialized", ply, mov)
	return mov
end

function hg.Movement.Get(ply)
	if not IsValid(ply) then return nil end
	return ply.movement or hg.Movement.Players[ply]
end

function hg.Movement.Cleanup(ply)
	hg.Movement.Players[ply] = nil
	if SERVER then
		hg.TimerRemove("MovementSync_" .. ply:EntIndex())
	end
end

-- State management
function hg.Movement.SetState(ply, state)
	local mov = hg.Movement.Get(ply)
	if not mov then return end
	
	local oldState = mov.state
	mov.state = state
	
	-- Handle transitions
	if state == hg.Movement.States.PRONE then
		mov.prone_transition = CurTime() + 0.5
		mov.was_prone = true
	elseif state == hg.Movement.States.SPRINT then
		if oldState ~= hg.Movement.States.SPRINT then
			mov.stamina_drain = hg.Config.GetFloat("movement_stamina_drain")
		end
	elseif state == hg.Movement.States.CROUCH then
		-- Crouch transition
	end
	
	-- Update speeds
	hg.Movement.UpdateSpeeds(ply)
	hg.Movement.MarkDirty(ply)
	
	hook.Run("ZC_MovementStateChanged", ply, oldState, state)
end

function hg.Movement.UpdateSpeeds(ply)
	local mov = hg.Movement.Get(ply)
	if not mov then return end
	
	local org = hg.GetOrganism(ply)
	local healthMult = 1.0
	local staminaMult = 1.0
	
	if org then
		healthMult = math.Clamp(org.health / org.maxhealth, 0.3, 1.0)
		staminaMult = math.Clamp(org.stamina / org.maxstamina, 0.2, 1.0)
	end
	
	local speed = mov.walk_speed
	
	if mov.state == hg.Movement.States.SPRINT then
		speed = mov.sprint_speed * staminaMult
	elseif mov.state == hg.Movement.States.RUN then
		speed = mov.run_speed
	elseif mov.state == hg.Movement.States.CROUCH then
		speed = mov.crouch_speed
	elseif mov.state == hg.Movement.States.PRONE then
		speed = mov.prone_speed
	end
	
	speed = speed * healthMult
	
	ply:SetWalkSpeed(speed)
	ply:SetRunSpeed(speed)
	ply:SetCrouchedWalkSpeed(hg.Config.GetFloat("movement_crouch_mult"))
end

-- Lean system
function hg.Movement.SetLean(ply, direction)
	local mov = hg.Movement.Get(ply)
	if not mov then return end
	
	if direction == mov.lean then return end
	
	mov.lean_target = direction
	mov.lean_progress = 0
	
	if SERVER then
		hg.Net.SendPly(ply, "MovementLean", {lean = direction})
	end
end

-- Slide
function hg.Movement.TrySlide(ply)
	local mov = hg.Movement.Get(ply)
	if not mov then return false end
	
	if mov.sliding then return false end
	if mov.slide_cooldown > CurTime() then return false end
	if mov.state ~= hg.Movement.States.SPRINT then return false end
	if ply:Crouching() then return false end
	if ply:GetVelocity():Length2D() < 200 then return false end
	
	mov.sliding = true
	mov.slide_time = CurTime() + 1.0
	mov.slide_speed = ply:GetVelocity():Length2D()
	mov.slide_cooldown = CurTime() + 2.0
	
	ply:Crouch()
	
	local vel = ply:GetVelocity()
	vel.z = 0
	ply:SetVelocity(vel * 1.5)
	
	if SERVER then
		hg.Net.SendEffect(ply:GetPos(), "SlideDust", {})
	end
	
	return true
end

-- Vault
function hg.Movement.TryVault(ply)
	local mov = hg.Movement.Get(ply)
	if not mov then return false end
	
	if mov.vaulting then return false end
	if mov.state == hg.Movement.States.PRONE then return false end
	
	local tr = util.TraceLine({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * 60,
		filter = ply,
		mask = MASK_SOLID,
	})
	
	if not tr.Hit then return false end
	if tr.HitSky then return false end
	
	-- Check height
	local tr2 = util.TraceLine({
		start = tr.HitPos + Vector(0, 0, 10),
		endpos = tr.HitPos + Vector(0, 0, 100),
		filter = ply,
		mask = MASK_SOLID,
	})
	
	if tr2.Hit then return false end -- Too high
	
	mov.vaulting = true
	mov.vault_time = CurTime() + 0.5
	mov.vault_height = tr.HitPos.z - ply:GetPos().z
	
	ply:SetMoveType(MOVETYPE_NONE)
	
	timer.Simple(0.1, function()
		if IsValid(ply) then
			local vel = ply:GetAimVector() * 300 + Vector(0, 0, 200)
			ply:SetVelocity(vel)
		end
	end)
	
	timer.Simple(0.5, function()
		if IsValid(ply) then
			ply:SetMoveType(MOVETYPE_WALK)
			mov.vaulting = false
		end
	end)
	
	return true
end

-- Prone transition
function hg.Movement.UpdateProne(ply)
	local mov = hg.Movement.Get(ply)
	if not mov then return end
	
	local wantProne = ply:KeyDown(IN_DUCK) and ply:KeyDown(IN_WALK) and ply:GetVelocity():Length2D() < 50
	
	if wantProne and mov.state ~= hg.Movement.States.PRONE then
		if CurTime() > mov.prone_transition then
			hg.Movement.SetState(ply, hg.Movement.States.PRONE)
			ply:SetViewOffset(Vector(0, 0, 10))
			ply:SetViewOffsetDucked(Vector(0, 0, 10))
			ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, 16))
			ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 16))
		end
	elseif not wantProne and mov.state == hg.Movement.States.PRONE then
		hg.Movement.SetState(ply, ply:Crouching() and hg.Movement.States.CROUCH or hg.Movement.States.IDLE)
		ply:SetViewOffset(Vector(0, 0, 64))
		ply:SetViewOffsetDucked(Vector(0, 0, 28))
		ply:ResetHull()
	end
end

-- Think loop
function hg.Movement.Think(ply)
	local mov = hg.Movement.Get(ply)
	if not mov then return end
	
	local now = CurTime()
	local dt = FrameTime()
	if SERVER then dt = engine.TickInterval() end
	
	local vel = ply:GetVelocity()
	local speed2D = vel:Length2D()
	local onGround = ply:OnGround()
	
	-- Update state based on input
	if not mov.vaulting then
		if ply:KeyDown(IN_SPEED) and speed2D > 100 and onGround and not ply:Crouching() then
			local org = hg.GetOrganism(ply)
			if org and org.stamina > 10 then
				hg.Movement.SetState(ply, hg.Movement.States.SPRINT)
			else
				hg.Movement.SetState(ply, hg.Movement.States.RUN)
			end
		elseif ply:Crouching() and onGround then
			if ply:KeyDown(IN_WALK) and speed2D < 50 then
				-- Prone handled in UpdateProne
			else
				hg.Movement.SetState(ply, hg.Movement.States.CROUCH)
			end
		elseif speed2D > 10 then
			if ply:KeyDown(IN_WALK) then
				hg.Movement.SetState(ply, hg.Movement.States.WALK)
			else
				hg.Movement.SetState(ply, hg.Movement.States.RUN)
			end
		else
			hg.Movement.SetState(ply, hg.Movement.States.IDLE)
		end
	end
	
	-- Stamina
	local org = hg.GetOrganism(ply)
	if org then
		if mov.state == hg.Movement.States.SPRINT and speed2D > 50 then
			org.stamina = math.max(0, org.stamina - mov.stamina_drain * dt)
			if org.stamina <= 0 then
				hg.Movement.SetState(ply, hg.Movement.States.RUN)
			end
		elseif org.stamina < org.maxstamina then
			local regen = mov.stamina_regen * dt
			if mov.state == hg.Movement.States.IDLE then regen = regen * 2 end
			org.stamina = math.min(org.maxstamina, org.stamina + regen)
		end
	end
	
	-- Slide update
	if mov.sliding then
		if now > mov.slide_time or speed2D < 100 or not onGround then
			mov.sliding = false
			ply:UnCrouch()
		else
			-- Maintain slide momentum
			local dir = ply:GetAimVector()
			dir.z = 0
			dir:Normalize()
			ply:SetVelocity(dir * mov.slide_speed * 0.98)
			mov.slide_speed = mov.slide_speed * 0.98
		end
	end
	
	-- Lean interpolation
	if mov.lean_progress < 1 then
		mov.lean_progress = math.min(1, mov.lean_progress + dt * 5)
		mov.lean = mov.lean_target
	end
	
	-- Step sounds
	if onGround and speed2D > 50 then
		local stepRate = 0.4
		if mov.state == hg.Movement.States.SPRINT then stepRate = 0.25
		elseif mov.state == hg.Movement.States.CROUCH then stepRate = 0.6
		elseif mov.state == hg.Movement.States.PRONE then stepRate = 1.0 end
		
		mov.step_time = mov.step_time - dt
		if mov.step_time <= 0 then
			mov.step_time = stepRate
			mov.step_side = -mov.step_side
			
			-- Play step sound
			if SERVER then
				local snd = "player/footsteps/concrete" .. math.random(1, 4) .. ".wav"
				if mov.state == hg.Movement.States.CROUCH or mov.state == hg.Movement.States.PRONE then
					snd = "player/footsteps/concrete" .. math.random(1, 4) .. ".wav"
				end
				ply:EmitSound(snd, 65, 100, 0.5)
			end
		end
	end
	
	-- View bob
	if speed2D > 10 then
		mov.bob_time = mov.bob_time + dt * (speed2D / 200)
		mov.bob_intensity = math.min(1, speed2D / 300)
	else
		mov.bob_time = 0
		mov.bob_intensity = 0
	end
	
	hg.Movement.UpdateProne(ply)
	hg.Movement.MarkDirty(ply)
end

function hg.Movement.MarkDirty(ply)
	local mov = hg.Movement.Get(ply)
	if mov then mov.dirty = true end
end

-- Network sync
function hg.Movement.StartSync(ply)
	if not SERVER then return end
	
	local timerName = "MovementSync_" .. ply:EntIndex()
	hg.TimerRemove(timerName)
	
	timer.Create(timerName, 0.1, 0, function()
		if not IsValid(ply) then
			hg.TimerRemove(timerName)
			return
		end
		hg.Movement.Sync(ply)
	end)
end

function hg.Movement.Sync(ply)
	local mov = hg.Movement.Get(ply)
	if not mov or not mov.dirty then return end
	
	local data = {
		s = mov.state,
		l = mov.lean,
		lp = math.floor(mov.lean_progress * 100) / 100,
		sl = mov.sliding and 1 or 0,
		vt = mov.vaulting and 1 or 0,
		st = math.floor(mov.stamina * 10) / 10,
	}
	
	hg.Net.SendPly(ply, "MovementSync", data)
	mov.dirty = false
end

-- Client receive
if CLIENT then
	hg.Net.RegisterClient("MovementSync", function(data)
		local ply = LocalPlayer()
		local mov = hg.Movement.Get(ply)
		if not mov then
			mov = table.Copy(DEFAULT_MOVEMENT)
			ply.movement = mov
			hg.Movement.Players[ply] = mov
		end
		
		mov.state = data.s or mov.state
		mov.lean = data.l or mov.lean
		mov.lean_progress = data.lp or mov.lean_progress
		mov.sliding = data.sl == 1
		mov.vaulting = data.vt == 1
		mov.stamina = data.st or mov.stamina
	end)
	
	hg.Net.RegisterClient("MovementLean", function(data)
		local ply = LocalPlayer()
		local mov = hg.Movement.Get(ply)
		if mov then
			mov.lean_target = data.lean
			mov.lean_progress = 0
		end
	end)
	
	-- View bob for client
	hook.Add("CalcView", "ZC_MovementViewBob", function(ply, pos, ang, fov)
		local mov = hg.Movement.Get(ply)
		if not mov or mov.bob_intensity == 0 then return end
		if not GetConVar("hg_cl_bob"):GetBool() then return end
		
		local bobX = math.sin(mov.bob_time * 2) * mov.bob_intensity * 0.5
		local bobY = math.sin(mov.bob_time) * mov.bob_intensity * 0.3
		local bobZ = math.abs(math.sin(mov.bob_time)) * mov.bob_intensity * 0.2
		
		pos = pos + ang:Right() * bobX + ang:Forward() * bobY + ang:Up() * bobZ
		
		return {origin = pos}
	end)
	
	-- Lean view
	hook.Add("CalcView", "ZC_MovementLeanView", function(ply, pos, ang, fov)
		local mov = hg.Movement.Get(ply)
		if not mov or mov.lean == hg.Movement.Lean.NONE or mov.lean_progress == 0 then return end
		
		local leanAngle = 15 * mov.lean_progress
		if mov.lean == hg.Movement.Lean.LEFT then
			leanAngle = -leanAngle
		end
		
		ang = Angle(ang.p, ang.y, ang.r + leanAngle)
		pos = pos + ang:Right() * (leanAngle * 0.5)
		
		return {origin = pos, angles = ang}
	end)
end

-- Input hooks
hook.Add("KeyPress", "ZC_MovementKeys", function(ply, key)
	local mov = hg.Movement.Get(ply)
	if not mov then return end
	
	if key == IN_JUMP then
		mov.jump_cooldown = CurTime() + 0.2
		
		-- Vault
		if ply:KeyDown(IN_FORWARD) and mov.state ~= hg.Movement.States.PRONE then
			hg.Movement.TryVault(ply)
		end
	elseif key == IN_DUCK then
		-- Slide
		if ply:KeyDown(IN_SPEED) and mov.state == hg.Movement.States.SPRINT then
			hg.Movement.TrySlide(ply)
		end
	elseif key == IN_WALK then
		-- Lean left/right
		if ply:KeyDown(IN_MOVELEFT) then
			hg.Movement.SetLean(ply, hg.Movement.Lean.LEFT)
		elseif ply:KeyDown(IN_MOVERIGHT) then
			hg.Movement.SetLean(ply, hg.Movement.Lean.RIGHT)
		end
	end
end)

hook.Add("KeyRelease", "ZC_MovementKeysRelease", function(ply, key)
	local mov = hg.Movement.Get(ply)
	if not mov then return end
	
	if key == IN_WALK then
		hg.Movement.SetLean(ply, hg.Movement.Lean.NONE)
	elseif key == IN_DUCK then
		if mov.sliding then
			mov.sliding = false
			ply:UnCrouch()
		end
	end
end)

-- Main think
if SERVER then
	hook.Add("Tick", "ZC_MovementThink", function()
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) and ply:Alive() then
				hg.Movement.Think(ply)
			end
		end
	end)
else
	hook.Add("Think", "ZC_MovementThink", function()
		local ply = LocalPlayer()
		if IsValid(ply) and ply:Alive() then
			hg.Movement.Think(ply)
		end
	end)
end

hook.Add("PlayerSpawn", "ZC_MovementSpawn", function(ply)
	timer.Simple(0.1, function()
		if IsValid(ply) and not hg.Movement.Get(ply) then
			hg.Movement.Init(ply)
		end
	end)
end)

hook.Add("PlayerDeath", "ZC_MovementDeath", function(ply)
	local mov = hg.Movement.Get(ply)
	if mov then
		mov.state = hg.Movement.States.IDLE
		mov.sliding = false
		mov.vaulting = false
		mov.lean = hg.Movement.Lean.NONE
	end
end)

-- Console commands
if SERVER then
	concommand.Add("zc_mov_debug", function(ply, cmd, args)
		if not ply:IsAdmin() then return end
		local target = ply:GetEyeTrace().Entity
		if IsValid(target) and target:IsPlayer() then
			PrintTable(hg.Movement.Get(target) or {})
		else
			PrintTable(hg.Movement.Get(ply) or {})
		end
	end)
end

print("[ZC Movement] Movement system loaded")