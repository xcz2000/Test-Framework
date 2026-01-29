-- require services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- get remote events folder from replicatedStorage
local remoteEvents = ReplicatedStorage.RemoteEvents

-- get remoteEvents
local fireEvent = remoteEvents.Fire
local reloadEvent = remoteEvents.Reload

-- get player
local player = Players.LocalPlayer

local actionController = {}
actionController.__index = actionController

function actionController.new(weaponController) -- constructor function for action controller
	local self = setmetatable({}, actionController) -- creating a new metatable

	self.weaponController = weaponController -- save a reference to the weapon controller class

	-- create references to animations and sounds from weapon controller for easier access
	self.animations = weaponController.animations
	self.sounds = weaponController.sounds

	-- create variables for action controller
	self.maxFireLength = 500
	self.lastFire = 0
	self.fireRate = self.weaponController.module.firerate
	self.reloading = false

	self.fireRayParams = RaycastParams.new() -- create new raycast parameters
	self.fireRayParams.FilterDescendantsInstances = { self.weaponController.weapon, player.Character } -- set instances to be ignored by raycast

	return self
end

function actionController:TryFire()
	if self.reloading then -- check if currently reloading
		return
	end

	if tick() - self.lastFire < self.fireRate then -- check if enough time has passed since last fire by subtracting current time from last fire time and comparing it to fire rate from weapon's module
		return
	end

	if self.weaponController.ammo <= 0 then -- check if there is enough ammo
		return
	end

	self.lastFire = tick() -- update last fire time to current time

	self.animations.fire:Play() -- play animation
	self.sounds.fire:Play() -- play sound
	self.weaponController.ammo = self.weaponController.ammo - 1 -- decrease ammo amount by 1

	self.weaponController.ammoChanged:Fire(self.weaponController.ammo) -- fire bindable event to signal a change in ammo for gui update and other systems

	local raycast = workspace:Raycast( -- create a raycast to detect a target
		self.weaponController.firePoint.Position,
		self.weaponController.firePoint.CFrame.LookVector * self.maxFireLength,
		self.fireRayParams
	)
	if not raycast or not raycast.Instance then -- check if raycast hit something
		return
	end

	local targetCharacter = raycast.Instance:FindFirstAncestorOfClass("Model") -- check if hit instance is part of a model
	if not targetCharacter then
		return
	end

	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid") -- check if that model contains an instance with classname humanoid
	if not targetHumanoid then
		return
	end

	fireEvent:FireServer(targetHumanoid) -- fire remote event to server with target humanoid as argument
end

function actionController:Reload()
	if self.reloading then -- check if currently reloading
		return
	end

	if self.weaponController.ammo >= self.weaponController.module.maxAmmo then -- check if ammo is equal or greater than max ammo
		return
	end
	self.animations.fire:Stop() -- stop firing animation
	self.animations.reload:Play() -- play reload animation
	self.sounds.reload:Play() -- play reload sound
	self.reloading = true -- set reloading boolean to true
	self.animations.reload.Stopped:Wait() -- wait for reload animation to finish or get stopped by other script
	self.reloading = false -- set reloading boolean to false after reload animation is stopped
	self.weaponController.ammo = self.weaponController.module.maxAmmo -- set ammo to max ammo from weapon's module

	self.weaponController.ammoChanged:Fire(self.weaponController.ammo) -- fire bindable event to signal a change in ammo for gui update and other systems

	reloadEvent:FireServer() -- fire remote event to server to signal reload
end

function actionController:Destroy()
	self = nil -- set action controller instance to nil to help garbage collection
end

return actionController -- return the action controller module
