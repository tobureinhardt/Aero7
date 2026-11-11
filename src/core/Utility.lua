--!nonstrict
-- Aero7: core/Utility - Core utilities: signals, tweens, dual-layer bevel borders, DWM glowing text, vector icons, and shadow rendering.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Theme = require("core/Theme")

local Utility = {}

-- Lightweight Luau signal implementation
function Utility.CreateSignal()
	local listeners = {}
	local signal = {}

	function signal:Connect(fn)
		local conn = { Connected = true, _fn = fn }
		table.insert(listeners, conn)
		function conn:Disconnect()
			conn.Connected = false
			for i = #listeners, 1, -1 do
				if listeners[i] == conn then
					table.remove(listeners, i)
					break
				end
			end
		end
		return conn
	end

	function signal:Fire(...)
		local snapshot = {}
		for i = 1, #listeners do
			snapshot[i] = listeners[i]
		end
		for i = 1, #snapshot do
			local conn = snapshot[i]
			if conn and conn.Connected then
				task.spawn(conn._fn, ...)
			end
		end
	end

	function signal:Destroy()
		for i = #listeners, 1, -1 do
			listeners[i].Connected = false
			listeners[i] = nil
		end
	end

	return signal
end

-- Safely gets Gui container across studio and executor environments
function Utility.GetSafeGuiParent()
	local okHui, hui = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if okHui and hui then
		return hui
	end

	local okCore, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and coreGui then
		local okTest = pcall(function()
			return coreGui.Name
		end)
		if okTest then
			return coreGui
		end
	end

	local lp = Players.LocalPlayer
	if lp then
		local pg = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 3)
		if pg then
			return pg
		end
	end

	return game:GetService("Workspace")
end

-- Instantiates GuiObjects with properties, children, and automatic Segoe UI font mapping
function Utility.Create(className, props, children)
	local inst = Instance.new(className)
	if className == "Frame" or className == "ScrollingFrame" or className == "TextButton" or className == "TextLabel" or className == "TextBox" or className == "ImageLabel" or className == "ImageButton" then
		inst.BorderSizePixel = 0
	end
	if className == "TextButton" or className == "ImageButton" then
		inst.AutoButtonColor = false
	end

	local parent = nil
	local fontProp = nil
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			elseif k == "Font" then
				fontProp = v
				if type(v) == "string" then
					inst.Font = Theme.Fonts[v] or Theme.Fonts.Regular
				else
					inst.Font = v
				end
			else
				inst[k] = v
			end
		end
	end

	if className == "TextLabel" or className == "TextButton" or className == "TextBox" then
		Theme.RegisterTextObject(inst, fontProp)
	end

	if children then
		for _, child in ipairs(children) do
			if child then
				child.Parent = inst
			end
		end
	end

	if parent then
		inst.Parent = parent
	end

	return inst
end

-- Executes smooth DWM-style tween
function Utility.Tween(instance, duration, easingStyle, easingDirection, goal)
	if not instance then
		return nil
	end
	local info = TweenInfo.new(
		duration or 0.16,
		easingStyle or Enum.EasingStyle.Cubic,
		easingDirection or Enum.EasingDirection.Out
	)
	local tw = TweenService:Create(instance, info, goal)
	tw:Play()
	return tw
end

-- Creates UICorner
function Utility.AddCorner(parent, radiusPx)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radiusPx or 3)
	corner.Parent = parent
	return corner
end

-- Creates UIStroke
function Utility.AddStroke(parent, color, thickness, transparency, applyMode)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Colors.ControlBorderNormal
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = applyMode or Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

