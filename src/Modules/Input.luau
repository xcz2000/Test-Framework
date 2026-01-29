-- input action wrapper module

-- create types for input module
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

-- require services
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")

-- get player and wait for playergui
local localPlayer = players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local input = {}
input.__index = input

local contexts = {} -- table to hold all created input contexts
local lastContextStates = {} -- table to hold last enabled contexts

guiService.MenuOpened:Connect(function() -- disable all input contexts when menu is opened
	for i, v in contexts do -- loop through all created contexts
		lastContextStates[i] = v.Enabled -- save last enabled state of each context
		v.Enabled = false -- disable context
	end
end)

guiService.MenuClosed:Connect(function() -- restore all input contexts when menu is closed
	for i, v in contexts do -- loop through all created contexts
		v.Enabled = lastContextStates[i] -- restore last enabled state of each context
	end
end)

function input.new(
	context: string,
	name: string,
	keycodes: keycodesType
): inputType -- constructor function for input action wrapper module
	local self = setmetatable({}, input) -- create a metatable

	self.gui = self:SetupGui() -- call setup gui method and save reference to new gui

	self.context = self:SetupContext(context) -- call setup context method and save reference to new context
	self.input = self:CreateInput(name) -- call create input method and save reference to new input action
	self.bindings = { -- create a bindings table to hold all created input bindings
		keyboard = self:BindKeycodes("Keyboard", keycodes.Keyboard), -- call bind keycodes method to create keyboard bindings
		gamepad = self:BindKeycodes("Gamepad", keycodes.Gamepad), -- call bind keycodes method to create gamepad bindings
		mobile = self:BindUI("Mobile", keycodes.Mobile), -- call bind ui method to create mobile buttons
	}
	self.uiButtons = {} -- create a table to hold ui buttons for mobile

	self.pressed = self.input.Pressed -- reference to pressed event
	self.released = self.input.Released -- reference to released event
	self.stateChanged = self.input.StateChanged -- reference to state changed event

	return self -- return metatable
end

function input.direction2D(
	context: string,
	name: string,
	directions: directions2DType
): inputType -- constructor function for 2D directional input action wrapper module
	local self = setmetatable({}, input) -- create a metatable

	self.gui = self:SetupGui() -- call setup gui method and save reference to new gui

	self.context = self:SetupContext(context) -- call setup context method and save reference to new context
	self.input = self:CreateInput(name) -- call create input method and save reference to new input action
	self.bindings = { -- create a bindings table to hold all created input bindings
		keyboard = self:Bind2D("Controls", directions.Keyboard), -- call bind 2D method to create keyboard directional bindings
		gamepad = self:BindJoystick("Controls", directions.Gamepad), -- call bind joystick method to create gamepad joystick binding
	}

	self.input.Type = Enum.InputActionType.Direction2D -- set input action type to Direction2D

	self.stateChanged = self.input.StateChanged -- reference to state changed event

	return self -- return metatable
end

function input:SetupGui() -- setup gui method
	local gui = playerGui:FindFirstChild("InputService") -- find existing input service gui
	if not gui then -- if it does not exist, create a new one
		gui = Instance.new("ScreenGui") -- create new screengui instance
		gui.Name = "InputService" -- set name of gui
		if not self:IsMobile() then -- check if not mobile
			gui.Enabled = false -- disable gui if not mobile
		end
		gui.Parent = playerGui -- parent gui to playergui
	end
	return gui -- return gui
end

function input:SetupContext(name: string) -- setup context method
	if not self.gui then -- check if gui reference exists
		return -- return if it does not
	end

	local context = self.gui:FindFirstChild(name) -- find existing context by name
	if context then -- if context exists, return it
		return context
	end
	context = Instance.new("InputContext") -- create new input context instance
	context.Name = name -- set name of context
	context.Parent = self.gui -- parent context to gui

	table.insert(contexts, context) -- add context to contexts table

	return context -- return context
end

function input:CreateInput(name: string) -- create input method
	if not self.context then -- if context reference does not exist then return
		return
	end

	local newInput = self.context:FindFirstChild(name) -- find existing input action by name
	if newInput then -- if input action exists, return it
		return newInput
	end

	newInput = Instance.new("InputAction") -- create new input action instance
	newInput.Name = name -- set name of input action
	newInput.Parent = self.context -- parent input action to context
	return newInput -- return input action
end

