AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/controller.mdl"
ENT.RangeDistance		= 1250 // def: 1250

ENT.SpawnRagdollOnDeath = true
ENT.FadeOnDeath = false
ENT.BloodType = "yellow"
ENT.Pain = true
ENT.PainSound = "npc/controller/con_pain"
ENT.PainSoundCount = 3
ENT.DeathSound = "npc/controller/con_die"
ENT.DeathSoundCount = 2
ENT.DeathSkin = false

local schdChase = ai_schedule.New( "Chase Enemy" ) //creates the schedule used on this npc
schdChase:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdChase:EngTask( "TASK_RUN_PATH_TIMED", 0.2 )
schdChase:EngTask( "TASK_WAIT", 0.2 ) 

local schdFollow = ai_schedule.New( "Follow friend" )
schdFollow:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdFollow:EngTask( "TASK_RUN_PATH_WITHIN_DIST", 125 ) 

local schdRangeAttack_a = ai_schedule.New( "Attack Enemy range a" ) 
schdRangeAttack_a:EngTask( "TASK_STOP_MOVING", 0 )
schdRangeAttack_a:EngTask( "TASK_STOP_MOVING", 0 )
schdRangeAttack_a:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK1 )

local schdRangeAttack_b = ai_schedule.New( "Attack Enemy range b" ) 
schdRangeAttack_b:EngTask( "TASK_STOP_MOVING", 0 )
schdRangeAttack_b:EngTask( "TASK_STOP_MOVING", 0 )
schdRangeAttack_b:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK2 )

local schdWandering = ai_schedule.New( "Wander" ) 
schdWandering:AddTask( "wandering" )
schdWandering:EngTask( "TASK_GET_PATH_TO_RANDOM_NODE", 384 )
schdWandering:EngTask( "TASK_WALK_PATH", 0 ) 

local schdHide = ai_schedule.New( "Hide" ) 
schdHide:EngTask( "TASK_FIND_COVER_FROM_ENEMY", 0 ) 

//local schdFlyUp = ai_schedule.New( "Fly up" ) 
//schdFlyUp:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_CONTROLLER_UP )

local schdDodge = ai_schedule.New( "Dodge" ) 
schdDodge:EngTask( "TASK_FIND_BACKAWAY_FROM_SAVEPOSITION", 0 ) 

local schdHurt = ai_schedule.New( "Hurt" ) 
schdHurt:EngTask( "TASK_SMALL_FLINCH", 0 ) 

local schdReset = ai_schedule.New( "Reset" ) 
schdReset:EngTask( "TASK_RESET_ACTIVITY", 0 ) 

function ENT:Initialize()
	if( turret_index_table == nil ) then
		turret_index_table = {}
	end
	self.table_fear = {}

	self:SetModel( self.Model )

	self:SetHullType( HULL_HUMAN );
	self:SetHullSizeNormal();

	self:SetSolid( SOLID_BBOX )
	self:SetMoveType( MOVETYPE_FLY )

	self:CapabilitiesAdd( CAP_MOVE_FLY | CAP_INNATE_RANGE_ATTACK1 | CAP_FRIENDLY_DMG_IMMUNE | CAP_SQUAD | CAP_SKIP_NAV_GROUND_CHECK )

	self:SetMaxYawSpeed( 5000 )

	if !self.health then
		self:SetHealth(sk_controller_health_value)
	end
	
	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end
	
	if !self.h_flyspeed then
		self.h_flyspeed = sk_controller_fly_speed_value
	end

	self.attacksound1 = CreateSound( self, "npc/controller/con_attack1.wav" )
	self.attacksound2 = CreateSound( self, "npc/controller/con_attack2.wav" )
	self.attacksound3 = CreateSound( self, "npc/controller/con_attack3.wav" )
	
	self.idlesound1 = CreateSound( self, "npc/controller/con_idle1.wav" )
	self.idlesound2 = CreateSound( self, "npc/controller/con_idle2.wav" )
	self.idlesound3 = CreateSound( self, "npc/controller/con_idle3.wav" )
	self.idlesound4 = CreateSound( self, "npc/controller/con_idle4.wav" )
	self.idlesound5 = CreateSound( self, "npc/controller/con_idle5.wav" )
	
	self:SetUpEnemies( false, false, true )
	//self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }

	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
