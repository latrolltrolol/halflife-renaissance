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

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/v_satchel.mdl"
SWEP.WorldModel = "models/props_c17/briefcase001a.mdl"

SWEP.Primary.Sound		= Sound( "weapons/hks1.wav" )
SWEP.Primary.Delay			= 1.8

SWEP.Primary.MaxClipSize	= 5
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.ClipSize		= 5
SWEP.Primary.Automatic		= false
SWEP.Primary.ShootInWater		= true
SWEP.Primary.Ammo			= "satchel"
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
	self.st_mdl:SetModel( "models/w_satchel.mdl" )
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
	if self:Clip1() == 0 and !self.satchel_active then return false end
	self:Draw()
	return true
end 

function SWEP:Draw()
	if !self or ( self:Clip1() == 0 and !self.satchel_active ) then return false end
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 0.6, 1, function() if self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	return true
end

function SWEP:ToggleModel( Model )
	if CLIENT then return end
	if self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) then
		local rp = RecipientFilter() 
		rp:AddAllPlayers() 
		
		umsg.Start( "Set_Model", rp )
		umsg.String( Model )
		umsg.End() 
		
		self.ViewModel = Model
		self:Draw()
	end
end

function SWEP:ThrowSatchel()
	self:EmitSound( "weapons/slam/throw.wav", 100, 100 )
	if CLIENT then return end
	
	self:TakePrimaryAmmo( 1 )
	self.satchel_phys = ents.Create( "monster_satchel" )
	self.satchel_phys.damage = sk_wep_satchel_value
	self.satchel_phys.owner = self.Owner
	self.satchel_phys:SetModel( "models/props_c17/briefcase001a.mdl" )
	self.satchel_phys:SetOwner( self.Owner )
	self.satchel_phys:SetPos( self.Owner:GetShootPos() )
	self.satchel_phys:SetColor( 255, 255, 255, 0 )
	self.satchel_phys:DrawShadow( false )

	self.satchel_phys:Spawn()
	self.satchel_phys:Activate()
		
	self.satchel_phys.parentent = ents.Create( "prop_dynamic_override" )
	self.satchel_phys.parentent:SetModel( "models/w_satchel.mdl" )
	self.satchel_phys.parentent:SetPos( self.satchel_phys:GetPos() )
	self.satchel_phys.parentent:SetAngles( self.satchel_phys:GetAngles() +Vector(0,90,0) )
	self.satchel_phys.parentent:Spawn()
	self.satchel_phys.parentent:Activate()
	self.satchel_phys.parentent:SetSolid( SOLID_BBOX )
	self.satchel_phys.parentent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self.satchel_phys.parentent:SetCollisionBounds( Vector( 8, 4, 15 ), Vector( -8, -4, 0 ) )
		
	self.satchel_phys.parentent:SetParent( self.satchel_phys )
	
	local phys = self.satchel_phys:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetVelocity( self.Owner:GetForward() *500 )
	end
	self.Weapon:SendWeaponAnim( ACT_VM_HOLSTER )
	
	timer.Create( "Draw_timer" .. self:EntIndex(), 0.3, 1, function() if self.Owner and ( self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) ) then self:ToggleModel( "models/v_satchel_radio.mdl" ) end end )
end

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if ( !self:CanPrimaryAttack() ) then return end
	if !self.satchel_active then
		self:ThrowSatchel()
		self.satchel_active = true
	else
		self:EmitSound( "buttons/button9.wav", 100, 100 )
		self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		if ValidEntity( self.satchel_phys ) then
			self.satchel_phys:Explode()
		end
		self.satchel_active = false
		self.Weapon:SendWeaponAnim( ACT_VM_HOLSTER )
		timer.Create( "Draw_timer" .. self:EntIndex(), 0.6, 1, function() if self.Owner and ( self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) ) then self:ToggleModel( "models/v_satchel.mdl" ) end end )
	end
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
	if self.satchel_active then return end
	self:PrimaryAttack()
end

/*---------------------------------------------------------
   Name: SWEP:CanPrimaryAttack( )
   Desc: Helper function for checking for no ammo
---------------------------------------------------------*/
function SWEP:CanPrimaryAttack()
	if ( !self.satchel_active and ( ( !self.Primary.Global and self:GetAmmo( self.Primary.Ammo ) <= 0 ) or ( self.Primary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 ) or ( !self.Primary.ShootInWater and self.Owner:WaterLevel() == 3 ) ) ) then
		self:SetNextPrimaryFire( CurTime() + 0.2 )
		if self.ReloadOnEmpty and self:GetAmmo( self.Primary.Ammo ) <= 0 then self:Reload() end
		return false
		
	end

	return true

end

function SWEP:Reload()
end

function SWEP:Precache()
	util.PrecacheModel( "models/v_satchel_radio.mdl" )
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