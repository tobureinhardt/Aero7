--!nonstrict
-- Aero7: components/Slider - Windows 7 Trackbar / Slider supporting horizontal and vertical orientations (msctls_trackbar32).

local UserInputService = game:GetService("UserInputService")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")

local Slider = {}

function Slider.new(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "Slider"
	local minVal = tonumber(options.Min) or 0
	local maxVal = tonumber(options.Max) or 100
	if maxVal <= minVal then
		maxVal = minVal + 100
	end
	local step = tonumber(options.Step or options.Rounding) or 1
	local suffix = options.Suffix or ""
	local defaultVal = tonumber(options.Default or options.Value) or minVal
	defaultVal = math.clamp(defaultVal, minVal, maxVal)
	local isVertical = options.Vertical == true or options.Orientation == "Vertical"
	local callback = options.Callback or function() end

	local wrapper
	local trackArea
	local groove
	local thumb
	local valueBox
	local valStroke

	if isVertical then
		local height = tonumber(options.Height) or 140
		local width = tonumber(options.Width) or 64

		wrapper = Utility.Create("Frame", {
			Name = "Slider_Vert_" .. title,
			Parent = parentContainer,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, width, 0, height),
			LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
			ZIndex = parentContainer.ZIndex + 1,
		})

		Utility.Create("TextLabel", {
			Name = "SliderTitle",
			Parent = wrapper,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, 16),
			Font = Theme.Fonts.Regular,
			Text = title,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = wrapper.ZIndex + 1,
		})

		valueBox = Utility.Create("TextBox", {
			Name = "SliderValueEditBox",
			Parent = wrapper,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0.5, -24, 1, -20),
			Size = UDim2.new(0, 48, 0, 19),
			ClearTextOnFocus = false,
			Font = Theme.Fonts.Regular,
			Text = tostring(defaultVal) .. suffix,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 12,
			ZIndex = wrapper.ZIndex + 2,
		})
		Utility.AddCorner(valueBox, 1)
		valStroke = Utility.AddStroke(valueBox, Theme.Colors.EditBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)
		valueBox.Focused:Connect(function()
			valStroke.Color = Theme.Colors.EditBorderFocused
		end)

		trackArea = Utility.Create("TextButton", {
			Name = "TrackbarInteractiveZone",
			Parent = wrapper,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, -12, 0, 18),
			Size = UDim2.new(0, 24, 1, -42),
			Text = "",
			ZIndex = wrapper.ZIndex + 2,
		})

		groove = Utility.Create("Frame", {
			Name = "RecessedGroove",
			Parent = trackArea,
			BackgroundColor3 = Theme.Colors.TrackFill,
			Position = UDim2.new(0.5, -2, 0, 6),
			Size = UDim2.new(0, 4, 1, -12),
			ZIndex = trackArea.ZIndex + 1,
		})
		Utility.AddCorner(groove, 1)
		Utility.AddStroke(groove, Theme.Colors.TrackBorderTop, 1, 0, Enum.ApplyStrokeMode.Border)

		-- Tick marks alongside vertical slider track
		local tickCount = 6
		for i = 0, tickCount do
			local ratio = i / tickCount
			Utility.Create("Frame", {
				Name = "Tick_" .. tostring(i),
				Parent = trackArea,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Theme.Colors.TrackTick,
				Position = UDim2.new(0.5, 6, ratio, 0),
				Size = UDim2.new(0, (i == 0 or i == tickCount) and 4 or 3, 0, 1),
				ZIndex = trackArea.ZIndex + 1,
			})
		end

		thumb = Utility.Create("Frame", {
			Name = "TrackbarThumbHandle",
			Parent = trackArea,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 19, 0, 11),
			ZIndex = trackArea.ZIndex + 3,
		})
		Utility.AddCorner(thumb, 2)
	else
		-- Horizontal Slider
		wrapper = Utility.Create("Frame", {
			Name = "Slider_" .. title,
			Parent = parentContainer,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 42),
			LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
			ZIndex = parentContainer.ZIndex + 1,
		})

		Utility.Create("TextLabel", {
			Name = "SliderTitle",
			Parent = wrapper,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, -60, 0, 18),
			Font = Theme.Fonts.Regular,
			Text = title,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = wrapper.ZIndex + 1,
		})

		valueBox = Utility.Create("TextBox", {
			Name = "SliderValueEditBox",
			Parent = wrapper,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(1, -54, 0, 0),
			Size = UDim2.new(0, 54, 0, 19),
			ClearTextOnFocus = false,
			Font = Theme.Fonts.Regular,
			Text = tostring(defaultVal) .. suffix,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 12,
			ZIndex = wrapper.ZIndex + 2,
		})
		Utility.AddCorner(valueBox, 1)
		valStroke = Utility.AddStroke(valueBox, Theme.Colors.EditBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)
		valueBox.Focused:Connect(function()
			valStroke.Color = Theme.Colors.EditBorderFocused
		end)

		trackArea = Utility.Create("TextButton", {
			Name = "TrackbarInteractiveZone",
			Parent = wrapper,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 4, 0, 19),
			Size = UDim2.new(1, -8, 0, 22),
			Text = "",
			ZIndex = wrapper.ZIndex + 2,
		})

		groove = Utility.Create("Frame", {
			Name = "RecessedGroove",
			Parent = trackArea,
			BackgroundColor3 = Theme.Colors.TrackFill,
			Position = UDim2.new(0, 0, 0, 7),
			Size = UDim2.new(1, 0, 0, 4),
			ZIndex = trackArea.ZIndex + 1,
		})
		Utility.AddCorner(groove, 1)
		Utility.AddStroke(groove, Theme.Colors.TrackBorderTop, 1, 0, Enum.ApplyStrokeMode.Border)

		Utility.Create("Frame", {
			Name = "GrooveBottomHighlight",
			Parent = groove,
			BackgroundColor3 = Theme.Colors.TrackBorderBot,
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = groove.ZIndex + 1,
		})

		local ticksRow = Utility.Create("Frame", {
			Name = "TrackbarTicks",
			Parent = trackArea,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 16),
			Size = UDim2.new(1, 0, 0, 4),
			ZIndex = trackArea.ZIndex + 1,
		})
		local tickCount = 10
		for i = 0, tickCount do
			local ratio = i / tickCount
			Utility.Create("Frame", {
				Name = "Tick_" .. tostring(i),
				Parent = ticksRow,
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Theme.Colors.TrackTick,
				Position = UDim2.new(ratio, 0, 0, 0),
				Size = UDim2.new(0, 1, 0, (i == 0 or i == 5 or i == 10) and 4 or 3),
				ZIndex = ticksRow.ZIndex + 1,
			})
		end

		thumb = Utility.Create("Frame", {
			Name = "TrackbarThumbHandle",
			Parent = trackArea,
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0, 11, 0, 19),
			ZIndex = trackArea.ZIndex + 3,
		})
		Utility.AddCorner(thumb, 2)
	end

	local thumbStroke = Utility.AddStroke(thumb, Theme.Colors.ControlBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)
	local thumbInner = Utility.Create("Frame", {
		Name = "ThumbInnerHighlight",
		Parent = thumb,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = thumb.ZIndex + 1,
	})
	Utility.AddStroke(thumbInner, Color3.fromRGB(255, 255, 255), 1, 0.25, Enum.ApplyStrokeMode.Border)

	local thumbGrad = Instance.new("UIGradient")
	thumbGrad.Rotation = isVertical and 0 or 90
	thumbGrad.Color = Theme.Gradients.ButtonNormal
	thumbGrad.Parent = thumb

	local dragging = false
	local hovered = false

	local function refreshThumbVisual()
		if dragging then
			thumbStroke.Color = Theme.Colors.ControlBorderPressed
			thumbGrad.Color = Theme.Gradients.ButtonPressed
		elseif hovered then
			thumbStroke.Color = Theme.Colors.ControlBorderHover
			thumbGrad.Color = Theme.Gradients.ButtonHover
		else
			thumbStroke.Color = Theme.Colors.ControlBorderNormal
			thumbGrad.Color = Theme.Gradients.ButtonNormal
		end
	end

	local function roundToStep(val)
		local snapped = minVal + math.floor(((val - minVal) / step) + 0.5) * step
		local decimals = 0
		local stepStr = tostring(step)
		local dotIdx = stepStr:find("%.")
		if dotIdx then
			decimals = #stepStr - dotIdx
		end
		local mult = 10 ^ decimals
		snapped = math.floor(snapped * mult + 0.5) / mult
		return math.clamp(snapped, minVal, maxVal)
	end

	local controller = {
		Wrapper = wrapper,
		Value = defaultVal,
		IsVertical = isVertical,
	}

	function controller:SetValue(newVal, silent)
		local clamped = roundToStep(tonumber(newVal) or minVal)
		self.Value = clamped
		local alpha = math.clamp((clamped - minVal) / (maxVal - minVal), 0, 1)

		if isVertical then
			-- In Windows vertical slider: top is Max (alpha=1), bottom is Min (alpha=0)
			local yPos = 1 - alpha
			thumb.Position = UDim2.new(0.5, 0, yPos, 0)
		else
			thumb.Position = UDim2.new(alpha, 0, 0, 0)
		end

		valueBox.Text = tostring(clamped) .. suffix
		if not silent then
			callback(clamped)
		end
	end

	local function updateFromInput(screenX, screenY)
		if isVertical then
			local absPos = trackArea.AbsolutePosition.Y
			local absH = math.max(trackArea.AbsoluteSize.Y, 1)
			local alphaY = math.clamp((screenY - absPos) / absH, 0, 1)
			local alphaVal = 1 - alphaY
			local rawVal = minVal + (maxVal - minVal) * alphaVal
			controller:SetValue(rawVal)
		else
			local absPos = trackArea.AbsolutePosition.X
			local absW = math.max(trackArea.AbsoluteSize.X, 1)
			local alpha = math.clamp((screenX - absPos) / absW, 0, 1)
			local rawVal = minVal + (maxVal - minVal) * alpha
			controller:SetValue(rawVal)
		end
	end

	trackArea.MouseEnter:Connect(function()
		hovered = true
		refreshThumbVisual()
	end)
	trackArea.MouseLeave:Connect(function()
		hovered = false
		refreshThumbVisual()
	end)

	trackArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			refreshThumbVisual()
			updateFromInput(input.Position.X, input.Position.Y)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position.X, input.Position.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			refreshThumbVisual()
		end
	end)

	valueBox.FocusLost:Connect(function()
		valStroke.Color = Theme.Colors.EditBorderNormal
		local numStr = valueBox.Text:gsub("[^%d%.%-]", "")
		local parsed = tonumber(numStr)
		if parsed then
			controller:SetValue(parsed)
		else
			valueBox.Text = tostring(controller.Value) .. suffix
		end
	end)

	controller:SetValue(defaultVal, true)

	if options.Tooltip then
		Tooltip.Attach(wrapper, options.Tooltip)
	end

	return controller
end

return Slider
