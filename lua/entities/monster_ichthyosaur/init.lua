AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/hl1_icky_m1.mdl"
ENT.MinDistance		= 100
ENT.WaterMonster = true

ENT.SpawnRagdollOnDeath = true
ENT.FadeOnDeath = false
ENT.BloodType = "green"
ENT.Pain = true
ENT.PainSound = "npc/ichthyosaur/ichy_pain"
ENT.PainSoundCount = 4
ENT.DeathSound = "npc/ichthyosaur/ichy_die"
ENT.DeathSoundCount = 4
ENT.DeathSkin = false

local schdAttack = ai_schedule.New( "Attack Enemy" ) 
schdAttack:AddTask( "PlaySequence", { Name = "attackstart", Speed = 1 } )

local schdAttackEndHit = ai_schedule.New( "Stop Attack Enemy" ) 
schdAttackEndHit:AddTask( "PlaySequence", { Name = "attackend", Speed = 0.8 } )

local schdAttackEndMiss = ai_schedule.New( "Stop Attack Enemy" ) 
schdAttackEndMiss:AddTask( "PlaySequence", { Name = "attackmiss", Speed = 0.8 } )

local schdSwimSlow = ai_schedule.New( "Swim" ) 
schdSwimSlow:AddTask( "PlaySequence", { Name = "swim", Speed = 0.6 } )

local schdSwimFast = ai_schedule.New( "Swim to Enemy" ) 
schdSwimFast:AddTask( "PlaySequence", { Name = "swim", Speed = 1.3 } )

function ENT:Initialize()
	if( turret_index_table == nil ) then
		turret_index_table = {}
	end
	self.table_fear = {}

	self:SetModel( self.Model )

	self:SetHullType( HULL_WIDE_SHORT );
	self:SetHullSizeNormal();

	self:SetSolid( SOLID_BBOX )
	self:SetMoveType( MOVETYPE_FLY )

	self:CapabilitiesAdd( CAP_MOVE_SWIM | CAP_INNATE_MELEE_ATTACK1 | CAP_ANIMATEDFACE | CAP_FRIENDLY_DMG_IMMUNE | CAP_SQUAD )
	self:SetMaxYawSpeed( 5000 )


	if !self.health then
		self:SetHealth(sk_ichthyosaur_health_value)
	end
	
	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end

	self.attacksound1 = CreateSound( self, "npc/ichthyosaur/attack_growl1.wav" )
	self.attacksound2 = CreateSound( self, "npc/ichthyosaur/attack_growl2.wav" )
	self.attacksound3 = CreateSound( self, "npc/ichthyosaur/attack_growl3.wav" )
	
	self.idlesound1 = CreateSound( self, "npc/ichthyosaur/ichy_idle1.wav" )
	self.idlesound2 = CreateSound( self, "npc/ichthyosaur/ichy_idle2.wav" )
	self.idlesound3 = CreateSound( self, "npc/ichthyosaur/ichy_idle3.wav" )
	self.idlesound4 = CreateSound( self, "npc/ichthyosaur/ichy_idle4.wav" )
	self.idlesound5 = CreateSound( self, "npc/ichthyosaur/water_breath.wav" )
	self.idlesound6 = CreateSound( self, "npc/ichthyosaur/water_growl5.wav" )
	
	self.attackhitsound = CreateSound( self, "npc/ichthyosaur/snap.wav" )
	self.attackmisssound = CreateSound( self, "npc/ichthyosaur/snap_miss.wav" )

	self.alertsound = "npc/ichthyosaur/ichy_alert"
	self.alertsound_amount = 3
	
	self:SetUpEnemies( )
	self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }
	
	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
end

