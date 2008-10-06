if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
	SWEP.HoldType			= "grenade"
end

SWEP.Author = "Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Base = "base_swep_h"
SWEP.Category		= "Half-Life 1"
SWEP.GotGlobalClip = false

SWEP.GotSecondary = false

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/v_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_eq_fraggrenade_thrown.mdl"

SWEP.Primary.Sound		= Sound( "weapons/hks1.wav" )
SWEP.Primary.Recoil			= 2.5
SWEP.Primary.Delay			= 1.8

SWEP.Primary.MaxClipSize		= 10
SWEP.Primary.DefaultClip	= 10
SWEP.Primary.AmmoCount = 10
SWEP.Primary.ClipSize		= 10
SWEP.Primary.Automatic		= false
SWEP.Primary.ShootInWater		= true
SWEP.Primary.Ammo			= "Grenades"
SWEP.Primary.BulletType = "none"
SWEP.Primary.Global = true
SWEP.Primary.Reload = false
SWEP.Primary.PickUpAmmo = 1
SWEP.Primary.Limited = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.ShootInWater		= false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.PickUpAmmo = 0


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
	if CLIENT or ( SERVER and ValidEntity( self.Owner ) ) then return end
	self.gr_mdl = ents.Create( "prop_dynamic_override" )
	self.gr_mdl:SetPos( self:GetPos() )
	self.gr_mdl:SetAngles( self:GetAngles() )
	self.gr_mdl:SetModel( "models/w_grenade.mdl" )
	self.gr_mdl:Spawn()
	self.gr_mdl:Activate()
	self.gr_mdl:SetParent( self )
	self:SetColor( 255, 255, 255, 0 )
	self:DrawShadow( false )
end


/*---------------------------------------------------------
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy()
	if !self then return end
	if self.attack then
		self.attack = false
		self.attackstarttime = nil
		self:RemTimer()
	end

	if self.Owner:GetCustomAmmo( self.Primary.Ammo ) > 0 then
		self:Draw()
		return true
	else
		return false
	end
end 

function SWEP:Draw()
	if !self then return end
	if self.Owner:GetCustomAmmo( self.Primary.Ammo ) > 0 then
		self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
		timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 0.6, 1, function() if self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	end
end

/*---------------------------------------------------------
   Think does nothing
---------------------------------------------------------*/
function SWEP:Think()
	if self.attack and !self.Owner:KeyDown( IN_ATTACK ) then
		self.attack = false
		self.grenade_explodedelay = 3 -(CurTime() -self.attackstarttime)
		self.attackstarttime = nil
		self:ThrowGrenade()
	end
end

function SWEP:ThrowGrenade()
	if CLIENT then return end
	local function gr_throw()
		if self.Owner:IsPlayer() then
			self:TakePrimaryAmmo( 1 )
		end
		local grenade_phys = ents.Create( "monster_handgrenade" )
		grenade_phys.damage = sk_wep_gren_value
		grenade_phys.owner = self.Owner
		grenade_phys.type = "hgrenade"
		grenade_phys.explodedelay = self.grenade_explodedelay
		grenade_phys:SetModel( "models/weapons/w_eq_fraggrenade_thrown.mdl" )
		grenade_phys:SetOwner( self.Owner )
		grenade_phys:SetPos( self.Owner:GetShootPos() )
		grenade_phys:SetColor( 255, 255, 255, 0 )
		grenade_phys:DrawShadow( false )

		grenade_phys:Spawn()
		grenade_phys:Activate()
		
		grenade_phys.parentent = ents.Create( "prop_physics" )
		grenade_phys.parentent:SetModel( "models/w_grenade.mdl" )
		grenade_phys.parentent:SetPos( grenade_phys:GetPos() )
		grenade_phys.parentent:SetAngles( grenade_phys:GetAngles() )
		grenade_phys.parentent:Spawn()
		grenade_phys.parentent:Activate()
		
		grenade_phys.parentent:SetParent( grenade_phys )
		
		local phys = grenade_phys:GetPhysicsObject()
		if phys:IsValid() then
			local pl_eye_ang = self.Owner:EyeAngles()
			local grenade_phys_throwpos = self.Owner:GetShootPos() + pl_eye_ang:Right() * 5 - pl_eye_ang:Up() * 7
			local grenade_phys_throwpos_f = ( util.TraceLine( util.GetPlayerTrace( self.Owner ) ).HitPos - grenade_phys_throwpos ):GetNormalized()
			phys:SetVelocity( grenade_phys_throwpos_f * 800 )
		end
		local rand = math.random(1,3)
		if rand == 1 then
			self.Weapon:SendWeaponAnim( ACT_HANDGRENADE_THROW1 )
		elseif rand == 2 then
			self.Weapon:SendWeaponAnim( ACT_HANDGRENADE_THROW2 )
		else
			self.Weapon:SendWeaponAnim( ACT_HANDGRENADE_THROW3 )
		end
		timer.Create( "Draw_timer" .. self:EntIndex(), 0.3, 1, function() if self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) then self:Draw() end end )
	end
	timer.Create( "throw_delay_timer" .. self:EntIndex(), 0.6, 1, function() if self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) then gr_throw() end end )
end

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if ( !self:CanPrimaryAttack() ) then return end
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) 		// View model animation
	
	if ( self.Owner:IsNPC() ) then self:ThrowGrenade(); return end
	self.attack = true
	self.attackstarttime = CurTime()
	self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation
	
	// Punch the player's view
	//self.Owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	
end

/*---------------------------------------------------------
   Name: SWEP:CanPrimaryAttack( )
   Desc: Helper function for checking for no ammo
---------------------------------------------------------*/
function SWEP:CanPrimaryAttack()
	if ( ( !self.Primary.Global and self:GetAmmo( self.Primary.Ammo ) <= 0 ) or ( self.Primary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 ) or ( !self.Primary.ShootInWater and self.Owner:WaterLevel() == 3 ) ) then
		self:SetNextPrimaryFire( CurTime() + 0.2 )
		if self.ReloadOnEmpty and self:GetAmmo( self.Primary.Ammo ) <= 0 then self:Reload() end
		return false
		
	end

	return true

end

/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
end


function SWEP:Reload()
end

function SWEP:RemTimer()
	timer.Destroy( "VM_Idle_anim_timer_2" .. self:EntIndex() )
	timer.Destroy( "Draw_timer" .. self:EntIndex() )
	timer.Destroy( "throw_delay_timer" .. self:EntIndex() )
end

function SWEP:OnRemove()
	self:RemTimer()
	if self.gr_mdl and ValidEntity( self.gr_mdl ) then
		self.gr_mdl:Remove()
	end
end