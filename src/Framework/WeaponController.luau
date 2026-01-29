local ReplicatedStorage = game:GetService("ReplicatedStorage")

local viewmodelController = require(script.Parent.ViewmodelController)
local inputController = require(script.Parent.InputController)
local actionController = require(script.Parent.ActionController)
local guiController = require(script.Parent.GUIController)

local camera = workspace.CurrentCamera

local gunModels = ReplicatedStorage.GunModels
local gunModules = ReplicatedStorage.Modules.Gun

local weaponController = {}
weaponController.__index = weaponController

function weaponController.new(name: string)
	local self = setmetatable({}, weaponController)

	self.ammoChanged = Instance.new("BindableEvent")

	self.viewmodelController = nil
	self.inputController = nil
	self.actionController = nil
	self.weapon = nil
	self.module = nil
	self.animator = nil
	self.root = nil
	self.firePoint = nil
	self.ammo = 0
	self.animations = {}
	self.sounds = {}

	self:Init(name)

	return self
end

function weaponController:Init(name)
	local module = gunModules:FindFirstChild(name)
	if not module then
		error("Module by name " .. name .. " was not found")
	end
	self.module = require(module)

	local weapon = gunModels:FindFirstChild(name)
	if not weapon then
		error("Model by name " .. name .. " was not found")
	end
	self.weapon = weapon:Clone()

	self.weapon.Parent = camera

	self.root = self.weapon.HumanoidRootPart
	self.ammo = self.module.maxAmmo
	self.firePoint = self.weapon.FirePoint

	self.animator = self.weapon.AnimationController.Animator

	for animName, id in self.module.animations do
		local newAnim = Instance.new("Animation")
		newAnim.Name = name
		newAnim.AnimationId = "rbxassetid://" .. id
		newAnim.Parent = self.weapon
		self.animations[animName] = self.animator:LoadAnimation(newAnim)
	end

	for soundName, sound in self.module.sounds do
		local newSound = sound:Clone()
		newSound.Parent = self.root
		self.sounds[soundName] = newSound
	end

	self.actionController = actionController.new(self)
	self.inputController = inputController.new(self)
	self.viewmodelController = viewmodelController.new(self)
	self.guiController = guiController.new(self)
end

return weaponController
