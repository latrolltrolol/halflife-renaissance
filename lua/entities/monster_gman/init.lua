AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/hlgm.mdl"

ENT.res_time = 0

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
	self:SetMoveType( MOVETYPE_STEP )

	self:CapabilitiesAdd( CAP_SKIP_NAV_GROUND_CHECK | CAP_ANIMATEDFACE )
	self:SetMaxYawSpeed( 5000 )

	if !self.health then
		self:SetHealth(1200)
	end

	self.enemyTable_nt = { "npc_gman", "npc_antlion", "npc_antlion_worker", "npc_combine_s", "npc_hunter", "npc_rollermine", "npc_turret_floor", "npc_alyx", "npc_barney", "npc_citizen", "npc_metropolice", "npc_vortigaunt", "npc_antlionguard", "npc_fastzombie_torso", "npc_fastzombie", "npc_headcrab", "npc_headcrab_black", "npc_headcrab_poison", "npc_headcrab_fast", "npc_poisonzombie", "npc_zombie", "npc_zombie_torso", "npc_zombine", "npc_stalker", "npc_clawscanner", "npc_cscanner", "npc_manhack", "npc_monk", "npc_breen", "npc_dog", "npc_eli", "npc_fisherman", "npc_kleiner", "npc_magnusson", "npc_mossman", "monster_generic", "monster_alien_controller", "monster_alien_grunt", "monster_babycrab", "monster_barney", "monster_bigmomma", "monster_bullchicken", "monster_gargantua", "monster_headcrab", "monster_houndeye", "monster_panthereye", "monster_scientist", "monster_sitting_scientist", "monster_snark", "monster_tentacle", "monster_zombie", "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }
	
	self.enemyTable_enemies_e = {}
	
	self:SetSchedule( 1 )
	self.init = true
end

function ENT:Think()
	if GetConVarNumber("ai_disabled") == 1 or self.efficient then return end
	local players = player.GetAll( )
	for k, v in pairs( players ) do
		if v:GetPos():Distance( self:GetPos() ) < 100 and v:KeyDown( IN_USE ) and v:GetEyeTrace().Entity == self then
			self:Use( v, v )
		end
	end
	
	for k, v in pairs( self.enemyTable_nt ) do
		local enemyTable_enemies_fr = ents.FindByClass( v )
		for k, v in pairs( enemyTable_enemies_fr ) do
			if( !table.HasValue( self.enemyTable_enemies_e, v ) ) then
				table.insert( self.enemyTable_enemies_e, v )
				v:AddEntityRelationship( self, 4, 10 )
				self:AddEntityRelationship( v, 4, 10 )
			end
		end
	end
	
	if self:GetActivity() == 1 and self.res_time < CurTime() and !self.following and !self.FoundEnemy_fear then
		self:SetSchedule( 4 )
		self.res_time = CurTime() +1
	end
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

function ENT:OnTakeDamage(dmg)
	self:SetHealth(self:Health() - dmg:GetDamage())
	local damage = dmg:GetDamage()

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
	end
end

/*---------------------------------------------------------
 Name: SelectSchedule
//-------------------------------------------------------*/
function ENT:SelectSchedule()
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

function ENT:GmanRandomSpeech()
	local rand = math.random(1,10)
	if rand == 1 then
		self.spkspeech_s = "!GM_SUIT"
	elseif rand == 2 then
		self.spkspeech_s = "!GM_NASTY"
	elseif rand == 3 then
		self.spkspeech_s = "!GM_POTENTIAL"
	elseif rand == 4 then
		self.spkspeech_s = "!GM_STEPIN"
	elseif rand == 5 then
		self.spkspeech_s = "!GM_OTHERWISE"
	elseif rand == 6 then
		self.spkspeech_s = "!GM_1CHOOSE"
	elseif rand == 7 then
		self.spkspeech_s = "!GM_2CHOOSE"
	elseif rand == 8 then
		self.spkspeech_s = "!GM_WISE"
	elseif rand == 9 then
		self.spkspeech_s = "!GM_REGRET"
	else
		self.spkspeech_s = "!GM_WONTWORK"
	end
end

function ENT:Use( activator, caller )
	if !self.plyused then
		self.plyused = true
		self:GmanRandomSpeech()
		self:SpeakSentence( self.spkspeech_s, self, activator, 10, 10, 1, true, true, false, true )
		timer.Create( "self.plyused_reset_timer" .. self:EntIndex(), 7, 1, function() self.plyused = false end )
	end
end

/*---------------------------------------------------------
Name: OnRemove
Desc: Called just before entity is deleted
//-------------------------------------------------------*/
function ENT:OnRemove()
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
end