local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = {
	canAim = true,
	firerate = 0.125,
	reloadTime = 1,

	animations = {
		fire = 18389819726,
		reload = 18405997889,
	},
	sounds = {
		fire = ReplicatedStorage.Sounds.M4A1.Fire,
		reload = ReplicatedStorage.Sounds.M4A1.Reload,
	},

	maxAmmo = 30,
}

return Settings
