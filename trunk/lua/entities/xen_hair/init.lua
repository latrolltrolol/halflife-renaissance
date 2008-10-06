
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	
	self:SetModel( "models/props_junk/watermelon01_chunk02c.mdl" )
	self:SetColor( 255, 255, 255, 0 )
	self:DrawShadow( false )
	
	self.hair = ents.Create( "prop_dynamic_override" )
	self.hair:SetModel( "models/hair.mdl" )
	self.hair:SetKeyValue( "DefaultAnim", "spin" )
	self.hair:SetPos( self:GetPos() )
	self.hair:SetAngles( self:GetAngles() )
	self.hair:Spawn()
	self.hair:Activate()
	self.hair:SetParent( self )
end

function ENT:Think()
end

function ENT:OnRemove()
	self.hair:Remove()
end
