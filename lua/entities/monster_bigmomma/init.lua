AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/big_mom.mdl"
ENT.RangeDistance		= 1250
ENT.MeleeDistance		= 135

ENT.birth_recharged = true

ENT.range_attack_counter = 0
ENT.dead_child_counter = 0
ENT.attack_counter_max_r = math.random(2,4)
ENT.ChildTable = {}
ENT.bcrab_allow = true
ENT.Attack_allow = true

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
schdRangeAttack:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK1 )

local schdBirthBCrab = ai_schedule.New( "Spawn Baby Crabs" ) 
schdBirthBCrab:EngTask( "TASK_STOP_MOVING", 0 )
schdBirthBCrab:EngTask( "TASK_STOP_MOVING", 0 )
schdBirthBCrab:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_MELEE_ATTACK2 )

local schdMeleeAttack = ai_schedule.New( "Attack Enemy melee" ) 
schdMeleeAttack:EngTask( "TASK_STOP_MOVING", 0 )
schdMeleeAttack:EngTask( "TASK_STOP_MOVING", 0 )
schdMeleeAttack:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_MELEE_ATTACK1 )

local schdAlert_a = ai_schedule.New( "Alert1" ) 
schdAlert_a:EngTask( "TASK_STOP_MOVING", 0 )
schdAlert_a:EngTask( "TASK_STOP_MOVING", 0 )
schdAlert_a:AddTask( "PlaySequence", { Name = "angry1", Speed = 1 } )

local schdAlert_b = ai_schedule.New( "Alert2" ) 
schdAlert_b:EngTask( "TASK_STOP_MOVING", 0 )
schdAlert_b:EngTask( "TASK_STOP_MOVING", 0 )
schdAlert_b:AddTask( "PlaySequence", { Name = "angry2", Speed = 1 } )

local schdAlert_c = ai_schedule.New( "Alert3" ) 
schdAlert_c:EngTask( "TASK_STOP_MOVING", 0 )
schdAlert_c:EngTask( "TASK_STOP_MOVING", 0 )
schdAlert_c:AddTask( "PlaySequence", { Name = "angry3", Speed = 1 } )

local schdWandering = ai_schedule.New( "Wander" ) 
schdWandering:AddTask( "wandering" )
schdWandering:EngTask( "TASK_GET_PATH_TO_RANDOM_NODE", 384 )
schdWandering:EngTask( "TASK_WALK_PATH", 0 ) 

local schdHide = ai_schedule.New( "Hide" ) 
schdHide:EngTask( "TASK_FIND_COVER_FROM_ENEMY", 0 ) 

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
	
	if ( self.Entity_angles != nil ) then
		self:SetAngles( self.Entity_angles ) 
	end


	self:SetModel( self.Model )

	self:SetHullType( HULL_LARGE );
	self:SetHullSizeNormal();

	self:SetSolid( SOLID_BBOX )
	self:SetMoveType( MOVETYPE_STEP )

	self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_OPEN_DOORS | CAP_INNATE_RANGE_ATTACK1 | CAP_FRIENDLY_DMG_IMMUNE | CAP_SQUAD )

	self:SetMaxYawSpeed( 5000 )
	
	if !self.health then
		self:SetHealth(sk_gonarch_health_value)
	end
	
	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end

	self.attacksound1 = CreateSound( self, "npc/gonarch/gon_attack1.wav" )
	self.attacksound2 = CreateSound( self, "npc/gonarch/gon_attack2.wav" )
	self.attacksound3 = CreateSound( self, "npc/gonarch/gon_attack3.wav" )
	
	self.alertsound = "npc/gonarch/gon_alert"
	self.alertsound_amount = 3
	self.alertanim = true
	
	self:SetUpEnemies( true )
	self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }
	self.enemyTable_LI = { "monster_headcrab", "monster_zombie", "npc_fastzombie_torso", "npc_fastzombie", "npc_poisonzombie", "npc_zombie", "npc_zombie_torso", "npc_zombine", "npc_headcrab_black", "npc_headcrab_poison", "npc_headcrab_fast", "npc_headcrab", "monster_babycrab" }
	
	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
	
	self.possess_viewpos = Vector( -186, 0, 230 )
	self.possess_addang = Vector(0,0,200)
