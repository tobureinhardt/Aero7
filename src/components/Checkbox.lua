--!nonstrict
-- Aero7: components/Checkbox - Standard Windows 7 14x14px Checkbox with tri-state support (Common Controls v6).

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")

local Checkbox = {}

function Checkbox.new(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "Checkbox Option"
	local triState = options.TriState == true
	local initialRaw = (options.Default ~= nil) and options.Default or options.Value
	local value
	if initialRaw == "Indeterminate" then
		value = "Indeterminate"
	else
		value = (initialRaw == true)
	end
	local callback = options.Callback or function() end

	local rowBtn = Utility.Create("TextButton", {
		Name = "Checkbox_" .. title,
		Parent = parentContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		Text = "",
		ZIndex = parentContainer.ZIndex + 1,
	})

	-- Standard Windows 7 14x14px box
	local boxOuter = Utility.Create("Frame", {
		Name = "CheckBoxOuter",
		Parent = rowBtn,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 0.5, -7),
		Size = UDim2.new(0, 14, 0, 14),
		ZIndex = rowBtn.ZIndex + 1,
	})
	Utility.AddCorner(boxOuter, 2)
	local outerStroke = Utility.AddStroke(boxOuter, Theme.Colors.ControlBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

	-- Inset bevel background
	local boxInner = Utility.Create("Frame", {
		Name = "CheckBoxInnerInset",
		Parent = boxOuter,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = boxOuter.ZIndex + 1,
	})
	local innerStroke = Utility.AddStroke(boxInner, Color3.fromRGB(208, 212, 216), 1, 0.15, Enum.ApplyStrokeMode.Border)

	local fillGrad = Instance.new("UIGradient")
	fillGrad.Rotation = 135
	fillGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(235, 238, 242)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(248, 249, 251)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
	})
	fillGrad.Parent = boxInner

	-- Checkmark glyph
	local checkIcon = Utility.Create("ImageLabel", {
		Name = "CheckmarkGlyph",
		Parent = boxInner,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Visible = (value == true),
		ZIndex = boxInner.ZIndex + 2,
	})
	Assets.BindIcon(checkIcon, "Checkmark")

	local checkScale = Instance.new("UIScale")
	checkScale.Scale = (value == true) and 1 or 0.4
	checkScale.Parent = checkIcon

	-- Centered teal square for Tri-State Indeterminate state (BS_3STATE per 7.css)
	local indeterminateBox = Utility.Create("Frame", {
		Name = "IndeterminateFill",
		Parent = boxInner,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0.5, -4, 0.5, -4),
		Size = UDim2.new(0, 8, 0, 8),
		Visible = (value == "Indeterminate"),
		ZIndex = boxInner.ZIndex + 2,
	})
	Utility.AddCorner(indeterminateBox, 1)
	Utility.AddStroke(indeterminateBox, Color3.fromRGB(16, 72, 130), 1, 0, Enum.ApplyStrokeMode.Border)
	local indGrad = Instance.new("UIGradient")
	indGrad.Rotation = 90
	indGrad.Color = Theme.MakeSplitSequence(
		Color3.fromRGB(124, 206, 252),
		Color3.fromRGB(48, 152, 226),
		Color3.fromRGB(20, 108, 184),
		Color3.fromRGB(42, 146, 220)
	)
	indGrad.Parent = indeterminateBox

	-- Checkbox text label
	local label = Utility.Create("TextLabel", {
		Name = "CheckboxLabel",
		Parent = rowBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 21, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = rowBtn.ZIndex + 1,
	})

	local hovered = false
	local pressed = false
	local disabled = false

	local function refreshBox()
		if disabled then
			outerStroke.Color = Theme.Colors.ControlBorderDisabled
			innerStroke.Color = Color3.fromRGB(228, 228, 228)
			label.TextColor3 = Theme.Colors.TextDisabled
			return
		end

		if pressed then
			outerStroke.Color = Theme.Colors.ControlBorderPressed
			innerStroke.Color = Color3.fromRGB(132, 188, 228)
			fillGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(186, 222, 248)),
				ColorSequenceKeypoint.new(1.0, Color3.fromRGB(224, 242, 254)),
			})
		elseif hovered then
			outerStroke.Color = Theme.Colors.ControlBorderHover
			innerStroke.Color = Color3.fromRGB(162, 214, 252)
			fillGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(218, 238, 253)),
				ColorSequenceKeypoint.new(1.0, Color3.fromRGB(244, 250, 255)),
			})
		else
			outerStroke.Color = Theme.Colors.ControlBorderNormal
			innerStroke.Color = Color3.fromRGB(208, 212, 216)
			fillGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(235, 238, 242)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(248, 249, 251)),
				ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
			})
		end
	end

	local controller = {
		Row = rowBtn,
		Value = value,
	}

	function controller:SetValue(newVal, silent)
		if newVal == "Indeterminate" then
			self.Value = "Indeterminate"
			checkIcon.Visible = false
			checkScale.Scale = 0.4
			indeterminateBox.Visible = true
		elseif newVal == true then
			self.Value = true
			indeterminateBox.Visible = false
			checkIcon.Visible = true
			checkScale.Scale = 0.55
			Utility.Tween(checkScale, 0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1.0 })
		else
			self.Value = false
			indeterminateBox.Visible = false
			checkIcon.Visible = false
			checkScale.Scale = 0.4
		end
		if not silent then
			callback(self.Value)
		end
	end

	function controller:SetIndeterminate(silent)
		self:SetValue("Indeterminate", silent)
	end

	function controller:SetDisabled(dis)
		disabled = (dis == true)
		refreshBox()
	end

	rowBtn.MouseEnter:Connect(function()
		hovered = true
		refreshBox()
	end)
	rowBtn.MouseLeave:Connect(function()
		hovered = false
		pressed = false
		refreshBox()
	end)
	rowBtn.MouseButton1Down:Connect(function()
		if not disabled then
			pressed = true
			refreshBox()
		end
	end)
	rowBtn.MouseButton1Up:Connect(function()
		if pressed then
			pressed = false
			refreshBox()
		end
	end)
	rowBtn.MouseButton1Click:Connect(function()
		if not disabled then
			if triState then
				if controller.Value == false then
					controller:SetValue(true)
				elseif controller.Value == true then
					controller:SetValue("Indeterminate")
				else
					controller:SetValue(false)
				end
			else
				controller:SetValue(controller.Value ~= true)
			end
		end
	end)

	if options.Tooltip then
		Tooltip.Attach(rowBtn, options.Tooltip)
	end

	return controller
end

return Checkbox
