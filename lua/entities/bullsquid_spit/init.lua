
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')



function ENT:Initialize()   

	self.exploded = false
	self.Entity:SetModel( "models/weapons/w_bugbait.mdl" ) 	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	self.Entity:SetColor(100,100,100,0)
	
	self.target = NULL
	
	local phys = self.Entity:GetPhysicsObject()  	
	if (phys:IsValid()) then  		
		phys:Wake()
		phys:SetMass( 1 )
		phys:EnableDrag(false)
		phys:SetBuoyancyRatio( 0.1 )
	end 
	
end   

function ENT:OnTakeDamage( dmginfo )
	
	self.Entity:TakePhysicsDamage( dmginfo )
	
end

function ENT:PhysicsCollide(data, phys)
	if ( self.exploded == false) then
		local effectdata = EffectData()
		effectdata:SetOrigin(self.Entity:GetPos())
		util.Effect( "impact_splat", effectdata )
		
		util.Decal( "BeerSplash", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal )
		
		self.target = data.HitEntity
		self.exploded = true
	end
end

function ENT:Think()
if self.exploded == true then
	self.exploded = false
	if !self.target:IsValid() || self.target == NULL then self:Remove(); return end
	if( ValidEntity( self.target ) and ( ( (self.target:IsPlayer() and self.target:Alive()) or self.target:IsNPC() ) and ( ( ValidEntity( self.Owner ) and ( self.Owner:Disposition(self.target) == 1 or self.Owner:Disposition(self.target) == 2 ) ) or !ValidEntity( self.Owner ) ) ) or self.target:GetClass() == "prop_physics" ) then
		self.owner = self.owner or self.Entity
		self.target.attacker = self.owner
		self.target.inflictor = self
		self.target:TakeDamage( sk_bullsquid_spit_value, self.owner, self )
		
		if( self.target:GetClass() == "npc_turret_floor" and !table.HasValue( turret_index_table, self.target:EntIndex() ) ) then
			table.insert( turret_index_table, self.target:EntIndex() )
			self.target:Fire( "selfdestruct", "", 0 )
			timer.Create( "entity_index_remove_timer" .. self.Entity:EntIndex( ), 4, 1, function() table.remove( turret_index_table ) end )
		end
		
		if( self.target:GetClass() != "prop_physics" ) then
			self.target:EmitSound( "npc/bullsquid/acid1.wav", 500, 100)
		end
	end
	bullsquid_disposition = nil
	self:Remove()
end
self:NextThink( CurTime() )
return true
end
 
