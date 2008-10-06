AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()
	self:SetModel( "models/props_junk/watermelon01_chunk02c.mdl" )
	self:SetColor( 255, 255, 255, 0 )
	
	local class = self.target:GetClass()
	if class == "npc_zombine" then
		self.target.possess_viewpos = Vector( -80, 0, 100 )
		self.target.possess_addang = Vector(0,0,65)
		self.primattack_a = true
		self.primattack_a_delay = 1.2
		self.secattack_a = true
		self.secattack_a_delay = 4
		self.movedist = 65
	elseif class == "npc_zombie" then
		self.target.possess_viewpos = Vector( -80, 0, 100 )
		self.target.possess_addang = Vector(0,0,65)
		self.primattack_a = true
		self.primattack_a_delay = 1.2
		self.movedist = 65
	elseif class == "npc_zombie_torso" or class == "npc_fastzombie_torso" then
		self.target.possess_viewpos = Vector( -80, 0, 50 )
		self.target.possess_addang = Vector(0,0,45)
		self.primattack_a = true
		self.primattack_a_delay = 0.9
		self.movedist = 65
	elseif class == "npc_fastzombie" then
		self.target.possess_viewpos = Vector( -80, 0, 100 )
		self.target.possess_addang = Vector(0,0,65)
		self.primattack_a = true
		self.primattack_a_delay = 2.6
		self.secattack_a = true
		self.secattack_a_delay = 2
		self.movedist = 200
	elseif class == "npc_poisonzombie" then
		self.target.possess_viewpos = Vector( -80, 0, 100 )
		self.target.possess_addang = Vector(0,0,65)
		self.primattack_a = true
		self.primattack_a_delay = 1.8
		self.secattack_a = true
		self.secattack_a_delay = 3
		self.movedist = 65
	elseif class == "npc_headcrab" then
		self.target.possess_viewpos = Vector( -75, 0, 32 )
		self.target.possess_addang = Vector(0,0,22)
		self.primattack_a = true
		self.primattack_a_delay = 1.6
		self.secattack_a = true
		self.secattack_a_delay = 2
		self.movedist = 65
	elseif class == "npc_headcrab_fast" then
		self.target.possess_viewpos = Vector( -75, 0, 32 )
		self.target.possess_addang = Vector(0,0,22)
		self.primattack_a = true
		self.primattack_a_delay = 1
		self.movedist = 175
	elseif class == "npc_headcrab_black" or class == "npc_headcrab_poison" then
		self.target.possess_viewpos = Vector( -75, 0, 32 )
		self.target.possess_addang = Vector(0,0,22)
		self.primattack_a = true
		self.primattack_a_delay = 1.8
		self.movedist = 65
	elseif class == "npc_antlionguard" then
		self.target.possess_viewpos = Vector( -75, 0, 120 )
		self.target.possess_addang = Vector(0,0,95)
		self.primattack_a = true
		self.primattack_a_delay = 1.8
		self.movedist = 200
	elseif class == "npc_antlion" then
		self.target.possess_viewpos = Vector( -75, 0, 100 )
		self.target.possess_addang = Vector(0,0,65)
		self.primattack_a = true
		self.primattack_a_delay = 0.8
		self.movedist = 200
	elseif class == "npc_antlion_worker" then
		self.target.possess_viewpos = Vector( -75, 0, 100 )
		self.target.possess_addang = Vector(0,0,65)
		self.primattack_a = true
		self.primattack_a_delay = 0.8
		self.secattack_a = true
		self.secattack_a_delay = 1.8
		self.movedist = 200
	elseif class == "npc_vortigaunt" then
		self.target.possess_viewpos = Vector( -80, 0, 100 )
		self.target.possess_addang = Vector(0,0,65)
		self.primattack_a = true
		self.primattack_a_delay = 1.4
		self.secattack_a = true
		self.secattack_a_delay = 3
		self.secattack_b = true
		self.secattack_b_delay = 3
		self.movedist = 120
	end
	
	
end

function ENT:AddAttackDelay( delay )
	self.possession_allowdelay = CurTime() +delay
end

function ENT:Think()
	if !self.target or !ValidEntity( self.target ) or self.target:Health() <= 0 then
		self:EndPossession()
		return
	end
	if self.target:GetNPCState() != 0 then self.target:SetNPCState( 0 ) end
	if (!self.possession_allowdelay or ( self.possession_allowdelay and CurTime() > self.possession_allowdelay )) and !self.targetisburrowed then
		self.possession_allowdelay = nil
		self:PossessMovement( self.movedist )
		if !self.master then return end
		if self.master:KeyDown( 1 ) then
			if self.primattack_a and (!self.master:KeyDown( 4 ) or !self.primattack_b) then
				self:ChooseSchedule( true )
			elseif self.master:KeyDown( 4 ) and self.primattack_b then
				self:ChooseSchedule( false, true )
			end
		elseif self.master:KeyDown( 2048 ) then
			if self.secattack_a and (!self.master:KeyDown( 4 ) or !self.secattack_b) then
				self:ChooseSchedule( false, false, true )
			elseif self.master:KeyDown( 4 ) and self.secattack_b then
				self:ChooseSchedule( false, false, false, true )
			end
		end
	elseif self.targetisburrowed and self.master:KeyDown( 2048 ) then
		self:AddAttackDelay( self.secattack_a_delay )
		self.targetisburrowed = false
		self.target:Fire( "unburrow", "", 0 )
	end
end 