end

function ENT:PlayAlertAnim()
	local random_alert_anim = math.random(1,3)
	if( random_alert_anim == 1 ) then
		self:StartSchedule( schdAlert_a )
	elseif( random_alert_anim == 2 ) then
		self:StartSchedule( schdAlert_b )
	else
		self:StartSchedule( schdAlert_c )
	end
	self.Attack_allow = false
	timer.Create( "alert_reset_timer" .. self:EntIndex(), 2, 1, function() self.Attack_allow = true end )
end

function ENT:Think()
	local combine_balls = ents.FindByClass( "prop_combine_ball" )
	for k,v in pairs(combine_balls) do
		if( ValidEntity( v ) ) then
			constraint.NoCollide( self, v, 0, 0 );  
		end
	end
	if GetConVarNumber("ai_disabled") == 1 then return end
	
	if( self:GetActivity( ) == 10 or self:GetActivity( ) == 6 ) then
		local function playstepsound()
			self:EmitSound( "npc/gonarch/gon_step" .. math.random(1,3) .. ".wav", 100, 100 )
			self.step_time = nil
		end
		
		if( self:GetActivity( ) == 10 ) then
			self.step_delay = 0.3
		else
			self.step_delay = 0.55
		end
		if !self.step_time then self.step_time = CurTime() +self.step_delay end
		if CurTime() > self.step_time then
			playstepsound()
		end
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
	
	for k, v in pairs( self.enemyTable_LI ) do
		local enemyTable_enemies_li = ents.FindByClass( v )
		for k, v in pairs( enemyTable_enemies_li ) do
			if( !table.HasValue( self.enemyTable_enemies_e, v ) ) then
				table.insert( self.enemyTable_enemies_e, v )
				v:AddEntityRelationship( self, 3, 10 )
				self:AddEntityRelationship( v, 3, 10 )
			end
		end
	end
	
	for k, v in pairs( ents.FindByClass("npc_barnacle") ) do
		if( !table.HasValue( self.enemyTable_enemies_e, v ) ) then
			table.insert( self.enemyTable_enemies_e, v )
			v:AddEntityRelationship( self, 3, 10 )
			self:AddEntityRelationship( v, 3, 10 )
		end
	end
	
	if self.possessed and !self.melee_attacking and !self.range_attacking and ( !self.possession_allowdelay or ( self.possession_allowdelay and CurTime() > self.possession_allowdelay ) ) then
		self.possession_allowdelay = nil
		self:PossessMovement( 250 )
		if !self.master then return end
		if self.master:KeyDown( 1 ) then
			if !self.master:KeyDown( 4 ) then
				self:Attack_Range( true )
			elseif self.birth_recharged and self.bcrab_allow then
				self.birth_recharged = false
				timer.Create( "bcrab_recharge_timer" .. self.Entity:EntIndex( ), math.random( 11, 16 ), 1, function() self.birth_recharged = true end )
				if( table.Count( self.ChildTable ) < 7 ) then
					self:BCrab_Birth()
				end
			end
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
	self.range_attacking = true
	self.idle = 0
	self:StartSchedule( schdRangeAttack )
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
		if !poss and !tar:IsValid() then self.range_attacking = false; return end
		local FireTrace
		if !poss then
			FireTrace = ((self.enemy:GetPos() - Vector(0,0,180)) - self:GetPos())
		else
			FireTrace = self:GetForward() *400 -Vector(0,0,180)
		end
		local Firevector = FireTrace:GetNormalized()
		local FireLength = FireTrace:Length()
		local ArriveTime = FireLength / 2000
		local BaseShootVector = Firevector *200 + Vector(0,0,3000 *ArriveTime)
		
		for i=0, 5 do
			local spitball = ents.Create("gonarch_spit")
			spitball:SetPos( self:GetPos() + self:GetUp() * 190)
			spitball.owner = self.Entity
			spitball:SetOwner( self.Entity )
			spitball:Spawn()
			local phys = spitball:GetPhysicsObject()
			if phys:IsValid() then
				phys:SetVelocity( BaseShootVector + VectorRand() * 18)
			end
		end
		self.range_attacking = false
		if( self.range_attack_counter == self.attack_counter_max_r ) then
			self.attack_counter_reached_max = true
			timer.Create( "Gonarch_reset_counter_timer" .. self:EntIndex(), math.random(10,18), 1, function() self.range_attack_counter = 0; self.attack_counter_reached_max = false; self.attack_counter_max_r = math.random(2,4) end )
		else
			self.range_attack_counter = self.range_attack_counter +1
		end
	end
	if poss then self.possession_allowdelay = CurTime() +0.8 end
	timer.Create( "range_attack_timer" .. self.Entity:EntIndex( ), 0.5, 1, lAttak, self.enemy )
