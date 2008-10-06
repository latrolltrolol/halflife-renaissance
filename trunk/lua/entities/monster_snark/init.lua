AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/w_squeak.mdl"
ENT.MinDistance		= 235
ENT.CheckWorld = true

ENT.pitch = 95

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
schdAttack:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK2 )

local schdHide = ai_schedule.New( "Hide" ) 
schdHide:EngTask( "TASK_FIND_COVER_FROM_ENEMY", 0 ) 

/*local schdWandering = ai_schedule.New( "Wander" ) 
schdWandering:AddTask( "wandering" )
schdWandering:EngTask( "TASK_GET_PATH_TO_RANDOM_NODE", 124 )
schdWandering:EngTask( "TASK_WALK_PATH", 0 ) */

local schdReset = ai_schedule.New( "Reset" ) 
schdReset:EngTask( "TASK_RESET_ACTIVITY", 0 ) 

function ENT:Initialize()
	if( turret_index_table == nil ) then
		turret_index_table = {}
	end
	self.table_fear = {}

	self:SetModel( self.Model )

	self:SetHullType( HULL_TINY );
	self:SetHullSizeNormal();

	self:SetSolid( SOLID_BBOX )
	self:SetMoveType( MOVETYPE_STEP )

	self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_MOVE_JUMP | CAP_OPEN_DOORS | CAP_INNATE_RANGE_ATTACK1 | CAP_FRIENDLY_DMG_IMMUNE | CAP_SQUAD )

	self:SetMaxYawSpeed( 5000 )
	
	if !self.health then
		self:SetHealth(sk_snark_health_value)
	end
	
	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end
	
	if !self.blastdmg then
		self.blastdmg = sk_snark_blast_value
	end

	self:SetUpEnemies( )
	self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }
	
	self:SetSchedule( 1 )
	
	self.enemyTable_enemies_e = {}
	
	if snarkgun_owner then
		self.owner = snarkgun_owner
	end
	if !self.dontdestruct then
		if !self.blasttime then
			timer.Create( "self_explode_timer" .. self:EntIndex(), sk_snark_delay_value, 1, function() self:TakeDamage( self:Health(), self ) end )
		else
			timer.Create( "self_explode_timer" .. self:EntIndex(), self.blasttime, 1, function() self:TakeDamage( self:Health(), self ) end )
		end
	end
end
function ENT:OnCondition( iCondition )
	if self.efficient then return end
	//Msg( self, " Condition: ", iCondition, " - ", self:ConditionName(iCondition), "\n" )
	if !self.val_cur then self.val_cur = CurTime() +0.2 end
	if self.val_cur < CurTime() then
		self:ValidateMemory()
		self.val_cur = nil
	end
	if( ( ( !self:HasCondition( 8 ) and self:HasCondition( 7 ) ) or ( self:HasCondition( 8 ) and self:HasCondition( 7 ) ) ) or ( self.enemy_memory and table.Count( self.enemy_memory ) > 0 ) ) then
		self.FoundEnemy = true
		self.FoundEnemy_fear = false
		timer.Destroy( "wandering_timer" .. self.Entity:EntIndex( ) )
		self.timer_created = false
	elseif( self:HasCondition( 8 ) and !self:HasCondition( 13 ) ) then
		self.FoundEnemy_fear = true
		timer.Destroy( "wandering_timer" .. self.Entity:EntIndex( ) )
		timer.Destroy( "snark_hunt_timer" .. self:EntIndex() )
		self.timer_created = false
	elseif( self.FoundEnemy_fear and self:HasCondition( 13 ) ) then
		self.FoundEnemy_fear = false
	elseif( ( !self.enemy_memory or table.Count( self.enemy_memory ) == 0 ) and ( self:HasCondition( 13 ) and self:HasCondition( 31 ) ) or ( !self:HasCondition( 8 ) and !self:HasCondition( 7 ) and !self.enemy_occluded ) ) then
		self.FoundEnemy = false
	end
	
	/*if( self:HasCondition( 13 ) or self:HasCondition( 31 ) ) then
		timer.Destroy( "snark_hunt_timer" .. self:EntIndex() )
	end*/
	
	if( self:HasCondition( 13 ) ) then
		self.enemy_occluded = true
		timer.Destroy( "self.enemy_occluded_timer" .. self:EntIndex() )
	elseif( !timer.IsTimer( "self.enemy_occluded_timer" .. self:EntIndex() ) ) then
		timer.Create( "self.enemy_occluded_timer" .. self:EntIndex(), 1.5, 1, function() self.enemy_occluded = false end )
	end
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
end

