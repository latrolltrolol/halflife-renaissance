include('shared.lua')

SWEP.PrintName = "Gluon Cannon"
SWEP.Slot = 3
SWEP.SlotPos = 5
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModelFOV = 90
SWEP.ViewModelFlip = false

function SWEP:SetWeaponHoldType(t)
end

SWEP.WepSelectIcon = surface.GetTextureID("HUD/swepicons/weapon_egon") 
SWEP.BounceWeaponIcon = false 