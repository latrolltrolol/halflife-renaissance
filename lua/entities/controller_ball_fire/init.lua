
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	timer.Simple(8,self.Remov,self)
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_CUSTOM )
	self:SetHealth(1)

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	self.ai_sound = ents.Create( "ai_sound" )
	self.ai_sound:SetPos( self:GetPos() )
	self.ai_sound:SetKeyValue( "volume", "80" )
	self.ai_sound:SetKeyValue( "duration", "8" )
	self.ai_sound:SetKeyValue( "soundtype", "8" )
	self.ai_sound:SetParent( self )
	self.ai_sound:Spawn()
	self.ai_sound:Activate()
	self.ai_sound:Fire( "EmitAISound", "", 0 )
	
	/*self.particle = ents.Create( "info_particle_system" )
	self.particle:SetKeyValue( "effect_name", "Controller_ball_fire" )
			
	self.particle:SetParent( self )
	self.particle:Spawn()
	self.particle:Activate() */
end

function ENT:Remov()
	if self then
		if self.Entity then
			self:Remove()
		end
	end
end

function ENT:OnRemove()
	self.ai_sound:Remove()
end

function ENT:Think()
	if self.Entity then
		if ValidEntity( self.owner ) and self:GetPos():Distance(self.owner:GetPos()) > 2000 then
			self:Remove()
		return
		end
	end 
	if ValidEntity(self.enemy) then
		self.Entity:GetPhysicsObject():ApplyForceCenter( (((self.enemy:NearestPoint( self.enemy:GetPos() + Vector(0,0,1000) ) + self.enemy:NearestPoint( self.enemy:GetPos() + Vector(0,0,-1000) )) / 2 ) - self.Entity:GetPos()):GetNormal() * self.Speed )
	end
end

function ENT:PhysicsCollide( data, physobj )
	if not data.HitEntity then return true end
	
	if not data.HitEntity:IsPlayer() and not data.HitEntity:IsNPC() then self:EmitSound( "npc/controller/electro4.wav", 100, 100 ); self.Remov( self ); return true end
	self.owner = self.owner or self
	data.HitEntity.attacker = self.owner
	data.HitEntity.inflictor = self
	if data.HitEntity:IsPlayer() then
		data.HitEntity:TakeDamage( sk_controller_attack_value, self.owner, self )
	elseif( ( ValidEntity( self.owner ) and ( self.owner:Disposition( data.HitEntity ) == 1 or self.owner:Disposition( data.HitEntity ) == 2 ) ) and data.HitEntity:GetClass() != "npc_turret_floor" ) then
		data.HitEntity:TakeDamage( sk_controller_attack_value, self.owner, self )
	elseif( data.HitEntity:GetClass() == "npc_turret_floor" ) then
		data.HitEntity:GetPhysicsObject():ApplyForceCenter( Vector( 6000, 0, 9000 ) )
		data.HitEntity:Fire( "selfdestruct", "", 0 )
	end
	self:EmitSound( "npc/controller/electro4.wav", 100, 100 )
	timer.Simple( .01, self.Remov, self )
		
	return true
end

