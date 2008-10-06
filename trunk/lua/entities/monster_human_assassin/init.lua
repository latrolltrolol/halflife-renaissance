AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/hassassin.mdl"
ENT.MeleeDistance		= 75
ENT.RunMeleeDistance = 375
ENT.MinDistance = 2075

ENT.SpawnRagdollOnDeath = true
ENT.FadeOnDeath = false
ENT.BloodType = "red"
ENT.Pain = false

local schdHideTest = ai_schedule.New( "Hide" ) 
schdHideTest:EngTask( "TASK_FIND_COVER_FROM_ORIGIN", 0 ) 
schdHideTest:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 )
schdHideTest:AddTask( "HideTest", 0 ) 

function ENT:TaskStart_HideTest()
	self:TaskComplete()
end 

function ENT:Task_HideTest()
	self:TaskComplete()
end

function ENT:AcceptInput( cvar_name, activator, caller )
	if cvar_name == "hide" then
		self:StartSchedule( schdHideTest )
	end
end

local schdChase = ai_schedule.New( "Chase Enemy" ) //creates the schedule used on this npc
schdChase:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdChase:EngTask( "TASK_RUN_PATH_WITHIN_DIST", 1800 ) 
schdChase:EngTask( "TASK_STOP_MOVING", 0 )
//schdChase:AddTask( "Stop_moving", 0 ) 

local schdMoveToLOS = ai_schedule.New( "Chase Enemy" ) //creates the schedule used on this npc
schdMoveToLOS:EngTask( "TASK_GET_PATH_TO_ENEMY_LKP_LOS ", 0 )
schdMoveToLOS:EngTask( "TASK_RUN_PATH_TIMED", 0.2 )
schdMoveToLOS:EngTask( "TASK_WAIT", 0.2 ) 
schdMoveToLOS:EngTask( "TASK_STOP_MOVING", 0 )

local schdChaseClose = ai_schedule.New( "Chase Enemy close" )
schdChaseClose:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdChaseClose:EngTask( "TASK_RUN_PATH_TIMED", 0.2 )
schdChaseClose:EngTask( "TASK_WAIT", 0.2 ) 

local schdFollow = ai_schedule.New( "Follow friend" )
schdFollow:EngTask( "TASK_GET_PATH_TO_ENEMY", 0 )
schdFollow:EngTask( "TASK_RUN_PATH_WITHIN_DIST", 125 ) 

local schdFollowply = ai_schedule.New( "Follow player" )
schdFollowply:EngTask( "TASK_TARGET_PLAYER", 0 )
schdFollowply:EngTask( "TASK_GET_PATH_TO_TARGET", 0 )
schdFollowply:EngTask( "TASK_MOVE_TO_TARGET_RANGE", 125 ) 

local schdMeleeAttack_a = ai_schedule.New( "Attack Enemy melee" ) 
schdMeleeAttack_a:EngTask( "TASK_STOP_MOVING", 0 )
schdMeleeAttack_a:AddTask( "Attack_Melee", 0 ) 
schdMeleeAttack_a:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_MELEE_ATTACK1 )

local schdMeleeAttack_b = ai_schedule.New( "Attack Enemy melee" ) 
schdMeleeAttack_b:EngTask( "TASK_STOP_MOVING", 0 )
schdMeleeAttack_b:AddTask( "Attack_Melee", 0 ) 
schdMeleeAttack_b:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_MELEE_ATTACK2 )

local schdAttack = ai_schedule.New( "Attack Enemy" ) 
schdAttack:AddTask( "Attack", 0 ) 
schdAttack:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK1 )

local schdThrowgrenade = ai_schedule.New( "Throw grenade" ) 
schdThrowgrenade:EngTask( "TASK_STOP_MOVING", 0 )
schdThrowgrenade:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_RANGE_ATTACK2 )
//schdThrowgrenade:AddTask( "PlaySequence", { Name = "grenadethrow", Speed = 1 } )

local schdJump = ai_schedule.New( "Jump" ) 
schdJump:EngTask( "TASK_STOP_MOVING", 0 )
schdJump:EngTask( "TASK_PLAY_SEQUENCE_FACE_ENEMY", ACT_HOP )//"PlaySequence", { Name = "jump", Speed = 1 } )

local schdFlyUp = ai_schedule.New( "Fly up" ) 
schdFlyUp:EngTask( "TASK_STOP_MOVING", 0 )
schdFlyUp:AddTask( "PlaySequence", { Name = "fly_up", Speed = 1 } )

local schdFlyDown = ai_schedule.New( "Fly down" ) 
schdFlyDown:EngTask( "TASK_STOP_MOVING", 0 )
schdFlyDown:AddTask( "PlaySequence", { Name = "fly_down", Speed = 1 } )

