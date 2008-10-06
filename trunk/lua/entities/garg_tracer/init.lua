
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	//timer.Simple(8,self.Remov,self)
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:SetHealth(1)
	
	self.ai_sound = ents.Create( "ai_sound" )
	self.ai_sound:SetPos( self:GetPos() )
	self.ai_sound:SetKeyValue( "volume", "80" )
	self.ai_sound:SetKeyValue( "duration", "8" )
	self.ai_sound:SetKeyValue( "soundtype", "8" )
	self.ai_sound:SetParent( self )
	self.ai_sound:Spawn()
	self.ai_sound:Activate()
	self.ai_sound:Fire( "EmitAISound", "", 0 )
	self:EmitSound( "weapons/mine_charge.wav", 100, 100 )
	self.tr_delay = CurTime() +1
	
	/*self:SetName( "Garg" .. self.owner:EntIndex() .. "_tracer" .. self:EntIndex() )
	
	self.tracer_effect_tbl = {}
	
	self.stomp_trail_effect = ents.Create( "info_particle_system" )
	self.stomp_trail_effect:SetKeyValue( "effect_name", "Advisor_Psychic_Scan_Green" )
			
	self.stomp_trail_effect:SetAngles( self:GetAngles() )
	self.stomp_trail_effect:SetPos( self:GetPos() )
	self.stomp_trail_effect:SetKeyValue( "cpoint1", "Garg" .. self.owner:EntIndex() .. "_tracer" .. self:EntIndex() )
	self.stomp_trail_effect:SetParent( self )
	self.stomp_trail_effect:Spawn()
	self.stomp_trail_effect:Activate() 
	//self.stomp_trail_effect:Fire( "SetParentAttachment", tostring(i), 0 )
	table.insert( self.tracer_effect_tbl, self.stomp_trail_effect )
	
	self.stomp_psy_effect = ents.Create( "info_particle_system" )
	self.stomp_psy_effect:SetKeyValue( "effect_name", "Advisor_Psychic_Scan_Suck" )
			
	self.stomp_psy_effect:SetAngles( self:GetAngles() )
	self.stomp_psy_effect:SetPos( self:GetPos() )
	self.stomp_psy_effect:SetKeyValue( "cpoint1", "Garg" .. self.owner:EntIndex() .. "_tracer" .. self:EntIndex() )
	self.stomp_psy_effect:SetParent( self )
	self.stomp_psy_effect:Spawn()
	self.stomp_psy_effect:Activate() 
	//self.stomp_psy_effect:Fire( "SetParentAttachment", tostring(i), 0 )
	table.insert( self.tracer_effect_tbl, self.stomp_psy_effect )
	
	for k, v in pairs( self.tracer_effect_tbl ) do v:Fire( "Start", "", 0.1 ) end*/
	//self:SetColor( 255, 255, 255, 0 )
	self.multiplier = 0
	self:Fire( "kill", "", 20 )
	self.endtracetime = CurTime() +6
end

function ENT:OnRemove()
	self.ai_sound:Remove()
end

function ENT:Dissolve( ent )
	if ent:IsPlayer() then
		self.dissolve_target = "!player"
	elseif( ( ValidEntity( self.owner ) and ( self.owner:Disposition( ent ) == 1 or self.owner:Disposition( ent ) == 2 ) ) and ent:GetClass() != "npc_turret_floor" ) then
		if ent:GetName() == "" then
			ent:SetName( tostring(ent) )
		end
		self.dissolve_target = ent:GetName()
	elseif( ent:GetClass() == "npc_turret_floor" ) then
		ent:GetPhysicsObject():ApplyForceCenter( Vector( 6000, 0, 9000 ) )
		ent:Fire( "selfdestruct", "", 0 )
	end
	if self.dissolve_target and ent:Health() <= 100 then
		self.dissolver = ents.Create( "env_entity_dissolver" )
		self.dissolver:SetKeyValue( "dissolvetype", "2" )
		self.dissolver:Spawn()
		self.dissolver:Activate()
		self.dissolver:SetOwner( self.owner )
		ent:TakeDamage( ent:Health(), self.owner, self )
		self.dissolver:Fire( "Dissolve", self.dissolve_target, 0 )
		self.dissolver:Remove()
	else
		ent:TakeDamage( sk_gargantua_stomp_value, self.owner, self )
	end