function ENT:Think()
	if GetConVarNumber("ai_disabled") == 1 or self:WaterLevel() == 0 then self:SetLocalVelocity( Vector( 0, 0, 0 ) ); return end
	//self:SwimToSurface()
	self.swimveloc = Vector( 0, 0, 0 )
	self:SelectSchedule()
	if self.enemy and ValidEntity( self.enemy ) and self.enemy:Health() > 0 and self:GetPos():Distance( self.enemy:GetPos() ) > self.MinDistance and !self.attacking then
		if self.enemy:WaterLevel() == 0 then self.enemy = NULL; return end
		self:UseEnemySwimMovement()
		//self:SelectSchedule()
	elseif self.enemy and ValidEntity( self.enemy ) and self.attacking then
		local enemy_pos = self.enemy:OBBCenter()
		local enemy_ang = self.enemy:GetAngles()
		local enemy_pos_center = self.enemy:GetPos() + enemy_ang:Up() * enemy_pos.z + enemy_ang:Forward() * enemy_pos.x + enemy_ang:Right() * enemy_pos.y
		local enemy_vec = (enemy_pos_center -self:GetPos()):GetNormalized()
		self:SetAngles( enemy_vec:Angle() )
		self.vel_divisor = 1.04
		local trace = {}
		trace.start = self:LocalToWorld( Vector( 0, 0, 120 ) )
		trace.endpos = self:GetPos()
		trace.mask = MASK_WATER
		trace.filter = self

		local tr = util.TraceLine( trace ) 
		if tr.HitWorld and trace.start != tr.HitPos and (self:GetPos():Distance( trace.start ) -trace.start:Distance( tr.HitPos )) <= 75 then
			self.vel_divisor = 1.4
		end
		self:SetLocalVelocity( self:GetVelocity() /self.vel_divisor )
		self.vel_divisor = nil
		
	elseif !self.enemy or !ValidEntity( self.enemy ) then
		self:UseDefaultSwimMovement()
	end
	
	if self.efficient then return end
	
	for k, v in pairs( self.enemyTable ) do
		local enemyTable_enemies = ents.FindByClass( v )
		for k, v in pairs( enemyTable_enemies ) do
			if( !table.HasValue( self.enemyTable_enemies_e, v ) ) then
				table.insert( self.enemyTable_enemies_e, v )
				if( !v:IsPlayer() ) then
					v:AddEntityRelationship( self, 1, 10 )
				end
				self:AddEntityRelationship( v, 1, 10 )
			end
		end
	end
	
	/*for k, v in pairs( self.enemyTable_fear ) do
		local enemyTable_enemies_fr = ents.FindByClass( v )
		for k, v in pairs( enemyTable_enemies_fr ) do
			if( !table.HasValue( self.enemyTable_enemies_e, v ) ) then
				table.insert( self.enemyTable_enemies_e, v )
				v:AddEntityRelationship( self, 1, 10 )
				self:AddEntityRelationship( v, 2, 10 )
			end
		end
	end*/
end

function ENT:ChangeDirection( direction, degree, divisor )
	if direction == "left" then
		local turn_direction = ((self:GetRight() *-1) /12) +self:GetForward()
		self:SetLocalVelocity( turn_direction )
		self:SetAngles( turn_direction:GetNormal():Angle() )
	elseif direction == "right" then
		local turn_direction = (self:GetRight() /12) +self:GetForward()
		self:SetLocalVelocity( turn_direction )
		self:SetAngles( turn_direction:GetNormal():Angle() )
	elseif direction == "up" then
		//local turn_direction = (self:GetUp() /12) +self:GetForward()
		//self:SetLocalVelocity( turn_direction )
		//self:SetAngles( turn_direction:GetNormal():Angle() )
		
		//local hitnormal = tr.HitNormal
		//local hitnormal_ang = tr.HitNormal:Angle()
		
		if !self.forward then self.forward = self:GetForward() end
		//local swim_vec = (self.forward +Vector( 0, 0, 0.8 )):GetNormalized()
		//if self.forward:GetNormalized() +degree > self:GetForward():GetNormalized() +degree then
			local swim_vec = self:GetForward():GetNormalized() +(degree /12)
			self:SetAngles( swim_vec:Angle() )
			self:SetLocalVelocity( swim_vec *180 )
		//end
	elseif direction == "down" then
		if !self.forward then self.forward = self:GetForward() end
		local swim_vec = ((self:GetUp() *-1) /divisor) +self:GetForward()
		self:SetAngles( swim_vec:GetNormal():Angle() )
		self:SetLocalVelocity( swim_vec )
	end
