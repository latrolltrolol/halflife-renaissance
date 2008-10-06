SWEP.Author = "Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = ""
SWEP.Instructions = ""

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/v_hgun.mdl"
SWEP.WorldModel = "models/w_hgun.mdl"

SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "GaussEnergy"
SWEP.attack = 0
SWEP.Category		= "Half-Life 1"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

local ShootSound1 = Sound( "hornet/fire.wav" )
function SWEP:Initialize()
	if SERVER then
		self.Weapon:SetWeaponHoldType("melee")
	end
	self:SetPos( self:GetPos() +Vector( 0, 0, 1 ) )
end

function SWEP:OnDrop()
	self:Remove()
end

function SWEP:Equip( NewOwner )
	if self.ammunition then
		self.Primary.DefaultClip = self.ammunition
		self:SetClip1( self.ammunition )
	end
end

function SWEP:EquipAmmo( NewOwner )
	local owner_weapon = NewOwner:GetWeapon( "weapon_hornetgun" )
	local weapon_clip = owner_weapon:Clip1()
	if( weapon_clip < self.Primary.DefaultClip ) then
		owner_weapon:SetClip1( self.Primary.DefaultClip )
	end
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
	if CLIENT then return end
	if self:Clip1() < 8 then
		if !self.wait_cur then self.wait_cur = CurTime() +0.5; return end
		if self.wait_cur <= CurTime() then
			self:SetClip1( self:Clip1() +1 )
			self.wait_cur = nil
		end
	end
end

function SWEP:Draw()
	if !self then return end
	if self:Clip1() > 0 and ( self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) ) then
		if self.attack == 0 then
			self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
			timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), 1.1, 1, function() if self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
		else
			self:SendWeaponAnim( ACT_VM_IDLE )
			self.attack = 0
		end
		local function Idle()
			if( self.attack == 0 and ( self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) ) ) then
				timer.Create( "Reset_anim_timer" .. self:EntIndex(), 2.52, 1, function() if self.Owner:IsNPC() or ( self.Owner:IsPlayer() and self.Owner:GetActiveWeapon( ) == self ) then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
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
		timer.Create( "Reset_anim_timer" .. self:EntIndex(), 2.52, 1, function() if self.Owner:GetActiveWeapon( ) == self then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	end
end

/*---------------------------------------------------------
   Name: SWEP:Deploy( )
   Desc: Whip it out
---------------------------------------------------------*/
function SWEP:Deploy()
	if self:Clip1() > 0 then
		self:Draw()
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

function SWEP:FireHornet()
	self:RemTimer()
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = pos+(ang*80)
	local trace = util.TraceLine(tracedata) 
	if trace.HitWorld then return end
	
	local trace = util.TraceLine(tracedata)
	if self:Clip1() > 0 then
		self:EmitSound( ShootSound1, 100, 100 )
		if CLIENT then return end
	
		self.attack = 1
		
		self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		timer.Create( "VM_Idle_anim_timer_1" .. self:EntIndex(), 0.56, 1, function() self:Draw() end )

		if self.owner:IsPlayer() then
			self.tr = self.Owner:GetEyeTrace()
			self:SetClip1( self:Clip1() -1 )
		elseif self.owner:IsNPC() then
			local AttachAngPos = self.Owner:GetAttachment( self.Owner:LookupAttachment( "anim_attachment_LH" ) )
			self.tr = AttachAngPos["Pos"]
		end
		hornetgun_owner = self.Owner
		
		local hornet = ents.Create( "monster_hornet" )
		
		hornet:SetPos( self.Owner:GetShootPos() )//self:LocalToWorld( Vector( 40, -10, 50 ) ) )
		hornet:SetModel( "models/props_junk/watermelon01_chunk02c.mdl" )
		hornet:SetMoveCollide( 3 )
		hornet:SetPhysicsAttacker( self.Entity )
		
		hornet.homing = self.homing
		hornet.HornetSpeed = 100
		hornet.Damage = sk_wep_hornet_value
		hornet.HornetSearchRadi = 500
			
		hornet.ownerpos = self:GetPos()
			
		hornet.owner = self.Owner
		hornet.enemy = hornet:SortEnemies( hornet )
		hornet.deploytime = 0
		hornet.buzztimer = 0
		
		hornet:Spawn()
		
		local phys = hornet:GetPhysicsObject()
			hornet:SetParent("")
			phys:SetMass(1)
			phys:EnableGravity( false )
			phys:EnableDrag( false )
			
		constraint.NoCollide( hornet, self.Owner, 0, 0 )

		local pl_eye_ang = self.Owner:EyeAngles()
		local hornet_flypos = self.Owner:GetShootPos() + pl_eye_ang:Right() * 5 - pl_eye_ang:Up() * 7
		local hornet_flypos_f = ( util.TraceLine( util.GetPlayerTrace( self.Owner ) ).HitPos - hornet_flypos ):GetNormalized()
		phys:ApplyForceCenter( hornet_flypos_f * 600 )
		self.homing = nil
	end
end

/*---------------------------------------------------------
PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	self.homing = true
	self:FireHornet()
		
	hornetgun_owner = nil
	self:SetNextPrimaryFire(CurTime() + 0.2)
end

/*---------------------------------------------------------
SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
	self.homing = false
	self:FireHornet()
		
	hornetgun_owner = nil
	self:SetNextSecondaryFire(CurTime() + 0.1)
end 

function SWEP:RemTimer()
	timer.Destroy( "VM_Idle_anim_timer_2" .. self:EntIndex() )
	timer.Destroy( "Reset_anim_timer" .. self:EntIndex() )
	timer.Destroy( "Idle_anim_timer" .. self:EntIndex() )
	timer.Destroy( "VM_Idle_anim_timer_1" .. self:EntIndex() )
end

function SWEP:OnRemove( )
	self:RemTimer()
end