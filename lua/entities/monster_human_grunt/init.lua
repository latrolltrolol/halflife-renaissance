AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/hgrunt.mdl"
ENT.MeleeDistance		= 75
ENT.MinDistance = 900

ENT.defammo = 28

local schdChase = ai_schedule.New( "Chase Enemy" ) //creates the schedule used on this npc
//schdChase:EngTask( "TASK_GET_PATH_TO_ENEMY_LOS", 0 )
schdChase:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdChase:EngTask( "TASK_RUN_PATH_WITHIN_DIST", 600 ) 
//schdChase:EngTask( "TASK_STOP_MOVING", 0 ) 
schdChase:AddTask( "Stop_moving", 0 ) 

//schdChase:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 )

local schdReload = ai_schedule.New( "Reloading" ) 
schdReload:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RELOAD ) 

local schdFollow = ai_schedule.New( "Follow friend" )
schdFollow:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdFollow:EngTask( "TASK_RUN_PATH_WITHIN_DIST", 125 ) 

local schdFollowply = ai_schedule.New( "Follow player" )
schdFollowply:EngTask( "TASK_TARGET_PLAYER", 0 )
schdFollowply:EngTask( "TASK_GET_PATH_TO_TARGET", 0 )
schdFollowply:EngTask( "TASK_MOVE_TO_TARGET_RANGE", 125 ) 

local schdMeleeAttack = ai_schedule.New( "Attack Enemy melee" ) 
schdMeleeAttack:EngTask( "TASK_STOP_MOVING", 0 )
schdMeleeAttack:EngTask( "TASK_STOP_MOVING", 0 )
schdMeleeAttack:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_MELEE_ATTACK1 )

local schdAttack = ai_schedule.New( "Attack Enemy" ) 
schdAttack:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK1 )

local schdThrowgrenade = ai_schedule.New( "Throw grenade" ) 
schdThrowgrenade:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK2 )

local schdStop = ai_schedule.New( "Stop" )
schdStop:EngTask( "TASK_STOP_MOVING", 0 ) 

local schdHide = ai_schedule.New( "Hide" ) 
schdHide:EngTask( "TASK_FIND_COVER_FROM_ENEMY", 0 ) 

local schdHurt = ai_schedule.New( "Hurt" ) 
schdHurt:EngTask( "TASK_SMALL_FLINCH", 0 ) 

local schdReset = ai_schedule.New( "Reset" ) 
schdReset:EngTask( "TASK_RESET_ACTIVITY", 0 ) 

local schdBackaway = ai_schedule.New( "Back away" ) 
schdBackaway:EngTask( "TASK_FIND_BACKAWAY_FROM_SAVEPOSITION", 0 ) 

local schdGetWeapon = ai_schedule.New( "Get weapon" ) 
schdGetWeapon:EngTask( "TASK_WEAPON_FIND", 0 ) 
schdGetWeapon:EngTask( "TASK_WEAPON_RUN_PATH", 0 ) 
schdGetWeapon:EngTask( "TASK_WEAPON_PICKUP", 0 ) 

function ENT:Initialize()
	self.table_fear = {}
	self.f_headcrab_table = {}

	self:SetModel( self.Model )

	self:SetHullType( HULL_HUMAN );
	self:SetHullSizeNormal();

	self:SetSolid( SOLID_BBOX )
	self:SetMoveType( MOVETYPE_STEP )

	self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_ANIMATEDFACE | CAP_AIM_GUN | CAP_USE | CAP_OPEN_DOORS | CAP_FRIENDLY_DMG_IMMUNE | CAP_SQUAD )
	self:SetMaxYawSpeed( 5000 )

	if !self.health then
		self:SetHealth(sk_hgrunt_health_value)
	end
	
	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end
	self.ammo = self.defammo
	
	if self.weapon == 8 or self.weapon == 10 then
		self.gotshotgun = true
	else
		self.gotmp5 = true
	end
	
	if self.weapon == 5 then
		self.allow_gr = true
		self.gr_type = "gr_def"
	end
	
	if self.weapon == 3 or self.weapon == 10 then
		self.allow_gr = true
		self.gr_type = "gr_h"
	end
	
	if !self.weapon then
		local rand = math.random(1,3)
		if rand == 1 and !self.gotshotgun then
			self.gr_type = "gr_def"
			self.allow_gr = true
		elseif rand == 2 then
			self.gr_type = "gr_h"
			self.allow_gr = true
		end
	end
	
	if self.bodykey_v == "-1" or !self.bodykey_v then
		local rand = math.random(0,3)
		self.bodykey_value = rand
		if self.gotshotgun then
			self.bodykey_value = self.bodykey_value +4
		end
		self:SetKeyValue( "body", self.bodykey_value )
	else
		self.bodykey_value = self.bodykey_v
	end
	if self.gotshotgun then
		self.MinDistance = 440
	end
	
	if tonumber(self.bodykey_value) == 3 or tonumber(self.bodykey_value) == 7 then
		self:SetSkin( 1 )
	end

	self:SetUpEnemies( false, false, false, true )
	self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }
	
	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
	self.possess_viewpos = Vector( -95, 0, 108 )
	self.possess_addang = Vector(0,0,85)