function ENT:Attack()
	if( self.pitch < 135 ) then
		self.pitch = self.pitch +math.random(5,10)
	end
	self:EmitSound( "npc/squeek/sqk_deploy1.wav", 100, self.pitch )
	if( self.enemy:GetPos():Distance( self:GetPos() ) < 70 ) then
		self.attack_angle = self.enemy:GetPos() + Vector( 0, 0, 25 ) - self:GetPos();
	else
		self.attack_angle = self.enemy:GetPos() + Vector( 0, 0, 70 ) - self:GetPos();
	end
	
	self:SetLocalVelocity(self.attack_angle:Normalize()*500);

	local enemy_table = {}
	local function attack_dmg()
		local self_pos = self:GetPos()
		
		local victim = ents.FindInSphere( self_pos, 35 )
		for k, v in pairs(victim) do
			if( !table.HasValue( enemy_table, v ) ) then
				if( ( ( ( v:IsPlayer() and v:Alive() ) or v:IsNPC() ) and ( self:Disposition( v ) == 1 or self:Disposition( v ) == 2 ) ) or v:GetClass() == "prop_physics" ) then
					table.insert( enemy_table, v )
					if v:IsNPC() and v:Health() - sk_snark_melee_value <= 0 then
						self.killicon_ent = ents.Create( "sent_killicon" )
						self.killicon_ent:SetKeyValue( "classname", "sent_killicon_snark" )
						self.killicon_ent:Spawn()
						self.killicon_ent:Activate()
						self.killicon_ent:Fire( "kill", "", 0.1 )
						self.attack_inflictor = self.killicon_ent
					else
						self.attack_inflictor = self
					end
					if self.owner and self.owner:IsPlayer() then
						if( v:Health() > 0 and v:Health() - sk_snark_melee_value <= 0 ) then
							self.owner:AddFrags( 1 )
						end
						v:TakeDamage( sk_snark_melee_value, self.owner, self.attack_inflictor )  
					else
						v:TakeDamage( sk_snark_melee_value, self, self.attack_inflictor )  
					end
					
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
		end
		
		local function attack_end()
			timer.Destroy( "attack_dmgdelay_timer" .. self.Entity:EntIndex( ) )
			self:StartSchedule( schdWait )
			self.timer_allow = 1
			self.attacking = false
		end
		timer.Create( "attack_end_timer" .. self.Entity:EntIndex( ), 0.6, 1, attack_end )
	end
	timer.Create( "attack_dmgdelay_timer" .. self.Entity:EntIndex( ), 0.01, 0, attack_dmg )
	timer.Create( "attack_dmgdelay_deltimer" .. self.Entity:EntIndex( ), 0.8, 1, function() timer.Destroy( "attack_dmgdelay_timer" .. self.Entity:EntIndex( ) ) end )
end


function ENT:TaskStart_wandering()
end 

function ENT:Task_wandering()
	if( self.FoundEnemy ) then
		self:TaskComplete()
	end
end


