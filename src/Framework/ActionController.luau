local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteEvents = ReplicatedStorage.RemoteEvents

local fireEvent = remoteEvents.Fire
local reloadEvent = remoteEvents.Reload

local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()

local actionController = {}
actionController.__index = actionController

function actionController.new(weaponController)
	local self = setmetatable({}, actionController)

	self.weaponController = weaponController

	self.animations = weaponController.animations
	self.sounds = weaponController.sounds

	self.maxFireLength = 500
	self.lastFire = 0
	self.fireRate = self.weaponController.module.firerate
	self.reloading = false

	self.fireRayParams = RaycastParams.new()
	self.fireRayParams.FilterDescendantsInstances = { self.weaponController.weapon, character }

	return self
end

function actionController:TryFire()
	if self.reloading then
		return
	end

	if tick() - self.lastFire < self.fireRate then
		return
	end

	if self.weaponController.ammo <= 0 then
		return
	end

	self.lastFire = tick()

	self.animations.fire:Play()
	self.sounds.fire:Play()
	self.weaponController.ammo = self.weaponController.ammo - 1

	self.weaponController.ammoChanged:Fire(self.weaponController.ammo)

	-- implement bullet logic and effects here

	local raycast = workspace:Raycast(
		self.weaponController.firePoint.Position,
		self.weaponController.firePoint.CFrame.LookVector * self.maxFireLength,
		self.fireRayParams
	)
	if not raycast or not raycast.Instance then
		return
	end

	local targetCharacter = raycast.Instance:FindFirstAncestorOfClass("Model")
	if not targetCharacter then
		return
	end

	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid then
		return
	end

	fireEvent:FireServer(targetHumanoid)
end

function actionController:Reload()
	if self.reloading then
		return
	end

	if self.weaponController.ammo >= self.weaponController.module.maxAmmo then
		return
	end
	self.animations.fire:Stop()
	self.animations.reload:Play()
	self.sounds.reload:Play()
	self.reloading = true
	self.animations.reload.Stopped:Wait()
	self.reloading = false
	self.weaponController.ammo = self.weaponController.module.maxAmmo

	self.weaponController.ammoChanged:Fire(self.weaponController.ammo)

	reloadEvent:FireServer()
end

return actionController