end

function ENT:TaskStart_Stop_moving()
	self:TaskComplete()
	if !self.enemy or !ValidEntity( self.enemy ) then return end
	local MuzzleBone = self:LookupBone("Bip01 R Hand")
	local BonePos, BoneAng = self:GetBonePosition( MuzzleBone ) 
	
	local trd = {}
	trd.start = BonePos
	trd.endpos = self.enemy:GetPos()
	trd.filter = {self}
	local tr = util.TraceLine(trd)
	if tr.HitWorld then return end
	self:StartSchedule( schdStop )
end 

function ENT:Task_Stop_moving()
	self:TaskComplete()
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
		if !self.FoundEnemy then
			self.FoundEnemy_w_t = false
		else
			self.FoundEnemy_w_t = true
		end
		self.FoundEnemy = true
		self.FoundEnemy_fear = false
		self.timer_created = false
		if( self.alert_allow and self:HasCondition( 7 ) and !self:HasCondition( 8 ) and !self.FoundEnemy_w_t and !self.following ) then
			/*if !self.searchdelay then
				self.searchdelay = CurTime() +0.15
			end
			if self.searchdelay < CurTime() then
				self:FindInCone( 1, 9999 )
				self.searchdelay = nil
			end*/
			if self.enemy and ValidEntity( self.enemy ) then
				local monster_table = { "npc_antlion", "npc_antlion_worker", "npc_hunter", "npc_rollermine", "npc_vortigaunt", "npc_antlionguard", "npc_fastzombie_torso", "npc_fastzombie", "npc_headcrab", "npc_headcrab_black", "npc_headcrab_poison", "npc_headcrab_fast", "npc_poisonzombie", "npc_zombie", "npc_zombie_torso", "npc_zombine", "npc_stalker", "monster_generic", "monster_alien_controller", "monster_alien_grunt", "monster_babycrab", "monster_bigmomma", "monster_bullchicken", "monster_gargantua", "monster_headcrab", "monster_houndeye", "monster_panthereye", "monster_snark", "monster_tentacle", "monster_zombie" }
				if self.enemy:IsPlayer() then
					self:SpeakSentence( "!HG_ALERT" .. math.random(0,6), self, self, 10, 10, 1, true, true, false, false )
				elseif table.HasValue( monster_table, self.enemy:GetClass() ) then
					self:SpeakSentence( "!HG_MONST" .. math.random(0,3), self, self, 10, 10, 1, true, true, false, false )
				else
					local rand = math.random(1,4)
					if rand == 1 then
						self.alertspk = "!HG_ALERT1"
					elseif rand == 2 then
						self.alertspk = "!HG_ALERT2"
					elseif rand == 3 then
						self.alertspk = "!HG_ALERT3"
					else
						self.alertspk = "!HG_ALERT6"
					end
					self:SpeakSentence( self.alertspk, self, self, 10, 10, 1, true, true, false, false )
					self.alertspk = nil
				end
			end
			self.alert_allow = false
		end
	elseif( self:HasCondition( 8 ) and !self:HasCondition( 13 ) ) then
		self.FoundEnemy_fear = true
		self.timer_created = false
	elseif( self.FoundEnemy_fear and self:HasCondition( 13 ) ) then
		self.FoundEnemy_fear = false
	elseif( ( !self.enemy_memory or table.Count( self.enemy_memory ) == 0 ) and ( self:HasCondition( 13 ) and self:HasCondition( 31 ) ) or ( !self:HasCondition( 8 ) and !self:HasCondition( 7 ) and !self.enemy_occluded ) ) then
		self.FoundEnemy = false
	end
	
	if( !self.alert_allow and !self.FoundEnemy and !timer.IsTimer( "self.alert_allow_timer" .. self:EntIndex() ) ) then
		timer.Create( "self.alert_allow_timer" .. self:EntIndex(), 3, 1, function() self.alert_allow = true end )
	elseif( self.FoundEnemy ) then
		timer.Destroy( "self.alert_allow_timer" .. self:EntIndex() )
	end
	
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
	
	if self.possessed and !self.attacking and !self.reloading and ( !self.possession_allowdelay or ( self.possession_allowdelay and CurTime() > self.possession_allowdelay ) ) then
		self.possession_allowdelay = nil
		self:PossessMovement( 130 )
		if !self.master then return end
		if self.master:KeyDown( 1 ) then
			if !self.master:KeyDown( 4 ) then
				if !self.gotshotgun then
					if !self.noammo then
						self.attacking = true
						self.idle = 0
						self:Attack_ar( true )
					elseif self.noammo and !self.reloading then
						self:Reload()
					end
				else
					if !self.noammo then
						self.attacking = true
						self.idle = 0
						self:Attack_sh( true )
					elseif self.noammo and !self.reloading then
						self:Reload()
					end
				end
			else
				//throwgrenade
			end
		elseif self.master:KeyDown( 2048 ) then
			if !self.master:KeyDown( 4 ) and ( !self.possession_allowgrenade or ( self.possession_allowgrenade and CurTime() > self.possession_allowgrenade ) ) then
				self.possession_allowgrenade = nil
				if self.gr_type == "gr_def" then
					self:LaunchGrenade( true )
				elseif self.gr_type == "gr_h" then
					self:ThrowGrenade( true )
				end
			elseif self.master:KeyDown( 4 ) then
				self:Attack_Melee( true )
			end
		elseif self.master:KeyDown( 8192 ) then
			if self.ammo != self.defammo and !self.reloading then
				self:Reload()
			end
		end
	end
	
	if self.possessed then return end
	local grenades = ents.FindByClass( "npc_grenade_frag" )
	for k,v in pairs(grenades) do
		local grenade_dist = v:GetPos():Distance( self:GetPos() )
		if( !self.ghide and grenade_dist < 256 ) then
			self:SetEnemy( v, true )
			self:UpdateEnemyMemory( v, v:GetPos() )
			self:StartSchedule( schdBackaway )
			if !self.spkgr then
				self:SpeakSentence( "!HG_GREN" .. math.random(0,6), self, self, 10, 10, 1, true, true, false, false )
			end
			self.spkgr = true
			self.ghide = true
			self:SetEnemy( NULL )
			timer.Create( "self.ghide_reset_timer" .. self.Entity:EntIndex( ), 1, 1, function() self.ghide = false end )
			if !timer.IsTimer( "self.spkgr_reset_timer" .. self.Entity:EntIndex( ) ) then
				timer.Create( "self.spkgr_reset_timer" .. self.Entity:EntIndex( ), 6, 1, function() self.spkgr = false end )
			end
		end
	end