end

function ENT:FlyToPos( Vec, Speed, x, y, z )
	local Entity_pos = self:GetPos()
	if x == 0 then
		Entity_pos.x = 0
	end
	if y == 0 then
		Entity_pos.y = 0
	end
	if z == 0 then
		Entity_pos.z = 0
	end
	local normal = (Vec - Entity_pos):GetNormalized() *Speed
	self:SetLocalVelocity( normal )
end

/*function ENT:FlySchedule( schedule )
	if !self.started_flyschedule then
		self.started_flyschedule = true
		self:StartSchedule( schedule )
		timer.Create( "self.started_flyschedule_reset_timer" .. self:EntIndex(), 3, 1, function() self.started_flyschedule = false end )
	end
end*/

function ENT:Think()
	if GetConVarNumber("ai_disabled") == 1 then return end

	if self.flytarget then
		if self.h_flytarget and ValidEntity( self.h_flytarget ) then
			if self:GetPos():Distance( self.h_flytarget:GetPos() ) <= 5 then
				local path_keyvalues = self.h_flytarget:GetKeyValues()
				for k, v in pairs( path_keyvalues ) do
					if k == "target" then
						if v then
							self.h_flytarget_n = v
							self.h_flytarget = ents.FindByName( self.h_flytarget_n )[1]
						else
							self.flytarget = false
						end
					end
				end
			end
			if self.flytarget and self.h_flytarget then
				self:FlyToPos( self.h_flytarget:GetPos(), self.h_flyspeed, 1, 1, 1 )
			end
		else
			self.flytarget = false
		end
	end
	
	if self.following or self.flytarget then return end
	self.flyveloc = Vector( 0, 0, 0 )
	if ValidEntity( self.enemy ) and self.FoundEnemy then
		self.enemy_dist = Vector( 0, 0, 0 )

		local self_enemy_pos = self.enemy:GetPos()
		local self_pos = self:GetPos()
		if self_enemy_pos.z < 0 and self_pos.z < 0 then
			self_enemy_pos.z = self_enemy_pos.z /-1
			self_pos.z = self_pos.z /-1
		end
		if( ( self_pos.z - self_enemy_pos.z ) < 150 ) then
			self.enemy_dist.z = 125
			self_enemy_pos.z = 0
		elseif( ( self_pos.z - self_enemy_pos.z ) > 200 ) then
			self.enemy_dist.z = -125
			self_enemy_pos.z = 0
			local c_veloc = self:GetVelocity()
			if c_veloc.z > 0 then
				c_veloc.z = 0				// temporary fix for the fly-to-the-sky bug
			end
			self:SetLocalVelocity( c_veloc )
		elseif( ( self_pos.z - self_enemy_pos.z ) >= 150 and ( self_enemy_pos.z - self_pos.z ) <= 200 ) then
			self.enemy_dist.z = 0
			self_enemy_pos.z = 0
		end
		local self_pos_xy = self:GetPos()
		self_pos_xy.z = 0
		local self_enemy_pos_xy = self.enemy:GetPos()
		self_enemy_pos_xy.z = 0
		if self_pos_xy:Distance( self_enemy_pos_xy ) < 380 and self_pos_xy:Distance( self_enemy_pos_xy ) >= 300 then
			self_enemy_pos.x = 0
			self_enemy_pos.y = 0
			self.enemy_dist.x = 0
			self.enemy_dist.y = 0
		elseif self_pos_xy:Distance( self_enemy_pos_xy ) < 200 and ( self_pos.z - self_enemy_pos.z ) < 200 then
			self.test = true
			self:SetLocalVelocity( (self:GetPos() - self_enemy_pos):GetNormalized() *160 )
		end
		if self_pos_xy:Distance( self_enemy_pos_xy ) > 300 and !self.test then
			self:FlyToPos( ( self_enemy_pos + self.enemy_dist ), self.h_flyspeed, 1, 1, 0 )
		end
		self.test = nil
	else
		// UP trace
		local trace = {}
		trace.start = self:GetPos()
		trace.endpos = self:GetPos() + Vector( 0, 0, 380 )
		trace.filter = self

		local tr = util.TraceLine( trace ) 
		if tr.HitWorld then 
			self.flyveloc = self.flyveloc + Vector( 0, 0, -50 )
		end
		
		// DOWN trace
		local trace = {}
		trace.start = self:GetPos()
		trace.endpos = self:GetPos() + Vector( 0, 0, -380 )
		trace.filter = self

		local tr = util.TraceLine( trace ) 
		if tr.HitWorld then 
			self.flyveloc = self.flyveloc + Vector( 0, 0, 50 )
			//self:FlySchedule( schdFlyUp )
		end

		// FORWARD trace
		local trace = {}
		trace.start = self:GetPos()
		trace.endpos = self:GetPos() + Vector( 380, 0, 0 )
		trace.filter = self

		local tr = util.TraceLine( trace ) 
		if tr.HitWorld then 
			self.flyveloc = self.flyveloc + Vector( -50, 0, 0 )
		end
		
		// BACKWARD trace
		local trace = {}
		trace.start = self:GetPos()
		trace.endpos = self:GetPos() + Vector( -380, 0, 0 )
		trace.filter = self

		local tr = util.TraceLine( trace ) 
		if tr.HitWorld then 
			self.flyveloc = self.flyveloc + Vector( 50, 0, 0 )
		end
		
		// LEFT trace
		local trace = {}
		trace.start = self:GetPos()
		trace.endpos = self:GetPos() + Vector( 0, 380, 0 )
		trace.filter = self

		local tr = util.TraceLine( trace ) 
		if tr.HitWorld then 
			self.flyveloc = self.flyveloc + Vector( 0, -50, 0 )
		end
		
		// RIGHT trace
		local trace = {}
		trace.start = self:GetPos()
		trace.endpos = self:GetPos() + Vector( 0, -380, 0 )
		trace.filter = self

		local tr = util.TraceLine( trace ) 
		if tr.HitWorld then 
			self.flyveloc = self.flyveloc + Vector( 0, 50, 0 )
		end
		self:SetLocalVelocity( self.flyveloc )
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

