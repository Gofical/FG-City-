-- ZCity Optimized - Example Rifle
-- AR-15 style rifle

AddCSLuaFile()

SWEP.Base = "zc_weapon_base"
SWEP.PrintName = "M4A1"
SWEP.Category = "ZCity Optimized - Rifles"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/cstrike/c_rif_m4a1.mdl"
SWEP.WorldModel = "models/weapons/w_rif_m4a1.mdl"

SWEP.Primary = {
	Ammo = "smg1",
	ClipSize = 30,
	DefaultClip = 90,
	Automatic = true,
	Damage = 28,
	DamageMin = 18,
	Range = 5000,
	Spread = 0.01,
	Recoil = 1.2,
	RecoilSide = 0.6,
	RPM = 800,
	Force = 1.5,
	Tracer = 1,
	Num = 1,
	Sound = "Weapon_M4A1.Single",
	SoundSilenced = "Weapon_M4A1.Silenced",
}

SWEP.ReloadTime = 2.5
SWEP.ReloadEmptyTime = 3.2
SWEP.ReloadSound = "Weapon_M4A1.Reload"

SWEP.Weight = 3.2
SWEP.Length = 30
SWEP.HoldType = "ar2"
SWEP.HoldTypeSights = "ar2"

SWEP.IronSightsPos = Vector(-7.5, -6, 1.5)
SWEP.IronSightsAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(2, 0, -2)
SWEP.SprintAng = Angle(-15, 30, 0)

SWEP.InspectPos = Vector(10, -6, -2)
SWEP.InspectAng = Angle(10, 35, 5)

SWEP.MuzzleEffect = "muzzleflash_rifle"
SWEP.ShellModel = "models/shells/shell_556.mdl"
SWEP.ShellScale = 1.2

SWEP.FireModes = {"auto", "semi", "burst"}

SWEP.Attachments = {
	[1] = {
		slot = "optic",
		name = "Optic",
		options = {"att_optic_reddot", "att_optic_acog", "att_optic_scope"},
		bone = "v_weapon.top",
		pos = Vector(0, 0, 0),
		ang = Angle(0, 0, 0),
	},
	[2] = {
		slot = "muzzle",
		name = "Muzzle",
		options = {"att_suppressor", "att_compensator", "att_flashhider"},
		bone = "v_weapon.muzzle",
		pos = Vector(0, 0, 0),
		ang = Angle(0, 0, 0),
	},
	[3] = {
		slot = "grip",
		name = "Grip",
		options = {"att_grip", "att_grip_angled", "att_bipod"},
		bone = "v_weapon.grip",
		pos = Vector(0, 0, 0),
		ang = Angle(0, 0, 0),
	},
	[4] = {
		slot = "tactical",
		name = "Tactical",
		options = {"att_laser", "att_flashlight"},
		bone = "v_weapon.handguard",
		pos = Vector(0, 0, 0),
		ang = Angle(0, 0, 0),
	},
}

function SWEP:ResetToBaseStats()
	self.Primary.Damage = 28
	self.Primary.DamageMin = 18
	self.Primary.Spread = 0.01
	self.Primary.Recoil = 1.2
	self.Primary.RecoilSide = 0.6
	self.Primary.RPM = 800
end