end

function ENT:Attack_Melee( poss )
	self.melee_attacking = true
	self.idle = 0
	self:StartSchedule( schdMeleeAttack )
	local function attack_dmg()
		local self_pos = self:GetPos()
		local victim = ents.FindInSphere( self_pos, self.MeleeDistance )

		for k, v in pairs(victim) do
			if( ( ( ( v:IsPlayer() and v:Alive() ) or v:IsNPC() ) and ( self:Disposition( v ) == 1 or self:Disposition( v ) == 2 ) ) or v:GetClass() == "prop_physics" ) then
				if( v:GetClass() != "prop_physics" ) then
					v:EmitSound( "npc/zombie/claw_strike" ..math.random(1,3).. ".wav", 100, 100)
				end
				if v:IsNPC() and v:Health() - sk_gonarch_slash_value <= 0 then
					self.killicon_ent = ents.Create( "sent_killicon" )
					self.killicon_ent:SetKeyValue( "classname", "sent_killicon_bigmomma" )
					self.killicon_ent:Spawn()
					self.killicon_ent:Activate()
					self.killicon_ent:Fire( "kill", "", 0.1 )
					self.attack_inflictor = self.killicon_ent
				else
					self.attack_inflictor = self
				end				
				v:TakeDamage( sk_gonarch_slash_value, self, self.attack_inflictor )  
				if v:IsPlayer() then
					v:ViewPunch( Angle( 5, 8, -20 ) ) 
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
		self.melee_attacking = false
	end
	timer.Create( "melee_attack_dmgdelay_timer" .. self.Entity:EntIndex( ), 0.68, 1, attack_dmg )
end

