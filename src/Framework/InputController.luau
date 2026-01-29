-- require services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- require inputaction wrapper module
local input = require(ReplicatedStorage.Modules.Input)

local inputController = {}
inputController.__index = inputController

function inputController.new(weaponController) -- constructor function for input controller
	local self = setmetatable({}, inputController) -- create a metatable

	-- save references to weapon controller and action controller
	self.weaponController = weaponController
	self.action = weaponController.actionController

	-- create input actions for firing, aiming, and reloading
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
		Gamepad = { Enum.KeyCode.ButtonB },
	})

	-- create input state variables
	self.shooting = false
	self.aiming = false

	self:Init() -- call init method

	return self -- return metatable
end

function inputController:Init() -- init method
	self.fireInput.pressed:Connect(function() -- connect to pressed event of fire input
		self.shooting = true -- set shooting state to true when fireInput pressed event fires
	end)
	self.fireInput.released:Connect(function() -- connect to released event of fire input
		self.shooting = false -- set shooting state to false when fireInput released event fires
	end)
	self.aimInput.pressed:Connect(function() -- connect to pressed event of aim input
		self.aiming = true -- set aiming state to true when aimInput pressed event fires
	end)
	self.aimInput.released:Connect(function() -- connect to released event of aim input
		self.aiming = false -- set aiming state to false when aimInput released event fires
	end)
	self.reloadInput.pressed:Connect(function() -- connect to pressed event of reload input
		self.action:Reload() -- call reload method from action controller when reloadInput pressed event fires
	end)
end

function inputController:Destroy() -- destroy method
	self.fireInput:Destroy() -- destroy fire input action
	self.aimInput:Destroy() -- destroy aim input action
	self.reloadInput:Destroy() -- destroy reload input action

	self = nil -- set input controller instance to nil to help garbage collection
end

return inputController -- return module