end

function ENT:DropWeapon( velocity )
	if self.dontdropweapon then return end
	local AttachAngPos = self:GetAttachment( self:LookupAttachment( "0" ) )
	for k, v in pairs( AttachAngPos ) do
		if !self.a then
			self.attachangle = v
			self.a = true
		else
			self.attachvector = v
			self.a = nil
		end
	end
	
	if self.gr_type and self.gr_type == "gr_h" then
		local AttachAngPos = self:GetAttachment( self:LookupAttachment( "1" ) )
		for k, v in pairs( AttachAngPos ) do
			if !self.a then
				self.attachangle = v
				self.a = true
			else
				self.attachvector = v
				self.a = nil
			end
		end
		
		local ammo = ents.Create( "weapon_handgrenade" )
		ammo:SetPos( self.attachvector )
		ammo:SetAngles( self.attachangle )
		ammo:Spawn()
		ammo:Activate()
		local ammo_phys = ammo:GetPhysicsObject( )
			ammo_phys:ApplyForceCenter( velocity *2 )
	end
	
	if self.gotshotgun then
		local weapon = ents.Create( "weapon_shotgun" )
		weapon:SetPos( self.attachvector )
		weapon:SetAngles( self.attachangle )
		weapon:Spawn()
		weapon:Activate()
		local wep_phys = weapon:GetPhysicsObject( )
			wep_phys:ApplyForceCenter( velocity )
		return true
	elseif self.gotmp5 then
		local weapon = ents.Create( "weapon_9mmAR" )
		weapon:SetPos( self.attachvector )
		weapon:SetAngles( self.attachangle )
		weapon:Spawn()
		weapon:Activate()
		local wep_phys = weapon:GetPhysicsObject( )
			wep_phys:ApplyForceCenter( velocity *2 )
		return true
	end
	return false
end

