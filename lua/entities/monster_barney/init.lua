AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/ba_hl1.mdl"

ENT.MinDistance = 800
ENT.defammo = 18

local schdChase = ai_schedule.New( "Chase Enemy" ) //creates the schedule used on this npc
//schdChase:EngTask( "TASK_GET_PATH_TO_ENEMY_LOS", 0 )
schdChase:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdChase:EngTask( "TASK_RUN_PATH_WITHIN_DIST", 600 ) 
//schdChase:EngTask( "TASK_STOP_MOVING", 0 ) 
schdChase:AddTask( "Stop_moving", 0 ) 

//schdChase:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 )

local schdDrawwep = ai_schedule.New( "Draw Weapon" ) 
schdDrawwep:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_ARM ) 

local schdReload = ai_schedule.New( "Reloading" ) 
schdReload:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RELOAD ) 

local schdDisarm = ai_schedule.New( "Disarm" ) 
schdDisarm:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_DISARM ) 

local schdFollow = ai_schedule.New( "Follow friend" )
schdFollow:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdFollow:EngTask( "TASK_RUN_PATH_WITHIN_DIST", 125 ) 

local schdFollowply = ai_schedule.New( "Follow player" )
schdFollowply:EngTask( "TASK_TARGET_PLAYER", 0 )
schdFollowply:EngTask( "TASK_GET_PATH_TO_TARGET", 0 )
schdFollowply:EngTask( "TASK_MOVE_TO_TARGET_RANGE", 125 ) 

local schdAttack = ai_schedule.New( "Attack Enemy" ) 
schdAttack:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK1 )

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

//local schdResetSchedule = ai_schedule.New( "ResetSchedule" ) 
//schdResetSchedule:EngTask( "TASK_ENABLE_SCRIPT", 0 )
//schdResetSchedule:EngTask( "TASK_SET_SCHEDULE", "SCHED_IRIS_FOLLOW_PLAYER" )//"SCHED_SCRIPTED_WAIT" ) 

local schdResetSchedule = ai_schedule.New( "ResetSchedule" ) 
schdResetSchedule:EngTask( "TASK_SET_SCHEDULE", 59 ) 

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
		self:SetHealth(sk_barney_health_value)
	end
	
	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end
	self.ammo = self.defammo

	self:SetUpEnemies( false, true )
	self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }
	
	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
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
		self.FoundEnemy = true
		self.FoundEnemy_fear = false
		self.timer_created = 0
	elseif( self:HasCondition( 8 ) and !self:HasCondition( 13 ) ) then
		self.FoundEnemy_fear = true
		self.timer_created = 0
	elseif( self.FoundEnemy_fear and self:HasCondition( 13 ) ) then
		self.FoundEnemy_fear = false
	elseif( ( !self.enemy_memory or table.Count( self.enemy_memory ) == 0 ) and ( self:HasCondition( 13 ) and self:HasCondition( 31 ) ) or ( !self:HasCondition( 8 ) and !self:HasCondition( 7 ) and !self.enemy_occluded ) ) then
		self.FoundEnemy = false
	end
	
	if( self:HasCondition( 13 ) ) then
		self.enemy_occluded = true
		timer.Destroy( "self.enemy_occluded_timer" .. self:EntIndex() )
	elseif( !timer.IsTimer( "self.enemy_occluded_timer" .. self:EntIndex() ) ) then
		timer.Create( "self.enemy_occluded_timer" .. self:EntIndex(), 1.5, 1, function() self.enemy_occluded = false end )
	end
	
	if( self:HasCondition( 35 ) and self.following and self.pressed ) then
		if self.follow_target and ValidEntity( self.follow_target ) and self.follow_target:IsPlayer() then
			self:SpeakSentence( "!BA_STOP" .. math.random(0,1), self, self.follow_target, 10, 10, 1, true, true, false, true )
		end
		self:Fire( "stopfollowtarget", "", 0 )
		timer.Create( "self_pressed_reset_timer" .. self:EntIndex(), 1, 1, function() self.pressed = false end )
	end
end

