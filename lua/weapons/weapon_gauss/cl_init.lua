include('shared.lua')

language.Add("weapon_gauss", "Gauss cannon")
killicon.Add("weapon_gauss","HUD/killicons/weapon_gauss",Color ( 255, 80, 0, 255 ) )

SWEP.PrintName = "Gauss Cannon"
SWEP.Slot = 3
SWEP.SlotPos = 4
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModelFOV = 75
SWEP.ViewModelFlip = false

SWEP.WepSelectIcon = surface.GetTextureID("HUD/swepicons/weapon_gauss") 
SWEP.BounceWeaponIcon = false 

function SWEP:Think()
	if self.Owner and self.Owner:GetActiveWeapon( ) != self then return end
	//if !self:GetNetworkedBool( 1 ) then return end
	self:SetNetworkedBool( 1, false )
	local Owner = self:GetOwner()
	local vm = Owner:GetViewModel()
	local attachment = vm:GetAttachment(1)
	StartPos = attachment.Pos
	RunConsoleCommand("SendText",tostring(StartPos))
	self:NextThink(CurTime() +0.08)
end
