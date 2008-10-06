AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/islave.mdl"
ENT.RangeDistance		= 1200
ENT.MeleeDistance		= 75

ENT.SpawnRagdollOnDeath = true
ENT.FadeOnDeath = false
ENT.BloodType = "green"
ENT.Pain = true
ENT.PainSound = "aslave/slv_pain"
ENT.PainSoundCount = 2
ENT.DeathSound = "aslave/slv_die"
ENT.DeathSoundCount = 2
ENT.DeathSkin = false

local schdChase = ai_schedule.New( "Chase Enemy" ) //creates the schedule used on this npc
schdChase:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdChase:EngTask( "TASK_RUN_PATH_TIMED", 0.2 )
schdChase:EngTask( "TASK_WAIT", 0.2 ) 

local schdFollow = ai_schedule.New( "Follow friend" )
schdFollow:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdFollow:EngTask( "TASK_RUN_PATH_WITHIN_DIST", 125 ) 

local schdRangeAttack = ai_schedule.New( "Attack Enemy range" ) 
schdRangeAttack:EngTask( "TASK_STOP_MOVING", 0 )
schdRangeAttack:EngTask( "TASK_STOP_MOVING", 0 )
//schdRangeAttack:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 )
//schdRangeAttack:AddTask( "PlaySequence", { Name = "attack", Speed = 0.8 } )
schdRangeAttack:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK1 )
//schdRangeAttack:AddTask( "Attack" )

local schdMeleeAttack = ai_schedule.New( "Attack Enemy melee" ) 
schdMeleeAttack:EngTask( "TASK_STOP_MOVING", 0 )
schdMeleeAttack:EngTask( "TASK_STOP_MOVING", 0 )
schdMeleeAttack:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_MELEE_ATTACK1 )

local schdWandering = ai_schedule.New( "Wander" ) 
schdWandering:AddTask( "wandering" )
schdWandering:EngTask( "TASK_GET_PATH_TO_RANDOM_NODE", 384 )
schdWandering:EngTask( "TASK_WALK_PATH", 0 ) 

local schdHide = ai_schedule.New( "Hide" ) 
schdHide:EngTask( "TASK_FIND_COVER_FROM_ENEMY", 0 ) 

local schdDodge = ai_schedule.New( "Dodge" ) 
schdDodge:EngTask( "TASK_FIND_BACKAWAY_FROM_SAVEPOSITION", 0 ) 

local schdReset = ai_schedule.New( "Reset" ) 
schdReset:EngTask( "TASK_RESET_ACTIVITY", 0 ) 

function ENT:Initialize()
	if( turret_index_table == nil ) then
		turret_index_table = {}
	end
	self.table_fear = {}

	self:SetModel( self.Model )
	self:SetHullType( HULL_WIDE_HUMAN );
	self:SetHullSizeNormal();

	self:SetSolid( SOLID_BBOX )
	self:SetMoveType( MOVETYPE_STEP )

	self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_MOVE_JUMP | CAP_OPEN_DOORS | CAP_INNATE_RANGE_ATTACK1 | CAP_FRIENDLY_DMG_IMMUNE | CAP_SQUAD )

	self:SetMaxYawSpeed( 5000 )

	if !self.health then
		self:SetHealth(sk_aslave_health_value)
	end

	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end
	
	self.attacksound1 = CreateSound( self, "debris/zap4.wav" )
	
	self.alertsound = "aslave/slv_alert"
	self.alertsound_amount = 3
	
	self:SetUpEnemies( false, false, true )
	self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }

	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
	
	// Particle Systems
	self.Zap_pre_effect_table = {}
	
	for i = 0,1 do
		self.Zap_pre_effect_a = ents.Create( "info_particle_system" )
		self.Zap_pre_effect_a:SetKeyValue( "effect_name", "vortigaunt_hand_glow" )
		
		self.Zap_pre_effect_a:SetParent( self )
		self.Zap_pre_effect_a:Spawn()
		self.Zap_pre_effect_a:Activate() 
		if i == 0 then
			self.Zap_pre_effect_a:Fire( "SetParentAttachment", "0", 0 )
		else
			self.Zap_pre_effect_a:Fire( "SetParentAttachment", "1", 0 )
		end
		table.insert( self.Zap_pre_effect_table, self.Zap_pre_effect_a )
	end
	
	self.allow_range_attack = true
	self.possess_viewpos = Vector( -80, 0, 100 )
	self.possess_addang = Vector(0,0,65)