end

function ENT:SwimToSurface()
	if self:WaterLevel() <= 1 then 
		self:SetLocalVelocity( self:WorldToLocal( Vector( 0, 1, 0 ) ):GetNormalized() *180 )
		return
	end
	
	if !self.forward then self.forward = self:GetForward() end
	local swim_vec = (self.forward +Vector( 0, 0, 0.8 )):GetNormalized()
	self:SetAngles( swim_vec:Angle() )
	self:SetLocalVelocity( swim_vec *180 )
end

function ENT:UseEnemySwimMovement()
	self:SetEyeTarget( self.enemy:OBBCenter() )
	local enemy_pos = self.enemy:OBBCenter()
	local enemy_ang = self.enemy:GetAngles()
	local enemy_pos_center = self.enemy:GetPos() + enemy_ang:Up() * enemy_pos.z + enemy_ang:Forward() * enemy_pos.x + enemy_ang:Right() * enemy_pos.y
	local swim_vec = (enemy_pos_center -self:GetPos()):GetNormalized()
	self:SetLocalVelocity( swim_vec *240 )
	self:SetAngles( swim_vec:Angle() )
	self:StartSchedule( schdSwimFast )
end

function ENT:UseDefaultSwimMovement()
	// UP trace
	local trace = {}
	trace.start = self:LocalToWorld( Vector( 0, 0, 120 ) )
	trace.endpos = self:GetPos()
	trace.mask = MASK_WATER
	trace.filter = self

	local tr = util.TraceLine( trace ) 
	if tr.HitWorld and trace.start != tr.HitPos then 
		self.swimveloc = self.swimveloc + Vector( 0, 0, -50 )
		self.UpTrace = true
		self.tr_up_cur = CurTime() +math.Rand(0.6, 1.8)
		local tr_distance = self:GetPos():Distance( trace.start ) -trace.start:Distance( tr.HitPos )
		if !self.DownTrace and !self.ForwardTrace and tr_distance <= 120 and tr_distance > 76 then
			//local dir_normal = self:LocalToWorld( Vector( 50, 0, -40 ) )
			self:ChangeDirection( "down", false, 12 )
		elseif tr_distance <= 76 then
			//local dir_normal = ( self:LocalToWorld( Vector( 50, 0, -128 ) ) ):GetNormal()
			self:ChangeDirection( "down", false, 6 )
		end
	elseif self:GetAngles().p > 0.5 and self:GetAngles().p < 180 and ( ( self.tr_up_cur and CurTime() >= self.tr_up_cur ) or !self.tr_up_cur ) then
		self.tr_up_cur = nil
		self:SetAngles( Angle( (self:GetAngles().p -1.5), self:GetAngles().y, self:GetAngles().r ) )
		if self:GetAngles().p < 1 then
			self:SetAngles( Angle( 0, self:GetAngles().y, self:GetAngles().r ) )
		end
	end
	if !tr.HitWorld or trace.start == tr.HitPos then self.UpTrace = false end
		
	// DOWN trace
	local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:GetPos() + Vector( 0, 0, -75 )
	trace.filter = self

	local tr = util.TraceLine( trace ) 
	if tr.HitWorld then 
		if !self.UpTrace then
			self.swimveloc = self.swimveloc + Vector( 0, 0, 50 )
			self.DownTrace = true
			self:ChangeDirection( "up", tr.HitNormal )
			self.tr_down_cur = CurTime() +math.Rand(1.2, 2.2)
		/*else
			local trace = {}
			trace.start = self:GetPos()
			trace.endpos = self:LocalToWorld( Vector( 0, 380, 0 ) )
			trace.filter = self

			local tr_right = util.TraceLine( trace ) 
			trace.endpos = self:LocalToWorld( Vector( 0, -380, 0 ) )
			local tr_left = util.TraceLine( trace ) 
			if tr_right and !tr_left then
				self:TurnBack( "left" )	//direction
			elseif tr_left and !tr_right then
				self:TurnBack( "right" )
			elseif tr_right and tr_left then
				local Pos = self:GetPos()
				if Pos:Distance( tr_right.HitPos ) < Pos:Distance( tr_left.HitPos ) then
					self:TurnBack( "left" )
				else
					self:TurnBack( "right" )
				end
			else
				local rand = math.random(1,2)
				if rand == 1 then
					self:TurnBack( "right" )
				else
					self:TurnBack( "left" )
				end
			end*/
		end
	elseif self:GetAngles().p > 0.5 and self:GetAngles().p >= 180 and ( ( self.tr_down_cur and CurTime() >= self.tr_down_cur ) or !self.tr_down_cur ) then
		self.tr_down_cur = nil
		self:SetAngles( Angle( (self:GetAngles().p +1.5), self:GetAngles().y, self:GetAngles().r ) )
		if self:GetAngles().p > 359 then
			self:SetAngles( Angle( 0, self:GetAngles().y, self:GetAngles().r ) )
		end
	end
	if !tr.HitWorld then self.DownTrace = false end
		
	// BACKWARD trace
	/*local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:GetPos() + Vector( -380, 0, 0 )
	trace.filter = self

	local tr = util.TraceLine( trace ) 
	if tr.HitWorld then 
		self.swimveloc = self.swimveloc + Vector( 50, 0, 0 )
		self.BackwardTrace = true
	end*/ // No need for this?
		
	// LEFT trace
	local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:LocalToWorld( Vector( 0, 380, 0 ) )//self:GetPos() + Vector( 0, 380, 0 )
	trace.filter = self

	local tr = util.TraceLine( trace ) 
	if tr.HitWorld then 
		self.swimveloc = self.swimveloc + Vector( 0, -50, 0 )
		self.LeftTrace = true
		self.TurnRight = true
		self.LeftTraceRCur = CurTime() +2
	end
	
	if self.TurnRight and self.LeftTraceRCur <= CurTime() then
		self.TurnRight = false
	end
		
	// RIGHT trace
	local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:LocalToWorld( Vector( 0, -380, 0 ) )//self:GetPos() + Vector( 0, -380, 0 )
	trace.filter = self

	local tr = util.TraceLine( trace ) 
	if tr.HitWorld then 
		self.swimveloc = self.swimveloc + Vector( 0, 50, 0 )
		self.RightTrace = true
		self.TurnLeft = true
		self.RightTraceRCur = CurTime() +2
	end
	
	if self.TurnLeft and self.RightTraceRCur <= CurTime() then
		self.TurnLeft = false
	end
	if !self.TurnLeft and !self.TurnRight then
		local trace = {}
		trace.start = self:GetPos()
		trace.endpos = self:LocalToWorld( Vector( 0, -800, 0 ) )
		trace.filter = self

		local tr_right = util.TraceLine( trace ) 
	
		local trace = {}
		trace.start = self:GetPos()
		trace.endpos = self:LocalToWorld( Vector( 0, 800, 0 ) )
		trace.filter = self

		local tr_left = util.TraceLine( trace ) 
	
		if ( tr_right.HitWorld and tr_left.HitWorld ) then
			local Pos = self:GetPos()
			if Pos:Distance( tr_right.HitPos ) <= Pos:Distance( tr_left.HitPos ) then
				self.TurnLeft = true
				self.RightTraceRCur = CurTime() +2
			else
				self.TurnRight = true
				self.LeftTraceRCur = CurTime() +2
			end
		elseif ( !tr_right.HitWorld and !tr_left.HitWorld ) then
			local rand = math.random(1,2)
			if rand == 1 then
				self.TurnRight = true
				self.LeftTraceRCur = CurTime() +2
			else
				self.TurnLeft = true
				self.RightTraceRCur = CurTime() +2
			end
		elseif tr_right.HitWorld then
			self.TurnLeft = true
			self.RightTraceRCur = CurTime() +2
		elseif tr_left.HitWorld then
			self.TurnRight = true
			self.LeftTraceRCur = CurTime() +2
		end
	end
	
	// FORWARD trace
	local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:LocalToWorld( Vector( 380, 0, 0 ) )//self:GetPos() + Vector( 380, 0, 0 )
	trace.filter = self

	local tr = util.TraceLine( trace ) 
	if tr.HitWorld then 
		self.ForwardTrace = true
		if self.TurnLeft then
			self:ChangeDirection( "left" )
		elseif self.TurnRight then
			self:ChangeDirection( "right" )
		end
	else
		self.ForwardTrace = false
	end
	self:StartSchedule( schdSwimSlow )
	self:SetLocalVelocity( self:GetForward() *100 )
	if !self.change_dir_delay then
		self.change_dir_delay = CurTime() +math.Rand(4,6)
	end
	if self.turndirection_y or self.change_dir_delay <= CurTime() then
		if self.ForwardTrace or self.DownTrace or self.UpTrace then
			self.change_dir_delay = nil
		else
			if !self.turndirection_y then
				self.turndegree = math.Rand(35, 80)
			end
			if self.RightTrace and !self.LeftTrace then
				self:TurnDirection( self.turndegree, "left" )
			elseif self.LeftTrace and !self.RightTrace then
				self:TurnDirection( self.turndegree, "right" )
			else	// if both or none??
				local rand = math.random(1,2)
				if rand == 1 then
					self:TurnDirection( self.turndegree, "left" )
				else
					self:TurnDirection( self.turndegree, "right" )
				end
			end
		end
	end
	self.LeftTrace = false
	self.RightTrace = false
