-- require services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- get player and camera references
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local viewmodelController = {}
viewmodelController.__index = viewmodelController

function viewmodelController.new(weaponController) -- constructor function for viewmodel controller
	local self = setmetatable({}, viewmodelController) -- creating a new metatable

	-- create references to needed controllers
	self.weaponController = weaponController
	self.input = weaponController.inputController
	self.action = weaponController.actionController

	-- create variables to weapon and its parts
	self.weapon = weaponController.weapon
	self.root = self.weapon.HumanoidRootPart
	self.aimPart = self.weapon.Aim

	-- create variables for viewmodel controller
	self.aimCFrame = CFrame.new()
	self.bobbleCFrame = CFrame.new()
	self.swayCFrame = CFrame.new()
	self.lastCameraCF = camera.CFrame
	self.bobbleAplitude = 0.04
	self.bobbleSpeed = 5
	self.lerpSpeed = 0.0025

	-- connect to RenderStepped to update viewmodel every frame
	RunService.RenderStepped:Connect(function(deltatime)
		self:UpdateSway(deltatime) -- call update sway function
		self:UpdateAimCF(deltatime) -- call update aim cframe function
		self:UpdateBobble(deltatime) -- call update bobble function

		if self.input.shooting then -- check if shooting input is active
			self.action:TryFire() -- call tryfire function from action controller
		end

		self.weapon:PivotTo(camera.CFrame * self.aimCFrame * self.bobbleCFrame * self.swayCFrame) -- pivot weapon to cframe by combining camera cframe with aim, bobble, and sway cframes
	end)

	return self -- return metatable
end

function viewmodelController:UpdateSway(deltatime: number) -- update sway method
	local swayDifference = camera.CFrame:ToObjectSpace(self.lastCameraCF) -- get difference between last camera cframe and current camera cframe
	local rx, ry, _ = swayDifference:ToEulerAnglesXYZ() -- get angle values of difference cframe

	-- lerp sway cframe based on angle values
	-- 1-self.lerpSpeed ^ deltatime makes lerp identical on different frame rates
	-- math.sin is used to make sway smoother
	self.swayCFrame =
		self.swayCFrame:Lerp(CFrame.Angles(math.sin(rx) * 2, math.sin(ry) * 2, 0), 1 - self.lerpSpeed ^ deltatime)
	self.lastCameraCF = camera.CFrame -- update last camera cframe to current camera cframe
end

function viewmodelController:UpdateAimCF(deltatime: number) -- update aim cframe method
	if self.input.aiming then -- check if aiming input is active
		local offset = self.aimPart.CFrame:ToObjectSpace(self.root.CFrame) -- get offset between aimpart and root part
		self.aimCFrame = self.aimCFrame:Lerp(offset, 1 - self.lerpSpeed ^ deltatime) -- lerp aim cframe to offset cframe
	else
		self.aimCFrame = self.aimCFrame:Lerp(CFrame.new(), 1 - self.lerpSpeed ^ deltatime) -- lerp aim cframe to zero cframe if player is not aiming
	end
end

function viewmodelController:UpdateBobble(deltatime: number) -- update bobble cframe method
	if player.Character.Humanoid.MoveDirection.Magnitude > 0 then -- check if player is moving
		-- calculate x and y values for bobble using sine wave
		-- since time is always increasing math.sin combined with tick() creates a sine wave
		local bobbleX = math.sin(tick() * self.bobbleSpeed) * self.bobbleAplitude
		local bobbleY = math.sin(tick() * self.bobbleSpeed * 2) * self.bobbleAplitude -- y bobble is 2x faster than x bobble to make weapon bobbling instead of moving it in circle
		self.bobbleCFrame = self.bobbleCFrame:Lerp(CFrame.new(bobbleX, bobbleY, 0), 1 - self.lerpSpeed ^ deltatime) -- lerp bobble cframe to new calculated bobble cframe
	else
		self.bobbleCFrame = self.bobbleCFrame:Lerp(CFrame.new(), 1 - self.lerpSpeed ^ deltatime) -- lerp bobble cframe to zero cframe if player is not moving
	end
end

function viewmodelController:Destroy() -- destroy method
	self = nil -- set viewmodel controller instance to nil to help garbage collection
end

return viewmodelController -- return viewmodel controller module