function input:BindUI(bindName: string, buttons: { GuiButton }?) -- bind ui method
	if not self.context or not self.input then -- check if context and input references exist
		return -- if not then return
	end

	if not buttons then -- check if buttons argument exists
		return -- return if not
	end

	local newBindings = {} -- create a table to hold new bindings

	for i, v in buttons do -- loop through all provided buttons
		local binding = self.input:FindFirstChild(bindName .. i) -- find existing binding by name
		if binding then -- if binding exists,
			binding.UIButton = v -- update its UIButton property
		else
			binding = Instance.new("InputBinding") -- create new input binding instance
			binding.Name = bindName .. i -- set name of binding
			binding.UIButton = v -- set UIButton property of binding
			binding.Parent = self.input -- parent binding to input action
		end

		if self:IsMobile() then -- check if mobile
			v.Parent = self.gui -- parent button to gui
			table.insert(self.uiButtons, v) -- add button to ui buttons table
		else
			v:Destroy() -- destroy button if not mobile
		end
		table.insert(newBindings, binding) -- add binding to new bindings table
	end

	return newBindings -- return new bindings table
end

function input:Bind2D(
	bindName: string,
	keycodes: { Down: Enum.KeyCode, Up: Enum.KeyCode, Left: Enum.KeyCode, Right: Enum.KeyCode }
) -- bind 2D input method
	if not self.context or not self.input then -- check if context and input references exist
		return -- return if not
	end

	if not keycodes then -- check if keycodes argument exists
		return -- return if not
	end

	local binding = self.input:FindFirstChild(bindName) -- find existing binding by name

	if binding then -- if it exists update its properties
		binding.Down = keycodes.Down
		binding.Up = keycodes.Up
		binding.Left = keycodes.Left
		binding.Right = keycodes.Right
	else -- if it does not exist, create a new one and set its properties
		binding = Instance.new("InputBinding")
		binding.Name = bindName -- set name of binding
		binding.Down = keycodes.Down
		binding.Up = keycodes.Up
		binding.Left = keycodes.Left
		binding.Right = keycodes.Right
		binding.Parent = self.input -- parent new binding to an input instance
	end

	return binding -- return binding
end

function input:BindJoystick(bindName: string, keycode: Enum.KeyCode) -- bind joystick method
	if not self.context or not self.input then -- check if context and input references exist
		return -- return if not
	end

	if not keycode then -- check if keycode argument exists
		return -- return if not
	end

	local binding = self.input:FindFirstChild(bindName) -- find existing binding by name

	if binding then -- if it exists, update its KeyCode property
		binding.KeyCode = keycode
	else -- if it does not exist, create a new one and set its KeyCode property
		binding = Instance.new("InputBinding") -- create a new input binding instance
		binding.KeyCode = keycode -- update its KeyCode property
		binding.Parent = self.input -- parent it to an input instance
	end

	return binding -- return new binding
end

function input:BindKeycodes(bindName: string, keycodes: { Enum.KeyCode }) -- bind keycodes method
	if not self.context or not self.input then -- check if context and input references exist
		return -- if not then return
	end

	if not keycodes then -- check if keycodes argument exists
		return -- return if not
	end

	local newBindings = {} -- create a table to hold new bindings

	for i, v in keycodes do -- loop through all provided keycodes
		local binding = self.input:FindFirstChild(bindName .. i) -- find existing binding by name
		if binding then -- if binding exists,
			binding.KeyCode = v -- update its KeyCode property
		else -- if it does not exist, create a new one and set its KeyCode property
			binding = Instance.new("InputBinding") -- create new input binding instance
			binding.Name = bindName .. i -- set name of binding
			binding.KeyCode = v -- set KeyCode property of binding
			binding.Parent = self.input -- parent binding to input action
		end
		table.insert(newBindings, binding) -- add binding to new bindings table
	end

	return newBindings -- return new bindings table
end

function input:IsMobile() -- method to check if device is mobile
	return not userInputService.KeyboardEnabled and not userInputService.GamepadEnabled -- return true if both keyboard and gamepad are not enabled
end

function input:Destroy() -- destroy method to clean up created instances
	if self.context then -- check if context reference exists
		self.context:Destroy() -- destroy context if it exists
	end
	if self.uiButtons then -- check if ui buttons table exists
		for _, v in self.uiButtons do -- loop through all buttons in the table
			if v then -- check if button exists
				v:Destroy() -- destroy button if it exists
			end
		end
	end
	self = nil -- set self to nil to help with garbage collection
end

return input -- return input action wrapper module
