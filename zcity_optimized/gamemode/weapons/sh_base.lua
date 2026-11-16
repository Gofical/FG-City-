-- ZCity Optimized - Weapon Base
-- Lightweight, performant weapon base for Sandbox

SWEP.Base = "weapon_base"
SWEP.Category = "ZCity Optimized"
SWEP.Spawnable = false
SWEP.AdminOnly = false

-- Weapon info
SWEP.PrintName = "Weapon Base"
SWEP.Author = "ZCity Optimized"
SWEP.Purpose = "Base weapon class"
SWEP.Instructions = ""

-- Viewmodel/Worldmodel
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true

-- Primary fire
SWEP.Primary = {
	Ammo = "pistol",
	ClipSize = 15,
	DefaultClip = 45,
	Automatic = false,
	Damage = 25,
	DamageMin = 15,
	Range = 3000,
	Spread = 0.02,
	Recoil = 1.0,
	RecoilSide = 0.5,
	RPM = 600,
	Force = 1,
	Tracer = 1,
	Num = 1,
	Sound = "Weapon_Pistol.Single",
	SoundSilenced = "Weapon_Pistol.Silenced",
}

-- Secondary fire
SWEP.Secondary = {
	Ammo = "none",
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false,
}

-- Reload
SWEP.ReloadTime = 2.0
SWEP.ReloadEmptyTime = 2.5
SWEP.ReloadSound = "Weapon_Pistol.Reload"

-- Weight & handling
SWEP.Weight = 1.0
SWEP.Length = 16
SWEP.HoldType = "pistol"
SWEP.HoldTypeSights = "revolver"
SWEP.HoldTypeSprint = "passive"

-- Sights
SWEP.IronSightsPos = Vector(-2, -4, 1)
SWEP.IronSightsAng = Angle(0, 0, 0)
SWEP.SightTime = 0.25
SWEP.SightFOV = 50

-- Sprint
SWEP.SprintPos = Vector(0, 0, 0)
SWEP.SprintAng = Angle(-10, 20, 0)

-- Inspect
SWEP.InspectPos = Vector(8, -4, -2)
SWEP.InspectAng = Angle(10, 30, 5)

-- Attachments
SWEP.Attachments = {}
SWEP.AttachmentModels = {}

-- Shell ejection
SWEP.ShellModel = "models/shells/shell_9mm.mdl"
SWEP.ShellScale = 1
SWEP.ShellEjectPos = Vector(0, 0, 0)
SWEP.ShellEjectAng = Angle(0, 90, 0)
SWEP.ShellVelocity = 100

-- Muzzle
SWEP.MuzzleEffect = "muzzleflash_pistol"
SWEP.MuzzlePos = Vector(0, 0, 0)
SWEP.MuzzleAng = Angle(0, 0, 0)

-- Crosshair
SWEP.CrosshairSize = 2
SWEP.CrosshairGap = 4
SWEP.CrosshairThickness = 1

-- Internal state
SWEP.ZC_LastFire = 0
SWEP.ZC_Recoil = Angle(0, 0, 0)
SWEP.ZC_SightProgress = 0
SWEP.ZC_SprintProgress = 0
SWEP.ZC_InspectProgress = 0
SWEP.ZC_Reloading = false
SWEP.ZC_ReloadFinish = 0
SWEP.ZC_Heat = 0
SWEP.ZC_Dirt = 0
SWEP.ZC_Jammed = false

-- Initialize
function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	
	if CLIENT then
		self:CreateModels()
	end
end

function SWEP:CreateModels()
	// Create viewmodel attachments
	for _, att in pairs(self.Attachments or {}) do
		if att.model then
			local ent = ClientsideModel(att.model, RENDERGROUP_OPAQUE)
			if IsValid(ent) then
				ent:SetNoDraw(true)
				ent:SetParent(self.Owner:GetViewModel())
				ent:AddEffects(EF_BONEMERGE)
				self.AttachmentModels[att.slot] = ent
			end
		end
	end