end

function ENT:Think()
	if GetConVarNumber("ai_disabled") == 1 or self.efficient then return end
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
	
	for k, v in pairs( self.enemyTable_fear ) do
		local enemyTable_enemies_fr = ents.FindByClass( v )
		for k, v in pairs( enemyTable_enemies_fr ) do
			if( !table.HasValue( self.enemyTable_enemies_e, v ) ) then
				table.insert( self.enemyTable_enemies_e, v )
				v:AddEntityRelationship( self, 1, 10 )
				self:AddEntityRelationship( v, 2, 10 )
			end
		end
	end
	
	if self.possessed and !self.attacking and ( !self.possession_allowdelay or ( self.possession_allowdelay and CurTime() > self.possession_allowdelay ) ) then
		self.possession_allowdelay = nil
		self:PossessMovement( 120 )
		if !self.master then return end
		if self.master:KeyDown( 1 ) then
			self:Attack_Range( true )
		elseif self.master:KeyDown( 2048 ) then
			self:Attack_Melee(true)
		end
	end
	
	if self.possessed then return end
	local grenades = ents.FindByClass( "npc_grenade_frag" )
	for k,v in pairs(grenades) do
		local grenade_dist = v:GetPos():Distance( self:GetPos() )
		if( !self.ghide and grenade_dist < 256 and !self.FoundEnemy ) then
			self:SetEnemy( v, true )
			self:UpdateEnemyMemory( v, v:GetPos() )
			self:StartSchedule( schdHide )
			self.ghide = true
			self:SetEnemy( NULL )
			timer.Create( "self.ghide_reset_timer" .. self.Entity:EntIndex( ), 1, 1, function() self.ghide = false end )
		end
	end
end

