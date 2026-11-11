--!nonstrict
-- Aero7: components/Button - Windows 7 PushButton and SplitButton (Common Controls v6).

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")
local MenuBar = require("components/MenuBar")

local Button = {}

function Button.new(parentContainer, options)
	if type(options) == "string" then
		options = { Title = options }
	end
	options = options or {}

	local title = options.Title or options.Text or "Button"
	local description = options.Description or options.Label
	local buttonText = options.ButtonText or title
	local isDefault = options.IsDefault == true
	local showShield = options.Shield == true
	local iconName = options.Icon or (showShield and "Shield" or nil)
	local callback = options.Callback or function() end

	local row = Utility.Create("Frame", {
		Name = "ButtonRow_" .. title,
		Parent = parentContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 25),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})

	local btnWidth = options.Width
	local btnPos, btnSize

	if description and description ~= "" then
		Utility.Create("TextLabel", {
			Name = "RowDescription",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, -(btnWidth or 118) - 8, 1, 0),
			Font = Theme.Fonts.Regular,
			Text = description,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = row.ZIndex + 1,
		})
		local w = btnWidth or math.max(88, #buttonText * 7 + 26)
		btnPos = UDim2.new(1, -w, 0, 1)
		btnSize = UDim2.new(0, w, 0, 23)
	else
		if btnWidth then
			btnPos = UDim2.new(0, 0, 0, 1)
			btnSize = UDim2.new(0, btnWidth, 0, 23)
		else
			btnPos = UDim2.new(0, 0, 0, 1)
			btnSize = UDim2.new(1, 0, 0, 23)
		end
	end

	local pushBtn = Utility.Create("TextButton", {
		Name = "Win7PushButton",
		Parent = row,
		Position = btnPos,
		Size = btnSize,
		Text = "",
		ZIndex = row.ZIndex + 1,
	})

	local btnState = Utility.BindWin7ButtonStates(pushBtn, {
		CornerRadius = 3,
		IsDefault = isDefault,
	})

	local contentHolder = Utility.Create("Frame", {
		Name = "BtnContent",
		Parent = pushBtn,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = pushBtn.ZIndex + 2,
	})
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 5)
	list.Parent = contentHolder

	if iconName and iconName ~= "" then
		local ico = Utility.Create("ImageLabel", {
			Name = "BtnIcon",
			Parent = contentHolder,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 14, 0, 14),
			ZIndex = pushBtn.ZIndex + 3,
		})
		Assets.BindIcon(ico, iconName)
	end

	local textLabel = Utility.Create("TextLabel", {
		Name = "BtnText",
		Parent = contentHolder,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = buttonText,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		ZIndex = pushBtn.ZIndex + 3,
	})

	pushBtn.MouseButton1Click:Connect(function()
		if not btnState.Disabled then
			callback()
		end
	end)

	if options.Tooltip then
		Tooltip.Attach(pushBtn, options.Tooltip)
	end

	return {
		Row = row,
		Button = pushBtn,
		SetText = function(_, newText)
			textLabel.Text = tostring(newText or "")
		end,
		SetDisabled = function(_, dis)
			btnState:SetDisabled(dis)
			textLabel.TextColor3 = dis and Theme.Colors.TextDisabled or Theme.Colors.TextPrimary
		end,
		Fire = function()
			if not btnState.Disabled then
				callback()
			end
		end,
	}
end

