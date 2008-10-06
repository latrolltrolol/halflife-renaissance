
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_BBOX )
	self:SetCollisionBounds( Vector( 8, 4, 15 ), Vector( -8, -4, 0 ) )
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetHealth(1)
	if !self.damage then self.damage = 85 end
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass( 1 )
		phys:EnableDrag(false)
		phys:SetBuoyancyRatio( 0.1 )
	end
end

function ENT:Think()
end

function ENT:Explode()
	local vPoint = self:GetPos()
	local effectdata = EffectData()
	effectdata:SetStart( vPoint )
	effectdata:SetOrigin( vPoint )
	effectdata:SetScale( 1 )
	if self:WaterLevel() != 3 then
		self:EmitSound( "weapons/explode" .. math.random(3,5) .. ".wav", 100, 100 )
		util.Effect( "HelicopterMegaBomb", effectdata ) 
	else
		util.Effect( "WaterSurfaceExplosion", effectdata ) 
	end
	if self.owner and ValidEntity( self.owner ) then
		util.BlastDamage( self, self.owner, self:GetPos(), 180, self.damage )
	else
		util.BlastDamage( self, self, self:GetPos(), 180, self.damage )
	end
	
	local tracedata = {}
	tracedata.start = self:GetPos()
	tracedata.endpos = self:GetPos() -Vector( 0, 0, 25 )
	tracedata.filter = self
	local trace = util.TraceLine(tracedata)
	if trace.HitWorld then
		util.Decal("Scorch",trace.HitPos +trace.HitNormal,trace.HitPos -trace.HitNormal)  
	end 
	
	self:Remove()
end

function ENT:OnTakeDamage(dmg)
	self:SetHealth(self:Health() - dmg:GetDamage())

	if( self:Health() <= 0 and !self.explode ) then //run on death
		self.explode = true
		self:Explode()
	end
end

function ENT:OnRemove()
end