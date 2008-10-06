

// Variables that are used on both client and server

SWEP.Author			= ""
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.ViewModelFOV	= 62
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/weapons/v_pistol.mdl"
SWEP.WorldModel		= "models/weapons/w_357.mdl"
SWEP.AnimPrefix		= "python"
SWEP.ReloadOnEmpty = false
SWEP.playsoundonempty = true

SWEP.GotGlobalClip = true
SWEP.GotPrimary = true
SWEP.GotSecondary = true
SWEP.NextIronChs = 0

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.Primary.MaxClipSize		= 250
SWEP.Primary.ClipSize		= 8					// Size of a clip
SWEP.Primary.DefaultClip	= 32				// Default number of bullets in a clip
SWEP.Primary.AmmoCount = 306
SWEP.Primary.ShootInWater		= false
SWEP.Primary.Automatic		= false				// Automatic/Semi Auto
SWEP.Primary.Ammo			= "Pistol"
SWEP.Primary.Global = false
SWEP.Primary.Reload = true
SWEP.Primary.PickUpAmmo = 0
SWEP.Primary.playsoundonempty = true

SWEP.Secondary.MaxClipSize		= 250
SWEP.Secondary.ClipSize		= 8					// Size of a clip
SWEP.Secondary.DefaultClip	= 32				// Default number of bullets in a clip
SWEP.Secondary.AmmoCount = 2
SWEP.Secondary.ShootInWater		= false
SWEP.Secondary.Automatic	= false				// Automatic/Semi Auto
SWEP.Secondary.Ammo			= "Pistol"
SWEP.Secondary.Global = true
SWEP.Secondary.Reload = true
SWEP.Secondary.PickUpAmmo = 0
SWEP.Secondary.playsoundonempty = true

SWEP.LastReload = 0

/*---------------------------------------------------------
---------------------------------------------------------*/
function SWEP:Initialize()

	if ( SERVER ) then
		self:SetWeaponHoldType( self.HoldType )
		self:SetNPCMinBurst( 30 )
		self:SetNPCMaxBurst( 30 )
		self:SetNPCFireRate( 0.01 )
	end
	
	self.Weapon:SetNetworkedBool( "Ironsights", false )
	ironsight_ply = nil
	
	if !self.Primary.Global then
		self:SetAmmo( self.Primary.Ammo, self.Primary.DefaultClip )
	end
	if !self.Secondary.Global then
		self:SetAmmo( self.Secondary.Ammo, self.Secondary.DefaultClip )
	end
end

/*---------------------------------------------------------
   Name: SWEP:Precache( )
   Desc: Use this function to precache stuff
---------------------------------------------------------*/
function SWEP:Precache()
end


/*---------------------------------------------------------
   Name: SWEP:PrimaryAttack( )
   Desc: +attack1 has been pressed
---------------------------------------------------------*/
function SWEP:PrimaryAttack()

	// Make sure we can shoot first
	if ( !self:CanPrimaryAttack() ) then return end

	// Play shoot sound
	self.Weapon:EmitSound("Weapon_AR2.Single")
	
	// Shoot 9 bullets, 150 damage, 0.75 aimcone
	self:ShootBullet( 150, 1, 0.01 )
	
	// Remove 1 bullet from our clip
	self:TakePrimaryAmmo( 1 )
	
	// Punch the player's view
	self.Owner:ViewPunch( Angle( -1, 0, 0 ) )

end


/*---------------------------------------------------------
   Name: SWEP:SecondaryAttack( )
   Desc: +attack2 has been pressed
---------------------------------------------------------*/
function SWEP:SecondaryAttack()

	// Make sure we can shoot first
	if ( !self:CanSecondaryAttack() ) then return end

	// Play shoot sound
	self.Weapon:EmitSound("Weapon_Shotgun.Single")
	
	// Shoot 9 bullets, 150 damage, 0.75 aimcone
	self:ShootBullet( 150, 9, 0.2 )
	
	// Remove 1 bullet from our clip
	self:TakeSecondaryAmmo( 1 )
	
	// Punch the player's view
	self.Owner:ViewPunch( Angle( -10, 0, 0 ) )

end

/*---------------------------------------------------------
   Name: SWEP:CheckReload( )
   Desc: CheckReload
---------------------------------------------------------*/
function SWEP:CheckReload()
	
end

