if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
	SWEP.HoldType			= "pistol"
end

if ( CLIENT ) then
	SWEP.CSMuzzleFlashes	= true
end

SWEP.Author = "Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Base = "base_swep_h"
SWEP.GotSecondary = false
SWEP.Category		= "Half-Life 1"

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/v_9mmhandgun.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

SWEP.Primary.Sound			= Sound( "weapons/pl_gun3.wav" )
SWEP.Primary.Recoil			= 2.5
SWEP.Primary.Damage			= sk_wep_9mm_value
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.01
SWEP.Primary.Delay			= 0.34

SWEP.Primary.MaxClipSize		= 250
SWEP.Primary.ClipSize		= 18
SWEP.Primary.DefaultClip	= 18
SWEP.Primary.AmmoCount = 18
SWEP.Primary.Automatic		= true
SWEP.Primary.ShootInWater		= true
SWEP.Primary.Ammo			= "9mm"
SWEP.Primary.BulletType = "pistol"
SWEP.Primary.Global = false
SWEP.Primary.Reload = true
SWEP.Primary.PickUpAmmo = 64
SWEP.Primary.Limited = true

SWEP.Secondary.Sound			= Sound( "weapons/pl_gun3.wav" )
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.ShootInWater		= true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Recoil			= 2.5
SWEP.Secondary.Damage			= 8
SWEP.Secondary.NumShots		= 1
SWEP.Secondary.Cone			= 0.08
SWEP.Secondary.Delay			= 0.22
SWEP.Secondary.Global = false
SWEP.Secondary.Reload = false
SWEP.Secondary.PickUpAmmo = 0

SWEP.ReloadSound1			= Sound( "items/9mmclip2.wav" )
SWEP.ReloadSound2			= Sound( "items/9mmclip1.wav" )

SWEP.ReloadOnEmpty = true

SWEP.IronSightsPos 		= Vector (-8.0713, -0.8332, 3.9602)
SWEP.IronSightsAng 		= Vector (-0.3893, 0.0236, 0.5999)

function SWEP:ShootBullet( damage, num_bullets, aimcone )
	local bullet = {}
	bullet.Num = num_bullets
	bullet.Src = self.Owner:GetShootPos() 
	bullet.Dir = self.Owner:GetAimVector()
	bullet.Spread = Vector( aimcone, aimcone, 0 ) 
	bullet.Tracer = 4
	bullet.Force = 1 
	bullet.Damage = damage
	bullet.AmmoType = self.Primary.BulletType

	self.Owner:FireBullets( bullet )

	self:ShootEffects()
end 

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if ( !self:CanPrimaryAttack() ) then return end
	
	// Play shoot sound
	self.Weapon:EmitSound( self.Primary.Sound )
	
	// Shoot the bullet
	self:ShootBullet( self.Primary.Damage, self.Primary.NumShots, self.Primary.Cone )
	
	if ( self.Owner:IsNPC() ) then return end
	
	// Remove 1 bullet from our clip
	self:TakePrimaryAmmo( 1 )
	
	// Punch the player's view
	self.Owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	
end

SWEP.NextSecondaryAttack = 0
/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Secondary.Delay )
		
	if ( !self:CanPrimaryAttack() ) then return end
		
	// Play shoot sound
	self.Weapon:EmitSound( self.Secondary.Sound )
	
	// Shoot the bullet
	self:ShootBullet( self.Secondary.Damage, self.Secondary.NumShots, self.Secondary.Cone )
		
	// Remove 1 bullet from our clip
	self:TakePrimaryAmmo( 1 )
		
	if ( self.Owner:IsNPC() ) then return end
		
	// Punch the player's view
	self.Owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Secondary.Recoil, math.Rand(-0.1,0.1) *self.Secondary.Recoil, 0 ) )
		
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
			self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
end
