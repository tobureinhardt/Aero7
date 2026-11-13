--!nonstrict
-- Aero7: window/ColorDialog - Windows 7 ChooseColor modal dialog (comdlg32.dll 0x12b0) with basic/custom colors, spectrum box, and HLS/RGB controls.

local UserInputService = game:GetService("UserInputService")

local Theme = require("core/Theme")
local Utility = require("core/Utility")
local DWM = require("core/DWM")

local ColorDialog = {}

-- 48 standard Windows 7 basic colors from comdlg32.dll (offset 0x66ae0)
ColorDialog.BasicColors = {
	Color3.fromRGB(255, 128, 128), Color3.fromRGB(255, 255, 128), Color3.fromRGB(128, 255, 128), Color3.fromRGB(0, 255, 128), Color3.fromRGB(128, 255, 255), Color3.fromRGB(0, 128, 255), Color3.fromRGB(255, 128, 192), Color3.fromRGB(255, 128, 255),
	Color3.fromRGB(255, 0, 0),     Color3.fromRGB(255, 255, 0),   Color3.fromRGB(128, 255, 0),   Color3.fromRGB(0, 255, 64),  Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 128, 192), Color3.fromRGB(128, 128, 192), Color3.fromRGB(255, 0, 255),
	Color3.fromRGB(128, 64, 64),   Color3.fromRGB(255, 128, 64),  Color3.fromRGB(0, 255, 0),     Color3.fromRGB(0, 128, 128), Color3.fromRGB(0, 64, 128), Color3.fromRGB(128, 128, 255), Color3.fromRGB(128, 0, 64),   Color3.fromRGB(255, 0, 128),
	Color3.fromRGB(128, 0, 0),     Color3.fromRGB(255, 128, 0),   Color3.fromRGB(0, 128, 0),     Color3.fromRGB(0, 128, 64),  Color3.fromRGB(0, 0, 255),   Color3.fromRGB(0, 0, 160),   Color3.fromRGB(128, 0, 128), Color3.fromRGB(128, 0, 255),
	Color3.fromRGB(64, 0, 0),      Color3.fromRGB(128, 64, 0),    Color3.fromRGB(0, 64, 0),      Color3.fromRGB(0, 64, 64),   Color3.fromRGB(0, 0, 128),   Color3.fromRGB(0, 0, 64),    Color3.fromRGB(64, 0, 64),   Color3.fromRGB(64, 0, 128),
	Color3.fromRGB(0, 0, 0),       Color3.fromRGB(128, 128, 0),   Color3.fromRGB(128, 128, 64),  Color3.fromRGB(128, 128, 128), Color3.fromRGB(64, 128, 128), Color3.fromRGB(192, 192, 192), Color3.fromRGB(64, 0, 64), Color3.fromRGB(255, 255, 255),
}

-- RGB (0-255) to HLS (0-239, 0-240, 0-240) conversion algorithm (ColorRGBToHLS)
function ColorDialog.RgbToHls(r, g, b)
	r = math.clamp(math.floor(tonumber(r) or 0), 0, 255)
	g = math.clamp(math.floor(tonumber(g) or 0), 0, 255)
	b = math.clamp(math.floor(tonumber(b) or 0), 0, 255)

	local cMax = math.max(r, g, b)
	local cMin = math.min(r, g, b)
	local lum = math.floor(((cMax + cMin) * 240 + 255) / 510)
	local sat = 0
	local hue = 160 -- Windows default hue when Sat = 0

	if cMax ~= cMin then
		local delta = cMax - cMin
		if lum <= 120 then
			sat = math.floor((delta * 240 + math.floor((cMax + cMin) / 2)) / (cMax + cMin))
		else
			sat = math.floor((delta * 240 + math.floor((510 - cMax - cMin) / 2)) / (510 - cMax - cMin))
		end
		local h = 0
		if r == cMax then
			h = ((g - b) * 40) / delta
		elseif g == cMax then
			h = 80 + ((b - r) * 40) / delta
		else
			h = 160 + ((r - g) * 40) / delta
		end
		if h < 0 then
			h = h + 240
		elseif h >= 240 then
			h = h - 240
		end
		hue = math.floor(h + 0.5)
	end

	return math.clamp(hue, 0, 239), math.clamp(sat, 0, 240), math.clamp(lum, 0, 240)
