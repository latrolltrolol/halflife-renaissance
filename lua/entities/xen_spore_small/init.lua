
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
	
	local ent = ents.Create( "xen_spore_small" )
	ent:SetPos( SpawnPos )
	ent:SetAngles( self.Spawn_angles )
	ent:Spawn()
	ent:Activate()
	
	
	return ent
end

function ENT:Initialize()
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_BBOX )
	
	self:SetModel( "models/props_junk/watermelon01_chunk02c.mdl" )
	self:SetColor( 255, 255, 255, 0 )
	self:DrawShadow( false )
	
	self.spore = ents.Create( "prop_dynamic_override" )
	self.spore:SetModel( "models/fungus(small).mdl" )
	self.spore:SetKeyValue( "DefaultAnim", "idle1" )
	self.spore:SetPos( self:GetPos() )
	self.spore:SetAngles( self:GetAngles() )
	self.spore:Spawn()
	self.spore:Activate()
	self.spore:SetParent( self )
	
	self:SetCollisionBounds( Vector( -28, 26, 0 ), Vector( 28, -22, 70 ) )	
end

function ENT:Think()
end

function ENT:OnRemove()
	self.spore:Remove()
end
