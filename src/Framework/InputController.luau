local ReplicatedStorage = game:GetService("ReplicatedStorage")

local input = require(ReplicatedStorage.Modules.Input)

local inputController = {}
inputController.__index = inputController

function inputController.new(weaponController)
	local self = setmetatable({}, inputController)

	self.weaponController = weaponController
	self.action = weaponController.actionController

	self.fireInput = input.new("WeaponContext", "Fire", {
		Keyboard = { Enum.KeyCode.MouseLeftButton },
		Gamepad = { Enum.KeyCode.ButtonR2 },
	})
	self.aimInput = input.new("WeaponContext", "Aim", {
		Keyboard = { Enum.KeyCode.MouseRightButton },
		Gamepad = { Enum.KeyCode.ButtonR1 },
	})
	self.reloadInput = input.new("WeaponContext", "Reload", {
		Keyboard = { Enum.KeyCode.R },
		Gamepad = { Enum.KeyCode.ButtonR1 },
	})

	self.shooting = false
	self.aiming = false

	self:Init()

	return self
end

function inputController:Init()
	self.fireInput.pressed:Connect(function()
		self.shooting = true
	end)
	self.fireInput.released:Connect(function()
		self.shooting = false
	end)
	self.aimInput.pressed:Connect(function()
		self.aiming = true
	end)
	self.aimInput.released:Connect(function()
		self.aiming = false
	end)
	self.reloadInput.pressed:Connect(function()
		self.action:Reload()
	end)
end

return inputController