function ENT:OnTakeDamage(dmg)
	if dmg:GetInflictor():GetClass() == self:GetClass() then dmg:ScaleDamage( 0.04 ) end
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
		self:EmitSound( "hgrunt/gr_pain" .. math.random(1,5), 100, 100 )
	end
	
	if !self.enemy and self.enemy_memory and ( !self.WaterMonster or ( self.WaterMonster and self.attacker:WaterLevel() > 0 ) ) then
		local convar_ignoreply = GetConVarNumber("ai_ignoreplayers")
		if !table.HasValue( self.enemy_memory, self.attacker ) and ( !self.attacker:IsPlayer() or ( self.attacker:IsPlayer() and convar_ignoreply != 1 and !self.ignoreplys ) ) and self:Disposition( self.attacker ) == 1 then table.insert( self.enemy_memory, self.attacker ) end
	end
	
	if ValidEntity(self.attacker) then
		self:UpdateEnemyMemory( self.attacker, self.attacker:GetPos() )
	end
	self.idle = 0

	if ( self:Health() <= 0 and !self.dead ) then //run on death
		self.dead = true
		self:EndPossession()
		if self.triggertarget and self.triggercondition == "4" then self:GotTriggerCondition() end
		gamemode.Call( "OnNPCKilled", self, self.attacker, self.inflictor )
		self:EmitSound( "hgrunt/gr_die" ..math.random(1,3).. ".wav", 500, 100)
		
		if self.attacker:IsPlayer() then
			self.attacker:AddFrags( 1 )
		end
		
		if( self.attacker:GetClass() != "npc_barnacle" and !dmg:IsDamageType( DMG_DISSOLVE ) ) then
			if self.gotshotgun then
				self.bodykey_value = self.bodykey_value +4
			else
				self.bodykey_value = self.bodykey_value +8
			end
			local entvel
			local entphys = self:GetPhysicsObject()
			if entphys:IsValid() then
				entvel = entphys:GetVelocity()
			else
				entvel = self:GetVelocity()
			end
			self:SpawnRagdoll( dmg:GetDamageForce(), self.bodykey_value )
			self:DropWeapon( entvel )
			if self.drophealthkit then self:DropHealthkit() end
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

function ENT:Attack_Melee()
	self.attacking = true
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
				if v:IsNPC() and v:Health() - sk_hgrunt_kick_value <= 0 then
					self.killicon_ent = ents.Create( "sent_killicon" )
					self.killicon_ent:SetKeyValue( "classname", "sent_killicon_hgrunt" )
					self.killicon_ent:Spawn()
					self.killicon_ent:Activate()
					self.killicon_ent:Fire( "kill", "", 0.1 )
					self.attack_inflictor = self.killicon_ent
				else
					self.attack_inflictor = self
				end
				v:TakeDamage( sk_hgrunt_kick_value, self, self.attack_inflictor )
				self.attack_inflictor = nil
				if v:IsPlayer() then
					v:ViewPunch( Angle( math.Rand(-4,-9), 0, math.Rand(-10,10) ) )
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
			//else
			//	self:EmitSound( "npc/zombie/claw_miss" ..math.random(1,2).. ".wav", 80, 100)
			end
		end
		self.attacking = false
	end
	timer.Create( "melee_attack_dmgdelay_timer" .. self.Entity:EntIndex( ), 0.54, 1, attack_dmg )
end

function ENT:Reload()
	self.reloading = true
	self:StartSchedule( schdReload )
	self:EmitSound( "hgrunt/gr_reload1.wav", 100, 100 )
	timer.Create( "reload_timer" .. self:EntIndex(), 1.6, 1, function() self.noammo = false; self.reloading = false; self.ammo = self.defammo end )
end

