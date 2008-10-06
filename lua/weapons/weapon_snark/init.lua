AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false 

/*---------------------------------------------------------
  Name: Equip
  Desc: A player or NPC has picked the weapon up
//-------------------------------------------------------*/
function SWEP:Equip( NewOwner )
	if !NewOwner:GetCustomAmmo( self.Primary.Ammo ) then
		NewOwner:SetCustomAmmo( self.Primary.Ammo, self.Primary.AmmoCount )
	else
		NewOwner:SetCustomAmmo( self.Primary.Ammo, NewOwner:GetCustomAmmo( self.Primary.Ammo ) +self:CalculatePrimaryPickUpAmmo( NewOwner ) )
	end
	
	if !NewOwner:GetCustomAmmo( self.Secondary.Ammo ) then
		NewOwner:SetCustomAmmo( self.Secondary.Ammo, self.Secondary.AmmoCount )
	else
		NewOwner:SetCustomAmmo( self.Secondary.Ammo, NewOwner:GetCustomAmmo( self.Secondary.Ammo ) +self:CalculateSecondaryPickUpAmmo( NewOwner ) )
	end

	if ValidEntity( self.swep_item ) then
		self.swep_item:Remove()
	end
end 