end

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "ZC_IronSights")
	self:NetworkVar("Bool", 1, "ZC_Reloading")
	self:NetworkVar("Bool", 2, "ZC_Sprinting")
	self:NetworkVar("Bool", 3, "ZC_Inspecting")
	self:NetworkVar("Bool", 4, "ZC_Jammed")
	self:NetworkVar("Float", 0, "ZC_Heat")
	self:NetworkVar("Float", 1, "ZC_Dirt")
	self:NetworkVar("Int", 0, "ZC_FireMode")
	self:NetworkVar("Int", 1, "ZC_AttachmentMask")
end

-- Deploy/Holster
function SWEP:Deploy()
	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)
	
	self.ZC_SightProgress = 0
	self.ZC_SprintProgress = 0
	self.ZC_InspectProgress = 0
	self.ZC_Reloading = false
	self.ZC_Jammed = false
	
	self:SendWeaponAnim(ACT_VM_DRAW)
	self:SetPlaybackRate(1)
	
	if SERVER then
		hg.Net.SendEffect(self.Owner:GetShootPos(), "WeaponDeploy", {class = self:GetClass()})
	end
	
	return true
end

function SWEP:Holster(wep)
	if self.ZC_Reloading then return false end
	if self.ZC_Inspecting then self:SetZC_Inspecting(false) end
	return true
end

-- Primary Attack
function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	
	if self:GetZC_Jammed() then
		self:EmitSound("Weapon_Pistol.Empty", 75, 100, 0.5)
		self:SetNextPrimaryFire(CurTime() + 0.5)
		return
	end
	
	if self:GetZC_Sprinting() then return end
	if self:GetZC_Inspecting() then return end
	
	local clip = self:Clip1()
	if clip <= 0 then
		self:Reload()
		return
	end
	
	// Fire
	self:FireBullet()
	self:TakePrimaryAmmo(1)
	
	// Recoil
	self:ApplyRecoil()
	
	// Heat
	self:AddHeat(1)
	
	// Dirt
	self:AddDirt(0.1)
	
	// Jam check
	if hg.Config.GetBool("weapon_jam_enable") then
		local jamChance = hg.Config.GetFloat("weapon_jam_chance") * (1 + self.ZC_Dirt * 10)
		if math.random() < jamChance then
			self:SetZC_Jammed(true)
			self:EmitSound("Weapon_Pistol.Empty", 75, 100, 0.5)
		end
	end
	
	// Next fire
	local rpm = self.Primary.RPM
	self:SetNextPrimaryFire(CurTime() + 60 / rpm)
	self.ZC_LastFire = CurTime()
	
	// Network
	if SERVER then
		hg.Net.SendEffect(self:GetMuzzlePos(), "MuzzleFlash", {
			effect = self.MuzzleEffect,
			scale = 1,
		})
	end
end

function SWEP:CanPrimaryAttack()
	if self.ZC_Reloading then return false end
	if self:GetZC_Sprinting() then return false end
	if self:GetZC_Inspecting() then return false end
	if self:Clip1() <= 0 then return false end
	if CurTime() < self:GetNextPrimaryFire() then return false end
	return true
end