function ENT:Think()
	if GetConVarNumber("ai_disabled") == 1 then return end
	
	if !self.disarmed and self.drawnwep and ( !self.enemy or !ValidEntity( self.enemy ) ) and !self.enemy_memory_valid then
		self:Disarm()
	end
	
	if self.efficient then return end
	
	if barney_kply and ValidEntity( barney_kply ) and barney_kply:Health() > 0 and barney_kply_attacker and ValidEntity( barney_kply_attacker ) and barney_kply_attacker:Health() > 0/* and self:Disposition( barney_kply_attacker ) != 1*/ then
		local trd = {}
		trd.start = self:GetPos()
		trd.endpos = barney_kply:GetPos()
		trd.filter = {self}
		local tr = util.TraceLine(trd)
		if barney_kply != self then
			self.barney_kply_attacker_defrel = self:Disposition( barney_kply_attacker )
		end
		if tr.Entity == barney_kply then
			self:AddEntityRelationship( barney_kply_attacker, 1, 10 )
		end
		if self.following and ValidEntity( self.follow_target ) and self.follow_target == barney_kply_attacker then
			self:Fire( "stopfollowtarget", "", 0 )
		end
		self.kply = barney_kply
		self.kply_v = self.kply
		self.kply_attacker = barney_kply_attacker
		self.kply_attacker_v = self.kply_attacker
		timer.Simple( 0.1, function() barney_kply = NULL; self.kply_attacker = NULL end )
	elseif self.kply_attacker_v and self.kply_attacker_v:Health() <= 0 then
		self:AddEntityRelationship( self.kply_attacker_v, self.barney_kply_attacker_defrel, 10 )
		self.barney_kply_attacker_defrel = nil
		self.kply_attacker_v = nil
		self.kply = nil
		if self.attackedbyply and self.attackedbyply >= 2 then
			self.attackedbyply = nil
		end
	end
	
	local grenades = ents.FindByClass( "npc_grenade_frag" )
	for k,v in pairs(grenades) do
		local grenade_dist = v:GetPos():Distance( self:GetPos() )
		if( self.ghide == 0 and grenade_dist < 256 and !self.FoundEnemy ) then
			self:SetEnemy( v, true )
			self:UpdateEnemyMemory( v, v:GetPos() )
			self:StartSchedule( schdHide )
			self.ghide = 1
			self:SetEnemy( NULL )
			timer.Create( "self.ghide_reset_timer" .. self.Entity:EntIndex( ), 1, 1, function() self.ghide = 0 end )
		end
	end
	
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
	
	if sc_atkbyply and ValidEntity( sc_atkbyply ) and sc_atkbyply != self and sc_atkbyply.owner == self.owner then
		self:SpeakSentence( "!BA_SCARE" .. math.random(0,1), self, self.owner, 10, 10, 1, true, true, false, true )
		sc_atkbyply.owner = NULL
		sc_atkbyply = NULL
	end	
end

function ENT:DropWeapon( velocity )
	if !self.drawnwep or self.dontdropweapon then return false end
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
	
	local weapon = ents.Create( "weapon_9mmhandgun" )
	weapon:SetPos( self.attachvector )
	weapon:SetAngles( self.attachangle )
	weapon:Spawn()
	weapon:Activate()
	local wep_phys = weapon:GetPhysicsObject( )
		wep_phys:ApplyForceCenter( velocity *2 )
	return true
end

function ENT:OnTakeDamage(dmg)
	self:SpawnBloodEffect( "red", dmg:GetDamagePosition() )
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

	if self.attacker:IsPlayer() and !self.attackedbyply then
		self.attackedbyply = 1
		self:SpeakSentence( "!BA_SHOT" .. math.random(0,1), self, self.attacker, 10, 10, 1, true, true, false, true )
	elseif self.attackedbyply == 1 then
		self.attackedbyply = 2
		self:SpeakSentence( "!BA_MAD" .. math.random(0,6), self, self.attacker, 10, 10, 1, true, true, false, true )
		self.barney_kply_attacker_defrel = self:Disposition( self.attacker )
		self:AddEntityRelationship( self.attacker, 1, 10 )
		barney_kply = self
		barney_kply_attacker = self.attacker
	end
	
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
		if !self.spkwounded then
			self.spkwounded = true
			self:SpeakSentence( "!BA_WOUND" .. math.random(0,1), self, self.attacker, 10, 10, 1, true, true, false, true )
			timer.Create( "self.spkwounded_reset_timer" .. self:EntIndex(), math.random(4,7), 1, function() self.spkwounded = false end )
		end
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
		if self.triggertarget and self.triggercondition == "4" then self:GotTriggerCondition() end
		gamemode.Call( "OnNPCKilled", self, self.attacker, self.inflictor )
		self:EmitSound( "barney/ba_die" ..math.random(1,3).. ".wav", 500, 100)
		
		if self.attacker:IsPlayer() then
			self.attacker:AddFrags( 1 )
		end
		
		if( self.attacker:GetClass() != "npc_barnacle" and !dmg:IsDamageType( DMG_DISSOLVE ) ) then
			local entvel
			local entphys = self:GetPhysicsObject()
			if entphys:IsValid() then
				entvel = entphys:GetVelocity()
			else
				entvel = self:GetVelocity()
			end
			self:SpawnRagdoll( dmg:GetDamageForce() )
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