function ENT:OnTakeDamage(dmg)
	self:SetHealth(self:Health() - dmg:GetDamage())
	if self.triggertarget and self.triggercondition == "2" then
		self:GotTriggerCondition()
	elseif self.starthealth and self:Health() <= (self.starthealth /2) then
		self:GotTriggerCondition()
	end
	local damage = dmg:GetDamage()
	if !self.inflictor then
		self.inflictor = dmg:GetInflictor()
	end
	if !self.attacker then
		self.attacker = dmg:GetAttacker()
	end
	local damage_force = dmg:GetDamageForce()
	
	if !self.enemy and self.enemy_memory and ( !self.WaterMonster or ( self.WaterMonster and self.attacker:WaterLevel() > 0 ) ) then
		local convar_ignoreply = GetConVarNumber("ai_ignoreplayers")
		if !table.HasValue( self.enemy_memory, self.attacker ) and ( !self.attacker:IsPlayer() or ( self.attacker:IsPlayer() and convar_ignoreply != 1 and !self.ignoreplys ) ) and self:Disposition( self.attacker ) == 1 then table.insert( self.enemy_memory, self.attacker ) end
	end
	if ValidEntity(self.attacker) then
		self:UpdateEnemyMemory( self.attacker, self.attacker:GetPos() )
	end
	self.idle = 0

	if ( self:Health() <= 0 and !self.dead ) then
		self.dead = true
		if self.triggertarget and self.triggercondition == "4" then self:GotTriggerCondition() end
		local cvar_keepragdolls = GetConVarNumber("ai_keepragdolls")
		gamemode.Call( "OnNPCKilled", self, self.attacker, self.inflictor )
		if self.attacker:IsPlayer() and self.attacker != self.owner then
			self.attacker:AddFrags( 1 )
		end
		
		if( self.attacker:GetClass() != "npc_barnacle" and !dmg:IsDamageType( DMG_DISSOLVE ) ) then
			self:SetNPCState( NPC_STATE_DEAD )
			self:EmitSound( "npc/squeek/sqk_die1.wav", 100, 100 )
			self:SetLocalVelocity( self:GetPos():Normalize() + Vector(0,0,190) )//*5 )
			local function snark_explode()
				self:EmitSound( "npc/squeek/sqk_blast1.wav", 100, 100 )
				local effectdata = EffectData()
				effectdata:SetStart( self:GetPos() ) 
				effectdata:SetOrigin( self:GetPos() )
				effectdata:SetScale( 1 )
				util.Effect( "StriderBlood", effectdata )
				local dmg_ents = ents.FindInSphere( self:GetPos(), 62 )
				for k, v in pairs( dmg_ents ) do
					if( ( ( ( v:IsPlayer() and v:Alive() ) or v:IsNPC() ) and ( self:Disposition( v ) == 1 or self:Disposition( v ) == 2 ) ) or v:GetClass() == "prop_physics" ) then
						if v:IsNPC() and v:Health() - self.blastdmg <= 0 then
							self.killicon_ent = ents.Create( "sent_killicon" )
							self.killicon_ent:SetKeyValue( "classname", "sent_killicon_snark" )
							self.killicon_ent:Spawn()
							self.killicon_ent:Activate()
							self.killicon_ent:Fire( "kill", "", 0.1 )
							self.attack_inflictor = self.killicon_ent
						else
							self.attack_inflictor = self
						end
						if self.owner and self.owner:IsPlayer() then
							if( v:Health() > 0 and v:Health() - sk_snark_blast_value <= 0 ) then
								self.owner:AddFrags( 1 )
							end
							v:TakeDamage( self.blastdmg, self.owner, self.attack_inflictor )  
						else
							v:TakeDamage( self.blastdmg, self, self.attack_inflictor )  
						end
					end
				end
				self:Remove()
			end
			timer.Create( "explode_timer" .. self:EntIndex(), 0.5, 1, snark_explode )
			//self:SetNPCState( NPC_STATE_DEAD )
			//self:Remove()
		elseif( dmg:IsDamageType( DMG_DISSOLVE ) ) then
			self:SetNPCState( NPC_STATE_DEAD )
			self:SetSchedule( SCHED_DIE_RAGDOLL )
		end
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
				self:StartSchedule( schdAttack )
				self:Attack()
			elseif( ( self.following and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) < 800 ) or !self.following ) then
				self:SetEnemy( self.enemy, true )
				if self.schedule_runtarget_pos then self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos ) end
				self:StartSchedule( schdChase )
				if( self:GetPos():Distance( self.enemy:GetPos() ) < 1600 ) then
				
					local function snark_hunt()
						self.hunt_timer_created = false
						self:EmitSound( "npc/squeek/sqk_hunt" .. math.random(1,3) .. ".wav", 100, 100 )
						if self:IsOnGround( ) and self.enemy and ValidEntity( self.enemy ) then
							local trd = {}
							trd.start = self:GetPos()
							trd.endpos = self:GetCenter( self.enemy )
							trd.filter = {self}
							local tr = util.TraceLine(trd)
							if tr.Entity and ValidEntity( tr.Entity ) and tr.Entity == self.enemy then
								local jump_angle = self.enemy:GetPos() + Vector( 0, 0, 100 ) - self:GetPos()
								self:SetLocalVelocity( jump_angle:Normalize()*500 );
							end
						end
					end

					if( !self.hunt_timer_created ) then
						self.hunt_timer_created = true
						timer.Create( "snark_hunt_timer" .. self:EntIndex(), math.random(0.1,0.3), 1, snark_hunt )
					end
				end
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
	
	if( self.following ) then
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

	
	if( !self.following and !self.FoundEnemy and convar_ai == 0 and !self.attacking ) then
		if( !self.timer_created ) then
			self.timer_created = true
			//wandering_schd()
			self:SetSchedule( SCHED_IDLE_WANDER )
			timer.Create( "wandering_timer" .. self.Entity:EntIndex( ), math.random(4,5), 0, function() self:SetSchedule( SCHED_IDLE_WANDER ) end ) //wandering_schd )
		end
	end	
end 

function ENT:KeyValue( key, value )	
	if( key == "squadname" or key == "netname" ) then
		self.squad = value
		self:SetupSquad()
	end
	if( key == "health" ) then
		self.health = value
	end
	
	if( key == "blast" ) then
		self.blastdmg = value
	end
	
	if( key == "blasttime" ) then
		self.blasttime = value
	end
	
	if( key == "spawnflags" and value >= "32768" ) then
		self.dontdestruct = true
	end
end

/*---------------------------------------------------------
Name: OnRemove
Desc: Called just before entity is deleted
//-------------------------------------------------------*/
function ENT:OnRemove()
	timer.Destroy( "snark_hunt_timer" .. self:EntIndex() )
	timer.Destroy( "explode_timer" .. self:EntIndex() )
	timer.Destroy( "self_explode_timer" .. self:EntIndex() )
	timer.Destroy( "self.enemy_occluded_timer" .. self:EntIndex() )
	timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
	timer.Destroy( "entity_index_remove_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "attack_end_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "attack_dmgdelay_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "attack_dmgdelay_deltimer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "wandering_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "timer_created_timer" .. self.Entity:EntIndex( ) )
end