function ENT:ChooseSchedule( primattack_a, primattack_b, secattack_a, secattack_b )
	local class = self.target:GetClass()
	if class == "npc_zombine" or class == "npc_zombie" or class == "npc_zombie_torso" or class == "npc_fastzombie_torso" then
		if primattack_a then
			self:AddAttackDelay( self.primattack_a_delay )
			self.target:SetSchedule( 41 )
		elseif secattack_a then
			self:AddAttackDelay( self.secattack_a_delay )
			self.target:Fire( "PullGrenade", "", 0 )
		end
	elseif class == "npc_fastzombie" then
		if primattack_a then
			self:AddAttackDelay( self.primattack_a_delay )
			self.target:SetSchedule( 41 )
		elseif secattack_a then
			self:AddAttackDelay( self.secattack_a_delay )
			self.target:SetSchedule( 43 ) 
			self.target:SetLocalVelocity( self.target:GetForward() *1200 +Vector(0,0,280) )
		end
	elseif class == "npc_poisonzombie" or class == "npc_antlionguard" then
		if primattack_a then
			self:AddAttackDelay( self.primattack_a_delay )
			self.target:SetSchedule( 41 )
		elseif secattack_a then
			self:AddAttackDelay( self.secattack_a_delay )
			self.target:SetSchedule( 43 )
		end
	elseif class == "npc_headcrab" then
		if primattack_a then
			self:AddAttackDelay( self.primattack_a_delay )
			self.target:SetSchedule( 43 )
			//self.target:SetLocalVelocity( self.target:GetForward() *500 +Vector(0,0,240) )
		elseif secattack_a then
			self:AddAttackDelay( self.secattack_a_delay )
			self.targetisburrowed = true
			self.target:Fire( "burrowimmediate", "", 0 )
		end
	elseif class == "npc_headcrab_fast" or class == "npc_headcrab_black" or class == "npc_headcrab_poison" then
		if primattack_a then
			self:AddAttackDelay( self.primattack_a_delay )
			self.target:SetSchedule( 43 )
		end
	elseif class == "npc_antlion" then
		if primattack_a then
			self:AddAttackDelay( self.primattack_a_delay )
			self.target:SetSchedule( 41 )
		end
	elseif class == "npc_antlion_worker" then
		if primattack_a then
			self:AddAttackDelay( self.primattack_a_delay )
			self.target:SetSchedule( 41 )
		elseif secattack_a then
			self:AddAttackDelay( self.secattack_a_delay )
			self.target:SetSchedule( 43 )
		end
	elseif class == "npc_vortigaunt" then
		if primattack_a then
			self:AddAttackDelay( self.primattack_a_delay )
			self.target:SetSchedule( 41 )
		elseif secattack_a then
			self:AddAttackDelay( self.secattack_a_delay )
			self.target:SetSchedule( 43 )
		elseif secattack_b then
			self:AddAttackDelay( self.secattack_b_delay )
			local playerinrange
			for k, v in pairs( ents.FindInSphere( self.target:GetPos(), 256 ) ) do
				if ValidEntity( v ) and v:IsPlayer() and v:Health() > 0 then
					playerinrange = true
				end
			end
			if playerinrange then
				self.target:Fire( "enablearmorrecharge", "", 0 )
				self.target:Fire( "ChargeTarget", "!player", 0.1 )
			end
		end
	end
end

function ENT:PossessMovement( movedist )
	if self.master:KeyDown( 2 ) then
		self.target:SetNPCState( 1 )
		self:EndPossession()
		return
	end
	local function MoveToTargetPos( pos, walk )
		local movetarget = ents.Create( "info_target" )
		movetarget:SetPos( pos )
		movetarget:Spawn()
		movetarget:Activate()
		self.target:SetLastPosition( movetarget:GetPos() )
		
		if !walk then
			self.target:SetSchedule( SCHED_FORCED_GO_RUN )
		else
			self.target:SetSchedule( SCHED_FORCED_GO )
		end
		self.target:SetSchedule( SCHED_FORCED_GO_RUN )
		movetarget:Fire( "Kill", "", 1 )
	end
	if self.master:KeyDown( 8 ) then
		local targetpos 
		local trace = {}
		trace.start = self.target:GetPos()
		trace.endpos = self.target:LocalToWorld( Vector( movedist, 0, 10 ) )
		trace.filter = self.target

		local tr = util.TraceLine( trace ) 
		if tr.HitWorld then
			targetpos = tr.HitPos
		else
			targetpos = self.target:GetPos() +self.target:GetForward() *movedist
		end
		if self.master:KeyDown( 512 ) then
			targetpos = targetpos +self.target:GetRight() *-1 *50
		elseif self.master:KeyDown( 1024 ) then
			targetpos = targetpos +self.target:GetRight() *50
		end
		local walk = false
		if self.master:KeyDown( 262144 ) then walk = true end
		MoveToTargetPos( targetpos, walk )
	elseif self.master:KeyDown( 512 ) then
		MoveToTargetPos( self.target:GetPos() +self.target:GetRight() *-1 *1.3 +self.target:GetForward() *4 )
	elseif self.master:KeyDown( 1024 ) then
		MoveToTargetPos( self.target:GetPos() +self.target:GetRight() *1.3 +self.target:GetForward() *4 )
	end
end

function ENT:EndPossession()
	self.possession_allowdelay = nil
	if self.master and ValidEntity( self.master ) then self.master:GetTable().frozen = false; self.master:Spawn(); self.master:SetViewEntity( self.master ) end
	self.master = nil
	self:Remove()
end

function ENT:OnRemove()
end
