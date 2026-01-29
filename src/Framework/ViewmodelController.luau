local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local viewmodelController = {}
viewmodelController.__index = viewmodelController

function viewmodelController.new(weaponController)
	local self = setmetatable({}, viewmodelController)

	self.weaponController = weaponController
	self.input = weaponController.inputController
	self.action = weaponController.actionController

	self.weapon = weaponController.weapon
	self.root = self.weapon.HumanoidRootPart
	self.aimPart = self.weapon.Aim

	self.aimCFrame = CFrame.new()
	self.bobbleCFrame = CFrame.new()
	self.swayCFrame = CFrame.new()
	self.lastCameraCF = camera.CFrame
	self.bobbleAplitude = 0.04
	self.bobbleSpeed = 5
	self.lerpSpeed = 0.0025

	RunService.RenderStepped:Connect(function(deltatime)
		self:UpdateSway(deltatime)
		self:UpdateAimCF(deltatime)
		self:UpdateBobble(deltatime)

		if self.input.shooting then
			self.action:TryFire()
		end

		self.weapon:SetPrimaryPartCFrame(camera.CFrame * self.aimCFrame * self.bobbleCFrame * self.swayCFrame)
	end)

	return self
end

function viewmodelController:UpdateSway(deltatime: number)
	local swayDifference = camera.CFrame:ToObjectSpace(self.lastCameraCF)
	local rx, ry, _ = swayDifference:ToEulerAnglesXYZ()
	self.swayCFrame =
		self.swayCFrame:Lerp(CFrame.Angles(math.sin(rx) * 2, math.sin(ry) * 2, 0), 1 - self.lerpSpeed ^ deltatime)
	self.lastCameraCF = camera.CFrame
end

function viewmodelController:UpdateAimCF(deltatime: number)
	if self.input.aiming then
		local offset = self.aimPart.CFrame:ToObjectSpace(self.root.CFrame)
		self.aimCFrame = self.aimCFrame:Lerp(offset, 1 - self.lerpSpeed ^ deltatime)
	else
		self.aimCFrame = self.aimCFrame:Lerp(CFrame.new(), 1 - self.lerpSpeed ^ deltatime)
	end
end

function viewmodelController:UpdateBobble(deltatime: number)
	if humanoid.MoveDirection.Magnitude > 0 then
		local bobbleX = math.sin(tick() * self.bobbleSpeed) * self.bobbleAplitude
		local bobbleY = math.sin(tick() * self.bobbleSpeed * 2) * self.bobbleAplitude
		self.bobbleCFrame = self.bobbleCFrame:Lerp(CFrame.new(bobbleX, bobbleY, 0), 1 - self.lerpSpeed ^ deltatime)
	else
		self.bobbleCFrame = self.bobbleCFrame:Lerp(CFrame.new(), 1 - self.lerpSpeed ^ deltatime)
	end
end

return viewmodelController
