
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	timer.Simple(8,self.Remov,self)
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_CUSTOM )
	self.Entity:SetHealth(1)
	
	// Wake the physics object up. It's time to have fun!
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:Remov()
	if self then
		if self.Entity then
			self:Remove()
		end
	end
end

function ENT:Think()
	if self.Entity then
		if self:GetPos():Distance(self.ownerpos) > 2000 then
			self:Remove()
		return
		end
	end 
	if !self.homing then return end
	if self.enemy then
		if not self.enemy:IsValid() then
			local enemy = self:SortEnemies( self.Entity )
			self.enemy = enemy
		end
	else
		local enemy = self:SortEnemies( self.Entity )
		self.enemy = enemy
	end
	if not self.enemy then return end
	
	if self.buzztimer < CurTime() then
		self.Entity:EmitSound( "hornet/buzz" ..math.random(1,3).. ".wav", 500, 100)
		self.buzztimer = CurTime() + .05
	end

	self.Entity:GetPhysicsObject():ApplyForceCenter( (((self.enemy:NearestPoint( self.enemy:GetPos() + Vector(0,0,1000) ) + self.enemy:NearestPoint( self.enemy:GetPos() + Vector(0,0,-1000) )) / 2 ) - self.Entity:GetPos()):GetNormal() * self.HornetSpeed )
end

function ENT:PhysicsCollide( data, physobj )
	if not data.HitEntity then return true end
	if !self.homing and data.HitEntity:GetClass() == "worldspawn" then self.Entity:EmitSound("hornet/hit" ..math.random(1,3).. ".wav", 500, 100); self:Remov(); return end
	if not data.HitEntity:IsPlayer() and not data.HitEntity:IsNPC() then return true end
	self.Entity:EmitSound("hornet/hit" ..math.random(1,3).. ".wav", 500, 100)
	self.owner = self.owner or self
	data.HitEntity.attacker = self.owner
	data.HitEntity.inflictor = self
	if data.HitEntity:IsPlayer() then
		data.HitEntity:TakeDamage( self.Damage, self.owner, self )
	elseif( ( ValidEntity( self.owner ) and ( ( self.owner:IsNPC() and self.owner:Disposition( data.HitEntity ) == 1 or self.owner:Disposition( data.HitEntity ) == 2 ) or !self.owner:IsNPC() ) ) and data.HitEntity:GetClass() != "npc_turret_floor" ) then
		data.HitEntity:TakeDamage( self.Damage, self.owner, self )
	elseif( data.HitEntity:GetClass() == "npc_turret_floor" ) then
		data.HitEntity:GetPhysicsObject():ApplyForceCenter( Vector( 6000, 0, 9000 ) )
		data.HitEntity:Fire( "selfdestruct", "", 0 )
	end
	timer.Simple( .01, self.Remov, self )
		
	return true
end

local function GetNumVelocity( ent ) --determines the area to search for enemies of the hornet based on the velocity of the hornet
	local vel = ent:GetVelocity()
	vel.x = math.abs(vel.x) * 0.01 // def .08
	vel.y = math.abs(vel.y) * 0.01
	vel.z = math.abs(vel.z) * 0.01
	if vel.x > vel.y and vel.x > vel.z then
		return math.Clamp( vel.x, 2, 20 )
	elseif vel.y > vel.x and vel.y > vel.z then
		return  math.Clamp( vel.y, 2, 20 )
	elseif vel.z > vel.x and vel.z > vel.y then
		return  math.Clamp( vel.z, 2, 20 )
	else
		return 10 --failsafe
	end
end


 function ENT:SortEnemies( hornet )

	local EnemyTable = ents.FindInSphere( hornet:GetPos(), self.HornetSearchRadi / GetNumVelocity( hornet ) ) 
	local Enemies = {}
	local Enemy
	for k,v in pairs(EnemyTable) do
		if (v:IsPlayer() || v:IsNPC()) && v != l and v != self.owner and v:GetClass( ) != "monster_alien_grunt" then
			table.insert(Enemies,v)
		end
	end

	Enemy = Enemies[math.random(1,(#Enemies > 2 && #Enemies) || 2)]
	return Enemy

end 
