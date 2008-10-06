if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
	SWEP.HoldType			= "smg"
end

if ( CLIENT ) then
	SWEP.CSMuzzleFlashes	= true
end

SWEP.Author = "Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Base = "base_swep_h"
SWEP.Category		= "Half-Life 1"

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/v_9mmAR.mdl"
SWEP.WorldModel = "models/weapons/w_rif_m4a1.mdl"

SWEP.Primary.Sound1			= Sound( "weapons/hks1.wav" )
SWEP.Primary.Sound2			= Sound( "weapons/hks2.wav" )
SWEP.Primary.Sound3			= Sound( "weapons/hks3.wav" )
SWEP.Primary.Recoil			= 2.5
SWEP.Primary.Damage			= 8
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.08
SWEP.Primary.Delay			= 0.12

SWEP.Primary.MaxClipSize	= 250
SWEP.Primary.ClipSize		= 50
SWEP.Primary.DefaultClip	= 50
SWEP.Primary.AmmoCount = 306
SWEP.Primary.Automatic		= true
SWEP.Primary.ShootInWater		= false
SWEP.Primary.Ammo			= "9mm"
SWEP.Primary.BulletType = "smg1"
SWEP.Primary.Global = false
SWEP.Primary.Reload = true
SWEP.Primary.PickUpAmmo = 150
SWEP.Primary.Limited = true

SWEP.Secondary.MaxClipSize	= 10
SWEP.Secondary.Sound			= Sound( "weapons/grenade_launcher1.wav" )
SWEP.Secondary.ClipSize = 10
SWEP.Secondary.DefaultClip = 2
SWEP.Secondary.AmmoCount = 2
SWEP.Secondary.Automatic = true
SWEP.Secondary.ShootInWater		= true
SWEP.Secondary.Ammo = "9mmAR_Grenade"
SWEP.Secondary.Recoil			= 14
SWEP.Secondary.NumShots		= 1
SWEP.Secondary.Cone			= 0.01
SWEP.Secondary.Delay			= 1
SWEP.Secondary.BulletType = "none"
SWEP.Secondary.Global = true
SWEP.Secondary.Reload = false
SWEP.Secondary.PickUpAmmo = 2

SWEP.ReloadSound1			= Sound( "items/cliprelease1.wav" )
SWEP.ReloadSound2			= Sound( "items/clipinsert1.wav" )

SWEP.IronSightsPos 		= Vector (-7.0255, -5.7685, 2.0971)//Vector( -6.1, 2, -3)
SWEP.IronSightsAng 		= Vector (-0.801, -3.5802, -6.1811)//Vector( 8, 0, 0 )

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
	local rand = math.random(1,3)
	if rand == 1 then
		self.Weapon:EmitSound( self.Primary.Sound1 )
	elseif rand == 2 then
		self.Weapon:EmitSound( self.Primary.Sound2 )
	else
		self.Weapon:EmitSound( self.Primary.Sound3 )
	end
	
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

	if ( !self:CanSecondaryAttack() ) then return end
	self:EmitSound( self.Secondary.Sound )
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
			self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	
	if CLIENT then return end
	local grenade_phys = ents.Create( "monster_handgrenade" )
	grenade_phys.damage = sk_wep_mp5_gren_value
	grenade_phys.owner = self.Owner
	grenade_phys.type = "wgrenade"
	grenade_phys:SetOwner( self.Owner )
	grenade_phys:SetModel( "models/items/ar2_grenade.mdl" )
	grenade_phys:SetPos( self.Owner:GetShootPos() )


	local FireTrace = self:GetPos() +Vector( 30, 0, 0 )
	local Firevector = FireTrace:GetNormalized()
	local FireLength = FireTrace:Length()
	local ArriveTime = FireLength / 2000
	local BaseShootVector = Firevector * 600 + Vector(0,0,300 * ArriveTime)

	grenade_phys:Spawn()
	grenade_phys:Activate()
	local phys = grenade_phys:GetPhysicsObject()
	if phys:IsValid() then
		local pl_eye_ang = self.Owner:EyeAngles()
		local grenade_phys_throwpos = self.Owner:GetShootPos() + pl_eye_ang:Right() * 5 - pl_eye_ang:Up() * 7
		local grenade_phys_throwpos_f = ( util.TraceLine( util.GetPlayerTrace( self.Owner ) ).HitPos - grenade_phys_throwpos ):GetNormalized()
		phys:SetVelocity( grenade_phys_throwpos_f * 800 )
	end
	
	// Remove 1 bullet from our clip
	self:TakeSecondaryAmmo( 1 )
	
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) 		// View model animation
	self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation
		
	if ( self.Owner:IsNPC() ) then return end
		
	// Punch the player's view
	self.Owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Secondary.Recoil, math.Rand(-0.1,0.1) *self.Secondary.Recoil, 0 ) )
end