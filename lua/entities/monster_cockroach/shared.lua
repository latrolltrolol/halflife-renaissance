ENT.Base = "monster_base"
ENT.Type = "ai"

ENT.PrintName = "Cockroach"
ENT.Author = "Silverlan"
ENT.Contact = "Silverlan@gmx.de"
ENT.Information		= ""
ENT.Category		= "SNPCs"

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.AutomaticFrameAdvance = true


/*---------------------------------------------------------
Name: PhysicsCollide
Desc: Called when physics collides. The table contains
data on the collision
//-------------------------------------------------------*/
function ENT:PhysicsCollide( data, physobj )
	if data.HitEntity and ValidEntity( data.HitEntity ) and ( ( ( data.HitEntity:IsNPC() or data.HitEntity:IsPlayer() ) and data.HitEntity:Health() > 0 ) or  data.HitEntity:GetClass() == "prop_physics" ) then
		self:SetHealth( 0 )
	end
end
 
 
/*---------------------------------------------------------
Name: PhysicsUpdate
Desc: Called to update the physics .. or something.
//-------------------------------------------------------*/
function ENT:PhysicsUpdate( physobj )
end
  
/*---------------------------------------------------------
Name: SetAutomaticFrameAdvance
Desc: If you're not using animation you should turn this
off - it will save lots of bandwidth.
//-------------------------------------------------------*/
function ENT:SetAutomaticFrameAdvance( bUsingAnim )

self.AutomaticFrameAdvance = bUsingAnim

end 