include('shared.lua')

language.Add("monster_satchel", "Satchel")
killicon.Add("monster_satchel","HUD/killicons/satchel",Color ( 255, 80, 0, 255 ) )

function ENT:Initialize()
end

function ENT:Draw()
	self.Entity:DrawModel()
end