function ENT:Attack_Range( poss )
	self.allow_range_attack = false
	self.attacking = true
	self.idle = 0
	self:StartSchedule( schdRangeAttack )

	self.attacksound1:Stop()
	self.attacksound1:Play()

	for k, v in pairs( self.Zap_pre_effect_table ) do
		v:Fire( "Start", "", 0 )
	end
	
	local function lAttak( tar )
		for k, v in pairs( self.Zap_pre_effect_table ) do
			v:Fire( "Stop", "", 0 )
		end
		if !poss and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
		self.Zap_effect_table = {}
		if poss or self:GetPos():Distance( self.enemy:GetPos() ) < 2000 then
			local enemy_pos_center
			if !poss then
				enemy_pos_center = self:GetCenter( self.enemy )
			else
				local trace = {}
				trace.start = self:GetPos()
				trace.endpos = self:LocalToWorld( Vector( 9999, 0, 450 ) )
				trace.filter = self

				local tr = util.TraceLine( trace ) 
				enemy_pos_center = tr.HitPos
			end
			self.zaptarget = ents.Create( "sent_killicon" )
			self.zaptarget:SetName( "aslv_tr" .. self:EntIndex() )
			if !poss then
				local tracedata = {}
				tracedata.start = self:GetPos()
				tracedata.endpos = enemy_pos_center
				tracedata.filter = self
				local trace = util.TraceLine(tracedata)
				if trace.Entity == self.enemy then
					self.zaptarget:SetPos( enemy_pos_center )
				else
					self.zaptarget:SetPos( trace.HitPos )
				end
			else
				self.zaptarget:SetPos( enemy_pos_center +Vector(self:GetForward().x, 0, 0 ) )
			end
			
			self.zaptarget:Spawn()
			self.zaptarget:Activate()
			local function zap()
				local tracedata = {}
				tracedata.start = self:GetPos()
				tracedata.endpos = self.zaptarget:GetPos()
				tracedata.filter = self
				local trace = util.TraceLine(tracedata)
				if trace.Entity and ValidEntity( trace.Entity ) and (trace.Entity:IsNPC() or trace.Entity:IsPlayer()) and (self:Disposition( trace.Entity ) == 1 or self:Disposition( trace.Entity ) == 2) then
					self.hitentity = true
				end 

				for i = 0,5 do
					self.Zap_effect = ents.Create( "info_particle_system" )
					if i == 0 or i == 1 then
						self.Zap_effect:SetKeyValue( "effect_name", "vortigaunt_beam" )
					elseif i == 2 or i == 3 then
						self.Zap_effect:SetKeyValue( "effect_name", "vortigaunt_beam_b" )
					elseif i == 4 or i == 5 then
						self.Zap_effect:SetKeyValue( "effect_name", "vortigaunt_beam_charge" )
					end
					self.Zap_effect:SetKeyValue( "cpoint1", "aslv_tr" .. self:EntIndex() )
					self.Zap_effect:SetParent( self )
					self.Zap_effect:Spawn()
					self.Zap_effect:Activate() 
					if i == 0 or i == 2 or i == 4 then
						self.Zap_effect:Fire( "SetParentAttachment", "0", 0 )
					else
						self.Zap_effect:Fire( "SetParentAttachment", "1", 0 )
					end
					self.Zap_effect:Fire( "Start", "", 0 )
				
					table.insert( self.Zap_effect_table, self.Zap_effect )
				end

				if self.hitentity then
					if( trace.Entity:GetClass() != "prop_physics" ) then
						trace.Entity:EmitSound( "hassault/hw_shoot1.wav", 500, 145 )
					end
					if trace.Entity:IsNPC() and trace.Entity:Health() - sk_aslave_zap_value <= 0 then
						self.killicon_ent = ents.Create( "sent_killicon" )
						self.killicon_ent:SetKeyValue( "classname", "sent_killicon_islave" )
						self.killicon_ent:Spawn()
						self.killicon_ent:Activate()
						self.killicon_ent:Fire( "kill", "", 0.1 )
						self.attack_inflictor = self.killicon_ent
					else
						self.attack_inflictor = self
					end
					trace.Entity:TakeDamage( sk_aslave_zap_value, self, self.attack_inflictor )
					self.attack_inflictor = nil
					if trace.Entity:IsPlayer() then
						trace.Entity:ViewPunch( Angle( -12, 0, 0 ) ) 
					end
						
					if( trace.Entity:GetClass() == "npc_turret_floor" and !table.HasValue( turret_index_table, trace.Entity:EntIndex() ) ) then
						table.insert( turret_index_table, trace.Entity:EntIndex() )
						trace.Entity:Fire( "selfdestruct", "", 0 )
						trace.Entity:GetPhysicsObject():ApplyForceCenter( Vector( 6000, 0, 9000 ) ) 
						local function entity_index_remove()
							table.remove( turret_index_table )
						end
						timer.Create( "entity_index_remove_timer" .. self.Entity:EntIndex( ), 4, 1, entity_index_remove )
					end
				end
			end
			timer.Create( "zap_delay_timer" .. self:EntIndex(), 0.02, 1, zap )
		end
		self.attacking = false
		if poss then self.possession_allowdelay = CurTime() +0.4 end
		timer.Create( "allow_r_attack_timer" .. self:EntIndex(), math.Rand(3,4), 1, function() self.allow_range_attack = true end )
		local function zap_rem()
			for k, v in pairs(self.Zap_effect_table) do
				v:Fire( "Stop", "", 0 )
				v:Remove()
			end
			if self.zaptarget and ValidEntity( self.zaptarget ) then self.zaptarget:Remove() end
			self.hitentity = nil
		end
		timer.Create( "zap_rem_timer" .. self:EntIndex(), 0.2, 1, zap_rem )
		
		if self.e_noname and ValidEntity( self.enemy ) then
			self.enemy:SetName( "" )
		end
		self.e_noname = false
	end
	
	timer.Create( "range_attack_end_timer" .. self.Entity:EntIndex( ), 1.6, 1, lAttak, self.enemy )
end