function ENT:Attack_Range_a()
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
	
	local function lAttak( tar )
		if !tar:IsValid() then 
			self.range_attacking = false
			for k, v in pairs( self.sprite_table ) do
				v:Remove()
			end
		return end
		
		local FireTrace = ((self.enemy:GetPos() + Vector(0,0,10)) - self:GetPos())
		local Firevector = FireTrace:GetNormalized()
		local FireLength = FireTrace:Length()
		local ArriveTime = FireLength / 2000
		local BaseShootVector = Firevector * 2000 + Vector(0,0,300 * ArriveTime)
		controller_disposition = self:Disposition( self.enemy )
		
		self.c_ball_count = 0
		local function c_ball_spawn( Vec )
			if self.enemy and ValidEntity( self.enemy ) then
				local c_ball = ents.Create("controller_ball_fire")
				c_ball:SetPos( Vec )
				c_ball:SetModel( "models/props_junk/watermelon01_chunk02c.mdl" )
				c_ball.owner = self
				c_ball.Speed = 115
				c_ball:SetMoveCollide( 3 )
				c_ball.enemy = self.enemy
				c_ball:SetOwner( self )
				c_ball:Spawn()
				local phys = c_ball:GetPhysicsObject()
					phys:SetMass( 1 )
					phys:EnableGravity( false )
					phys:EnableDrag( false )
					phys:ApplyForceCenter( ( self.enemy:GetPos() - self:GetPos() ):GetNormal() * 1000 )
			end
		end
		local rand = math.random(4,8)
		c_ball_spawn( self:LocalToWorld( Vector( 30, 0, 30 ) ) )
		timer.Create("C_Ball1_timer" .. self.Entity:EntIndex( ), 0.1, 1, c_ball_spawn, self:LocalToWorld( Vector( 25, 0, 27 ) ) )
		timer.Create("C_Ball2_timer" .. self.Entity:EntIndex( ), 0.2, 1, c_ball_spawn, self:LocalToWorld( Vector( 28, 0, 33 ) ) )
		if rand >= 4 then
			timer.Create("C_Ball3_timer" .. self.Entity:EntIndex( ), 0.3, 1, c_ball_spawn, self:LocalToWorld( Vector( 27, 0, 30 ) ) )
		end
		if rand >= 5 then
			timer.Create("C_Ball4_timer" .. self.Entity:EntIndex( ), 0.4, 1, c_ball_spawn, self:LocalToWorld( Vector( 31, 0, 32 ) ) )
		end
		if rand >= 6 then
			timer.Create("C_Ball5_timer" .. self.Entity:EntIndex( ), 0.5, 1, c_ball_spawn, self:LocalToWorld( Vector( 25, 0, 26 ) ) )
		end
		if rand >= 7 then
			timer.Create("C_Ball6_timer" .. self.Entity:EntIndex( ), 0.6, 1, c_ball_spawn, self:LocalToWorld( Vector( 29, 0, 32 ) ) )
		end
		if rand == 8 then
			timer.Create("C_Ball7_timer" .. self.Entity:EntIndex( ), 0.7, 1, c_ball_spawn, self:LocalToWorld( Vector( 30, 0, 30 ) ) )
		end
		
		local function attack_end()
			self.range_attacking = false
			for k, v in pairs( self.sprite_table ) do
				v:Remove()
			end
		end
		timer.Create("attack_end_timer" .. self.Entity:EntIndex( ), 0.7, 1, attack_end )
	end
	timer.Create( "range_attack_end_timer" .. self.Entity:EntIndex( ), 2.3, 1, lAttak, self.enemy )
	self.sprite_count = 0
	self.sprite_table = {}
	local function c_ball_sprites()
		self.sprite_count = self.sprite_count +1
		local sprite = ents.Create( "env_sprite" )
		sprite:SetKeyValue( "rendermode", "9" )
		sprite:SetKeyValue( "rendercolor", "255 141 15" )
		sprite:SetKeyValue( "model", "sprites/orangecore2.spr" )
		sprite:SetKeyValue( "scale", "0.4" )
		sprite:SetKeyValue( "spawnflags", "1" )
		sprite:SetPos( self:GetPos() )
		sprite:Spawn()
		sprite:Activate()
		sprite:SetParent( self )
		if self.sprite_count == 1 then
			sprite:Fire( "SetParentAttachment", "2", 0 )
			c_ball_sprites()
		else
			sprite:Fire( "SetParentAttachment", "3", 0 )
		end
		table.insert( self.sprite_table, sprite )
	end
	timer.Create( "range_attack_sprite_timer" .. self.Entity:EntIndex( ), 0.8, 1, c_ball_sprites )