function ENT:BCrab_Birth()
	self.bcrab_spawning = true
	self.idle = 0
	self:StartSchedule( schdBirthBCrab )
	self:EmitSound( "npc/gonarch/gon_birth" ..math.random(1,3).. ".wav", 100, 100)
	
	local function bcrab_spawn( )
		gonarch_owner = self
		
		local bcrab_a = ents.Create( "monster_babycrab" )
		local self_pos_bcrab_a = self:GetPos()
		self_pos_bcrab_a.x = self_pos_bcrab_a.x + 25
		self_pos_bcrab_a.y = self_pos_bcrab_a.y + 12
		self_pos_bcrab_a.z = self_pos_bcrab_a.z + 12
		bcrab_a:SetPos( self_pos_bcrab_a )
		bcrab_a:SetAngles( self:GetAngles() )
		bcrab_a:Spawn()
		bcrab_a:Activate()
		constraint.NoCollide( self, bcrab_a, 0, 0 );  
		table.insert( self.ChildTable, bcrab_a )
		
		local bcrab_b = ents.Create( "monster_babycrab" )
		local self_pos_bcrab_b = self:GetPos()
		self_pos_bcrab_b.x = self_pos_bcrab_b.x - 12
		self_pos_bcrab_b.y = self_pos_bcrab_b.y + 14
		self_pos_bcrab_b.z = self_pos_bcrab_b.z + 12
		bcrab_b:SetPos( self_pos_bcrab_b )
		bcrab_b:SetAngles( self:GetAngles() )
		bcrab_b:Spawn()
		bcrab_b:Activate()
		constraint.NoCollide( self, bcrab_b, 0, 0 );  
		table.insert( self.ChildTable, bcrab_b )
			
		local bcrab_c = ents.Create( "monster_babycrab" )
		local self_pos_bcrab_c = self:GetPos()
		self_pos_bcrab_c.x = self_pos_bcrab_c.x - 12
		self_pos_bcrab_c.y = self_pos_bcrab_c.y - 6
		self_pos_bcrab_c.z = self_pos_bcrab_c.z + 12
		bcrab_c:SetPos( self_pos_bcrab_c )
		bcrab_c:SetAngles( self:GetAngles() )
		bcrab_c:Spawn()
		bcrab_c:Activate()
		constraint.NoCollide( self, bcrab_c, 0, 0 );  
		table.insert( self.ChildTable, bcrab_c )
		
		if( self.following ) then
			bcrab_a:Fire( self.cvar_ftarget, "", 0 )
			bcrab_b:Fire( self.cvar_ftarget, "", 0 )
			bcrab_c:Fire( self.cvar_ftarget, "", 0 )
		end
		gonarch_owner = nil
	end
	self.bcrab_spawning = false
	timer.Create( "bcrab_birth_timer" .. self.Entity:EntIndex( ), 0.8, 1, bcrab_spawn )
end



function ENT:TaskStart_wandering()
	self:TaskComplete()
end 

function ENT:Task_wandering()
	if( self.FoundEnemy ) then
		self:TaskComplete()
	end
end


function ENT:OnTakeDamage(dmg)
	self:SpawnBloodEffect( "yellow", dmg:GetDamagePosition() )
	if !self.inflictor then
		self.inflictor = dmg:GetInflictor()
	end
	if !self.attacker then
		self.attacker = dmg:GetAttacker()
	end
	if dmg:IsBulletDamage() then
		dmg:ScaleDamage( 0.1 )
		if( dmg:GetDamage() == self:Health() ) then
			dmg:SetDamage( 75 )
		end
	elseif( ValidEntity( self.attacker ) and self.attacker:IsNPC() and self.attacker:GetClass() == "npc_antlionguard" ) then
		dmg:ScaleDamage( 0.25 )
	end

	if( !dmg:IsDamageType( DMG_DISSOLVE ) ) then
		self:SetHealth(self:Health() - dmg:GetDamage())
	end
	if self.triggertarget and self.triggercondition == "2" then
		self:GotTriggerCondition()
	elseif self.starthealth and self:Health() <= (self.starthealth /2) then
		self:GotTriggerCondition()
	end
	local damage = dmg:GetDamage()
	
	if( self:Health() > 0 ) then
		if( damage <= 30 ) then
			self:SetCondition( 17 )
		else
			self:SetCondition( 18 )
		end
		
		if( ValidEntity( self.inflictor ) and self.inflictor:GetClass() == "prop_physics" ) then
			self:SetCondition( 19 )
		end
	
		self.damage_count = self.damage_count +1
		if( self.damage_count == 6 ) then
			self:SetCondition( 20 )
			self.mul_dmg = true
		end
		timer.Create( "damage_count_reset_timer" .. self.Entity:EntIndex( ), 1.5, 1, function() self.damage_count = 0 end )
	end
	
	if( self.damage_count == 6 or self:HasCondition( 18 ) and !self.range_attacking and !self.melee_attacking and self.pain == 1 ) then
		self:StartSchedule( schdHurt )
		self:EmitSound( "npc/gonarch/gon_pain" ..math.random(1,3).. ".wav", 500, 100)
	end
	
	if !self.enemy and self.enemy_memory and ( !self.WaterMonster or ( self.WaterMonster and self.attacker:WaterLevel() > 0 ) ) then
		local convar_ignoreply = GetConVarNumber("ai_ignoreplayers")
		if ValidEntity( self.attacker ) and !table.HasValue( self.enemy_memory, self.attacker ) and ( !self.attacker:IsPlayer() or ( self.attacker:IsPlayer() and convar_ignoreply != 1 and !self.ignoreplys ) ) and self:Disposition( self.attacker ) == 1 then table.insert( self.enemy_memory, self.attacker ) end
	end
	
	if ValidEntity(self.attacker) then
		self:UpdateEnemyMemory( self.attacker, self.attacker:GetPos() )
	end
	self.idle = 0

	if( self:Health() <= 0 and !self.dead ) then //run on death
		self.dead = true
		self:EndPossession()
		if self.triggertarget and self.triggercondition == "4" then self:GotTriggerCondition() end
		
		gamemode.Call( "OnNPCKilled", self, self.attacker, self.inflictor )
		self:EmitSound( "npc/gonarch/gon_die1.wav", 500, 100)
		
		if self.attacker:IsPlayer() then
			self.attacker:AddFrags( 1 )
		end
		
		local function death_hitworld()
			self:EmitSound( "npc/gonarch/gon_step" .. math.random(1,3) .. ".wav", 150, 90)
			util.ScreenShake( self:GetPos(), 85, 85, 0.4, 1300 )  
		end
		timer.Create( "gonarch_death_shake_timer" .. self:EntIndex(), 1.92, 1, death_hitworld )
		
		self:SetNPCState( NPC_STATE_DEAD )
		self:SetSchedule( SCHED_DIE_RAGDOLL )
		self:Fade()
	elseif( self:Health() > 0 ) then
		self.inflictor = nil
		self.attacker = nil
	end
