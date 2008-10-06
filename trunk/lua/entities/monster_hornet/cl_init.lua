include('shared.lua')

killicon.Add("monster_hornet","HUD/killicons/monster_hornet",Color ( 255, 80, 0, 255 ) )

function ENT:Initialize()
	self.col = Color( 255, 141, 15, 255 )
end

function ENT:Draw()
	self.Entity:DrawModel()
	local pos = self.Entity:GetPos()
	local vel = self.Entity:GetVelocity()
	
	render.SetMaterial( Material( "sprites/glow04_noz" ) ) 
	
	local lcolor = render.GetLightColor( pos ) * 2
	lcolor.x = self.col.r * mathx.Clamp( lcolor.x, 0, 1 )
	lcolor.y = self.col.g * mathx.Clamp( lcolor.y, 0, 1 )
	lcolor.z = self.col.b * mathx.Clamp( lcolor.z, 0, 1 )
		
	// Fake motion blur
	for i = 1, 20 do
	
		local col = Color( lcolor.x, lcolor.y, lcolor.z, 255 / (i / 2) )
		render.DrawSprite( pos + vel*(i*-0.01), 16, 16, col ) //def size = 32
		
	end
		
	render.DrawSprite( pos, 16, 16, lcolor )
end