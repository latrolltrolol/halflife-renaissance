AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/scientist.mdl"
ENT.res_time = 0

local schdSitting_a = ai_schedule.New( "Sitting a" )
schdSitting_a:AddTask( "PlaySequence", { Name = "sitting2", Speed = 1 } )

local schdSitting_b = ai_schedule.New( "Sitting b" )
schdSitting_b:AddTask( "PlaySequence", { Name = "sitting3", Speed = 1 } )

local schdStop = ai_schedule.New( "Stop" )
schdStop:EngTask( "TASK_STOP_MOVING", 0 ) 

local schdReset = ai_schedule.New( "Reset" ) 
schdReset:EngTask( "TASK_RESET_ACTIVITY", 0 ) 

local schdBackaway = ai_schedule.New( "Back away" ) 
schdBackaway:EngTask( "TASK_FIND_BACKAWAY_FROM_SAVEPOSITION", 0 ) 

function ENT:DoSchedule( schedule )
	if ( self:TaskFinished() ) then
		self:NextTask( schedule )
	end
  
	if ( self.CurrentTask ) then
		self:RunTask( self.CurrentTask )
	end
end

function ENT:OnTaskComplete()
	self.bTaskComplete = true
	//self:DoSchedule(self.CurrentSchedule)
end

function ENT:Initialize()
	self.table_fear = {}
	self.f_headcrab_table = {}

	self:SetModel( self.Model )

	self:SetHullType( HULL_HUMAN );
	self:SetHullSizeNormal();

	self:SetSolid( SOLID_BBOX )
	self:SetMoveType( MOVETYPE_NONE )

	self:CapabilitiesAdd( CAP_ANIMATEDFACE | CAP_SKIP_NAV_GROUND_CHECK )
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
	
	self:SetPos( self:GetPos() -Vector( 0, 0, 26 ) )
	
	self:SetSchedule( 1 )
	self.init = true
	local function random_seq()
		local rand = math.random( 1,2 )
		if rand == 1 then
			self:StartSchedule( schdSitting_a )
		else
			self:StartSchedule( schdSitting_b )
		end
	end
	random_seq()
	timer.Create( "anim_delay_timer" .. self:EntIndex(), 5, 0, random_seq )
end

function ENT:OnCondition( iCondition )
end

function ENT:Think()
	if GetConVarNumber("ai_disabled") == 1 or self.efficient then return end
end

function ENT:SpawnBloodEffect( bloodtype, dmgPos )
	if dmgPos == Vector( 0, 0, 0 ) then return false end
	local bloodeffect = ents.Create( "info_particle_system" )
	if bloodtype == "red" then self.bloodeffecttype = "blood_impact_red_01" elseif bloodtype == "yellow" then self.bloodeffecttype = "blood_impact_yellow_01" else self.bloodeffecttype = "blood_impact_green_01" end
	
	bloodeffect:SetKeyValue( "effect_name", self.bloodeffecttype )
	bloodeffect:SetPos( dmgPos ) 
	bloodeffect:SetParent( self )
	bloodeffect:Spawn()
	bloodeffect:Activate() 
	bloodeffect:Fire( "Start", "", 0 )
	bloodeffect:Fire( "Kill", "", 0.1 )
	self.bloodeffecttype = nil
	return true
end

