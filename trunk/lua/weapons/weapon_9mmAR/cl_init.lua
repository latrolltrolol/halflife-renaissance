include('shared.lua')

language.Add("weapon_9mmar", "MP5")
killicon.Add("weapon_9mmar","HUD/killicons/9mm_ar",Color ( 255, 80, 0, 255 ) )

SWEP.PrintName = "MP5"
SWEP.Slot = 2
SWEP.SlotPos = 3
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModelFOV = 90
SWEP.ViewModelFlip = false

SWEP.WepSelectIcon = surface.GetTextureID("HUD/swepicons/9mmAR") 
SWEP.BounceWeaponIcon = false 