function SWEP:FireBullet()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	local dmg = self.Primary.Damage
	local range = self.Primary.Range
	local spread = self:GetCurrentSpread()
	local num = self.Primary.Num
	local force = self.Primary.Force
	local tracer = self.Primary.Tracer
	
	// Get shoot pos/ang
	local pos = owner:GetShootPos()
	local ang = owner:EyeAngles() + self.ZC_Recoil
	
	// Fire bullets
	for i = 1, num do
		local dir = (ang + Angle(
			math.Rand(-spread, spread),
			math.Rand(-spread, spread),
			0
		)):Forward()
		
		local tr = util.TraceLine({
			start = pos,
			endpos = pos + dir * range,
			filter = owner,
			mask = MASK_SHOT,
		})
		
		if tr.Hit then
			// Damage
			local dmgInfo = DamageInfo()
			dmgInfo:SetDamage(dmg * self:GetDamageFalloff(tr.Fraction))
			dmgInfo:SetDamageType(DMG_BULLET)
			dmgInfo:SetAttacker(owner)
			dmgInfo:SetInflictor(self)
			dmgInfo:SetDamageForce(dir * force * 1000)
			dmgInfo:SetDamagePosition(tr.HitPos)
			
			if IsValid(tr.Entity) then
				tr.Entity:TakeDamageInfo(dmgInfo)
			end
			
			// Effects
			if SERVER then
				hg.Net.SendEffect(tr.HitPos, "BulletImpact", {
					normal = tr.HitNormal,
					decal = "Impact.Concrete",
				})
			end
		end
	end
	
	// Muzzle flash (client)
	if CLIENT then
		self:CreateMuzzleFlash()
	end
	
	// Sound
	self:EmitSound(self:GetFireSound())
	
	// View punch
	owner:ViewPunch(Angle(-self.Primary.Recoil * 0.5, math.Rand(-self.Primary.RecoilSide, self.Primary.RecoilSide) * 0.5, 0))
end

function SWEP:GetCurrentSpread()
	local base = self.Primary.Spread
	local owner = self:GetOwner()
	
	if not IsValid(owner) then return base end
	
	local mult = 1.0
	
	// Movement
	local vel = owner:GetVelocity():Length2D()
	if vel > 10 then mult = mult + vel / 500 end
	
	// Crouch
	if owner:Crouching() then mult = mult * 0.5 end
	
	// Sights
	local sightProg = self:GetSightProgress()
	if sightProg > 0 then mult = mult * Lerp(sightProg, 1, 0.1) end
	
	// Sprint
	if self:GetZC_Sprinting() then mult = mult * 3 end
	
	// Heat
	mult = mult * (1 + self.ZC_Heat * 0.5)
	
	// Dirt
	mult = mult * (1 + self.ZC_Dirt * 0.2)
	
	return base * mult
end

function SWEP:GetDamageFalloff(frac)
	local dmgMin = self.Primary.DamageMin
	local dmgMax = self.Primary.Damage
	return Lerp(frac, dmgMax, dmgMin) / dmgMax
end

function SWEP:GetFireSound()
	if self:GetZC_Silenced() and self.Primary.SoundSilenced then
		return self.Primary.SoundSilenced
	end
	return self.Primary.Sound
end

// Recoil
function SWEP:ApplyRecoil()
	local recoil = self.Primary.Recoil
	local recoilSide = self.Primary.RecoilSide
	
	self.ZC_Recoil = Angle(
		-math.Rand(recoil * 0.5, recoil),
		math.Rand(-recoilSide, recoilSide),
		math.Rand(-recoilSide * 0.5, recoilSide * 0.5)
	)
end

function SWEP:GetSightProgress()
	return self.ZC_SightProgress or 0
end

// Heat system
function SWEP:AddHeat(amount)
	if not hg.Config.GetBool("weapon_overheat_enable") then return end
	
	self.ZC_Heat = math.min(100, self.ZC_Heat + amount)
	self:SetZC_Heat(self.ZC_Heat)
end

function SWEP:ThinkHeat()
	if self.ZC_Heat > 0 then
		self.ZC_Heat = math.max(0, self.ZC_Heat - FrameTime() * 5)
		self:SetZC_Heat(self.ZC_Heat)
	end
end

// Dirt system
function SWEP:AddDirt(amount)
	if not hg.Config.GetBool("weapon_dirt_enable") then return end
	
	self.ZC_Dirt = math.min(100, self.ZC_Dirt + amount)
	self:SetZC_Dirt(self.ZC_Dirt)
end

