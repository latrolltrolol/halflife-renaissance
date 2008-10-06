AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/houndeye.mdl"
ENT.MinDistance		= 265

ENT.SpawnRagdollOnDeath = true
ENT.FadeOnDeath = false
ENT.BloodType = "yellow"
ENT.Pain = true
ENT.PainSound = "npc/houndeye/he_pain"
ENT.PainSoundCount = 5
ENT.DeathSound = "npc/houndeye/he_die"
ENT.DeathSoundCount = 3
ENT.DeathSkin = 2

local schdChase = ai_schedule.New( "Chase Enemy" ) //creates the schedule used on this npc
schdChase:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdChase:EngTask( "TASK_RUN_PATH_TIMED", 0.2 )
schdChase:EngTask( "TASK_WAIT", 0.2 ) 

local schdFollow = ai_schedule.New( "Follow friend" )
schdFollow:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdFollow:EngTask( "TASK_RUN_PATH_WITHIN_DIST", 125 ) 

local schdWait = ai_schedule.New( "Wait" )
schdWait:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 )

local schdAttack = ai_schedule.New( "Attack Enemy" ) 
schdAttack:EngTask( "TASK_STOP_MOVING", 0 )
schdAttack:EngTask( "TASK_STOP_MOVING", 0 )
//schdAttack:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 )
//schdAttack:AddTask( "PlaySequence", { Name = "attack", Speed = 0.8 } )
schdAttack:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK1 )
//schdAttack:AddTask( "Attack" )

local schdWandering = ai_schedule.New( "Wander" ) 
schdWandering:AddTask( "wandering" )
schdWandering:EngTask( "TASK_GET_PATH_TO_RANDOM_NODE", 384 )
schdWandering:EngTask( "TASK_WALK_PATH", 0 ) 

local schdHide = ai_schedule.New( "Hide" ) 
schdHide:EngTask( "TASK_FIND_COVER_FROM_ENEMY", 0 ) 

local schdReset = ai_schedule.New( "Reset" ) 
schdReset:EngTask( "TASK_RESET_ACTIVITY", 0 ) 

local schdMad_a = ai_schedule.New( "Mad Idle a" ) 
schdMad_a:AddTask( "PlaySequence", { Name = "madidle", Speed = 1 } )

local schdMad_b = ai_schedule.New( "Mad Idle b" ) 
schdMad_b:AddTask( "PlaySequence", { Name = "madidle2", Speed = 1 } )

local schdMad_c = ai_schedule.New( "Mad Idle c" ) 
schdMad_c:AddTask( "PlaySequence", { Name = "madidle3", Speed = 1 } )

function ENT:Initialize()
	if( turret_index_table == nil ) then
		turret_index_table = {}
	end
	self.table_fear = {}

	self:SetModel( self.Model )

	self:SetHullType( HULL_HUMAN );
	self:SetHullSizeNormal();

	self:SetSolid( SOLID_BBOX )
	self:SetMoveType( MOVETYPE_STEP )

	self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_MOVE_JUMP | CAP_OPEN_DOORS | CAP_INNATE_RANGE_ATTACK1 | CAP_FRIENDLY_DMG_IMMUNE | CAP_SQUAD )
	//self.customcaps = { "CAP_HEAR" }
	self:SetMaxYawSpeed( 5000 )


	if !self.health then
		self:SetHealth(sk_houndeye_health_value)
	end
	
	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end

	self.attacksound1 = CreateSound( self, "npc/houndeye/he_attack1.wav" )
	self.attacksound2 = CreateSound( self, "npc/houndeye/he_attack2.wav" )
	self.attacksound3 = CreateSound( self, "npc/houndeye/he_attack3.wav" )
	
	self.idlesound1 = CreateSound( self, "npc/houndeye/he_idle1.wav" )
	self.idlesound2 = CreateSound( self, "npc/houndeye/he_idle2.wav" )
	self.idlesound3 = CreateSound( self, "npc/houndeye/he_idle3.wav" )
	self.idlesound4 = CreateSound( self, "npc/houndeye/he_idle4.wav" )
	
	self.alertsound = "npc/houndeye/he_alert"
	self.alertsound_amount = 3
	self:SetUpEnemies()
	self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }
	
	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
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


	if( !self.FoundEnemy ) then
		timer.Destroy("hunt_sound_timer" .. self.Entity:EntIndex( )) 
	end
	
	if self.possessed and !self.attacking then
		self:PossessMovement( 100 )
		if !self.master then return end
		if self.master:KeyDown( 1 ) then
			self:Attack()
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

function ENT:MadIdle()
	local rand = math.random(1,3)
	if rand == 1 then
		self:StartSchedule( schdMad_a )
	elseif rand == 2 then
		self:StartSchedule( schdMad_b )
		self:EmitSound( "npc/houndeye/he_pain3.wav" )
		self:Fire( "Skin", "1", 0 )
		self:Fire( "Skin", "2", 0.08 )
		self:Fire( "Skin", "0", 0.12 )
		self:Fire( "Skin", "1", 0.2 )
		self:Fire( "Skin", "2", 0.28 )
		self:Fire( "Skin", "0", 0.32 )
		self:Fire( "Skin", "1", 0.8 )
		self:Fire( "Skin", "2", 0.87 )
		self:Fire( "Skin", "0", 0.94 )
		timer.Create( "madidleb_timer_a" .. self:EntIndex(), 0.2, 1, function() self:EmitSound( "npc/houndeye/he_pain3.wav" ) end )
		timer.Create( "madidleb_timer_b" .. self:EntIndex(), 0.8, 1, function() self:EmitSound( "npc/houndeye/he_pain1.wav" ) end )
	else
		self:StartSchedule( schdMad_c )
	end
