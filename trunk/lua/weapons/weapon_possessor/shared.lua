SWEP.Author = "Silverlan"
SWEP.Contact = "Silverlan@gmx.de"
SWEP.Purpose = "Take control over a NPC"
SWEP.Instructions = "Aim at a NPC and use primary fire to possess it. Use jump key to stop the possession. More instructions are in the readme."

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/v_hgun.mdl"
SWEP.WorldModel = "models/w_hgun.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

local possess_snpcs = { "monster_houndeye", "monster_bullchicken", "monster_alien_grunt", "monster_gargantua", "monster_cockroach", "monster_panthereye", "monster_alien_slave", "monster_headcrab", "monster_zombie", "monster_babycrab", "monster_human_grunt", "monster_human_assassin", "monster_parasite", "monster_bigmomma" }
local possess_npcs = { "npc_zombine", "npc_zombie", "npc_zombie_torso", "npc_fastzombie", "npc_fastzombie_torso", "npc_poisonzombie", "npc_headcrab", "npc_headcrab_black", "npc_headcrab_poison", "npc_headcrab_fast", "npc_antlionguard", "npc_antlion", "npc_antlion_worker", "npc_vortigaunt" }

function SWEP:Initialize()
	if SERVER then
		self.Weapon:SetWeaponHoldType("smg")
	end
end

/*---------------------------------------------------------
Reload does nothing
---------------------------------------------------------*/
function SWEP:Reload()
end


/*---------------------------------------------------------
Think
---------------------------------------------------------*/
function SWEP:Think()
end

/*---------------------------------------------------------
   Name: GetCapabilities
   Desc: For NPCs, returns what they should try to do with it.
---------------------------------------------------------*/
function SWEP:GetCapabilities()
	return false
end

function SWEP:Possess( ent, NPC )
	ent.possessed = true
	ent.master = self.Owner
	
	if NPC then
		local possess_ent = ents.Create( "sent_possess" )
		possess_ent.target = ent
		possess_ent.master = self.Owner
		possess_ent:Spawn()
		possess_ent:Activate()
	end
	
	local viewent_pos = ent:LocalToWorld( ent.possess_viewpos )
	local viewent = ents.Create( "sent_killicon" )
	viewent:SetPos( viewent_pos )
	viewent:SetAngles( (ent:GetPos() -viewent_pos +ent.possess_addang):Angle() )
	viewent:SetParent( ent )
	viewent:Spawn()
	viewent:Activate()

	self.Owner:SetViewEntity( viewent )
	self.Owner:GetTable().frozen = true
	self.Owner:KillSilent()
end

/*---------------------------------------------------------
PrimaryAttack
---------------------------------------------------------*/
function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.2)
	if CLIENT then return end
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = pos+(ang*8000)
	tracedata.filter = self.Owner
	local trace = util.TraceLine(tracedata) 
	if trace.Entity and ValidEntity( trace.Entity ) and trace.Entity:Health() > 0 then
		local targetnpc_class = trace.Entity:GetClass()
		if table.HasValue( possess_snpcs, targetnpc_class ) then
			self:Possess( trace.Entity )
		elseif table.HasValue( possess_npcs, targetnpc_class ) then
			self:Possess( trace.Entity, true )
		elseif !table.HasValue( possess_snpcs, targetnpc_class ) and !table.HasValue( possess_npcs, targetnpc_class ) then
			self.Owner:PrintMessage( HUD_PRINTTALK, "You can't possess this NPC!" )
		end
	end
	
	local trace = util.TraceLine(tracedata)
end

/*---------------------------------------------------------
SecondaryAttack
---------------------------------------------------------*/
function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 0.1)
end 

function SWEP:OnRemove( )
end
