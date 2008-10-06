
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.Base = "ammo_base"

ENT.AmmoType = "Buckshot"
ENT.AmmoName = "Buckshot"
ENT.AmmoToGive = 12
ENT.Model = "models/w_shotbox.mdl"
ENT.ParentEntModel = "models/items/357ammo.mdl"
ENT.PlyAmmoLimit = 125

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	local SpawnPos = (tr.HitPos + tr.HitNormal * 16) -Vector( 0, 0, 17 )
	self.Spawn_angles = ply:GetAngles()
	self.Spawn_angles.pitch = 0
	self.Spawn_angles.roll = 0
	self.Spawn_angles.yaw = self.Spawn_angles.yaw + 180
	
	local ent = ents.Create( "ammo_buckshot" )
	ent:SetPos( SpawnPos )
	ent:SetAngles( self.Spawn_angles )
	ent:Spawn()
	ent:Activate()
	
	return ent
end

function ENT:Touch(ent)
	if ent:IsPlayer() and !self.pickedup and CurTime() > self.initcur then
		ent:GiveAmmo( self.AmmoToGive, self.AmmoType )
		self.pickedup = true
		ent:EmitSound( "items/ammo_pickup.wav", 100, 100 )
		self:FireOutput( "OnPlayerPickup" )
		
		local rp = RecipientFilter() 
		rp:AddPlayer( ent )

		umsg.Start( "ItemPickedUp", rp )
		umsg.String( self.AmmoName .. "," .. self.AmmoToGive )
		umsg.End() 
		self:Remove()
	end
end