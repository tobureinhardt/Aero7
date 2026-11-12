--!nonstrict
-- Aero7: core/DWM - Windows 7 Desktop Window Manager (DWM) engine: focus z-order, glass reflections, parallax, snap, and transitions.

local Theme = require("core/Theme")
local Utility = require("core/Utility")
local BlurController = require("core/BlurController")

local DWM = {
	Windows = {},
	BlurController = BlurController,
	ActiveWindow = nil,
	GlassChanged = Utility.CreateSignal(),
	RestPositions = setmetatable({}, { __mode = "k" }),
	CustomColors = {
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255),
	},
}

-- Generates Aero Glass specular light reflection layers (7.css _window.scss & Windows 7 DWM standard)
function DWM.BuildAeroGlassLayers(windowFrame)
	-- 1. Tint Layer - Horizontal depth: lighter at borders, deep color in middle (--w7-w-grad)
	local tintLayer = Utility.Create("Frame", {
		Name = "AeroTintLayer",
		Parent = windowFrame,
		BackgroundColor3 = Theme.CurrentGlass.Color,
		BackgroundTransparency = Theme.CurrentGlass.Transparency,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1,
	})
	Utility.AddCorner(tintLayer, 6)

	local tintGrad = Instance.new("UIGradient")
	tintGrad.Name = "TintDepthGradient"
	tintGrad.Rotation = 0
	tintGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.18, Color3.fromRGB(232, 244, 255)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(196, 218, 240)),
		ColorSequenceKeypoint.new(0.82, Color3.fromRGB(224, 238, 252)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(246, 252, 255)),
	})
	tintGrad.Parent = tintLayer

	-- 2. Upper titlebar arch highlight + 135°/225° corner sheen reflections (Upper Corner & Wet Gloss)
	local topGloss = Utility.Create("Frame", {
		Name = "TopTitleGloss",
		Parent = windowFrame,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.52,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 0, 26),
		ZIndex = 2,
	})
	Utility.AddCorner(topGloss, 5)

	local topGlossGrad = Instance.new("UIGradient")
	topGlossGrad.Rotation = 90
	topGlossGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.12),
		NumberSequenceKeypoint.new(0.45, 0.55),
		NumberSequenceKeypoint.new(1.00, 1.00),
	})
	topGlossGrad.Parent = topGloss

	-- Upper-left corner sheen reflection (135deg corner sheen from 7.css --w7-w-glass)
	local cornerSheenLeft = Utility.Create("Frame", {
		Name = "AeroCornerSheenLeft",
		Parent = windowFrame,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.66,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(0, 110, 0, 56),
		ZIndex = 2,
	})
	Utility.AddCorner(cornerSheenLeft, 5)
	local cLeftGrad = Instance.new("UIGradient")
	cLeftGrad.Rotation = 45
	cLeftGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.00),
		NumberSequenceKeypoint.new(0.65, 0.65),
		NumberSequenceKeypoint.new(1.00, 1.00),
	})
	cLeftGrad.Parent = cornerSheenLeft

	-- Upper-right corner sheen reflection (225deg corner sheen from 7.css --w7-w-glass)
	local cornerSheenRight = Utility.Create("Frame", {
		Name = "AeroCornerSheenRight",
		Parent = windowFrame,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.70,
		Position = UDim2.new(1, -111, 0, 1),
		Size = UDim2.new(0, 110, 0, 56),
		ZIndex = 2,
	})
	Utility.AddCorner(cornerSheenRight, 5)
	local cRightGrad = Instance.new("UIGradient")
	cRightGrad.Rotation = 135
	cRightGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.00),
		NumberSequenceKeypoint.new(0.65, 0.65),
		NumberSequenceKeypoint.new(1.00, 1.00),
	})
	cRightGrad.Parent = cornerSheenRight

	-- 3. 10 alternating diagonal reflection stripes (Diagonal Specular Reflection Stripes from 7.css --w7-w-glass)
	local sheenLayer = Utility.Create("Frame", {
		Name = "AeroSpecularSheen",
		Parent = windowFrame,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ClipsDescendants = true,
		ZIndex = 2,
	})
	Utility.AddCorner(sheenLayer, 6)

	local sheenGrad = Instance.new("UIGradient")
	sheenGrad.Name = "SpecularStreakGradient"
	sheenGrad.Rotation = 104
	sheenGrad.Offset = Vector2.new(0, 0)
	sheenGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(16, 28, 44)),
		ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.24, Color3.fromRGB(16, 28, 44)),
		ColorSequenceKeypoint.new(0.27, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.34, Color3.fromRGB(16, 28, 44)),
		ColorSequenceKeypoint.new(0.38, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.49, Color3.fromRGB(16, 28, 44)),
		ColorSequenceKeypoint.new(0.60, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.68, Color3.fromRGB(16, 28, 44)),
		ColorSequenceKeypoint.new(0.76, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.84, Color3.fromRGB(16, 28, 44)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 255, 255)),
	})
	sheenGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.90),
		NumberSequenceKeypoint.new(0.10, 0.92),
		NumberSequenceKeypoint.new(0.17, 0.78), -- Light stripe 1
		NumberSequenceKeypoint.new(0.23, 0.90), -- Dark trough 1
		NumberSequenceKeypoint.new(0.27, 0.60), -- Major light stripe 2
		NumberSequenceKeypoint.new(0.33, 0.89), -- Dark trough 2
		NumberSequenceKeypoint.new(0.38, 0.66), -- Light stripe 3
		NumberSequenceKeypoint.new(0.44, 0.82), -- Minor stripe 4
		NumberSequenceKeypoint.new(0.50, 0.91), -- Center dark trough
		NumberSequenceKeypoint.new(0.60, 0.64), -- Broad light stripe 5
		NumberSequenceKeypoint.new(0.68, 0.90), -- Dark trough 3
		NumberSequenceKeypoint.new(0.76, 0.70), -- Light stripe 6
		NumberSequenceKeypoint.new(0.83, 0.91), -- Dark trough 4
		NumberSequenceKeypoint.new(0.90, 0.80), -- Minor stripe 7
		NumberSequenceKeypoint.new(1.00, 0.95),
	})
	sheenGrad.Parent = sheenLayer

	-- 4. Inner rim frost glow (box-shadow: inset 0 0 0 1px #fffa)
	local frostRim = Utility.Create("Frame", {
		Name = "AeroFrostRim",
		Parent = windowFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ZIndex = 2,
	})
	Utility.AddCorner(frostRim, 5)
	local frostStroke = Utility.AddStroke(frostRim, Theme.CurrentGlass.Glow, 1, 0.45, Enum.ApplyStrokeMode.Border)

	-- 5. Smooth drop shadow system (box-shadow: 2px 2px 10px 1px #000000b3):
	-- - On Executor (with getcustomasset): Uses single hollow 9-Slice Gaussian Blur ImageLabel (DWMDropShadowSlice).
	-- - Fallback Pure-UI: Uses 12 cumulative outward strokes anchored at window border (Position = 0,0; Size = 1,0,1,0; Thickness = 1..12; yShift = 0),
	--   eliminating offset jumping or ring artifacts.
	local shadowOuter = Utility.Create("Frame", {
		Name = "DWMDropShadowOuter",
		Parent = windowFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 0,
	})

	local shadowMid = Utility.Create("Frame", {
		Name = "DWMDropShadowMid",
		Parent = windowFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 0,
	})

	local shadowSliceAsset = Utility.GetShadow9SliceAsset()
	local shadowSliceImg = nil
	if shadowSliceAsset ~= nil and shadowSliceAsset ~= "" then
		shadowSliceImg = Utility.Create("ImageLabel", {
			Name = "DWMDropShadowSlice",
			Parent = shadowOuter,
			BackgroundTransparency = 1,
			Image = shadowSliceAsset,
			ImageTransparency = 0.04,
			Position = UDim2.new(0, -16, 0, -16),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect and Rect.new(24, 24, 40, 40) or nil,
			Size = UDim2.new(1, 32, 1, 32),
			ZIndex = 0,
		})
	end

	local ringStrokes = {}
	local totalRings = 12
	for idx = 1, totalRings do
		local t = (idx - 1) / (totalRings - 1)
		-- Each layer expands from 0..idx px outside window border with high transparency (0.94..0.985) for a seamless fade
		local activeTrans = math.clamp(0.938 + (0.048 * t), 0.938, 0.988)
		local inactiveTrans = math.clamp(0.968 + (0.025 * t), 0.968, 0.995)
		local parentLayer = (idx <= 5) and shadowMid or shadowOuter

		local ringFrame = Utility.Create("Frame", {
			Name = "FeatherRing_" .. tostring(idx),
			Parent = parentLayer,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Visible = (shadowSliceImg == nil),
			ZIndex = 0,
		})
		Utility.AddCorner(ringFrame, 8)
		local st = Utility.AddStroke(
			ringFrame,
			Color3.fromRGB(0, 0, 0),
			idx,
			activeTrans,
			Enum.ApplyStrokeMode.Border
		)

		table.insert(ringStrokes, {
			Stroke = st,
			ActiveTrans = activeTrans,
			InactiveTrans = inactiveTrans,
		})
	end

	return {
		TintLayer = tintLayer,
		TopGloss = topGloss,
		SheenLayer = sheenLayer,
		SheenGradient = sheenGrad,
		FrostStroke = frostStroke,
		ShadowOuter = shadowOuter,
		ShadowMid = shadowMid,
		ShadowSlice = shadowSliceImg,
		ShadowRings = ringStrokes,
	}
end

-- Offsets specular sheen reflections (Specular Parallax) when dragging window across screen
function DWM.UpdateSpecularParallax(glassLayers, posX, posY)
	if not glassLayers or not glassLayers.SheenGradient then
		return
	end
	local shiftX = math.clamp(-(posX % 900) / 1800, -0.35, 0.35)
	local shiftY = math.clamp(-(posY % 600) / 1600, -0.25, 0.25)
	glassLayers.SheenGradient.Offset = Vector2.new(shiftX, shiftY)
end

-- Creates Aero Snap glass preview overlay when dragging window to screen edges
function DWM.CreateSnapPreview(screenGui)
	local preview = Utility.Create("Frame", {
		Name = "Win7AeroSnapPreview",
		Parent = screenGui,
		BackgroundColor3 = Color3.fromRGB(165, 215, 255),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 0, 0, 0),
		Visible = false,
		ZIndex = 5,
	})
	Utility.AddCorner(preview, 6)

	local outerStroke = Utility.AddStroke(preview, Color3.fromRGB(255, 255, 255), 2, 1, Enum.ApplyStrokeMode.Border)
	local innerFrame = Utility.Create("Frame", {
		Name = "InnerSnapRim",
		Parent = preview,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
	})
	Utility.AddCorner(innerFrame, 5)
	local innerStroke = Utility.AddStroke(innerFrame, Color3.fromRGB(48, 138, 224), 1, 1, Enum.ApplyStrokeMode.Border)

	local snapController = {
		Frame = preview,
		ActiveZone = nil,
	}

	function snapController:ShowZone(zoneName, targetPos, targetSize, originPos)
		if self.ActiveZone == zoneName and preview.Visible then
			return
		end
		self.ActiveZone = zoneName
		preview.Visible = true
		if originPos then
			preview.Position = originPos
			preview.Size = UDim2.new(0, 120, 0, 80)
		end
		Utility.Tween(preview, 0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
			Position = targetPos,
			Size = targetSize,
			BackgroundTransparency = 0.74,
		})
		Utility.Tween(outerStroke, 0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
			Transparency = 0.15,
		})
		Utility.Tween(innerStroke, 0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
			Transparency = 0.25,
		})
	end

	function snapController:Hide()
		if not preview.Visible then
			return
		end
		self.ActiveZone = nil
		Utility.Tween(preview, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
			BackgroundTransparency = 1,
		})
		Utility.Tween(outerStroke, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
			Transparency = 1,
		})
		Utility.Tween(innerStroke, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
			Transparency = 1,
		})
		task.delay(0.13, function()
			if self.ActiveZone == nil then
				preview.Visible = false
			end
		end)
	end

	return snapController
