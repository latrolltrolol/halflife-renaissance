
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.Model = "models/w_tripmine.mdl"

function ENT:Initialize()
	self:SetModel( self.Model )
	self:PhysicsInit( SOLID_NONE )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	self:SetHealth(1)
	
	self:EmitSound( "weapons/mine_charge.wav", 100, 100 )
	self.active_delay = CurTime() +3.2
	self:SetName( tostring(self) .. "_tripmine" .. self:EntIndex() )
end

function ENT:Think()
	if !self.active and CurTime() > self.active_delay then
		local pos = self:GetPos()
		local tracedata = {}
		tracedata.start = pos
		tracedata.endpos = pos +self:GetForward() *8000
		tracedata.filter = self
		local trace_beamtarget = util.TraceLine(tracedata)
		if trace_beamtarget.HitWorld or ( ValidEntity( trace_beamtarget.Entity ) and string.find( trace_beamtarget.Entity:GetClass(), "func_" ) ) then
			self.beamendpos = trace_beamtarget.HitPos
		elseif ValidEntity( trace_beamtarget.Entity ) then
			self.beamendpos = trace_beamtarget.HitPos
			self:Fire( "Explode", "", 0.5 )
		else
			self:Explode()
			self.active = true
			return
		end
		self.beam = ents.Create( "env_beam" )
		self.beam:SetKeyValue( "life", "0" )
		self.beam:SetKeyValue( "BoltWidth", "1" )
		self.beam:SetKeyValue( "NoiseAmplitude", "0" )
		self.beam:SetKeyValue( "damage", "0" )
		self.beam:SetKeyValue( "TouchType", "4" )
		self.beam:SetKeyValue( "Spawnflags", "1" )
		self.beam:SetKeyValue( "texture", "sprites/bluelaser1.spr" )
			
		self.beamtarget = ents.Create( "info_target" )
		self.beamtarget:SetName( "Tripmine" .. self:EntIndex() .. "_target" )
		self.beamtarget:SetPos( self.beamendpos )
		self.beamtarget:Spawn()
		self.beamtarget:Activate()
			
		self.beam:SetPos( self:GetPos() )
		self.beam:SetName( "Tripmine" .. self:EntIndex() .. "_beam" )
		self.beam:SetKeyValue( "LightningStart", "Tripmine" .. self:EntIndex() .. "_beam" )
		self.beam:SetKeyValue( "LightningEnd", "Tripmine" .. self:EntIndex() .. "_target" )
		self.beam:Spawn()
		self.beam:Activate()
		self.beam:Fire( "AddOutput", "OnTouchedByEntity " .. self:GetName() .. ":Explode::0:1", 0 )
		
		self.active = true
		self:EmitSound( "weapons/mine_activate.wav", 100, 100 )
		self:SetSolid( SOLID_BBOX )
		self:SetCollisionBounds( Vector( 2, -8, 3 ), Vector( -8, 12, -5 ) )	
	end
end

function ENT:Explode()
	local vPoint = self:GetPos()
	local effectdata = EffectData()
	effectdata:SetStart( vPoint )
	effectdata:SetOrigin( vPoint )
	effectdata:SetScale( 1 )
	if self:WaterLevel() != 3 then
		self:EmitSound( "weapons/explode" .. math.random(3,5) .. ".wav", 100, 100 )
		util.Effect( "HelicopterMegaBomb", effectdata ) 
	else
		util.Effect( "WaterSurfaceExplosion", effectdata ) 
	end
	if self.owner and ValidEntity( self.owner ) then
		util.BlastDamage( self, self.owner, self:GetPos(), 350, sk_wep_tripmine_value )
	else
		util.BlastDamage( self, self, self:GetPos(), 350, sk_wep_tripmine_value )
	end
	
	local tracedata = {}
	tracedata.start = self:GetPos()
	tracedata.endpos = self:GetPos() -Vector( 0, 0, 25 )
	tracedata.filter = self
	local trace = util.TraceLine(tracedata)
	if trace.HitWorld then
		util.Decal("Scorch",trace.HitPos +trace.HitNormal,trace.HitPos -trace.HitNormal)  
	end 
	
	self:Remove()
end

function ENT:AcceptInput( cvar_name, activator, caller )
	if cvar_name == "Explode" then
		self:Explode()
	end
end

function ENT:OnTakeDamage(dmg)
	self:SetHealth(self:Health() - dmg:GetDamage())

	if( self:Health() <= 0 and !self.explode ) then //run on death
		self.explode = true
		self:Explode()
	end
end

function ENT:OnRemove()
	if ValidEntity( self.beamtarget ) then self.beamtarget:Remove() end
	if ValidEntity( self.beam ) then self.beam:Remove() end
end