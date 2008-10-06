include('shared.lua')

language.Add("monster_tripmine", "Tripmine")
killicon.Add("monster_tripmine","HUD/killicons/monster_tripmine",Color ( 255, 80, 0, 255 ) )

function ENT:Initialize()
end

function ENT:Draw()
	self.Entity:DrawModel()
end