function ENT:Attack_Melee( poss )
	self.attacking = true
	self.idle = 0
	self:StartSchedule( schdMeleeAttack )
	local function attack_dmg()
		local self_pos = self:GetPos()
		local victim = ents.FindInSphere( self_pos, self.MeleeDistance )
		if !self.attack_c then
			self.attack_c = 1
		else
			self.attack_c = self.attack_c +1
		end

		for k, v in pairs(victim) do
			if( ( ( ( v:IsPlayer() and v:Alive() ) or v:IsNPC() ) and ( self:Disposition( v ) == 1 or self:Disposition( v ) == 2 ) ) or v:GetClass() == "prop_physics" ) then
				if( v:GetClass() != "prop_physics" ) then
					v:EmitSound( "npc/zombie/claw_strike" ..math.random(1,3).. ".wav", 100, 100)
				end
				if v:IsNPC() and v:Health() - (sk_aslave_slash_value /3) <= 0 then
					self.killicon_ent = ents.Create( "sent_killicon" )
					self.killicon_ent:SetKeyValue( "classname", "sent_killicon_islave" )
					self.killicon_ent:Spawn()
					self.killicon_ent:Activate()
					self.killicon_ent:Fire( "kill", "", 0.1 )
					self.attack_inflictor = self.killicon_ent
				else
					self.attack_inflictor = self
				end
				v:TakeDamage( (sk_aslave_slash_value /3), self, self.attack_inflictor )
				self.attack_inflictor = nil
				if v:IsPlayer() then
					if self.attack_c == 1 then
						v:ViewPunch( Angle( -6, -15, 0 ) ) 
					elseif self.attack_c == 2 then
						v:ViewPunch( Angle( -6, 15, 0 ) ) 
					else
						v:ViewPunch( Angle( -5, -11, 0 ) ) 
					end
				end
				
				if( v:GetClass() == "npc_turret_floor" and !table.HasValue( turret_index_table, v:EntIndex() ) ) then
					table.insert( turret_index_table, v:EntIndex() )
					v:Fire( "selfdestruct", "", 0 )
					v:GetPhysicsObject():ApplyForceCenter( Vector( 6000, 0, 9000 ) ) 
					local function entity_index_remove()
						table.remove( turret_index_table )
					end
					timer.Create( "entity_index_remove_timer" .. self.Entity:EntIndex( ), 4, 1, entity_index_remove )
				end
			else
				self:EmitSound( "npc/zombie/claw_miss" ..math.random(1,2).. ".wav", 80, 100)
			end
		end
		if self.attack_c == 3 then
			self.attacking = false
			self.attack_c = nil
			if poss then self.possession_allowdelay = CurTime() +0.3 end
		end
	end
	timer.Create( "melee_attack_dmgdelay_a_timer" .. self.Entity:EntIndex( ), 0.3, 1, attack_dmg )
	timer.Create( "melee_attack_dmgdelay_b_timer" .. self.Entity:EntIndex( ), 0.588, 1, attack_dmg )
	timer.Create( "melee_attack_dmgdelay_c_timer" .. self.Entity:EntIndex( ), 0.915, 1, attack_dmg )
end


function ENT:TaskStart_wandering()
	self:TaskComplete()
end 

function ENT:Task_wandering()
	if( self.FoundEnemy ) then
		self:TaskComplete()
	end
end


