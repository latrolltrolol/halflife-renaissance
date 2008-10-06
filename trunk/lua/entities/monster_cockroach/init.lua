AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

////// DONT CHANGE ANYTHING BELOW THIS!!!
ENT.Model = "models/roach.mdl"
ENT.MinDistance		= 235

ENT.wander = 0
ENT.CheckWorld = false

ENT.SpawnRagdollOnDeath = false
ENT.RemoveOnDeath = true
ENT.BloodType = "yellow"
ENT.DeathSound = "roach/rch_die.wav"
ENT.DeathSoundCount = 1
ENT.Pain = false
ENT.PrintDeathDecal = true

local schdWait = ai_schedule.New( "Wait" )
schdWait:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 )

local schdHide = ai_schedule.New( "Hide" ) 
schdHide:EngTask( "TASK_FIND_COVER_FROM_ENEMY", 0 ) 
schdHide:EngTask( "TASK_WAIT_FOR_MOVEMENT", 0 ) 
schdHide:AddTask( "FinishedHide" )

local schdReset = ai_schedule.New( "Reset" ) 
schdReset:EngTask( "TASK_RESET_ACTIVITY", 0 ) 

local schdWander = ai_schedule.New( "Wander" ) 
schdWander:EngTask( "TASK_GET_PATH_TO_RANDOM_NODE", 45 )
schdWander:EngTask( "TASK_WALK_PATH", 0 ) 

function ENT:Initialize()
	if( turret_index_table == nil ) then
		turret_index_table = {}
	end
	self.table_fear = {}

	self:SetModel( self.Model )

	self:SetHullType( HULL_TINY );
	self:SetHullSizeNormal();

	//self:SetSolid( SOLID_NONE )
	self:SetSolid( SOLID_BBOX )
	self:SetCollisionBounds( Vector( -8, 16, 0 ), Vector( 8, -16, 4 ) )	
	self:SetMoveType( MOVETYPE_STEP )

	self:CapabilitiesAdd( CAP_MOVE_GROUND )

	self:SetMaxYawSpeed( 5000 )
	
	if !self.health then
		self:SetHealth(2)
	end

	self:SetUpEnemies( )
	self.enemyTable_fear = { "npc_combinedropship", "npc_combinegunship", "npc_helicopter", "npc_strider", "npc_sniper" }
	for k, v in pairs( self.enemyTable ) do
		table.insert( self.enemyTable_fear, v )
	end
	self.enemeyTable = nil
	
	self:SetSchedule( 1 )
	
	self.enemyTable_enemies_e = {}
	self.wanderdelay = CurTime()
	
	self.walksound = CreateSound( self, "roach/rch_walk.wav" )
	
	self.possess_viewpos = Vector( -38, 0, 30 )
	self.possess_addang = Vector(0,0,20)
end

function ENT:TaskStart_FinishedHide()
	self.hiding = false
	self:TaskComplete()
end 

function ENT:Task_FinishedHide()
	self:TaskComplete()
end

function ENT:OnCondition( iCondition )
end

function ENT:Think()
	for k, v in pairs( ents.FindInSphere( self:GetPos(), 12 ) ) do
		if ValidEntity( v ) and v:GetClass() != "monster_cockroach" and ( ( ( ( v:IsNPC() or v:IsPlayer() ) and v:Health() > 0 ) ) or ValidEntity( v:GetPhysicsObject( ) ) ) then
			self:SetPos( Vector( self:GetPos().x, self:GetPos().y, self:GetPos().z +4 ) )
			self:SpawnBloodEffect( "yellow", self:OBBCenter() )
			self:SpawnBloodDecal( "YellowBlood", { self, v } )
			self:EmitSound( "roach/rch_smash.wav", 100, 100 )
			self:Remove()
		end
	end

	if GetConVarNumber("ai_disabled") == 1 or self.efficient then return end
	for k, v in pairs( self.enemyTable_fear ) do
		local enemyTable_enemies_fr = ents.FindByClass( v )
		for k, v in pairs( enemyTable_enemies_fr ) do
			if( !table.HasValue( self.enemyTable_enemies_e, v ) ) then
				table.insert( self.enemyTable_enemies_e, v )
				if !v:IsPlayer() then
					v:AddEntityRelationship( self, 4, 10 )
				end
				self:AddEntityRelationship( v, 2, 10 )
			end
		end
	end
	
	if self.possessed and ( !self.possession_allowdelay or ( self.possession_allowdelay and CurTime() > self.possession_allowdelay ) ) then
		self:PossessMovement( 80 )
	end
end

/*---------------------------------------------------------
 Name: SelectSchedule
//-------------------------------------------------------*/
function ENT:SelectSchedule()
	local convar_ai = GetConVarNumber("ai_disabled")
	if self.efficient or convar_ai == 1 or self.possessed or self.hiding then return end
	
	if !self.SearchDelay then self.SearchDelay = CurTime() +0.2; return end
	self.SearchDelay = nil
	for k, v in pairs( self.enemyTable_fear ) do
		for k, v in pairs ( ents.FindByClass( v ) ) do
			if ValidEntity( v ) and v:Health() > 0 and self:GetPos():Distance( v:GetPos() ) < 128 then
				self.hiding = true
				self.walksound:Stop()
				self.walksound:Play()
				self:StartSchedule( schdHide ) 
				return
			end
		end
	end
	
	if !self.wanderdelay then self.wanderdelay = CurTime() +math.Rand(4,7) end
	if CurTime() > self.wanderdelay then
		self.wanderdelay = nil
		self:StartSchedule( schdWander )
		self.walksound:Stop()
		self.walksound:Play()
	end
	self:SetEnemy( NULL )	
end 

/*---------------------------------------------------------
Name: OnRemove
Desc: Called just before entity is deleted
//-------------------------------------------------------*/
function ENT:OnRemove()
	self:EndPossession()
end