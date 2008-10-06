// ALIEN CONTROLLER
function sk_controller_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_controller_health_value = v
		end
	end
end 
concommand.Add( "sk_controller_health", sk_controller_health )

sk_controller_health_value = 170

function sk_controller_attack_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_controller_attack_value = v
		end
	end
end 
concommand.Add( "sk_controller_dmgball", sk_controller_attack_dmg )

sk_controller_attack_value = 12

function sk_controller_fly_speed( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_controller_fly_speed_value = v
		end
	end
end 
concommand.Add( "sk_controller_fly_speed", sk_controller_fly_speed )

sk_controller_fly_speed_value = 45

// ALIEN GRUNT
function sk_agrunt_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_agrunt_health_value = v
		end
	end
end 
concommand.Add( "sk_agrunt_health", sk_agrunt_health )

sk_agrunt_health_value = 190

function sk_agrunt_slash_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_agrunt_slash_value = v
		end
	end
end 
concommand.Add( "sk_agrunt_dmg_punch", sk_agrunt_slash_dmg )

sk_agrunt_slash_value = 26

// BABYCRAB
function sk_babycrab_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_babycrab_health_value = v
		end
	end
end 
concommand.Add( "sk_babycrab_health", sk_babycrab_health )

sk_babycrab_health_value = 8

function sk_babycrab_melee_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_babycrab_melee_value = v
		end
	end
end 
concommand.Add( "sk_babycrab_dmg_bite", sk_babycrab_melee_dmg )

sk_babycrab_melee_value = 4

// BARNEY
function sk_barney_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_barney_health_value = v
		end
	end
end 
concommand.Add( "sk_barney_hl1_health", sk_barney_health )

sk_barney_health_value = 120

// BULLSQUID
function sk_bullsquid_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_bullsquid_health_value = v
		end
	end
end 
concommand.Add( "sk_bullsquid_health", sk_bullsquid_health )

sk_bullsquid_health_value = 160

function sk_bullsquid_slash_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_bullsquid_slash_value = v
		end
	end
end 
concommand.Add( "sk_bullsquid_dmg_whip", sk_bullsquid_slash_dmg )

sk_bullsquid_slash_value = 35

function sk_bullsquid_bite_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_bullsquid_bite_value = v
		end
	end
end 
concommand.Add( "sk_bullsquid_dmg_bite", sk_bullsquid_bite_dmg )

sk_bullsquid_bite_value = 28

function sk_bullsquid_spit_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_bullsquid_spit_value = v
		end
	end
end 
concommand.Add( "sk_bullsquid_dmg_spit", sk_bullsquid_spit_dmg )

sk_bullsquid_spit_value = 4

// FRIENDLY
/*function sk_friendly_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_friendly_health_value = v
		end
	end
end 
concommand.Add( "sk_friendly_health", sk_friendly_health )

sk_friendly_health_value = 85

function sk_friendly_whip_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_friendly_whip_value = v
		end
	end
end 
concommand.Add( "sk_friendly_dmg_whip", sk_friendly_whip_dmg )

sk_friendly_whip_value = 35*/

// GARGANTUA
function sk_gargantua_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_gargantua_health_value = v
		end
	end
end 
concommand.Add( "sk_gargantua_health", sk_gargantua_health )

sk_gargantua_health_value = 1800

function sk_gargantua_slash_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_gargantua_slash_value = v
		end
	end
end 
concommand.Add( "sk_gargantua_dmg_slash", sk_gargantua_slash_dmg )

sk_gargantua_slash_value = 46

function sk_gargantua_burn_pl_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_gargantua_burn_pl_value = v
		end
	end
end 
concommand.Add( "sk_gargantua_dmg_fire", sk_gargantua_burn_pl_dmg )

sk_gargantua_burn_pl_value = 28

function sk_gargantua_burn_npc_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_gargantua_burn_npc_value = v
		end
	end
end 
concommand.Add( "sk_gargantua_dmg_fire_npc", sk_gargantua_burn_npc_dmg )

sk_gargantua_burn_npc_value = 18

function sk_gargantua_stomp_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_gargantua_stomp_value = v
		end
	end
end 
concommand.Add( "sk_gargantua_dmg_stomp", sk_gargantua_stomp_dmg )

sk_gargantua_stomp_value = 100

// GONARCH
function sk_gonarch_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_gonarch_health_value = v
		end
	end
end 
concommand.Add( "sk_gonarch_health", sk_gonarch_health )

sk_gonarch_health_value = 1400

function sk_gonarch_slash_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_gonarch_slash_value = v
		end
	end
end 
concommand.Add( "sk_bigmomma_dmg_slash", sk_gonarch_slash_dmg )

sk_gonarch_slash_value = 33

function sk_gonarch_spit_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_gonarch_spit_value = v
		end
	end
end 
concommand.Add( "sk_bigmomma_dmg_blast", sk_gonarch_spit_dmg )

sk_gonarch_spit_value = 11

/*function sk_gonarch_max_bcrabs( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_gonarch_bcrab_value = v
		end
	end
end 
concommand.Add( "sk_gonarch_max_bcrabs", sk_gonarch_max_bcrabs )

sk_gonarch_bcrab_value = 7*/

// HOUNDEYE
function sk_houndeye_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_houndeye_health_value = v
		end
	end
end 
concommand.Add( "sk_houndeye_health", sk_houndeye_health )

sk_houndeye_health_value = 100

function sk_houndeye_blast_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_houndeye_blast_value = v
		end
	end
end 
concommand.Add( "sk_houndeye_dmg_blast", sk_houndeye_blast_dmg )

sk_houndeye_blast_value = 28

// PARASITE
function sk_parasite_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_parasite_health_value = v
		end
	end
end 
concommand.Add( "sk_parasite_health", sk_parasite_health )

sk_parasite_health_value = 70

function sk_parasite_slash_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_parasite_slash_value = v
		end
	end
end 
concommand.Add( "sk_parasite_dmg_slash", sk_parasite_slash_dmg )

sk_parasite_slash_value = 12

// SNARK
function sk_snark_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_snark_health_value = v
		end
	end
end 
concommand.Add( "sk_snark_health", sk_snark_health )

sk_snark_health_value = 8

function sk_snark_melee_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_snark_melee_value = v
		end
	end
end 
concommand.Add( "sk_snark_dmg_bite", sk_snark_melee_dmg )

sk_snark_melee_value = 4

function sk_snark_blast_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_snark_blast_value = v
		end
	end
end 
concommand.Add( "sk_snark_dmg_pop", sk_snark_blast_dmg )

sk_snark_blast_value = 12

function sk_snark_blast_delay( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_snark_delay_value = v
		end
	end
end 
concommand.Add( "sk_snark_pop_delay", sk_snark_blast_delay )

sk_snark_delay_value = 17

// TENTACLE
/*function sk_tentacle_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_tentacle_health_value = v
		end
	end
end 
concommand.Add( "sk_tentacle_health", sk_tentacle_health )

sk_tentacle_health_value = 160

function sk_tentacle_slash_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_tentacle_slash_value = v
		end
	end
end 
concommand.Add( "sk_tentacle_slash_dmg", sk_tentacle_slash_dmg )

sk_tentacle_slash_value = 28*/

function sk_panthereye_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_panthereye_health_value = v
		end
	end
end 
concommand.Add( "sk_panthereye_health", sk_panthereye_health )

sk_panthereye_health_value = 160

function sk_panthereye_slash_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_panthereye_slash_value = v
		end
	end
end 
concommand.Add( "sk_panthereye_dmg_slash", sk_panthereye_slash_dmg )

sk_panthereye_slash_value = 26

function sk_panthereye_jump_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_panthereye_jump_value = v
		end
	end
end 
concommand.Add( "sk_panthereye_dmg_jump", sk_panthereye_jump_dmg )

sk_panthereye_jump_value = 32

function sk_archer_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_archer_health_value = v
		end
	end
end 
concommand.Add( "sk_archer_health", sk_archer_health )

sk_archer_health_value = 60

function sk_archer_bite_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_archer_bite_value = v
		end
	end
end 
concommand.Add( "sk_archer_dmg_bite", sk_archer_bite_dmg )

sk_archer_bite_value = 7

function sk_archer_shoot_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_archer_shoot_value = v
		end
	end
end 
concommand.Add( "sk_archer_dmg_shoot", sk_archer_shoot_dmg )

sk_archer_shoot_value = 6

function sk_scientist_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_scientist_health_value = v
		end
	end
end 
concommand.Add( "sk_scientist_health", sk_scientist_health )

sk_scientist_health_value = 80

function sk_scientist_heal( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_scientist_heal_value = v
		end
	end
end 
concommand.Add( "sk_scientist_heal", sk_scientist_heal )

sk_scientist_heal_value = 26

function sk_headcrab_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_headcrab_health_value = v
		end
	end
end 
concommand.Add( "sk_headcrab_hl1_health", sk_headcrab_health )

sk_headcrab_health_value = 14

function sk_headcrab_melee_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_headcrab_melee_value = v
		end
	end
end 
concommand.Add( "sk_headcrab_hl1_dmg_bite", sk_headcrab_melee_dmg )

sk_headcrab_melee_value = 12

function sk_zombie_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_zombie_health_value = v
		end
	end
end 
concommand.Add( "sk_zombie_hl1_health", sk_zombie_health )

sk_zombie_health_value = 180

function sk_zombie_slash_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_zombie_slash_value = v
		end
	end
end 
concommand.Add( "sk_zombie_hl1_dmg_one_slash", sk_zombie_slash_dmg )

sk_zombie_slash_value = 18

function sk_zombie_both_slash_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_zombie_both_slash_value = v
		end
	end
end 
concommand.Add( "sk_zombie_hl1_dmg_both_slash", sk_zombie_both_slash_dmg )

sk_zombie_both_slash_value = 28

function sk_aslave_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_aslave_health_value = v
		end
	end
end 
concommand.Add( "sk_islave_health", sk_aslave_health )

sk_aslave_health_value = 150

function sk_aslave_slash_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_aslave_slash_value = v
		end
	end
end 
concommand.Add( "sk_islave_dmg_claw", sk_aslave_slash_dmg )

sk_aslave_slash_value = 26

function sk_aslave_zap_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_aslave_zap_value = v
		end
	end
end 
concommand.Add( "sk_islave_dmg_zap", sk_aslave_zap_dmg )

sk_aslave_zap_value = 32

function sk_hgrunt_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_hgrunt_health_value = v
		end
	end
end 
concommand.Add( "sk_hgrunt_health", sk_hgrunt_health )

sk_hgrunt_health_value = 70

function sk_hgrunt_kick_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_hgrunt_kick_value = v
		end
	end
end 
concommand.Add( "sk_hgrunt_dmg_kick", sk_hgrunt_kick_dmg )

sk_hgrunt_kick_value = 24

function sk_hgrunt_kick_double_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_hgrunt_kick_double_value = v
		end
	end
end 
concommand.Add( "sk_hgrunt_dmg_kick_double", sk_hgrunt_kick_double_dmg )

sk_hgrunt_kick_double_value = 14

function sk_hassassin_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_hassassin_health_value = v
		end
	end
end 
concommand.Add( "sk_hassassin_health", sk_hassassin_health )

sk_hassassin_health_value = 80

function sk_ichthyosaur_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_ichthyosaur_health_value = v
		end
	end
end 
concommand.Add( "sk_ichthyosaur_health", sk_ichthyosaur_health )

sk_ichthyosaur_health_value = 200

function sk_ichthyosaur_bite_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_ichthyosaur_bite_value = v
		end
	end
end 
concommand.Add( "sk_ichthyosaur_melee_dmg", sk_ichthyosaur_bite_dmg )

sk_ichthyosaur_bite_value = 36

// WEAPONS
function ironsight_enable( player, command, arguments )
	ironsight_ply = player
end 
concommand.Add( "ironsight", ironsight_enable )

function sk_wep_9mm_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_9mm_value = v
		end
	end
end 
concommand.Add( "sk_plr_dmg_9mm_bullet", sk_wep_9mm_dmg )

sk_wep_9mm_value = 8

function sk_wep_mp5_gren_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_mp5_gren_value = v
		end
	end
end 
concommand.Add( "sk_plr_dmg_mp5_grenade", sk_wep_mp5_gren_dmg )

sk_wep_mp5_gren_value = 100

function sk_wep_gren_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_gren_value = v
		end
	end
end 
concommand.Add( "sk_plr_dmg_grenade", sk_wep_gren_dmg )

sk_wep_gren_value = 100

function sk_wep_hornet_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_hornet_value = v
		end
	end
end 
concommand.Add( "sk_plr_dmg_hornet", sk_wep_hornet_dmg )

sk_wep_hornet_value = 7

function sk_wep_satchel_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_satchel_value = v
		end
	end
end 
concommand.Add( "sk_plr_dmg_satchel", sk_wep_satchel_dmg )

sk_wep_satchel_value = 150

function sk_wep_tripmine_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_tripmine_value = v
		end
	end
end 
concommand.Add( "sk_plr_dmg_tripmine", sk_wep_tripmine_dmg )

sk_wep_tripmine_value = 150

function sk_wep_gauss_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_gauss_value = v
		end
	end
end 
concommand.Add( "sk_plr_dmg_gauss", sk_wep_gauss_dmg )

sk_wep_gauss_value = 20

function sk_wep_gauss_deathmatch( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_gauss_deathmatch_value = v
		end
	end
end 
concommand.Add( "sk_gauss_deathmatch", sk_wep_gauss_deathmatch )

//sk_wep_gauss_deathmatch_value = 0

// MONSTER WEAPONS
function sk_wep_npc_hornet_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_npc_hornet_value = v
		end
	end
end 
concommand.Add( "sk_npc_dmg_hornet", sk_wep_npc_hornet_dmg )

sk_wep_npc_hornet_value = 8

function sk_wep_npc_9mm_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_npc_9mm_value = v
		end
	end
end 
concommand.Add( "sk_npc_dmg_9mm_bullet", sk_wep_npc_9mm_dmg )

sk_wep_npc_9mm_value = 8

function sk_wep_npc_9mmAR_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_npc_9mmAR_value = v
		end
	end
end 
concommand.Add( "sk_npc_dmg_9mmAR_bullet", sk_wep_npc_9mmAR_dmg )

sk_wep_npc_9mmAR_value = 5

function sk_wep_npc_12mm_dmg( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_wep_npc_12mm_value = v
		end
	end
end 
concommand.Add( "sk_npc_dmg_12mm_bullet", sk_wep_npc_12mm_dmg )

sk_wep_npc_12mm_value = 10

// SENTRY
function sk_sentry_health( player, command, arguments )
	if player:IsAdmin() then
		for k,v in pairs( arguments ) do
			sk_sentry_health_value = v
		end
	end
end 
concommand.Add( "sk_sentry_health", sk_sentry_health )

sk_sentry_health_value = 50