local schdFlyDownAttack = ai_schedule.New( "Fly down attack" ) 
schdFlyDownAttack:EngTask( "TASK_STOP_MOVING", 0 )
schdFlyDownAttack:AddTask( "Attack", 0 ) 
schdFlyDownAttack:AddTask( "PlaySequence", { Name = "fly_attack", Speed = 1 } )

local schdLand = ai_schedule.New( "Land" ) 
schdLand:EngTask( "TASK_STOP_MOVING", 0 )
schdLand:AddTask( "PlaySequence", { Name = "landfromjump", Speed = 1 } )
schdLand:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 )

local schdStop = ai_schedule.New( "Stop" )
schdStop:EngTask( "TASK_STOP_MOVING", 0 ) 

local schdHide = ai_schedule.New( "Hide" ) 
schdHide:EngTask( "TASK_FIND_COVER_FROM_ENEMY", 0 ) 
schdHide:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 )

local schdHurt = ai_schedule.New( "Hurt" ) 
schdHurt:EngTask( "TASK_SMALL_FLINCH", 0 ) 

local schdReset = ai_schedule.New( "Reset" ) 
schdReset:EngTask( "TASK_RESET_ACTIVITY", 0 ) 

local schdBackaway = ai_schedule.New( "Back away" ) 
schdBackaway:EngTask( "TASK_FIND_BACKAWAY_FROM_SAVEPOSITION", 0 ) 

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
		self:SetHealth(sk_hassassin_health_value)
	end
	
	if self.triggertarget and self.triggercondition == "3" then self.starthealth = self:Health() end
	
	
	self:SetUpEnemies( false, false, false, true )
	self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }
	
	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
	self.allow_gr = true
	self.allowjump = true
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

function ENT:DmgAdd()
	if !self.allowjump then return end
	local rand = math.random( 1,3 )
	if rand == 1 and self:CheckEnemy( 1 ) and self.enemy:GetPos():Distance( self:GetPos() ) < self.RunMeleeDistance and self.enemy:GetPos():Distance( self:GetPos() ) > self.MeleeDistance then
		local rand = math.random(1,2)
		if rand == 1 then
			self:StartSchedule( schdJump )
			self:SetLocalVelocity( ( self:GetForward() *-420 ) +Vector( 0, 0, 380 ) )
			self.jumping = true
			self.allowjump = false
			self.jumpcur = CurTime() +math.Rand(5,13)
		else
			self.HideCur = CurTime()
		end
	end
end

function ENT:Think()
	if self:HasCondition( 26 ) then
		self:SetCondition( 10 )
		self:HasCondition( 7 )
	end

	if jumpcur and CurTime() > jumpcur then
		self.allowjump = true
	end 
	if self.jumping then
		local vel_z = self:GetVelocity().z
		if vel_z > -100 and vel_z != 0 then
			self:StartSchedule( schdFlyUp )
		else
			if self:CheckEnemy( 1 ) then
				local rand = math.random(1,2)
				if rand == 1 then
					self:StartSchedule( schdFlyDownAttack )
				else
					self:StartSchedule( schdFlyDown )
				end
			else
				self:StartSchedule( schdFlyDown )
			end
			
			local trace = {}
			trace.start = self:GetPos()
			trace.endpos = self:GetPos() + Vector( 0, 0, -25 )
			trace.filter = self

			local tr = util.TraceLine( trace ) 
			if tr.HitWorld or ( ValidEntity( tr.Entity ) and ( tr.Entity:IsPlayer() or tr.Entity:IsNPC() or ValidEntity( tr.Entity:GetPhysicsObject( ) ) ) ) then 
				self.jumping = nil
				self:StartSchedule( schdLand )
				self.HideCur = CurTime() +0.3
			end
		end
	end
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
	
	if self.possessed and !self.attacking and !self.jumping and ( !self.possession_allowdelay or ( self.possession_allowdelay and CurTime() > self.possession_allowdelay ) ) then
		self.possession_allowdelay = nil
		self:PossessMovement( 180 )
		if !self.master then return end
		if self.master:KeyDown( 1 ) then
			if !self.master:KeyDown( 4 ) then
				self.attacking = true
				self.idle = 0
				self:StartSchedule( schdAttack )
			else
				self.attacking = true
				self.idle = 0
				self:ThrowGrenade( true )
			end
		elseif self.master:KeyDown( 2048 ) then
			if !self.master:KeyDown( 4 ) then
				self:StartSchedule( schdJump )
				self:SetLocalVelocity( ( self:GetForward() *-420 ) +Vector( 0, 0, 380 ) )
				self.jumping = true
				self.allowjump = false
				self.jumpcur = CurTime() +math.Rand(5,13)
			else
				self.attacking = true
				self.idle = 0
				local rand = math.random(1,2)
				if rand == 1 then
					self:StartSchedule( schdMeleeAttack_a )
					self.m_attack = 1
				else
					self:StartSchedule( schdMeleeAttack_b )
					self.m_attack = 2
				end
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
			self.ghide = true
			self:SetEnemy( NULL )
			timer.Create( "self.ghide_reset_timer" .. self.Entity:EntIndex( ), 1, 1, function() self.ghide = false end )
		end
	end
	
	if self.HideCur and CurTime() > self.HideCur then
		self.HideCur = nil
		self:StartSchedule( schdHide )
	end
