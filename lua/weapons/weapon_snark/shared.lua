if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
	SWEP.HoldType			= "melee"
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

SWEP.ViewModel = "models/v_squeak.mdl"
SWEP.WorldModel = "models/w_SQKNEST.mdl"

SWEP.Primary.MaxClipSize	= 15
SWEP.Primary.ClipSize = 15
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = false
SWEP.Primary.ShootInWater		= true
SWEP.Primary.Ammo			= "snark"
SWEP.Primary.BulletType = "none"
SWEP.Primary.Global = true
SWEP.Primary.Reload = false
SWEP.Primary.PickUpAmmo = 5
SWEP.Primary.Limited = true

SWEP.attack = 0
SWEP.Primary.Delay			= 0.3

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.ShootInWater		= false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.PickUpAmmo = 0

local ShootSound1 = Sound( "npc/squeek/sqk_hunt1.wav" )
local ShootSound2 = Sound( "npc/squeek/sqk_hunt2.wav" )
local ShootSound3 = Sound( "npc/squeek/sqk_hunt3.wav" )
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
		self:DropToFloor()
		self:SetColor( 255, 255, 255, 0 )
		self.swep_item = ents.Create( "prop_dynamic_override" )
		self.swep_item:SetModel( "models/w_SQKNEST.mdl" )
		self.swep_item:SetPos( self:GetPos() )
		self.swep_item:SetAngles( self:GetAngles() )
		self.swep_item:SetKeyValue( "DefaultAnim", "idle" )
		self.swep_item:Spawn()
		self.swep_item:Activate()
		self.swep_item:SetParent( self )
		self.swep_item:Fire( "SetAnimation", "idle", 0 )
end

function SWEP:OnDrop()
	self:SetColor( 255, 255, 255, 255 )
end

/*---------------------------------------------------------
Reload does nothing
---------------------------------------------------------*/
function SWEP:Reload()
end


/*---------------------------------------------------------
Think
---------------------------------------------------------*/
function SWEP:Think()
end

function SWEP:Draw()
	if !self then return end
	if self:Clip1() > 0 and ( self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) ) then
		self.attack = 0
		self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
		timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 1.675, 1, function() if self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
		local function Idle()
			if( self.attack == 0 and ( self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) ) ) then
				timer.Create( "Reset_anim_timer" .. self:EntIndex(), 5.007, 1, function() if self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
				self:SendWeaponAnim(ACT_VM_FIDGET)
			end
		end
		timer.Create( "Idle_anim_timer" .. self:EntIndex(), math.random(12,16), 0, Idle )
	end
end

function SWEP:Idle()
	if !self then return end
	if( self.attack == 0 ) then
		self:SendWeaponAnim(ACT_VM_FIDGET)
		timer.Create( "Reset_anim_timer" .. self:EntIndex(), 5.007, 1, function() if self.Owner:GetActiveWeapon( ) == self then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	end
end

/*---------------------------------------------------------
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy()
	if self:Clip1() > 0 then
		self:Draw()
		self:EmitSound( "npc/squeek/sqk_hunt" .. math.random(1,3) .. ".wav", 100, 100 )
		return true
	else
		return false
	end
end 

/*function ENT:KeyValue( key, value )	
	if( key == "ammo" ) then
		self.ammunition = value
	end
end*/

/*---------------------------------------------------------
   Name: GetCapabilities
   Desc: For NPCs, returns what they should try to do with it.
---------------------------------------------------------*/
function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1 | CAP_INNATE_RANGE_ATTACK1
end

/*---------------------------------------------------------
PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if ( !self:CanPrimaryAttack() ) then return end
	
	local rand = math.random(1,3)
	if rand == 1 then
		self:EmitSound( ShootSound1, 100, 100 )
	elseif rand == 2 then
		self:EmitSound( ShootSound2, 100, 100 )
	else
		self:EmitSound( ShootSound3, 100, 100 )
	end
	
	if CLIENT then return end
	self:RemTimer()
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = pos+(ang*80)
	tracedata.filter = self.Owner
	local trace = util.TraceLine(tracedata) 
	if trace.HitWorld then return end
	
	local trace = util.TraceLine(tracedata)
		self.attack = 1
		
	//local throw_pos = self.enemy:GetPos() + Vector( 0, 0, 0 ) - self:GetPos()
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	timer.Create( "VM_Idle_anim_timer_1" .. self:EntIndex(), 0.56, 1, function() self:Draw() end )

	if self.owner:IsPlayer() then
		self.tr = self.Owner:GetEyeTrace()
		self:TakePrimaryAmmo( 1 )
	elseif self.owner:IsNPC() then
		local AttachAngPos = self.Owner:GetAttachment( self.Owner:LookupAttachment( "anim_attachment_LH" ) )
		self.tr = AttachAngPos["Pos"]
	end
	snarkgun_owner = self.Owner
	local snark = ents.Create( "monster_snark" )
	local snark_spawnpos = self:LocalToWorld( Vector( 40, 0, 0 ) )
	if self.owner:IsPlayer() then
		snark_spawnpos.z = self.tr.StartPos.z -16
	end
	snark:SetPos( snark_spawnpos )
	local snark_angles = self.owner:GetAngles()
	snark_angles.p = 0
	snark_angles.r = 0
	snark:SetAngles( snark_angles )
	snark:Spawn()
	snark:Activate()
	snark:Fire( "SetSquad", tostring(self.Owner) .. "_snarksquad", 0.1 )
	snarkgun_owner = nil
	constraint.NoCollide( snark, self.Owner, 0, 0 )
	local pl_eye_ang = self.Owner:EyeAngles()
	local snark_throwpos = self.Owner:GetShootPos() + pl_eye_ang:Right() * 5 - pl_eye_ang:Up() * 7
	local snark_throwpos_f = ( util.TraceLine( util.GetPlayerTrace( self.Owner ) ).HitPos - snark_throwpos ):GetNormalized()
	snark:SetVelocity( snark_throwpos_f * 500 )
	self:SetNextPrimaryFire(CurTime() + 0.3)
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

function SWEP:RemTimer()
	timer.Destroy( "VM_Idle_anim_timer_2" .. self:EntIndex() )
	timer.Destroy( "Reset_anim_timer" .. self:EntIndex() )
	timer.Destroy( "Idle_anim_timer" .. self:EntIndex() )
	timer.Destroy( "VM_Idle_anim_timer_1" .. self:EntIndex() )
end

function SWEP:OnRemove( )
	self:RemTimer()
	if ValidEntity( self.swep_item ) then
		self.swep_item:Remove()
	end
end