/*------------------------------------
    Reload
------------------------------------*/
function SWEP:Reload( )

	local reloaded = false;

	// should reload?
	if( self.LastReload > CurTime() ) then return reloaded; end
	self.LastReload = CurTime() + 1.41;

	// reload primary
	if( self.Primary.Reload and self.Primary && self.Primary.Ammo && self.Primary.ClipSize != -1 ) then

		local available = self.Owner:GetCustomAmmo( self.Primary.Ammo );
		local ammo = self:GetAmmo( self.Primary.Ammo );
		// do we have any ammo available to put into this?
		if( ammo < self.Primary.ClipSize && available > 0 ) then
		
			self.Weapon:SendWeaponAnim( ACT_VM_RELOAD ) 
			self.Owner:SetAnimation( PLAYER_RELOAD )
			
			// how much ammo do we need
			local needs = math.min( self.Primary.ClipSize - ammo, available );
			self.add_prim = math.max( 0, needs );
			self:EmitSound( self.ReloadSound1 )
			// remove the ammo from the players bag.
			self.reloading = true
			self.reload_cur_start = CurTime()

			// add the ammo to our clip
			//self:SetAmmo( self.Primary.Ammo, self:GetAmmo( self.Primary.Ammo ) + add );

			// don't fire
			self:SetNextPrimaryFire( CurTime() + ( self.Primary.Delay || 0.25 ) + 1.4 );
			self:SetNextSecondaryFire( CurTime() + ( self.Primary.Delay || 0.25 ) + 1.4 );

			// flag
			reloaded = true;

		end

	end

	// reload secondary
	if( self.Secondary.Reload and self.Secondary && self.Secondary.Ammo && self.Secondary.ClipSize != -1 ) then
		local available = self.Owner:GetCustomAmmo( self.Secondary.Ammo );
		local ammo = self:GetAmmo( self.Secondary.Ammo );
		// do we have any ammo available to put into this?
		if( ammo < self.Secondary.ClipSize && available > 0 ) then
			// figure out how much ammo to add
			local needs = math.min( self.Secondary.ClipSize - ammo, available );
			local add = math.max( 0, needs );

			// remove the ammo from the players bag.
			self.Owner:AddCustomAmmo( self.Secondary.Ammo, -add );

			// add the ammo to our clip
			self:SetAmmo( self.Secondary.Ammo, self:GetAmmo( self.Secondary.Ammo ) + add );

			// don't fire
			self:SetNextSecondaryFire( CurTime() + ( self.Secondary.Delay || 0.25 ) + 0.5 );

			// flag
			reloaded = true;

		end

	end

	// toggle iron sights
	if( reloaded ) then

		self:SetIronsights( false );

	end

	return reloaded;

end 

/*---------------------------------------------------------
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy( )
	if !self then return end
	ironsight_ply = nil

	self.reloading = false
	self.r_emit = false
	self.add_prim = nil
	
	if self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) == 0 then return false end
	self:Draw()
	return true
end

function SWEP:Draw()
	if self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) == 0 then return false end
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 0.6, 1, function() if self.Owner and (self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self )) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	return true
end

/*------------------------------------
   SetAmmo
------------------------------------*/
function SWEP:SetAmmo( ammo, amt )
	self.Weapon:SetNetworkedInt( "ammo_" .. ammo, amt );
end

/*------------------------------------
    GetAmmo
------------------------------------*/
function SWEP:GetAmmo( ammo )
	return self.Weapon:GetNetworkedInt( "ammo_" .. ammo );
end

/*---------------------------------------------------------
   Think
---------------------------------------------------------*/
function SWEP:Think()	
	if ironsight_ply and ValidEntity( ironsight_ply ) then
		self:ToggleIronSight()
		ironsight_ply = nil
	end
	
	if self.reloading then
		if self.reload_cur_start +0.7 <= CurTime() and !self.r_emit then
			self:EmitSound( self.ReloadSound2 )
			self.r_emit = true
		end
		
		if self.reload_cur_start +1.4 <= CurTime() then
			self.r_emit = false
			self.reloading = false
			self.Owner:AddCustomAmmo( self.Primary.Ammo, -self.add_prim )
			self:SetAmmo( self.Primary.Ammo, self:GetAmmo( self.Primary.Ammo ) + self.add_prim )
			self.add_prim = nil
		end
	end
end

/*---------------------------------------------------------
   Name: GetCapabilities
   Desc: For NPCs, returns what they should try to do with it.
---------------------------------------------------------*/
function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1 | CAP_INNATE_RANGE_ATTACK1 | CAP_WEAPON_RANGE_ATTACK2 | CAP_INNATE_RANGE_ATTACK2
end