end

function ENT:Attack_Range_b()
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
	
	local function lAttak( tar )
		if !tar:IsValid() then self.range_attacking = false; return end
		local FireTrace = ((self.enemy:GetPos() + Vector(0,0,10)) - self:GetPos())
		local Firevector = FireTrace:GetNormalized()
		local FireLength = FireTrace:Length()
		local ArriveTime = FireLength / 2000
		local BaseShootVector = Firevector * 2000 + Vector(0,0,300 * ArriveTime)
		controller_disposition = self:Disposition( self.enemy )
	
		local c_ball = ents.Create("controller_ball_dark")
		local bone_pos, bone_ang = self:GetBonePosition( self:LookupBone("Bip01 L Hand") )
		c_ball:SetPos( bone_pos + Vector( 15, 0, 30 ) )
		c_ball:SetModel( "models/props_junk/watermelon01_chunk02c.mdl" )
		c_ball.owner = self
		c_ball.Speed = 100
		c_ball:SetMoveCollide( 3 )
		c_ball.enemy = self.enemy
		c_ball:SetOwner( self )
		c_ball:Spawn()
		local function c_ball_pos()
			if self and ValidEntity( self ) and ValidEntity( c_ball ) then
				local bone_pos, bone_ang = self:GetBonePosition( self:LookupBone("Bip01 L Hand") )
				c_ball:SetPos( bone_pos + Vector( 15, 0, 30 ) )
			end
		end
		timer.Create( "c_ball_pos_timer" .. self.Entity:EntIndex( ), 0.05, 0, c_ball_pos )
		
		
		local function throw_c_ball()
			timer.Destroy( "c_ball_pos_timer" .. self.Entity:EntIndex( ) )
			if ValidEntity( c_ball ) then
				local phys = c_ball:GetPhysicsObject()
					phys:SetMass( 1 )
					phys:EnableGravity( false )
					phys:EnableDrag( false )

					phys:ApplyForceCenter( ( self.enemy:GetPos() - self:GetPos() ):GetNormal() * 1000 )
			end
			self.range_attacking = false
		end
		timer.Create( "throw_c_ball_timer" .. self.Entity:EntIndex( ), 1.05, 1, throw_c_ball )
	end
	timer.Create( "range_attack_end_timer" .. self.Entity:EntIndex( ), 0.64, 1, lAttak, self.enemy )
