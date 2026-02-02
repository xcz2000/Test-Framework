-- require services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- specify settings for M4A1 weapon
local Settings = {
	firerate = 0.125,
	reloadTime = 1,

	animations = {
		fire = 18389819726,
		reload = 18405997889,
		equip = 18379747970,
		unequip = 18380534417,
	},
	sounds = {
		fire = ReplicatedStorage.Sounds.M4A1.Fire,
		reload = ReplicatedStorage.Sounds.M4A1.Reload,
		equip = ReplicatedStorage.Sounds.M4A1.Equip,
		unequip = ReplicatedStorage.Sounds.M4A1.Unequip,
	},

	maxAmmo = 30,
}

return Settings -- return settings module