end

function ENT:TurnDirection( degree, direction )
	if direction == "left" and !self.turndirection then
		self.turndirection_y = self:GetAngles().y +degree
	elseif direction == "right" and !self.turndirection then
		self.turndirection_y = self:GetAngles().y -degree
	end
	
	if direction == "right" and self:GetAngles().y >= self.turndirection_y then
		self:SetAngles( Angle( self:GetAngles().p, ( self:GetAngles() +Angle( 0, 1.5, 0 ) ).y, self:GetAngles().r ) )
		return true
	elseif direction == "left" and self:GetAngles().y <= self.turndirection_y then
		self:SetAngles( Angle( self:GetAngles().p, ( self:GetAngles() -Angle( 0, 1.5, 0 ) ).y, self:GetAngles().r ) )
		return true
	else
		self.turndegree = nil
		self.turndirection_y = nil
		return false
	end
end

function ENT:Attack()
	self.attacksound1:Stop()
	self.attacksound2:Stop()
	self.attacksound3:Stop()
	self.attackhitsound:Stop()
	self.attackmisssound:Stop()
	
	local attacksound_rand = math.random(1,3)
	if (attacksound_rand == 1) then
		self.attacksound1:Play()
	end
	
	if (attacksound_rand == 2) then
		self.attacksound2:Play()
	end
	
	if (attacksound_rand == 3) then
		self.attacksound3:Play()
	end

	local function attack_dmg()
		local victim = ents.FindInBox( self:LocalToWorld(Vector( 28, 33, -16 )), self:LocalToWorld(Vector( 67, -30, 35 )) )
		for k, v in pairs(victim) do
			if( ( ( ( v:IsPlayer() and v:Alive() ) or v:IsNPC() ) and ( self:Disposition( v ) == 1 or self:Disposition( v ) == 2 ) ) or v:GetClass() == "prop_physics" ) then
				if v:IsNPC() and v:Health() - sk_ichthyosaur_bite_value <= 0 then
					self.killicon_ent = ents.Create( "sent_killicon" )
					self.killicon_ent:SetKeyValue( "classname", "sent_killicon_ichthyosaur" )
					self.killicon_ent:Spawn()
					self.killicon_ent:Activate()
					self.killicon_ent:Fire( "kill", "", 0.1 )
					self.attack_inflictor = self.killicon_ent
				else
					self.attack_inflictor = self
				end
				v:TakeDamage( sk_ichthyosaur_bite_value, self, self.attack_inflictor )  
				if v:IsPlayer() then
					v:SetEyeAngles( Angle( ( v:GetAimVector():Angle().p +math.Rand(-360,360) ), ( v:GetAimVector():Angle().y +math.Rand(-360,360) ), 0 ) ) //Angle( 0, math.Rand(-40,40), 0 ).y
				end
				self.enmyinrange = true
			end
		end
		if self.enmyinrange then
			self:StartSchedule( schdAttackEndHit )
			self.attackhitsound:Play()
		else
			self:StartSchedule( schdAttackEndMiss )
			self.attackmisssound:Play()
		end
		self.enmyinrange = nil
		
		local function attack_end()
			self.attacking = false
		end
		timer.Create( "attack_end_timer" .. self.Entity:EntIndex( ), 1.1, 1, attack_end )
	end
	timer.Create( "attack_blastdelay_timer" .. self.Entity:EntIndex( ), 0.83, 1, attack_dmg )