function SWEP:CleanWeapon()
	self.ZC_Dirt = 0
	self:SetZC_Dirt(0)
	self:SetZC_Jammed(false)
end

// Reload
function SWEP:Reload()
	if self.ZC_Reloading then return end
	if self:Clip1() >= self.Primary.ClipSize then return end
	if self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then return end
	if self:GetZC_Sprinting() then return end
	if self:GetZC_Inspecting() then return end
	
	local empty = self:Clip1() == 0
	local reloadTime = empty and self.ReloadEmptyTime or self.ReloadTime
	
	self.ZC_Reloading = true
	self:SetZC_Reloading(true)
	self.ZC_ReloadFinish = CurTime() + reloadTime
	
	self:SendWeaponAnim(empty and ACT_VM_RELOAD_EMPTY or ACT_VM_RELOAD)
	self:SetPlaybackRate(1 / reloadTime)
	
	self:SetNextPrimaryFire(CurTime() + reloadTime)
	self:SetNextSecondaryFire(CurTime() + reloadTime)
	
	timer.Simple(reloadTime * 0.8, function()
		if IsValid(self) and self.ZC_Reloading then
			self:EmitSound(self.ReloadSound)
		end
	end)
end

function SWEP:FinishReload()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	local ammo = owner:GetAmmoCount(self.Primary.Ammo)
	local needed = self.Primary.ClipSize - self:Clip1()
	local give = math.min(needed, ammo)
	
	self:SetClip1(self:Clip1() + give)
	owner:RemoveAmmo(give, self.Primary.Ammo)
	
	self.ZC_Reloading = false
	self:SetZC_Reloading(false)
	self.ZC_ReloadFinish = 0
	
	self:SendWeaponAnim(ACT_VM_IDLE)
end

// Sprint
function SWEP:CheckSprint()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	local sprinting = owner:KeyDown(IN_SPEED) and owner:GetVelocity():Length2D() > 50 and owner:OnGround()
	
	if sprinting ~= self:GetZC_Sprinting() then
		self:SetZC_Sprinting(sprinting)
	end
	
	// Sprint progress
	if sprinting then
		self.ZC_SprintProgress = math.min(1, (self.ZC_SprintProgress or 0) + FrameTime() * 5)
	else
		self.ZC_SprintProgress = math.max(0, (self.ZC_SprintProgress or 0) - FrameTime() * 5)
	end
end

// Sights
function SWEP:CheckSights()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
	local sights = owner:KeyDown(IN_ATTACK2) and not self:GetZC_Sprinting() and not self.ZC_Reloading
	
	if sights ~= self:GetZC_IronSights() then
		self:SetZC_IronSights(sights)
	end
	
	// Sight progress
	if sights then
		self.ZC_SightProgress = math.min(1, (self.ZC_SightProgress or 0) + FrameTime() / self.SightTime)
	else
		self.ZC_SightProgress = math.max(0, (self.ZC_SightProgress or 0) - FrameTime() / self.SightTime)
	end
end

// Inspect
function SWEP:SecondaryAttack()
	if self:GetZC_Sprinting() then return end
	if self.ZC_Reloading then return end
	if self:GetZC_IronSights() then return end
	
	if not self:GetZC_Inspecting() then
		self:SetZC_Inspecting(true)
		self.ZC_InspectProgress = 0
	else
		self:SetZC_Inspecting(false)
	end
end

function SWEP:UpdateInspect()
	if self:GetZC_Inspecting() then
		self.ZC_InspectProgress = math.min(1, (self.ZC_InspectProgress or 0) + FrameTime() * 3)
	else
		self.ZC_InspectProgress = math.max(0, (self.ZC_InspectProgress or 0) - FrameTime() * 3)
	end
end

// Jam clearing
function SWEP:ClearJam()
	if not self:GetZC_Jammed() then return end
	
	self:SendWeaponAnim(ACT_VM_FIDGET)
	self:SetPlaybackRate(1)
	
	timer.Simple(1.5, function()
		if IsValid(self) then
			self:SetZC_Jammed(false)
			self:SendWeaponAnim(ACT_VM_IDLE)
		end
	end)
