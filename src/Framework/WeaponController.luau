local ReplicatedStorage = game:GetService("ReplicatedStorage")

local viewmodelController = require(script.Parent.ViewmodelController)

local camera = workspace.CurrentCamera

local gunModels = ReplicatedStorage.GunModels
local gunModules = ReplicatedStorage.Modules.Gun

local weaponController = {}
weaponController.__index = weaponController

function weaponController.new(name: string)
	local self = setmetatable({}, weaponController)

	self.viewmodelController = nil
	self.weapon = nil
	self.module = nil
	self.animator = nil
	self.root = nil
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

	self.root = self.weapon.HumanoidRootPart
	self.ammo = self.module.maxAmmo

	self.animator = self.weapon.AnimationController.Animator

	for animName, id in self.module.animations do
		local newAnim = Instance.new("Animation")
		newAnim.AnimationId = id
		self.animations[animName] = self.animator:LoadAnimation(newAnim)
		newAnim:Destroy()
	end

	for soundName, id in self.module.sounds do
		local newSound = Instance.new("Sound")
		newSound.SoundId = id
		newSound.Parent = self.root
		self.sounds[soundName] = newSound
	end

	self.weapon.Parent = camera

	self.viewmodelController = viewmodelController.new(self)
end

return weaponController
