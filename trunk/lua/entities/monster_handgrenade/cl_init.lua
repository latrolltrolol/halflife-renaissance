include('shared.lua')

killicon.Add("monster_handgrenade","HUD/killicons/handgrenade",Color ( 255, 80, 0, 255 ) )
function ENT:Initialize()
end

function ENT:Draw()
	self.Entity:DrawModel()
end