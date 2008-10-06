
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )
include( "ai_translations.lua" )

SWEP.Weight				= 5			// Decides whether we should switch from/to this
SWEP.AutoSwitchTo		= true		// Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= true		// Auto switch from if you pick up a better weapon

local ActIndex = {}
	ActIndex[ "pistol" ] 		= ACT_HL2MP_IDLE_PISTOL
	ActIndex[ "smg" ] 			= ACT_HL2MP_IDLE_SMG1
	ActIndex[ "grenade" ] 		= ACT_HL2MP_IDLE_GRENADE
	ActIndex[ "ar2" ] 			= ACT_HL2MP_IDLE_AR2
	ActIndex[ "shotgun" ] 		= ACT_HL2MP_IDLE_SHOTGUN
	ActIndex[ "rpg" ]	 		= ACT_HL2MP_IDLE_RPG
	ActIndex[ "physgun" ] 		= ACT_HL2MP_IDLE_PHYSGUN
	ActIndex[ "crossbow" ] 		= ACT_HL2MP_IDLE_CROSSBOW
	ActIndex[ "melee" ] 		= ACT_HL2MP_IDLE_MELEE
	ActIndex[ "slam" ] 			= ACT_HL2MP_IDLE_SLAM
	ActIndex[ "normal" ]		= ACT_HL2MP_IDLE
	
	
/*---------------------------------------------------------
   Name: SetWeaponHoldType
   Desc: Sets up the translation table, to translate from normal 
			standing idle pose, to holding weapon pose.
---------------------------------------------------------*/
function SWEP:SetWeaponHoldType( t )

	local index = ActIndex[ t ]
	
	/*if (index == nil) then
		Msg( "SWEP:SetWeaponHoldType - ActIndex[ \""..t.."\" ] isn't set!\n" )
		return
	end*/

	self.ActivityTranslate = {}
	self.ActivityTranslate [ ACT_HL2MP_IDLE ] 					= index
	self.ActivityTranslate [ ACT_HL2MP_WALK ] 					= index+1
	self.ActivityTranslate [ ACT_HL2MP_RUN ] 					= index+2
	self.ActivityTranslate [ ACT_HL2MP_IDLE_CROUCH ] 			= index+3
	self.ActivityTranslate [ ACT_HL2MP_WALK_CROUCH ] 			= index+4
	self.ActivityTranslate [ ACT_HL2MP_GESTURE_RANGE_ATTACK ] 	= index+5
	self.ActivityTranslate [ ACT_HL2MP_GESTURE_RELOAD ] 		= index+6
	self.ActivityTranslate [ ACT_HL2MP_JUMP ] 					= index+7
	self.ActivityTranslate [ ACT_RANGE_ATTACK1 ] 				= index+8
	
	self:SetupWeaponHoldTypeForAI( t )

end

// Default hold pos is the pistol
SWEP:SetWeaponHoldType( "pistol" )

/*---------------------------------------------------------
   Name: weapon:TranslateActivity( )
   Desc: Translate a player's Activity into a weapon's activity
		 So for example, ACT_HL2MP_RUN becomes ACT_HL2MP_RUN_PISTOL
		 Depending on how you want the player to be holding the weapon
---------------------------------------------------------*/
function SWEP:TranslateActivity( act )

	if ( self.Owner:IsNPC() ) then
		if ( self.ActivityTranslateAI[ act ] ) then
			return self.ActivityTranslateAI[ act ]
		end
		return -1
	end

	if ( self.ActivityTranslate[ act ] != nil ) then
		return self.ActivityTranslate[ act ]
	end
	
	return -1

end


/*---------------------------------------------------------
   Name: AcceptInput
   Desc: Accepts input, return true to override/accept input
---------------------------------------------------------*/
function SWEP:AcceptInput( name, activator, caller, data )
	return false
end


