
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	timer.Simple(12,self.Remov,self)
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_CUSTOM )
	self:SetHealth(1)

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	self.sound = CreateSound( self, "ambient/energy/electric_loop.wav" )
	self.sound:Play()
	
	self.ai_sound = ents.Create( "ai_sound" )
	self.ai_sound:SetPos( self:GetPos() )
	self.ai_sound:SetKeyValue( "volume", "300" )
	self.ai_sound:SetKeyValue( "duration", "12" )
	self.ai_sound:SetKeyValue( "soundtype", "8" )
	self.ai_sound:SetParent( self )
	self.ai_sound:Spawn()
	self.ai_sound:Activate()
	self.ai_sound:Fire( "EmitAISound", "", 0 )
end

function ENT:Remov()
	if self then
		if self.Entity then
			self:EmitSound( "ambient/levels/labs/electric_explosion5.wav", 100, 100 )
			local vPoint = self:GetPos()
			local effectdata = EffectData()
			effectdata:SetOrigin( vPoint )
			effectdata:SetScale( 1 )
			util.Effect( "cball_explode", effectdata ) 
			self:Remove()
		end
	end
end

function ENT:OnRemove()
	self.sound:Stop()
	self.ai_sound:Remove()
	if self.dissolver and ValidEntity( self.dissolver ) then
		self.dissolver:Remove()
	end
end

function ENT:Think()
	if self.Entity then
		if ValidEntity( self.owner ) and self:GetPos():Distance(self.owner:GetPos()) > 2000 then
			self:Remov()
		return
		end
	end 
	if ValidEntity(self.enemy) then
		self.Entity:GetPhysicsObject():ApplyForceCenter( (((self.enemy:NearestPoint( self.enemy:GetPos() + Vector(0,0,1000) ) + self.enemy:NearestPoint( self.enemy:GetPos() + Vector(0,0,-1000) )) / 2 ) - self.Entity:GetPos()):GetNormal() * self.Speed )
	end
end

function ENT:PhysicsCollide( data, physobj )
	if not data.HitEntity then return true end
	
	if not data.HitEntity:IsPlayer() and not data.HitEntity:IsNPC() then return true end
	self.owner = self.owner or self
	data.HitEntity.attacker = self.owner
	data.HitEntity.inflictor = self
	if data.HitEntity:IsPlayer() then
		//data.HitEntity:TakeDamage( sk_controller_attack_value, self.owner, self )
		self.dissolve_target = "!player"
	elseif( ( ValidEntity( self.owner ) and ( self.owner:Disposition( data.HitEntity ) == 1 or self.owner:Disposition( data.HitEntity ) == 2 ) ) and data.HitEntity:GetClass() != "npc_turret_floor" ) then
		if data.HitEntity:GetName() == "" then
			data.HitEntity:SetName( tostring(data.HitEntity) )
		end
		self.dissolve_target = data.HitEntity:GetName()
	elseif( data.HitEntity:GetClass() == "npc_turret_floor" ) then
		data.HitEntity:GetPhysicsObject():ApplyForceCenter( Vector( 6000, 0, 9000 ) )
		data.HitEntity:Fire( "selfdestruct", "", 0 )
	end
	if self.dissolve_target and data.HitEntity:Health() <= 100 then
		self.dissolver = ents.Create( "env_entity_dissolver" )
		self.dissolver:SetKeyValue( "dissolvetype", "2" )
		self.dissolver:Spawn()
		self.dissolver:Activate()
		self.dissolver:SetOwner( self.owner )
		data.HitEntity:TakeDamage( data.HitEntity:Health(), self.owner, self )
		self.dissolver:Fire( "Dissolve", self.dissolve_target, 0 )
		self.dissolver:Remove()
	else
		data.HitEntity:TakeDamage( sk_controller_attack_value *3, self.owner, self )
	end
	timer.Simple( .01, self.Remov, self )
		
	return true
end