end


/*---------------------------------------------------------
 Name: SelectSchedule
//-------------------------------------------------------*/
function ENT:SelectSchedule()
	if self.efficient then return end
	local convar_ai = GetConVarNumber("ai_disabled")
	
	if( convar_ai == 0 ) then
		for k, v in pairs(self.ChildTable) do
			if self.enemy and self.enemy:IsValid() and v:IsValid() then
				v:UpdateEnemyMemory( self.enemy, self.enemy:GetPos() )
			elseif self.enemy and self.enemy:IsValid() then
				table.remove(self.ChildTable,k)
				self.dead_child_counter = self.dead_child_counter +1
			end
							
			if( self.dead_child_counter == 4 ) then
				self:EmitSound( "npc/gonarch/gon_childdie" .. math.random(1,3) .. ".wav", 500, 100 )
				self.dead_child_counter = 0
			end
		end
	end
	
	if( ( self.FoundEnemy or self.FoundEnemy_fear ) and !self.range_attacking and !self.melee_attacking and !self.possessed and !self.bcrab_spawning and convar_ai == 0 ) then
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
		if( self.enemy and ValidEntity( self.enemy ) and self.enemy:GetPos():Distance( self:GetPos() ) <= self.closest_range and self.Attack_allow ) then
			if( self.enemy:GetPos():Distance( Pos ) < self.RangeDistance and self.enemy:GetPos():Distance( Pos ) > self.MeleeDistance and ( ( self.bcrab_allow and !self.birth_recharged ) or !self.bcrab_allow ) and !self.attack_counter_reached_max and self:HasCondition( 10 ) and !self:HasCondition( 42 ) ) then
				if( self.enemy:IsNPC() ) then
					self.SetEnemy( self.enemy )
				end
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				self:Attack_Range()
			elseif( self.birth_recharged and self:HasCondition( 10 ) and !self:HasCondition( 42 ) and self.bcrab_allow ) then
				self.birth_recharged = false
				timer.Create( "bcrab_recharge_timer" .. self.Entity:EntIndex( ), math.random( 11, 16 ), 1, function() self.birth_recharged = true end )
				if( table.Count( self.ChildTable ) < 7 ) then
					self:BCrab_Birth()
				end
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
			
			if( self:GetPos():Distance( self.follow_target ) > 175 and ( ( ValidEntity( self.enemy ) and self.enemy != self.follow_target and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) > 800 ) or !ValidEntity( self.enemy ) ) and !self.range_attacking and !self.melee_attacking and !self.bcrab_spawning and convar_ai == 0 ) then
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
	
	
	if( self.wander == 1 and !self.following and !self.possessed and !self.FoundEnemy and convar_ai == 0 and !self.range_attacking and !self.melee_attacking and !self.bcrab_spawning ) then
		if( !self.timer_created ) then
			self.timer_created = true
			timer.Create( "wandering_timer" .. self.Entity:EntIndex( ), math.random(10,14), 1, wandering_schd )
		end
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
	
	if( key == "bcrabs" ) then
		self.bcrab_allow = value
	end
