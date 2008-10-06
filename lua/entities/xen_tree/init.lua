
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	local SpawnPos = (tr.HitPos + tr.HitNormal * 16) -Vector( 0, 0, 17 )
	self.Spawn_angles = ply:GetAngles()
	self.Spawn_angles.pitch = 0
	self.Spawn_angles.roll = 0
	self.Spawn_angles.yaw = self.Spawn_angles.yaw + 180
	
	local ent = ents.Create( "xen_tree" )
	ent:SetPos( SpawnPos )
	ent:SetAngles( self.Spawn_angles )
	ent:Spawn()
	ent:Activate()
	
	
	return ent
end

function ENT:Initialize()
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_BBOX )
	
	self:SetModel( "models/props_junk/watermelon01_chunk02c.mdl" )
	self:SetColor( 255, 255, 255, 0 )
	self:DrawShadow( false )
	
	self.tree = ents.Create( "prop_dynamic_override" )
	self.tree:SetModel( "models/tree.mdl" )
	self.tree:SetKeyValue( "DefaultAnim", "idle1" )
	self.tree:SetPos( self:GetPos() )
	self.tree:SetAngles( self:GetAngles() )
	self.tree:Spawn()
	self.tree:Activate()
	self.tree:SetParent( self )
	
	self:SetCollisionBounds( Vector( -20, 22, 0 ), Vector( 28, -22, 190 ) )	
end

function ENT:CheckTable( tb )
	for k, v in pairs( tb ) do
		if ( v:IsNPC() or v:IsPlayer() ) and v:Health() > 0 then self.tb_v = true end
	end
	if self.tb_v then self.tb_v = false; return true else return false end
end

function ENT:EnemyInBox( enemy )
	local ents = ents.FindInBox( self:LocalToWorld( Vector( 28, 21, 4 ) ), self:LocalToWorld( Vector( 105, -21, 84 ) ) )
	for k, v in pairs( ents ) do
		if v == enemy then self.eb = true end
	end
	if self.eb then self.eb = false; return true else return false end
end

function ENT:Think()
	if self.attacking then return end
	local ents = ents.FindInBox( self:LocalToWorld( Vector( 28, 21, 4 ) ), self:LocalToWorld( Vector( 105, -21, 84 ) ) )
	if table.Count( ents ) == 0 or !self:CheckTable( ents ) then return end
	self.attacking = true
	self.tree:Fire( "SetAnimation", "attack", 0 )
	local function enemy_dmg()
		for k, v in pairs( ents ) do
			if self:EnemyInBox( v ) and ( v:IsNPC() or v:IsPlayer() ) and v:Health() > 0 then
				if v:IsPlayer() then
					v:ViewPunch( Angle( 12, math.random(-4,4), 0  ) )
				end
				v:TakeDamage( 23, self, self )
				v:EmitSound( "npc/zombie/claw_strike" ..math.random(1,3).. ".wav", 100, 100)
				self.gotenemy = true
			end
		end
		if !self.gotenemy then
			self:EmitSound( "npc/zombie/claw_miss" ..math.random(1,2).. ".wav", 100, 100)
		end
		self.gotenemy = false
	end
	timer.Create( "enemy_tk_dmg_timer" .. self:EntIndex(), 0.35, 1, enemy_dmg )
	timer.Create( "attacking_reset_timer" .. self:EntIndex(), 1.165, 1, function() self.attacking = false; self:Fire( "SetAnimation", "idle1", 0 ); self:Fire( "SetDefaultAnimation", "idle1", 0 ) end )
end

function ENT:OnRemove()
	self.tree:Remove()
	timer.Destroy( "enemy_tk_dmg_timer" .. self:EntIndex() )
	timer.Destroy( "attacking_reset_timer" .. self:EntIndex() )
end