end

-- HLS (0-239, 0-240, 0-240) to RGB (0-255) conversion algorithm (ColorHLSToRGB)
function ColorDialog.HlsToRgb(hue, lum, sat)
	hue = math.clamp(math.floor(tonumber(hue) or 0), 0, 239)
	lum = math.clamp(math.floor(tonumber(lum) or 0), 0, 240)
	sat = math.clamp(math.floor(tonumber(sat) or 0), 0, 240)

	if sat == 0 then
		local v = math.floor((lum * 255 + 120) / 240)
		return v, v, v
	end

	local m2
	if lum <= 120 then
		m2 = math.floor((lum * (240 + sat) + 120) / 240)
	else
		m2 = lum + sat - math.floor((lum * sat + 120) / 240)
	end
	local m1 = 2 * lum - m2

	local function hueVal(n1, n2, h)
		if h < 0 then h = h + 240 end
		if h > 240 then h = h - 240 end
		if h < 40 then
			return n1 + math.floor(((n2 - n1) * h + 20) / 40)
		elseif h < 120 then
			return n2
		elseif h < 160 then
			return n1 + math.floor(((n2 - n1) * (160 - h) + 20) / 40)
		else
			return n1
		end
	end

	local r = math.floor((hueVal(m1, m2, hue + 80) * 255 + 120) / 240)
	local g = math.floor((hueVal(m1, m2, hue) * 255 + 120) / 240)
	local b = math.floor((hueVal(m1, m2, hue - 80) * 255 + 120) / 240)

	return math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255)
end

