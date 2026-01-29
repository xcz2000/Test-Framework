local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local validateInstance = require(ReplicatedStorage.Modules.TypeValidation.ValidateInstance)
local validateHit = require(script.ValidateHit)

local remoteEvents = ReplicatedStorage.RemoteEvents
local gunModules = ReplicatedStorage.Modules.Gun

local fireEvent = remoteEvents.Fire
local reloadEvent = remoteEvents.Reload

local playerWeaponData = {}

local function isAlive(player)
	return player
		and player.Character
		and player.Character.HumanoidRootPart
		and player.Character.Humanoid
		and player.Character.Humanoid.Health > 0
end

fireEvent.OnServerEvent:Connect(function(player, targetHumanoid)
	if not isAlive(player) then
		return
	end

	local playerData = playerWeaponData[player]

	if playerData.reloading then
		return
	end

	if playerData.ammo <= 0 then
		return
	end

	if tick() - playerData.lastFire < playerData.module.firerate - 0.05 then
		return
	end

	playerData.lastFire = tick()
	playerData.ammo -= 1

	if not validateInstance(targetHumanoid, "Humanoid") then
		return
	end

	if not validateHit(player, targetHumanoid) then
		return
	end

	targetHumanoid.Health = targetHumanoid.Health - 10
end)

reloadEvent.OnServerEvent:Connect(function(player: Player)
	if not isAlive(player) then
		return
	end

	local playerData = playerWeaponData[player]

	if playerData.reloading then
		return
	end

	if playerData.ammo >= playerData.module.maxAmmo then
		return
	end

	playerData.reloading = true
	task.wait(playerData.module.reloadTime)
	playerData.reloading = false

	playerData.ammo = playerData.module.maxAmmo
end)

Players.PlayerAdded:Connect(function(player)
	local newModule = require(gunModules:FindFirstChild("M4A1"))
	playerWeaponData[player] = {
		module = newModule,
		lastFire = 0,
		ammo = newModule.maxAmmo,
		reloading = false,
	}
end)
