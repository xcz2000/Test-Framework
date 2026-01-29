-- require services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- require class modules
local viewmodelController = require(script.Parent.ViewmodelController)
local inputController = require(script.Parent.InputController)
local actionController = require(script.Parent.ActionController)
local guiController = require(script.Parent.GUIController)

-- get player and current camera
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- get gun models and modules folders
local gunModels = ReplicatedStorage.GunModels
local gunModules = ReplicatedStorage.Modules.Gun

local weaponController = {}
weaponController.__index = weaponController

function weaponController.new(name: string) -- constructor function for weapon controller
	local self = setmetatable({}, weaponController) -- creating a new metatable

	self.ammoChanged = Instance.new("BindableEvent") -- create bindable event instance for ammo changes

	-- create variables of weapon controller (this is optional but it helps to understand what variables the class has)
	self.viewmodelController = nil
	self.inputController = nil
	self.actionController = nil
	self.weapon = nil
	self.module = nil
	self.animator = nil
	self.root = nil
	self.firePoint = nil

	-- create variables for ammo, animations, and sounds
	self.ammo = 0
	self.animations = {}
	self.sounds = {}

	self:Init(name) -- call init function from weapon controller class with name argument

	return self -- returns metatable
end

function weaponController:Init(name) -- initialization function for weapon controller
	local module = gunModules:FindFirstChild(name) -- find module by name in gun modules folder
	if not module then -- check if module exists
		error("Module by name " .. name .. " was not found") -- fire an error if it does not exist
	end
	self.module = require(module) -- require the module and save it to weapon controller's module variable

	local weapon = gunModels:FindFirstChild(name) -- find model by name in gun models folder
	if not weapon then -- check if model exists
		error("Model by name " .. name .. " was not found") -- fire an error if it does not exist
	end
	self.weapon = weapon:Clone() -- clone the model and save it to weapon controller's weapon variable

	self.weapon.Parent = camera -- parent weapon to the current camera

	self.root = self.weapon.HumanoidRootPart -- save reference to root part of weapon
	self.ammo = self.module.maxAmmo -- set current ammo to max ammo from weapon's module
	self.firePoint = self.weapon.FirePoint -- save reference to fire point part of weapon

	self.animator = self.weapon.AnimationController.Animator -- save reference to animator from weapon's animation controller

	for animName, id in self.module.animations do -- loop through animation ids from weapon's module
		local newAnim = Instance.new("Animation") -- create a new instance of animation
		newAnim.AnimationId = "rbxassetid://" .. id -- set animation id of new animation to current id
		self.animations[animName] = self.animator:LoadAnimation(newAnim) -- load animation to create a animationtrack and save it to animations table by the key name
	end

	for soundName, sound in self.module.sounds do -- loop through sounds from weapon's module
		local newSound = sound:Clone() -- clone the sound
		newSound.Parent = self.root -- parent it to the weapon's root part
		self.sounds[soundName] = newSound -- save it to sounds table by the key name
	end

	-- create instances of controller classes and save references to weapon controller
	self.actionController = actionController.new(self)
	self.inputController = inputController.new(self)
	self.viewmodelController = viewmodelController.new(self)
	self.guiController = guiController.new(self)

	player.Character.Humanoid.Died:Once(function()
		self.actionController:Destroy()
		self.inputController:Destroy()
		self.viewmodelController:Destroy()
		self.guiController:Destroy()
		self:Destroy()
	end)
end

function weaponController:Destroy()
	self.weapon:Destroy() -- destroy the weapon model
	self.ammoChanged:Destroy() -- destroy the ammo changed bindable event
	self = nil -- set weapon controller instance to nil to help garbage collection
end

return weaponController -- return module
