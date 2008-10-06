include('shared.lua')

language.Add("weapon_satchel", "Satchel")
killicon.Add("weapon_satchel","HUD/killicons/satchel",Color ( 255, 80, 0, 255 ) )

SWEP.PrintName = "Satchel"
SWEP.Slot = 4
SWEP.SlotPos = 5
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = false
SWEP.ViewModelFOV = 85
SWEP.ViewModelFlip = false

SWEP.WepSelectIcon = surface.GetTextureID("HUD/swepicons/satchel") 
SWEP.BounceWeaponIcon = false 

function Set_Model( um )
	local Model = um:ReadString()
	for k,v in pairs( ents.FindByClass( "viewmodel" ) ) do
		v:SetModel( Model )
	end
end
usermessage.Hook( "Set_Model", Set_Model ) 