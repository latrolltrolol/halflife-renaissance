AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/scientist.mdl"

local schdFollow = ai_schedule.New( "Follow friend" )
schdFollow:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdFollow:EngTask( "TASK_RUN_PATH_WITHIN_DIST", 125 ) 

local schdFollowply = ai_schedule.New( "Follow player" )
schdFollowply:EngTask( "TASK_TARGET_PLAYER", 0 )
schdFollowply:EngTask( "TASK_GET_PATH_TO_TARGET", 0 )
schdFollowply:EngTask( "TASK_MOVE_TO_TARGET_RANGE", 125 ) 

local schdHealPull = ai_schedule.New( "Pull needle" )
schdHealPull:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_ARM ) 

local schdHeal = ai_schedule.New( "Heal" )
schdHeal:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_MELEE_ATTACK1 ) 

local schdHealReturn = ai_schedule.New( "Return needle" )
schdHealReturn:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_DISARM ) 

local schdStop = ai_schedule.New( "Stop" )
schdStop:EngTask( "TASK_STOP_MOVING", 0 ) 

local schdHide = ai_schedule.New( "Hide" ) 
schdHide:EngTask( "TASK_FIND_COVER_FROM_ENEMY", 0 ) 
schdHide:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 )
schdHide:AddTask( "PlaySequence", { Name = "crouch", Speed = 0.6 } )
schdHide:AddTask( "CroucHide" )

local schdCrouch = ai_schedule.New( "Crouch" ) 
schdCrouch:EngTask( "TASK_PLAY_SEQUENCE", ACT_CROUCHIDLE ) 
schdCrouch:AddTask( "CroucHide" )

local schdStand = ai_schedule.New( "Crouch" ) 
schdStand:EngTask( "TASK_PLAY_SEQUENCE", ACT_STAND ) 

local schdHurt = ai_schedule.New( "Hurt" ) 
schdHurt:EngTask( "TASK_SMALL_FLINCH", 0 ) 

local schdReset = ai_schedule.New( "Reset" ) 
schdReset:EngTask( "TASK_RESET_ACTIVITY", 0 ) 

local schdBackaway = ai_schedule.New( "Back away" ) 
schdBackaway:EngTask( "TASK_FIND_BACKAWAY_FROM_SAVEPOSITION", 0 ) 

local schdResetSchedule = ai_schedule.New( "ResetSchedule" ) 
schdResetSchedule:EngTask( "TASK_SET_SCHEDULE", 59 ) 

function ENT:TaskStart_CroucHide()
	self:TaskComplete()
	self.enemy_fear = NULL
	self:FindInCone( 1, 256 )
	if self.StopCrouching then self.StopCrouching = false; timer.Destroy( "sc_stand_timer" .. self:EntIndex() ); self:StartSchedule( schdStand ) return end
	if ( self.enemy_fear and ValidEntity( self.enemy_fear ) ) or ( self.follow_target and ValidEntity( self.follow_target ) ) then timer.Destroy( "sc_stand_timer" .. self:EntIndex() ); self:StartSchedule( schdStand ); self:StartSchedule( schdHide ) return end
	if !timer.IsTimer( "sc_stand_timer" .. self:EntIndex() ) then
		timer.Create( "sc_stand_timer" .. self:EntIndex(), 12, 1, function() self.StopCrouching = true end )
	end
	self:StartSchedule( schdCrouch )
end 

function ENT:Task_CroucHide()
	self:TaskComplete()
end

