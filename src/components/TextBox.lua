--!nonstrict
-- Aero7: components/TextBox - Windows 7 single-line Edit Control and multi-line TextArea (ES_MULTILINE).

local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")

local TextBox = {}

function TextBox.new(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "Text Input"
	local defaultText = tostring(options.Default or options.Value or "")
	local placeholder = tostring(options.Placeholder or "Enter text...")
	local clearOnFocus = options.ClearTextOnFocus == true
	local numericOnly = options.Numeric == true
	local isMultiLine = options.MultiLine == true or options.TextArea == true
	local callback = options.Callback or function() end

	local row
	local editWrap
	local inputBox
	local topInnerShadow

	if isMultiLine then
		local boxHeight = tonumber(options.Height) or 68
		local hasTitle = (title ~= "" and title ~= "Text Input")

		row = Utility.Create("Frame", {
			Name = "TextArea_" .. title,
			Parent = parentContainer,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, boxHeight + (hasTitle and 22 or 0) + 4),
			LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
			ZIndex = parentContainer.ZIndex + 1,
		})

		local currentY = 0
		if hasTitle then
			Utility.Create("TextLabel", {
				Name = "EditLabel",
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 18),
				Font = Theme.Fonts.Regular,
				Text = title,
				TextColor3 = Theme.Colors.TextPrimary,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = row.ZIndex + 1,
			})
			currentY = 20
		end

		editWrap = Utility.Create("Frame", {
			Name = "Win7EditBoxFrame",
			Parent = row,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0, 0, 0, currentY),
			Size = UDim2.new(1, 0, 0, boxHeight),
			ZIndex = row.ZIndex + 1,
		})
		Utility.AddCorner(editWrap, 1)
		local editStroke = Utility.AddStroke(editWrap, Theme.Colors.EditBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

		topInnerShadow = Utility.Create("Frame", {
			Name = "TopInsetShadow",
			Parent = editWrap,
			BackgroundColor3 = Theme.Colors.EditInnerShadow,
			Position = UDim2.new(0, 1, 0, 0),
			Size = UDim2.new(1, -2, 0, 1),
			ZIndex = editWrap.ZIndex + 1,
		})

		inputBox = Utility.Create("TextBox", {
			Name = "EditInput",
			Parent = editWrap,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 6, 0, 4),
			Size = UDim2.new(1, -12, 1, -8),
			ClearTextOnFocus = clearOnFocus,
			Font = Theme.Fonts.Regular,
			MultiLine = true,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			PlaceholderText = placeholder,
			PlaceholderColor3 = Color3.fromRGB(142, 148, 156),
			Text = defaultText,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = editWrap.ZIndex + 2,
		})

		local focused = false
		editWrap.MouseEnter:Connect(function()
			if not focused then
				editStroke.Color = Theme.Colors.EditBorderHover
			end
		end)
		editWrap.MouseLeave:Connect(function()
			if not focused then
				editStroke.Color = Theme.Colors.EditBorderNormal
			end
		end)

		inputBox.Focused:Connect(function()
			focused = true
			editStroke.Color = Theme.Colors.EditBorderFocused
			topInnerShadow.BackgroundColor3 = Color3.fromRGB(192, 222, 246)
		end)

		inputBox.FocusLost:Connect(function()
			focused = false
			editStroke.Color = Theme.Colors.EditBorderNormal
			topInnerShadow.BackgroundColor3 = Theme.Colors.EditInnerShadow
		end)
	else
		row = Utility.Create("Frame", {
			Name = "TextBox_" .. title,
			Parent = parentContainer,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 25),
			LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
			ZIndex = parentContainer.ZIndex + 1,
		})

		Utility.Create("TextLabel", {
			Name = "EditLabel",
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

		editWrap = Utility.Create("Frame", {
			Name = "Win7EditBoxFrame",
			Parent = row,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0.44, 0, 0, 1),
			Size = UDim2.new(0.56, 0, 0, 23),
			ZIndex = row.ZIndex + 1,
		})
		Utility.AddCorner(editWrap, 1)
		local editStroke = Utility.AddStroke(editWrap, Theme.Colors.EditBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

		topInnerShadow = Utility.Create("Frame", {
			Name = "TopInsetShadow",
			Parent = editWrap,
			BackgroundColor3 = Theme.Colors.EditInnerShadow,
			Position = UDim2.new(0, 1, 0, 0),
			Size = UDim2.new(1, -2, 0, 1),
			ZIndex = editWrap.ZIndex + 1,
		})

		inputBox = Utility.Create("TextBox", {
			Name = "EditInput",
			Parent = editWrap,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 6, 0, 1),
			Size = UDim2.new(1, -12, 1, -2),
			ClearTextOnFocus = clearOnFocus,
			Font = Theme.Fonts.Regular,
			PlaceholderText = placeholder,
			PlaceholderColor3 = Color3.fromRGB(142, 148, 156),
			Text = defaultText,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = editWrap.ZIndex + 2,
		})

		local focused = false
		editWrap.MouseEnter:Connect(function()
			if not focused then
				editStroke.Color = Theme.Colors.EditBorderHover
			end
		end)
		editWrap.MouseLeave:Connect(function()
			if not focused then
				editStroke.Color = Theme.Colors.EditBorderNormal
			end
		end)

		inputBox.Focused:Connect(function()
			focused = true
			editStroke.Color = Theme.Colors.EditBorderFocused
			topInnerShadow.BackgroundColor3 = Color3.fromRGB(192, 222, 246)
		end)

		inputBox.FocusLost:Connect(function()
			focused = false
			editStroke.Color = Theme.Colors.EditBorderNormal
			topInnerShadow.BackgroundColor3 = Theme.Colors.EditInnerShadow
		end)
	end

	local controller = {
		Row = row,
		Input = inputBox,
		Value = defaultText,
	}

	function controller:SetValue(newVal, silent)
		local s = tostring(newVal or "")
		if numericOnly then
			s = s:gsub("[^%d%.%-]", "")
		end
		self.Value = s
		inputBox.Text = s
		if not silent then
			callback(s)
		end
	end

	inputBox.FocusLost:Connect(function(enterPressed)
		controller:SetValue(inputBox.Text, false)
		if options.OnEnter and enterPressed then
			options.OnEnter(controller.Value)
		end
	end)

	if options.LiveChange then
		inputBox:GetPropertyChangedSignal("Text"):Connect(function()
			controller.Value = inputBox.Text
			callback(controller.Value)
		end)
	end

	if options.Tooltip then
		Tooltip.Attach(editWrap, options.Tooltip)
	end

	return controller
end

function TextBox.CreateTextArea(parentContainer, options)
	options = options or {}
	options.MultiLine = true
	return TextBox.new(parentContainer, options)
end

return TextBox