end

// Muzzle position
function SWEP:GetMuzzlePos()
	local vm = self:GetOwner():GetViewModel()
	if IsValid(vm) then
		local att = vm:GetAttachment(vm:LookupAttachment("muzzle"))
		if att then return att.Pos end
	end
	return self:GetOwner():GetShootPos()
end

// Think
function SWEP:Think()
	self:ThinkHeat()
	self:CheckSprint()
	self:CheckSights()
	self:UpdateInspect()
	
	// Finish reload
	if self.ZC_Reloading and CurTime() >= self.ZC_ReloadFinish then
		self:FinishReload()
	end
	
	// Recoil recovery
	self.ZC_Recoil = Angle(
		Lerp(FrameTime() * 10, self.ZC_Recoil.p, 0),
		Lerp(FrameTime() * 10, self.ZC_Recoil.y, 0),
		Lerp(FrameTime() * 10, self.ZC_Recoil.r, 0)
	)
	
	// Auto clear jam on inspect
	if self:GetZC_Jammed() and self:GetZC_Inspecting() and self.ZC_InspectProgress > 0.5 then
		self:ClearJam()
	end
end

// Viewmodel position
function SWEP:GetViewModelPosition(pos, ang)
	local sightProg = self:GetSightProgress()
	local sprintProg = self.ZC_SprintProgress or 0
	local inspectProg = self.ZC_InspectProgress or 0
	
	// Sprint
	if sprintProg > 0 then
		local sp = self.SprintPos * sprintProg
		local sa = self.SprintAng * sprintProg
		pos = pos + ang:Right() * sp.x + ang:Forward() * sp.y + ang:Up() * sp.z
		ang:RotateAroundAxis(ang:Right(), sa.p)
		ang:RotateAroundAxis(ang:Up(), sa.y)
		ang:RotateAroundAxis(ang:Forward(), sa.r)
	end
	
	// Sights
	if sightProg > 0 then
		local ip = self.IronSightsPos * sightProg
		local ia = self.IronSightsAng * sightProg
		pos = pos + ang:Right() * ip.x + ang:Forward() * ip.y + ang:Up() * ip.z
		ang:RotateAroundAxis(ang:Right(), ia.p)
		ang:RotateAroundAxis(ang:Up(), ia.y)
		ang:RotateAroundAxis(ang:Forward(), ia.r)
	end
	
	// Inspect
	if inspectProg > 0 then
		local ip = self.InspectPos * inspectProg
		local ia = self.InspectAng * inspectProg
		pos = pos + ang:Right() * ip.x + ang:Forward() * ip.y + ang:Up() * ip.z
		ang:RotateAroundAxis(ang:Right(), ia.p)
		ang:RotateAroundAxis(ang:Up(), ia.y)
		ang:RotateAroundAxis(ang:Forward(), ia.r)
	end
	
	// Recoil
	pos = pos + ang:Forward() * self.ZC_Recoil.p * 0.5
	ang = ang + self.ZC_Recoil * 0.1
	
	return pos, ang
end

// Viewmodel FOV
function SWEP:AdjustViewModelFOV(fov)
	local sightProg = self:GetSightProgress()
	if sightProg > 0 then
		return Lerp(sightProg, fov, self.SightFOV)
	end
	return fov
end

// World model
function SWEP:DrawWorldModel()
	self:DrawModel()
	
	// Draw attachments
	for slot, model in pairs(self.AttachmentModels) do
		if IsValid(model) then
			model:DrawModel()
		end
	end
end

