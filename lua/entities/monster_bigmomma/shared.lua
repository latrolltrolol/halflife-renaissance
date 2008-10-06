ENT.Base = "monster_base"
ENT.Type = "ai"

ENT.PrintName = "Gonarch"
ENT.Author = "Silverlan, Q42"
ENT.Contact = "Silverlan@gmx.de | FrigginRatBomb@gmail.com"
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