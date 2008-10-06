include('shared.lua')

language.Add("xen_tree", "Xen Tree")
killicon.Add("xen_tree","HUD/killicons/xen_tree",Color ( 255, 80, 0, 255 ) )

function ENT:Initialize()
end

function ENT:Draw()
	self.Entity:DrawModel()
end