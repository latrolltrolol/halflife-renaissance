AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/bullsquid.mdl"
ENT.RangeDistance		= 1250 // def: 1250
ENT.MeleeDistance		= 85

ENT.SpawnRagdollOnDeath = true
ENT.FadeOnDeath = false
ENT.BloodType = "green"
ENT.Pain = true
ENT.PainSound = "npc/bullsquid/pain"
ENT.PainSoundCount = 2
ENT.DeathSound = "npc/bullsquid/die"
ENT.DeathSoundCount = 3
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

local schdMeleeAttack_b = ai_schedule.New( "Attack Enemy melee b" ) 
schdMeleeAttack_b:EngTask( "TASK_STOP_MOVING", 0 )
schdMeleeAttack_b:EngTask( "TASK_STOP_MOVING", 0 )
schdMeleeAttack_b:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_MELEE_ATTACK2 )

local schdSurprised = ai_schedule.New( "Surprised" ) 
schdSurprised:EngTask( "TASK_STOP_MOVING", 0 )
schdSurprised:EngTask( "TASK_STOP_MOVING", 0 )
schdSurprised:AddTask( "PlaySequence", { Name = "suprisedhop", Speed = 1 } )

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
	self:SetHullType( HULL_WIDE_SHORT );
	self:SetHullSizeNormal();

	self:SetSolid( SOLID_BBOX )
	self:SetMoveType( MOVETYPE_STEP )

	self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_MOVE_JUMP | CAP_OPEN_DOORS | CAP_INNATE_RANGE_ATTACK1 | CAP_FRIENDLY_DMG_IMMUNE | CAP_SQUAD )

	self:SetMaxYawSpeed( 5000 )

	if !self.health then
		self:SetHealth(sk_bullsquid_health_value)
	end
	
	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end

	self.attacksound1 = CreateSound( self, "npc/bullsquid/attack1.wav" )
	self.attacksound2 = CreateSound( self, "npc/bullsquid/attack2.wav" )
	self.attacksound3 = CreateSound( self, "npc/bullsquid/attack3.wav" )
	
	self.attack_melee_sound1 = CreateSound( self, "npc/bullsquid/attackgrowl1.wav" )
	self.attack_melee_sound2 = CreateSound( self, "npc/bullsquid/attackgrowl2.wav" )
	self.attack_melee_sound3 = CreateSound( self, "npc/bullsquid/attackgrowl3.wav" )
	
	self.attack_bite_sound1 = CreateSound( self, "npc/bullsquid/bite1.wav" )
	self.attack_bite_sound2 = CreateSound( self, "npc/bullsquid/bite2.wav" )
	self.attack_bite_sound3 = CreateSound( self, "npc/bullsquid/bite3.wav" )
	
	self.idlesound1 = CreateSound( self, "npc/bullsquid/idle1.wav" )
	self.idlesound2 = CreateSound( self, "npc/bullsquid/idle2.wav" )
	self.idlesound3 = CreateSound( self, "npc/bullsquid/idle3.wav" )
	self.idlesound4 = CreateSound( self, "npc/bullsquid/idle4.wav" )
	self.idlesound5 = CreateSound( self, "npc/bullsquid/idle5.wav" )
	
	self:SetUpEnemies( )
	self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }

	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
	self.allow_range_attack = true
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
		self:PossessMovement( 128 )
		if !self.master then return end
		if self.master:KeyDown( 1 ) then
			self:Attack_Range( true )
		elseif self.master:KeyDown( 2048 ) then
			if !self.master:KeyDown( 4 ) then
				self:Attack_Melee(true)
			else
				self:Attack_Melee_b(true)
			end
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
	self.attacking = true
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
		if !poss and !tar:IsValid() then self.attacking = false; return end
		local FireTrace
		if poss then
			FireTrace = self:GetForward() *500 +Vector(0,0,12)
		else
			FireTrace = ((self.enemy:GetPos() + Vector(0,0,10)) - self:GetPos())
		end
		local Firevector = FireTrace:GetNormalized()
		local FireLength = FireTrace:Length()
		local ArriveTime = FireLength / 2000
		local BaseShootVector = Firevector * 2000 + Vector(0,0,300 * ArriveTime)
		//if !poss then
		//bullsquid_disposition = self:Disposition( self.enemy )
		//end
	
		for i=0, 5 do
			local spitball = ents.Create("bullsquid_spit")
			spitball:SetPos( self:GetPos() + self:GetForward() * 20 + self:GetUp() * 20)
			spitball.owner = self.Entity
			spitball:SetOwner( self.Entity )
			spitball:Spawn()
			local phys = spitball:GetPhysicsObject()
			if phys:IsValid() then
				phys:SetVelocity( BaseShootVector + VectorRand() * 60)
			end
		end
		self.attacking = false
		if poss then self.possession_allowdelay = CurTime() +1.4 end
	end
	timer.Create( "range_attack_end_timer" .. self.Entity:EntIndex( ), 0.5, 1, lAttak, self.enemy )
