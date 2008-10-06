
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
	
	local ent = ents.Create( "xen_plantlight" )
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
	
	self.light = ents.Create( "prop_dynamic_override" )
	self.light:SetModel( "models/light.mdl" )
	self.light:SetKeyValue( "DefaultAnim", "idle1" )
	self.light:SetPos( self:GetPos() )
	self.light:SetAngles( self:GetAngles() )
	self.light:Spawn()
	self.light:Activate()
	self.light:SetParent( self )
	
	self:SetCollisionBounds( Vector( -5, 5, 0 ), Vector( 5, -5, 63 ) )	
	if self.lighttarget then return end
	self.lighttarget = ents.Create( "light_dynamic" )
	self.lighttarget:SetKeyValue( "_light", "255 194 53 100" )//251 235 172 100" )
	self.lighttarget:SetKeyValue( "brightness", "8" )
	self.lighttarget:SetKeyValue( "distance", "80" )
	self.lighttarget:SetKeyValue( "_cone", "0" )
	self.lighttarget:SetParent( self.light )
	self.lighttarget:Spawn()
	self.lighttarget:Activate()
	self.lighttarget:Fire( "SetParentAttachment", "0", 0 )
	self.lighttarget:Fire( "TurnOn", "", 0 )
	
	self.sprite = ents.Create( "env_sprite" )
	self.sprite:SetKeyValue( "spawnflags", "1" )
	self.sprite:SetKeyValue( "rendercolor", "255 235 155" )
	self.sprite:SetKeyValue( "renderamt", "240" )
	self.sprite:SetKeyValue( "model", "sprites/glow08.spr" )
	self.sprite:SetKeyValue( "rendermode", "9" )
	self.sprite:SetKeyValue( "scale", "0.2" )
	self.sprite:SetParent( self.light )
	self.sprite:Spawn()
	self.sprite:Activate()
	self.sprite:Fire( "SetParentAttachment", "0", 0 )
end

function ENT:CheckTable( tb )
	for k, v in pairs( tb ) do
		if ValidEntity( v ) and ( v:IsNPC() or v:IsPlayer() ) and v:Health() > 0 then return true end
	end
	return false
end

function ENT:KeyValue( key, value )
	if( key == "target" ) then
		self.lighttarget_t = ents.FindByName( value )[1]
		if self.lighttarget_n != NULL then
			self.lighttarget = self.lighttarget_n
		end
	end
end

function ENT:Think()
	if self.hiding and self.deploydelay and CurTime() > self.deploydelay then
		if self:CheckTable( ents.FindInSphere( self:GetPos(), 64 ) ) then 
			self.deploydelay = CurTime() +6
		else
			self.hiding = false
			self.light:Fire( "SetAnimation", "delpoy", 0 )
			self.light:Fire( "SetDefaultAnimation", "idle1", 0 )
			self.lighttarget:Fire( "TurnOn", "", 0.8 )
			self.sprite:Fire( "ShowSprite", "", 0.8 )
			self.allowhidedelay = CurTime() + 1.865
		end
	end

	if self.hiding or ( self.allowhidedelay and CurTime() < self.allowhidedelay ) then return end
	if self:CheckTable( ents.FindInSphere( self:GetPos(), 64 ) ) then 
		self.hiding = true
		self.light:Fire( "SetAnimation", "retract", 0 )
		self.light:Fire( "SetDefaultAnimation", "hide", 0 )
		self.lighttarget:Fire( "TurnOff", "", 0.1 )
		self.sprite:Fire( "HideSprite", "", 0.1 )
		self.deploydelay = CurTime() +6
	end
end

function ENT:OnRemove()
	self.lighttarget:Remove()
	self.sprite:Remove()
	self.light:Remove()
end