function ENT:Disarm()
	self.disarmed = true
	self:StartSchedule( schdDisarm )
	self:Fire( "SetBodygroup", "0", 1.42 )
	timer.Create( "disarm_timer" .. self:EntIndex(), 1.42, 1, function() self.drawnwep = false end )
end

function ENT:DrawWeapon()
	self.drawing_weapon = true
	self:StartSchedule( schdDrawwep )
	self:Fire( "SetBodygroup", "1", 0.38 )
	timer.Create( "draw_wep_timer" .. self:EntIndex(), 0.75, 1, function() self.drawnwep = true; self.drawing_weapon = false; self.disarmed = false end )
end

function ENT:Reload()
	self.reloading = true
	self:StartSchedule( schdReload )
	self:EmitSound( "items/9mmclip" .. math.random(1,2) .. ".wav", 100, 100 )
	timer.Create( "reload_timer" .. self:EntIndex(), 1.6, 1, function() self.noammo = false; self.reloading = false; self.ammo = self.defammo end )
end

function ENT:Attack()
	self:StartSchedule( schdAttack )
	self:EmitSound( "barney/ba_attack2.wav", 100, 100 )

	//local MuzzleBone = self:LookupBone("Bip01 R Hand")
	//local BonePos, BoneAng = self:GetBonePosition( MuzzleBone ) 
	
	local MuzzleAttach = self:LookupAttachment( "0" )
	local AttachAngPos = self:GetAttachment( MuzzleAttach )
	
	local enemy_pos = self.enemy:GetPos()
	
	local npcclass = self.enemy:GetClass()
	if( npcclass == "npc_zombie_torso" or npcclass == "npc_fastzombie_torso" ) then
		enemy_pos.z = enemy_pos.z -38
	end
	
	if( npcclass == "npc_fastzombie" or npcclass == "npc_poisonzombie" or npcclass == "monster_human_grunt" ) then
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
	
	
	local rp = RecipientFilter() 
	rp:AddAllPlayers() 

	self.killicon_ent = ents.Create( "sent_killicon" )
	self.killicon_ent:SetKeyValue( "classname", "sent_killicon_barney" )
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
	bullet.Spread = Vector(0.03,0.03,0)
	bullet.Tracer = 1
	bullet.Force = 4
	bullet.Damage = sk_wep_npc_9mm_value
	bullet.Callback = function( attacker, tr, dmginfo )
		local victim = tr.Entity
		local dmg = dmginfo:GetDamage()
		if tr.HitGroup == 1 then
			dmg = dmg*10
		elseif tr.HitGroup != 0 then
			dmg = dmg*0.25
		end
		if victim:IsNPC() and victim:Health() -dmg <= 0 then
			if !self.spkkill then
				self:SpeakSentence( "!BA_KILL" .. math.random(0,6), self, self, 10, 10, 1, true, true, false, true )
				self.spkkill = true
				timer.Create( "self.spkkill_reset_timer" .. self:EntIndex(), 6, 1, function() self.spkkill = false end )
			end
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
			
			if !self.enemy_memory_valid then
				self:Disarm()
			end
		end
	end
	
	self:FireBullets(bullet) 
	self.ammo = self.ammo -1
	if self.ammo <= 0 then
		self.noammo = true
	end
	
	local effectdata = EffectData()
	effectdata:SetStart( AttachAngPos["Pos"] )
	effectdata:SetOrigin( AttachAngPos["Pos"] )
	effectdata:SetScale( 1 )
	util.Effect( "MuzzleEffect", effectdata )
	
	self.attacking = false
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
				if !self.drawing_weapon and self.drawnwep and !self.noammo then
					self.attacking = true
					self.idle = 0
					self:StartSchedule( schdAttack )
					self:Attack()
				elseif !self.drawing_weapon and !self.drawnwep then
					self:StartSchedule( schdDrawwep )
					self:DrawWeapon()
				elseif !self.drawing_weapon and self.drawnwep and self.noammo and !self.reloading then
					self:Reload()
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
	
	if( self.following and !self:EnemyIsInWeaponRange() ) then
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
	if value == 65536 then
		self.predisaster = true
	end
	if value == 16 then
		self.efficient = true
	end
	if value == 8192 then
		self.dontdropweapon = true
	end
	if value == 8 then
		self.drophealthkit = true
	end
	return true
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
	if cvar_name == "setsquad" then
		timer.Simple( 0.01, function() self.squad = self:GetKeyValue( self, "squadname" ); self:SetupSquad() end )
		self.squadtable = {}
	end
	if cvar_name == "Use" and ( ( caller:IsPlayer() and caller:IsAdmin() ) or !caller:IsPlayer() ) and !self.inuse then
		self.inuse = true
		self:Use( activator, caller )
		timer.Create( "in_use_reset_timer" .. self:EntIndex(), 1, 1, function() self.inuse = false end )
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
		if self.following_disp and ( !self.kply_attacker_v or ( self.follow_target != self.kply_attacker_v ) ) then
			self:AddEntityRelationship( self.follow_target, self.following_disp, 10 )
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

