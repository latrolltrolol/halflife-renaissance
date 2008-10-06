include('shared.lua')

SWEP.PrintName = "Hornet Gun"
SWEP.Slot = 3
SWEP.SlotPos = 6
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = false 
SWEP.ViewModelFOV = 90

SWEP.WepSelectIcon = surface.GetTextureID("HUD/swepicons/hornetgun") 
SWEP.BounceWeaponIcon = false 

function SWEP:CustomAmmoDisplay()
	self.AmmoDisplay = self.AmmoDisplay or {}
	self.AmmoDisplay.Draw = true
	self.AmmoDisplay.PrimaryClip 	= self.Weapon:Clip1()
	self.AmmoDisplay.PrimaryAmmo 	= "AlyxGun"
	self.AmmoDisplay.SecondaryAmmo 	= -1
	return self.AmmoDisplay
end