function ENT:ThrowGrenade( poss )
	if !poss and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
	if !poss then
		for k, v in pairs( ents.FindInSphere( self.enemy:GetPos(), 200 ) ) do
			if ValidEntity(v) and v:IsNPC() and v:GetClass() == self:GetClass() then
				self.attacking = false
				self.allow_gr = false
				timer.Create( "allow_gr_timer_s" .. self:EntIndex(), math.random(8,12), 1, function() self.allow_gr = true end )
				return
			end
		end
	end
	
	self:StartSchedule( schdThrowgrenade )
	self:SpeakSentence( "!HG_THROW" .. math.random(0,3), self, self, 10, 10, 1, true, true, false, false )
	
	local function throw_gr()
		if !poss and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
		local grenade_phys = ents.Create( "monster_handgrenade" )
		grenade_phys.owner = self
		grenade_phys.type = "hgrenade"
		grenade_phys:SetModel( "models/weapons/w_eq_fraggrenade_thrown.mdl" )
		grenade_phys:SetOwner( self )
		
		local bone_pos, bone_ang = self:GetBonePosition( self:LookupBone("Bip01 L Forearm") )
		grenade_phys:SetPos( bone_pos )
		grenade_phys:SetColor( 255, 255, 255, 0 )
		grenade_phys:DrawShadow( false )
		
		local FireTrace
		if !poss then
			FireTrace = ((self.enemy:GetPos() + Vector(0,0,10)) - self:GetPos())
		else
			FireTrace = self:GetForward() *300 +Vector(0,0,12)
		end
		local Firevector = FireTrace:GetNormalized()
		local FireLength = FireTrace:Length()
		local ArriveTime = FireLength / 2000
		local BaseShootVector = Firevector * 800 + Vector(0,0,300 * ArriveTime)

		grenade_phys:Spawn()
		grenade_phys:Activate()
		
		grenade_phys.parentent = ents.Create( "prop_physics" )
		grenade_phys.parentent:SetModel( "models/w_grenade.mdl" )
		grenade_phys.parentent:SetPos( grenade_phys:GetPos() )
		grenade_phys.parentent:SetAngles( grenade_phys:GetAngles() )
		grenade_phys.parentent:Spawn()
		grenade_phys.parentent:Activate()
		
		grenade_phys.parentent:SetParent( grenade_phys )
		
		local phys = grenade_phys:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetVelocity( BaseShootVector + VectorRand() * 60)
		end
		timer.Create( "gr_atk_reset_timer" .. self:EntIndex(), 0.6, 1, function() self.attacking = false; self.allow_gr = false end )
		timer.Create( "allow_gr_timer" .. self:EntIndex(), math.random(13,19), 1, function() self.allow_gr = true end )
	end
	if poss then self.possession_allowgrenade = CurTime() +8 end
	timer.Create( "throw_gr" .. self:EntIndex(), 1.16, 1, throw_gr )
end

function ENT:LaunchGrenade( poss )
	if !poss and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
	if !poss then
		for k, v in pairs( ents.FindInSphere( self.enemy:GetPos(), 200 ) ) do
			if ValidEntity(v) and v:IsNPC() and v:GetClass() == self:GetClass() then
				self.attacking = false
				self.allow_gr = false
				timer.Create( "allow_gr_timer_s" .. self:EntIndex(), math.random(8,12), 1, function() self.allow_gr = true end )
				return
			end
		end
	end
	
	self:StartSchedule( schdAttack )
	
	local function throw_gr()
		if !poss and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
		self:EmitSound( "weapons/grenade_launcher1.wav", 100, 100 )
		local grenade_phys = ents.Create( "monster_handgrenade" )
		grenade_phys.owner = self
		grenade_phys.type = "wgrenade"
		grenade_phys:SetOwner( self )
		grenade_phys:SetModel( "models/items/ar2_grenade.mdl" )
		
		local MuzzleAttach = self:LookupAttachment( "0" )
		local AttachAngPos = self:GetAttachment( MuzzleAttach )
		for k, v in pairs( AttachAngPos ) do
			if !self.a then
				self.attachangle = v
				self.a = true
			else
				self.attachvector = v
				self.a = nil
			end
		end
		grenade_phys:SetPos( self.attachvector )
		
		local FireTrace
		if !poss then
			FireTrace = ((self.enemy:GetPos() + Vector(0,0,20)) - self:GetPos())
		else
			FireTrace = self:GetForward() *300 +Vector(0,0,12)
		end
		local Firevector = FireTrace:GetNormalized()
		local FireLength = FireTrace:Length()
		local ArriveTime = FireLength / 2000
		local BaseShootVector = Firevector * 600 + Vector(0,0,300 * ArriveTime)

		grenade_phys:Spawn()
		grenade_phys:Activate()
		local phys = grenade_phys:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetVelocity( BaseShootVector + VectorRand() * 60)
		end
		timer.Create( "gr_atk_reset_timer" .. self:EntIndex(), 0.6, 1, function() self.attacking = false; self.allow_gr = false end )
		timer.Create( "allow_gr_timer" .. self:EntIndex(), math.random(13,19), 1, function() self.allow_gr = true end )
	end
	if poss then self.possession_allowgrenade = CurTime() +8 end
	timer.Create( "throw_gr" .. self:EntIndex(), 0.4, 1, throw_gr )
end