/*---------------------------------------------------------
   Name: SWEP:Holster( weapon_to_swap_to )
   Desc: Weapon wants to holster
   RetV: Return true to allow the weapon to holster
---------------------------------------------------------*/
function SWEP:Holster( wep )
	return true
end


/*---------------------------------------------------------
   Name: SWEP:ShootBullet( )
   Desc: A convenience function to shoot bullets
---------------------------------------------------------*/
function SWEP:ShootEffects()
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) 		// View model animation
	self:MuzzleFlash()								// Crappy muzzle light
	self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation
end


/*---------------------------------------------------------
   Name: SWEP:ShootBullet( )
   Desc: A convenience function to shoot bullets
---------------------------------------------------------*/
function SWEP:ShootBullet( damage, num_bullets, aimcone )
	
	local bullet = {}
	bullet.Num 		= num_bullets
	bullet.Src 		= self.Owner:GetShootPos()			// Source
	bullet.Dir 		= self.Owner:GetAimVector()			// Dir of bullet
	bullet.Spread 	= Vector( aimcone, aimcone, 0 )		// Aim Cone
	bullet.Tracer	= 5									// Show a tracer on every x bullets 
	bullet.Force	= 1									// Amount of force to give to phys objects
	bullet.Damage	= damage
	bullet.AmmoType = "Pistol"
	
	self.Owner:FireBullets( bullet )
	
	self:ShootEffects()
	
end


/*---------------------------------------------------------
   Name: SWEP:TakePrimaryAmmo(   )
   Desc: A convenience function to remove ammo
---------------------------------------------------------*/
function SWEP:TakePrimaryAmmo( num )
	
	// Doesn't use clips
	if ( ( !self.Primary.Global and self:GetAmmo( self.Primary.Ammo ) <= 0 ) or ( self.Primary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 ) ) then 
	
		//if ( self:Ammo1() <= 0 ) then return end
		
		//self.Owner:RemoveAmmo( num, self.Weapon:GetPrimaryAmmoType() )
	
	return end
	
	if self.Primary.Global then
		self.Owner:SetNetworkedInt( "ammo_" .. self.Primary.Ammo, self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) -num );
	else
		self:SetAmmo( self.Primary.Ammo, self:GetAmmo( self.Primary.Ammo ) -num )
	end
	
end


/*---------------------------------------------------------
   Name: SWEP:TakeSecondaryAmmo(   )
   Desc: A convenience function to remove ammo
---------------------------------------------------------*/
function SWEP:TakeSecondaryAmmo( num )
	
	// Doesn't use clips
	if ( ( !self.Secondary.Global and self:GetAmmo( self.Secondary.Ammo ) <= 0 ) or ( self.Secondary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Secondary.Ammo ) <= 0 ) ) then 
	
		//if ( self:Ammo2() <= 0 ) then return end
		
		//self.Owner:RemoveAmmo( num, self.Weapon:GetSecondaryAmmoType() )
	return end

	if self.Secondary.Global then
		self.Owner:SetNetworkedInt( "ammo_" .. self.Secondary.Ammo, self.Owner:GetCustomAmmo( self.Secondary.Ammo ) -num );
	else
		self:SetAmmo( self.Secondary.Ammo, self:GetAmmo( self.Secondary.Ammo ) -num )
	end
	
end


/*---------------------------------------------------------
   Name: SWEP:CanPrimaryAttack( )
   Desc: Helper function for checking for no ammo
---------------------------------------------------------*/
function SWEP:CanPrimaryAttack()
	if ( ( !self.Primary.Global and self:GetAmmo( self.Primary.Ammo ) <= 0 ) or ( self.Primary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 ) or ( !self.Primary.ShootInWater and self.Owner:WaterLevel() == 3 ) ) then
		if self.Primary.playsoundonempty then
			self:EmitSound( "Weapon_Pistol.Empty" )
		end
		self:SetNextPrimaryFire( CurTime() + 0.2 )
		if self.ReloadOnEmpty and self:GetAmmo( self.Primary.Ammo ) <= 0 then self:Reload() end
		return false
		
	end

	return true

end


