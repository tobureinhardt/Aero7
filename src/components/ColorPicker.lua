--!nonstrict
-- Aero7: components/ColorPicker - Windows 7 ColorPicker inline control and Personalization glass color mixer.

local Theme = require("core/Theme")
local Utility = require("core/Utility")
local DWM = require("core/DWM")
local Slider = require("components/Slider")
local ColorDialog = require("window/ColorDialog")

local ColorPicker = {}

-- Mode 1: ColorPicker Inline Control (opens Windows 7 ChooseColor dialog)
function ColorPicker.newInline(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "Color"
	local currentColor = options.Default or options.Value or Color3.fromRGB(0, 120, 215)
	local callback = options.Callback or function() end

	local row = Utility.Create("Frame", {
		Name = "ColorPickerRow_" .. title,
		Parent = parentContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})

	local titleLabel = Utility.Create("TextLabel", {
		Name = "ColorPickerTitle",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -140, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = row.ZIndex + 1,
	})

	local hexLabel = Utility.Create("TextLabel", {
		Name = "ColorHexValue",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -140, 0, 0),
		Size = UDim2.new(0, 96, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = string.format("#%02X%02X%02X", math.floor(currentColor.R * 255 + 0.5), math.floor(currentColor.G * 255 + 0.5), math.floor(currentColor.B * 255 + 0.5)),
		TextColor3 = Theme.Colors.TextSecondary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = row.ZIndex + 1,
	})

	local swatchBtn = Utility.Create("TextButton", {
		Name = "ColorSwatchButton",
		Parent = row,
		BackgroundColor3 = currentColor,
		Position = UDim2.new(1, -38, 0, 2),
		Size = UDim2.new(0, 38, 0, 22),
		AutoButtonColor = false,
		Text = "",
		ZIndex = row.ZIndex + 2,
	})
	Utility.AddCorner(swatchBtn, 3)
	local outerStroke = Utility.AddStroke(swatchBtn, Theme.Colors.ControlBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

	local innerHighlight = Utility.Create("Frame", {
		Name = "InnerHighlight",
		Parent = swatchBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = swatchBtn.ZIndex + 1,
	})
	Utility.AddCorner(innerHighlight, 2)
	local innerStroke = Utility.AddStroke(innerHighlight, Color3.fromRGB(255, 255, 255), 1, 0.45, Enum.ApplyStrokeMode.Border)

	swatchBtn.MouseEnter:Connect(function()
		outerStroke.Color = Theme.Colors.ControlBorderHover
		innerStroke.Transparency = 0.2
	end)
	swatchBtn.MouseLeave:Connect(function()
		outerStroke.Color = Theme.Colors.ControlBorderNormal
		innerStroke.Transparency = 0.45
	end)

	local controller = {
		Row = row,
		Button = swatchBtn,
		Value = currentColor,
	}

	local function updateColor(newColor, silent)
		controller.Value = newColor
		swatchBtn.BackgroundColor3 = newColor
		local r = math.floor(newColor.R * 255 + 0.5)
		local g = math.floor(newColor.G * 255 + 0.5)
		local b = math.floor(newColor.B * 255 + 0.5)
		hexLabel.Text = string.format("#%02X%02X%02X", r, g, b)
		if not silent then
			callback(newColor)
		end
	end

	swatchBtn.MouseButton1Click:Connect(function()
		ColorDialog.Show(nil, {
			Title = options.DialogTitle or title or "Color",
			InitialColor = controller.Value,
			Callback = function(pickedColor)
				updateColor(pickedColor, false)
			end,
		})
	end)

	function controller:SetValue(newColor, silent)
		if typeof and typeof(newColor) == "Color3" then
			updateColor(newColor, silent)
		elseif type(newColor) == "table" and newColor.R ~= nil then
			updateColor(newColor, silent)
		end
	end

	function controller:GetValue()
		return controller.Value
	end

	return controller
end

-- Mode 2: Window Color and Appearance Mixer (16 glass swatches + DWM color mixer)
function ColorPicker.newGlassMixer(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "Window Color and Appearance"
	local currentColor = options.Default or options.Value or Theme.CurrentGlass.Color
	local currentTrans = tonumber(options.Transparency) or Theme.CurrentGlass.Transparency
	local syncWindowGlass = options.BindToWindowGlass == true
	local callback = options.Callback or function() end

	local h, s, v = Color3.toHSV(currentColor)

	local wrapper = Utility.Create("Frame", {
		Name = "ColorPicker_" .. title,
		Parent = parentContainer,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = wrapper

	-- Header row and current color preview swatch
	local topRow = Utility.Create("Frame", {
		Name = "ColorHeaderRow",
		Parent = wrapper,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 1,
		ZIndex = wrapper.ZIndex + 1,
	})

	Utility.Create("TextLabel", {
		Name = "ColorPickerTitle",
		Parent = topRow,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -135, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = topRow.ZIndex + 1,
	})

	local currentNameLabel = Utility.Create("TextLabel", {
		Name = "CurrentColorLabel",
		Parent = topRow,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -135, 0, 0),
		Size = UDim2.new(0, 102, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = "Current color: Sky",
		TextColor3 = Theme.Colors.TextSecondary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = topRow.ZIndex + 1,
	})

	local previewBox = Utility.Create("Frame", {
		Name = "CurrentColorSwatchPreview",
		Parent = topRow,
		BackgroundColor3 = currentColor,
		Position = UDim2.new(1, -26, 0, 1),
		Size = UDim2.new(0, 26, 0, 20),
		ZIndex = topRow.ZIndex + 2,
	})
	Utility.ApplyDualBevel(previewBox, Color3.fromRGB(64, 64, 64), 0.1, Color3.fromRGB(255, 255, 255), 0.15, 2)

	-- 16 Personalization glass color swatches (8 columns x 2 rows)
	local paletteGrid = Utility.Create("Frame", {
		Name = "Win7SwatchesGrid",
		Parent = wrapper,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 56),
		LayoutOrder = 2,
		ZIndex = wrapper.ZIndex + 1,
	})
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 28, 0, 26)
	gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = paletteGrid

	local swatchFrames = {}
	local controller = {
		Wrapper = wrapper,
		Value = currentColor,
		Transparency = currentTrans,
	}

	local hSlider, sSlider, vSlider, opSlider
	local updatingSliders = false

	local function applyColorUpdate(newColor, newTrans, presetName, silent)
		controller.Value = newColor
		if newTrans ~= nil then
			controller.Transparency = math.clamp(newTrans, 0.05, 0.85)
		end
		previewBox.BackgroundColor3 = newColor
		if presetName then
			currentNameLabel.Text = "Current color: " .. presetName
		else
			local r = math.floor(newColor.R * 255 + 0.5)
			local g = math.floor(newColor.G * 255 + 0.5)
			local b = math.floor(newColor.B * 255 + 0.5)
			currentNameLabel.Text = string.format("#%02X%02X%02X", r, g, b)
		end

		if syncWindowGlass then
			DWM:SetGlassColor(newColor, controller.Transparency)
		end
		if not silent then
			callback(newColor, controller.Transparency)
		end
	end

	for idx, preset in ipairs(Theme.GlassPresets) do
		local tileBtn = Utility.Create("TextButton", {
			Name = "Swatch_" .. preset.Name,
			Parent = paletteGrid,
			BackgroundColor3 = Color3.fromRGB(245, 248, 252),
			BackgroundTransparency = 1,
			LayoutOrder = idx,
			Text = "",
			ZIndex = paletteGrid.ZIndex + 1,
		})
		Utility.AddCorner(tileBtn, 3)
		local selStroke = Utility.AddStroke(tileBtn, Theme.Colors.ControlBorderHover, 1.5, ( idx == 1 ) and 0 or 1, Enum.ApplyStrokeMode.Border)

		local colorSquare = Utility.Create("Frame", {
			Name = "GlassColorTile",
			Parent = tileBtn,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = preset.Color,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 22, 0, 20),
			ZIndex = tileBtn.ZIndex + 1,
		})
		Utility.ApplyDualBevel(colorSquare, Color3.fromRGB(50, 50, 50), 0.15, Color3.fromRGB(255, 255, 255), 0.15, 2)

		-- Specular diagonal sheen on each glass swatch
		local tileGloss = Utility.Create("Frame", {
			Name = "TileGloss",
			Parent = colorSquare,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.58,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 0.45, 0),
			ZIndex = colorSquare.ZIndex + 2,
		})

		tileBtn.MouseEnter:Connect(function()
			tileBtn.BackgroundTransparency = 0.25
			selStroke.Transparency = 0.15
		end)
		tileBtn.MouseLeave:Connect(function()
			if controller.Value ~= preset.Color then
				tileBtn.BackgroundTransparency = 1
				selStroke.Transparency = 1
			end
		end)

		tileBtn.MouseButton1Click:Connect(function()
			for _, sf in ipairs(swatchFrames) do
				sf.Button.BackgroundTransparency = 1
				sf.Stroke.Transparency = 1
			end
			tileBtn.BackgroundTransparency = 0.15
			selStroke.Transparency = 0

			h, s, v = Color3.toHSV(preset.Color)
			updatingSliders = true
			if hSlider then hSlider:SetValue(math.floor(h * 360 + 0.5), true) end
			if sSlider then sSlider:SetValue(math.floor(s * 100 + 0.5), true) end
			if vSlider then vSlider:SetValue(math.floor(v * 100 + 0.5), true) end
			if opSlider then opSlider:SetValue(math.floor((1 - preset.Transparency) * 100 + 0.5), true) end
			updatingSliders = false

			applyColorUpdate(preset.Color, preset.Transparency, preset.Name, false)
		end)

		table.insert(swatchFrames, { Button = tileBtn, Stroke = selStroke, Preset = preset })
	end

	-- "Show color mixer" expander button
	local mixerToggleBtn = Utility.Create("TextButton", {
		Name = "ToggleColorMixerLink",
		Parent = wrapper,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 150, 0, 18),
		LayoutOrder = 3,
		Font = Theme.Fonts.Regular,
		Text = (options.ShowMixer == true) and "   Hide color mixer" or "   Show color mixer",
		TextColor3 = Theme.Colors.TextLink,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = wrapper.ZIndex + 1,
	})
	local mixerChevronWrap = Utility.Create("Frame", {
		Name = "MixerChevron",
		Parent = mixerToggleBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0.5, -5),
		Size = UDim2.new(0, 10, 0, 10),
		ZIndex = wrapper.ZIndex + 2,
	})
	local mixerChevron = Utility.CreateVectorChevron(
		mixerChevronWrap,
		(options.ShowMixer == true) and "Down" or "Right",
		Theme.Colors.TextLink,
		wrapper.ZIndex + 3
	)

	local mixerPanel = Utility.Create("Frame", {
		Name = "Win7ColorMixerPanel",
		Parent = wrapper,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = options.ShowMixer == true,
		LayoutOrder = 4,
		ZIndex = wrapper.ZIndex + 1,
	})
	local mixerLayout = Instance.new("UIListLayout")
	mixerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mixerLayout.Padding = UDim.new(0, 4)
	mixerLayout.Parent = mixerPanel

	local function onSubSliderChanged()
		if updatingSliders then
			return
		end
		local newH = (hSlider and hSlider.Value or 210) / 360
		local newS = (sSlider and sSlider.Value or 75) / 100
		local newV = (vSlider and vSlider.Value or 85) / 100
		local newOp = (opSlider and opSlider.Value or 74) / 100
		local col = Color3.fromHSV(newH, newS, newV)
		applyColorUpdate(col, 1 - newOp, nil, false)
	end

	hSlider = Slider.new(mixerPanel, {
		Title = "Hue:",
		Min = 0,
		Max = 360,
		Default = math.floor(h * 360 + 0.5),
		Suffix = "°",
		Callback = onSubSliderChanged,
	})
	sSlider = Slider.new(mixerPanel, {
		Title = "Saturation:",
		Min = 0,
		Max = 100,
		Default = math.floor(s * 100 + 0.5),
		Suffix = "%",
		Callback = onSubSliderChanged,
	})
	vSlider = Slider.new(mixerPanel, {
		Title = "Brightness:",
		Min = 0,
		Max = 100,
		Default = math.floor(v * 100 + 0.5),
		Suffix = "%",
		Callback = onSubSliderChanged,
	})
	opSlider = Slider.new(mixerPanel, {
		Title = "Color intensity:",
		Min = 15,
		Max = 95,
		Default = math.floor((1 - currentTrans) * 100 + 0.5),
		Suffix = "%",
		Callback = onSubSliderChanged,
	})

	mixerToggleBtn.MouseEnter:Connect(function()
		mixerToggleBtn.TextColor3 = Theme.Colors.TextLinkHover
		mixerChevron:SetColor(Theme.Colors.TextLinkHover)
	end)
	mixerToggleBtn.MouseLeave:Connect(function()
		mixerToggleBtn.TextColor3 = Theme.Colors.TextLink
		mixerChevron:SetColor(Theme.Colors.TextLink)
	end)
	mixerToggleBtn.MouseButton1Click:Connect(function()
		mixerPanel.Visible = not mixerPanel.Visible
		mixerToggleBtn.Text = mixerPanel.Visible and "   Hide color mixer" or "   Show color mixer"
		mixerChevron:SetDirection(mixerPanel.Visible and "Down" or "Right")
	end)

	function controller:SetValue(newColor, newTrans, silent)
		h, s, v = Color3.toHSV(newColor)
		updatingSliders = true
		hSlider:SetValue(math.floor(h * 360 + 0.5), true)
		sSlider:SetValue(math.floor(s * 100 + 0.5), true)
		vSlider:SetValue(math.floor(v * 100 + 0.5), true)
		if newTrans ~= nil then
			opSlider:SetValue(math.floor((1 - newTrans) * 100 + 0.5), true)
		end
		updatingSliders = false
		applyColorUpdate(newColor, newTrans, nil, silent)
	end

	function controller:GetValue()
		return controller.Value
	end

	return controller
end

-- Main entry: selects Inline or GlassMixer based on options
function ColorPicker.new(parentContainer, options)
	options = options or {}
	if options.BindToWindowGlass == true or options.Mixer == true or options.GlassMixer == true then
		return ColorPicker.newGlassMixer(parentContainer, options)
	else
		return ColorPicker.newInline(parentContainer, options)
	end
end

return ColorPicker