function ENT:Attack_ar( poss )
	if !poss and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
	
	self:StartSchedule( schdAttack )
	
	self:EmitSound( "hgrunt/gr_mgun" .. math.random(1,2) .. ".wav", 100, 100 )
	local function fire()
		if !poss and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
		self:StartSchedule( schdAttack )
		local MuzzleAttach = self:LookupAttachment( "0" )
		local AttachAngPos = self:GetAttachment( MuzzleAttach )
		local enemy_pos
		if !poss then
			enemy_pos = self.enemy:GetPos()
			local npcclass = self.enemy:GetClass()
			if( npcclass == "npc_zombie_torso" or npcclass == "npc_fastzombie_torso" ) then
				enemy_pos.z = enemy_pos.z -42
			end
			
			if( npcclass == "npc_fastzombie" or npcclass == "npc_poisonzombie" ) then
				enemy_pos.z = enemy_pos.z -16
			end
									
			if( npcclass == "npc_clawscanner" or npcclass == "npc_cscanner" or npcclass == "npc_manhack" ) then
				enemy_pos.z = enemy_pos.z -33
			end
									
			if( npcclass == "npc_rollermine" or npcclass == "npc_headcrab" or npcclass == "npc_headcrab_black" or npcclass == "npc_headcrab_poison" or npcclass == "npc_headcrab_fast" or npcclass == "monster_headcrab" ) then
				enemy_pos.z = enemy_pos.z -48
			end
			
			if npcclass == "monster_babycrab" or npcclass == "monster_snark" then
				enemy_pos.z = enemy_pos.z -55
			end
									
			if( npcclass == "monster_houndeye" or npcclass == "monster_bullchicken" or npcclass == "monster_panthereye" ) then
				enemy_pos.z = enemy_pos.z -33
			end
			
			if( self.enemy:IsPlayer() and self.enemy:KeyDown( IN_DUCK ) ) then
				enemy_pos.z = enemy_pos.z -22
			end
		else
			enemy_pos = self:GetPos() +self:GetForward() *25
		end

		self.killicon_ent = ents.Create( "sent_killicon" )
		self.killicon_ent:SetKeyValue( "classname", "sent_killicon_hgrunt" )
		self.killicon_ent:Spawn()
		self.killicon_ent:Activate()
		self.killicon_ent:Fire( "kill", "", 0.1 )
		self.attack_inflictor = self.killicon_ent
		
		local enemy_sh_vec = (enemy_pos - self:GetPos()):Normalize()
		bullet = {}
		bullet.Num = 1
		bullet.Src = AttachAngPos["Pos"]
		bullet.Attacker = self.attack_inflictor
		bullet.Dir = enemy_sh_vec
		bullet.Spread = Vector(0.04,0.04,0)
		bullet.Tracer = 1
		bullet.Force = 4
		bullet.Damage = sk_wep_npc_9mmAR_value
		bullet.Callback = function( attacker, tr, dmginfo )
			local victim = tr.Entity
			local dmg = dmginfo:GetDamage()
			if tr.HitGroup == 1 then
				dmg = dmg*10
			elseif tr.HitGroup != 0 then
				dmg = dmg*0.25
			end
			
			if victim:IsNPC() and victim:Health() -dmg <= 0 then
				if self.enemy_memory and table.Count( self.enemy_memory ) > 0 then
					self.enemy_memory_valid = false
					for k, v in pairs( self.enemy_memory ) do
						if ValidEntity( v ) and v != victim and self:Disposition( v ) == 1 then
							self.enemy_memory_valid = true
						end
					end
				else
					self.enemy_memory_valid = false
				end
			end
		end
		
		self:FireBullets(bullet) 
		self.ammo = self.ammo -1
		if self.ammo <= 0 then
			self.noammo = true
		end
		
		//if self.shotbullets == 6 then
		//
		//end
		
		local effectdata = EffectData()
		effectdata:SetStart( AttachAngPos["Pos"] )
		effectdata:SetOrigin( AttachAngPos["Pos"] )
		effectdata:SetScale( 1 )
		util.Effect( "MuzzleEffect", effectdata )
	end
	fire()
	timer.Create( "Ar_Shoot_timer" .. self:EntIndex(), 0.1, 3, fire )
	
	if poss then self.possession_allowdelay = CurTime() +0.6 end
	self.attacking = false
end