end



/*---------------------------------------------------------
 Name: SelectSchedule
//-------------------------------------------------------*/
function ENT:SelectSchedule()
	if self.efficient then return end
	local convar_ai = GetConVarNumber("ai_disabled")
	
	if( ( self.FoundEnemy or self.FoundEnemy_fear ) and !self.range_attacking and convar_ai == 0 ) then
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
			if( self.enemy:GetPos():Distance( Pos ) < self.RangeDistance and self:HasCondition( 10 ) and !self:HasCondition( 42 ) ) then
				if( self.enemy:IsNPC() ) then
					self.SetEnemy( self.enemy )
				end
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				self.range_attacking = true
				self.idle = 0
				if !self.range_sec_charged then
					self:StartSchedule( schdRangeAttack_a )
					self:Attack_Range_a()
				else
					local rand = math.random( 1, 3 )
					if rand == 3 then
						self:StartSchedule( schdRangeAttack_b )
						self:Attack_Range_b()
					else
						self.range_attacking = false
					end
					self.range_sec_charged = false
					timer.Destroy( "sec_attack_recharge_timer" .. self:EntIndex() )
				end
				if !self.range_sec_charged and !timer.IsTimer( "sec_attack_recharge_timer" .. self:EntIndex() ) then
					timer.Create( "sec_attack_recharge_timer" .. self:EntIndex(), math.Rand( 8, 20 ), 1, function() self.range_sec_charged = true end )
				end
			elseif( self:HasCondition( 42 ) ) then
				self:UpdateEnemyMemory( self.enemy, self.enemy:GetPos() )
				self:StartSchedule( schdDodge )
			elseif( ( self.following and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) < 900 ) or !self.following ) then
				timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
				self:SetEnemy( self.enemy, true )
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				self:StartSchedule( schdChase )
			end
		/*elseif( ( !self.enemy or !ValidEntity(self.enemy) ) and self.enemy_fear and ValidEntity(self.enemy_fear) and self:HasCondition( 8 ) and !self:HasCondition( 7 ) ) then
			if( self.enemy_fear:IsNPC() ) then
				self:SetEnemy( self.enemy_fear )
			end
			self:UpdateEnemyMemory( self.enemy_fear, self.enemy_fear:GetPos() )
			self:StartSchedule( schdHide ) */
		else
			self.closest_range = 9999
		end
		
	self:SetEnemy( NULL )	
	elseif( self.idle == 0 and convar_ai == 0 ) then
		self.idle = 1
		self:SetSchedule( SCHED_IDLE_STAND )
		self:SelectSchedule()
	/*elseif( !self.FoundEnemy and !self.FoundEnemy_fear and table.Count( self.table_fear ) > 0 ) then
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
		end*/
	end
	
	if( self.following ) then
		if ValidEntity( self.follow_target ) then
			if( self:Disposition( self.follow_target ) != 3 ) then
				self:AddEntityRelationship( self.follow_target, 3, 10 )
			end

			if( self:GetPos():Distance( self.follow_target:GetPos() ) > 120 and ( ( ValidEntity( self.enemy ) and self.enemy != self.follow_target and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) > 800 ) or !ValidEntity( self.enemy ) ) and !self.range_attacking and convar_ai == 0 ) then
				self:SetEnemy( self.follow_target, true )
				self:UpdateEnemyMemory( self.follow_target, self.follow_target:GetPos() )
				self:FlyToPos( self.follow_target:GetPos(), self.h_flyspeed, 1, 1, 1 )
				timer.Create( "self_select_schedule_timer" .. self:EntIndex(), 1, 1, function() self:StartSchedule( schdReset ) end )
			elseif( self.enemy == self.follow_target ) then
				self.enemy = NULL
			end
		else
			self.following = false
			self.follow_target = NULL
		end
	end
	
	
	/*local function wandering_schd()
		local convar_ai = GetConVarNumber("ai_disabled")
		if( convar_ai == 0 ) then
			self:StartSchedule( schdWandering )
		end
		timer.Create( "timer_created_timer" .. self.Entity:EntIndex( ), 5, 1, function() self.timer_created = false end )
	end*/
	
	
	if( self.wander == 1 and !self.following and !self.FoundEnemy and convar_ai == 0 and !self.range_attacking ) then
		if( !self.timer_created ) then
			self.timer_created = true
			local idle_random = math.random(1,5)
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
			
			if (idle_random == 5) then
				self.idlesound5:Stop()
				self.idlesound5:Play()
			end
			timer.Create( "timer_created_timer" .. self.Entity:EntIndex( ), 5, 1, function() self.timer_created = false end )
			//timer.Create( "wandering_timer" .. self.Entity:EntIndex( ), math.random(10,14), 1, wandering_schd )
		end
	else
		timer.Destroy( "wandering_timer" .. self.Entity:EntIndex( ) )
	end