end

function ENT:AcceptInput( cvar_name, activator, caller )
	if cvar_name == "setsquad" then
		timer.Simple( 0.01, function() self.squad = self:GetKeyValue( self, "squadname" ); self:SetupSquad() end )
		self.squadtable = {}
	end
	local function set_bcrab_rel()
		local npcs = ents.FindByClass( "npc_*" ) 
		table.Add( npcs, ents.FindByClass( "monster_*" ) )
		table.Add( npcs, player.GetAll() )
		for k, v in pairs( npcs ) do
			local enemy = v
			local enemy_disp = self:Disposition( v )
			if( table.Count( self.ChildTable ) > 0 ) then
				for k, v in pairs( self.ChildTable ) do
					if ValidEntity( v ) then
						v:AddEntityRelationship( enemy, enemy_disp, 10 )
					end
				end
			end
		end
	end

	if( string.find( cvar_name,"followtarget_" ) and ( ( caller:IsPlayer() and caller:IsAdmin() ) or !caller:IsPlayer() ) and !self.following ) then
		self.cvar_ftarget = cvar_name
		if( table.Count( self.ChildTable ) > 0 ) then
			for k, v in pairs( self.ChildTable ) do
				v:Fire( cvar_name, "", 0 )
			end
		end
		
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
				set_bcrab_rel()
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
		
		if( table.Count( self.ChildTable ) > 0 ) then
			for k, v in pairs( self.ChildTable ) do
				v:Fire( "stopfollowtarget", "", 0 )
			end
		end
		
		if self.following_disp then
			self:AddEntityRelationship( self.follow_target, self.following_disp, 10 )
			timer.Create( "bcrab_rel_timer2_b" .. self:EntIndex(), 0.1, 1, set_bcrab_rel )
		end
		timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
		self:StartSchedule( schdReset )
		self.follow_target = NULL
	end

	if( cvar_name == "setrelationship" ) then
		timer.Create( "bcrab_rel_timer" .. self:EntIndex(), 0.1, 1, set_bcrab_rel )
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
	end
	self:EndPossession()
	timer.Destroy( "self.enemy_occluded_timer" .. self:EntIndex() )
	timer.Destroy( "self.alert_allow_timer" .. self:EntIndex() )
	timer.Destroy( "bcrab_rel_timer2_b" .. self:EntIndex() )
	timer.Destroy( "bcrab_rel_timer" .. self:EntIndex() )
	timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
	timer.Destroy( "gonarch_death_shake_timer" .. self:EntIndex() )
	timer.Destroy( "Gonarch_reset_counter_timer" .. self:EntIndex() )
	timer.Destroy( "alpha_timer" .. self:EntIndex() )
	timer.Destroy( "damage_count_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "entity_index_remove_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "range_attack_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "melee_attack_dmgdelay_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "wandering_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "timer_created_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "self.ghide_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "Alert_reset_timer" .. self:EntIndex() )
	timer.Destroy( "bcrab_birth_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "bcrab_recharge_timer" .. self.Entity:EntIndex( ) )

end