end

function ENT:Attack_Melee( poss )
	self.attacking = true
	self.idle = 0
	self:StartSchedule( schdMeleeAttack )

	self.attack_melee_sound1:Stop()
	self.attack_melee_sound2:Stop()
	self.attack_melee_sound3:Stop()
	
	local attacksound_rand = math.random(1,3)
	if (attacksound_rand == 1) then
		self.attack_melee_sound1:Play()
	end
	
	if (attacksound_rand == 2) then
		self.attack_melee_sound2:Play()
	end
	
	if (attacksound_rand == 3) then
		self.attack_melee_sound3:Play()
	end
	
	local function attack_dmg()
		local self_pos = self:GetPos()
		local victim = ents.FindInSphere( self_pos, self.MeleeDistance )

		for k, v in pairs(victim) do
			if( ( ( ( v:IsPlayer() and v:Alive() ) or v:IsNPC() ) and ( self:Disposition( v ) == 1 or self:Disposition( v ) == 2 ) ) or v:GetClass() == "prop_physics" ) then
				if( v:GetClass() != "prop_physics" ) then
					v:EmitSound( "npc/zombie/claw_strike" ..math.random(1,3).. ".wav", 100, 100)
				end
				if v:IsNPC() and v:Health() - sk_bullsquid_slash_value <= 0 then
					self.killicon_ent = ents.Create( "sent_killicon" )
					self.killicon_ent:SetKeyValue( "classname", "sent_killicon_bullchicken" )
					self.killicon_ent:Spawn()
					self.killicon_ent:Activate()
					self.killicon_ent:Fire( "kill", "", 0.1 )
					self.attack_inflictor = self.killicon_ent
				else
					self.attack_inflictor = self
				end
				v:TakeDamage( sk_bullsquid_slash_value, self, self.attack_inflictor )
				self.attack_inflictor = nil
				if v:IsPlayer() then
					v:ViewPunch( Angle( -5, -15, 0 ) ) 
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
		self.attacking = false
		if poss then self.possession_allowdelay = CurTime() +0.4 end
		timer.Create( "atk_r_select_sched" .. self:EntIndex(), 0.4, 1, function() self:SelectSchedule() end )
	end
	timer.Create( "melee_attack_dmgdelay_timer" .. self.Entity:EntIndex( ), 1, 1, attack_dmg )
end

function ENT:Attack_Melee_b( poss )
	self.attacking = true
	self.idle = 0
	self:StartSchedule( schdMeleeAttack_b )

	self.attack_bite_sound1:Stop()
	self.attack_bite_sound2:Stop()
	self.attack_bite_sound3:Stop()
	
	local attacksound_rand = math.random(1,3)
	if (attacksound_rand == 1) then
		self.attack_bite_sound1:Play()
	end
	
	if (attacksound_rand == 2) then
		self.attack_bite_sound2:Play()
	end
	
	if (attacksound_rand == 3) then
		self.attack_bite_sound3:Play()
	end
	
	local function attack_bite_dmg()
		local self_pos = self:GetPos()
		local victim = ents.FindInBox( self:LocalToWorld( Vector( 28, 33, 4 ) ), self:LocalToWorld( Vector( 77, -30, 35 ) ) )

		for k, v in pairs(victim) do
			if( ( ( ( v:IsPlayer() and v:Alive() ) or v:IsNPC() ) and ( self:Disposition( v ) == 1 or self:Disposition( v ) == 2 ) ) or v:GetClass() == "prop_physics" ) then
				if v:IsNPC() and v:Health() - sk_bullsquid_bite_value <= 0 then
					self.killicon_ent = ents.Create( "sent_killicon" )
					self.killicon_ent:SetKeyValue( "classname", "sent_killicon_bullchicken" )
					self.killicon_ent:Spawn()
					self.killicon_ent:Activate()
					self.killicon_ent:Fire( "kill", "", 0.1 )
					self.attack_inflictor = self.killicon_ent
				else
					self.attack_inflictor = self
				end
				v:SetVelocity( (self:GetForward() *100) +Vector( 0, 0, 300 ) )
				v:TakeDamage( sk_bullsquid_bite_value, self, self.attack_inflictor )
				self.attack_inflictor = nil
				if v:IsPlayer() then
					v:ViewPunch( Angle( 0, 0, 15 ) ) 
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
			end
		end
		timer.Destroy( "range_attack_reset_timer" .. self:EntIndex() )
		self.allow_range_attack = true
		self.attacking = false
		if poss then self.possession_allowdelay = CurTime() +0.4 end
	end
	timer.Create( "melee_attack_dmgdelay_timer" .. self.Entity:EntIndex( ), 0.28, 1, attack_bite_dmg )
