type keycodesType = {
	Keyboard: { Enum.KeyCode }?,
	Gamepad: { Enum.KeyCode }?,
	Mobile: { GuiButton }?,
}

type directions2DType = {
	Keyboard: { Down: Enum.KeyCode, Left: Enum.KeyCode, Right: Enum.KeyCode, Up: Enum.KeyCode }?,
	Gamepad: Enum.KeyCode?,
}

export type inputType = typeof(setmetatable({}, {})) & {
	context: InputContext,
	input: InputAction,
	bindings: { keyboard: InputBinding, gamepad: InputBinding },
	pressed: RBXScriptSignal?,
	released: RBXScriptSignal?,
	stateChanged: RBXScriptSignal,
}

local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")

local localPlayer = players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local input = {}
input.__index = input

local contexts = {}
local lastContextStates = {}

guiService.MenuOpened:Connect(function()
	for i, v in contexts do
		lastContextStates[i] = v.Enabled
		v.Enabled = false
	end
end)

guiService.MenuClosed:Connect(function()
	for i, v in contexts do
		v.Enabled = lastContextStates[i]
	end
end)

function input.new(context: string, name: string, keycodes: keycodesType): inputType
	local self = setmetatable({}, input)

	self.gui = self:SetupGui()

	self.context = self:SetupContext(context)
	self.input = self:CreateInput(name)
	self.bindings = {
		keyboard = self:BindKeycodes("Keyboard", keycodes.Keyboard),
		gamepad = self:BindKeycodes("Gamepad", keycodes.Gamepad),
		mobile = self:BindUI("Mobile", keycodes.Mobile),
	}
	self.uiButtons = {}

	self.pressed = self.input.Pressed
	self.released = self.input.Released
	self.stateChanged = self.input.StateChanged

	return self
end

function input.direction2D(context: string, name: string, directions: directions2DType): inputType
	local self = setmetatable({}, input)

	self.gui = self:SetupGui()

	self.context = self:SetupContext(context)
	self.input = self:CreateInput(name)
	self.bindings = {
		keyboard = self:Bind2D("Controls", directions.Keyboard),
		gamepad = self:BindJoystick("Controls", directions.Gamepad),
	}

	self.input.Type = Enum.InputActionType.Direction2D

	self.stateChanged = self.input.StateChanged

	return self
end

function input:SetupGui()
	local gui = playerGui:FindFirstChild("InputService")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "InputService"
		if not self:IsMobile() then
			gui.Enabled = false
		end
		gui.Parent = playerGui
	end
	return gui
end

function input:SetupContext(name: string)
	if not self.gui then
		return
	end

	local context = self.gui:FindFirstChild(name)
	if context then
		return context
	end
	context = Instance.new("InputContext")
	context.Name = name
	context.Parent = self.gui

	table.insert(contexts, context)

	return context
end

function input:CreateInput(name: string)
	if not self.context then
		return
	end

	local newInput = self.context:FindFirstChild(name)
	if newInput then
		return newInput
	end

	newInput = Instance.new("InputAction")
	newInput.Name = name
	newInput.Parent = self.context
	return newInput
end

function input:BindUI(bindName: string, buttons: { GuiButton }?)
	if not self.context or not self.input then
		return
	end

	if not buttons then
		return
	end

	local newBindings = {}

	for i, v in buttons do
		local binding = self.input:FindFirstChild(bindName .. i)
		if binding then
			binding.UIButton = v
		else
			binding = Instance.new("InputBinding")
			binding.Name = bindName .. i
			binding.UIButton = v
			binding.Parent = self.input
		end

		if self:IsMobile() then
			v.Parent = self.gui
			table.insert(self.uiButtons, v)
		else
			v:Destroy()
		end
		table.insert(newBindings, binding)
	end

	return newBindings
end

function input:Bind2D(
	bindName: string,
	keycodes: { Down: Enum.KeyCode, Up: Enum.KeyCode, Left: Enum.KeyCode, Right: Enum.KeyCode }
)
	if not self.context or not self.input then
		return
	end

	if not keycodes then
		return
	end

	local binding = self.input:FindFirstChild(bindName)

	if binding then
		binding.Down = keycodes.Down
		binding.Up = keycodes.Up
		binding.Left = keycodes.Left
		binding.Right = keycodes.Right
	else
		binding = Instance.new("InputBinding")
		binding.Name = bindName
		binding.Down = keycodes.Down
		binding.Up = keycodes.Up
		binding.Left = keycodes.Left
		binding.Right = keycodes.Right
		binding.Parent = self.input
	end

	return binding
end

function input:BindJoystick(bindName: string, keycode: Enum.KeyCode)
	if not self.context or not self.input then
		return
	end

	if not keycode then
		return
	end

	local binding = self.input:FindFirstChild(bindName)

	if binding then
		binding.KeyCode = keycode
	else
		binding = Instance.new("InputBinding")
		binding.KeyCode = keycode
		binding.Parent = self.input
	end

	return binding
end

function input:BindKeycodes(bindName: string, keycodes: { Enum.KeyCode })
	if not self.context or not self.input then
		return
	end

	if not keycodes then
		return
	end

	local newBindings = {}

	for i, v in keycodes do
		local binding = self.input:FindFirstChild(bindName .. i)
		if binding then
			binding.KeyCode = v
		else
			binding = Instance.new("InputBinding")
			binding.Name = bindName .. i
			binding.KeyCode = v
			binding.Parent = self.input
		end
		table.insert(newBindings, binding)
	end

	return newBindings
end

function input:IsMobile()
	return not userInputService.KeyboardEnabled and not userInputService.GamepadEnabled
end

function input:Destroy()
	if self.context then
		self.context:Destroy()
	end
	if self.uiButtons then
		for _, v in self.uiButtons do
			if v then
				v:Destroy()
			end
		end
	end
	self = nil
end

return input
