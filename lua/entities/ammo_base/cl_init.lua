include('shared.lua')

function ENT:Draw()
	self.Entity:DrawModel()
end

function ItemPickedUp( um )
	local um_sep = string.Explode( ",", um:ReadString() ) 
	for k, v in pairs( um_sep ) do
		if k == 1 then
			AmmoName = v
		else
			AmmoAmmount = v
		end
	end
	//PrintTable( GAMEMODE.PickupHistory )
	gamemode.Call( "HUDAmmoPickedUp", AmmoName, AmmoAmmount )
	AmmoName = nil
	AmmoAmmount = nil
	
end
usermessage.Hook("ItemPickedUp", ItemPickedUp) 