-- Creates dual-layer bevel border: outer dark rim + inner specular highlight
function Utility.ApplyDualBevel(frame, outerColor, outerTrans, innerColor, innerTrans, radiusPx)
	if radiusPx and radiusPx > 0 then
		Utility.AddCorner(frame, radiusPx)
	end

	local outerStroke = Utility.AddStroke(
		frame,
		outerColor or Theme.Colors.WindowOuterBorder,
		1,
		outerTrans or 0.38,
		Enum.ApplyStrokeMode.Border
	)
	outerStroke.Name = "OuterBevelStroke"

	local innerBevel = Utility.Create("Frame", {
		Name = "InnerBevelFrame",
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = frame.ZIndex + 1,
	})
	if radiusPx and radiusPx > 1 then
		Utility.AddCorner(innerBevel, radiusPx - 1)
	end

	local innerStroke = Utility.AddStroke(
		innerBevel,
		innerColor or Theme.Colors.WindowInnerHighlight,
		1,
		innerTrans or 0.18,
		Enum.ApplyStrokeMode.Border
	)
	innerStroke.Name = "InnerBevelStroke"

	local bevelGrad = Instance.new("UIGradient")
	bevelGrad.Rotation = 90
	bevelGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.00),
		NumberSequenceKeypoint.new(0.35, 0.32),
		NumberSequenceKeypoint.new(0.85, 0.50),
		NumberSequenceKeypoint.new(1.00, 0.15),
	})
	bevelGrad.Parent = innerStroke

	return outerStroke, innerStroke, innerBevel
end

-- Creates DWM glowing titlebar text with outer halo
function Utility.CreateGlowingTitle(parent, text, zIndex)
	local container = Utility.Create("Frame", {
		Name = "GlowingTitleContainer",
		Parent = parent,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 30, 0, 0),
		Size = UDim2.new(1, -142, 0, 28),
		ZIndex = zIndex or 5,
	})

	-- Soft white halo behind text for readability on translucent glass
	local glowBack1 = Utility.Create("TextLabel", {
		Name = "GlowHaloOuter",
		Parent = container,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -1, 0, 0),
		Size = UDim2.new(1, 2, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = text or "Windows 7",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0.42,
		TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
		TextStrokeTransparency = 0.35,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = (zIndex or 5),
	})

	local glowBack2 = Utility.Create("TextLabel", {
		Name = "GlowHaloInner",
		Parent = container,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, 0, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = text or "Windows 7",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0.55,
		TextStrokeColor3 = Color3.fromRGB(225, 240, 255),
		TextStrokeTransparency = 0.45,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = (zIndex or 5) + 1,
	})

	local mainLabel = Utility.Create("TextLabel", {
		Name = "TitleText",
		Parent = container,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = text or "Windows 7",
		TextColor3 = Theme.Colors.TitleTextActive,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = (zIndex or 5) + 2,
	})

	local controller = {
		Container = container,
		MainLabel = mainLabel,
		Glow1 = glowBack1,
		Glow2 = glowBack2,
	}

	function controller:SetText(newText)
		mainLabel.Text = tostring(newText or "")
		glowBack1.Text = mainLabel.Text
		glowBack2.Text = mainLabel.Text
	end

	function controller:SetActive(isActive)
		if isActive then
			mainLabel.TextTransparency = 0
			glowBack1.TextTransparency = 0.42
			glowBack2.TextTransparency = 0.55
		else
			mainLabel.TextTransparency = 0.35
			glowBack1.TextTransparency = 0.72
			glowBack2.TextTransparency = 0.80
		end
	end

	return controller
end

