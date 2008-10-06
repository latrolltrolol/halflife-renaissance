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

SWEP.ViewModel = "models/weapons/v_gauss.mdl"
SWEP.WorldModel = "models/weapons/w_gauss.mdl"

SWEP.Primary.Fire   		= Sound( "weapons/gauss2.wav" )
SWEP.Primary.FireUnderWater			= Sound( "weapons/electro4.wav" )
SWEP.Primary.Zap1			= Sound( "weapons/electro4.wav" )
SWEP.Primary.StaticDischarge			= Sound( "weapons/electro5.wav" )
SWEP.Primary.Zap2			= Sound( "weapons/electro6.wav" )

SWEP.GotGlobalClip = false
SWEP.GotPrimary = true
SWEP.GotSecondary = false
SWEP.NextIronChs = 0
SWEP.ReloadOnEmpty = false

SWEP.Primary.Recoil			= 6
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.08
SWEP.Primary.Delay			= 0.2

SWEP.Primary.MaxClipSize		= 100
SWEP.Primary.ClipSize		= 100
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.AmmoCount = 100
SWEP.Primary.Automatic		= true
SWEP.Primary.ShootInWater		= false
SWEP.Primary.Ammo			= "gauss"
SWEP.Primary.BulletType = "none"
SWEP.Primary.Global = true
SWEP.Primary.Reload = false
SWEP.Primary.PickUpAmmo = 20
SWEP.Primary.Limited = true
SWEP.Primary.playsoundonempty = false

SWEP.Secondary.Damage			= 120

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.ShootInWater		= false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.PickUpAmmo = 0
SWEP.Secondary.Delay = 1

SWEP.chargecount = 0

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
	
	self.Primary.Spin = CreateSound( self, "ambience/pulsemachine.wav" )
end

