//---------- Client Files
if( SERVER ) then

	// include
	AddCSLuaFile( "modulus_ammo_ext.lua" );

end

//---------- Ammo Extension
local meta = FindMetaTable( "Entity" );
if( !meta ) then

	return;

end

/*------------------------------------
   GetCustomAmmo
------------------------------------*/
function meta:GetCustomAmmo( name )
	return self:GetNetworkedInt( "ammo_" .. name );

end

/*------------------------------------
    SetCustomAmmo
------------------------------------*/
function meta:SetCustomAmmo( name, num )
	return self:SetNetworkedInt( "ammo_" .. name, num );

end

/*------------------------------------
    AddCustomAmmo
------------------------------------*/
function meta:AddCustomAmmo( name, num )

	return self:SetCustomAmmo( name, self:GetCustomAmmo( name ) + num );

end