-- Attaches standard Windows 7 button dynamics (50/50 split-gradient, bevels, hover/press states)
function Utility.BindWin7ButtonStates(button, options)
	options = options or {}
	local radius = options.CornerRadius or 3
	local isDefault = options.IsDefault == true

	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Utility.AddCorner(button, radius)

	local outerStroke = Utility.AddStroke(
		button,
		isDefault and Theme.Colors.ControlBorderHover or Theme.Colors.ControlBorderNormal,
		1,
		0,
		Enum.ApplyStrokeMode.Border
	)
	outerStroke.Name = "Win7OuterBorder"

	local innerHighlight = Utility.Create("Frame", {
		Name = "Win7InnerHighlight",
		Parent = button,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = button.ZIndex + 1,
	})
	if radius > 1 then
		Utility.AddCorner(innerHighlight, radius - 1)
	end

	local innerStroke = Utility.AddStroke(
		innerHighlight,
		isDefault and Color3.fromRGB(96, 198, 252) or Color3.fromRGB(255, 255, 255),
		1,
		isDefault and 0.15 or 0.25,
		Enum.ApplyStrokeMode.Border
	)

	local grad = Instance.new("UIGradient")
	grad.Name = "Win7SplitGradient"
	grad.Rotation = 90
	grad.Color = options.NormalGradient or Theme.Gradients.ButtonNormal
	grad.Parent = button

	local state = {
		Hovered = false,
		Pressed = false,
		Disabled = false,
		IsDefault = isDefault,
		OuterStroke = outerStroke,
		InnerStroke = innerStroke,
		Gradient = grad,
	}

	local function refreshVisual()
		if state.Disabled then
			outerStroke.Color = Theme.Colors.ControlBorderDisabled
			innerStroke.Transparency = 0.7
			grad.Color = Theme.Gradients.ButtonDisabled
			return
		end

		if state.Pressed then
			outerStroke.Color = Theme.Colors.ControlBorderPressed
			innerStroke.Color = Color3.fromRGB(130, 194, 232)
			innerStroke.Transparency = 0.25
			grad.Color = options.PressedGradient or Theme.Gradients.ButtonPressed
		elseif state.Hovered then
			outerStroke.Color = Theme.Colors.ControlBorderHover
			innerStroke.Color = Theme.Colors.ControlInnerGlowHover
			innerStroke.Transparency = 0.10
			grad.Color = options.HoverGradient or Theme.Gradients.ButtonHover
		else
			outerStroke.Color = state.IsDefault and Theme.Colors.ControlBorderHover or Theme.Colors.ControlBorderNormal
			innerStroke.Color = state.IsDefault and Color3.fromRGB(96, 198, 252) or Color3.fromRGB(255, 255, 255)
			innerStroke.Transparency = state.IsDefault and 0.15 or 0.25
			grad.Color = options.NormalGradient or Theme.Gradients.ButtonNormal
		end
	end

	button.MouseEnter:Connect(function()
		state.Hovered = true
		refreshVisual()
	end)

	button.MouseLeave:Connect(function()
		state.Hovered = false
		state.Pressed = false
		refreshVisual()
	end)

	button.MouseButton1Down:Connect(function()
		if not state.Disabled then
			state.Pressed = true
			refreshVisual()
		end
	end)

	button.MouseButton1Up:Connect(function()
		if state.Pressed then
			state.Pressed = false
			refreshVisual()
		end
	end)

	function state:SetDisabled(disabled)
		state.Disabled = disabled == true
		refreshVisual()
	end

	function state:SetDefault(def)
		state.IsDefault = def == true
		refreshVisual()
	end

	refreshVisual()
	return state
end

-- Renders a thin rotated chevron branch (±45° rounded bar with anti-aliasing)
local function createChevronArm(holder, name, cx, cy, rot, color, trans, z)
	local arm = Utility.Create("Frame", {
		Name = name,
		Parent = holder,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BackgroundTransparency = trans or 0,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, cx, 0.5, cy),
		Rotation = rot,
		Size = UDim2.new(0, 5, 0, 2),
		ZIndex = z,
	})
	Utility.AddCorner(arm, 1)
	return arm
end

-- Positions dual chevron branches around center (ox, oy) according to direction
local function layoutChevronArms(arms, direction, ox, oy)
	local d = 1.8
	local specs
	if direction == "Up" then
		specs = { { -d, 0, -45 }, { d, 0, 45 } }
	elseif direction == "Right" then
		specs = { { 0, -d, 45 }, { 0, d, -45 } }
	elseif direction == "Left" then
		specs = { { 0, -d, -45 }, { 0, d, 45 } }
	else -- Down
		specs = { { -d, 0, 45 }, { d, 0, -45 } }
	end
	for i = 1, 2 do
		arms[i].Position = UDim2.new(0.5, ox + specs[i][1], 0.5, oy + specs[i][2])
		arms[i].Rotation = specs[i][3]
	end
end