function ENT:Use( activator, caller )
	if self.kply_attacker_v and self.kply_attacker_v == activator then return end
	self:ChooseResponseContext()
	if !self.nofollow then
		if ( !self.following and !self.pressed ) then
			self:SpeakSentence( "!BA_OK" .. math.random(0,6), self, activator, 10, 10, 1, true, false, false, true )
			self:Fire( "followtarget_!player" .. tostring(activator:UserID( )), "", 0.4 )
			timer.Create( "self_pressed_timer" .. self:EntIndex(), 1, 1, function() self.pressed = true end )
			self.owner = activator
		elseif ( self.following and self.pressed ) then
			self:SpeakSentence( "!BA_WAIT" .. math.random(0,5), self, activator, 10, 10, 1, true, true, false, true )
			self:Fire( "stopfollowtarget", "", 0 )
			timer.Create( "self_pressed_reset_timer" .. self:EntIndex(), 1, 1, function() self.pressed = false end )
		end
	elseif !self.plyused then
		self.plyused = true
		self:SpeakSentence( self.resp_use, self, activator, 10, 10, 1, true, true, false, true )
		timer.Create( "self.plyused_reset_timer" .. self:EntIndex(), 5, 1, function() self.plyused = false end )
	end
end

function ENT:ChooseResponseContext()
	if self.predisaster then
		self.resp_greet = "!BA_HELLO" .. math.random(0,6)
		self.resp_quest = "!BA_QUESTION" .. math.random(0,14)
		self.resp_use = "!BA_POK" .. math.random(0,3)
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
	timer.Destroy( "self.enemy_occluded_timer" .. self:EntIndex() )
	timer.Destroy( "self.ghide_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "damage_count_reset_timer" .. self.Entity:EntIndex( ) )
	timer.Destroy( "disarm_timer" .. self:EntIndex() )
	timer.Destroy( "draw_wep_timer" .. self:EntIndex() )
	timer.Destroy( "reload_timer" .. self:EntIndex() )
	timer.Destroy( "self.spkkill_reset_timer" .. self:EntIndex() )
	timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
	timer.Destroy( "self_pressed_timer" .. self:EntIndex() )
	timer.Destroy( "self_pressed_reset_timer" .. self:EntIndex() )
	timer.Destroy( "self.plyused_reset_timer" .. self:EntIndex() )
	timer.Destroy( "in_use_reset_timer" .. self:EntIndex() )
	timer.Destroy( "self.spkwounded_reset_timer" .. self:EntIndex() )
end