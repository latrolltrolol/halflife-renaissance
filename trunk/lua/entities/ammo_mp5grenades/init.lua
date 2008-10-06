
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.Base = "ammo_base"

ENT.AmmoType = "9mmAR_Grenade"
ENT.AmmoName = "9mm AR Grenade"
ENT.AmmoToGive = 2
ENT.Model = "models/w_ARgrenade.mdl"
ENT.ParentEntModel = "models/items/boxsrounds.mdl"
ENT.PlyAmmoLimit = 10