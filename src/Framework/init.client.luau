-- require services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- get player and current camera
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui") -- wait for playergui to load

-- get gun models and modules folders
local gunModels = ReplicatedStorage.GunModels
local gunModules = ReplicatedStorage.Modules.Gun

-- get remote events folder from replicatedStorage
local remoteEvents = ReplicatedStorage.RemoteEvents

-- get remoteEvents
local fireEvent = remoteEvents.Fire
local reloadEvent = remoteEvents.Reload

-- weapons in inventory table
local inventory = {
	"M4A1",
	"M45A1",
}

-- create variables for weapon loading
local weaponName = nil
local weapon = nil
local module = nil
local animator = nil
local root = nil
local firePoint = nil
local aimPart = nil
local aiming = false
local shooting = false
local interacting = false
local lastFire = 0
local ammo = 0
local animations = {}
local sounds = {}

-- create variables for controlling weapon's cframe
local aimCFrame = CFrame.new()
local bobbleCFrame = CFrame.new()
local swayCFrame = CFrame.new()
local lastCameraCF = camera.CFrame

-- create static variables
local bobbleAplitude = 0.04
local bobbleSpeed = 5
local lerpSpeed = 0.0025
local maxFireLength = 500

-- variables for controlling ui
local gunGui = playerGui:WaitForChild("GunGui")
local ammoLabel = gunGui:WaitForChild("AmmoLabel")

local function updateAmmoUI() -- function for updating current ammo ui
	ammoLabel.Text = tostring(ammo) -- set ammo text
		.. " / "
		.. tostring(module.maxAmmo)
end

