local function validateBoolean(boolean: boolean): boolean
	if typeof(boolean) ~= "boolean" then
		return false
	end

	if boolean ~= boolean then
		return false
	end

	return true
end

return validateBoolean