/*---------------------------------------------------------
 Name: SelectSchedule
//-------------------------------------------------------*/
function ENT:SelectSchedule()
	if self.efficient then return end
	local convar_ai = GetConVarNumber("ai_disabled")	
	if( ( self.FoundEnemy or self.FoundEnemy_fear ) and !self.attacking and !self.possessed and convar_ai == 0 ) then
		if !self.searchdelay then
			self.searchdelay = CurTime() +0.15
		end
		if self.searchdelay < CurTime() then
			self:FindInCone( 1, 9999 )  -- cone, SearchDist; cone: decrease this to decrease the angle within which it'll search; 1 = 90 degrees, 0.7 = 45-ish degrees, etc.
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
		
		if( self.enemy and ValidEntity( self.enemy ) and self.enemy:IsValid() and self.enemy:Health() > 0 and self:Disposition( self.enemy ) == 1 and self.enemy:GetPos():Distance( self:GetPos() ) <= self.closest_range ) then
			if( self.enemy:GetPos():Distance( Pos ) < self.RangeDistance and self.enemy:GetPos():Distance( Pos ) > self.MeleeDistance and self:HasCondition( 10 ) and !self:HasCondition( 42 ) and self.allow_range_attack ) then
				if( self.enemy:IsNPC() ) then
					self.SetEnemy( self.enemy )
				end
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				self:Attack_Range()
			elseif( self.enemy:GetPos():Distance( Pos ) < self.MeleeDistance and self:HasCondition( 10 ) and !self:HasCondition( 42 ) ) then
				if( self.enemy:IsNPC() ) then
					self.SetEnemy( self.enemy )
				end
				self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				self:Attack_Melee()
			elseif( self:HasCondition( 42 ) ) then
				self:UpdateEnemyMemory( self.enemy, self.enemy:GetPos() )
				self:StartSchedule( schdDodge )
			elseif( ( self.following and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) < 800 ) or !self.following ) then
				timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
				self:SetEnemy( self.enemy, true )
				self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				self:StartSchedule( schdChase )
			end
		elseif( ( !self.enemy or !ValidEntity(self.enemy) ) and self.enemy_fear and ValidEntity(self.enemy_fear) and self:HasCondition( 8 ) and !self:HasCondition( 7 ) ) then
			if( self.enemy_fear:IsNPC() ) then
				self:SetEnemy( self.enemy_fear )
			end
			self:UpdateEnemyMemory( self.enemy_fear, self.enemy_fear:GetPos() )
			self:StartSchedule( schdHide ) 
		else
			self.closest_range = 9999
		end
		
	self:SetEnemy( NULL )	
	elseif( self.idle == 0 and convar_ai == 0 ) then
		self.idle = 1
		self:SetSchedule( SCHED_IDLE_STAND )
		self:SelectSchedule()
	elseif( !self.FoundEnemy and self.FoundEnemy_fear == 0 and table.Count( self.table_fear ) > 0 ) then
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
	
	if( self.following and !self.possessed ) then
		if ValidEntity( self.follow_target ) then
			if( self:Disposition( self.follow_target ) != 3 ) then
				self:AddEntityRelationship( self.follow_target, 3, 10 )
			end

			if( self:GetPos():Distance( self.follow_target:GetPos() ) > 120 and ( ( ValidEntity( self.enemy ) and self.enemy != self.follow_target and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) > 800 ) or !ValidEntity( self.enemy ) ) and !self.attacking and convar_ai == 0 ) then
				self:SetEnemy( self.follow_target, true )
				self:UpdateEnemyMemory( self.follow_target, self.follow_target:GetPos() )
				self:StartSchedule( schdFollow )
				timer.Create( "self_select_schedule_timer" .. self:EntIndex(), 1, 1, function() self:StartSchedule( schdReset ) end )
			elseif( self.enemy == self.follow_target ) then
				self.enemy = NULL
			end
		else
			self.following = false
			self.follow_target = NULL
		end
	end
	
	
	local function wandering_schd()
		local convar_ai = GetConVarNumber("ai_disabled")
		if( convar_ai == 0 ) then
			self:StartSchedule( schdWandering )
		end
		timer.Create( "timer_created_timer" .. self.Entity:EntIndex( ), 5, 1, function() self.timer_created = false end )
	end
	
	
	if( self.wander == 1 and !self.following and !self.possessed and !self.FoundEnemy and convar_ai == 0 and !self.attacking ) then
		if( !self.timer_created ) then
			self.timer_created = true
			timer.Create( "wandering_timer" .. self.Entity:EntIndex( ), math.random(10,14), 1, wandering_schd )
		end
	else
		timer.Destroy( "wandering_timer" .. self.Entity:EntIndex( ) )
	end
end 

/*---------------------------------------------------------
Name: OnRemove
Desc: Called just before entity is deleted
//-------------------------------------------------------*/
function ENT:OnRemove()
	if self.init then
		self.attacksound1:Stop()
	end
	self:EndPossession()
	timer.Destroy( "self.ghide_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "entity_index_remove_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "zap_rem_timer" .. self:EntIndex() )
	timer.Destroy( "range_attack_end_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "entity_index_remove_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "melee_attack_dmgdelay_a_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "melee_attack_dmgdelay_b_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "melee_attack_dmgdelay_c_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "damage_count_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
	timer.Destroy( "timer_created_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "wandering_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "zap_delay_timer" .. self:EntIndex() )
end