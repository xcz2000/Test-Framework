local validateVector3 = require(script.Parent.ValidateVector3)

local function validateCFrame(cframe: CFrame): boolean
	if typeof(cframe) ~= "CFrame" then
		return false
	end

	if not validateVector3(cframe.Position) then
		return false
	end

	if not validateVector3(cframe.LookVector) then
		return false
	end

	return true
end

return validateCFrame
