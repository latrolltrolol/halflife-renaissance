
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.Base = "ammo_base"

ENT.AmmoType = "9mm"
ENT.AmmoName = "9mm"
ENT.AmmoToGive = 17
ENT.Model = "models/w_9mmclip.mdl"
ENT.ParentEntModel = "models/items/boxsrounds.mdl"
ENT.PlyAmmoLimit = 250

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	local SpawnPos = (tr.HitPos + tr.HitNormal * 16) -Vector( 0, 0, 17 )
	self.Spawn_angles = ply:GetAngles()
	self.Spawn_angles.pitch = 0
	self.Spawn_angles.roll = 0
	self.Spawn_angles.yaw = self.Spawn_angles.yaw + 180
	
	local ent = ents.Create( "ammo_9mmclip" )
	ent:SetPos( SpawnPos )
	ent:SetAngles( self.Spawn_angles )
	ent:Spawn()
	ent:Activate()
	
	return ent
end