end

function ENT:Task_Attack_Melee( )
	self:TaskComplete()
end

function ENT:TaskStart_Attack_Melee( )
	self:TaskComplete()
	local function attack_dmg()
		local self_pos = self:GetPos()
		local victim = ents.FindInSphere( self_pos, self.MeleeDistance )

		for k, v in pairs(victim) do
			if( ( ( ( v:IsPlayer() and v:Alive() ) or v:IsNPC() ) and ( self:Disposition( v ) == 1 or self:Disposition( v ) == 2 ) ) or v:GetClass() == "prop_physics" ) then
				if( v:GetClass() != "prop_physics" ) then
					v:EmitSound( "npc/zombie/claw_strike" ..math.random(1,3).. ".wav", 100, 100)
				end
				self.dmg_gotenemy = true
				if v:IsNPC() and v:Health() - sk_hgrunt_kick_value <= 0 then
					self.killicon_ent = ents.Create( "sent_killicon" )
					self.killicon_ent:SetKeyValue( "classname", "sent_killicon_hassassin" )
					self.killicon_ent:Spawn()
					self.killicon_ent:Activate()
					self.killicon_ent:Fire( "kill", "", 0.1 )
					self.attack_inflictor = self.killicon_ent
				else
					self.attack_inflictor = self
				end
				if self.m_attack == 1 then
					v:TakeDamage( sk_hgrunt_kick_double_value, self, self.attack_inflictor )
				else
					v:TakeDamage( sk_hgrunt_kick_value, self, self.attack_inflictor )
				end
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
			end
		end
		if !self.dmg_gotenemy then self:EmitSound( "npc/zombie/claw_miss" ..math.random(1,2).. ".wav", 80, 100) end
		self.dmg_gotenemy = nil
		self.attacking = false
	end
	if self.m_attack == 1 then
		timer.Create( "melee_attack_dmgdelay_timer" .. self.Entity:EntIndex( ), 0.2, 1, attack_dmg )
		timer.Create( "melee_attack_dmgdelay_b_timer" .. self.Entity:EntIndex( ), 0.7, 1, attack_dmg )
		if self.possessed then self.possession_allowdelay = CurTime() +0.8 end
	else
		timer.Create( "melee_attack_dmgdelay_timer" .. self.Entity:EntIndex( ), 0.4, 1, attack_dmg )
		if self.possessed then self.possession_allowdelay = CurTime() +0.5 end
	end
end

function ENT:Reload()
	self.reloading = true
	self:StartSchedule( schdReload )
	self:EmitSound( "hgrunt/gr_reload1.wav", 100, 100 )
	timer.Create( "reload_timer" .. self:EntIndex(), 1.6, 1, function() self.noammo = false; self.reloading = false; self.ammo = self.defammo end )
end

function ENT:ThrowGrenade( poss )
	if !self.possessed and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
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
	
	local function throw_gr()
		if !poss and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
		local grenade_phys = ents.Create( "monster_handgrenade" )
		grenade_phys.owner = self
		grenade_phys.type = "hgrenade"
		grenade_phys:SetModel( "models/weapons/w_eq_fraggrenade_thrown.mdl" )
		grenade_phys:SetOwner( self )
		
		local bone_pos, bone_ang = self:GetBonePosition( self:LookupBone("Bip01 L Hand") )
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
		timer.Create( "gr_atk_reset_timer" .. self:EntIndex(), 0.3, 1, function() self.attacking = false; self.allow_gr = false end )
		timer.Create( "allow_gr_timer" .. self:EntIndex(), math.random(13,19), 1, function() self.allow_gr = true end )
		self.HideCur = CurTime() +0.3
	end
	if poss then self.possession_allowdelay = CurTime() +1.4 end
	timer.Create( "throw_gr" .. self:EntIndex(), 0.6, 1, throw_gr )
end

function ENT:Task_Attack()
	self:TaskComplete()
