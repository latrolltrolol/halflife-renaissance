include('shared.lua')

language.Add("weapon_9mmhandgun", "9MM Handgun")
killicon.Add("weapon_9mmhandgun","HUD/killicons/9mm_handgun",Color ( 255, 80, 0, 255 ) )

SWEP.PrintName = "9mm Handgun"
SWEP.Slot = 1
SWEP.SlotPos = 3
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModelFOV = 90
SWEP.ViewModelFlip = false

SWEP.WepSelectIcon = surface.GetTextureID("HUD/swepicons/9mmhandgun") 
SWEP.BounceWeaponIcon = false 
