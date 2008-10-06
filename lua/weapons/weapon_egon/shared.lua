
if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false
	SWEP.HoldType			= "smg"
end

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.Author = "Garry, Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.Base = "base_swep_h"
SWEP.Category		= "Half-Life 1"

SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/v_egon.mdl"
SWEP.WorldModel = "models/w_egon.mdl"

SWEP.GotGlobalClip = false
SWEP.GotPrimary = true
SWEP.GotSecondary = false
SWEP.NextIronChs = 0

SWEP.Primary.StartSound			= Sound( "weapons/egon_windup2.wav" )
SWEP.Primary.RunSound			= Sound( "weapons/egon_run3.wav" )
SWEP.Primary.StopSound			= Sound( "weapons/egon_off1.wav" )
SWEP.Primary.Recoil			= 0
SWEP.Primary.Damage			= 4
SWEP.Primary.NumShots		= 0
SWEP.Primary.Cone			= 0
SWEP.Primary.Delay			= 1

SWEP.Primary.MaxClipSize		= 100
SWEP.Primary.ClipSize		= 100
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.AmmoCount = 100
SWEP.Primary.Automatic		= false
SWEP.Primary.ShootInWater		= false
SWEP.Primary.Ammo			= "gauss"
SWEP.Primary.BulletType = "none"
SWEP.Primary.Global = true
SWEP.Primary.Reload = false
SWEP.Primary.PickUpAmmo = 60
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
	self.sndPowerUp = CreateSound( self, self.Primary.StartSound )//"weapons/egon_windup2.wav" )
	self.sndAttackLoop 	= CreateSound( self, self.Primary.RunSound )//"weapons/egon_run3.wav" )
	self.sndPowerDown = CreateSound( self, self.Primary.StopSound )//"weapons/egon_off1.wav" )
	
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
//-------------------------------------------------------*/
function SWEP:Precache()
	util.PrecacheSound( "weapons/egon_windup2.wav" )
	util.PrecacheSound( "weapons/egon_run3.wav" )
	util.PrecacheSound( "weapons/egon_off1.wav" )
end 

function SWEP:Think()
	if !self.Owner or self.Owner == NULL then return end
	if self.Owner:KeyPressed(IN_ATTACK) and self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) > 0 and self.Owner:WaterLevel() != 3 then
		self:StartAttack()
	elseif self.Owner:KeyDown(IN_ATTACK) and self.attack and self.Owner:WaterLevel() != 3 then
		self:UpdateAttack()
	elseif self.Owner:KeyReleased(IN_ATTACK) and self.attack then
		self:EndAttack(true)
	elseif self.attack and ( !self.Owner:KeyPressed(IN_ATTACK) or self.Owner:WaterLevel() == 3 ) then
		self:EndAttack(true)
	end
end

function SWEP:StartAttack()
	if self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 then return end
	self.attack = true
	if SERVER then
		if !self.Beam then
			self.Beam = ents.Create("egon_beam")
			self.Beam:SetPos(self.Owner:GetShootPos())
			self.Beam:Spawn()
		end
		self.Beam:SetParent(self.Owner)
		self.Beam:SetOwner(self.Owner)
	end
	self:UpdateAttack()
end

function SWEP:UpdateAttack()
	if self.Timer and self.Timer > CurTime() then return end
	if ( self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 or self.Owner:WaterLevel() == 3 ) then self:EndAttack(true); return end
	if !self.ammocur then self.ammocur = CurTime() +0.03 end
	if CurTime() > self.ammocur then
		self:TakePrimaryAmmo( 1 )
		self.ammocur = nil
	end
	self.Timer = CurTime()+0.05
	self.Owner:LagCompensation(true)
	local st = self.Owner:GetShootPos()
	local en = st+(self.Owner:GetAimVector()*4096)
	local fl = {self.Owner,self.Weapon}
	local tr = Egon_GetTraceData(st,en,fl)
	local ent = tr.Entity
	if SERVER then
		if ValidEntity(ent) then
			if ent:GetClass() == "shield" then
				ent:Hit(self.Weapon,tr.HitPos,0.5,-1*tr.Normal)
			end
		end
	end
	if SERVER and self.Beam then
		self.Beam:GetTable():SetEndPos(tr.HitPos)
	end
	util.BlastDamage(self.Weapon,self.Owner,tr.HitPos,80,18)
	if ent and ent:IsPlayer() and !tr.HitSky then
		local effectdata = EffectData()
		effectdata:SetEntity(ent)
		effectdata:SetOrigin(tr.HitPos)
		effectdata:SetNormal(tr.HitNormal)
		util.Effect("bodyshot",effectdata)
	end
	self.Owner:LagCompensation(false)
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
end

function SWEP:EndAttack(a)
	if CLIENT then return end
	self.attack = false
	self.sndPowerUp:Stop()
	self.sndAttackLoop:Stop()
	if a then
		self.sndPowerDown:Stop()
		self.sndPowerDown:Play()
	end
	timer.Simple( 0.1, function() if self.Owner and self.Owner:GetActiveWeapon( ) == self then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	if CLIENT then return end
	if !self.Beam then return end
	self.Beam:Remove()
	self.Beam = nil
end

function SWEP:Holster()
	self:EndAttack(false)
	return true
end

function SWEP:OnRemove()
	self:EndAttack(false)
	return true
end

function SWEP:PrimaryAttack()
	if self.Owner:GetNetworkedInt( "ammo_" .. self.Primary.Ammo ) <= 0 or self.Owner:WaterLevel() == 3 then return end
	self.sndPowerUp:Play()
	self.sndAttackLoop:Play()
end

function SWEP:SecondaryAttack()
end