-- Windows 7 SplitButton (BS_SPLITBUTTON - primary button with right drop-down arrow)
function Button.CreateSplitButton(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "Split Button"
	local description = options.Description or options.Label
	local buttonText = options.ButtonText or title
	local isDefault = options.IsDefault == true
	local showShield = options.Shield == true
	local iconName = options.Icon or (showShield and "Shield" or nil)
	local callback = options.Callback or function() end
	local menuItems = options.MenuItems or options.Items or {}

	local row = Utility.Create("Frame", {
		Name = "SplitButtonRow_" .. title,
		Parent = parentContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 25),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})

	local btnWidth = options.Width
	local btnPos, btnSize
	if description and description ~= "" then
		Utility.Create("TextLabel", {
			Name = "RowDescription",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, -(btnWidth or 132) - 8, 1, 0),
			Font = Theme.Fonts.Regular,
			Text = description,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = row.ZIndex + 1,
		})
		local w = btnWidth or math.max(106, #buttonText * 7 + 44)
		btnPos = UDim2.new(1, -w, 0, 1)
		btnSize = UDim2.new(0, w, 0, 23)
	else
		if btnWidth then
			btnPos = UDim2.new(0, 0, 0, 1)
			btnSize = UDim2.new(0, btnWidth, 0, 23)
		else
			btnPos = UDim2.new(0, 0, 0, 1)
			btnSize = UDim2.new(1, 0, 0, 23)
		end
	end

	local outerBtn = Utility.Create("Frame", {
		Name = "Win7SplitButton",
		Parent = row,
		Position = btnPos,
		Size = btnSize,
		ZIndex = row.ZIndex + 1,
	})

	local mainHit = Utility.Create("TextButton", {
		Name = "SplitMainButton",
		Parent = outerBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Text = "",
		ZIndex = outerBtn.ZIndex + 3,
	})

	local arrowHit = Utility.Create("TextButton", {
		Name = "SplitArrowButton",
		Parent = outerBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 0, 0),
		Size = UDim2.new(0, 20, 1, 0),
		Text = "",
		ZIndex = outerBtn.ZIndex + 3,
	})
	local splitChevron = Utility.CreateVectorChevron(arrowHit, "Down", Theme.Colors.TextPrimary, outerBtn.ZIndex + 4)

	-- Vertical separator between main button and drop-down arrow (BS_SPLITBUTTON)
	local dividerDark = Utility.Create("Frame", {
		Name = "SplitDividerDark",
		Parent = outerBtn,
		BackgroundColor3 = Theme.Colors.ControlBorderNormal,
		Position = UDim2.new(1, -20, 0, 3),
		Size = UDim2.new(0, 1, 1, -6),
		ZIndex = outerBtn.ZIndex + 3,
	})
	local dividerLight = Utility.Create("Frame", {
		Name = "SplitDividerLight",
		Parent = outerBtn,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.25,
		Position = UDim2.new(1, -19, 0, 3),
		Size = UDim2.new(0, 1, 1, -6),
		ZIndex = outerBtn.ZIndex + 3,
	})

	-- Attaches 50/50 split-gradient effect to button frame
	outerBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Utility.AddCorner(outerBtn, 3)
	local outerStroke = Utility.AddStroke(
		outerBtn,
		isDefault and Theme.Colors.ControlBorderHover or Theme.Colors.ControlBorderNormal,
		1,
		0,
		Enum.ApplyStrokeMode.Border
	)
	local innerHighlight = Utility.Create("Frame", {
		Name = "Win7InnerHighlight",
		Parent = outerBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = outerBtn.ZIndex + 1,
	})
	Utility.AddCorner(innerHighlight, 2)
	local innerStroke = Utility.AddStroke(
		innerHighlight,
		isDefault and Color3.fromRGB(96, 198, 252) or Color3.fromRGB(255, 255, 255),
		1,
		isDefault and 0.15 or 0.25,
		Enum.ApplyStrokeMode.Border
	)

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = Theme.Gradients.ButtonNormal
	grad.Parent = outerBtn

	local contentHolder = Utility.Create("Frame", {
		Name = "BtnContent",
		Parent = mainHit,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = mainHit.ZIndex + 1,
	})
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 5)
	list.Parent = contentHolder

	if iconName and iconName ~= "" then
		local ico = Utility.Create("ImageLabel", {
			Name = "BtnIcon",
			Parent = contentHolder,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 14, 0, 14),
			ZIndex = mainHit.ZIndex + 2,
		})
		Assets.BindIcon(ico, iconName)
	end

	local textLabel = Utility.Create("TextLabel", {
		Name = "BtnText",
		Parent = contentHolder,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = buttonText,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		ZIndex = mainHit.ZIndex + 2,
	})

	local hovered = false
	local pressed = false
	local disabled = false

	local function refreshVisual()
		if disabled then
			outerStroke.Color = Theme.Colors.ControlBorderDisabled
			dividerDark.BackgroundColor3 = Theme.Colors.ControlBorderDisabled
			grad.Color = Theme.Gradients.ButtonDisabled
			textLabel.TextColor3 = Theme.Colors.TextDisabled
			splitChevron:SetColor(Theme.Colors.TextDisabled)
			return
		end
		textLabel.TextColor3 = Theme.Colors.TextPrimary
		splitChevron:SetColor(Theme.Colors.TextPrimary)
		if pressed then
			outerStroke.Color = Theme.Colors.ControlBorderPressed
			dividerDark.BackgroundColor3 = Theme.Colors.ControlBorderPressed
			innerStroke.Color = Color3.fromRGB(130, 194, 232)
			grad.Color = Theme.Gradients.ButtonPressed
		elseif hovered then
			outerStroke.Color = Theme.Colors.ControlBorderHover
			dividerDark.BackgroundColor3 = Theme.Colors.ControlBorderHover
			innerStroke.Color = Theme.Colors.ControlInnerGlowHover
			grad.Color = Theme.Gradients.ButtonHover
		else
			outerStroke.Color = isDefault and Theme.Colors.ControlBorderHover or Theme.Colors.ControlBorderNormal
			dividerDark.BackgroundColor3 = Theme.Colors.ControlBorderNormal
			innerStroke.Color = isDefault and Color3.fromRGB(96, 198, 252) or Color3.fromRGB(255, 255, 255)
			grad.Color = Theme.Gradients.ButtonNormal
		end
	end

	for _, hit in ipairs({ mainHit, arrowHit }) do
		hit.MouseEnter:Connect(function()
			hovered = true
			refreshVisual()
		end)
		hit.MouseLeave:Connect(function()
			hovered = false
			pressed = false
			refreshVisual()
		end)
		hit.MouseButton1Down:Connect(function()
			if not disabled then
				pressed = true
				refreshVisual()
			end
		end)
		hit.MouseButton1Up:Connect(function()
			if pressed then
				pressed = false
				refreshVisual()
			end
		end)
	end

	mainHit.MouseButton1Click:Connect(function()
		if not disabled then
			callback()
		end
	end)

	local activePopup = nil
	local function openDropdownMenu()
		if disabled then
			return
		end
		if activePopup and activePopup.Frame and activePopup.Frame.Parent then
			activePopup:Destroy()
			activePopup = nil
			return
		end
		local screenGui = outerBtn:FindFirstAncestorWhichIsA("ScreenGui") or parentContainer
		local absPos = outerBtn.AbsolutePosition
		local absSize = outerBtn.AbsoluteSize
		activePopup = MenuBar.ShowPopupMenu(
			screenGui,
			UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2),
			menuItems,
			function()
				activePopup = nil
			end
		)
	end

	arrowHit.MouseButton1Click:Connect(openDropdownMenu)

	if options.Tooltip then
		Tooltip.Attach(outerBtn, options.Tooltip)
	end

	return {
		Row = row,
		Button = outerBtn,
		MainButton = mainHit,
		ArrowButton = arrowHit,
		OpenMenu = openDropdownMenu,
		SetText = function(_, newText)
			textLabel.Text = tostring(newText or "")
		end,
		SetMenuItems = function(_, newItems)
			menuItems = newItems or {}
		end,
		SetDisabled = function(_, dis)
			disabled = (dis == true)
			refreshVisual()
		end,
		Fire = function()
			if not disabled then
				callback()
			end
		end,
	}
end

return Button