function ENT:Attack_sh( poss )
	if !poss and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
	self:StartSchedule( schdAttack )

	//local MuzzleBone = self:LookupBone("Bip01 R Hand")
	//local BonePos, BoneAng = self:GetBonePosition( MuzzleBone ) 
	//self.shotbullets = 0
	self:EmitSound( "weapons/sbarrel1.wav", 100, 100 )
	self:StartSchedule( schdAttack )
	local MuzzleAttach = self:LookupAttachment( "0" )
	local AttachAngPos = self:GetAttachment( MuzzleAttach )
	for k, v in pairs( AttachAngPos ) do
		if !self.a then
			self.attachangle = v
			self.a = true
		else
			self.attachvector = v
			self.a = nil
		end
	end
	local enemy_pos
	if !poss then
		enemy_pos = self.enemy:GetPos()
		local npcclass = self.enemy:GetClass()
		if( npcclass == "npc_zombie_torso" or npcclass == "npc_fastzombie_torso" ) then
			enemy_pos.z = enemy_pos.z -38
		end
			
		if( npcclass == "npc_fastzombie" or npcclass == "npc_poisonzombie" ) then
			enemy_pos.z = enemy_pos.z -16
		end
									
		if( npcclass == "npc_clawscanner" or npcclass == "npc_cscanner" or npcclass == "npc_manhack" ) then
			enemy_pos.z = enemy_pos.z -33
		end
									
		if( npcclass == "npc_rollermine" or npcclass == "npc_headcrab" or npcclass == "npc_headcrab_black" or npcclass == "npc_headcrab_poison" or npcclass == "npc_headcrab_fast" or npcclass == "monster_headcrab" ) then
			enemy_pos.z = enemy_pos.z -48
		end
			
		if npcclass == "monster_babycrab" or npcclass == "monster_snark" then
			enemy_pos.z = enemy_pos.z -55
		end
									
		if( npcclass == "monster_houndeye" or npcclass == "monster_bullchicken" or npcclass == "monster_panthereye" ) then
			enemy_pos.z = enemy_pos.z -33
		end
			
		if( self.enemy:IsPlayer() and self.enemy:KeyDown( IN_DUCK ) ) then
			enemy_pos.z = enemy_pos.z -22
		end
	else
		enemy_pos = self:GetPos() +self:GetForward() *25
	end

	self.killicon_ent = ents.Create( "sent_killicon" )
	self.killicon_ent:SetKeyValue( "classname", "sent_killicon_hgrunt" )
	self.killicon_ent:Spawn()
	self.killicon_ent:Activate()
	self.killicon_ent:Fire( "kill", "", 0.1 )
	self.attack_inflictor = self.killicon_ent
		
	local enemy_sh_vec = (enemy_pos - self:GetPos()):Normalize()
	bullet = {}
	bullet.Num = 4
	bullet.Src = self.attachvector
	bullet.Attacker = self.attack_inflictor
	bullet.Dir = enemy_sh_vec
	bullet.Spread = Vector(0.15,0.15,0.1)
	bullet.Tracer = 1
	bullet.Force = 4
	bullet.Damage = math.random( 5, 7 )
	bullet.Callback = function( attacker, tr, dmginfo )
		local victim = tr.Entity
		local dmg = dmginfo:GetDamage()
		if tr.HitGroup == 1 then
			dmg = dmg*10
		elseif tr.HitGroup != 0 then
			dmg = dmg*0.25
		end
		if victim:IsNPC() and victim:Health() -dmg <= 0 then
			if self.enemy_memory and table.Count( self.enemy_memory ) > 0 then
				self.enemy_memory_valid = false
				for k, v in pairs( self.enemy_memory ) do
					if ValidEntity( v ) and v != victim and self:Disposition( v ) == 1 then
						self.enemy_memory_valid = true
					end
				end
			else
				self.enemy_memory_valid = false
			end
		end
	end
		
	self:FireBullets(bullet) 
	self.ammo = self.ammo -4
	if self.ammo <= 0 then
		self.noammo = true
	end
		
	local effectdata = EffectData()
	effectdata:SetStart( self.attachvector )
	effectdata:SetOrigin( self.attachvector )
	effectdata:SetScale( 1 )
	util.Effect( "MuzzleEffect", effectdata )
	if poss then self.possession_allowdelay = CurTime() +0.6 end
	timer.Create( "self.attack_sh_reset_timer" .. self:EntIndex(), 0.3, 1, function() self.attacking = false end )
end