/*---------------------------------------------------------
   Name: SWEP:CanSecondaryAttack( )
   Desc: Helper function for checking for no ammo
---------------------------------------------------------*/
function SWEP:CanSecondaryAttack()
	if ( ( !self.Secondary.Global and self:GetAmmo( self.Secondary.Ammo ) <= 0 ) or ( self.Secondary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Secondary.Ammo ) <= 0 ) or ( !self.Secondary.ShootInWater and self.Owner:WaterLevel() == 3 ) ) then
		if self.Secondary.playsoundonempty then
			self.Weapon:EmitSound( "Weapon_Pistol.Empty" )
		end
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.2 )
		return false
		
	end

	return true

end


/*---------------------------------------------------------
   Name: ContextScreenClick(  aimvec, mousecode, pressed, ply )
---------------------------------------------------------*/
function SWEP:ContextScreenClick( aimvec, mousecode, pressed, ply )
end

/*---------------------------------------------------------
	onRestore
	Loaded a saved game (or changelevel)
---------------------------------------------------------*/
function SWEP:OnRestore()

	self.NextIronChs = 0
	self:SetIronsights( false )
	
end

/*---------------------------------------------------------
   Name: OnRemove
   Desc: Called just before entity is deleted
---------------------------------------------------------*/
function SWEP:OnRemove()
end


/*---------------------------------------------------------
   Name: OwnerChanged
   Desc: When weapon is dropped or picked up by a new player
---------------------------------------------------------*/
function SWEP:OwnerChanged()
end


local IRONSIGHT_TIME = 0.25

/*---------------------------------------------------------
   Name: GetViewModelPosition
   Desc: Allows you to re-position the view model
---------------------------------------------------------*/
function SWEP:GetViewModelPosition( pos, ang )
	if ( !self.IronSightsPos ) then return pos, ang end
	local bIron = self.Weapon:GetNetworkedBool( "Ironsights" )
	
	if ( bIron != self.bLastIron ) then
	
		self.bLastIron = bIron 
		self.fIronTime = CurTime()
		
		if ( bIron ) then 
			self.SwayScale 	= 0.3
			self.BobScale 	= 0.1
		else 
			self.SwayScale 	= 1.0
			self.BobScale 	= 1.0
		end
	
	end
	
	local fIronTime = self.fIronTime or 0

	if ( !bIron && fIronTime < CurTime() - IRONSIGHT_TIME ) then 
		return pos, ang 
	end
	
	local Mul = 1.0
	
	if ( fIronTime > CurTime() - IRONSIGHT_TIME ) then
	
		Mul = math.Clamp( (CurTime() - fIronTime) / IRONSIGHT_TIME, 0, 1 )
		
		if (!bIron) then Mul = 1 - Mul end
	
	end

	local Offset	= self.IronSightsPos
	
	if ( self.IronSightsAng ) then
	
		ang = ang * 1
		ang:RotateAroundAxis( ang:Right(), 		self.IronSightsAng.x * Mul )
		ang:RotateAroundAxis( ang:Up(), 		self.IronSightsAng.y * Mul )
		ang:RotateAroundAxis( ang:Forward(), 	self.IronSightsAng.z * Mul )
	
	
	end
	
	local Right 	= ang:Right()
	local Up 		= ang:Up()
	local Forward 	= ang:Forward()
	
	

	pos = pos + Offset.x * Right * Mul
	pos = pos + Offset.y * Forward * Mul
	pos = pos + Offset.z * Up * Mul

	return pos, ang
	
end


/*---------------------------------------------------------
	SetIronsights
---------------------------------------------------------*/
function SWEP:SetIronsights( b )

	self.Weapon:SetNetworkedBool( "Ironsights", b )

end

function SWEP:ToggleIronSight()
	if ( self.NextIronChs > CurTime() or !self.IronSightsPos ) then return end
	bIronsights = !self.Weapon:GetNetworkedBool( "Ironsights", false )
	self:SetIronsights( bIronsights )
	self.NextIronChs = CurTime() + 0.3
end

/*---------------------------------------------------------
   Name: Ammo1
   Desc: Returns how much of ammo1 the player has
---------------------------------------------------------*/
function SWEP:Ammo1()
	return self.Owner:GetAmmoCount( self.Weapon:GetPrimaryAmmoType() )
end


/*---------------------------------------------------------
   Name: Ammo2
   Desc: Returns how much of ammo2 the player has
---------------------------------------------------------*/
function SWEP:Ammo2()
	return self.Owner:GetAmmoCount( self.Weapon:GetSecondaryAmmoType() )
end
