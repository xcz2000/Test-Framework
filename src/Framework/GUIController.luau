local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local guiController = {}
guiController.__index = guiController

function guiController.new(weaponController)
	local self = setmetatable({}, guiController)

	self.weaponController = weaponController

	self.gunGui = playerGui:WaitForChild("GunGui")
	self.ammoLabel = self.gunGui:WaitForChild("AmmoLabel")

	self:Init()

	return self
end

function guiController:Init()
	self.ammoLabel.Text = tostring(self.weaponController.ammo)
		.. " / "
		.. tostring(self.weaponController.module.maxAmmo)

	self.weaponController.ammoChanged.Event:Connect(function(newAmmo)
		self.ammoLabel.Text = tostring(newAmmo) .. " / " .. tostring(self.weaponController.module.maxAmmo)
	end)
end

return guiController