end


function ENT:TaskStart_wandering()
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
			self:FindInCone( 1, 9999 ) -- cone, SearchDist; cone: decrease this to decrease the angle within which it'll search; 1 = 90 degrees, 0.7 = 45-ish degrees, etc.
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
		if( self.enemy and ValidEntity(self.enemy) and self.enemy:GetPos():Distance( Pos ) <= self.closest_range ) then
			if( self.enemy:GetPos():Distance( Pos ) < self.RangeDistance and self.enemy:GetPos():Distance( Pos ) > self.MeleeDistance and self:HasCondition( 10 ) and !self:HasCondition( 42 ) and self.allow_range_attack ) then
				if( self.enemy:IsNPC() ) then
					self.SetEnemy( self.enemy )
				end
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				self:Attack_Range()
				if !self.range_attack_max_count then
					self.range_attack_max_count = math.random(2,3)
				else
					self.range_attack_max_count = self.range_attack_max_count -1
				end
				
				if self.range_attack_max_count == 0 then
					self.allow_range_attack = false
					self.range_attack_max_count = nil
					timer.Create( "range_attack_reset_timer" .. self:EntIndex(), math.random(6,9), 1, function() self.allow_range_attack = true end )
				end
			elseif( self.enemy:GetPos():Distance( Pos ) < self.MeleeDistance and self:HasCondition( 10 ) and !self:HasCondition( 42 ) ) then
				if( self.enemy:IsNPC() ) then
					self.SetEnemy( self.enemy )
				end
				self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				local rand = math.random(1,2)
				if rand == 1 then
					self:Attack_Melee_b()
				else
					self:Attack_Melee()
				end
			elseif( self:HasCondition( 42 ) ) then
				self:UpdateEnemyMemory( self.enemy, self.enemy:GetPos() )
				self:StartSchedule( schdDodge )
			elseif( ( self.following and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) < 800 ) or !self.following ) then
				timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
				self:SetEnemy( self.enemy, true )
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				self:StartSchedule( schdChase )
			end
		elseif( ( !self.enemy or !ValidEntity(self.enemy) ) and self.enemy_fear and ValidEntity(self.enemy_fear) and self:HasCondition( 8 ) and !self:HasCondition( 7 ) and !self.possessed ) then
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
		self.attacksound2:Stop()
		self.attacksound3:Stop()
		
		self.attack_bite_sound1:Stop()
		self.attack_bite_sound2:Stop()
		self.attack_bite_sound3:Stop()
		
		self.attack_melee_sound1:Stop()
		self.attack_melee_sound2:Stop()
		self.attack_melee_sound3:Stop()
			
		self.idlesound1:Stop()
		self.idlesound2:Stop()
		self.idlesound3:Stop()
		self.idlesound4:Stop()
		self.idlesound5:Stop()
	end
	self:EndPossession()
	timer.Destroy( "self.enemy_occluded_timer" .. self:EntIndex() )
	timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
	timer.Destroy( "damage_count_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "entity_index_remove_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "range_attack_end_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "melee_attack_end_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "range_attack_dmgdelay_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "melee_attack_dmgdelay_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "wandering_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "timer_created_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "self.ghide_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "range_attack_reset_timer" .. self:EntIndex() )
	timer.Destroy( "atk_r_select_sched" .. self:EntIndex() )
end