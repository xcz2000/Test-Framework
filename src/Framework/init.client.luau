local Players = game:GetService("Players") -- get the players service

local player = Players.LocalPlayer -- get the local player

local weaponController = require(script.WeaponController) -- require weapon controller module

player.CharacterAdded:Connect(function() -- connect to character added event
	weaponController.new("M4A1") -- initialize the weapon controller with the M4A1 weapon parameter
end)

if player.Character then -- check if character already exists
	weaponController.new("M4A1") -- initialize the weapon controller with the M4A1 weapon parameter
end
