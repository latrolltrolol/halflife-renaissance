 include('shared.lua')   

killicon.Add("bullsquid_spit","HUD/killicons/bullsquid",Color ( 255, 80, 0, 255 ) )
 
 //[[---------------------------------------------------------     
 //Name: Draw     Purpose: Draw the model in-game.     
 //Remember, the things you render first will be underneath!  
 //-------------------------------------------------------]]  
 function ENT:Draw()      
 // self.BaseClass.Draw(self)  
 -- We want to override rendering, so don't call baseclass.                                   
 // Use this when you need to add to the rendering.        
 self.Entity:DrawModel()       // Draw the model.   
 end  
 
 function ENT:Initialize()
	self.emitter = ParticleEmitter( self:GetPos() )
 end
 
 function ENT:OnRemove()
	
	self.emitter:Finish()
	
 end
 
 function ENT:Think()
	local particle1 = self.emitter:Add( "toxicsplat", self:GetPos() ) 
 			if (particle1) then 
 				 
 				particle1:SetVelocity( VectorRand() * math.Rand(0, 200) ) 
 				 
 				particle1:SetLifeTime( 0 ) 
 				particle1:SetDieTime( math.Rand(0.3, 0.5) ) 
 				 
 				particle1:SetStartAlpha( math.Rand(100, 255) ) 
 				particle1:SetEndAlpha( 0 ) 
 				 
 				particle1:SetStartSize( 10 ) 
 				particle1:SetEndSize( 5 ) 
 				 
 				particle1:SetRoll( math.Rand(0, 360) ) 
 				 
 				particle1:SetAirResistance( 400 ) 
 				 
 				particle1:SetGravity( Vector( 0, 0, -200 ) ) 
 			 
 			end
 end
 