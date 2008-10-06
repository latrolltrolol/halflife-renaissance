
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_CUSTOM )
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	//self:PhysicsInitSphere( 6, "item" )
	self:SetHealth(1)
	
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass( 1 )
		phys:EnableDrag(false)
		phys:SetBuoyancyRatio( 0.1 )
	end
	
	if !self.damage then self.damage = 85 end
	
	if self.type == "hgrenade" then
		if !self.explodedelay then
			self.explodedelay = 3
		elseif self.explodedelay < 0 then
			self.explodedelay = 0
		end
		timer.Create( "self_exp_timer" .. self:EntIndex(), self.explodedelay, 1, function() self:Explode() end )
		self.ai_sound = ents.Create( "ai_sound" )
		self.ai_sound:SetPos( self:GetPos() )
		self.ai_sound:SetKeyValue( "volume", "180" )
		self.ai_sound:SetKeyValue( "duration", "12" )
		self.ai_sound:SetKeyValue( "soundtype", "8" )
		self.ai_sound:SetParent( self )
		self.ai_sound:Spawn()
		self.ai_sound:Activate()
		self.ai_sound:Fire( "EmitAISound", "", 0 )
		return
	end
	self.smoketrail = ents.Create( "env_smoketrail" )
	self.smoketrail:SetKeyValue( "opacity", "0.75" )
	self.smoketrail:SetKeyValue( "spawnrate", "20" )
	self.smoketrail:SetKeyValue( "lifetime", "0.3" )
	self.smoketrail:SetKeyValue( "startcolor", "192 192 192" )
	self.smoketrail:SetKeyValue( "endcolor", "160 160 160" )
	self.smoketrail:SetKeyValue( "firesprite", "particle/particle_smokegrenade.vmt" )
	self.smoketrail:SetKeyValue( "smokesprite", "particle/particle_smokegrenade.vmt" )
	self.smoketrail:SetKeyValue( "spawnradius", "8" )
	self.smoketrail:SetKeyValue( "endsize", "20" )
	self.smoketrail:SetPos( self:GetPos() )
	self.smoketrail:SetParent( self )
	self.smoketrail:Spawn()
	self.smoketrail:Activate()
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
	
	if self.type == "hgrenade" then
		local tracedata = {}
		tracedata.start = self:GetPos()
		tracedata.endpos = self:GetPos() -Vector( 0, 0, 25 )
		tracedata.filter = self
		local trace = util.TraceLine(tracedata)
		if trace.HitWorld then
			util.Decal("Scorch",trace.HitPos +trace.HitNormal,trace.HitPos -trace.HitNormal)  
		end 
	end
	
	
	self:Remove()
end

function ENT:PhysicsCollide( data, physobj )
	if self.type == "hgrenade" then return end
	util.Decal("Scorch",data.HitPos +data.HitNormal,data.HitPos -data.HitNormal)  
	
	self:Explode()
end

function ENT:OnRemove()
	if self.smoketrail and ValidEntity( self.smoketrail ) then
		self.smoketrail:Remove()
	end
	if self.ai_sound and ValidEntity( self.ai_sound ) then
		self.ai_sound:Remove()
	end
	if self.parentent and ValidEntity( self.parentent ) then
		self.parentent:Remove()
	end
	timer.Destroy( "self_exp_timer" .. self:EntIndex() )
end