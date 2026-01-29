-- static variables
local MAX_ANGLE = math.pi / 16
local MAX_DISTANCE = 500

function validateHit(character, target) -- return validateHit function
	local root = character.HumanoidRootPart -- get the humanoid root part of the character

	local targetCharacter = target.Parent -- get the character model of the target humanoid
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart") -- get the humanoid root part of the target character

	local direction = root.Position - targetRoot.Position -- calculate direction vector from player's root part to target's root part
	local playerLookVector = root.CFrame.LookVector -- get the look vector of the player's root part
	local distance = direction.Magnitude -- calculate distance between player and target's root parts
	if distance > MAX_DISTANCE then -- check if distance exceeds maximum allowed distance
		return false -- return false if distance is too great
	end
	local angle = math.abs(math.atan2(direction.Z, direction.X) - math.atan2(playerLookVector.Z, playerLookVector.X)) -- calculate angle between player's look vector and direction vector
		- math.pi

	if angle > MAX_ANGLE then -- check if angle exceeds maximum allowed angle
		return false -- return false if angle is too great
	end

	local raycastParams = RaycastParams.new() -- create new raycast parameters
	raycastParams.FilterDescendantsInstances = { character } -- set instances to be ignored by raycast

	local raycast = workspace:Raycast( -- perform raycast from player's root part towards target's root part
		character.HumanoidRootPart.Position,
		(target.Parent.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Unit * MAX_DISTANCE,
		raycastParams
	)

	if not raycast or raycast.Instance == nil then -- check if raycast hit something
		return false
	end

	local rayCharacter = raycast.Instance:FindFirstAncestorOfClass("Model") -- check if hit instance is part of a model
	if not rayCharacter then -- check if it found a model
		return false
	end
	local rayHumanoid = rayCharacter:FindFirstChild("Humanoid") -- get humanoid from hit model
	if rayHumanoid == nil or rayHumanoid ~= target then -- check if it found it and check if hit humanoid is the same as target humanoid
		return false
	end

	return true -- return true if all checks passed
end

return validateHit
