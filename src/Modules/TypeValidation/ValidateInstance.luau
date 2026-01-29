local function validateInstance(
	instance: Instance,
	expectedClass: string
): boolean -- function to validate if an instance is of expected class
	if typeof(instance) ~= "Instance" then -- check if the provided argument is an instance
		return false -- return false if it is not
	end

	return instance:IsA(expectedClass) -- check if instance is of expected class and return the result
end

return validateInstance -- return the validateInstance function
