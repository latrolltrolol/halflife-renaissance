
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