function ENT:SpawnRagdoll( damage_force, body )
	local forcepos = self:LocalToWorld( self:OBBCenter() )

	if not util.IsValidRagdoll( self.Model ) then return nil end

	local ragdoll = ents.Create( "prop_ragdoll" )

	ragdoll:SetModel( self:GetModel() )
	ragdoll:SetPos( self:GetPos() )
	ragdoll:SetAngles( self:GetAngles() )
	if body then
		ragdoll:SetKeyValue( "body", body )
		//if self.bodykey_value == 2 then
		//	self:SetSkin( 1 )
		//end
	end
	ragdoll:Spawn()

			
	if not ragdoll:IsValid() then return nil end

	local entvel
	local entphys = self:GetPhysicsObject()
	if entphys:IsValid() then
		entvel = entphys:GetVelocity()
	else
		entvel = self:GetVelocity()
	end


	for i=1,128 do
		local bone = ragdoll:GetPhysicsObjectNum( i )
		if ValidEntity( bone ) then
			local bonepos, boneang = self:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )

			bone:SetPos( bonepos )
			bone:SetAngle( boneang )

			bone:ApplyForceOffset( damage_force /3, forcepos )
			bone:AddVelocity( entvel )
		end
	end
	ragdoll:SetSkin( self:GetSkin() )
	ragdoll:SetColor( self:GetColor() )
	ragdoll:SetMaterial( self:GetMaterial() )
	if self:IsOnFire() then ragdoll:Ignite( math.Rand( 8, 10 ), 0 ) end
	local cvar_keepragdolls = GetConVarNumber("ai_keepragdolls")
	if( cvar_keepragdolls == 0 ) then
		ragdoll:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		ragdoll:Fire( "FadeAndRemove", "", 0.2 )
	else
		ragdoll:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE_DEBRIS )
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
	
		/*self.damage_count = self.damage_count +1
		if( self.damage_count == 6 ) then
			self:SetCondition( 20 )
		end
		timer.Create( "damage_count_reset_timer" .. self.Entity:EntIndex( ), 1.5, 1, function() self.damage_count = 0 end )*/
	end
	
	if( self.damage_count == 3 or self:HasCondition( 18 ) and self.pain == 1 ) then
		//self:StartSchedule( schdHurt )
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
end

function ENT:GetSpawnflag( value )
	local spawnflags = { 131072, 65536, 32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1 }
	if !table.HasValue( spawnflags, value ) then return false end
	return true
end

function ENT:KeyValue( key, value )
	if( key == "health" ) then
		self.health = value
	end
	
	if( key == "body" ) then
		self.bodykey_v = value
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
end

function ENT:SpeakSentence( spksentence, speaker, listener, sradius, volume, attenuation, once, interrupt, concurrent, toactivator )
	local sentence = ents.Create( "scripted_sentence" )
	sentence:SetPos( self:GetPos() )
	sentence:SetKeyValue( "sentence", spksentence )
	if speaker:GetName() == "" then
		self.sentence_ent = speaker:GetClass()
	else
		self.sentence_ent = speaker:GetName()
	end
	sentence:SetKeyValue( "entity", self.sentence_ent )

	if listener:GetName() != "" and !listener:IsPlayer() then
		self.sentence_listener = listener:GetName()
	elseif listener:IsPlayer() then
		self.sentence_listener = "player"
	else
		self.sentence_listener = listener:GetClass()
	end
	sentence:SetKeyValue( "listener", self.sentence_listener )
	sentence:SetKeyValue( "radius", sradius )
	sentence:SetKeyValue( "volume", volume )
	sentence:SetKeyValue( "attenuation", attenuation )
	self.sentence_spawnflags = 0
	if once then
		self.sentence_spawnflags = self.sentence_spawnflags +1
	end
	if interrupt then
		self.sentence_spawnflags = self.sentence_spawnflags +4
	end
	if concurrent then
		self.sentence_spawnflags = self.sentence_spawnflags +8
	end
	if toactivator then
		self.sentence_spawnflags = self.sentence_spawnflags +16
	end
	sentence:SetKeyValue( "spawnflags", self.sentence_spawnflags )
	
	sentence:Spawn()
	sentence:Activate()
	sentence:Fire( "BeginSentence", "", 0.1 )
	self.sentence_spawnflags = nil
end

/*---------------------------------------------------------
Name: OnRemove
Desc: Called just before entity is deleted
//-------------------------------------------------------*/
function ENT:OnRemove()
	timer.Destroy( "anim_delay_timer" .. self:EntIndex() )
	timer.Destroy( "damage_count_reset_timer" .. self.Entity:EntIndex( ) )
end