end

function ENT:Think()
	if CurTime() < self.tr_delay then return end
	
	for k, v in pairs( ents.FindInSphere( self:GetPos(), 16 ) ) do
		if ValidEntity( v ) and ( v:IsNPC() or v:IsPlayer() ) and v:Health() > 0 and v != self.owner then
			self:Dissolve( v )
			self:Remove()
		end
	end
	self:NextThink( CurTime() + 0.01 ) 
	// FORWARD trace
	local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:LocalToWorld( Vector( 4, 0, 0 ) )
	trace.filter = self

	local tr = util.TraceLine( trace ) 
	if tr.HitWorld then 
		self:Remove()
	end
	
	// DOWN trace
	local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:GetPos() + Vector( 0, 0, -75 )
	trace.filter = self
	
	local tr = util.TraceLine( trace ) 
	if tr.HitWorld then 
		if self.multiplier < 7 then
			self.multiplier = self.multiplier +0.3
		end
		self:SetPos( tr.HitPos +Vector( 0, 0, 12 ) +( self:GetForward() *self.multiplier ) )
		if !self.enemy or !ValidEntity( self.enemy ) or self.enemy:Health() <= 0 or CurTime() > self.endtracetime then return true end
		local enemy_pos = self.enemy:OBBCenter()
		local enemy_ang = self.enemy:GetAngles()
		local enemy_pos_center = self.enemy:GetPos() + enemy_ang:Up() * enemy_pos.z + enemy_ang:Forward() * enemy_pos.x + enemy_ang:Right() * enemy_pos.y
		local enemy_normal_angle = (enemy_pos_center -self:GetPos()):GetNormalized():Angle()
		if enemy_normal_angle.y < 0 then
			enemy_normal_angle.y = enemy_normal_angle.y *-1
		end
		local self_angle_p = self:GetAngles().p
		local self_angle_y = self:GetAngles().y
		local self_angle_r = self:GetAngles().r
		if self_angle_y < 0 then
			self_angle_y = self_angle_y *-1
		end
		if self:GetAngles().y <= enemy_normal_angle.y then
			if ( self_angle_y <= 180 and enemy_normal_angle.y <= 180 ) or ( self_angle_y > 180 and enemy_normal_angle.y > 180 ) then
				self:SetAngles( Angle( self_angle_p, self:GetAngles().y +0.8, self_angle_r ) )
			elseif enemy_normal_angle.y -self_angle_y <= 180 then
				self:SetAngles( Angle( self_angle_p, self:GetAngles().y +0.8, self_angle_r ) )
			elseif enemy_normal_angle.y -self_angle_y > 180 then
				self:SetAngles( Angle( self_angle_p, self:GetAngles().y -0.8, self_angle_r ) )
			end
		else
			if ( self_angle_y <= 180 and enemy_normal_angle.y <= 180 ) or ( self_angle_y > 180 and enemy_normal_angle.y > 180 ) then
				self:SetAngles( Angle( self_angle_p, self:GetAngles().y -0.8, self_angle_r ) )
			elseif self_angle_y -enemy_normal_angle.y <= 180 then
				self:SetAngles( Angle( self_angle_p, self:GetAngles().y -0.8, self_angle_r ) )
			elseif self_angle_y -enemy_normal_angle.y > 180 then
				self:SetAngles( Angle( self_angle_p, self:GetAngles().y +0.8, self_angle_r ) )
			end
		end
	end
	return true
end

function ENT:PhysicsCollide( data, physobj )
	return true
end