-- Renders smooth vector chevron ("Down", "Up", "Left", "Right")
function Utility.CreateVectorChevron(parent, direction, color, zIndex)
	direction = direction or "Down"
	color = color or Color3.fromRGB(42, 58, 78)
	local zi = zIndex or (parent and parent.ZIndex + 2 or 5)

	local holder = Utility.Create("Frame", {
		Name = "Win7VectorChevron",
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 10, 0, 10),
		ZIndex = zi,
	})

	local arms = {
		createChevronArm(holder, "ChevronArm_1", 0, 0, 45, color, 0, zi + 1),
		createChevronArm(holder, "ChevronArm_2", 0, 0, -45, color, 0, zi + 1),
	}

	local ctrl = {
		Holder = holder,
		Bars = arms,
		Wing1 = arms[1],
		Wing2 = arms[2],
		Direction = direction,
	}

	function ctrl:SetDirection(dir)
		self.Direction = dir or "Down"
		layoutChevronArms(arms, self.Direction, 0, 0)
	end

	function ctrl:SetColor(newColor, trans)
		for i = 1, 2 do
			if newColor then
				arms[i].BackgroundColor3 = newColor
			end
			if trans ~= nil then
				arms[i].BackgroundTransparency = trans
			end
		end
	end

	ctrl:SetDirection(direction)
	return ctrl
end

-- Renders breadcrumb double-arrow symbol (« or ») for Explorer address bar
function Utility.CreateVectorDoubleChevron(parent, direction, color, zIndex)
	direction = direction or "Left"
	color = color or Color3.fromRGB(48, 78, 114)
	local zi = zIndex or (parent and parent.ZIndex + 1 or 5)

	local holder = Utility.Create("Frame", {
		Name = "Win7VectorDoubleChevron",
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 10, 0, 10),
		ZIndex = zi,
	})

	local arms = {}
	for i = 1, 4 do
		arms[i] = createChevronArm(holder, "DoubleChevronArm_" .. tostring(i), 0, 0, 45, color, 0, zi + 1)
	end

	local ctrl = {
		Holder = holder,
		Direction = direction,
	}

	function ctrl:SetDirection(dir)
		self.Direction = dir or "Left"
		layoutChevronArms({ arms[1], arms[2] }, self.Direction, -2, 0)
		layoutChevronArms({ arms[3], arms[4] }, self.Direction, 2, 0)
	end

	function ctrl:SetColor(newColor, trans)
		for i = 1, 4 do
			if newColor then
				arms[i].BackgroundColor3 = newColor
			end
			if trans ~= nil then
				arms[i].BackgroundTransparency = trans
			end
		end
	end

	ctrl:SetDirection(direction)
	return ctrl
end

-- Renders arrow vector with shaft (Arrow ← / →) for Explorer Back/Forward buttons
function Utility.CreateVectorArrow(parent, direction, mainColor, shadowColor, zIndex)
	direction = direction or "Left"
	mainColor = mainColor or Color3.fromRGB(255, 255, 255)
	shadowColor = shadowColor or Color3.fromRGB(10, 44, 92)
	local zi = zIndex or (parent and parent.ZIndex + 2 or 8)

	local holder = Utility.Create("Frame", {
		Name = "Win7VectorArrow",
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		ZIndex = zi,
	})

	local isLeft = (direction == "Left")
	local s = isLeft and 1 or -1

	local function buildLayer(offsetY, col, layerZ)
		local parts = {}
		-- Horizontal shaft 9px wide, 2px high connecting directly to arrowhead
		table.insert(parts, Utility.Create("Frame", {
			Name = "Shaft",
			Parent = holder,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = col,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 1 * s, 0.5, offsetY),
			Size = UDim2.new(0, 9, 0, 2),
			ZIndex = layerZ,
		}))

		-- Arrowhead: dual thin rotated branches (anti-aliased)
		local wingLen = 7
		for idx, sign in ipairs({ -1, 1 }) do
			local wing = Utility.Create("Frame", {
				Name = "HeadWing_" .. tostring(idx),
				Parent = holder,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = col,
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, -2.9 * s, 0.5, sign * 2.4 + offsetY),
				Rotation = sign * 45 * s,
				Size = UDim2.new(0, wingLen, 0, 2),
				ZIndex = layerZ,
			})
			Utility.AddCorner(wing, 1)
			table.insert(parts, wing)
		end

		return parts
	end

	local shadowParts = buildLayer(1, shadowColor, zi)
	local mainParts = buildLayer(0, mainColor, zi + 2)

	local ctrl = {
		Holder = holder,
		MainParts = mainParts,
		ShadowParts = shadowParts,
	}

	function ctrl:SetAlpha(trans)
		for _, p in ipairs(mainParts) do
			p.BackgroundTransparency = trans
		end
		for _, p in ipairs(shadowParts) do
			p.BackgroundTransparency = math.clamp(trans + 0.35, 0, 1)
		end
	end

	function ctrl:SetColor(newMainColor, newShadowColor, trans)
		if newMainColor then
			for _, p in ipairs(mainParts) do
				p.BackgroundColor3 = newMainColor
			end
		end
		if newShadowColor then
			for _, p in ipairs(shadowParts) do
				p.BackgroundColor3 = newShadowColor
			end
		end
		if trans ~= nil then
			self:SetAlpha(trans)
		end
	end

	return ctrl
