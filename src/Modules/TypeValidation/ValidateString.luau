local function validateString(str: string): boolean
	if typeof(str) ~= "string" then
		return false
	end

	if str ~= str then
		return false
	end

	return true
end

return validateString