end

-- Registers window with DWM to manage Focus Z-Order & Active/Inactive glass state
function DWM:RegisterWindow(windowObj)
	table.insert(self.Windows, windowObj)
	self:FocusWindow(windowObj)
end

function DWM:UnregisterWindow(windowObj)
	for i = #self.Windows, 1, -1 do
		if self.Windows[i] == windowObj then
			table.remove(self.Windows, i)
			break
		end
	end
	if self.ActiveWindow == windowObj then
		self.ActiveWindow = self.Windows[#self.Windows]
		if self.ActiveWindow then
			self:FocusWindow(self.ActiveWindow)
		end
	end
end

-- Brings window to foreground (Active) and desaturates background windows (Inactive) per DWM standard
function DWM:FocusWindow(targetWindow)
	if not targetWindow then
		return
	end
	self.ActiveWindow = targetWindow

	-- Reorders window list for DisplayOrder / ZIndex calculation
	for i = #self.Windows, 1, -1 do
		if self.Windows[i] == targetWindow then
			table.remove(self.Windows, i)
			break
		end
	end
	table.insert(self.Windows, targetWindow)

	for idx, win in ipairs(self.Windows) do
		local isFocused = (win == targetWindow)
		if win.ScreenGui then
			win.ScreenGui.DisplayOrder = 100 + idx
		end
		if win._ApplyFocusState then
			win:_ApplyFocusState(isFocused)
		end
	end
end

-- Changes Aero Glass accent color globally or per-window (Windows 7 Personalization)
function DWM:SetGlassColor(color3, transparency, glowColor)
	if type(color3) == "string" and Theme.GlassPresetByName[color3] then
		local preset = Theme.GlassPresetByName[color3]
		Theme.CurrentGlass.Color = preset.Color
		Theme.CurrentGlass.Transparency = transparency or preset.Transparency
		Theme.CurrentGlass.Glow = glowColor or preset.Glow
	else
		Theme.CurrentGlass.Color = color3 or Theme.CurrentGlass.Color
		if transparency ~= nil then
			Theme.CurrentGlass.Transparency = math.clamp(transparency, 0.05, 0.85)
		end
		if glowColor then
			Theme.CurrentGlass.Glow = glowColor
		end
	end

	for _, win in ipairs(self.Windows) do
		if win._RefreshGlassAppearance then
			win:_RefreshGlassAppearance()
		end
	end

	self.GlassChanged:Fire(Theme.CurrentGlass.Color, Theme.CurrentGlass.Transparency, Theme.CurrentGlass.Glow)
end

-- Synchronously fades/reveals entire window (content + border + glass) with Scale/Position for native dwm.exe feel,
-- Synchronously fades/reveals entire window (content + border + glass) with Scale/Position for native dwm.exe feel,
-- preventing abrupt pop-in at the end of transition animations.
local FADE_PROPS = {
	CanvasGroup = { "GroupTransparency" },
	Frame = { "BackgroundTransparency" },
	ScrollingFrame = { "BackgroundTransparency", "ScrollBarImageTransparency" },
	TextLabel = { "BackgroundTransparency", "TextTransparency", "TextStrokeTransparency" },
	TextButton = { "BackgroundTransparency", "TextTransparency", "TextStrokeTransparency" },
	TextBox = { "BackgroundTransparency", "TextTransparency", "TextStrokeTransparency" },
	ImageLabel = { "BackgroundTransparency", "ImageTransparency" },
	ImageButton = { "BackgroundTransparency", "ImageTransparency" },
	UIStroke = { "Transparency" },
}
local fadeSnapshots = setmetatable({}, { __mode = "k" })
local animTokens = setmetatable({}, { __mode = "k" })
local auxTweens = setmetatable({}, { __mode = "k" })

local function nextAnimToken(windowFrame)
	local tok = (animTokens[windowFrame] or 0) + 1
	animTokens[windowFrame] = tok
	local prevAux = auxTweens[windowFrame]
	if prevAux then
		for _, tw in ipairs(prevAux) do
			pcall(function()
				if tw and tw.Cancel then
					tw:Cancel()
				end
			end)
		end
		auxTweens[windowFrame] = nil
	end
	return tok
end

DWM.NextAnimToken = nextAnimToken
DWM.GetAnimToken = function(windowFrame)
	return animTokens[windowFrame] or 0
end

local function collectFadeTargets(windowFrame)
	local list = {}
	local maxTargets = 45 -- Capped at 45 tweens to preserve 60 FPS performance

	local function scanNode(obj)
		if #list >= maxTargets then
			return
		end

		local name = obj.Name or ""
		if name == "GaussianGlowSlice" or name:find("^GlowFeather_") or name:find("GlowHalo$") or name:find("BloomHalo$") then
			return
		end

		local isCanvasGroup = false
		pcall(function()
			isCanvasGroup = obj:IsA("CanvasGroup")
		end)

		local props = FADE_PROPS[obj.ClassName]
		if props then
			local orig = {}
			local any = false
			for _, prop in ipairs(props) do
				local v = obj[prop]
				if type(v) == "number" and v < 1 then
					orig[prop] = v
					any = true
				end
			end
			if any then
				table.insert(list, { Obj = obj, Orig = orig, Tween = nil })
			end
		end

		-- If obj is CanvasGroup, GroupTransparency handles all descendants on GPU,
		-- skipping traversal into CanvasGroup descendants saves CPU and preserves 60 FPS.
		if isCanvasGroup then
			return
		end

		for _, child in ipairs(obj:GetChildren()) do
			if #list >= maxTargets then
				break
			end
			scanNode(child)
		end
	end

	scanNode(windowFrame)
	return list
end

local function restoreFadeTargets(windowFrame)
	local snap = fadeSnapshots[windowFrame]
	if snap then
		-- 1. Cancels all active tweens before restoring baseline values
		for _, t in ipairs(snap) do
			if t.Tween then
				pcall(function()
					if t.Tween.Cancel then
						t.Tween:Cancel()
					end
				end)
				t.Tween = nil
			end
		end
		-- 2. Restores baseline transparency values for all elements
		for _, t in ipairs(snap) do
			if t.Obj and t.Obj.Parent then
				for prop, v in pairs(t.Orig) do
					t.Obj[prop] = v
				end
			end
		end
		fadeSnapshots[windowFrame] = nil
	end
end

-- Smoothly fades out window to fully transparent (used on Close)
function DWM.FadeOut(windowFrame, duration)
	restoreFadeTargets(windowFrame)
	local list = collectFadeTargets(windowFrame)
	fadeSnapshots[windowFrame] = list
	for _, t in ipairs(list) do
		local goal = {}
		for prop in pairs(t.Orig) do
			goal[prop] = 1
		end
		t.Tween = Utility.Tween(t.Obj, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In, goal)
	end
end

-- Smoothly fades in window from transparent to baseline opacity (used on Open)
function DWM.FadeIn(windowFrame, duration)
	restoreFadeTargets(windowFrame)
	local list = collectFadeTargets(windowFrame)
	fadeSnapshots[windowFrame] = list
	for _, t in ipairs(list) do
		local goal = {}
		for prop, v in pairs(t.Orig) do
			t.Obj[prop] = 1
			goal[prop] = v
		end
		t.Tween = Utility.Tween(t.Obj, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, goal)
	end
	task.delay((duration or 0.17) + 0.03, function()
		if fadeSnapshots[windowFrame] == list then
			restoreFadeTargets(windowFrame)
		end
	end)
end

DWM.RestoreFade = restoreFadeTargets

function DWM.CancelAnimations(windowFrame, uiScale)
	nextAnimToken(windowFrame)
	restoreFadeTargets(windowFrame)
	if uiScale then
		uiScale.Scale = 1.0
	end
end

-- Standard Windows 7 DWM window transition (dwm.exe Window Open / Close Transition):
-- Subtle zoom from center 93% -> 100% synchronized with 170ms FadeIn (no Y offset shift)
function DWM.AnimateOpen(windowFrame, uiScale, glassLayers)
	local tok = nextAnimToken(windowFrame)
	windowFrame.Visible = true
	local targetPos = DWM.RestPositions[windowFrame] or windowFrame.Position
	DWM.RestPositions[windowFrame] = targetPos
	windowFrame.Position = targetPos

	DWM.FadeIn(windowFrame, 0.17)

	local extra = {}
	if uiScale then
		uiScale.Scale = 0.93
		local twScale = Utility.Tween(uiScale, 0.17, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
			Scale = 1.0,
		})
		if twScale then
			table.insert(extra, twScale)
		end
	end

	if glassLayers and glassLayers.SheenGradient then
		glassLayers.SheenGradient.Offset = Vector2.new(-0.14, -0.08)
		local twSheen = Utility.Tween(glassLayers.SheenGradient, 0.22, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
			Offset = Vector2.new(0, 0),
		})
		if twSheen then
			table.insert(extra, twSheen)
		end
	end
	auxTweens[windowFrame] = extra

	task.delay(0.20, function()
		if animTokens[windowFrame] == tok and uiScale then
			uiScale.Scale = 1.0
		end
	end)