-- Displays Windows 7 ChooseColor dialog
function ColorDialog.Show(parentWindow, options)
	options = options or {}
	local title = options.Title or "Color"
	local initialColor = options.InitialColor or options.Default or Color3.fromRGB(0, 0, 0)
	local callback = options.Callback or function() end
	local onCancel = options.OnCancel or function() end
	local fullOpen = (options.FullOpen == true)

	-- Modal overlay must reside in a ScreenGui to render properly
	local ownedGui = nil
	local screenGui = parentWindow and parentWindow.ScreenGui
	if not screenGui then
		ownedGui = Utility.Create("ScreenGui", {
			Name = "Win7ColorDialogGui",
			Parent = Utility.GetSafeGuiParent(),
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 300,
		})
		screenGui = ownedGui
	end

	-- Retrieves or initializes 16 persistent custom color slots in DWM
	if not DWM.CustomColors or #DWM.CustomColors < 16 then
		DWM.CustomColors = {}
		for i = 1, 16 do
			DWM.CustomColors[i] = Color3.fromRGB(255, 255, 255)
		end
	end

	-- Invisible modal layer: still blocks clicks behind the dialog, but does not dim the screen
	local overlay = Utility.Create("TextButton", {
		Name = "Win7ColorModalOverlay",
		Parent = screenGui,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		ZIndex = 80,
	})

	local collapsedWidth = 240
	local expandedWidth = 484
	local dialogHeight = 340
	local isExpanded = fullOpen

	-- Primary window frame
	local dialogFrame = Utility.Create("Frame", {
		Name = "Win7ChooseColorDialog",
		Parent = overlay,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(25, 42, 65),
		BackgroundTransparency = 0.82,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, isExpanded and expandedWidth or collapsedWidth, 0, dialogHeight),
		Active = true,
		ZIndex = 81,
	})

	local scale = Instance.new("UIScale")
	scale.Scale = 0.92
	scale.Parent = dialogFrame

	Utility.ApplyDualBevel(
		dialogFrame,
		Theme.Colors.WindowOuterBorder,
		0.32,
		Theme.Colors.WindowInnerHighlight,
		0.15,
		8
	)
	local dialogGlass = DWM.BuildAeroGlassLayers(dialogFrame)

	-- TitleBar (supports dragging on touch and desktop)
	local titleBar = Utility.Create("Frame", {
		Name = "ColorDialogTitleBar",
		Parent = dialogFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 28),
		Active = true,
		ZIndex = 94,
	})
	local titleCtrl = Utility.CreateGlowingTitle(titleBar, title, 95)
	titleCtrl.Container.Position = UDim2.new(0, 10, 0, 0)

	-- Windows 7 Close button with red glow halo (box-shadow: 0 0 7px 3px #e68e75)
	local closeRedHalo = Utility.Create("Frame", {
		Name = "CloseRedGlowHalo",
		Parent = titleBar,
		BackgroundColor3 = Color3.fromRGB(230, 142, 117),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -52, 0, 0),
		Size = UDim2.new(0, 44, 0, 19),
		ZIndex = 95,
	})
	local closeGlowCtrl = Utility.AttachGaussianGlow(closeRedHalo, Color3.fromRGB(230, 142, 117), 3, 9)

	local closeBtn = Utility.Create("TextButton", {
		Name = "DialogCloseButton",
		Parent = titleBar,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.14,
		Position = UDim2.new(1, -52, 0, 0),
		Size = UDim2.new(0, 44, 0, 19),
		AutoButtonColor = false,
		Text = "",
		ZIndex = 96,
	})
	Utility.AddCorner(closeBtn, 3)
	Utility.AddStroke(closeBtn, Color3.fromRGB(48, 14, 12), 1, 0.25, Enum.ApplyStrokeMode.Border)
	local closeGrad = Instance.new("UIGradient")
	closeGrad.Rotation = 90
	closeGrad.Color = Theme.Gradients.CloseButtonNormal
	closeGrad.Parent = closeBtn

	local innerRim = Utility.Create("Frame", {
		Name = "InnerHighlight",
		Parent = closeBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 97,
	})
	Utility.AddCorner(innerRim, 2)
	local innerStroke = Utility.AddStroke(innerRim, Color3.fromRGB(255, 255, 255), 1, 0.45, Enum.ApplyStrokeMode.Border)
	Utility.CreateVectorCloseX(closeBtn, Color3.fromRGB(255, 255, 255), Color3.fromRGB(52, 12, 12), 98)

	local closed = false
	local function closeDialog(triggerCancel)
		if closed then
			return
		end
		closed = true
		DWM.AnimateClose(dialogFrame, scale, function()
			if overlay and overlay.Parent then
				overlay:Destroy()
			end
			if ownedGui and ownedGui.Parent then
				ownedGui:Destroy()
			end
			if triggerCancel then
				onCancel()
			end
		end, dialogGlass)
	end

	closeBtn.MouseEnter:Connect(function()
		closeGrad.Color = Theme.Gradients.CloseButtonHover
		closeBtn.BackgroundTransparency = 0.02
		innerStroke.Color = Color3.fromRGB(255, 215, 200)
		innerStroke.Transparency = 0.15
		closeGlowCtrl:Fade(1, 0.12)
	end)
	closeBtn.MouseLeave:Connect(function()
		closeGrad.Color = Theme.Gradients.CloseButtonNormal
		closeBtn.BackgroundTransparency = 0.14
		innerStroke.Color = Color3.fromRGB(255, 255, 255)
		innerStroke.Transparency = 0.45
		closeGlowCtrl:Fade(0, 0.20)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		closeDialog(true)
	end)

	-- Drag handling on TitleBar
	local dragging = false
	local dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = dialogFrame.Position
			local endConn
			endConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					endConn:Disconnect()
				end
			end)
		end
	end)
	titleBar.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			dialogFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	-- Client area with COLOR_3DFACE background (#F0F0F0)
	local clientBox = Utility.Create("Frame", {
		Name = "DialogClientBox",
		Parent = dialogFrame,
		BackgroundColor3 = Theme.Colors.DialogFaceBg,
		Position = UDim2.new(0, 8, 0, 28),
		Size = UDim2.new(1, -16, 1, -36),
		ClipsDescendants = true,
		ZIndex = 93,
	})
	Utility.AddStroke(clientBox, Theme.Colors.ClientOuterBorder, 1, 0.15, Enum.ApplyStrokeMode.Border)

	-- Current active color state
	local curR = math.floor(initialColor.R * 255 + 0.5)
	local curG = math.floor(initialColor.G * 255 + 0.5)
	local curB = math.floor(initialColor.B * 255 + 0.5)
	local curHue, curSat, curLum = ColorDialog.RgbToHls(curR, curG, curB)
	local currentColor = initialColor
	local selectedCustomSlot = 1

	-- UI control synchronization handles
	local basicSwatchFrames = {}
	local customSwatchFrames = {}
	local previewColorBox, reticle, lumArrow, lumGradient
	local inpHue, inpSat, inpLum, inpRed, inpGreen, inpBlue
	local isUpdatingUI = false

	local function updateVisuals(source)
		if isUpdatingUI then return end
		isUpdatingUI = true

		currentColor = Color3.fromRGB(curR, curG, curB)

		-- Updates "Color | Solid" preview swatch
		if previewColorBox then
			previewColorBox.BackgroundColor3 = currentColor
		end

		-- Updates Hue/Saturation matrix crosshair position
		if reticle then
			local nx = math.clamp(curHue / 239, 0, 1)
			local ny = math.clamp(1 - (curSat / 240), 0, 1)
			reticle.Position = UDim2.new(nx, 0, ny, 0)
		end

		-- Updates Luminosity slider pointer and gradient
		if lumArrow then
			local ny = math.clamp(1 - (curLum / 240), 0, 1)
			lumArrow.Position = UDim2.new(1, 4, ny, -5)
		end
		if lumGradient then
			local pureR, pureG, pureB = ColorDialog.HlsToRgb(curHue, 120, curSat)
			lumGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(pureR, pureG, pureB)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0)),
			})
		end

		-- Updates numeric input boxes (excluding currently focused box)
		if inpHue and source ~= "Hue" then inpHue.Text = tostring(curHue) end
		if inpSat and source ~= "Sat" then inpSat.Text = tostring(curSat) end
		if inpLum and source ~= "Lum" then inpLum.Text = tostring(curLum) end
		if inpRed and source ~= "Red" then inpRed.Text = tostring(curR) end
		if inpGreen and source ~= "Green" then inpGreen.Text = tostring(curG) end
		if inpBlue and source ~= "Blue" then inpBlue.Text = tostring(curB) end

		-- Highlights basic color swatch if exact match
		for _, sf in ipairs(basicSwatchFrames) do
			local c = sf.Color
			local match = (math.abs(c.R * 255 - curR) < 1 and math.abs(c.G * 255 - curG) < 1 and math.abs(c.B * 255 - curB) < 1)
			sf.FocusRing.Visible = match
		end

		-- Highlights selected custom color swatch
		for idx, sf in ipairs(customSwatchFrames) do
			sf.FocusRing.Visible = (idx == selectedCustomSlot)
		end

		isUpdatingUI = false
	end

	-- Left panel: basic colors, custom colors, define button, OK, Cancel

	-- "Basic colors:" label
	Utility.Create("TextLabel", {
		Name = "BasicColorsLabel",
		Parent = clientBox,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 6),
		Size = UDim2.new(0, 212, 0, 16),
		Font = Theme.Fonts.Regular,
		Text = "Basic colors:",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 94,
	})

	-- 48 basic color grid (8 cols x 6 rows)
	local basicGrid = Utility.Create("Frame", {
		Name = "BasicColorsGrid",
		Parent = clientBox,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 24),
		Size = UDim2.new(0, 212, 0, 114),
		ZIndex = 94,
	})

	for i, col in ipairs(ColorDialog.BasicColors) do
		local colIdx = (i - 1) % 8
		local rowIdx = math.floor((i - 1) / 8)

		local swatchTile = Utility.Create("TextButton", {
			Name = "BasicSwatch_" .. i,
			Parent = basicGrid,
			BackgroundColor3 = col,
			Position = UDim2.new(0, colIdx * 26 + 1, 0, rowIdx * 19 + 1),
			Size = UDim2.new(0, 23, 0, 16),
			AutoButtonColor = false,
			Text = "",
			ZIndex = 95,
		})
		-- Win32 sunken well 3D border
		Utility.AddStroke(swatchTile, Color3.fromRGB(112, 112, 112), 1, 0, Enum.ApplyStrokeMode.Border)

		local focusRing = Utility.Create("Frame", {
			Name = "FocusIndicator",
			Parent = swatchTile,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2),
			Visible = false,
			ZIndex = 96,
		})
		Utility.AddStroke(focusRing, Color3.fromRGB(255, 255, 255), 1, 0, Enum.ApplyStrokeMode.Border)

		table.insert(basicSwatchFrames, {
			Button = swatchTile,
			FocusRing = focusRing,
			Color = col,
		})

		swatchTile.MouseButton1Click:Connect(function()
			curR = math.floor(col.R * 255 + 0.5)
			curG = math.floor(col.G * 255 + 0.5)
			curB = math.floor(col.B * 255 + 0.5)
			curHue, curSat, curLum = ColorDialog.RgbToHls(curR, curG, curB)
			updateVisuals("BasicSwatch")
		end)
	end

	-- "Custom colors:" label
	Utility.Create("TextLabel", {
		Name = "CustomColorsLabel",
		Parent = clientBox,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 142),
		Size = UDim2.new(0, 212, 0, 16),
		Font = Theme.Fonts.Regular,
		Text = "Custom colors:",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 94,
	})

	-- 16 custom color grid (8 cols x 2 rows)
	local customGrid = Utility.Create("Frame", {
		Name = "CustomColorsGrid",
		Parent = clientBox,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 160),
		Size = UDim2.new(0, 212, 0, 38),
		ZIndex = 94,
	})

	for i = 1, 16 do
		local colIdx = (i - 1) % 8
		local rowIdx = math.floor((i - 1) / 8)
		local savedColor = DWM.CustomColors[i] or Color3.fromRGB(255, 255, 255)

		local swatchTile = Utility.Create("TextButton", {
			Name = "CustomSwatch_" .. i,
			Parent = customGrid,
			BackgroundColor3 = savedColor,
			Position = UDim2.new(0, colIdx * 26 + 1, 0, rowIdx * 19 + 1),
			Size = UDim2.new(0, 23, 0, 16),
			AutoButtonColor = false,
			Text = "",
			ZIndex = 95,
		})
		Utility.AddStroke(swatchTile, Color3.fromRGB(112, 112, 112), 1, 0, Enum.ApplyStrokeMode.Border)

		local focusRing = Utility.Create("Frame", {
			Name = "FocusIndicator",
			Parent = swatchTile,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2),
			Visible = (i == 1),
			ZIndex = 96,
		})
		Utility.AddStroke(focusRing, Color3.fromRGB(0, 0, 0), 1, 0, Enum.ApplyStrokeMode.Border)

		table.insert(customSwatchFrames, {
			Button = swatchTile,
			FocusRing = focusRing,
			Index = i,
		})

		swatchTile.MouseButton1Click:Connect(function()
			selectedCustomSlot = i
			local c = DWM.CustomColors[i]
			curR = math.floor(c.R * 255 + 0.5)
			curG = math.floor(c.G * 255 + 0.5)
			curB = math.floor(c.B * 255 + 0.5)
			curHue, curSat, curLum = ColorDialog.RgbToHls(curR, curG, curB)
			updateVisuals("CustomSwatch")
		end)
	end

	-- "Define Custom Colors >>" button
	local defineBtn = Utility.Create("TextButton", {
		Name = "DefineCustomColorsButton",
		Parent = clientBox,
		Position = UDim2.new(0, 8, 0, 238),
		Size = UDim2.new(0, 212, 0, 23),
		Font = Theme.Fonts.Regular,
		Text = isExpanded and "<< Define Custom Colors" or "Define Custom Colors >>",
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 95,
	})
	Utility.BindWin7ButtonStates(defineBtn, { CornerRadius = 3 })

	local function setExpanded(expand)
		isExpanded = expand
		defineBtn.Text = isExpanded and "<< Define Custom Colors" or "Define Custom Colors >>"
		local targetW = isExpanded and expandedWidth or collapsedWidth
		Utility.Tween(dialogFrame, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
			Size = UDim2.new(0, targetW, 0, dialogHeight),
		})
	end

	defineBtn.MouseButton1Click:Connect(function()
		setExpanded(not isExpanded)
	end)

	-- "OK" button
	local okBtn = Utility.Create("TextButton", {
		Name = "ColorDialogOKButton",
		Parent = clientBox,
		Position = UDim2.new(0, 8, 0, 272),
		Size = UDim2.new(0, 68, 0, 23),
		Font = Theme.Fonts.Regular,
		Text = "OK",
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 95,
	})
	Utility.BindWin7ButtonStates(okBtn, { CornerRadius = 3, IsDefault = true })
	okBtn.MouseButton1Click:Connect(function()
		callback(currentColor)
		closeDialog(false)
	end)

	-- "Cancel" button
	local cancelBtn = Utility.Create("TextButton", {
		Name = "ColorDialogCancelButton",
		Parent = clientBox,
		Position = UDim2.new(0, 80, 0, 272),
		Size = UDim2.new(0, 68, 0, 23),
		Font = Theme.Fonts.Regular,
		Text = "Cancel",
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 95,
	})
	Utility.BindWin7ButtonStates(cancelBtn, { CornerRadius = 3 })
	cancelBtn.MouseButton1Click:Connect(function()
		closeDialog(true)
	end)

	-- Right panel: spectrum box, luminosity bar, previews, inputs

	local rightPanel = Utility.Create("Frame", {
		Name = "RightCustomTuningPanel",
		Parent = clientBox,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 232, 0, 0),
		Size = UDim2.new(0, 236, 1, 0),
		ZIndex = 93,
	})

	-- 2D Hue/Saturation spectrum box (182x180 px)
	local spectrumBox = Utility.Create("TextButton", {
		Name = "Spectrum2DBox",
		Parent = rightPanel,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.new(0, 182, 0, 180),
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,
		ZIndex = 94,
	})
	Utility.AddStroke(spectrumBox, Color3.fromRGB(112, 112, 112), 1, 0, Enum.ApplyStrokeMode.Border)

	-- Horizontal Hue gradient (Red -> Yellow -> Green -> Cyan -> Blue -> Magenta -> Red)
	local hueGrad = Instance.new("UIGradient")
	hueGrad.Name = "HueSpectrumGradient"
	hueGrad.Rotation = 0
	hueGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
	})
	hueGrad.Parent = spectrumBox

	-- Vertical Saturation gradient overlay (bottom gray 128,128,128, top transparent pure color)
	local satOverlay = Utility.Create("Frame", {
		Name = "SaturationOverlay",
		Parent = spectrumBox,
		BackgroundColor3 = Color3.fromRGB(128, 128, 128),
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 95,
	})
	local satGrad = Instance.new("UIGradient")
	satGrad.Name = "SatVerticalGradient"
	satGrad.Rotation = 90
	satGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1.00), -- Top: pure color
		NumberSequenceKeypoint.new(1.00, 0.00), -- Bottom: zero saturation gray
	})
	satGrad.Parent = satOverlay

	-- Crosshair reticle
	reticle = Utility.Create("Frame", {
		Name = "SpectrumCrosshairReticle",
		Parent = spectrumBox,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 13, 0, 13),
		ZIndex = 97,
	})
	-- High-contrast black/white reticle circle
	local retOuter = Utility.Create("Frame", {
		Name = "ReticleOuterRing",
		Parent = reticle,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 97,
	})
	Utility.AddCorner(retOuter, 7)
	Utility.AddStroke(retOuter, Color3.fromRGB(0, 0, 0), 1.5, 0, Enum.ApplyStrokeMode.Border)

	local retInner = Utility.Create("Frame", {
		Name = "ReticleInnerRing",
		Parent = reticle,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 98,
	})
	Utility.AddCorner(retInner, 6)
	Utility.AddStroke(retInner, Color3.fromRGB(255, 255, 255), 1, 0, Enum.ApplyStrokeMode.Border)

	-- Drag handling on 2D spectrum box
	local isDraggingSpectrum = false
	local function updateFromSpectrumPos(inputX, inputY)
		local boxAbsPos = spectrumBox.AbsolutePosition
		local boxAbsSize = spectrumBox.AbsoluteSize
		if boxAbsSize.X <= 0 or boxAbsSize.Y <= 0 then return end

		local relX = math.clamp((inputX - boxAbsPos.X) / boxAbsSize.X, 0, 1)
		local relY = math.clamp((inputY - boxAbsPos.Y) / boxAbsSize.Y, 0, 1)

		curHue = math.clamp(math.floor(relX * 239 + 0.5), 0, 239)
		curSat = math.clamp(math.floor((1 - relY) * 240 + 0.5), 0, 240)
		curR, curG, curB = ColorDialog.HlsToRgb(curHue, curLum, curSat)
		updateVisuals("Spectrum")
	end

	spectrumBox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingSpectrum = true
			updateFromSpectrumPos(input.Position.X, input.Position.Y)
		end
	end)
	spectrumBox.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingSpectrum = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if isDraggingSpectrum and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromSpectrumPos(input.Position.X, input.Position.Y)
		end
	end)

	-- Vertical Luminosity slider (12x180 px)
	local lumBar = Utility.Create("TextButton", {
		Name = "LuminositySliderBar",
		Parent = rightPanel,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 190, 0, 8),
		Size = UDim2.new(0, 12, 0, 180),
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = false,
		ZIndex = 94,
	})
	Utility.AddStroke(lumBar, Color3.fromRGB(112, 112, 112), 1, 0, Enum.ApplyStrokeMode.Border)

	lumGradient = Instance.new("UIGradient")
	lumGradient.Name = "LumVerticalGradient"
	lumGradient.Rotation = 90
	lumGradient.Parent = lumBar

	-- Black left-pointing triangle indicator arrow (◄)
	lumArrow = Utility.Create("TextLabel", {
		Name = "LumIndicatorArrow",
		Parent = lumBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 4, 0, 0),
		Size = UDim2.new(0, 10, 0, 10),
		Font = Theme.Fonts.Bold,
		Text = "◄",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 96,
	})

	local isDraggingLum = false
	local function updateFromLumPos(inputY)
		local barAbsPos = lumBar.AbsolutePosition
		local barAbsSize = lumBar.AbsoluteSize
		if barAbsSize.Y <= 0 then return end

		local relY = math.clamp((inputY - barAbsPos.Y) / barAbsSize.Y, 0, 1)
		curLum = math.clamp(math.floor((1 - relY) * 240 + 0.5), 0, 240)
		curR, curG, curB = ColorDialog.HlsToRgb(curHue, curLum, curSat)
		updateVisuals("Lum")
	end

	lumBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingLum = true
			updateFromLumPos(input.Position.Y)
		end
	end)
	lumBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingLum = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if isDraggingLum and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromLumPos(input.Position.Y)
		end
	end)

	-- "Color | Solid" preview frame
	previewColorBox = Utility.Create("Frame", {
		Name = "ColorSolidPreviewBox",
		Parent = rightPanel,
		BackgroundColor3 = currentColor,
		Position = UDim2.new(0, 0, 0, 196),
		Size = UDim2.new(0, 60, 0, 36),
		ZIndex = 94,
	})
	Utility.AddStroke(previewColorBox, Color3.fromRGB(112, 112, 112), 1, 0, Enum.ApplyStrokeMode.Border)

	Utility.Create("TextLabel", {
		Name = "ColorLabel",
		Parent = rightPanel,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 234),
		Size = UDim2.new(0, 28, 0, 14),
		Font = Theme.Fonts.Regular,
		Text = "Color",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 94,
	})
	Utility.Create("TextLabel", {
		Name = "SolidLabel",
		Parent = rightPanel,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 28, 0, 234),
		Size = UDim2.new(0, 32, 0, 14),
		Font = Theme.Fonts.Regular,
		Text = "|Solid",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 94,
	})

	-- Helper to create standard Windows 7 numeric edit box
	local function createNumericInput(parent, labelText, xPos, yPos, maxVal, onChange)
		Utility.Create("TextLabel", {
			Name = "Label_" .. labelText,
			Parent = parent,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, xPos, 0, yPos + 1),
			Size = UDim2.new(0, 34, 0, 18),
			Font = Theme.Fonts.Regular,
			Text = labelText,
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 94,
		})

		local boxContainer = Utility.Create("Frame", {
			Name = "EditWrap_" .. labelText,
			Parent = parent,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0, xPos + 38, 0, yPos),
			Size = UDim2.new(0, 28, 0, 20),
			ZIndex = 94,
		})
		local border = Utility.AddStroke(boxContainer, Theme.Colors.ControlBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

		local tb = Utility.Create("TextBox", {
			Name = "InputBox",
			Parent = boxContainer,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 2, 0, 0),
			Size = UDim2.new(1, -4, 1, 0),
			ClearTextOnFocus = false,
			Font = Theme.Fonts.Regular,
			Text = "0",
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 95,
		})

		tb.Focused:Connect(function()
			border.Color = Theme.Colors.ControlBorderFocus
		end)
		tb.FocusLost:Connect(function()
			border.Color = Theme.Colors.ControlBorderNormal
			local n = tonumber(tb.Text) or 0
			n = math.clamp(math.floor(n), 0, maxVal)
			tb.Text = tostring(n)
			onChange(n)
		end)

		return tb
	end

	-- HLS group: Hue (0-239), Sat (0-240), Lum (0-240)
	inpHue = createNumericInput(rightPanel, "Hue:", 68, 194, 239, function(v)
		curHue = v
		curR, curG, curB = ColorDialog.HlsToRgb(curHue, curLum, curSat)
		updateVisuals("Hue")
	end)
	inpSat = createNumericInput(rightPanel, "Sat:", 68, 216, 240, function(v)
		curSat = v
		curR, curG, curB = ColorDialog.HlsToRgb(curHue, curLum, curSat)
		updateVisuals("Sat")
	end)
	inpLum = createNumericInput(rightPanel, "Lum:", 68, 238, 240, function(v)
		curLum = v
		curR, curG, curB = ColorDialog.HlsToRgb(curHue, curLum, curSat)
		updateVisuals("Lum")
	end)

	-- RGB group: Red (0-255), Green (0-255), Blue (0-255)
	inpRed = createNumericInput(rightPanel, "Red:", 136, 194, 255, function(v)
		curR = v
		curHue, curSat, curLum = ColorDialog.RgbToHls(curR, curG, curB)
		updateVisuals("Red")
	end)
	inpGreen = createNumericInput(rightPanel, "Green:", 136, 216, 255, function(v)
		curG = v
		curHue, curSat, curLum = ColorDialog.RgbToHls(curR, curG, curB)
		updateVisuals("Green")
	end)
	inpBlue = createNumericInput(rightPanel, "Blue:", 136, 238, 255, function(v)
		curB = v
		curHue, curSat, curLum = ColorDialog.RgbToHls(curR, curG, curB)
		updateVisuals("Blue")
	end)

	-- "Add to Custom Colors" button
	local addCustomBtn = Utility.Create("TextButton", {
		Name = "AddToCustomColorsButton",
		Parent = rightPanel,
		Position = UDim2.new(0, 0, 0, 272),
		Size = UDim2.new(0, 234, 0, 23),
		Font = Theme.Fonts.Regular,
		Text = "Add to Custom Colors",
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 95,
	})
	Utility.BindWin7ButtonStates(addCustomBtn, { CornerRadius = 3 })
	addCustomBtn.MouseButton1Click:Connect(function()
		DWM.CustomColors[selectedCustomSlot] = currentColor
		if customSwatchFrames[selectedCustomSlot] then
			customSwatchFrames[selectedCustomSlot].Button.BackgroundColor3 = currentColor
		end
		updateVisuals("AddCustom")
	end)

	-- Initial display synchronization
	updateVisuals("Init")

	DWM.AnimateOpen(dialogFrame, scale, dialogGlass)

	return {
		Overlay = overlay,
		DialogFrame = dialogFrame,
		Close = function() closeDialog(false) end,
		GetColor = function() return currentColor end,
	}
end

return ColorDialog
