include('shared.lua')

language.Add("weapon_handgrenade", "Grenade")
killicon.Add("weapon_handgrenade","HUD/killicons/handgrenade",Color ( 255, 80, 0, 255 ) )

SWEP.PrintName = "Handgrenade"
SWEP.Slot = 4
SWEP.SlotPos = 4
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = false
SWEP.ViewModelFOV = 85
SWEP.ViewModelFlip = false

SWEP.WepSelectIcon = surface.GetTextureID("HUD/swepicons/handgrenade") 
SWEP.BounceWeaponIcon = false 