end

-- Renders Windows 7 Caption close mark (✖) with crisp geometry
function Utility.CreateVectorCloseX(parent, mainColor, shadowColor, zIndex)
	mainColor = mainColor or Color3.fromRGB(255, 255, 255)
	shadowColor = shadowColor or Color3.fromRGB(52, 12, 12)
	local zi = zIndex or (parent and parent.ZIndex + 2 or 10)

	local holder = Utility.Create("Frame", {
		Name = "Glyph_Close",
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		ZIndex = zi,
	})

	-- Thin X mark: dual ±45° rotated rounded bars with 1px drop shadow
	local function addBar(prefix, col, trans, dy, z)
		for idx, rot in ipairs({ 45, -45 }) do
			local bar = Utility.Create("Frame", {
				Name = prefix .. tostring(idx),
				Parent = holder,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = col,
				BackgroundTransparency = trans,
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 0.5, dy),
				Rotation = rot,
				Size = UDim2.new(0, 12, 0, 2),
				ZIndex = z,
			})
			Utility.AddCorner(bar, 1)
		end
	end
	addBar("ShadowBar_", shadowColor, 0.3, 1, zi)
	addBar("MainBar_", mainColor, 0, 0, zi + 1)

	return holder
end

-- 9-Slice Gaussian shadow and glow assets (7.css gui/_window.scss specification)
local SHADOW_9SLICE_B64 = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAEzklEQVR42u2b3UtUQRiH19wvLduVpZXyI3OxQEXyQkRD7SYQQbaLQiL8SL3KmyUQu0gIBAnc\
	ujJEzAuNWCm2/Rd7DzxD0+Ecd9s9s0fYOfDcyXl/72/eeee4MxOJ2MfY02aQa53gjSbSVIOuSrQdoi5iBnDHULGvMiawxPWE9STjQkJICh3QaRAVI0ncuMuc\
	dh8zGk5eH2k9aUfUTaFLuA0pg6gYXcTtdJnhroy6TPBKXo14ghFQSTuiuoWMcEfICj0GyRInQ9yUZkYH+mKuavgvA/ySj2sj7gRMI8IRdFfoEwaEQeGBQQaJ\
	00fcLDrS6FIVEa/HBK/k1Tx33L2F4xlGo1e4L+SER8KIMCaMG2SMOI+Iex8dPehKobND6w+6CTUZoCevSl6NulN+9xiJYWFUeCxMCtPCE2FWmDPALO+fJt5j\
	4g+j5x76VDXoU6KqCX5lr5LvxuV+nHdGYQIx88IzYVFYEvLCcwPkef8i8eaJP4GeHPp60NulVUK0FgOqJe/MvYeU4pTwVFhA3LKwIrwRNoUtA2zy/hXiPSf+\
	U/SMo2/Ax4T2Wg2I0UhuUU568k7ZzTACzoi8EjaEt0JB2BF2hfcG2OX9BeJtED+Pnhn06SakySNZrQratNFP0E1TzKl+LfknuP5CWBe2EbUn7AufhEOhaIBD\
	3r9PvB3ir6NnAX3KhH70p8gn5meAGn136WdoLDnKa4YgLylHZyQ+CAfCF+FIOBFOhW8GOOX9R8Q7IH4BPS/RN4PeHPoz5JPwmwa6AQk+KlTpD9JgpiizFwR7\
	J3xkZL4KZ8KF8EMoCZcGKPH+C+J9Jf5H9Gyi7xl6R9CvpkKymgFq7qvR72WJmaDR5Cm3AkE/MyLnwmthCBODfqKM5qpQFn5hxjnxP6OngL48eifQ30s+nbyr\
	zW/+x7W5n+UjY5SlZoGGs03ZFbXgQ038V9wx4hgjfgrf0VFE1zY6F9A9Sh5ZKlv1AU8DVPl385mZo6HMs+Rs0HgOKL/zJievm1ARfmPCOXoO0LeB3nn058in\
	i0H2NCDqKv8+PjcnmVPLLD17NKAzyj6sZw0TykyHM3TtoXMZ3ZPk0cd/kZ4GqAbYwR/dYR0doYwW+fgosAQd0YiGQjRAVUGFnnCBrn10rqB7mjwGmNqJWgzI\
	0j3HWFeX+ALbYR0+oRtHQzQgqhlQRs8J+nbQu4T+MfJJexmgL4GqAfbwr+c4/4DkWWJ2+Rg5pezCfipaLyih6xCdm+ieJY8H9DZfA2I+BszRULb4HC3yUXJ5\
	zQy4RFcRnVvonnMZkLQGWAOsAdYAa4A1wBpgDbAGWAOsAdYAa4A1wBpgDbAGWAPqN+C6/CgamgG5a/KzeCAG1POr8GqIBqwF9atwI/sC5ZCqQB/9hvcFvAyo\
	dWfI2ZE5brIJanNUN6DhnaF69wZLuF+hJHMRs9vja67EA9sbbGR3+CdzsBICge4O13s+4Dsiyk1OPvDzAY2eECkxF8uMjCmMnRCxZ4QiLXxKTO8DLXlOUK+C\
	lj4p2vJnhVv6tLiXCS11X0A3oGVvjPiZ0DJ3hvymg9fNMa8rcymEdBskHfl7fc7r6pz7xlhdyV9VEe47hGqKqLuECc2goNHfH4/8e2myPRLgpclazAjjvvD/\
	3CO2T7XnD5swrHpbNaKbAAAAAElFTkSuQmCC"