end

/*---------------------------------------------------------
 Name: SelectSchedule
//-------------------------------------------------------*/
function ENT:SelectSchedule()
	if self.efficient then return end

	local convar_ai = GetConVarNumber("ai_disabled")
	if( ( self.FoundEnemy or self.FoundEnemy_fear ) and !self.attacking and convar_ai == 0 ) then
		if !self.searchdelay then
			self.searchdelay = CurTime() +0.15
		end
		if self.searchdelay < CurTime() then
			self:FindInCone( 1, 9999 )
			self.searchdelay = nil
		end
		if conetable and self.enemy_memory then
			for k, v in pairs( conetable ) do
				if ValidEntity( v ) and !table.HasValue( self.enemy_memory, v ) and self:Disposition( v ) == 1 then
					table.insert( self.enemy_memory, v )
				end
			end
		end
		local Pos = self:GetPos()
		if self.enemy then self:CheckEnemy( 1 ) end
		if self.enemy_fear then self:CheckEnemy( 3 ) end
		if( self.enemy and ValidEntity( self.enemy ) and self.enemy:GetPos():Distance( self:GetPos() ) <= self.closest_range ) then
			if( self.enemy:GetPos():Distance( Pos ) < self.MinDistance and self:HasCondition( 10 ) and !self:HasCondition( 42 ) ) then
				if( self.enemy:IsNPC() ) then
					self.SetEnemy( self.enemy )
				end
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				self.attacking = true
				self.idle = 0
				self:SetLocalVelocity( self:GetVelocity() /2 )
				self:StartSchedule( schdAttack )
				self:Attack()
			elseif( ( self.following and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) < 800 ) or !self.following ) then
				timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
				self:SetEnemy( self.enemy, true )
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				//self:StartSchedule( schdChase )
				local function houndeye_hunt()
					self:EmitSound( "npc/houndeye/he_hunt" ..math.random(1,4).. ".wav", 500, 100)
				end
				
				if (self.timer_allow == 1) then
					timer.Create( "hunt_sound_timer" .. self.Entity:EntIndex( ), 1, 0, houndeye_hunt ) 
					self.timer_allow = 0
				end
			end
		elseif( ( !self.enemy or !ValidEntity(self.enemy) ) and self.enemy_fear and ValidEntity(self.enemy_fear) and self:HasCondition( 8 ) and !self:HasCondition( 7 ) ) then
			if( self.enemy_fear:IsNPC() ) then
				self:SetEnemy( self.enemy_fear )
			end
			self:UpdateEnemyMemory( self.enemy_fear, self.enemy_fear:GetPos() )
			//self:StartSchedule( schdHide ) 
			timer.Destroy( "hunt_sound_timer" .. self.Entity:EntIndex( ) )
		else
			self.closest_range = 9999
		end
		
	self:SetEnemy( NULL )	
	elseif( self.idle == 0 and convar_ai == 0 ) then
		self.idle = 1
		self:SetSchedule( SCHED_IDLE_STAND )
		self:SelectSchedule()
	elseif( !self.FoundEnemy and !self.FoundEnemy_fear and table.Count( self.table_fear ) > 0 ) then
		local enemies = ents.FindByClass( "npc_*" ) 
		table.Add( enemies, ents.FindByClass( "monster_*" ) )
		table.Add( enemies, player.GetAll() )
		for i, v in ipairs(enemies) do
			if( v:Health() > 0 and self:Disposition( v ) == 3 and !self:HasCondition( 7 ) ) then
				if( table.HasValue( self.table_fear, v ) ) then
					self:AddEntityRelationship( v, 2, 10 )
					local table_en_li = {}
					local en_li = v
					for k, v in pairs( self.table_fear ) do
						if( v != en_li ) then
							table.insert( table_en_li, v )
						end
					end
					self.table_fear = table_en_li
				end
			end
		end
	end
	
	if( self.following ) then
		if ValidEntity( self.follow_target ) then
			if( self:Disposition( self.follow_target ) != 3 ) then
				self:AddEntityRelationship( self.follow_target, 3, 10 )
			end
			
			if( self:GetPos():Distance( self.follow_target ) > 175 and ( ( ValidEntity( self.enemy ) and self.enemy != self.follow_target and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) > 800 ) or !ValidEntity( self.enemy ) ) and !self.attacking and convar_ai == 0 ) then
						self:SetEnemy( self.follow_target, true )
						self:UpdateEnemyMemory( self.follow_target, self.follow_target:GetPos() )
						//self:StartSchedule( schdFollow )
						//timer.Create( "self_select_schedule_timer" .. self:EntIndex(), 1, 1, function() self:StartSchedule( schdReset ) end )
			elseif( self.enemy == self.follow_target ) then
				self.enemy = NULL
			end
		else
			self.following = false
			self.follow_target = NULL
		end
	end
	
	local function play_idle()	
		local convar_ai = GetConVarNumber("ai_disabled")
		if( convar_ai == 0 ) then
			local idle_random = math.random(1,4)
			if (idle_random == 1) then
				self.idlesound1:Stop()
				self.idlesound1:Play()
			end
				
			if (idle_random == 2) then
				self.idlesound2:Stop()
				self.idlesound2:Play()
			end
				
			if (idle_random == 3) then
				self.idlesound3:Stop()
				self.idlesound3:Play()
			end
				
			if (idle_random == 4) then
				self.idlesound4:Stop()
				self.idlesound4:Play()
			end
			
			if !self.TurnLeft and !self.TurnRight then
				local trace = {}
				trace.start = self:GetPos()
				trace.endpos = self:LocalToWorld( Vector( 0, -800, 0 ) )
				trace.filter = self

				local tr_right = util.TraceLine( trace ) 
			
				local trace = {}
				trace.start = self:GetPos()
				trace.endpos = self:LocalToWorld( Vector( 0, 800, 0 ) )
				trace.filter = self

				local tr_left = util.TraceLine( trace ) 
			
				if ( tr_right.HitWorld and tr_left.HitWorld ) or ( !tr_right.HitWorld and !tr_left.HitWorld ) then
					local rand = math.random(1,2)
					if rand == 1 then
						self.TurnRight = true
						self.LeftTraceRCur = CurTime() +2
					else
						self.TurnLeft = true
						self.RightTraceRCur = CurTime() +2
					end
				elseif tr_right.HitWorld then
					self.TurnLeft = true
					self.RightTraceRCur = CurTime() +2
				elseif tr_left.HitWorld then
					self.TurnRight = true
					self.LeftTraceRCur = CurTime() +2
				end
			end
		end
		timer.Create( "timer_created_timer" .. self.Entity:EntIndex( ), 5, 1, function() self.timer_created = false end )
	end
	
	
	if( ( !self.enemy or !ValidEntity( self.enemy ) ) and convar_ai == 0 and !self.attacking ) then
		if( !self.timer_created ) then
			self.timer_created = true
			timer.Create( "wandering_timer" .. self:EntIndex( ), math.random(7,10), 1, play_idle )
		end
	end
