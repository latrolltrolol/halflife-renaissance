include('shared.lua')

killicon.Add("controller_ball_dark","HUD/killicons/controller",Color ( 255, 80, 0, 255 ) )
function ENT:Initialize()
	local c = 2 --math.random( 0, 3 )
	if ( c == 0 ) then
		self.col = Color( 40, 0, 0, 255 )
	elseif ( c == 1 ) then
		self.col = Color( 0, 40, 0, 255 )
	elseif ( c == 2 ) then
		self.col = Color( 40, 40, 0, 255 )
	else
		self.col = Color( 0, 0, 40, 255 )
	end
end

function ENT:Draw()
	self.Entity:DrawModel()
	local pos = self.Entity:GetPos()
	local vel = self.Entity:GetVelocity()
	
	render.SetMaterial( Material( "sprites/strider_blackball" ) ) 
	
	local lcolor = render.GetLightColor( pos ) * 2
	lcolor.x = self.col.r * mathx.Clamp( lcolor.x, 0, 1 )
	lcolor.y = self.col.g * mathx.Clamp( lcolor.y, 0, 1 )
	lcolor.z = self.col.b * mathx.Clamp( lcolor.z, 0, 1 )
		
	// Fake motion blur
	for i = 1, 20 do
	
		local col = Color( lcolor.x, lcolor.y, lcolor.z, 255 / (i / 2) )
		render.DrawSprite( pos + vel*(i*-0.01), 32, 32, col )
		
	end
		
	render.DrawSprite( pos, 32, 32, lcolor )
end