end

function ENT:TaskStart_Attack()
	self:TaskComplete()
	if !self.possessed and (!self.enemy or !ValidEntity( self.enemy )) then self.attacking = false; return end
	
	self:EmitSound( "weapons/pl_gun" .. math.random(1,2) .. ".wav", 100, 100 )
	local MuzzleAttach = self:LookupAttachment( "0" )
	local AttachAngPos = self:GetAttachment( MuzzleAttach )
		
	local enemy_pos
	if !self.possessed then
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
	self.killicon_ent:SetKeyValue( "classname", "sent_killicon_hassassin" )
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
	bullet.Damage = sk_wep_npc_12mm_value
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
		
	local effectdata = EffectData()
	effectdata:SetStart( AttachAngPos["Pos"] )
	effectdata:SetOrigin( AttachAngPos["Pos"] )
	effectdata:SetScale( 1 )
	util.Effect( "MuzzleEffect", effectdata )
	
	self.attacking = false
	if self.possessed then self.possession_allowdelay = CurTime() +0.18 end
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
function ENT:SelectSchedule( )
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
			if( self.enemy:GetPos():Distance( Pos ) < self.MinDistance and ( ( self.enemy:GetPos():Distance( Pos ) > self.RunMeleeDistance or ( self.enemy:GetPos():Distance( Pos ) <= self.RunMeleeDistance and self.allow_gr ) ) or self.enemy:GetPos():Distance( Pos ) < self.MeleeDistance ) and ( self:HasCondition( 10 ) or self.hadnewenemy ) and !self:HasCondition( 42 ) and self.tr_ent_e ) then
				if( self.enemy:IsNPC() ) then
					self.SetEnemy( self.enemy )
				end
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				if self.enemy:GetPos():Distance( Pos ) > self.MeleeDistance then
					local d = self.enemy:GetPos():Distance( Pos )
					local rand = math.random(1,9)
					if d > self.RunMeleeDistance and ( rand != 3 or !self.allow_gr ) then
						self.attacking = true
						self.idle = 0
						self:StartSchedule( schdAttack )
					elseif d <= self.RunMeleeDistance and rand == 3 and self.allow_gr then
						self.attacking = true
						self.idle = 0
						self:ThrowGrenade()
					end
				else
					if( self.enemy:IsNPC() ) then
						self.SetEnemy( self.enemy )
					end
					if self.schedule_runtarget_pos then self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos ) end
					self.attacking = true
					self.idle = 0
					local rand = math.random(1,2)
					if rand == 1 then
						self:StartSchedule( schdMeleeAttack_a )
						self.m_attack = 1
					else
						self:StartSchedule( schdMeleeAttack_b )
						self.m_attack = 2
					end
				end
			elseif( ( self.following and self.enemy:GetPos():Distance( self.follow_target:GetPos() ) < 800 ) or !self.following ) then
				timer.Destroy( "self_select_schedule_timer" .. self:EntIndex() )
				self:SetEnemy( self.enemy, true )
				if self.schedule_runtarget_pos then
					self:UpdateEnemyMemory( self.enemy, self.schedule_runtarget_pos )
				end
				
				if self.enemy:GetPos():Distance( self:GetPos() ) <= self.RunMeleeDistance +175 then
					self.chaseclose = true
				else
					self.chaseclose = false
				end
				
				if !self.chaseclose then
					local trd = {}
					trd.start = self:GetPos()
					trd.endpos = self:GetCenter( self.enemy )
					trd.filter = {self}
					local tr = util.TraceLine(trd)
					if tr.HitWorld then
						self.chaseclose = true
						self:StartSchedule( schdMoveToLOS )
					else
						self:StartSchedule( schdChase )
					end
				else
					self:StartSchedule( schdChaseClose )
				end
				self.chaseclose = nil
			end
		elseif( ( !self.enemy or !ValidEntity(self.enemy) ) and self.enemy_fear and ValidEntity(self.enemy_fear) and self:HasCondition( 8 ) and !self:HasCondition( 7 ) ) then
			if( self.enemy_fear:IsNPC() ) then
				self:SetEnemy( self.enemy_fear )
			end
			self:UpdateEnemyMemory( self.enemy_fear, self.enemy_fear:GetPos() )
			self:StartSchedule( schdHide ) 
		end
		
		self:SetEnemy( NULL )	
	//elseif( self.idle == 0 and convar_ai == 0 ) then
	//	self.idle = 1
		//self:SetSchedule( SCHED_IDLE_STAND )
	//	self:SelectSchedule()
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
	timer.Destroy( "melee_attack_dmgdelay_b_timer" .. self.Entity:EntIndex( ) )
end