local GLOW_9SLICE_B64 = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAACgUlEQVR42u2arW8iQRyGe2X5LE2TTRoQR0VJCAEc4lJDgiFBklTQnMMjKhCIyjPYCipqT2Ow\
	iIqKNjlF9u/h3kmevWy3e5cTg9jNiEdB3o/f7GyWHU4Oh8NJmvnXh19inEbIHYmoR9z/vwtEAxtRT+RFQRRFSZShYolQr4RHAU8vUiyxSFL4MHgeMWNQFRfC\
	F5eiJuqWqaHt41XFu0iWaJHEAmF4jwmYiZwjaMQb4lq0REd0Rc8SXTRbeDTw9MlQJpMXLxEvkOOLFaZgJvJVNDHpixsxEEPLDNDu49XE+5IsFbLlkgqE08/T\
	Ngx/JdqIGoOxmIip+G6ZKdpjvPp4X0VKlMn4ZxXi0y+yZGF4s6zfxEjcipmYi4VYWmaB9gyvEd6dSIlzMuaSCngsk8/StREYMyEj/iBW4lGsxZMl1miu8Jjj\
	OSZDm0w+Gb2kAnl2fo3rr88UjNC9+IHRT7ERW8ts0F7jdY/3iCxNslXJ+qHAKRvkgjtAl+vwlmkYwWdMduJVvIl3S7yhucPjGc85GQZkapCxQOYPBYos0TWN\
	x1yPD0zFCL+IX2IvAsvs0X7Ba433jCx9svlk/VSgxEZpcTubMIEVS7vDwJjdiTOLzzRnaAZ47PBckWFCphYZS/ECOW5RNXb9gNvags21YYn3GB3r4ewOj1c8\
	H8kwJVOHjGUyfypQ51obsoGWLOWW6zSwPPmklQjw2uK9JMuQbPW/FajwYS9W4Amxd8SP/Ygc4LXFO1qgR8aKK+AKuAKugCvgCrgCroAr4Aq4Aq5Apgqk/idl\
	qn/Up/61SiZebKX61WLqX+5m4vV66g84Un3ElPpDvkwcs6b+oDsTfzXIxJ89UsVvoqHIvRjFj9kAAAAASUVORK5CYII="