end

-- Standard Windows 7 DWM window close transition: zoom out to 93% synchronized with 150ms FadeOut
function DWM.AnimateClose(windowFrame, uiScale, onComplete, glassLayers)
	local tok = nextAnimToken(windowFrame)
	local restPos = windowFrame.Position
	DWM.RestPositions[windowFrame] = restPos

	DWM.FadeOut(windowFrame, 0.15)

	local extra = {}
	if uiScale then
		local twScale = Utility.Tween(uiScale, 0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.In, {
			Scale = 0.93,
		})
		if twScale then
			table.insert(extra, twScale)
		end
	end

	if glassLayers and glassLayers.SheenGradient then
		local twSheen = Utility.Tween(glassLayers.SheenGradient, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {
			Offset = Vector2.new(0.14, 0.08),
		})
		if twSheen then
			table.insert(extra, twSheen)
		end
	end
	auxTweens[windowFrame] = extra

	task.delay(0.17, function()
		if animTokens[windowFrame] ~= tok then
			return
		end
		windowFrame.Visible = false
		DWM.RestoreFade(windowFrame)
		windowFrame.Position = restPos
		if uiScale then
			uiScale.Scale = 1.0
		end
		if onComplete then
			onComplete()
		end
	end)
end

function DWM:SetBlurIntensity(intensity)
	BlurController.SetIntensity(intensity)
end

function DWM:SetBlurEnabled(enabled)
	BlurController.SetEnabled(enabled)
end

return DWM
