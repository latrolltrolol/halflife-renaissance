
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	
	local SpawnPos = (tr.HitPos + tr.HitNormal * 16) -Vector( 0, 0, 17 )
	self.Spawn_angles = ply:GetAngles()
	self.Spawn_angles.pitch = 0
	self.Spawn_angles.roll = 0
	self.Spawn_angles.yaw = self.Spawn_angles.yaw + 180
	
	local ent = ents.Create( "monster_scientist_dead" )
	ent:SetPos( SpawnPos )
	ent:SetAngles( self.Spawn_angles )
	ent:SetModel( "models/props_junk/watermelon01_chunk02c.mdl" )
	ent:Spawn()
	ent:Activate()
	
	
	return ent
end

function ENT:Initialize()
	self:SetMoveType( MOVETYPE_NONE )
	//self:SetSolid( SOLID_BBOX )
	
	self:SetModel( "models/props_junk/watermelon01_chunk02c.mdl" )
	self:SetColor( 255, 255, 255, 0 )
	//self:SetCollisionBounds( Vector( -5, 5, 0 ), Vector( 5, -5, 63 ) )	
end

function ENT:CreateBody()
	if tonumber(self.deadpose) == 0 then
		self.deadanim = "lying_on_back"
	elseif tonumber(self.deadpose) == 1 then
		self.deadanim = "lying_on_stomach"
	elseif tonumber(self.deadpose) == 2 then
		self.deadanim = "dead_sitting"
	end

	self.sc_dead = ents.Create( "prop_dynamic_override" )
	self.sc_dead:SetModel( "models/scientist.mdl" )
	self.sc_dead:SetKeyValue( "DefaultAnim", self.deadanim )
	self.sc_dead:SetPos( self:GetPos() )
	self.sc_dead:SetAngles( self:GetAngles() )
	self.sc_dead:Spawn()
	self.sc_dead:Activate()
	self.sc_dead:Fire( "SetAnimation", self.deadanim, 0 )
	self.sc_dead:Fire( "SetDefaultAnimation", self.deadanim, 0 )
end

function ENT:KeyValue( key, value )
	if( key == "pose" ) then
		self.deadpose = value
		self:CreateBody()
	end
end

function ENT:Think()
end

function ENT:OnRemove()
	if ValidEntity( self.sc_dead ) then
		self.sc_dead:Remove()
	end
end
