--!nonstrict
-- Aero7: components/RadioGroup - Windows 7 Radio Button group with Aero gemstone center.

local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")

local RadioGroup = {}

function RadioGroup.new(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Label
	local items = options.Options or options.Items or { "Option 1", "Option 2" }
	local currentValue = options.Default or options.Value or items[1]
	local callback = options.Callback or function() end

	local wrapper = Utility.Create("Frame", {
		Name = "RadioGroup_" .. tostring(title or "Group"),
		Parent = parentContainer,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = wrapper

	if title and title ~= "" then
		Utility.Create("TextLabel", {
			Name = "RadioGroupHeader",
			Parent = wrapper,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = 0,
			Font = Theme.Fonts.Regular,
			Text = title,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = wrapper.ZIndex + 1,
		})
	end

	local radioEntries = {}
	local controller = {
		Wrapper = wrapper,
		Value = currentValue,
	}

	for idx, itemText in ipairs(items) do
		local rowBtn = Utility.Create("TextButton", {
			Name = "RadioItem_" .. tostring(itemText),
			Parent = wrapper,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			LayoutOrder = idx,
			Text = "",
			ZIndex = wrapper.ZIndex + 1,
		})

		local ringOuter = Utility.Create("Frame", {
			Name = "RadioRingOuter",
			Parent = rowBtn,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0, 0, 0.5, -7),
			Size = UDim2.new(0, 14, 0, 14),
			ZIndex = rowBtn.ZIndex + 1,
		})
		Utility.AddCorner(ringOuter, 7)
		local outerStroke = Utility.AddStroke(ringOuter, Theme.Colors.ControlBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

		local ringGrad = Instance.new("UIGradient")
		ringGrad.Rotation = 135
		ringGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(232, 236, 240)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
		})
		ringGrad.Parent = ringOuter

		-- Aero teal gemstone center when selected
		local pearlDot = Utility.Create("Frame", {
			Name = "AeroPearlCenter",
			Parent = ringOuter,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 6, 0, 6),
			Visible = (itemText == currentValue),
			ZIndex = ringOuter.ZIndex + 2,
		})
		Utility.AddCorner(pearlDot, 3)
		Utility.AddStroke(pearlDot, Color3.fromRGB(16, 72, 136), 1, 0.1, Enum.ApplyStrokeMode.Border)

		local pearlGrad = Instance.new("UIGradient")
		pearlGrad.Rotation = 90
		pearlGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(98, 228, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(28, 148, 232)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(10, 78, 168)),
		})
		pearlGrad.Parent = pearlDot

		Utility.Create("TextLabel", {
			Name = "RadioLabel",
			Parent = rowBtn,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 21, 0, 0),
			Size = UDim2.new(1, -24, 1, 0),
			Font = Theme.Fonts.Regular,
			Text = tostring(itemText),
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = rowBtn.ZIndex + 1,
		})

		rowBtn.MouseEnter:Connect(function()
			outerStroke.Color = Theme.Colors.ControlBorderHover
			ringGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(218, 238, 253)),
				ColorSequenceKeypoint.new(1.0, Color3.fromRGB(246, 251, 255)),
			})
		end)

		rowBtn.MouseLeave:Connect(function()
			outerStroke.Color = Theme.Colors.ControlBorderNormal
			ringGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(232, 236, 240)),
				ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
			})
		end)

		rowBtn.MouseButton1Click:Connect(function()
			controller:SetValue(itemText)
		end)

		radioEntries[itemText] = pearlDot
	end

	function controller:SetValue(newVal, silent)
		self.Value = newVal
		for k, dot in pairs(radioEntries) do
			dot.Visible = (k == newVal)
		end
		if not silent then
			callback(newVal)
		end
	end

	if options.Tooltip then
		Tooltip.Attach(wrapper, options.Tooltip)
	end

	return controller
end

return RadioGroup