local cachedShadowSliceAsset = nil
local cachedGlowSliceAsset = nil
local triedSliceAssets = false

local function decodeB64Bytes(data)
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local map = {}
	for i = 1, #b do
		map[string.byte(b, i)] = i - 1
	end
	local out = {}
	local n = 0
	local val = 0
	local count = 0
	for i = 1, #data do
		local c = string.byte(data, i)
		local v = map[c]
		if v ~= nil then
			val = val * 64 + v
			count = count + 1
			if count == 4 then
				local b1 = math.floor(val / 65536) % 256
				local b2 = math.floor(val / 256) % 256
				local b3 = val % 256
				n = n + 1
				out[n] = string.char(b1, b2, b3)
				val = 0
				count = 0
			end
		elseif c == 61 then
			if count == 3 then
				val = val * 64
				local b1 = math.floor(val / 65536) % 256
				local b2 = math.floor(val / 256) % 256
				n = n + 1
				out[n] = string.char(b1, b2)
			elseif count == 2 then
				val = val * 4096
				local b1 = math.floor(val / 65536) % 256
				n = n + 1
				out[n] = string.char(b1)
			end
			break
		end
	end
	return table.concat(out)
end

local function ensure9SliceAssets()
	if triedSliceAssets then
		return
	end
	triedSliceAssets = true

	local g = (type(getfenv) == "function" and getfenv()) or _G
	local getAssetFn = (type(getcustomasset) == "function" and getcustomasset)
		or (type(getsynasset) == "function" and getsynasset)
		or (type(g) == "table" and (g.getcustomasset or g.getsynasset))
	local writeFileFn = (type(writefile) == "function" and writefile) or (type(g) == "table" and g.writefile)
	local isFileFn = (type(isfile) == "function" and isfile) or (type(g) == "table" and g.isfile)
	local isFolderFn = (type(isfolder) == "function" and isfolder) or (type(g) == "table" and g.isfolder)
	local makeFolderFn = (type(makefolder) == "function" and makefolder) or (type(g) == "table" and g.makefolder)

	if type(getAssetFn) ~= "function" or type(writeFileFn) ~= "function" then
		return
	end

	pcall(function()
		if type(makeFolderFn) == "function" then
			if not (type(isFolderFn) == "function" and isFolderFn("Win7UI")) then
				makeFolderFn("Win7UI")
			end
		end

		local shPath = "Win7UI/window_shadow_9slice.png"
		local okShE, shExists = false, false
		if type(isFileFn) == "function" then
			okShE, shExists = pcall(isFileFn, shPath)
		end
		if not (okShE and shExists == true) then
			writeFileFn(shPath, decodeB64Bytes(SHADOW_9SLICE_B64))
		end
		local okShA, shUrl = pcall(getAssetFn, shPath)
		if okShA and type(shUrl) == "string" and shUrl ~= "" then
			cachedShadowSliceAsset = shUrl
		end

		local glPath = "Win7UI/button_glow_9slice.png"
		local okGlE, glExists = false, false
		if type(isFileFn) == "function" then
			okGlE, glExists = pcall(isFileFn, glPath)
		end
		if not (okGlE and glExists == true) then
			writeFileFn(glPath, decodeB64Bytes(GLOW_9SLICE_B64))
		end
		local okGlA, glUrl = pcall(getAssetFn, glPath)
		if okGlA and type(glUrl) == "string" and glUrl ~= "" then
			cachedGlowSliceAsset = glUrl
		end
	end)
