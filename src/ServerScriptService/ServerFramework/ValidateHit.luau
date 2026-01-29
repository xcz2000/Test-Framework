local MAX_ANGLE = math.pi / 16
local MAX_DISTANCE = 500

return function(player, target)
	local character = player.Character
	local root = character.HumanoidRootPart

	local targetCharacter = target.Parent
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")

	local direction = root.Position - targetRoot.Position
	local playerLookVector = root.CFrame.LookVector
	local distance = direction.Magnitude
	if distance > MAX_DISTANCE then
		return false
	end

	local angle = math.abs(math.atan2(direction.Z, direction.X) - math.atan2(playerLookVector.Z, playerLookVector.X))
		- math.pi

	if angle > MAX_ANGLE then
		return false
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { player.Character }

	local raycast = workspace:Raycast(
		player.Character.HumanoidRootPart.Position,
		(target.Parent.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Unit * MAX_DISTANCE,
		raycastParams
	)

	if not raycast or raycast.Instance == nil then
		return false
	end

	local rayCharacter = raycast.Instance:FindFirstAncestorOfClass("Model")
	if not rayCharacter then
		return false
	end
	local rayHumanoid = rayCharacter:FindFirstChild("Humanoid")
	if rayHumanoid == nil or rayHumanoid ~= target then
		return false
	end

	return true
end