function ENT:EnemyIsInWeaponRange()
	if self.enemy and ValidEntity( self.enemy ) and self.enemy:GetPos():Distance( self:GetPos() ) < self.MinDistance then
		return true
	else
		return false
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
			local tracedata = {}
			tracedata.start = self:GetPos()
			tracedata.endpos = self.enemy:GetPos()
			tracedata.filter = self
			local trace = util.TraceLine(tracedata)
			if !ValidEntity( trace.Entity ) or ( ValidEntity( trace.Entity ) and trace.Entity:GetClass() != self:GetClass() and ( self:Disposition( trace.Entity ) == 1 or self:Disposition( trace.Entity ) ==	2 ) ) then
				self.tr_ent_e = true
			else
				self.tr_ent_e = false
			end
			if( self.enemy:GetPos():Distance( Pos ) < self.MinDistance and self:HasCondition( 10 ) and !self:HasCondition( 42 ) and self.tr_ent_e ) then
				if( self.enemy:IsNPC() ) then
					self.SetEnemy( self.enemy )
				end
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				if self.enemy:GetPos():Distance( Pos ) > self.MeleeDistance then
					if !self.gotshotgun then
						if !self.noammo then
							self.attacking = true
							self.idle = 0
							local rand = math.random(1,9)
							if !self.allow_gr or ( self.allow_gr and rand != 3 ) or ( self.allow_gr and self.enemy:GetPos():Distance( Pos ) < 280 ) then
								self:Attack_ar()
							elseif self.allow_gr and rand == 3 then
								if self.gr_type == "gr_def" then
									self:LaunchGrenade()
								elseif self.gr_type == "gr_h" then
									self:ThrowGrenade()
								end
							else
								self.attacking = false
							end
						elseif self.noammo and !self.reloading then
							self:Reload()
						end
					else
						if !self.noammo then
							self.attacking = true
							self.idle = 0
							self:Attack_sh()
						elseif self.noammo and !self.reloading then
							self:Reload()
						end
					end
				else
					if( self.enemy:IsNPC() ) then
						self.SetEnemy( self.enemy )
					end
					if self.schedule_runtarget_pos then self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos ) end
					self:Attack_Melee()
				end
			elseif( ( self.following and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) < 800 ) or !self.following ) then
				timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
				self:SetEnemy( self.enemy, true )
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				self:StartSchedule( schdChase )
			end
		elseif( ( !self.enemy or !ValidEntity(self.enemy) ) and self.enemy_fear and ValidEntity(self.enemy_fear) and self:HasCondition( 8 ) and !self:HasCondition( 7 ) ) then
			if( self.enemy_fear:IsNPC() ) then
				self:SetEnemy( self.enemy_fear )
			end
			self:UpdateEnemyMemory( self.enemy_fear, self.enemy_fear:GetPos() )
			self:StartSchedule( schdHide ) 
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
	
	if( self.following and !self:EnemyIsInWeaponRange() and !self.possessed ) then
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
	if value == 8192 then
		self.dontdropweapon = true
	end
	if value == 8 then
		self.drophealthkit = true
	end
	return true
end

function ENT:KeyValue( key, value )
	if( key == "squadname" or key == "netname" ) then
		self.squad = value
		self:SetupSquad()
	end

	if( key == "health" ) then
		self.health = value
	end
	
	if( key == "body" ) then
		self.bodykey_v = value
	end
	
	if key == "additionalequipment" and value == "weapon_shotgun" then
		self.gotshotgun = true
	end
	
	if key == "weapons" then
		self.weapon = tonumber(value)
	end
	
	if( key == "spawnflags" ) then
		self.spawnflags = tonumber(value)
		self:CheckSpawnflags()
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

/*---------------------------------------------------------
Name: OnRemove
Desc: Called just before entity is deleted
//-------------------------------------------------------*/
function ENT:OnRemove()
	if sc_atkbyply and sc_atkbyply.owner and ValidEntity( sc_atkbyply.owner ) and sc_atkbyply.owner == self.owner then
		sc_atkbyply.owner = NULL
		sc_atkbyply = NULL
	end
	self:EndPossession()
	timer.Destroy( "self.enemy_occluded_timer" .. self:EntIndex() )
	timer.Destroy( "self.ghide_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "damage_count_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "draw_wep_timer" .. self:EntIndex() )
	timer.Destroy( "reload_timer" .. self:EntIndex() )
	timer.Destroy( "self.spkkill_reset_timer" .. self:EntIndex() )
	timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
	timer.Destroy( "self_pressed_timer" .. self:EntIndex() )
	timer.Destroy( "self_pressed_reset_timer" .. self:EntIndex() )
	timer.Destroy( "self.plyused_reset_timer" .. self:EntIndex() )
	timer.Destroy( "in_use_reset_timer" .. self:EntIndex() )
	timer.Destroy( "melee_attack_dmgdelay_timer" .. self.Entity:EntIndex( ) )
end