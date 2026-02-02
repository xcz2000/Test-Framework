-- require services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- specify settings for M4A1 weapon
local Settings = {
	firerate = 0.25,
	reloadTime = 2.6,

	animations = {
		fire = 18632452850,
		equip = 18633256689,
		unequip = 18633368223,
		reload = 18637585411,
	},
	sounds = {
		fire = ReplicatedStorage.Sounds.M45A1.Fire,
		equip = ReplicatedStorage.Sounds.M45A1.Equip,
		unequip = ReplicatedStorage.Sounds.M45A1.Unequip,
		reload = ReplicatedStorage.Sounds.M45A1.Reload,
	},

	maxAmmo = 7,
}

return Settings -- return settings module