/*---------------------------------------------------------
   Name: KeyValue
   Desc: Called when a keyvalue is added to us
---------------------------------------------------------*/
function SWEP:KeyValue( key, value )
end

function SWEP:CalculatePrimaryPickUpAmmo( NewOwner )
	if !self.Primary.Limited then return self.Primary.PickUpAmmo end
	self.ammo = 0
	for i = 1, self.Primary.PickUpAmmo do
		if NewOwner:GetCustomAmmo( self.Primary.Ammo ) +self.ammo < self.Primary.MaxClipSize then
			self.ammo = self.ammo +1
		end
	end
	return self.ammo
end

function SWEP:CalculateSecondaryPickUpAmmo( NewOwner )
	if !self.Secondary.Limited then return self.Secondary.PickUpAmmo end
	self.ammo = 0
	for i = 1, self.Secondary.PickUpAmmo do
		if NewOwner:GetCustomAmmo( self.Secondary.Ammo ) +self.ammo < self.Secondary.MaxClipSize then
			self.ammo = self.ammo +1
		end
	end
	return self.ammo
end

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
	if self.st_mdl and ValidEntity( self.st_mdl ) then
		self.st_mdl:Remove()
	end
end 

/*---------------------------------------------------------
   Name: EquipAmmo
   Desc: The player has picked up the weapon and has taken the ammo from it
		The weapon will be removed immidiately after this call.
---------------------------------------------------------*/
function SWEP:EquipAmmo( NewOwner )
	local NewPrimAmmo = self:CalculatePrimaryPickUpAmmo( NewOwner )
	local NewSecAmmo = self:CalculateSecondaryPickUpAmmo( NewOwner )
	if NewPrimAmmo > 0 then
		local rp = RecipientFilter() 
		rp:AddPlayer( NewOwner )

		umsg.Start( "ItemPickedUp", rp )
		umsg.String( self.Primary.Ammo .. "," .. NewPrimAmmo )
		umsg.End() 
	end
	if NewSecAmmo > 0 then
		local rp = RecipientFilter() 
		rp:AddPlayer( NewOwner )

		umsg.Start( "ItemPickedUp", rp )
		umsg.String( self.Secondary.Ammo .. "," .. NewSecAmmo )
		umsg.End() 
	end
	NewOwner:EmitSound( "items/ammo_pickup.wav", 100, 100 )
	self:Equip( NewOwner )
	self.Primary.AmmoToGive = nil
	self.Secondary.AmmoToGive = nil
end


/*---------------------------------------------------------
   Name: OnDrop
   Desc: Weapon was dropped
---------------------------------------------------------*/
function SWEP:OnDrop()

end

/*---------------------------------------------------------
   Name: ShouldDropOnDie
   Desc: Should this weapon be dropped when its owner dies?
---------------------------------------------------------*/
function SWEP:ShouldDropOnDie()
	return true
end


/*---------------------------------------------------------
   Name: NPCShoot_Secondary
   Desc: NPC tried to fire secondary attack
---------------------------------------------------------*/
function SWEP:NPCShoot_Secondary( ShootPos, ShootDir )

	self:SecondaryAttack()

end

/*---------------------------------------------------------
   Name: NPCShoot_Secondary
   Desc: NPC tried to fire primary attack
---------------------------------------------------------*/
function SWEP:NPCShoot_Primary( ShootPos, ShootDir )

	self:PrimaryAttack()

end

// These tell the NPC how to use the weapon
AccessorFunc( SWEP, "fNPCMinBurst", 		"NPCMinBurst" )
AccessorFunc( SWEP, "fNPCMaxBurst", 		"NPCMaxBurst" )
AccessorFunc( SWEP, "fNPCFireRate", 		"NPCFireRate" )
AccessorFunc( SWEP, "fNPCMinRestTime", 	"NPCMinRest" )
AccessorFunc( SWEP, "fNPCMaxRestTime", 	"NPCMaxRest" )


