
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.Base = "ammo_base"

ENT.AmmoType = "RPG_Round"
ENT.AmmoName = "RPG_Round"
ENT.AmmoToGive = 1
ENT.Model = "models/w_rpgammo.mdl"
ENT.ParentEntModel = "models/weapons/w_missile_closed.mdl"
ENT.PlyAmmoLimit = 5

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	local SpawnPos = (tr.HitPos + tr.HitNormal * 16) -Vector( 0, 0, 17 )
	self.Spawn_angles = ply:GetAngles()
	self.Spawn_angles.pitch = 0
	self.Spawn_angles.roll = 0
	self.Spawn_angles.yaw = self.Spawn_angles.yaw + 180
	
	local ent = ents.Create( "ammo_rpgclip" )
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