function SWEP:ShootZap( damage, force, beamwidth, scorchdecal )
	if CLIENT then return end
	self.Primary.Spin:Stop()
	self.spinsoundpitch = nil
	self.startcharge = false
	self.overloaddelay = nil
	self.chargeforcedelay = nil
	self.Owner:EmitSound( self.Primary.Fire, 100, math.Rand(98, 110) )
	
	self.charging = false
	self.chargecount = 0

	if self.Owner:IsPlayer() then
		self.trace_beamtarget = self.Owner:GetEyeTrace()
	else
		local pos = self.Owner:GetShootPos()
		local ang = self.Owner:GetAimVector()
		local tracedata = {}
		tracedata.start = pos
		tracedata.endpos = pos +(self.Owner:GetAimVector( ) *9999)
		tracedata.filter = self.Owner
		self.trace_beamtarget = util.TraceLine(tracedata)
	end
	local trace_beamtarget = self.trace_beamtarget
	self.trace_beamtarget = nil
	util.BlastDamage(self.Weapon,self.Owner,trace_beamtarget.HitPos,45,damage)
	if self.Owner:GetPos():Distance( trace_beamtarget.HitPos ) < 45 then self.Owner:TakeDamage( damage /2, self.Owner, self.Weapon ) end
	//if trace_beamtarget.Entity and ValidEntity( trace_beamtarget.Entity ) and ( trace_beamtarget.Entity:IsNPC() or trace_beamtarget.Entity:IsPlayer() ) and trace_beamtarget.Entity:Health() > 0 then
	//	trace_beamtarget.Entity:TakeDamage( damage, self.Owner, self )
	//end
	
	/*local Pos1 = trace_beamtarget.HitPos + trace_beamtarget.HitNormal
	local Pos2 = trace_beamtarget.HitPos - trace_beamtarget.HitNormal
	util.Decal("BulletProof", Pos1, Pos2) */

	if ( ( self.type and self.type == 1 ) or tonumber(sk_wep_gauss_deathmatch_value) == 1 ) and force then
		self.Owner:SetLocalVelocity( self.Owner:GetForward() *-1 *force )
	end
	
	if self.Owner:IsPlayer() then
		self:SetNetworkedBool( 1, true )
		local attachpos_str_l = attachpos_str
		attachpos_str = nil

		local vector_string = string.Explode( " ", attachpos_str_l )
		self.attachpos = Vector( tonumber(vector_string[1]), tonumber(vector_string[2]), tonumber(vector_string[3]) )
	else
		local AttachAngPos = self.Owner:GetAttachment( self.Owner:LookupAttachment( "anim_attachment_LH" ) )
		self.attachpos = AttachAngPos["Pos"]
	end
	local attachpos = self.attachpos
	self.attachpos = nil

	local effectdata = EffectData()
		effectdata:SetOrigin( trace_beamtarget.HitPos )
		effectdata:SetStart( attachpos )
		effectdata:SetMagnitude(20)
		effectdata:SetScale(5000)
	util.Effect("GaussTracer", effectdata)
	if !trace_beamtarget.Entity or ( trace_beamtarget.Entity and !trace_beamtarget.Entity:IsNPC() and !trace_beamtarget.Entity:IsPlayer() ) then
		local effectdata3 = EffectData()
			effectdata3:SetOrigin( trace_beamtarget.HitPos )
			effectdata3:SetStart( attachpos )
			effectdata3:SetScale(0.4)
		util.Effect("Sparks", effectdata3)
	end
	self:CreateBeam( attachpos, trace_beamtarget.HitPos, beamwidth )
	//Msg( "attachpos:DotProduct( trace_beamtarget.HitPos ) = " .. tostring(attachpos:DotProduct( trace_beamtarget.HitPos )) .. "\n" )
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	timer.Simple( 0.8, function() if self.Owner and self.Owner:GetActiveWeapon( ) == self then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	
	if self.Owner:IsNPC() then return end
	
	// Punch the player's view
	self.Owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
end

function SWEP:CreateBeam( StartPos, EndPos, beamwidth )
	self.beam = ents.Create( "env_beam" )
	self.beam:SetKeyValue( "life", "0" )
	self.beam:SetKeyValue( "BoltWidth", beamwidth )
	self.beam:SetKeyValue( "NoiseAmplitude", "0" )
	self.beam:SetKeyValue( "damage", "0" )
	self.beam:SetKeyValue( "Spawnflags", "1" )
	self.beam:SetKeyValue( "texture", "sprites/crystal_beam1.spr" ) //sprites/yellowlaser1.spr" )
			
	self.beamtarget = ents.Create( "info_target" )
	self.beamtarget:SetName( "guasscannon" .. self:EntIndex() .. "_target" )
	self.beamtarget:SetPos( StartPos )
	self.beamtarget:Spawn()
	self.beamtarget:Activate()

	self.beam:SetPos( EndPos )
	self.beam:SetName( "guasscannon" .. self:EntIndex() .. "_beam" )
	self.beam:SetKeyValue( "LightningStart", "guasscannon" .. self:EntIndex() .. "_beam" )
	self.beam:SetKeyValue( "LightningEnd", "guasscannon" .. self:EntIndex() .. "_target" )
	self.beam:Spawn()
	self.beam:Activate()
	self.beam:Fire( "Kill", "", 0.2 )
	self.beamtarget:Fire( "Kill", "", 0.2 )
	
	self.beam_la = ents.Create( "env_beam" )
	self.beam_la:SetKeyValue( "life", "0" )
	self.beam_la:SetKeyValue( "BoltWidth", 1 )
	self.beam_la:SetKeyValue( "NoiseAmplitude", "0.8" )
	self.beam_la:SetKeyValue( "damage", "0" )
	self.beam_la:SetKeyValue( "Spawnflags", "1" )
	self.beam_la:SetKeyValue( "texture", "sprites/rollermine_shock_yellow.spr" )
	self.beam_la:SetPos( EndPos )
	self.beam_la:SetName( "guasscannon" .. self:EntIndex() .. "_beam_la" )
	self.beam_la:SetKeyValue( "LightningStart", "guasscannon" .. self:EntIndex() .. "_beam_la" )
	self.beam_la:SetKeyValue( "LightningEnd", "guasscannon" .. self:EntIndex() .. "_target" )
	self.beam_la:Spawn()
	self.beam_la:Activate()
	self.beam_la:Fire( "Kill", "", 0.2 )
end

function RetrieveText(ply,cmd,args)
	local text = args[1]
	if (text != "" && text != nil) then
		attachpos_str = text
	end
end
concommand.Add("SendText",RetrieveText)

/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if ( !self:CanPrimaryAttack() ) then return end
	
	// Play shoot sound
	local rand = math.random(1,2)
	if rand == 1 then
		self.Owner:EmitSound( self.Primary.Zap1 )
	elseif rand == 2 then
		self.Owner:EmitSound( self.Primary.Zap2 )
	end
	self:ShootZap( sk_wep_gauss_value, nil, 2 )
	
	if ( self.Owner:IsNPC() ) then return end
	
	// Remove 1 bullet from our clip
	self:TakePrimaryAmmo( 2 )
	
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
	if ( ( !self.Primary.Global and self:GetAmmo( self.Primary.Ammo ) <= 1 ) or ( self.Primary.Global and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 1 ) or ( !self.Primary.ShootInWater and self.Owner:WaterLevel() == 3 ) ) then
		self:SetNextPrimaryFire( CurTime() + 0.2 )
		return false
		
	end
	return true
end

function SWEP:Think()
	if !self.Owner or self.Owner == NULL then return end
	
	if ( ( self.Owner:KeyDown(IN_ATTACK2) and ( self.startcharge or self.charging ) ) or ( self.chargeforcedelay and CurTime() <= self.chargeforcedelay ) ) and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) > 0 and self.Owner:WaterLevel() != 3 and !self.overloaddelay then
		if !self.chargedelay then self.chargedelay = CurTime() +0.15 end
		if CurTime() > self.chargedelay then
			self.chargedelay = nil
			self:Charge()
		end
	elseif self.charging and ( ( self.Owner:KeyDown(IN_ATTACK2) and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) == 0 ) or self.Owner:KeyReleased(IN_ATTACK2) or !self.Owner:KeyDown(IN_ATTACK2) ) then
		self:ShootZap( self.Secondary.Damage /12 *self.chargecount, self.chargecount *82, 12, true )
	elseif self.charging and self.overloaddelay and CurTime() > self.overloaddelay then
		self:Overload()
	end
	
	if self.charging and self.chargeanimdelay and CurTime() > self.chargeanimdelay then
		self.chargeanimdelay = CurTime() +0.5
		self.Weapon:SendWeaponAnim( ACT_VM_PULLBACK )
	end
	
	/*if self.charging and self.spinsoundpitch < 200 then
		self.Primary.Spin:ChangePitch( self.spinsoundpitch )
		self.spinsoundpitch = self.spinsoundpitch +10
	end*/