end 

function ENT:KeyValue( key, value )
	if( key == "squadname" or key == "netname" ) then
		self.squad = value
		self:SetupSquad()
	end
	if( key == "wander" and value == "1" ) then
		self.wander = 1
	elseif( key == "wander" ) then
		self.wander = 0
	end
	
	if( key == "health" ) then
		self.health = value
	end
	
	if( key == "target" ) then
		self.h_flytarget_n = value
	end
	
	if( key == "flyspeed" ) then
		self.h_flyspeed = value
	end
	//self[key] = value
end


function ENT:AcceptInput( cvar_name, activator, caller )
	if cvar_name == "setsquad" then
		timer.Simple( 0.01, function() self.squad = self:GetKeyValue( self, "squadname" ); self:SetupSquad() end )
	end
	
	if( string.find( cvar_name,"startflyingpath" ) and ( ( caller:IsPlayer() and caller:IsAdmin() ) or !caller:IsPlayer() ) and !self.flytarget and self.h_flytarget_n ) then
		self.h_flytarget = ents.FindByName( self.h_flytarget_n )[1]
		if self.h_flytarget then
			self:FlyToPos( self.h_flytarget:GetPos(), self.h_flyspeed, 1, 1, 1 )
			self.flytarget = true
		end
	end
	
	if( string.find( cvar_name,"stopflyingpath" ) and ( ( caller:IsPlayer() and caller:IsAdmin() ) or !caller:IsPlayer() ) and self.flytarget ) then
		self.flytarget = false
		self.h_flytarget = nil
	end
	
	if( string.find( cvar_name,"followtarget_" ) and ( ( caller:IsPlayer() and caller:IsAdmin() ) or !caller:IsPlayer() ) and !self.following ) then
		self.follow_target_string = string.Replace(cvar_name,"followtarget_","") 
		if( self.follow_target_string != "!self" and !string.find( cvar_name,"followtarget_!player" ) ) then
			self.follow_target_t = ents.FindByName( self.follow_target_string )
		elseif( self.follow_target_string == "!self" ) then
			if ValidEntity( caller ) then
				self.follow_target = caller
			end
		elseif( string.find( cvar_name,"followtarget_!player" ) ) then
			if( self.follow_target_string == "!player" ) then
				self.follow_closest_range = 9999
				for k, v in pairs( player:GetAll() ) do
					self.follow_closest = v:GetPos():Distance( self:GetPos() )
					if( self.follow_closest < self.follow_closest_range ) then
						self.follow_closest_range = v:GetPos():Distance( self:GetPos() )
						self.follow_target = v
					end
				end
			else
				self.follow_target_userid = string.Replace(cvar_name,"followtarget_!player","") 
				for k, v in pairs( player:GetAll() ) do
					if( tostring(v:UserID( )) == self.follow_target_userid ) then
						self.follow_target = v
					end
				end
			end
		end
		
		if( self.follow_target or ( self.follow_target_t and table.Count( self.follow_target_t ) == 1 ) ) then
			self.following = true
			if !ValidEntity( self.follow_target ) and self.follow_target_t then
				for k, v in pairs( self.follow_target_t ) do
					if( v != self ) then
						self.follow_target = v
					else
						self.following = false
						caller:PrintMessage( HUD_PRINTCONSOLE, "Can't follow itself! \n" )
					end
				end
			end
			
			if( self.follow_target:IsPlayer() or self.follow_target:IsNPC() ) then
				self.following_disp = self:Disposition( self.follow_target )
				self:AddEntityRelationship( self.follow_target, 3, 10 )
			end
		elseif( self.follow_target_t and table.Count( self.follow_target_t ) > 1 ) then
			self.following = true
			self.follow_closest_range = 9999
			for k, v in pairs( self.follow_target_t ) do
				self.follow_closest = v:GetPos():Distance( self:GetPos() )
				if( self.follow_closest < self.follow_closest_range ) then
					if( v != self ) then
						self.follow_closest_range = v:GetPos():Distance( self:GetPos() )
						self.follow_target = v
					end
				end
			end
				
			if( self.follow_target:IsPlayer() or self.follow_target:IsNPC() ) then
				self.following_disp = self:Disposition( self.follow_target )
				self:AddEntityRelationship( self.follow_target, 3, 10 )
			end
		elseif caller:IsPlayer() then
			caller:PrintMessage( HUD_PRINTCONSOLE, "No entity called '" .. self.follow_target_string .. "' found! \n" )
		end
	end
	if( cvar_name == "stopfollowtarget" and self.following and ( ( caller:IsPlayer() and caller:IsAdmin() ) or !caller:IsPlayer() ) ) then
		self.following = false
		if self.following_disp then
			self:AddEntityRelationship( self.follow_target, self.following_disp, 10 )
		end
		timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
		self:StartSchedule( schdReset )
		self.follow_target = NULL
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
		self.idlesound5:Stop()
	end
	
	if self.sprite_table then
		for k, v in pairs( self.sprite_table ) do
			if ValidEntity( v ) then
				v:Remove()
			end
		end
	end
	
	timer.Destroy( "self.enemy_occluded_timer" .. self:EntIndex() )
	timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
	timer.Destroy("C_Ball1_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy("C_Ball2_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy("C_Ball3_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy("C_Ball4_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy("C_Ball5_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy("C_Ball6_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy("C_Ball7_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy("attack_end_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "range_attack_end_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "range_attack_sprite_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "c_ball_pos_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "throw_c_ball_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "damage_count_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "sec_attack_recharge_timer" .. self:EntIndex() )
	timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
	timer.Destroy( "timer_created_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "wandering_timer" .. self.Entity:EntIndex( ) )
end