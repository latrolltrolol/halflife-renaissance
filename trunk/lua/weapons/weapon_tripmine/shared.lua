if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
	SWEP.HoldType			= "slam"
end

SWEP.Author = "Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Base = "base_swep_h"
SWEP.Category		= "Half-Life 1"
SWEP.GotGlobalClip = false

SWEP.GotSecondary = false
SWEP.ReloadOnEmpty = false

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/v_tripmine.mdl"
SWEP.WorldModel = "models/w_tripmine.mdl"

SWEP.Primary.Delay			= 1.8

SWEP.Primary.MaxClipSize	= 5
SWEP.Primary.ClipSize		= 5
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Automatic		= false
SWEP.Primary.ShootInWater		= true
SWEP.Primary.Ammo			= "tripmine"
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
	self.st_mdl = ents.Create( "prop_dynamic_override" )
	self.st_mdl:SetPos( self:GetPos() )
	self.st_mdl:SetAngles( self:GetAngles() )
	self.st_mdl:SetModel( "models/w_tripmine.mdl" )
	self.st_mdl:Spawn()
	self.st_mdl:Activate()
	self.st_mdl:SetParent( self )
	self:SetColor( 255, 255, 255, 0 )
	self:DrawShadow( false )
end

/*---------------------------------------------------------
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy()
	if self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) == 0 then return false end
	self:Draw()
	return true
end 

function SWEP:Draw()
	if self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) == 0 then return false end
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 0.6, 1, function() if self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	return true
end

function SWEP:Think()
	if self.drawdelay and CurTime() > self.drawdelay then
		self.drawdelay = nil
		self:Draw()
	end
end

function SWEP:PlaceTripmine( trace )
	if CLIENT then return end
	self:TakePrimaryAmmo( 1 )
	self.tripmine = ents.Create( "monster_tripmine" )
	self.tripmine.owner = self.Owner
	self.tripmine:SetModel( "models/w_tripmine.mdl" )
	
	self.tripmine:SetPos( trace.HitPos +(trace.HitNormal:Angle():Forward( ) *8) )
	local tripmine_angle = trace.HitNormal:Angle()
	//tripmine_angle.y = self.Owner:GetAngles().y +180
	self.tripmine:SetAngles( tripmine_angle )

	self.tripmine:Spawn()
	self.tripmine:Activate()
	self.tripmine:EmitSound( "weapons/mine_deploy.wav", 100, 100 )
	
	self.Weapon:SendWeaponAnim( ACT_VM_HOLSTER )
	self.drawdelay = CurTime() +1
end

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if ( !self:CanPrimaryAttack() ) then return end
	
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = pos+(ang*80)
	tracedata.filter = self.Owner
	local trace = util.TraceLine(tracedata) 
	if !trace.HitWorld and ( !ValidEntity( trace.Entity ) or ( ValidEntity( trace.Entity ) and !ValidEntity( trace.Entity:GetPhysicsObject() ) ) ) then return end
	
	self:PlaceTripmine( trace )
	self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation
	if ( self.Owner:IsNPC() ) then return end
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	
end


/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
	self:PrimaryAttack()
end

/*---------------------------------------------------------
   Name: SWEP:CanPrimaryAttack( )
   Desc: Helper function for checking for no ammo
---------------------------------------------------------*/
function SWEP:CanPrimaryAttack()
	if ( ( ( !self.Primary.Global and self:GetAmmo( self.Primary.Ammo ) <= 0 ) or ( self.Primary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 ) or ( !self.Primary.ShootInWater and self.Owner:WaterLevel() == 3 ) ) ) then
		self:SetNextPrimaryFire( CurTime() + 0.2 )
		if self.ReloadOnEmpty and self:GetAmmo( self.Primary.Ammo ) <= 0 then self:Reload() end
		return false
		
	end

	return true

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
	if self.st_mdl and ValidEntity( self.st_mdl ) then
		self.st_mdl:Remove()
	end
end