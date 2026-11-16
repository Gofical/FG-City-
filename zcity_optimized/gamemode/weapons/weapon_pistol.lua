-- ZCity Optimized - Example Pistol
-- Demonstrates the weapon base

AddCSLuaFile()

SWEP.Base = "zc_weapon_base"
SWEP.PrintName = "Glock 17"
SWEP.Category = "ZCity Optimized - Pistols"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/cstrike/c_pist_glock18.mdl"
SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl"

SWEP.Primary = {
	Ammo = "pistol",
	ClipSize = 17,
	DefaultClip = 51,
	Automatic = false,
	Damage = 22,
	DamageMin = 12,
	Range = 2500,
	Spread = 0.015,
	Recoil = 0.8,
	RecoilSide = 0.4,
	RPM = 650,
	Force = 1.2,
	Tracer = 1,
	Num = 1,
	Sound = "Weapon_Glock.Single",
	SoundSilenced = "Weapon_Glock.Silenced",
}

SWEP.ReloadTime = 2.2
SWEP.ReloadEmptyTime = 2.8
SWEP.ReloadSound = "Weapon_Glock.Reload"

SWEP.Weight = 0.8
SWEP.Length = 14
SWEP.HoldType = "pistol"
SWEP.HoldTypeSights = "revolver"

SWEP.IronSightsPos = Vector(-5.75, -4, 2.8)
SWEP.IronSightsAng = Angle(0.2, 0, 0)

SWEP.SprintPos = Vector(0, 0, 0)
SWEP.SprintAng = Angle(-10, 20, 0)

SWEP.InspectPos = Vector(6, -4, -1)
SWEP.InspectAng = Angle(5, 25, 3)

SWEP.MuzzleEffect = "muzzleflash_pistol"
SWEP.ShellModel = "models/shells/shell_9mm.mdl"
SWEP.ShellScale = 1

SWEP.Attachments = {
	[1] = {
		slot = "optic",
		name = "Optic",
		options = {"att_optic_reddot"},
		bone = "v_weapon.slide",
		pos = Vector(0, 0, 0),
		ang = Angle(0, 0, 0),
	},
	[2] = {
		slot = "muzzle",
		name = "Muzzle",
		options = {"att_suppressor"},
		bone = "v_weapon.muzzle",
		pos = Vector(0, 0, 0),
		ang = Angle(0, 0, 0),
	},
	[3] = {
		slot = "tactical",
		name = "Tactical",
		options = {"att_laser"},
		bone = "v_weapon.grip",
		pos = Vector(0, 0, 0),
		ang = Angle(0, 0, 0),
	},
}

function SWEP:ResetToBaseStats()
	self.Primary.Damage = 22
	self.Primary.DamageMin = 12
	self.Primary.Spread = 0.015
	self.Primary.Recoil = 0.8
	self.Primary.RecoilSide = 0.4
	self.Primary.RPM = 650
end