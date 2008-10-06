include('shared.lua')

language.Add("garg_tracer", "Tracer")
killicon.Add("garg_tracer","HUD/killicons/gargantua",Color ( 255, 80, 0, 255 ) )
function ENT:Initialize()
	self.col = Color( 255, 62, 67, 255 )
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
		render.DrawSprite( pos + vel*(i*-0.04), 45, 45, col ) //def size = 32
		
	end
		
	render.DrawSprite( pos, 45, 45, lcolor )
end