end

function Utility.GetShadow9SliceAsset()
	ensure9SliceAssets()
	return cachedShadowSliceAsset
end

function Utility.GetGlow9SliceAsset()
	ensure9SliceAssets()
	return cachedGlowSliceAsset
end

-- Creates smooth Gaussian fade glow effect (7.css box-shadow: 0 0 7px 3px)
-- Uses transparent background with radial gradient diffusion to 0% opacity
function Utility.AttachGaussianGlow(haloFrame, glowColor, cornerRadius, maxSpreadPx)
	haloFrame.BackgroundTransparency = 1
	glowColor = glowColor or Color3.fromRGB(230, 142, 117)
	cornerRadius = tonumber(cornerRadius) or 3
	maxSpreadPx = tonumber(maxSpreadPx) or 9

	-- Clears old child instances or UIStrokes on haloFrame
	for _, ch in ipairs(haloFrame:GetChildren()) do
		if not ch:IsA("UICorner") then
			ch:Destroy()
		end
	end

	local glowAsset = Utility.GetGlow9SliceAsset()
	local sliceImg = nil
	if glowAsset ~= nil and glowAsset ~= "" then
		sliceImg = Utility.Create("ImageLabel", {
			Name = "GaussianGlowSlice",
			Parent = haloFrame,
			BackgroundTransparency = 1,
			Image = glowAsset,
			ImageColor3 = glowColor,
			ImageTransparency = 1,
			Position = UDim2.new(0, -10, 0, -10),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect and Rect.new(18, 18, 30, 30) or nil,
			Size = UDim2.new(1, 20, 1, 20),
			ZIndex = haloFrame.ZIndex,
		})
	end

	-- Cumulative outward feather strokes anchored at border expanding 1..maxSpreadPx
	local layers = {}
	local numLayers = math.clamp(maxSpreadPx, 4, 10)
	for i = 1, numLayers do
		local shell = Utility.Create("Frame", {
			Name = "GlowFeather_" .. tostring(i),
			Parent = haloFrame,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Visible = (sliceImg == nil),
			ZIndex = haloFrame.ZIndex,
		})
		Utility.AddCorner(shell, cornerRadius)
		local st = Utility.AddStroke(shell, glowColor, i * (maxSpreadPx / numLayers), 1, Enum.ApplyStrokeMode.Border)
		-- Each thin layer contributes ~8%..12% brightness at inner edge, fading to 0 at perimeter
		local targetTrans = math.clamp(0.87 + (i / numLayers) * 0.09, 0.87, 0.965)
		table.insert(layers, {
			Stroke = st,
			TargetTrans = targetTrans,
		})
	end

	local ctrl = {
		Frame = haloFrame,
		SliceImage = sliceImg,
		Layers = layers,
	}

	function ctrl:SetColor(newColor)
		glowColor = newColor
		if sliceImg then
			sliceImg.ImageColor3 = newColor
		end
		for _, l in ipairs(layers) do
			l.Stroke.Color = newColor
		end
	end

	function ctrl:Fade(intensity, duration)
		local alpha = math.clamp(tonumber(intensity) or 0, 0, 1)
		local dur = tonumber(duration) or 0.14
		haloFrame.BackgroundTransparency = 1
		if sliceImg then
			local targetImgTrans = 1 - (alpha * 0.88)
			if dur <= 0 then
				sliceImg.ImageTransparency = targetImgTrans
			else
				Utility.Tween(sliceImg, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
					ImageTransparency = targetImgTrans,
				})
			end
		else
			for _, l in ipairs(layers) do
				local targetT = 1 - alpha * (1 - l.TargetTrans)
				if dur <= 0 then
					l.Stroke.Transparency = targetT
				else
					Utility.Tween(l.Stroke, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
						Transparency = targetT,
					})
				end
			end
		end
	end

	return ctrl
end

return Utility