end

function ENT:Attack()
	timer.Destroy("hunt_sound_timer" .. self.Entity:EntIndex( )) 
	
	self.attacking = true
	self.idle = 0
	self:StartSchedule( schdAttack )
	
	self.attacksound1:Stop()
	self.attacksound2:Stop()
	self.attacksound3:Stop()
	
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

	self:SetSkin( 1 )

	local function attack_blast()
		self:EmitSound( "npc/houndeye/he_blast" ..math.random(1,3).. ".wav", 500, 100)
		local self_pos = self:GetPos()
		
		local houndeye_blasteffect = ents.Create( "prop_combine_ball" )
		houndeye_blasteffect:SetPos( self_pos )
		houndeye_blasteffect:SetParent( self )
		houndeye_blasteffect:Spawn()
		houndeye_blasteffect:Fire( "explode", "", 0 )
		
		self:SetSkin( 2 )
		timer.Create( "houndeye_setskin_timer" .. self.Entity:EntIndex( ), 0.1, 1, function() self:SetSkin( 0 ) end )

		local victim = ents.FindInSphere( self_pos, 400 )
		for k, v in pairs(victim) do
			if( ( ( ( v:IsPlayer() and v:Alive() ) or v:IsNPC() ) and ( self:Disposition( v ) == 1 or self:Disposition( v ) == 2 ) ) or v:GetClass() == "prop_physics" ) then
				if v:IsNPC() and v:Health() - sk_houndeye_blast_value <= 0 then
					self.killicon_ent = ents.Create( "sent_killicon" )
					self.killicon_ent:SetKeyValue( "classname", "sent_killicon_houndeye" )
					self.killicon_ent:Spawn()
					self.killicon_ent:Activate()
					self.killicon_ent:Fire( "kill", "", 0.1 )
					self.attack_inflictor = self.killicon_ent
				else
					self.attack_inflictor = self
				end
				v:TakeDamage( sk_houndeye_blast_value, self, self.attack_inflictor )  
				
				if v:IsPlayer() then v:SetDSP( 34, false ) end
				
				if( v:GetClass() == "npc_turret_floor" and !table.HasValue( turret_index_table, v:EntIndex() ) ) then
					table.insert( turret_index_table, v:EntIndex() )
					v:Fire( "selfdestruct", "", 0 )
					v:GetPhysicsObject():ApplyForceCenter( Vector( 6000, 0, 9000 ) ) 
					local function entity_index_remove()
						table.remove( turret_index_table )
					end
					timer.Create( "entity_index_remove_timer" .. self.Entity:EntIndex( ), 4.4, 1, entity_index_remove )
				end
			end
		end
		
		local function attack_end()
			self:StartSchedule( schdWait )
			self.timer_allow = 1
			//timer.Destroy( "attacking_reset_timer" .. self:EntIndex() )
			local rand = math.random(1,2)
			if rand == 1 and self.enemy and ValidEntity( self.enemy ) and self:GetPos():Distance( self.enemy:GetPos() ) > self.MinDistance then
				timer.Create( "attacking_reset_timer" .. self:EntIndex(), 1.7, 1, function() self.attacking = false end )
				timer.Create( "MadIdle_delay_timer" .. self:EntIndex(), 0.2, 1, function() self:MadIdle() end )
			else
				timer.Create( "attacking_reset_timer" .. self:EntIndex(), 0.6, 1, function() self.attacking = false end )
			end
		end
		timer.Create( "attack_end_timer" .. self.Entity:EntIndex( ), 0.6, 1, attack_end )
	end
	timer.Create( "attack_blastdelay_timer" .. self.Entity:EntIndex( ), 2.5, 1, attack_blast )
end


function ENT:TaskStart_wandering()
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
		local Pos = self.Entity:GetPos()
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
		if self.enemy then self:CheckEnemy( 1 ) end
		if self.enemy_fear then self:CheckEnemy( 3 ) end
		if( self.enemy and ValidEntity( self.enemy ) and self.enemy:GetPos():Distance( self:GetPos() ) <= self.closest_range ) then
			if( self.enemy:GetPos():Distance( Pos ) < self.MinDistance and ( self:HasCondition( 10 ) or self.hadnewenemy ) and !self:HasCondition( 42 ) ) then
				if( self.enemy:IsNPC() ) then
					self.SetEnemy( self.enemy )
				end
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				self:Attack()
			elseif( ( self.following and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) < 800 ) or !self.following ) then
				timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
				self:SetEnemy( self.enemy, true )
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				self:StartSchedule( schdChase )
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
			self:StartSchedule( schdHide ) 
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
	
	if( self.following and !self.possessed ) then
		if ValidEntity( self.follow_target ) then
			if( self:Disposition( self.follow_target ) != 3 ) then
				self:AddEntityRelationship( self.follow_target, 3, 10 )
			end
			
			if( self:GetPos():Distance( self.follow_target ) > 175 and ( ( ValidEntity( self.enemy ) and self.enemy != self.follow_target and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) > 800 ) or !ValidEntity( self.enemy ) ) and !self.attacking and convar_ai == 0 ) then
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
	end
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
	self:EndPossession()
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
	timer.Destroy( "attacking_reset_timer" .. self:EntIndex() )
	timer.Destroy( "MadIdle_delay_timer" .. self:EntIndex() )
	timer.Destroy( "madidleb_timer_a" .. self:EntIndex() )
	timer.Destroy( "madidleb_timer_b" .. self:EntIndex() )
end