local function fire() -- function for firing a bullet
	if interacting then -- check if currently reloading
		return
	end

	if tick() - lastFire < module.firerate then -- check if enough time has passed since last fire by subtracting current time from last fire time and comparing it to fire rate from weapon's module
		return
	end

	if ammo <= 0 then -- check if there is enough ammo
		return
	end

	lastFire = tick() -- update last fire time to current time

	animations["fire"]:Play() -- play animation
	sounds["fire"]:Play() -- play sound
	ammo = ammo - 1 -- decrease ammo amount by 1

	updateAmmoUI() -- call function that updates ammo ui

	local fireRayParams = RaycastParams.new() -- create new raycast parameters
	fireRayParams.FilterDescendantsInstances = { weapon, player.Character } -- set instances to be ignored by raycast

	local raycast = workspace:Raycast( -- create a raycast to detect a target
		firePoint.Position,
		firePoint.CFrame.LookVector * maxFireLength,
		fireRayParams
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

local function reload()
	if interacting then -- check if currently interacting
		return
	end

	if ammo >= module.maxAmmo then -- check if ammo is equal or greater than max ammo
		return
	end
	animations["fire"]:Stop() -- stop firing animation
	animations["reload"]:Play() -- play reload animation
	sounds["reload"]:Play() -- play reload sound
	interacting = true -- set interacting boolean to true
	animations["reload"].Stopped:Wait() -- wait for reload animation to finish or get stopped by other script
	interacting = false -- set interacting boolean to false after reload animation is stopped
	ammo = module.maxAmmo -- set ammo to max ammo from weapon's module

	updateAmmoUI() -- call function that updates ammo ui

	reloadEvent:FireServer() -- fire remote event to server to signal reload
end

local function updateSway(deltatime: number) -- update sway method
	local swayDifference = camera.CFrame:ToObjectSpace(lastCameraCF) -- get difference between last camera cframe and current camera cframe
	local rx, ry, _ = swayDifference:ToEulerAnglesXYZ() -- get angle values of difference cframe

	-- lerp sway cframe based on angle values
	-- 1-self.lerpSpeed ^ deltatime makes lerp identical on different frame rates
	-- math.sin is used to make sway smoother
	swayCFrame = swayCFrame:Lerp(CFrame.Angles(math.sin(rx) * 2, math.sin(ry) * 2, 0), 1 - lerpSpeed ^ deltatime)
	lastCameraCF = camera.CFrame -- update last camera cframe to current camera cframe
end

local function updateAimCF(deltatime: number) -- update aim cframe method
	if aiming and interacting == false then -- check if aiming input is active
		local offset = aimPart.CFrame:ToObjectSpace(root.CFrame) -- get offset between aimpart and root part
		aimCFrame = aimCFrame:Lerp(offset, 1 - lerpSpeed ^ deltatime) -- lerp aim cframe to offset cframe
	else
		aimCFrame = aimCFrame:Lerp(CFrame.new(), 1 - lerpSpeed ^ deltatime) -- lerp aim cframe to zero cframe if player is not aiming
	end
end

local function updateBobble(deltatime: number) -- update bobble cframe method
	if player.Character.Humanoid.MoveDirection.Magnitude > 0 then -- check if player is moving
		-- calculate x and y values for bobble using sine wave
		-- since time is always increasing math.sin combined with tick() creates a sine wave
		local bobbleX = math.sin(tick() * bobbleSpeed) * bobbleAplitude
		local bobbleY = math.sin(tick() * bobbleSpeed * 2) * bobbleAplitude -- y bobble is 2x faster than x bobble to make weapon bobbling instead of moving it in circle
		bobbleCFrame = bobbleCFrame:Lerp(CFrame.new(bobbleX, bobbleY, 0), 1 - lerpSpeed ^ deltatime) -- lerp bobble cframe to new calculated bobble cframe
	else
		bobbleCFrame = bobbleCFrame:Lerp(CFrame.new(), 1 - lerpSpeed ^ deltatime) -- lerp bobble cframe to zero cframe if player is not moving
	end
end

local function deleteWeapon() -- function for deleting weapon
	if weapon then -- checks if weapon exists
		weapon:Destroy() -- destroys weapon
	end
	if module then -- checks if module exists
		module = nil -- sets module to nil
	end

	-- clear all of CF values
	aimCFrame = CFrame.new()
	bobbleCFrame = CFrame.new()
	swayCFrame = CFrame.new()
end

local function loadWeapon(name) -- load gun function
	if interacting then -- check if player does something
		return -- return if yes
	end

	if weaponName == name then
		return
	end

	interacting = true -- sets variable interacting to true

	if animations["unequip"] then -- checks if unequip exists in animations table
		animations["unequip"]:Play() -- plays it if exist
		animations["unequip"].Stopped:Wait() -- waits until it will finish
	end

	deleteWeapon() -- call weapon cleanup function

	module = gunModules:FindFirstChild(name) -- find module by name in gun modules folder
	if not module then -- check if module exists
		error("Module by name " .. name .. " was not found") -- fire an error if it does not exist
	end

	weapon = gunModels:FindFirstChild(name) -- find model by name in gun models folder
	if not weapon then -- check if model exists
		error("Model by name " .. name .. " was not found") -- fire an error if it does not exist
	end

	weaponName = name -- changes weaponName variable to weapon's name

	module = require(module) -- require the module and save it to weapon controller's module variable

	weapon = weapon:Clone() -- clone the model and save it to weapon controller's weapon variable

	weapon.Parent = camera -- parent weapon to the current camera

	root = weapon.HumanoidRootPart -- save reference to root part of weapon
	ammo = module.maxAmmo -- set current ammo to max ammo from weapon's module
	firePoint = weapon.FirePoint -- save reference to fire point part of weapon
	aimPart = weapon.Aim -- save reference to aim part of a weapon

	animator = weapon.AnimationController.Animator -- save reference to animator from weapon's animation controller

	animations = {} -- clear animations table
	sounds = {} -- clear sounds table

	for animName, id in module.animations do -- loop through animation ids from weapon's module
		local newAnim = Instance.new("Animation") -- create a new instance of animation
		newAnim.AnimationId = "rbxassetid://" .. id -- set animation id of new animation to current id
		animations[animName] = animator:LoadAnimation(newAnim) -- load animation to create a animationtrack and save it to animations table by the key name
		newAnim:Destroy() -- destroy animation instance
	end

	for soundName, sound in module.sounds do -- loop through sounds from weapon's module
		local newSound = sound:Clone() -- clone the sound
		newSound.Parent = root -- parent it to the weapon's root part
		sounds[soundName] = newSound -- save it to sounds table by the key name
	end

	-- create instances of controller classes and save references to weapon controller
	player.Character.Humanoid.Died:Once(function()
		deleteWeapon() -- cleanup weapon
	end)

	updateAmmoUI() -- call function that updates ammo ui

	animations["equip"]:Play() -- play equip animation
	animations["equip"].Stopped:Wait() -- wait until it finishes
	interacting = false -- set interacting to false
end

-- connect to RenderStepped to update viewmodel every frame
RunService.RenderStepped:Connect(function(deltatime)
	if not weapon then -- check if weapon exist
		return -- if doesn't exist return
	end

	updateSway(deltatime) -- call update sway function
	updateAimCF(deltatime) -- call update aim cframe function
	updateBobble(deltatime) -- call update bobble function

	if shooting then -- check if shooting input is active and player is not doing something else
		fire() -- call fire function
	end

	weapon:PivotTo(camera.CFrame * aimCFrame * bobbleCFrame * swayCFrame) -- pivot weapon to cframe by combining camera cframe with aim, bobble, and sway cframes
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then -- check if player doesn't have roblox's menu or chat openned
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then -- check if player pressed left mouse button
		shooting = true -- set shooting variable to true
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then -- check if player pressed right mouse button
		aiming = true -- set aiming variable to true
	end

	if input.KeyCode == Enum.KeyCode.R then -- check if inputed keycode was letter R
		reload() -- call reload function
	end

	if input.KeyCode == Enum.KeyCode.One then -- check if inputed keycode was 1
		loadWeapon(inventory[1]) -- switch weapon to first weapon in the inventory
	end

	if input.KeyCode == Enum.KeyCode.Two then -- check if inputed keycode was 1
		loadWeapon(inventory[2]) -- switch weapon to second weapon in the inventory
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then -- check if player doesn't have roblox's menu or chat openned
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then -- check if player released left mouse button
		shooting = false -- set shooting variable to false
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then -- check if player released right mouse button
		aiming = false -- set aiming variable to false
	end
end)

loadWeapon(inventory[1]) -- load default weapon
