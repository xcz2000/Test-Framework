-- require services
local Players = game:GetService("Players")

local player = Players.LocalPlayer -- get player
local playerGui = player:WaitForChild("PlayerGui") -- wait for playergui to load

local guiController = {}
guiController.__index = guiController

function guiController.new(weaponController) -- constructor function for gui controller
	local self = setmetatable({}, guiController) -- creating a new metatable

	-- save a reference to the weapon controller class
	self.weaponController = weaponController

	-- wait for gun gui and ammo label to load and save references to them
	self.gunGui = playerGui:WaitForChild("GunGui")
	self.ammoLabel = self.gunGui:WaitForChild("AmmoLabel")

	-- create a variable to store the ammo changed connection
	self.ammoChangedCon = nil

	self:Init() -- call init function

	return self -- returns metatable
end

function guiController:Init() -- init method
	self.ammoLabel.Text = tostring(self.weaponController.ammo) -- set ammo text
		.. " / "
		.. tostring(self.weaponController.module.maxAmmo)

	self.ammoChangedCon = self.weaponController.ammoChanged.Event:Connect(
		function(newAmmo) -- connect to ammo changed bindable event
			self.ammoLabel.Text = tostring(newAmmo) .. " / " .. tostring(self.weaponController.module.maxAmmo) -- update ammo text when event is fired
		end
	)
end
function guiController:Destroy() -- destroy method
	if self.ammoChangedCon then -- check if ammo changed connection exists
		self.ammoChangedCon:Disconnect() -- disconnect ammo changed connection
		self.ammoChangedCon = nil -- set connection variable to nil
	end

	self = nil -- set gui controller instance to nil to help garbage collection
end
return guiController -- return module
