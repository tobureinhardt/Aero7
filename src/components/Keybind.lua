--!nonstrict
-- Aero7: components/Keybind - Windows 7 shortcut key input box with toggle/hold/always modes.

local UserInputService = game:GetService("UserInputService")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")

local Keybind = {}

local function formatKeyName(keyCode)
	if not keyCode or keyCode == Enum.KeyCode.Unknown then
		return "None"
	end
	local name = keyCode.Name
	local map = {
		RightShift = "Right Shift",
		LeftShift = "Left Shift",
		RightControl = "Right Ctrl",
		LeftControl = "Left Ctrl",
		RightAlt = "Right Alt",
		LeftAlt = "Left Alt",
	}
	return map[name] or name
end

function Keybind.new(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "Shortcut key:"
	local currentKey = options.Default or options.Value or Enum.KeyCode.RightControl
	local mode = options.Mode or "Toggle" -- "Toggle", "Hold", "Always"
	local callback = options.Callback or function() end
	local onChanged = options.OnChanged or function() end

	local row = Utility.Create("Frame", {
		Name = "Keybind_" .. title,
		Parent = parentContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 25),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})

	Utility.Create("TextLabel", {
		Name = "KeybindLabel",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0.44, -6, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = row.ZIndex + 1,
	})

	-- Windows 7 shortcut key input box
	local keyBox = Utility.Create("TextButton", {
		Name = "Win7ShortcutKeyBox",
		Parent = row,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0.44, 0, 0, 1),
		Size = UDim2.new(0.56, -62, 0, 23),
		Font = Theme.Fonts.Regular,
		Text = "  " .. formatKeyName(currentKey),
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = row.ZIndex + 2,
	})
	Utility.AddCorner(keyBox, 1)
	local keyStroke = Utility.AddStroke(keyBox, Theme.Colors.EditBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

	Utility.Create("Frame", {
		Name = "TopInsetShadow",
		Parent = keyBox,
		BackgroundColor3 = Theme.Colors.EditInnerShadow,
		Position = UDim2.new(0, 1, 0, 0),
		Size = UDim2.new(1, -2, 0, 1),
		ZIndex = keyBox.ZIndex + 1,
	})

	-- Mode toggle button (Toggle / Hold / Always) 58x23 PushButton
	local modeBtn = Utility.Create("TextButton", {
		Name = "KeybindModeButton",
		Parent = row,
		Position = UDim2.new(1, -58, 0, 1),
		Size = UDim2.new(0, 58, 0, 23),
		Font = Theme.Fonts.Regular,
		Text = mode,
		TextColor3 = Theme.Colors.TextSecondary,
		TextSize = 12,
		ZIndex = row.ZIndex + 2,
	})
	Utility.BindWin7ButtonStates(modeBtn, { CornerRadius = 3 })

	local listening = false
	local activeState = (mode == "Always")

	local controller = {
		Row = row,
		Value = currentKey,
		Mode = mode,
		Active = activeState,
	}

	function controller:SetKey(newKey)
		self.Value = newKey or Enum.KeyCode.Unknown
		keyBox.Text = "  " .. formatKeyName(self.Value)
		onChanged(self.Value)
	end

	function controller:SetMode(newMode)
		self.Mode = newMode
		modeBtn.Text = newMode
		if newMode == "Always" then
			self.Active = true
			callback(true, self.Value)
		end
	end

	keyBox.MouseEnter:Connect(function()
		if not listening then
			keyStroke.Color = Theme.Colors.EditBorderHover
		end
	end)
	keyBox.MouseLeave:Connect(function()
		if not listening then
			keyStroke.Color = Theme.Colors.EditBorderNormal
		end
	end)

	keyBox.MouseButton1Click:Connect(function()
		listening = true
		keyStroke.Color = Theme.Colors.EditBorderFocused
		keyBox.Text = "  Press a key..."
		keyBox.TextColor3 = Theme.Colors.TextInstruction
	end)

	local modes = { "Toggle", "Hold", "Always" }
	modeBtn.MouseButton1Click:Connect(function()
		local idx = table.find(modes, controller.Mode) or 1
		local nextMode = modes[(idx % #modes) + 1]
		controller:SetMode(nextMode)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				keyStroke.Color = Theme.Colors.EditBorderNormal
				keyBox.TextColor3 = Theme.Colors.TextPrimary
				if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
					controller:SetKey(Enum.KeyCode.Unknown)
				else
					controller:SetKey(input.KeyCode)
				end
			end
			return
		end

		if not gameProcessed and controller.Value ~= Enum.KeyCode.Unknown and input.KeyCode == controller.Value then
			if controller.Mode == "Toggle" then
				controller.Active = not controller.Active
				callback(controller.Active, controller.Value)
			elseif controller.Mode == "Hold" then
				controller.Active = true
				callback(true, controller.Value)
			elseif controller.Mode == "Always" then
				controller.Active = true
				callback(true, controller.Value)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not listening and controller.Mode == "Hold" and controller.Value ~= Enum.KeyCode.Unknown and input.KeyCode == controller.Value then
			controller.Active = false
			callback(false, controller.Value)
		end
	end)

	if options.Tooltip then
		Tooltip.Attach(keyBox, options.Tooltip)
	end

	return controller
end

return Keybind
