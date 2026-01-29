-- require services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- require validation modules
local validateInstance = require(ReplicatedStorage.Modules.TypeValidation.ValidateInstance)
local validateHit = require(script.ValidateHit)

-- get remote events and gun modules folders
local remoteEvents = ReplicatedStorage.RemoteEvents
local gunModules = ReplicatedStorage.Modules.Gun

-- create references to remote events
local fireEvent = remoteEvents.Fire
local reloadEvent = remoteEvents.Reload

local playerWeaponData = {} -- table to store player weapon data

local function isAlive(player) -- function to check if player is alive
	return player -- check if player exists
		and player.Character -- check if character exists
		and player.Character.HumanoidRootPart -- check if humanoid root part exists
		and player.Character.Humanoid -- check if humanoid exists
		and player.Character.Humanoid.Health > 0 -- check if humanoid health is greater than 0
end

fireEvent.OnServerEvent:Connect(function(player, targetHumanoid) -- connect to fire remote event
	if not isAlive(player) then -- if player is dead then return from event
		return
	end

	local playerData = playerWeaponData[player] -- get player weapon data

	if playerData.reloading then -- if player is reloading then return from event
		return
	end

	if playerData.ammo <= 0 then -- if there is no ammo then return from event
		return
	end

	if tick() - playerData.lastFire < playerData.module.firerate - 0.05 then -- if not enough time has passed since last fire then return from event
		return
	end

	playerData.lastFire = tick() -- update last fire time to current time
	playerData.ammo -= 1 -- decrease ammo by 1

	if not validateInstance(targetHumanoid, "Humanoid") then -- check if target humanoid is a valid humanoid instance
		return
	end

	print(player.Character, targetHumanoid)
	if not validateHit(player.Character, targetHumanoid) then -- validate if shot is possible by using validateHit module and if not then return
		return
	end

	targetHumanoid.Health = targetHumanoid.Health - 10 -- decrease target humanoid health by 10
end)

reloadEvent.OnServerEvent:Connect(function(player: Player) -- connect to reload remote event
	if not isAlive(player) then -- if player is dead then return from event
		return
	end

	local playerData = playerWeaponData[player] -- get player weapon data

	if playerData.reloading then -- if player is already reloading then return from event
		return
	end

	if playerData.ammo >= playerData.module.maxAmmo then -- if ammo is already full then return from event
		return
	end

	playerData.reloading = true -- set reloading to true
	task.wait(playerData.module.reloadTime) -- wait until reload is finished
	playerData.reloading = false -- set reloading to false

	playerData.ammo = playerData.module.maxAmmo -- set ammo to max ammo
end)

Players.PlayerAdded:Connect(function(player) -- connect to player added event
	player.CharacterAdded:Connect(function() -- connect to character added event
		local newModule = require(gunModules:FindFirstChild("M4A1")) -- require the weapon module from weapon modules folder
		playerWeaponData[player] = { -- initialize player weapon data
			module = newModule, -- save reference to weapon module
			lastFire = 0, -- initialize last fire time to 0
			ammo = newModule.maxAmmo, -- set current ammo to max ammo from weapon's module
			reloading = false, -- initialize reloading boolean to false
		}
	end)
end)