end 

function ENT:SpawnRagdoll( damage_force, body )
	local forcepos = self:LocalToWorld( self:OBBCenter() )

	if not util.IsValidRagdoll( "models/ichthyosaurragdoll.mdl" ) then return nil end

	local ragdoll = ents.Create( "prop_ragdoll" )

	ragdoll:SetModel( "models/ichthyosaurragdoll.mdl" )
	ragdoll:SetPos( self:GetPos() )
	ragdoll:SetAngles( self:GetAngles() )
	ragdoll:Spawn()

			
	if not ragdoll:IsValid() then return nil end

	local entvel
	local entphys = self:GetPhysicsObject()
	if entphys:IsValid() then
		entvel = entphys:GetVelocity()
	else
		entvel = self:GetVelocity()
	end


	for i=1,128 do
		local bone = ragdoll:GetPhysicsObjectNum( i )
		if ValidEntity( bone ) then
			local bonepos, boneang = self:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )

			bone:SetPos( bonepos )
			bone:SetAngle( boneang )

			bone:ApplyForceOffset( damage_force /3, forcepos )
			bone:AddVelocity( entvel )
		end
	end
	ragdoll:SetSkin( self:GetSkin() )
	ragdoll:SetColor( self:GetColor() )
	ragdoll:SetMaterial( self:GetMaterial() )
	if self:IsOnFire() then ragdoll:Ignite( math.Rand( 8, 10 ), 0 ) end
	local cvar_keepragdolls = GetConVarNumber("ai_keepragdolls")
	if( cvar_keepragdolls == 0 ) then
		ragdoll:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		ragdoll:Fire( "FadeAndRemove", "", 0.2 )
	else
		ragdoll:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE_DEBRIS )
	end
	undo.ReplaceEntity( self, ragdoll )
	cleanup.ReplaceEntity( self, ragdoll )
end


/*---------------------------------------------------------
Name: OnRemove
Desc: Called just before entity is deleted
//-------------------------------------------------------*/
function ENT:OnRemove()
	if self.init then
		self.attacksound1:Stop()
		self.attacksound2:Stop()
		self.attacksound3:Stop()
		
		self.idlesound1:Stop()
		self.idlesound2:Stop()
		self.idlesound3:Stop()
		self.idlesound4:Stop()
	end
	
	timer.Destroy( "self.enemy_occluded_timer" .. self:EntIndex() )
	timer.Destroy( "self.alert_allow_timer" .. self:EntIndex() )
	timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
	timer.Destroy( "damage_count_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "entity_index_remove_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "attack_end_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "attack_blastdelay_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "wandering_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "houndeye_setskin_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "timer_created_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "hunt_sound_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "self.ghide_reset_timer" .. self.Entity:EntIndex( ) )
end