function ENT:Initialize()
	self.table_fear = {}
	self.f_headcrab_table = {}

	self:SetModel( self.Model )

	self:SetHullType( HULL_HUMAN );
	self:SetHullSizeNormal();

	self:SetSolid( SOLID_BBOX )
	self:SetMoveType( MOVETYPE_STEP )

	self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_ANIMATEDFACE | CAP_USE | CAP_OPEN_DOORS | CAP_FRIENDLY_DMG_IMMUNE | CAP_SQUAD )
	self:SetMaxYawSpeed( 5000 )

	if !self.health then
		self:SetHealth(sk_scientist_health_value)
	end
	
	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end
	
	if self.bodykey_v == "-1" or !self.bodykey_v then
		local rand = math.random(0,3)
		self.bodykey_value = rand
		self:SetKeyValue( "body", rand )
	else
		self.bodykey_value = self.bodykey_v
	end
	
	if tonumber(self.bodykey_value) == 2 then
		self:SetSkin( 1 )
	end

	self.enemyTable_fear = { "npc_antlion", "npc_antlion_worker", "npc_combine_s", "npc_hunter", "npc_rollermine", "npc_turret_floor", "npc_metropolice", "npc_antlionguard", "npc_fastzombie_torso", "npc_fastzombie", "npc_headcrab", "npc_headcrab_black", "npc_headcrab_poison", "npc_headcrab_fast", "npc_poisonzombie", "npc_zombie", "npc_zombie_torso", "npc_zombine", "npc_stalker", "npc_clawscanner", "npc_cscanner", "npc_manhack", "monster_generic", "monster_alien_controller", "monster_alien_grunt", "monster_babycrab", "monster_bigmomma", "monster_bullchicken", "monster_gargantua", "monster_headcrab", "monster_houndeye", "monster_panthereye", "monster_snark", "monster_tentacle", "monster_zombie", "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }
	
	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
end
function ENT:OnCondition( iCondition )
	if self.efficient then return end
	//Msg( self, " Condition: ", iCondition, " - ", self:ConditionName(iCondition), "\n" )
	if !self.val_cur then self.val_cur = CurTime() +0.2 end
	if self.val_cur < CurTime() then
		self:ValidateMemory()
		self.val_cur = nil
	end
	if( self:HasCondition( 8 ) and !self:HasCondition( 13 ) ) then
		self.FoundEnemy_fear = true
	elseif( self.FoundEnemy_fear and self:HasCondition( 13 ) ) then
		self.FoundEnemy_fear = false
	end
	
	if( self:HasCondition( 35 ) and self.following and self.pressed ) then
		if self.follow_target and ValidEntity( self.follow_target ) and self.follow_target:IsPlayer() then
			self:SpeakSentence( "!SC_STOP" .. math.random(0,3), self, self.follow_target, 10, 10, 1, true, true, false, true )
		end
		self:Fire( "stopfollowtarget", "", 0 )
		timer.Create( "self_pressed_reset_timer" .. self:EntIndex(), 1, 1, function() self.pressed = false end )
	end
end

function ENT:Think()
	if GetConVarNumber("ai_disabled") == 1 then return end
	
	//if self:GetActivity() == 1 and self.res_time < CurTime() and !self.following and !self.FoundEnemy_fear then
	//	self:ResetScheduleState()
	//end
	
	if self.efficient then return end
	
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
	
	for k, v in pairs( self.enemyTable_fear ) do
		local enemyTable_enemies_fr = ents.FindByClass( v )
		for k, v in pairs( enemyTable_enemies_fr ) do
			if( !table.HasValue( self.enemyTable_enemies_e, v ) ) then
				table.insert( self.enemyTable_enemies_e, v )
				v:AddEntityRelationship( self, 1, 10 )
				self:AddEntityRelationship( v, 2, 100 )
			end
		end
	end
	
	if sc_atkbyply and ValidEntity( sc_atkbyply ) and sc_atkbyply != self and sc_atkbyply.owner == self.owner then
		self:SpeakSentence( "!SC_SCARED" .. math.random(0,2), self, self.owner, 10, 10, 1, true, true, false, true )
		sc_atkbyply.owner = NULL
		sc_atkbyply = NULL
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

	if self.attacker:IsPlayer() then
		if self.following and self.follow_target == self.attacker then
			self:Fire( "stopfollowtarget", 0 )
		end
		self:AddEntityRelationship( self.attacker, 2, 100 )
	end
	
	if !self.enemy_fear or !ValidEntity( self.enemy_fear ) then
		self.enemy_fear = self.attacker
		self.dmgbyfr = true
		timer.Destroy( "dmg_fr_reset_timer" .. self:EntIndex() )
		timer.Create( "dmg_fr_reset_timer" .. self:EntIndex(), 3, 1, function() self.dmgbyfr = false end )
	end
	
	self:SpawnBloodEffect( "red", dmg:GetDamagePosition() )
	
	if( self:Health() > 0 ) then
		if( damage <= 25 ) then
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
		end
		timer.Create( "damage_count_reset_timer" .. self.Entity:EntIndex( ), 1.5, 1, function() self.damage_count = 0 end )
	end
	
	if( self.damage_count == 3 or self:HasCondition( 18 ) and self.pain == 1 ) then
		self:StartSchedule( schdHurt )
		if self.following and self.pressed then
			sc_atkbyply = self
		end
		self:SpeakSentence( "!SC_SCREAM" .. math.random(0,14), self, self.attacker, 10, 10, 1, true, true, false, true )
	end
	
	if !self.enemy then
		self.enemy = self.attacker
	end
	
	if ValidEntity(self.attacker) then
		self:UpdateEnemyMemory( self.attacker, self.attacker:GetPos() )
	end
	self.idle = 0

	if ( self:Health() <= 0 and !self.dead ) then //run on death
		self.dead = true
		if self.triggertarget and self.triggercondition == "4" then self:GotTriggerCondition() end
		gamemode.Call( "OnNPCKilled", self, self.attacker, self.inflictor )
		self:EmitSound( "scientist/sci_die" ..math.random(1,4).. ".wav", 500, 100)
		
		if self.attacker:IsPlayer() then
			self.attacker:AddFrags( 1 )
		end
		
		if( self.attacker:GetClass() != "npc_barnacle" and !dmg:IsDamageType( DMG_DISSOLVE ) ) then
			self:SpawnRagdoll( dmg:GetDamageForce(), self.bodykey_value )
			self:SetNPCState( NPC_STATE_DEAD )
			self:Remove()
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
	if( ( self.FoundEnemy_fear or self.dmgbyfr ) and !self.following and convar_ai == 0 ) then
		local Pos = self:GetPos()
		if !self.searchdelay then
			self.searchdelay = CurTime() +0.15
		end
		if self.searchdelay < CurTime() then
			self:FindInCone( 1, 9999 )
			self.searchdelay = nil
		end
		if( self.enemy_fear and ValidEntity(self.enemy_fear) ) then
			if( self.enemy_fear:IsNPC() ) then
				self:SetEnemy( self.enemy_fear )
			end
			self:UpdateEnemyMemory( self.enemy_fear, self.enemy_fear:GetPos() )
			self:StartSchedule( schdHide ) 
			if !self.spkfear then
				self.spkfear = true
				self:SpeakSentence( "!SC_FEAR" .. math.random(0,12), self, self.enemy_fear, 10, 10, 1, true, false, false, true )
				timer.Create( "self.spkfear_reset_timer" .. self:EntIndex(), 8, 1, function() self.spkfear = false end )
			end
		end
		
		self:SetEnemy( NULL )	
	elseif( self.idle == 0 and convar_ai == 0 ) then
		self.idle = 1
		self:SetSchedule( SCHED_IDLE_STAND )
		self:SelectSchedule()
	elseif( !self.FoundEnemy_fear and table.Count( self.table_fear ) > 0 ) then
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
		if ValidEntity( self.follow_target ) and self.follow_target:Health() > 0 then
			if( self:Disposition( self.follow_target ) != 3 ) then
				self:AddEntityRelationship( self.follow_target, 3, 10 )
			end
			
			if( self:GetPos():Distance( self.follow_target:GetPos() ) > 225 and convar_ai == 0 ) then
				self:SetEnemy( self.follow_target, true )
				self:UpdateEnemyMemory( self.follow_target, self.follow_target:GetPos() )
				if self.follow_target:IsPlayer() then
					self:StartSchedule( schdFollowply )
				else
					self:StartSchedule( schdFollow )
				end
				timer.Create( "self_select_schedule_timer" .. self:EntIndex(), 1, 1, function() self:StartSchedule( schdReset ) end )
			elseif( self:GetPos():Distance( self.follow_target ) <= 225 ) then
				self:StartSchedule( schdStop )
			end
			if !self.healing and self.follow_target:IsPlayer() and self.follow_target:Health() < 100 and self.follow_target:Health() > 0 and self:GetPos():Distance( self.follow_target:GetPos() ) <= 100 then
				self:SpeakSentence( "!SC_HEAL" .. math.random(0,7), self, self.follow_target, 10, 10, 1, true, false, false, true )
				self:StartSchedule( schdHealPull )
				self.bodykey_value = self.bodykey_value +4
				self:Fire( "SetBodygroup", self.bodykey_value, 1.05 )
				timer.Create( "needle_Pull_timer" .. self:EntIndex(), 1.1, 1, function() self.needleout = true end )
				timer.Create( "Heal_timer" .. self:EntIndex(), 0.05, 0, function() self:HealPlayer() end )
			end
			
			if( self:GetPos():Distance( self.follow_target:GetPos() ) < 30 and convar_ai == 0 ) then
				self:SetEnemy( self.follow_target, true )
				self:UpdateEnemyMemory( self.follow_target, self.follow_target:GetPos() )
				self:StartSchedule( schdBackaway )
			end
		else
			self.following = false
			self.follow_target = NULL
			self.pressed = false
		end
	end
end 

function ENT:GetSpawnflag( value )
	local spawnflags = { 131072, 65536, 32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1 }
	if !table.HasValue( spawnflags, value ) then return false end
	if value == 65536 then
		self.predisaster = true
	end
	if value == 16 then
		self.efficient = true
	end
	return true
end

function ENT:OnTriggerCondition()
	local ents = ents.FindByName( self.TriggerTarget )
	for k, v in pairs( ents ) do
		if v:GetClass() == "func_door" then
			v:Fire( "toggle", "", 0 )
		end
	end
end

function ENT:KeyValue( key, value )
	//Msg( "Key = " .. key .. ";value: " .. value .. "\n" )
	if( key == "squadname" or key == "netname" ) then
		self.squad = value
	end
	if( key == "health" ) then
		self.health = value
	end
	
	if( key == "body" ) then
		self.bodykey_v = value
	end
	
	if( key == "TriggerCondition" ) then
		self.triggercondition = value
	end
	
	if( key == "TriggerTarget" ) then
		self.triggertarget = value
	end
	
	if( key == "spawnflags" ) then
		self.spawnflags = tonumber(value)
		local function check_spawnflags()
			local spawnflags = { 131072, 65536, 32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1 }
			for k, v in pairs( spawnflags ) do
				if v <= self.spawnflags and !self.used then
					local value_a = v
					local value_b = self.spawnflags -v
					if table.HasValue( spawnflags, value_a ) then
						self:GetSpawnflag( value_a )
					end
					if self.spawnflags != v then
						if table.HasValue( spawnflags, value_b ) then
							self.used = true
							self:GetSpawnflag( value_b )
						else
							self.spawnflags = value_b
							self.used = false
							check_spawnflags()
						end
					else
						self.used = true
					end
				end
			end
		end
		check_spawnflags()
	end
end

function ENT:GetKeyValue( target, key )
	for k, v in pairs( target:GetKeyValues() ) do
		if k == key then
			self.keyvalue = v
		end
	end

	return self.keyvalue
end

function ENT:AcceptInput( cvar_name, activator, caller )
	if cvar_name == "Use" and ( ( caller:IsPlayer() and caller:IsAdmin() ) or !caller:IsPlayer() ) and !self.inuse then
		self.inuse = true
		self:Use( activator, caller )
		timer.Create( "in_use_reset_timer" .. self:EntIndex(), 1, 1, function() self.inuse = false end )
	end

	/*if( string.find( cvar_name,"heal" ) and ( ( caller:IsPlayer() and caller:IsAdmin() ) or !caller:IsPlayer() ) ) then
		self:StartSchedule( schdHealPull )
		self.bodykey_value = self.bodykey_value +4
		self:Fire( "SetBodygroup", self.bodykey_value, 1.05 )
		timer.Create( "needle_Pull_timer" .. self:EntIndex(), 1.1, 1, function() self.needleout = true end )
		timer.Create( "Heal_timer" .. self:EntIndex(), 0.05, 0, function() self:HealPlayer() end )
	end*/

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
			if self:Disposition( self.follow_target ) != 2 then
				self:AddEntityRelationship( self.follow_target, self.following_disp, 10 )
			end
		end
		timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
		self:StartSchedule( schdReset )
		self.follow_target = NULL
		self.pressed = false
		if sc_atkbyply and sc_atkbyply.owner and sc_atkbyply.owner == self.owner then
			sc_atkbyply.owner = NULL
			sc_atkbyply = NULL
		end
	end
end
function ENT:HealPlayer()
	self.healing = true
	local function check_target()
		if !self.follow_target or !self.follow_target:IsPlayer() or !ValidEntity( self.follow_target ) then
			self.needleout = false
			self.notarget = true
		end
	end
	check_target()
	if self.needleout and !self.notarget then
		if self.follow_target:GetPos():Distance( self:GetPos() ) < 65 then
			self.needleout = false
			self:StartSchedule( schdHeal )
			timer.Destroy( "needle_Pull_timer" .. self:EntIndex() )
			local function addhealth()
				check_target()
				if !self.notarget and self.follow_target:Health() < 100 then
					if self.follow_target:Health() +sk_scientist_heal_value <= 100 then
						self.follow_target:SetHealth( self.follow_target:Health() +sk_scientist_heal_value )
					elseif self.follow_target then
						self.follow_target:SetHealth( 100 )
					end
				end
			end
			timer.Create( "Heal_ply_timer" .. self:EntIndex(), 1.02, 1, addhealth )
			timer.Create( "Heal_ply_timer_shot" .. self:EntIndex(), 1.9, 1, function() self.needle_shot = true end )
		else
			self:SetEnemy( self.follow_target, true )
			self:UpdateEnemyMemory( self.follow_target, self.follow_target:GetPos() )
			self:StartSchedule( schdFollowply )
		end
	end
	
	if self.needle_shot or self.notarget then
		timer.Create( "self.healing_reset_timer" .. self:EntIndex(), 8, 1, function() self.healing = false end )
		self.needle_shot = false
		timer.Destroy( "Heal_timer" .. self:EntIndex() )
		timer.Destroy( "Heal_ply_timer" .. self:EntIndex() )
		timer.Destroy( "Heal_ply_timer_shot" .. self:EntIndex() )
		timer.Destroy( "Heal_timer" .. self:EntIndex() )
		timer.Destroy( "Heal_ply_timer" .. self:EntIndex() )
		self:StartSchedule( schdHealReturn )
		self.bodykey_value = self.bodykey_value -4
		self:Fire( "SetBodygroup", self.bodykey_value, 1.05 )
	end
end

function ENT:Use( activator, caller )
	if self:Disposition( activator ) == 2 then return false end
	self:ChooseResponseContext()
	if !self.nofollow then
		if ( !self.following and !self.pressed ) then
			self:SpeakSentence( "!SC_OK" .. math.random(0,8), self, activator, 10, 10, 1, true, true, false, true )
			self:Fire( "followtarget_!player" .. tostring(activator:UserID( )), "", 0.4 )
			timer.Create( "self_pressed_timer" .. self:EntIndex(), 1, 1, function() self.pressed = true end )
			self.owner = activator
		elseif ( self.following and self.pressed ) then
			self:SpeakSentence( "!SC_WAIT" .. math.random(0,6), self, activator, 10, 10, 1, true, true, false, true )
			self:Fire( "stopfollowtarget", "", 0 )
			timer.Create( "self_pressed_reset_timer" .. self:EntIndex(), 1, 1, function() self.pressed = false end )
		end
	elseif !self.plyused then
		self.plyused = true
		self:SpeakSentence( self.resp_use, self, activator, 10, 10, 1, true, true, false, true )
		timer.Create( "self.plyused_reset_timer" .. self:EntIndex(), 5, 1, function() self.plyused = false end )
	end
	return true
end

function ENT:ChooseResponseContext()
	if self.predisaster then
		self.resp_greet = "!SC_PHELLO" .. math.random(0,6)
		self.resp_quest = "!SC_PQUEST" .. math.random(0,17)
		self.resp_idle = "!SC_PIDLE" .. math.random(0,10)
		self.resp_use = "!SC_POK" .. math.random(0,4)
		self.nofollow = true
	end
end

/*---------------------------------------------------------
Name: OnRemove
Desc: Called just before entity is deleted
//-------------------------------------------------------*/
function ENT:OnRemove()
	if sc_atkbyply and sc_atkbyply.owner and ValidEntity( sc_atkbyply.owner ) and sc_atkbyply.owner == self.owner then
		sc_atkbyply.owner = NULL
		sc_atkbyply = NULL
	end
	timer.Destroy( "self_pressed_reset_timer" .. self:EntIndex() )
	timer.Destroy( "self.spkfear_reset_timer" .. self:EntIndex() )
	timer.Destroy( "self.ghide_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "damage_count_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "self.spkfear_reset_timer" .. self:EntIndex() )
	timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
	timer.Destroy( "needle_Pull_timer" .. self:EntIndex() )
	timer.Destroy( "Heal_timer" .. self:EntIndex() )
	timer.Destroy( "needle_Pull_timer" .. self:EntIndex() )
	timer.Destroy( "Heal_timer" .. self:EntIndex() )
	timer.Destroy( "Heal_ply_timer" .. self:EntIndex() )
	timer.Destroy( "Heal_ply_timer_shot" .. self:EntIndex() )
	timer.Destroy( "self.healing_reset_timer" .. self:EntIndex() )
	timer.Destroy( "self_pressed_timer" .. self:EntIndex() )
	timer.Destroy( "self_pressed_reset_timer" .. self:EntIndex() )
	timer.Destroy( "self.plyused_reset_timer" .. self:EntIndex() )
	timer.Destroy( "in_use_reset_timer" .. self:EntIndex() )
	timer.Destroy( "sc_stand_timer" .. self:EntIndex() )
	timer.Destroy( "dmg_fr_reset_timer" .. self:EntIndex() )
end