end

function SWEP:Charge()
	if self.chargecount < 11 then
		self.charging = true
		self.chargecount = self.chargecount +1
		self.Primary.Spin:ChangePitch( 110 +self.chargecount *20 )
		self:TakePrimaryAmmo( 1 )
	else
		self.overloaddelay = CurTime() +9
	end
end

function SWEP:Overload()
	if CLIENT then return end
	self.Primary.Spin:Stop()
	self.spinsoundpitch = nil
	self.overloaddelay = nil
	//self:EmitSound( self.Primary.Fire, 100, math.Rand(98, 110) )
	local rand = math.random(1,2)
	if rand == 1 then
		self.Owner:EmitSound( self.Primary.Zap1, 100, 100 )
	else
		self.Owner:EmitSound( self.Primary.StaticDischarge, 100, 100 )
	end
	
	self.Owner:TakeDamage( 50, self, self.Owner )
	self.charging = false
	self.chargeforcedelay = nil
	self.chargecount = 0
	self.startcharge = false
	self.waitsecond = CurTime() +3
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
end


SWEP.NextSecondaryAttack = 0
/*---------------------------------------------------------
	SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Secondary.Delay )

	if ( !self:CanPrimaryAttack() ) then return end
	self.Primary.Spin:Play()
	self.chargeforcedelay = CurTime() +0.5
	self.chargeanimdelay = CurTime() +0.5
	self.startcharge = true
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (SinglePlayer() && SERVER) || CLIENT ) then
			self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	
	self.Weapon:SendWeaponAnim( ACT_VM_PULLBACK_LOW )//ACT_VM_PRIMARYATTACK ) 		// View model animation
	//self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation
end