// Muzzle flash (client)
function SWEP:CreateMuzzleFlash()
	local vm = self:GetOwner():GetViewModel()
	if not IsValid(vm) then return end
	
	local att = vm:GetAttachment(vm:LookupAttachment("muzzle"))
	if not att then return end
	
	local effect = EffectData()
	effect:SetOrigin(att.Pos)
	effect:SetAngles(att.Ang)
	effect:SetEntity(self)
	effect:SetAttachment(vm:LookupAttachment("muzzle"))
	effect:SetScale(1)
	util.Effect(self.MuzzleEffect, effect)
end

// Shell ejection (client)
function SWEP:CreateShell()
	local vm = self:GetOwner():GetViewModel()
	if not IsValid(vm) then return end
	
	local att = vm:GetAttachment(vm:LookupAttachment("shell"))
	if not att then return end
	
	local effect = EffectData()
	effect:SetOrigin(att.Pos)
	effect:SetAngles(att.Ang)
	effect:SetEntity(self)
	effect:SetAttachment(vm:LookupAttachment("shell"))
	effect:SetScale(self.ShellScale)
	util.Effect("ShellEject", effect)
end

// HUD ammo
if CLIENT then
	function SWEP:DrawHUD()
		if not GetConVar("hg_cl_hud"):GetBool() then return end
		
		local x, y = ScrW() - 100, ScrH() - 100
		local clip = self:Clip1()
		local reserve = self:GetOwner():GetAmmoCount(self.Primary.Ammo)
		
		draw.SimpleTextOutlined(
			clip .. " / " .. reserve,
			"ZC_HUD_Medium", x, y,
			color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, color_black
		)
		
		// Heat indicator
		if self.ZC_Heat > 0 then
			local heatW = 100 * (self.ZC_Heat / 100)
			surface.SetDrawColor(255, 100, 0, 200)
			surface.DrawRect(x - 100, y + 20, heatW, 4)
		end
		
		// Jam indicator
		if self:GetZC_Jammed() then
			draw.SimpleTextOutlined(
				"JAMMED - PRESS R TO CLEAR",
				"ZC_HUD_Small", x, y + 30,
				color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, color_black
			)
		end
	end
end

// Attachments
function SWEP:AttachAttachment(slot, class)
	local attData = self.Attachments[slot]
	if not attData then return false end
	
	for _, option in ipairs(attData.options or {}) do
		if option == class then
			// Apply attachment stats
			local att = hg.Equipment.GetItem(class)
			if att and att.stats then
				for k, v in pairs(att.stats) do
					if self.Primary[k] then
						self.Primary[k] = self.Primary[k] * v
					end
				end
			end
			
			// Update attachment mask
			local mask = self:GetZC_AttachmentMask()
			mask = bit.bor(mask, bit.lshift(1, slot))
			self:SetZC_AttachmentMask(mask)
			
			return true
		end
	end
	
	return false
end

function SWEP:DetachAttachment(slot)
	local mask = self:GetZC_AttachmentMask()
	mask = bit.band(mask, bit.bnot(bit.lshift(1, slot)))
	self:SetZC_AttachmentMask(mask)
	
	// Reset stats (simplified)
	self:ResetToBaseStats()
	
	// Reapply all current attachments
	for s = 0, 7 do
		if bit.band(mask, bit.lshift(1, s)) ~= 0 then
			// Re-apply
		end
	end
end

function SWEP:ResetToBaseStats()
	// Override in derived weapons
end

// Fire modes
function SWEP:CycleFireMode()
	local modes = self.FireModes or {"auto"}
	local current = self:GetZC_FireMode()
	local next = (current % #modes) + 1
	self:SetZC_FireMode(next)
	
	self.Primary.Automatic = modes[next] == "auto"
	
	if SERVER then
		self:GetOwner():ChatPrint("Fire mode: " .. modes[next])
	end
end

// Cleaning kit
function SWEP:UseCleaningKit()
	self:CleanWeapon()
	if SERVER then
		self:GetOwner():ChatPrint("Weapon cleaned")
	end
end

print("[ZC Weapons] Weapon base loaded")