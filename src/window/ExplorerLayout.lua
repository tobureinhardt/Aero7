--!nonstrict
-- Aero7: window/ExplorerLayout - Standard Windows 7 Explorer / Control Panel layout with jewel buttons, breadcrumbs, search, sidebar, and client pages.

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local NavSprites = require("core/NavSprites")
local Scrollbar = require("components/Scrollbar")
local MenuBar = require("components/MenuBar")

local ExplorerLayout = {}
ExplorerLayout.__index = ExplorerLayout

-- Address bar metrics
local CRUMB_PAD = 6 -- horizontal padding inside each breadcrumb cell
local CRUMB_ARROW_W = 14 -- width of the arrow cell that follows each breadcrumb
local CRUMB_ELLIPSIS_W = 26
local ADDR_RIGHT_W = 44 -- reserved on the right of the address bar for [Refresh/Go/Stop][Dropdown]

--------------------------------------------------------------------------------
-- Code-drawn glyphs (no rbxassetid / SVG): bars, triangles and arcs built from Frames
--------------------------------------------------------------------------------

-- Centered bar: (cx, cy) are offsets from the holder center
local function mkBar(parent, name, cx, cy, w, h, rot, color, z, round)
	local f = Utility.Create("Frame", {
		Name = name,
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		Position = UDim2.new(0.5, cx, 0.5, cy),
		Size = UDim2.new(0, w, 0, h),
		Rotation = rot or 0,
		ZIndex = z,
	})
	if round then
		Utility.AddCorner(f, 1)
	end
	return f
end

-- Filled triangle pointing +X before rotation (rot in degrees, clockwise). Built from 1px-ish columns.
local function mkTriangle(parent, name, cx, cy, length, base, rot, color, z)
	local holder = Utility.Create("Frame", {
		Name = name,
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, cx, 0.5, cy),
		Size = UDim2.new(0, length, 0, base),
		Rotation = rot or 0,
		ZIndex = z,
	})
	local cols = math.max(2, math.floor(length + 0.5))
	local colW = length / cols
	for i = 0, cols - 1 do
		Utility.Create("Frame", {
			Name = "TriCol",
			Parent = holder,
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = color,
			Position = UDim2.new(0, i * colW, 0.5, 0),
			Size = UDim2.new(0, colW + 0.6, 0, base * (1 - i / cols)),
			ZIndex = z,
		})
	end
	return holder
end

local function mkGlyphHolder(parent, name, size, z)
	return Utility.Create("Frame", {
		Name = name,
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, size, 0, size),
		ZIndex = z,
	})
end

-- SVG-sourced glyphs (assets/icons) cut from the sprite sheet; nil when the executor lacks getcustomasset
local function spriteGlyph(parent, name, cell, z)
	local sheet = NavSprites.GetIconSheetAsset()
	local offset = NavSprites.Icons[cell]
	if not sheet or not offset then
		return nil
	end
	local px = NavSprites.ICON_LOGICAL
	return Utility.Create("ImageLabel", {
		Name = name,
		Parent = parent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = sheet,
		ImageRectOffset = offset,
		ImageRectSize = Vector2.new(NavSprites.ICON_CELL, NavSprites.ICON_CELL),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, px, 0, px),
		ZIndex = z,
	})
end

-- Windows 7 "Go" magnifier (Instant Search): glass lens + handle
local function buildSearchGlyph(parent, z)
	local sprite = spriteGlyph(parent, "SearchMagnifier", "Search", z)
	if sprite then
		return sprite
	end
	local holder = mkGlyphHolder(parent, "SearchMagnifier", 16, z)
	mkBar(holder, "Handle", 4.4, 4.4, 6.5, 2.8, 45, Color3.fromRGB(34, 82, 148), z + 1, true)
	mkBar(holder, "HandleShine", 4.1, 3.8, 4.5, 1, 45, Color3.fromRGB(128, 184, 236), z + 2, false)
	local lens = Utility.Create("Frame", {
		Name = "Lens",
		Parent = holder,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(214, 238, 254),
		Position = UDim2.new(0.5, -1.8, 0.5, -1.8),
		Size = UDim2.new(0, 8, 0, 8),
		ZIndex = z + 3,
	})
	Utility.AddCorner(lens, 4)
	local lensGrad = Instance.new("UIGradient")
	lensGrad.Rotation = 90
	lensGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(240, 250, 255)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(122, 188, 244)),
	})
	lensGrad.Parent = lens
	Utility.AddStroke(lens, Color3.fromRGB(38, 94, 168), 1.5, 0, Enum.ApplyStrokeMode.Border)
	local glint = Utility.Create("Frame", {
		Name = "LensGlint",
		Parent = lens,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.2,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(0, 3, 0, 2),
		ZIndex = z + 4,
	})
	Utility.AddCorner(glint, 2)
	return holder
end

-- Polyline arc: angles in degrees, 0 = +X, increasing clockwise on screen
local function mkArc(parent, name, radius, a0, a1, thick, color, z)
	local steps = 5
	for i = 0, steps - 1 do
		local t0 = math.rad(a0 + (a1 - a0) * i / steps)
		local t1 = math.rad(a0 + (a1 - a0) * (i + 1) / steps)
		local x0, y0 = radius * math.cos(t0), radius * math.sin(t0)
		local x1, y1 = radius * math.cos(t1), radius * math.sin(t1)
		local len = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2) + 1
		mkBar(parent, name, (x0 + x1) / 2, (y0 + y1) / 2, len, thick, math.deg(math.atan2(y1 - y0, x1 - x0)), color, z, false)
	end
end

-- Arrow head sitting at the clockwise end of an arc
local function mkArcHead(parent, name, radius, angle, color, z)
	local t = math.rad(angle)
	local ex, ey = radius * math.cos(t), radius * math.sin(t)
	local tx, ty = -math.sin(t), math.cos(t)
	mkTriangle(parent, name, ex + tx * 1.0, ey + ty * 1.0, 4, 6, math.deg(math.atan2(ty, tx)), color, z)
end

-- Refresh: two circular arrows (green top, blue bottom)
local function buildRefreshGlyph(parent, z)
	local sprite = spriteGlyph(parent, "RefreshGlyph", "Refresh", z)
	if sprite then
		return sprite
	end
	local holder = mkGlyphHolder(parent, "RefreshGlyph", 16, z)
	local r = 4.6
	local green = Color3.fromRGB(48, 160, 72)
	local blue = Color3.fromRGB(36, 104, 196)
	mkArc(holder, "ArcTop", r, 198, 330, 2.2, green, z + 1)
	mkArcHead(holder, "HeadTop", r, 330, green, z + 2)
	mkArc(holder, "ArcBottom", r, 18, 150, 2.2, blue, z + 1)
	mkArcHead(holder, "HeadBottom", r, 150, blue, z + 2)
	return holder
end

-- Go: blue right arrow (shown while the address text is being edited)
local function buildGoGlyph(parent, z)
	local sprite = spriteGlyph(parent, "GoGlyph", "Go", z)
	if sprite then
		return sprite
	end
	local holder = mkGlyphHolder(parent, "GoGlyph", 16, z)
	local main = Color3.fromRGB(40, 112, 204)
	mkBar(holder, "Shaft", -1.6, 0, 7, 3, 0, main, z + 1, false)
	mkBar(holder, "ShaftShine", -1.6, -0.9, 7, 1, 0, Color3.fromRGB(136, 190, 244), z + 2, false)
	mkTriangle(holder, "Head", 3.4, 0, 5.5, 9, 0, main, z + 1)
	return holder
end

-- Stop: red cross (shown while loading)
local function buildStopGlyph(parent, z)
	local sprite = spriteGlyph(parent, "StopGlyph", "Stop", z)
	if sprite then
		return sprite
	end
	local holder = mkGlyphHolder(parent, "StopGlyph", 16, z)
	for _, rot in ipairs({ 45, -45 }) do
		mkBar(holder, "StopShadow", 0, 0.7, 11, 2.8, rot, Color3.fromRGB(120, 22, 18), z + 1, true)
	end
	for _, rot in ipairs({ 45, -45 }) do
		mkBar(holder, "StopBar", 0, 0, 11, 2.6, rot, Color3.fromRGB(214, 56, 44), z + 2, true)
	end
	return holder
end

-- Dropdown: small solid down-pointing triangle
local function buildDropGlyph(parent, z)
	local sprite = spriteGlyph(parent, "DropGlyph", "Dropdown", z)
	if sprite then
		return sprite
	end
	local holder = mkGlyphHolder(parent, "DropGlyph", 12, z)
	mkTriangle(holder, "DropTri", 0, 0, 3.6, 7, 90, Color3.fromRGB(58, 68, 84), z + 1)
	return holder
end

-- Win7 "hot" button behaviour for flat toolbar-style buttons (hover = pale blue + border, pressed = deeper blue)
local function bindFlatButton(btn)
	Utility.AddCorner(btn, 2)
	local stroke = Utility.AddStroke(btn, Theme.Colors.SelectionBorder, 1, 1, Enum.ApplyStrokeMode.Border)
	local hovered, down = false, false
	local function refresh()
		if down then
			btn.BackgroundColor3 = Color3.fromRGB(196, 222, 248)
			btn.BackgroundTransparency = 0
			stroke.Transparency = 0
		elseif hovered then
			btn.BackgroundColor3 = Color3.fromRGB(234, 246, 253)
			btn.BackgroundTransparency = 0.1
			stroke.Transparency = 0.2
		else
			btn.BackgroundTransparency = 1
			stroke.Transparency = 1
		end
	end
	btn.MouseEnter:Connect(function()
		hovered = true
		refresh()
	end)
	btn.MouseLeave:Connect(function()
		hovered = false
		down = false
		refresh()
	end)
	btn.MouseButton1Down:Connect(function()
		down = true
		refresh()
	end)
	btn.MouseButton1Up:Connect(function()
		down = false
		refresh()
	end)
	refresh()
	return refresh
end

-- Measures text width for popup sizing (custom font face when loaded, else legacy font, else estimate)
local function measureText(text, size, variant)
	text = tostring(text or "")
	local width
	pcall(function()
		local ts = game:GetService("TextService")
		local face = Theme.FontFaces and (Theme.FontFaces[variant] or Theme.FontFaces.Regular)
		if face then
			local params = Instance.new("GetTextBoundsParams")
			params.Text = text
			params.Font = face
			params.Size = size
			params.Width = 10000
			width = ts:GetTextBoundsAsync(params).X
		else
			width = ts:GetTextSize(text, size, Theme.Fonts[variant] or Theme.Fonts.Regular, Vector2.new(10000, 10000)).X
		end
	end)
	if type(width) ~= "number" then
		width = #text * size * 0.56
	end
	return width + 4
end

function ExplorerLayout.new(aeroWindow, options, componentFactory)
	options = options or {}
	local self = setmetatable({}, ExplorerLayout)

	self.AeroWindow = aeroWindow
	self.ComponentFactory = componentFactory
	self.Root = aeroWindow.ClientOuterFrame
	self.Tabs = {}
	self.Categories = {}
	self.ActiveTab = nil

	-- Icon for Hierarchy bar (Address Bar) and default tab icon
	self.CustomHierarchyIcon = options.HierarchyIcon or options.AddressIcon
	self.HierarchyIcon = self.CustomHierarchyIcon or options.Icon or "ControlPanel"
	self.DefaultTabIcon = options.DefaultTabIcon or options.TabIcon or options.Icon or "ControlPanel"
	self.HierarchyExpanded = false

	-- Back / Forward navigation history stack
	self.History = {}
	self.HistoryIndex = 0
	self._NavigatingHistory = false

	-- Address bar state: "idle" (shows Refresh) | "editing" (shows Go) | "loading" (shows Stop)
	self.AddressState = "idle"
	self._LoadToken = 0
	self.OnRefresh = options.OnRefresh -- function(tab, layout) invoked by the Refresh button
	self.OnStop = options.OnStop -- function(tab, layout) invoked when Stop cancels a refresh
	self.OnNavigate = options.OnNavigate -- function(tab, layout) invoked whenever the active tab changes

	self:_BuildChrome(options)
	return self
end

function ExplorerLayout:_BuildChrome(options)
	local root = self.Root
	root.BackgroundColor3 = Theme.Colors.ExplorerClientBg
	root.BackgroundTransparency = 1

	-- 1. Upper Navigation Bar (Height: 34px, transparent so it floats directly on Aero Glass)
	local navBar = Utility.Create("Frame", {
		Name = "ExplorerNavigationBar",
		Parent = root,
		BackgroundColor3 = Color3.fromRGB(218, 232, 248),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 34),
		ZIndex = 6,
	})
	if self.AeroWindow and self.AeroWindow.BindDragHandle then
		self.AeroWindow:BindDragHandle(navBar)
	end

	-- Jewel Orbs Back / Forward cluster + history dropdown (ExplorerFrame.dll)
	-- Transparent cluster container without pill background
	-- HD sprite sheet (orbs rendered from vector art + glass frame); nil without getcustomasset -> pure-UI fallback below
	local navSheetAsset = NavSprites.GetSheetAsset()

	local navOrbHousing = Utility.Create("Frame", {
		Name = "BackForwardHousing",
		Parent = navBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0, 2),
		Size = UDim2.new(0, 70, 0, navSheetAsset and NavSprites.FRAME_H or 29),
		ZIndex = 7,
	})

	-- 3D Concave Waist bridge between Back & Forward buttons (X = 22..35)
	local concaveBridge = Utility.Create("Frame", {
		Name = "ConcaveBridge3D",
		Parent = navOrbHousing,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.28,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 22, 0.5, -7),
		Size = UDim2.new(0, 13, 0, 14),
		ZIndex = 7,
	})
	-- Disable outer stroke border (Transparency = 1) to avoid lines cutting through orbs
	local bridgeOuterStroke = Utility.AddStroke(concaveBridge, Color3.fromRGB(255, 255, 255), 1, 1, Enum.ApplyStrokeMode.Border)
	local bridgeStrokeGrad = Instance.new("UIGradient")
	bridgeStrokeGrad.Rotation = 90
	bridgeStrokeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(10, 24, 46)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(32, 62, 102)),
		ColorSequenceKeypoint.new(0.65, Color3.fromRGB(120, 168, 214)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 255, 255)),
	})
	bridgeStrokeGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 0.12),
		NumberSequenceKeypoint.new(0.50, 0.85),
		NumberSequenceKeypoint.new(1.00, 0.08),
	})
	bridgeStrokeGrad.Parent = bridgeOuterStroke

	local bridgeGrad = Instance.new("UIGradient")
	bridgeGrad.Rotation = 0
	bridgeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(96, 144, 192)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(24, 54, 96)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(96, 144, 192)),
	})
	bridgeGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1.00),
		NumberSequenceKeypoint.new(0.28, 0.35),
		NumberSequenceKeypoint.new(0.50, 0.15),
		NumberSequenceKeypoint.new(0.72, 0.35),
		NumberSequenceKeypoint.new(1.00, 1.00),
	})
	bridgeGrad.Parent = concaveBridge

	-- Top concave dark groove between orbs (fading to 1.0 at lateral edges)
	local bridgeTopLip = Utility.Create("Frame", {
		Name = "BridgeTopInnerShadow",
		Parent = concaveBridge,
		BackgroundColor3 = Color3.fromRGB(8, 20, 38),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 7,
	})
	local topLipGrad = Instance.new("UIGradient")
	topLipGrad.Rotation = 0
	topLipGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1.00),
		NumberSequenceKeypoint.new(0.30, 0.35),
		NumberSequenceKeypoint.new(0.50, 0.12),
		NumberSequenceKeypoint.new(0.70, 0.35),
		NumberSequenceKeypoint.new(1.00, 1.00),
	})
	topLipGrad.Parent = bridgeTopLip

	-- 3D specular highlight along bottom ridge between orbs (fading to 1.0 at edges)
	local housingBottomRim = Utility.Create("Frame", {
		Name = "HousingBottomRimHighlight",
		Parent = concaveBridge,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 7,
	})
	local rimStroke = Utility.AddStroke(housingBottomRim, Color3.fromRGB(255, 255, 255), 1, 1, Enum.ApplyStrokeMode.Border)
	local rimGrad = Instance.new("UIGradient")
	rimGrad.Rotation = 0
	rimGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(180, 220, 255)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(180, 220, 255)),
	})
	rimGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1.00),
		NumberSequenceKeypoint.new(0.30, 0.35),
		NumberSequenceKeypoint.new(0.50, 0.08),
		NumberSequenceKeypoint.new(0.70, 0.35),
		NumberSequenceKeypoint.new(1.00, 1.00),
	})
	rimGrad.Parent = housingBottomRim

	-- Glass frame beneath both orbs (ExplorerFrame "Frame" bitmap). Replaces the UI-built bridge when the sheet is available.
	if navSheetAsset then
		concaveBridge.Visible = false
		Utility.Create("ImageLabel", {
			Name = "BackForwardFrame",
			Parent = navOrbHousing,
			BackgroundTransparency = 1,
			Image = navSheetAsset,
			ImageRectOffset = NavSprites.Frame.Offset,
			ImageRectSize = NavSprites.Frame.Size,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0, NavSprites.FRAME_W, 0, NavSprites.FRAME_H),
			ZIndex = 7,
		})
	end

	local function createNavOrb(name, xPos, sizePx, arrowDirection)
		-- Socket bevel kept transparent to avoid extraneous rings around orbs
		local orbSocket = Utility.Create("Frame", {
			Name = name .. "SocketBevel",
			Parent = navOrbHousing,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, xPos - 1, 0.5, -math.floor(sizePx / 2) - 1),
			Size = UDim2.new(0, sizePx + 2, 0, sizePx + 2),
			ZIndex = 7,
		})
		Utility.AddCorner(orbSocket, math.floor((sizePx + 2) / 2))
		local socketFillGrad = Instance.new("UIGradient")
		socketFillGrad.Rotation = 90
		socketFillGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(14, 32, 58)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(44, 82, 126)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(204, 234, 255)),
		})
		socketFillGrad.Parent = orbSocket

		local socketStroke = Utility.AddStroke(orbSocket, Color3.fromRGB(255, 255, 255), 1, 1, Enum.ApplyStrokeMode.Border)
		local socketGrad = Instance.new("UIGradient")
		socketGrad.Rotation = 90
		socketGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(10, 24, 46)),
			ColorSequenceKeypoint.new(0.48, Color3.fromRGB(36, 70, 112)),
			ColorSequenceKeypoint.new(0.62, Color3.fromRGB(132, 178, 224)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 255, 255)),
		})
		socketGrad.Parent = socketStroke

		-- Cyan orb bloom halo softly illuminating button perimeter on hover/active
		local bloomHalo = Utility.Create("Frame", {
			Name = name .. "OrbBloomHalo",
			Parent = navOrbHousing,
			BackgroundColor3 = Color3.fromRGB(93, 196, 240),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, xPos, 0.5, -math.floor(sizePx / 2)),
			Size = UDim2.new(0, sizePx, 0, sizePx),
			ZIndex = 7,
		})
		local orbGlowCtrl = Utility.AttachGaussianGlow(bloomHalo, Color3.fromRGB(93, 196, 240), math.floor(sizePx / 2), 6)

		local orb = Utility.Create("TextButton", {
			Name = name .. "OrbButton",
			Parent = navOrbHousing,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0, xPos, 0.5, -math.floor(sizePx / 2)),
			Size = UDim2.new(0, sizePx, 0, sizePx),
			AutoButtonColor = false,
			Text = "",
			ZIndex = 8,
		})
		Utility.AddCorner(orb, math.floor(sizePx / 2))
		local orbStroke = Utility.AddStroke(orb, Color3.fromRGB(36, 78, 128), 1, 0.05, Enum.ApplyStrokeMode.Border)

		-- Thin inner glass ring inside orb face
		local innerRing = Utility.Create("Frame", {
			Name = "OrbInnerGlassRing",
			Parent = orb,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2),
			ZIndex = 9,
		})
		Utility.AddCorner(innerRing, math.floor((sizePx - 2) / 2))
		local innerRingStroke = Utility.AddStroke(innerRing, Color3.fromRGB(230, 248, 255), 1, 0.22, Enum.ApplyStrokeMode.Border)

		local orbGrad = Instance.new("UIGradient")
		orbGrad.Rotation = 90
		orbGrad.Parent = orb

		-- Upper specular lens dome
		local topShine = Utility.Create("Frame", {
			Name = "OrbTopGloss",
			Parent = orb,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.18,
			Position = UDim2.new(0.10, 0, 0.04, 0),
			Size = UDim2.new(0.80, 0, 0.45, 0),
			ZIndex = 9,
		})
		Utility.AddCorner(topShine, math.floor(sizePx / 2))
		local topShineGrad = Instance.new("UIGradient")
		topShineGrad.Rotation = 90
		topShineGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.0, 0.06),
			NumberSequenceKeypoint.new(0.75, 0.55),
			NumberSequenceKeypoint.new(1.0, 0.95),
		})
		topShineGrad.Parent = topShine

		-- Cyan bounce glow at orb base
		local bottomBounce = Utility.Create("Frame", {
			Name = "OrbBottomCyanBounce",
			Parent = orb,
			BackgroundColor3 = Color3.fromRGB(132, 236, 255),
			BackgroundTransparency = 0.52,
			Position = UDim2.new(0.16, 0, 0.66, 0),
			Size = UDim2.new(0.68, 0, 0.26, 0),
			ZIndex = 9,
		})
		Utility.AddCorner(bottomBounce, 6)

		-- Sharp Windows 7 vector arrow
		local arrowGlyph = Utility.CreateVectorArrow(
			orb,
			arrowDirection,
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(24, 62, 112),
			10
		)

		local ctrl = { Enabled = false, Button = orb, Arrow = arrowGlyph }
		local hovered = false
		local pressed = false

		local function refreshOrb()
			if not ctrl.Enabled then
				-- Disabled state (ExplorerFrame.dll Bitmap 579): translucent silver-white glass blending with Aero
				orb.BackgroundTransparency = 0.46
				orbGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(238, 245, 252)),
					ColorSequenceKeypoint.new(0.49, Color3.fromRGB(208, 222, 238)),
					ColorSequenceKeypoint.new(0.51, Color3.fromRGB(184, 202, 224)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(212, 226, 242)),
				})
				orbStroke.Color = Color3.fromRGB(96, 120, 148)
				orbStroke.Transparency = 0.32
				innerRingStroke.Color = Color3.fromRGB(255, 255, 255)
				innerRingStroke.Transparency = 0.52
				topShine.BackgroundTransparency = 0.55
				bottomBounce.BackgroundTransparency = 0.90
				bloomHalo.BackgroundTransparency = 1
				orbGlowCtrl:Fade(0, 0.12)
				arrowGlyph:SetColor(
					Color3.fromRGB(250, 252, 255),
					Color3.fromRGB(92, 116, 144),
					0.42
				)
			elseif pressed then
				-- Pressed state (Bitmap 580/581): deeply depressed Aero blue orb
				orb.BackgroundTransparency = 0
				orbGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(142, 198, 240)),
					ColorSequenceKeypoint.new(0.49, Color3.fromRGB(68, 146, 212)),
					ColorSequenceKeypoint.new(0.51, Color3.fromRGB(24, 92, 168)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(76, 188, 236)),
				})
				orbStroke.Color = Color3.fromRGB(22, 62, 112)
				orbStroke.Transparency = 0
				innerRingStroke.Color = Color3.fromRGB(168, 226, 255)
				innerRingStroke.Transparency = 0.28
				topShine.BackgroundTransparency = 0.36
				bottomBounce.BackgroundTransparency = 0.42
				bloomHalo.BackgroundTransparency = 1
				orbGlowCtrl:Fade(0.65, 0.10)
				arrowGlyph:SetColor(
					Color3.fromRGB(242, 250, 255),
					Color3.fromRGB(14, 48, 96),
					0
				)
			elseif hovered then
				-- Hover state (Bitmap 578): luminous ice-blue orb with cyan bloom halo
				orb.BackgroundTransparency = 0
				orbGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(228, 248, 255)),
					ColorSequenceKeypoint.new(0.49, Color3.fromRGB(132, 206, 252)),
					ColorSequenceKeypoint.new(0.51, Color3.fromRGB(48, 138, 222)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(136, 244, 255)),
				})
				orbStroke.Color = Color3.fromRGB(32, 98, 178)
				orbStroke.Transparency = 0
				innerRingStroke.Color = Color3.fromRGB(244, 254, 255)
				innerRingStroke.Transparency = 0.08
				topShine.BackgroundTransparency = 0.10
				bottomBounce.BackgroundTransparency = 0.25
				bloomHalo.BackgroundTransparency = 1
				orbGlowCtrl:Fade(1, 0.12)
				arrowGlyph:SetColor(
					Color3.fromRGB(255, 255, 255),
					Color3.fromRGB(18, 66, 128),
					0
				)
			else
				-- Normal state (Enabled - Bitmap 577): crisp light-blue orb from Windows 7 Explorer
				-- Upper ice-blue gradient (#D4EEFC -> #78BCEE), Aero blue horizon (#2E82CA), glowing cyan bottom (#72DCFA)
				orb.BackgroundTransparency = 0
				orbGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(212, 238, 252)),
					ColorSequenceKeypoint.new(0.48, Color3.fromRGB(120, 188, 238)),
					ColorSequenceKeypoint.new(0.52, Color3.fromRGB(46, 130, 202)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(114, 220, 250)),
				})
				orbStroke.Color = Color3.fromRGB(38, 84, 138)
				orbStroke.Transparency = 0.04
				innerRingStroke.Color = Color3.fromRGB(232, 248, 255)
				innerRingStroke.Transparency = 0.18
				topShine.BackgroundTransparency = 0.16
				bottomBounce.BackgroundTransparency = 0.42
				bloomHalo.BackgroundTransparency = 1
				orbGlowCtrl:Fade(0, 0.15)
				arrowGlyph:SetColor(
					Color3.fromRGB(255, 255, 255),
					Color3.fromRGB(22, 64, 118),
					0
				)
			end
		end

		orb.MouseEnter:Connect(function()
			hovered = true
			refreshOrb()
		end)
		orb.MouseLeave:Connect(function()
			hovered = false
			pressed = false
			refreshOrb()
		end)
		orb.MouseButton1Down:Connect(function()
			if ctrl.Enabled then
				pressed = true
				refreshOrb()
			end
		end)
		orb.MouseButton1Up:Connect(function()
			pressed = false
			refreshOrb()
		end)

		function ctrl:SetEnabled(en)
			ctrl.Enabled = en == true
			refreshOrb()
		end

		refreshOrb()
		return ctrl
	end

	-- Sprite-based orb: Default / Hover / Pressed / Disabled cells cut from the HD sheet
	local function createSpriteNavOrb(name, xPos, cells)
		local orb = Utility.Create("ImageButton", {
			Name = name .. "OrbButton",
			Parent = navOrbHousing,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Image = navSheetAsset,
			ImageRectOffset = cells.Disabled,
			ImageRectSize = Vector2.new(NavSprites.CELL_W, NavSprites.CELL_H),
			Position = UDim2.new(0, xPos, 0.5, -math.floor(NavSprites.ORB_H / 2)),
			Size = UDim2.new(0, NavSprites.ORB_W, 0, NavSprites.ORB_H),
			ZIndex = 8,
		})

		local ctrl = { Enabled = false, Button = orb }
		local hovered = false
		local pressed = false

		local function refreshOrb()
			if not ctrl.Enabled then
				orb.ImageRectOffset = cells.Disabled
			elseif pressed then
				orb.ImageRectOffset = cells.Pressed
			elseif hovered then
				orb.ImageRectOffset = cells.Hover
			else
				orb.ImageRectOffset = cells.Default
			end
		end

		orb.MouseEnter:Connect(function()
			hovered = true
			refreshOrb()
		end)
		orb.MouseLeave:Connect(function()
			hovered = false
			pressed = false
			refreshOrb()
		end)
		orb.MouseButton1Down:Connect(function()
			if ctrl.Enabled then
				pressed = true
				refreshOrb()
			end
		end)
		orb.MouseButton1Up:Connect(function()
			pressed = false
			refreshOrb()
		end)

		function ctrl:SetEnabled(en)
			ctrl.Enabled = en == true
			refreshOrb()
		end

		refreshOrb()
		return ctrl
	end

	if navSheetAsset then
		-- 25x26 orbs from the supplied SVG, centered in the 61x30 frame lobes (centers x = 15.5 / 45.5)
		self.BackOrb = createSpriteNavOrb("Back", 3, NavSprites.Cells.Back)
		self.ForwardOrb = createSpriteNavOrb("Forward", 33, NavSprites.Cells.Forward)
	else
		-- Back (27x27px) and Forward (25x25px) buttons per Windows 7 ExplorerFrame.dll
		self.BackOrb = createNavOrb("Back", 1, 27, "Left")
		self.ForwardOrb = createNavOrb("Forward", 30, 25, "Right")
	end

	-- Recent pages history chevron at right edge of Back/Forward cluster
	local historyDropBtn = Utility.Create("TextButton", {
		Name = "HistoryDropdownButton",
		Parent = navOrbHousing,
		BackgroundColor3 = Color3.fromRGB(196, 226, 255),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, navSheetAsset and 62 or 56, 0, 2),
		Size = UDim2.new(0, navSheetAsset and 8 or 14, 1, -4),
		AutoButtonColor = false,
		Text = "",
		ZIndex = 9,
	})
	Utility.AddCorner(historyDropBtn, 6)
	local histChevron = Utility.CreateVectorChevron(historyDropBtn, "Down", Color3.fromRGB(238, 246, 255), 10)
	self.HistoryDropButton = historyDropBtn
	self.HistoryChevron = histChevron
	historyDropBtn.MouseEnter:Connect(function()
		if #self.History > 1 then
			historyDropBtn.BackgroundTransparency = 0.45
			histChevron:SetColor(Color3.fromRGB(255, 255, 255))
		end
	end)
	historyDropBtn.MouseLeave:Connect(function()
		historyDropBtn.BackgroundTransparency = 1
		self:_UpdateHistoryButtons()
	end)
	-- Recent pages: lists the Back/Forward stack (newest first); picking an entry jumps straight to it
	historyDropBtn.MouseButton1Click:Connect(function()
		if #self.History < 2 then
			return
		end
		local items = {}
		for i = #self.History, math.max(1, #self.History - 11), -1 do
			local histTab = self.History[i]
			table.insert(items, {
				Text = tostring(histTab.Title),
				Icon = histTab.Icon,
				Current = (i == self.HistoryIndex),
				Callback = function()
					self:_GoToHistory(i)
				end,
			})
		end
		self:_ShowDropdown(navOrbHousing, items, { MinWidth = 170 })
	end)

	self.BackOrb.Button.MouseButton1Click:Connect(function()
		if self.HistoryIndex > 1 then
			self:_GoToHistory(self.HistoryIndex - 1)
		end
	end)

	self.ForwardOrb.Button.MouseButton1Click:Connect(function()
		if self.HistoryIndex < #self.History then
			self:_GoToHistory(self.HistoryIndex + 1)
		end
	end)

	-- Standard Windows 7 Explorer breadcrumb address bar (translucent white 0.14 on Aero glass, solid on hover/focus)
	local addressBar = Utility.Create("Frame", {
		Name = "AddressBreadcrumbBar",
		Parent = navBar,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.14,
		Position = UDim2.new(0, 78, 0, 5),
		Size = UDim2.new(1, -266, 0, 24),
		ClipsDescendants = true,
		ZIndex = 7,
	})
	Utility.AddCorner(addressBar, 2)
	local addrStroke = Utility.AddStroke(addressBar, Color3.fromRGB(58, 82, 108), 1, 0.18, Enum.ApplyStrokeMode.Border)
	local addrInnerRim = Utility.Create("Frame", {
		Name = "AddressInnerRim",
		Parent = addressBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 7,
	})
	Utility.AddStroke(addrInnerRim, Color3.fromRGB(255, 255, 255), 1, 0.35, Enum.ApplyStrokeMode.Border)
	addressBar.MouseEnter:Connect(function()
		addressBar.BackgroundTransparency = 0.02
		addrStroke.Color = Theme.Colors.EditBorderHover
		addrStroke.Transparency = 0
	end)
	addressBar.MouseLeave:Connect(function()
		addressBar.BackgroundTransparency = 0.14
		addrStroke.Color = Color3.fromRGB(58, 82, 108)
		addrStroke.Transparency = 0.18
	end)
	self.AddressBar = addressBar

	-- 1. Hierarchy bar leading icon (configurable via HierarchyIcon / Icon or default ControlPanel)
	local addrIconBtn = Utility.Create("TextButton", {
		Name = "HierarchyIconButton",
		Parent = addressBar,
		BackgroundColor3 = Color3.fromRGB(234, 246, 253),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(0, 20, 0, 20),
		Text = "",
		ZIndex = 8,
	})
	Utility.AddCorner(addrIconBtn, 2)
	local addrIconStroke = Utility.AddStroke(addrIconBtn, Theme.Colors.SelectionBorder, 1, 1, Enum.ApplyStrokeMode.Border)

	local addrIcon = Utility.Create("ImageLabel", {
		Name = "AddressIcon",
		Parent = addrIconBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 9,
	})
	Assets.BindIcon(addrIcon, self.HierarchyIcon)
	self.AddressIcon = addrIcon

	-- 2. Double-arrow chevron («) pointing towards hierarchy icon per Windows 7 Explorer
	local overflowBtn = Utility.Create("TextButton", {
		Name = "HierarchyOverflowButton",
		Parent = addressBar,
		BackgroundColor3 = Color3.fromRGB(234, 246, 253),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 23, 0, 2),
		Size = UDim2.new(0, 16, 0, 20),
		Text = "",
		ZIndex = 8,
	})
	Utility.AddCorner(overflowBtn, 2)
	local overflowStroke = Utility.AddStroke(overflowBtn, Theme.Colors.SelectionBorder, 1, 1, Enum.ApplyStrokeMode.Border)
	local overflowDoubleChevron = Utility.CreateVectorDoubleChevron(
		overflowBtn,
		"Left",
		Color3.fromRGB(48, 78, 114),
		9
	)
	self.HierarchyOverflowButton = overflowBtn
	self.HierarchyDoubleChevron = overflowDoubleChevron

	local function toggleHierarchyFullView()
		self.HierarchyExpanded = not self.HierarchyExpanded
		self:_UpdateBreadcrumbs(self.ActiveTab)
	end

	addrIconBtn.MouseEnter:Connect(function()
		addrIconBtn.BackgroundTransparency = 0.15
		addrIconStroke.Transparency = 0.2
	end)
	addrIconBtn.MouseLeave:Connect(function()
		addrIconBtn.BackgroundTransparency = 1
		addrIconStroke.Transparency = 1
	end)
	addrIconBtn.MouseButton1Click:Connect(toggleHierarchyFullView)

	overflowBtn.MouseEnter:Connect(function()
		overflowBtn.BackgroundTransparency = 0.15
		overflowStroke.Transparency = 0.2
		overflowDoubleChevron:SetColor(Color3.fromRGB(16, 108, 212))
	end)
	overflowBtn.MouseLeave:Connect(function()
		overflowBtn.BackgroundTransparency = 1
		overflowStroke.Transparency = 1
		overflowDoubleChevron:SetColor(Color3.fromRGB(48, 78, 114))
	end)
	overflowBtn.MouseButton1Click:Connect(toggleHierarchyFullView)

	-- 3. Breadcrumb cells. Every crumb (and the arrow after it) is AutomaticSize.X, so each cell grows/shrinks with its text.
	local breadcrumbContainer = Utility.Create("ScrollingFrame", {
		Name = "BreadcrumbSegments",
		Parent = addressBar,
		Active = false, -- lets clicks on the empty tail fall through to the "edit address" hit area behind
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 40, 0, 1),
		Size = UDim2.new(1, -(40 + ADDR_RIGHT_W), 1, -2),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = Color3.fromRGB(132, 164, 202),
		ClipsDescendants = true,
		ZIndex = 8,
	})
	local bcLayout = Instance.new("UIListLayout")
	bcLayout.FillDirection = Enum.FillDirection.Horizontal
	bcLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	bcLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bcLayout.Padding = UDim.new(0, 1)
	bcLayout.Parent = breadcrumbContainer
	self.BreadcrumbContainer = breadcrumbContainer

	-- Re-fit (collapse to "..." / restore) whenever cell widths or the available width change
	bcLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self:_FitBreadcrumbs()
	end)
	breadcrumbContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_FitBreadcrumbs()
	end)

	-- Empty area of the address bar: clicking it switches to editable path text (like Explorer)
	local addrHitArea = Utility.Create("TextButton", {
		Name = "AddressEditHitArea",
		Parent = addressBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 40, 0, 1),
		Size = UDim2.new(1, -(40 + ADDR_RIGHT_W), 1, -2),
		Text = "",
		ZIndex = 7,
	})
	self.AddressHitArea = addrHitArea
	addrHitArea.MouseButton1Click:Connect(function()
		self:_BeginAddressEdit()
	end)

	-- Editable path box (hidden until the hit area is clicked)
	local addrEdit = Utility.Create("TextBox", {
		Name = "AddressEditBox",
		Parent = addressBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 0, 1),
		Size = UDim2.new(1, -(24 + ADDR_RIGHT_W), 1, -2),
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Font = Theme.Fonts.Regular,
		Text = "",
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = false,
		ZIndex = 10,
	})
	self.AddressEditBox = addrEdit
	self.AddressStroke = addrStroke

	-- Load progress (green fill behind the crumbs, like Explorer while a folder is loading)
	local progressFill = Utility.Create("Frame", {
		Name = "AddressProgressFill",
		Parent = addressBar,
		BackgroundColor3 = Color3.fromRGB(176, 232, 160),
		BackgroundTransparency = 0.35,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(0, 0, 1, -2),
		Visible = false,
		ZIndex = 7,
	})
	local progressGrad = Instance.new("UIGradient")
	progressGrad.Rotation = 90
	progressGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(214, 246, 204)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(120, 210, 104)),
	})
	progressGrad.Parent = progressFill
	self.AddressProgressFill = progressFill

	-- Right edge: [Refresh | Go | Stop] + [Dropdown] (all glyphs are drawn in code)
	local dropBtn = Utility.Create("TextButton", {
		Name = "AddressDropdownButton",
		Parent = addressBar,
		BackgroundColor3 = Color3.fromRGB(234, 246, 253),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -17, 0, 1),
		Size = UDim2.new(0, 16, 1, -2),
		Text = "",
		ZIndex = 9,
	})
	buildDropGlyph(dropBtn, 10)
	bindFlatButton(dropBtn)
	self.AddressDropdownButton = dropBtn

	local refreshBtn = Utility.Create("TextButton", {
		Name = "AddressRefreshButton",
		Parent = addressBar,
		BackgroundColor3 = Color3.fromRGB(234, 246, 253),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -40, 0, 1),
		Size = UDim2.new(0, 22, 1, -2),
		Text = "",
		ZIndex = 9,
	})
	self.AddressActionButton = refreshBtn
	self._GlyphRefresh = buildRefreshGlyph(refreshBtn, 10)
	self._GlyphGo = buildGoGlyph(refreshBtn, 10)
	self._GlyphStop = buildStopGlyph(refreshBtn, 10)
	self._GlyphGo.Visible = false
	self._GlyphStop.Visible = false
	bindFlatButton(refreshBtn)

	-- Recent locations (full paths, newest first)
	dropBtn.MouseButton1Click:Connect(function()
		local items = {}
		local seen = {}
		for i = #self.History, 1, -1 do
			local histTab = self.History[i]
			if not seen[histTab] and #items < 12 then
				seen[histTab] = true
				local labels = {}
				for _, seg in ipairs(self:_GetPathSegments(histTab)) do
					table.insert(labels, seg.Label)
				end
				table.insert(items, {
					Text = table.concat(labels, "\\"),
					Icon = histTab.HierarchyIcon or histTab.Icon,
					Current = (histTab == self.ActiveTab),
					Callback = function()
						if histTab ~= self.ActiveTab then
							self:SelectTab(histTab)
						end
					end,
				})
			end
		end
		self:_ShowDropdown(addressBar, items, {
			MinWidth = addressBar.AbsoluteSize.X,
			OffsetX = 0,
		})
	end)

	-- Action button: Refresh when idle, Go while editing the path, Stop while loading
	refreshBtn.MouseButton1Down:Connect(function()
		if self.AddressState == "editing" then
			self._AddrGoDown = true
		end
	end)
	refreshBtn.MouseButton1Up:Connect(function()
		task.delay(0.1, function()
			self._SwallowActionClick = false
		end)
	end)
	refreshBtn.MouseButton1Click:Connect(function()
		if self._SwallowActionClick then
			self._SwallowActionClick = false
			return
		end
		local st = self.AddressState
		if st == "editing" then
			self:_CommitAddressText(addrEdit.Text)
		elseif st == "loading" then
			self:StopLoading()
		else
			self:Refresh()
		end
	end)

	addrEdit.FocusLost:Connect(function(enterPressed)
		if self.AddressState ~= "editing" then
			return
		end
		if enterPressed or self._AddrGoDown then
			if self._AddrGoDown then
				self._SwallowActionClick = true
			end
			self._AddrGoDown = false
			self:_CommitAddressText(addrEdit.Text)
		else
			self:_EndAddressEdit()
		end
	end)

	-- Instant Search box at right of navigation bar (translucent white 0.14 on Aero glass)
	local searchWrap = Utility.Create("Frame", {
		Name = "InstantSearchBoxWrap",
		Parent = navBar,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.14,
		Position = UDim2.new(1, -182, 0, 5),
		Size = UDim2.new(0, 176, 0, 24),
		ClipsDescendants = true,
		ZIndex = 7,
	})
	Utility.AddCorner(searchWrap, 2)
	local searchStroke = Utility.AddStroke(searchWrap, Color3.fromRGB(58, 82, 108), 1, 0.18, Enum.ApplyStrokeMode.Border)
	local searchInnerRim = Utility.Create("Frame", {
		Name = "SearchInnerRim",
		Parent = searchWrap,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 7,
	})
	Utility.AddStroke(searchInnerRim, Color3.fromRGB(255, 255, 255), 1, 0.35, Enum.ApplyStrokeMode.Border)

	local defaultSearchPlaceholder = "Search " .. tostring(options.Title or "Control Panel")
	local searchPlaceholderLbl = Utility.Create("TextLabel", {
		Name = "SearchPlaceholderLabel",
		Parent = searchWrap,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 7, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Font = Theme.Fonts.Italic,
		Text = defaultSearchPlaceholder,
		TextColor3 = Color3.fromRGB(118, 128, 140),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 8,
	})
	self.SearchPlaceholderLabel = searchPlaceholderLbl

	local searchBox = Utility.Create("TextBox", {
		Name = "SearchInput",
		Parent = searchWrap,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 7, 0, 0),
		Size = UDim2.new(1, -28, 1, 0),
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Font = Theme.Fonts.Regular,
		PlaceholderText = "",
		PlaceholderColor3 = Color3.fromRGB(118, 128, 140),
		Text = "",
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 9,
	})
	self.SearchBox = searchBox

	local searchActionBtn = Utility.Create("TextButton", {
		Name = "SearchActionButton",
		Parent = searchWrap,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -21, 0, 2),
		Size = UDim2.new(0, 19, 0, 20),
		Text = "",
		ZIndex = 9,
	})

	-- Magnifier drawn in code (no asset id); the button gets the Win7 hover/pressed box
	local searchIcon = buildSearchGlyph(searchActionBtn, 10)

	local searchClearGlyph = Utility.Create("Frame", {
		Name = "SearchClearGlyph",
		Parent = searchActionBtn,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ZIndex = 10,
	})
	-- Clear (x): default / hover / pressed sprites from the sheet; falls back to the vector X + flat hover box
	local clearSprite = spriteGlyph(searchClearGlyph, "ClearSprite", "ClearDefault", 11)
	if clearSprite then
		local function setClear(cell)
			clearSprite.ImageRectOffset = NavSprites.Icons[cell]
		end
		searchActionBtn.MouseEnter:Connect(function()
			setClear("ClearHover")
		end)
		searchActionBtn.MouseLeave:Connect(function()
			setClear("ClearDefault")
		end)
		searchActionBtn.MouseButton1Down:Connect(function()
			setClear("ClearPressed")
		end)
		searchActionBtn.MouseButton1Up:Connect(function()
			setClear("ClearHover")
		end)
	else
		Utility.CreateVectorCloseX(searchClearGlyph, Color3.fromRGB(72, 118, 172), Color3.fromRGB(220, 235, 250), 11)
		bindFlatButton(searchActionBtn)
	end

	local isSearchFocused = false
	searchWrap.MouseEnter:Connect(function()
		if not isSearchFocused then
			searchWrap.BackgroundTransparency = 0.02
			searchStroke.Color = Theme.Colors.EditBorderHover
			searchStroke.Transparency = 0
		end
	end)
	searchWrap.MouseLeave:Connect(function()
		if not isSearchFocused then
			searchWrap.BackgroundTransparency = 0.14
			searchStroke.Color = Color3.fromRGB(58, 82, 108)
			searchStroke.Transparency = 0.18
		end
	end)
	searchBox.Focused:Connect(function()
		isSearchFocused = true
		searchWrap.BackgroundTransparency = 0
		searchStroke.Color = Theme.Colors.EditBorderFocused
		searchStroke.Transparency = 0
		searchPlaceholderLbl.Visible = false
	end)
	searchBox.FocusLost:Connect(function()
		isSearchFocused = false
		searchWrap.BackgroundTransparency = 0.14
		searchStroke.Color = Color3.fromRGB(58, 82, 108)
		searchStroke.Transparency = 0.18
		searchPlaceholderLbl.Visible = (searchBox.Text == "")
	end)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local hasQuery = (searchBox.Text ~= "")
		searchPlaceholderLbl.Visible = (not isSearchFocused) and (not hasQuery)
		searchIcon.Visible = not hasQuery
		searchClearGlyph.Visible = hasQuery
		self:ApplySearchFilter(searchBox.Text)
	end)
	searchActionBtn.MouseButton1Click:Connect(function()
		if searchBox.Text ~= "" then
			searchBox.Text = ""
		end
	end)

	-- 2. Explorer Command Bar (Height: 28px)
	local commandBar = Utility.Create("Frame", {
		Name = "ExplorerCommandBar",
		Parent = root,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 0, 34),
		Size = UDim2.new(1, 0, 0, 28),
		ZIndex = 6,
	})
	if self.AeroWindow and self.AeroWindow.BindDragHandle then
		self.AeroWindow:BindDragHandle(commandBar)
	end
	local cmdGrad = Instance.new("UIGradient")
	cmdGrad.Rotation = 90
	cmdGrad.Color = Theme.Gradients.ExplorerCommandBar
	cmdGrad.Parent = commandBar

	Utility.Create("Frame", {
		Name = "CommandBarTopHighlight",
		Parent = commandBar,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 7,
	})
	Utility.Create("Frame", {
		Name = "CommandBarBottomBorder",
		Parent = commandBar,
		BackgroundColor3 = Color3.fromRGB(160, 178, 202),
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 7,
	})

	local cmdList = Utility.Create("Frame", {
		Name = "CommandButtonsHolder",
		Parent = commandBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 2),
		Size = UDim2.new(1, -36, 1, -4),
		ZIndex = 7,
	})
	local cmdLayout = Instance.new("UIListLayout")
	cmdLayout.FillDirection = Enum.FillDirection.Horizontal
	cmdLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	cmdLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cmdLayout.Padding = UDim.new(0, 4)
	cmdLayout.Parent = cmdList
	self.CommandButtonsHolder = cmdList
	self.CommandButtons = {}
	cmdList:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_FitCommandBar()
	end)

	-- Teal circular Help button (?) at right edge of Command Bar
	local helpOrbBtn = Utility.Create("TextButton", {
		Name = "ExplorerHelpOrbButton",
		Parent = commandBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -24, 0.5, -9),
		Size = UDim2.new(0, 18, 0, 18),
		Text = "",
		ZIndex = 8,
	})
	local helpOrbIco = Utility.Create("ImageLabel", {
		Name = "HelpIcon",
		Parent = helpOrbBtn,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 9,
	})
	Assets.BindIcon(helpOrbIco, "Question")

	-- 3. Main body area (Navigation Pane on left + white client area on right)
	local bodyFrame = Utility.Create("Frame", {
		Name = "ExplorerBodySplit",
		Parent = root,
		BackgroundColor3 = Theme.Colors.ExplorerClientBg,
		Position = UDim2.new(0, 0, 0, 62),
		Size = UDim2.new(1, 0, 1, -86),
		ClipsDescendants = true,
		ZIndex = 5,
	})
	self.BodyFrame = bodyFrame

	local baseNavPaneWidth = options.NavPaneWidth or 176
	self.NavPaneWidth = baseNavPaneWidth

	local navPane = Utility.Create("ScrollingFrame", {
		Name = "LeftNavigationPane",
		Parent = bodyFrame,
		BackgroundColor3 = Theme.Colors.ExplorerNavPaneBg,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, baseNavPaneWidth, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(168, 186, 208),
		ZIndex = 6,
	})
	local navPadding = Instance.new("UIPadding")
	navPadding.PaddingTop = UDim.new(0, 6)
	navPadding.PaddingBottom = UDim.new(0, 8)
	navPadding.PaddingLeft = UDim.new(0, 6)
	navPadding.PaddingRight = UDim.new(0, 6)
	navPadding.Parent = navPane

	local navList = Instance.new("UIListLayout")
	navList.SortOrder = Enum.SortOrder.LayoutOrder
	navList.Padding = UDim.new(0, 2)
	navList.Parent = navPane
	self.NavPane = navPane

	-- Vertical separator rule between Navigation Pane and white client area
	local navDivider = Utility.Create("Frame", {
		Name = "NavPaneVerticalDivider",
		Parent = bodyFrame,
		BackgroundColor3 = Theme.Colors.ExplorerNavPaneDivider,
		Position = UDim2.new(0, baseNavPaneWidth, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		ZIndex = 7,
	})
	self.NavDivider = navDivider

	-- Right-side Tab Page container
	local pagesHost = Utility.Create("Frame", {
		Name = "ExplorerPagesHost",
		Parent = bodyFrame,
		BackgroundColor3 = Theme.Colors.ExplorerClientBg,
		Position = UDim2.new(0, baseNavPaneWidth + 1, 0, 0),
		Size = UDim2.new(1, -(baseNavPaneWidth + 1), 1, 0),
		ClipsDescendants = true,
		ZIndex = 6,
	})
	self.PagesHost = pagesHost

	-- Responsive resizing of Navigation Pane and SearchBox (calculated from base width prior to UIScale)
	local function syncResponsiveLayout()
		local w = root.AbsoluteSize.X
		if self.AeroWindow and self.AeroWindow.WindowScale and self.AeroWindow.WindowScale.Scale > 0 then
			w = math.floor(w / self.AeroWindow.WindowScale.Scale + 0.5)
		end
		if self.AeroWindow and self.AeroWindow.WindowFrame and self.AeroWindow.WindowFrame.Size.X.Scale == 0 and self.AeroWindow.WindowFrame.Size.X.Offset > 0 then
			w = self.AeroWindow.WindowFrame.Size.X.Offset - 16
		end
		if w <= 0 then
			return
		end
		-- Continuous scaling (no visible jumps between breakpoints): navigation pane and search box follow ~35% of the width
		local adaptiveNavW = math.clamp(math.floor(w * 0.35), math.min(110, baseNavPaneWidth), baseNavPaneWidth)
		local searchW = math.clamp(math.floor(w * 0.35), 110, 176)
		-- The address bar always keeps at least 140px; on very narrow windows the search box gives way first
		searchW = math.max(40, math.min(searchW, w - 90 - 140))
		self.NavPaneWidth = adaptiveNavW
		navPane.Size = UDim2.new(0, adaptiveNavW, 1, 0)
		navDivider.Position = UDim2.new(0, adaptiveNavW, 0, 0)
		pagesHost.Position = UDim2.new(0, adaptiveNavW + 1, 0, 0)
		pagesHost.Size = UDim2.new(1, -(adaptiveNavW + 1), 1, 0)
		searchWrap.Position = UDim2.new(1, -(searchW + 6), 0, 5)
		searchWrap.Size = UDim2.new(0, searchW, 0, 24)
		addressBar.Size = UDim2.new(1, -(78 + searchW + 12), 0, 24)
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncResponsiveLayout)
	if self.AeroWindow and self.AeroWindow.WindowFrame then
		self.AeroWindow.WindowFrame:GetPropertyChangedSignal("Size"):Connect(syncResponsiveLayout)
	end
	syncResponsiveLayout()

	-- 4. Details / Status Bar at bottom (Height: 24px)
	local statusBar = Utility.Create("Frame", {
		Name = "ExplorerStatusBar",
		Parent = root,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 1, -24),
		Size = UDim2.new(1, 0, 0, 24),
		ZIndex = 6,
	})
	local statusGrad = Instance.new("UIGradient")
	statusGrad.Rotation = 90
	statusGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Theme.Colors.ExplorerStatusBarTop),
		ColorSequenceKeypoint.new(1.0, Theme.Colors.ExplorerStatusBarBot),
	})
	statusGrad.Parent = statusBar

	Utility.Create("Frame", {
		Name = "StatusTopBorder",
		Parent = statusBar,
		BackgroundColor3 = Theme.Colors.ExplorerStatusBarBorder,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 7,
	})

	local statusIcon = Utility.Create("ImageLabel", {
		Name = "StatusIcon",
		Parent = statusBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 4),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 7,
	})
	Assets.BindIcon(statusIcon, options.Icon or "Explorer")
	self.StatusIcon = statusIcon

	local statusText = Utility.Create("TextLabel", {
		Name = "StatusTextLabel",
		Parent = statusBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(1, -140, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = options.StatusText or "Ready",
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = Theme.Colors.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
	})
	self.StatusTextLabel = statusText

	local itemCountLabel = Utility.Create("TextLabel", {
		Name = "StatusItemCount",
		Parent = statusBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -120, 0, 0),
		Size = UDim2.new(0, 100, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = "0 items",
		TextColor3 = Theme.Colors.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 7,
	})
	self.ItemCountLabel = itemCountLabel

	-- Standard Windows 7 Status Bar resize gripper dots at bottom-right
	local gripHolder = Utility.Create("Frame", {
		Name = "Win7StatusResizeGrip",
		Parent = statusBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -13, 1, -13),
		Size = UDim2.new(0, 11, 0, 11),
		ZIndex = 8,
	})
	local gripCoords = {
		{ 7, 7 },
		{ 4, 7 }, { 7, 4 },
		{ 1, 7 }, { 4, 4 }, { 7, 1 },
	}
	for _, pt in ipairs(gripCoords) do
		Utility.Create("Frame", {
			Name = "GripDotHi",
			Parent = gripHolder,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0, pt[1] + 1, 0, pt[2] + 1),
			Size = UDim2.new(0, 2, 0, 2),
			ZIndex = 8,
		})
		Utility.Create("Frame", {
			Name = "GripDotLo",
			Parent = gripHolder,
			BackgroundColor3 = Color3.fromRGB(148, 164, 184),
			Position = UDim2.new(0, pt[1], 0, pt[2]),
			Size = UDim2.new(0, 2, 0, 2),
			ZIndex = 9,
		})
	end
end

-- Adds button to top Command Bar (supports 16x16 icon)
function ExplorerLayout:AddCommandBarButton(text, callback, iconName)
	if type(text) == "table" then
		local opts = text
		text = opts.Text or opts.Title or "Command"
		callback = opts.Callback or callback
		iconName = opts.Icon or iconName
	end

	local btn = Utility.Create("TextButton", {
		Name = "CmdBtn_" .. tostring(text),
		Parent = self.CommandButtonsHolder,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 22),
		Text = "",
		ZIndex = 8,
	})
	Utility.AddCorner(btn, 2)
	local stroke = Utility.AddStroke(btn, Theme.Colors.SelectionBorder, 1, 1, Enum.ApplyStrokeMode.Border)
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = Theme.Gradients.ButtonHover
	grad.Parent = btn

	local contentWrap = Utility.Create("Frame", {
		Name = "CmdBtnContent",
		Parent = btn,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		ZIndex = 9,
	})
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 7)
	pad.PaddingRight = UDim.new(0, 7)
	pad.Parent = contentWrap

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = contentWrap

	if iconName and iconName ~= "" then
		local ico = Utility.Create("ImageLabel", {
			Name = "CmdIcon",
			Parent = contentWrap,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(0, 14, 0, 14),
			ZIndex = 10,
		})
		Assets.BindIcon(ico, iconName)
	end

	Utility.Create("TextLabel", {
		Name = "CmdText",
		Parent = contentWrap,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = tostring(text),
		TextColor3 = Color3.fromRGB(30, 57, 91),
		TextSize = 13,
		ZIndex = 10,
	})

	btn.MouseEnter:Connect(function()
		btn.BackgroundTransparency = 0.1
		stroke.Transparency = 0.15
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundTransparency = 1
		stroke.Transparency = 1
	end)
	btn.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)

	table.insert(self.CommandButtons, {
		Button = btn,
		Label = contentWrap:FindFirstChild("CmdText"),
		HasIcon = (iconName ~= nil and iconName ~= ""),
		Compact = false,
	})
	btn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_FitCommandBar()
	end)
	self:_FitCommandBar()
	return btn
end

-- Buttons that have an icon drop their label (last button first) when the bar is too narrow, and get it back when space frees up.
-- Works purely on on-screen coordinates, so it is independent of UIScale and also accounts for a MenuBar sharing the holder.
function ExplorerLayout:_FitCommandBar()
	local holder = self.CommandButtonsHolder
	if not holder or not self.CommandButtons then
		return
	end
	local avail = holder.AbsoluteSize.X
	if avail <= 0 then
		return
	end
	local used = 0
	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible then
			used = math.max(used, child.AbsolutePosition.X + child.AbsoluteSize.X - holder.AbsolutePosition.X)
		end
	end

	if used > avail then
		for i = #self.CommandButtons, 1, -1 do
			local entry = self.CommandButtons[i]
			if entry.HasIcon and entry.Label and not entry.Compact then
				entry.FullWidth = entry.Button.AbsoluteSize.X
				entry.Label.Visible = false
				entry.Compact = true
				return -- the layout change re-runs this until everything fits
			end
		end
	else
		for i = 1, #self.CommandButtons do
			local entry = self.CommandButtons[i]
			if entry.Compact then
				local growth = (entry.FullWidth or 0) - entry.Button.AbsoluteSize.X
				if used + growth <= avail then
					entry.Label.Visible = true
					entry.Compact = false
				end
				return
			end
		end
	end
end

function ExplorerLayout:_UpdateHistoryButtons()
	self.BackOrb:SetEnabled(self.HistoryIndex > 1)
	self.ForwardOrb:SetEnabled(self.HistoryIndex < #self.History)
	if self.HistoryChevron then
		-- Chevron is only live when there is a Back/Forward stack to list
		if #self.History > 1 then
			self.HistoryChevron:SetColor(Color3.fromRGB(238, 246, 255), 0)
		else
			self.HistoryChevron:SetColor(Color3.fromRGB(238, 246, 255), 0.6)
		end
	end
end

-- Jumps to an entry of the Back/Forward stack without pushing a new history record
function ExplorerLayout:_GoToHistory(index)
	local target = self.History[index]
	if not target then
		return
	end
	self._NavigatingHistory = true
	self.HistoryIndex = index
	self:SelectTab(target)
	self._NavigatingHistory = false
	self:_UpdateHistoryButtons()
end

-- Path of an address: window title parts, then the tab's category, then the tab itself.
-- Kind = "root" | "category" | "tab" (drives what the arrow after a crumb lists).
function ExplorerLayout:_GetPathSegments(tabObj)
	local segments = {}
	local winTitle = tostring(self.AeroWindow and self.AeroWindow.Title or "Control Panel")
	for part in winTitle:gmatch("[^\\/]+") do
		local trimmed = part:gsub("^%s+", ""):gsub("%s+$", "")
		if trimmed ~= "" then
			table.insert(segments, { Label = trimmed, Tab = self.Tabs[1], Kind = "root" })
		end
	end
	if #segments == 0 then
		table.insert(segments, { Label = winTitle, Tab = self.Tabs[1], Kind = "root" })
	end

	if tabObj then
		if tabObj.Category and tabObj.Category ~= "" then
			local lastLbl = segments[#segments] and segments[#segments].Label
			if lastLbl ~= tabObj.Category then
				local firstInCategory = tabObj
				for _, t in ipairs(self.Tabs) do
					if t.Category == tabObj.Category then
						firstInCategory = t
						break
					end
				end
				table.insert(segments, {
					Label = tabObj.Category,
					Tab = firstInCategory,
					Kind = "category",
					Category = tabObj.Category,
				})
			end
		end
		table.insert(segments, { Label = tabObj.Title, Tab = tabObj, Kind = "tab" })
	end
	return segments
end

-- Items shown by the arrow that follows a crumb
function ExplorerLayout:_GetChildItems(seg)
	local items = {}
	local function add(t)
		table.insert(items, {
			Text = tostring(t.Title),
			Icon = t.Icon,
			Current = (t == self.ActiveTab),
			Callback = function()
				self:SelectTab(t)
			end,
		})
	end
	for _, t in ipairs(self.Tabs) do
		if seg.Kind == "root" or (seg.Kind == "category" and t.Category == seg.Category) then
			add(t)
		end
	end
	return items
end

-- Rebuilds the breadcrumb cells for a tab. Cells are AutomaticSize.X so width follows the text;
-- _FitBreadcrumbs then collapses the leading cells into "..." only when the real widths overflow.
function ExplorerLayout:_UpdateBreadcrumbs(tabObj)
	local container = self.BreadcrumbContainer
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	self._CrumbEllipsis = nil
	self._Crumbs = {}

	local segments = self:_GetPathSegments(tabObj)

	if self.HierarchyDoubleChevron then
		self.HierarchyDoubleChevron:SetDirection(self.HierarchyExpanded and "Right" or "Left")
	end

	for idx, seg in ipairs(segments) do
		local isLast = (idx == #segments)
		local crumb = Utility.Create("TextButton", {
			Name = "Breadcrumb_" .. tostring(idx),
			Parent = container,
			BackgroundColor3 = Color3.fromRGB(234, 246, 253),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 20),
			LayoutOrder = idx * 2,
			Font = isLast and Theme.Fonts.Semibold or Theme.Fonts.Regular,
			Text = tostring(seg.Label),
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.None,
			ZIndex = 9,
		})
		local crumbPad = Instance.new("UIPadding")
		crumbPad.PaddingLeft = UDim.new(0, CRUMB_PAD)
		crumbPad.PaddingRight = UDim.new(0, CRUMB_PAD)
		crumbPad.Parent = crumb
		bindFlatButton(crumb)

		crumb.MouseButton1Click:Connect(function()
			if seg.Tab and seg.Tab ~= self.ActiveTab then
				self:SelectTab(seg.Tab)
			end
		end)

		local entry = { Crumb = crumb }

		if not isLast then
			local arrow = Utility.Create("TextButton", {
				Name = "Arrow_" .. tostring(idx),
				Parent = container,
				BackgroundColor3 = Color3.fromRGB(234, 246, 253),
				BackgroundTransparency = 1,
				Size = UDim2.new(0, CRUMB_ARROW_W, 0, 20),
				LayoutOrder = idx * 2 + 1,
				Text = "",
				ZIndex = 9,
			})
			local chev = Utility.CreateVectorChevron(arrow, "Right", Color3.fromRGB(86, 104, 126), 10)
			bindFlatButton(arrow)
			-- Arrow = children of this location (rotates to "down" while its list is open)
			arrow.MouseButton1Click:Connect(function()
				local items = self:_GetChildItems(seg)
				if #items == 0 then
					return
				end
				chev:SetDirection("Down")
				self:_ShowDropdown(arrow, items, {
					MinWidth = 160,
					OnClose = function()
						chev:SetDirection("Right")
					end,
				})
			end)
			entry.Arrow = arrow
		end

		table.insert(self._Crumbs, entry)
	end

	self:_FitBreadcrumbs()
	-- Auto-size resolves a frame later (and again once the custom font loads), so re-fit shortly after
	task.delay(0.03, function()
		if self.BreadcrumbContainer and self.BreadcrumbContainer.Parent then
			self:_FitBreadcrumbs()
		end
	end)
	task.delay(0.35, function()
		if self.BreadcrumbContainer and self.BreadcrumbContainer.Parent then
			self:_FitBreadcrumbs()
		end
	end)
end

-- Decides which cells are visible from their *measured* widths (not character counts)
function ExplorerLayout:_FitBreadcrumbs()
	local container = self.BreadcrumbContainer
	local crumbs = self._Crumbs
	if not container or not crumbs or #crumbs == 0 or self._FittingCrumbs then
		return
	end
	self._FittingCrumbs = true

	-- Cache each cell's width while it is visible (hidden cells keep their last measured width)
	local allMeasured = true
	for _, c in ipairs(crumbs) do
		if c.Crumb.Visible then
			local w = c.Crumb.AbsoluteSize.X
			if w > 0 then
				c.CrumbW = w
			end
		end
		if c.CrumbW then
			c.Width = c.CrumbW + (c.Arrow and (CRUMB_ARROW_W + 2) or 0) + 1
		else
			allMeasured = false
		end
	end

	local n = #crumbs
	local avail = container.AbsoluteSize.X
	local first = 1
	local total = 0
	if allMeasured then
		for _, c in ipairs(crumbs) do
			total = total + c.Width
		end
	end

	if allMeasured and avail > 0 and not self.HierarchyExpanded and total > avail then
		-- Keep as many trailing cells as fit next to the "..." button; the last cell is always kept
		local used = CRUMB_ELLIPSIS_W + 2 + crumbs[n].Width
		first = n
		for i = n - 1, 1, -1 do
			if used + crumbs[i].Width <= avail then
				used = used + crumbs[i].Width
				first = i
			else
				break
			end
		end
	end

	if allMeasured or self.HierarchyExpanded then
		for i, c in ipairs(crumbs) do
			local show = (i >= first)
			c.Crumb.Visible = show
			if c.Arrow then
				c.Arrow.Visible = show
			end
		end

		-- "..." button exists only while leading cells are collapsed
		if first > 1 then
			if not self._CrumbEllipsis then
				local ell = Utility.Create("TextButton", {
					Name = "Breadcrumb_Ellipsis",
					Parent = container,
					BackgroundColor3 = Color3.fromRGB(234, 246, 253),
					BackgroundTransparency = 1,
					Size = UDim2.new(0, CRUMB_ELLIPSIS_W, 0, 20),
					LayoutOrder = 0,
					Font = Theme.Fonts.Regular,
					Text = "...",
					TextColor3 = Theme.Colors.TextPrimary,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Center,
					ZIndex = 9,
				})
				bindFlatButton(ell)
				ell.MouseButton1Click:Connect(function()
					-- Expands the full path (horizontal scroll)
					self.HierarchyExpanded = true
					self:_UpdateBreadcrumbs(self.ActiveTab)
				end)
				self._CrumbEllipsis = ell
			end
		elseif self._CrumbEllipsis then
			self._CrumbEllipsis:Destroy()
			self._CrumbEllipsis = nil
		end

		if self.HierarchyExpanded and avail > 0 and total > avail then
			container.ScrollBarThickness = 2
			container.CanvasPosition = Vector2.new(math.max(0, total - avail), 0)
		else
			container.ScrollBarThickness = 0
			container.CanvasPosition = Vector2.new(0, 0)
		end
	end

	self._FittingCrumbs = false
end

--------------------------------------------------------------------------------
-- Dropdown popup (history list, crumb arrows, recent locations)
--------------------------------------------------------------------------------

function ExplorerLayout:_CloseDropdown()
	local layer = self._DropdownLayer
	self._DropdownLayer = nil
	if layer then
		layer:Destroy()
	end
	local onClose = self._DropdownOnClose
	self._DropdownOnClose = nil
	if onClose then
		onClose()
	end
end

-- items = { { Text, Icon?, Current?, Callback } }; anchor = GuiObject the list hangs under
function ExplorerLayout:_ShowDropdown(anchor, items, options)
	options = options or {}
	self:_CloseDropdown()
	if not anchor or not items or #items == 0 then
		return nil
	end

	local host = self.AeroWindow and self.AeroWindow.ScreenGui
	if not host and anchor.FindFirstAncestorWhichIsA then
		host = anchor:FindFirstAncestorWhichIsA("ScreenGui")
	end
	if not host then
		return nil
	end

	local ROW_H = 22
	local maxRows = options.MaxRows or 12
	local width = options.MinWidth or 120
	for _, it in ipairs(items) do
		local labelX = it.Icon and 38 or 22
		local w = measureText(it.Text, 13, it.Current and "Semibold" or "Regular") + labelX + 12
		if w > width then
			width = w
		end
	end
	width = math.min(width, options.MaxWidth or 460)
	local rows = math.min(#items, maxRows)
	local height = rows * ROW_H + 6

	local ap = anchor.AbsolutePosition
	local as = anchor.AbsoluteSize
	local x = ap.X + (options.OffsetX or 0)
	local y = ap.Y + as.Y + 1
	local hostSize = host.AbsoluteSize
	if hostSize and hostSize.X > 0 and hostSize.Y > 0 then
		if x + width > hostSize.X then
			x = math.max(0, hostSize.X - width - 2)
		end
		if y + height > hostSize.Y then
			y = math.max(0, ap.Y - height - 1)
		end
	end

	-- Full-screen catcher: clicking anywhere outside closes the list
	local layer = Utility.Create("TextButton", {
		Name = "ExplorerDropdownLayer",
		Parent = host,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		ZIndex = 600,
	})
	layer.MouseButton1Click:Connect(function()
		self:_CloseDropdown()
	end)
	self._DropdownLayer = layer
	self._DropdownOnClose = options.OnClose

	local popup = Utility.Create("Frame", {
		Name = "ExplorerDropdownList",
		Parent = layer,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, x, 0, y),
		Size = UDim2.new(0, width, 0, height),
		ZIndex = 601,
	})
	Utility.AddStroke(popup, Color3.fromRGB(145, 155, 170), 1, 0, Enum.ApplyStrokeMode.Border)

	local list = Utility.Create("ScrollingFrame", {
		Name = "Items",
		Parent = popup,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 3),
		Size = UDim2.new(1, -4, 1, -6),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = (#items > maxRows) and 6 or 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 602,
	})
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	for i, it in ipairs(items) do
		local row = Utility.Create("TextButton", {
			Name = "DropdownItem_" .. tostring(i),
			Parent = list,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, ROW_H),
			LayoutOrder = i,
			Text = "",
			ZIndex = 603,
		})
		Utility.AddCorner(row, 2)
		local rowStroke = Utility.AddStroke(row, Theme.Colors.SelectionHoverBorder, 1, 1, Enum.ApplyStrokeMode.Border)
		local rowGrad = Instance.new("UIGradient")
		rowGrad.Rotation = 90
		rowGrad.Color = Theme.Gradients.ExplorerItemHover
		rowGrad.Parent = row

		if it.Current then
			local dot = Utility.Create("Frame", {
				Name = "CurrentMark",
				Parent = row,
				BackgroundColor3 = Color3.fromRGB(40, 104, 186),
				Position = UDim2.new(0, 7, 0.5, -3),
				Size = UDim2.new(0, 6, 0, 6),
				ZIndex = 604,
			})
			Utility.AddCorner(dot, 3)
		end

		local labelX = 22
		if it.Icon then
			local ico = Utility.Create("ImageLabel", {
				Name = "ItemIcon",
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 18, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				ZIndex = 604,
			})
			Assets.BindIcon(ico, it.Icon)
			labelX = 38
		end

		Utility.Create("TextLabel", {
			Name = "ItemText",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, labelX, 0, 0),
			Size = UDim2.new(1, -(labelX + 6), 1, 0),
			Font = it.Current and Theme.Fonts.Semibold or Theme.Fonts.Regular,
			Text = tostring(it.Text),
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 604,
		})

		row.MouseEnter:Connect(function()
			row.BackgroundTransparency = 0.05
			rowStroke.Transparency = 0.2
		end)
		row.MouseLeave:Connect(function()
			row.BackgroundTransparency = 1
			rowStroke.Transparency = 1
		end)
		row.MouseButton1Click:Connect(function()
			self:_CloseDropdown()
			if it.Callback then
				it.Callback()
			end
		end)
	end

	return popup
end

--------------------------------------------------------------------------------
-- Address bar behaviour: Refresh / Stop / Go + editable path
--------------------------------------------------------------------------------

function ExplorerLayout:_SetAddressState(state)
	self.AddressState = state
	if self._GlyphRefresh then
		self._GlyphRefresh.Visible = (state == "idle")
		self._GlyphGo.Visible = (state == "editing")
		self._GlyphStop.Visible = (state == "loading")
	end
end

-- Reloads the current page: clears the search filter, rebuilds the path, shows load progress, fires OnRefresh
function ExplorerLayout:Refresh()
	if self.AddressState == "loading" then
		return
	end
	if self.AddressState == "editing" then
		self:_EndAddressEdit()
	end
	self.HierarchyExpanded = false
	if self.SearchBox and self.SearchBox.Text ~= "" then
		self.SearchBox.Text = ""
	end

	self:_SetAddressState("loading")
	self._LoadToken = self._LoadToken + 1
	local token = self._LoadToken

	local fill = self.AddressProgressFill
	if fill then
		fill.Size = UDim2.new(0, 0, 1, -2)
		fill.Visible = true
		Utility.Tween(fill, 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
			Size = UDim2.new(1, -2, 1, -2),
		})
	end

	local tab = self.ActiveTab
	local callback = (tab and tab.OnRefresh) or self.OnRefresh
	if type(callback) == "function" then
		task.spawn(function()
			local ok, err = pcall(callback, tab, self)
			if not ok and type(warn) == "function" then
				warn("[Aero7] OnRefresh callback error: " .. tostring(err))
			end
		end)
	end

	task.delay(0.5, function()
		if self._LoadToken == token and self.AddressState == "loading" then
			self:_FinishLoading()
		end
	end)
end

function ExplorerLayout:_FinishLoading()
	if self.AddressProgressFill then
		self.AddressProgressFill.Visible = false
	end
	self:_SetAddressState("idle")
	self:_UpdateBreadcrumbs(self.ActiveTab)
	self:_UpdateStatusCount()
end

-- Cancels a running refresh (the Stop glyph)
function ExplorerLayout:StopLoading()
	if self.AddressState ~= "loading" then
		return
	end
	self._LoadToken = self._LoadToken + 1
	if self.AddressProgressFill then
		self.AddressProgressFill.Visible = false
	end
	self:_SetAddressState("idle")
	local tab = self.ActiveTab
	if type(self.OnStop) == "function" then
		task.spawn(function()
			pcall(self.OnStop, tab, self)
		end)
	end
end

-- Switches the crumbs to editable path text; the action button becomes Go
function ExplorerLayout:_BeginAddressEdit()
	if self.AddressState == "editing" or not self.AddressEditBox then
		return
	end
	if self.AddressState == "loading" then
		self:StopLoading()
	end
	local labels = {}
	for _, seg in ipairs(self:_GetPathSegments(self.ActiveTab)) do
		table.insert(labels, seg.Label)
	end
	local box = self.AddressEditBox
	box.Text = table.concat(labels, "\\")
	box.Visible = true
	self.BreadcrumbContainer.Visible = false
	self.AddressHitArea.Visible = false
	if self.HierarchyOverflowButton then
		self.HierarchyOverflowButton.Visible = false
	end
	self:_SetAddressState("editing")
	pcall(function()
		box:CaptureFocus()
		box.CursorPosition = #box.Text + 1
		box.SelectionStart = 1
	end)
end

function ExplorerLayout:_EndAddressEdit()
	if self.AddressState ~= "editing" then
		return
	end
	self.AddressEditBox.Visible = false
	self.BreadcrumbContainer.Visible = true
	self.AddressHitArea.Visible = true
	if self.HierarchyOverflowButton then
		self.HierarchyOverflowButton.Visible = true
	end
	self:_SetAddressState("idle")
end

-- Resolves typed text ("Control Panel\Appearance\Display", last part wins) to a tab
function ExplorerLayout:_ResolveAddress(text)
	local normalized = tostring(text or ""):gsub("/", "\\")
	local target
	for part in normalized:gmatch("[^\\]+") do
		local trimmed = part:gsub("^%s+", ""):gsub("%s+$", "")
		if trimmed ~= "" then
			target = trimmed:lower()
		end
	end
	if not target then
		return nil
	end

	for _, t in ipairs(self.Tabs) do
		if tostring(t.Title):lower() == target then
			return t
		end
	end
	for _, t in ipairs(self.Tabs) do
		if t.Category and tostring(t.Category):lower() == target then
			return t
		end
	end
	local winTitle = tostring(self.AeroWindow and self.AeroWindow.Title or "")
	for part in winTitle:gmatch("[^\\/]+") do
		local trimmed = part:gsub("^%s+", ""):gsub("%s+$", "")
		if trimmed:lower() == target then
			return self.Tabs[1]
		end
	end
	-- Unique prefix ("displ" -> "Display")
	local found, count = nil, 0
	for _, t in ipairs(self.Tabs) do
		if tostring(t.Title):lower():sub(1, #target) == target then
			found = t
			count = count + 1
		end
	end
	if count == 1 then
		return found
	end
	return nil
end

function ExplorerLayout:_CommitAddressText(text)
	local target = self:_ResolveAddress(text)
	self:_EndAddressEdit()
	if target then
		if target ~= self.ActiveTab then
			self:SelectTab(target)
		end
	else
		-- Unknown location: flash the border red like Explorer's "can't find" error
		local stroke = self.AddressStroke
		if stroke then
			stroke.Color = Color3.fromRGB(200, 60, 60)
			stroke.Transparency = 0
			task.delay(0.8, function()
				stroke.Color = Color3.fromRGB(58, 82, 108)
				stroke.Transparency = 0.18
			end)
		end
		self:SetStatus("Cannot find '" .. tostring(text) .. "'. Check the spelling and try again.")
	end
end

-- Allows updating leading hierarchy icon dynamically
function ExplorerLayout:SetHierarchyIcon(iconNameOrAssetId)
	self.CustomHierarchyIcon = iconNameOrAssetId
	self.HierarchyIcon = iconNameOrAssetId or "ControlPanel"
	if self.AddressIcon then
		Assets.BindIcon(self.AddressIcon, self.HierarchyIcon)
	end
end

function ExplorerLayout:SetDefaultTabIcon(iconNameOrAssetId)
	self.DefaultTabIcon = iconNameOrAssetId or "ControlPanel"
end

-- Creates a new Tab / Page in Explorer / Control Panel layout
function ExplorerLayout:CreateTab(tabOptions)
	if type(tabOptions) == "string" then
		tabOptions = { Title = tabOptions }
	end
	tabOptions = tabOptions or {}

	local tabTitle = tabOptions.Title or ("Category " .. tostring(#self.Tabs + 1))
	local tabIcon = (tabOptions.Icon ~= nil and tabOptions.Icon ~= "") and tabOptions.Icon
		or self.DefaultTabIcon
		or "ControlPanel"
	local tabHierarchyIcon = tabOptions.HierarchyIcon or tabOptions.AddressIcon
	local categoryName = tabOptions.Category
	local categoryIcon = tabOptions.CategoryIcon
	local subtitle = tabOptions.Subtitle or tabOptions.Description or ("Configure " .. tabTitle .. " settings and options.")

	-- Creates collapsible Category header in sidebar with Windows 7 animation if needed
	local catEntry = categoryName and self.Categories[categoryName] or nil
	if categoryName and not catEntry then
		local catOrder = (#self.Tabs + 1) * 10 - 2
		local catHeader = Utility.Create("TextButton", {
			Name = "TreeCategory_" .. categoryName,
			Parent = self.NavPane,
			BackgroundColor3 = Color3.fromRGB(235, 244, 253),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			LayoutOrder = catOrder,
			Text = "",
			ZIndex = 7,
		})
		Utility.AddCorner(catHeader, 2)
		local catHeaderStroke = Utility.AddStroke(
			catHeader,
			Theme.Colors.SelectionHoverBorder,
			1,
			1,
			Enum.ApplyStrokeMode.Border
		)

		local expandWrap = Utility.Create("Frame", {
			Name = "ExpandArrow",
			Parent = catHeader,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 1, 0, 0),
			Size = UDim2.new(0, 12, 1, 0),
			ZIndex = 8,
		})
		local catChevron = Utility.CreateVectorChevron(expandWrap, "Down", Color3.fromRGB(52, 82, 118), 9)

		-- Automatically selects category icon (Control Panel / Favorites / Libraries / Computer)
		local resolvedCatIcon = categoryIcon
		if not resolvedCatIcon or resolvedCatIcon == "" then
			local lowerCat = categoryName:lower()
			if lowerCat:find("system") or lowerCat:find("control") then
				resolvedCatIcon = "ControlPanel"
			elseif lowerCat:find("visual") or lowerCat:find("display") or lowerCat:find("aero") or lowerCat:find("appear") then
				resolvedCatIcon = "Personalize"
			elseif lowerCat:find("security") or lowerCat:find("admin") then
				resolvedCatIcon = "Security"
			elseif lowerCat:find("network") then
				resolvedCatIcon = "Network"
			else
				resolvedCatIcon = "Favorites"
			end
		end

		local catIco = Utility.Create("ImageLabel", {
			Name = "CategoryIcon",
			Parent = catHeader,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 14, 0.5, -7),
			Size = UDim2.new(0, 14, 0, 14),
			ZIndex = 8,
		})
		Assets.BindIcon(catIco, resolvedCatIcon)

		Utility.Create("TextLabel", {
			Name = "CategoryTitle",
			Parent = catHeader,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 32, 0, 0),
			Size = UDim2.new(1, -34, 1, 0),
			Font = Theme.Fonts.Semibold,
			Text = categoryName,
			TextColor3 = Color3.fromRGB(30, 57, 91),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 8,
		})

		-- Container for category items (supports smooth Windows 7 expand/collapse)
		local catItemsHolder = Utility.Create("Frame", {
			Name = "CategoryItems_" .. categoryName,
			Parent = self.NavPane,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, 0),
			ClipsDescendants = true,
			LayoutOrder = catOrder + 1,
			ZIndex = 7,
		})
		local catItemsLayout = Instance.new("UIListLayout")
		catItemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		catItemsLayout.Padding = UDim.new(0, 2)
		catItemsLayout.Parent = catItemsHolder
		-- 2px horizontal and 1px vertical padding so selection stroke is not clipped by ClipsDescendants
		local catItemsPad = Instance.new("UIPadding")
		catItemsPad.PaddingLeft = UDim.new(0, 2)
		catItemsPad.PaddingRight = UDim.new(0, 2)
		catItemsPad.PaddingTop = UDim.new(0, 1)
		catItemsPad.PaddingBottom = UDim.new(0, 1)
		catItemsPad.Parent = catItemsHolder

		catEntry = {
			Name = categoryName,
			Header = catHeader,
			Chevron = catChevron,
			ItemsHolder = catItemsHolder,
			Items = {},
			Expanded = true,
			ExpandedHeight = 0,
		}

		function catEntry:SetExpanded(state)
			if state == nil then
				self.Expanded = not self.Expanded
			else
				self.Expanded = (state == true)
			end
			self.Chevron:SetDirection(self.Expanded and "Down" or "Right")
			local targetH = self.Expanded and self.ExpandedHeight or 0
			if self.Expanded then
				self.ItemsHolder.Visible = true
			end
			Utility.Tween(self.ItemsHolder, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
				Size = UDim2.new(1, 0, 0, targetH),
			})
			if not self.Expanded and task and task.delay then
				task.delay(0.16, function()
					if not self.Expanded and self.ItemsHolder and self.ItemsHolder.Parent then
						self.ItemsHolder.Visible = false
					end
				end)
			end
		end

		function catEntry:Toggle()
			self:SetExpanded(not self.Expanded)
		end

		catHeader.MouseEnter:Connect(function()
			catHeader.BackgroundTransparency = 0.12
			catHeaderStroke.Transparency = 0.25
			catChevron:SetColor(Color3.fromRGB(28, 151, 234))
		end)
		catHeader.MouseLeave:Connect(function()
			catHeader.BackgroundTransparency = 1
			catHeaderStroke.Transparency = 1
			catChevron:SetColor(Color3.fromRGB(52, 82, 118))
		end)
		catHeader.MouseButton1Click:Connect(function()
			catEntry:Toggle()
		end)

		self.Categories[categoryName] = catEntry
	end

	-- Sidebar navigation item button (Aero selection box style)
	local navParent = catEntry and catEntry.ItemsHolder or self.NavPane
	local navBtn = Utility.Create("TextButton", {
		Name = "NavItem_" .. tabTitle,
		Parent = navParent,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = (#self.Tabs + 1) * 10,
		Text = "",
		ZIndex = 7,
	})
	Utility.AddCorner(navBtn, 2)

	if catEntry then
		table.insert(catEntry.Items, navBtn)
		catEntry.ExpandedHeight = (#catEntry.Items * 24) + math.max(0, #catEntry.Items - 1) * 2 + 2
		if catEntry.Expanded then
			catEntry.ItemsHolder.Size = UDim2.new(1, 0, 0, catEntry.ExpandedHeight)
		end
	end

	local navStroke = Utility.AddStroke(navBtn, Theme.Colors.SelectionBorder, 1, 1, Enum.ApplyStrokeMode.Border)
	local navGrad = Instance.new("UIGradient")
	navGrad.Rotation = 90
	navGrad.Color = Theme.Gradients.ExplorerItemSelected
	navGrad.Parent = navBtn

	local indentPx = categoryName and 14 or 6
	local itemIcon = Utility.Create("ImageLabel", {
		Name = "ItemIcon",
		Parent = navBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, indentPx, 0.5, -8),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 8,
	})
	Assets.BindIcon(itemIcon, tabIcon)

	local itemLabel = Utility.Create("TextLabel", {
		Name = "ItemLabel",
		Parent = navBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, indentPx + 22, 0, 0),
		Size = UDim2.new(1, -(indentPx + 26), 1, 0),
		Font = Theme.Fonts.Regular,
		Text = tabTitle,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 8,
	})

	-- Right-side client page with Windows 7 scrollbar
	local pageWrap = Utility.Create("Frame", {
		Name = "PageWrap_" .. tabTitle,
		Parent = self.PagesHost,
		BackgroundColor3 = Theme.Colors.ExplorerClientBg,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ZIndex = 6,
	})

	local pageScroll = Utility.Create("ScrollingFrame", {
		Name = "Page_" .. tabTitle,
		Parent = pageWrap,
		BackgroundColor3 = Theme.Colors.ExplorerClientBg,
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ZIndex = 6,
	})
	Scrollbar.Attach(pageScroll)

	local pagePad = Instance.new("UIPadding")
	pagePad.PaddingTop = UDim.new(0, 12)
	pagePad.PaddingBottom = UDim.new(0, 16)
	pagePad.PaddingLeft = UDim.new(0, 16)
	pagePad.PaddingRight = UDim.new(0, 16)
	pagePad.Parent = pageScroll

	local pageList = Instance.new("UIListLayout")
	pageList.SortOrder = Enum.SortOrder.LayoutOrder
	pageList.Padding = UDim.new(0, 10)
	pageList.Parent = pageScroll

	-- Windows 7 Control Panel #003399 blue section header with crisp icon
	local pageHeader = Utility.Create("Frame", {
		Name = "ControlPanelBanner",
		Parent = pageScroll,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		LayoutOrder = 0,
		ZIndex = 7,
	})
	local headerIcon = Utility.Create("ImageLabel", {
		Name = "HeaderIcon",
		Parent = pageHeader,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 2),
		Size = UDim2.new(0, 24, 0, 24),
		ZIndex = 8,
	})
	Assets.BindIcon(headerIcon, tabIcon)

	Utility.Create("TextLabel", {
		Name = "HeaderTitle",
		Parent = pageHeader,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 32, 0, 0),
		Size = UDim2.new(1, -32, 0, 20),
		Font = Theme.Fonts.Regular,
		Text = tabTitle,
		TextColor3 = Theme.Colors.TextInstruction, -- #003399
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 8,
	})
	Utility.Create("TextLabel", {
		Name = "HeaderSubtitle",
		Parent = pageHeader,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 32, 0, 20),
		Size = UDim2.new(1, -32, 0, 16),
		Font = Theme.Fonts.Regular,
		Text = subtitle,
		TextColor3 = Theme.Colors.TextSecondary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 8,
	})
	local bannerRule = Utility.Create("Frame", {
		Name = "BannerDividerLine",
		Parent = pageHeader,
		BackgroundColor3 = Theme.Colors.RuleDivider,
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 8,
	})
	local ruleGrad = Instance.new("UIGradient")
	ruleGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.0),
		NumberSequenceKeypoint.new(0.75, 0.2),
		NumberSequenceKeypoint.new(1.0, 0.9),
	})
	ruleGrad.Parent = bannerRule

	-- Container supporting single or dual column layout
	local contentContainer = Utility.Create("Frame", {
		Name = "PageContentContainer",
		Parent = pageScroll,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 1,
		ZIndex = 7,
	})
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 10)
	contentLayout.Parent = contentContainer

	local tabObj = {
		Title = tabTitle,
		Icon = tabIcon,
		HierarchyIcon = tabHierarchyIcon,
		OnRefresh = tabOptions.OnRefresh,
		Category = categoryName,
		Subtitle = subtitle,
		NavButton = navBtn,
		NavIcon = itemIcon,
		HeaderIcon = headerIcon,
		NavStroke = navStroke,
		NavGradient = navGrad,
		NavLabel = itemLabel,
		PageFrame = pageWrap,
		ScrollFrame = pageScroll,
		Container = contentContainer,
		Items = {},
		SetIcon = function(selfTab, newIcon)
			selfTab.Icon = newIcon or self.DefaultTabIcon or "ControlPanel"
			Assets.BindIcon(selfTab.NavIcon, selfTab.Icon)
			Assets.BindIcon(selfTab.HeaderIcon, selfTab.Icon)
			if self.ActiveTab == selfTab then
				local hIco = selfTab.HierarchyIcon or self.CustomHierarchyIcon or selfTab.Icon or self.HierarchyIcon
				Assets.BindIcon(self.AddressIcon, hIco)
				Assets.BindIcon(self.StatusIcon, selfTab.Icon)
			end
		end,
	}

	-- Binds component factory methods (AddGroupBox, AddButton, AddCheckbox...) to Tab
	if self.ComponentFactory then
		self.ComponentFactory:AttachToContainer(tabObj, contentContainer, function()
			self:_UpdateStatusCount()
		end)
	end

	navBtn.MouseEnter:Connect(function()
		if self.ActiveTab ~= tabObj then
			navGrad.Color = Theme.Gradients.ExplorerItemHover
			navBtn.BackgroundTransparency = 0.1
			navStroke.Color = Theme.Colors.SelectionHoverBorder
			navStroke.Transparency = 0.2
		end
	end)

	navBtn.MouseLeave:Connect(function()
		if self.ActiveTab ~= tabObj then
			navBtn.BackgroundTransparency = 1
			navStroke.Transparency = 1
		end
	end)

	navBtn.MouseButton1Click:Connect(function()
		self:SelectTab(tabObj)
	end)

	table.insert(self.Tabs, tabObj)
	if #self.Tabs == 1 then
		self:SelectTab(tabObj)
	end

	return tabObj
end

function ExplorerLayout:SelectTab(tabObj)
	if not tabObj then
		return
	end
	local previousTab = self.ActiveTab
	self.ActiveTab = tabObj

	for _, t in ipairs(self.Tabs) do
		local isSelected = (t == tabObj)
		t.PageFrame.Visible = isSelected
		if isSelected then
			t.NavGradient.Color = Theme.Gradients.ExplorerItemSelected
			t.NavButton.BackgroundTransparency = 0.05
			t.NavStroke.Color = Theme.Colors.SelectionBorder
			t.NavStroke.Transparency = 0.1
			Theme.ApplyFont(t.NavLabel, Theme.Fonts.Semibold)
		else
			t.NavButton.BackgroundTransparency = 1
			t.NavStroke.Transparency = 1
			Theme.ApplyFont(t.NavLabel, Theme.Fonts.Regular)
		end
	end

	-- Pushes navigation event to Back / Forward history
	if not self._NavigatingHistory then
		if self.History[self.HistoryIndex] ~= tabObj then
			for i = #self.History, self.HistoryIndex + 1, -1 do
				table.remove(self.History, i)
			end
			table.insert(self.History, tabObj)
			self.HistoryIndex = #self.History
		end
		self:_UpdateHistoryButtons()
	end

	self:_UpdateBreadcrumbs(tabObj)
	local resolvedHierarchyIcon = tabObj.HierarchyIcon or self.CustomHierarchyIcon or tabObj.Icon or self.HierarchyIcon
	Assets.BindIcon(self.AddressIcon, resolvedHierarchyIcon)
	Assets.BindIcon(self.StatusIcon, tabObj.Icon)
	if self.SearchPlaceholderLabel then
		self.SearchPlaceholderLabel.Text = "Search " .. tostring(tabObj.Title or self.AeroWindow.Title or "Control Panel")
	end
	self:_UpdateStatusCount()

	if previousTab ~= tabObj and type(self.OnNavigate) == "function" then
		local navCallback = self.OnNavigate
		task.spawn(function()
			pcall(navCallback, tabObj, self)
		end)
	end
end

-- Callback setters (a window controller forwards methods but not field assignment)
function ExplorerLayout:SetOnRefresh(fn)
	self.OnRefresh = fn
end

function ExplorerLayout:SetOnStop(fn)
	self.OnStop = fn
end

function ExplorerLayout:SetOnNavigate(fn)
	self.OnNavigate = fn
end

function ExplorerLayout:_UpdateStatusCount()
	if not self.ActiveTab then
		return
	end
	local count = #self.ActiveTab.Container:GetChildren() - 1
	if count < 0 then
		count = 0
	end
	self.ItemCountLabel.Text = tostring(count) .. (count == 1 and " item" or " items")
	self.StatusTextLabel.Text = self.ActiveTab.Title .. " — " .. self.ActiveTab.Subtitle
end

function ExplorerLayout:SetStatus(text)
	self.StatusTextLabel.Text = tostring(text or "")
end

-- Creates standard Windows 7 MenuBar (File, Edit, View, Tools, Help)
function ExplorerLayout:SetMenuBar(menusSpec)
	return MenuBar.new(self.CommandButtonsHolder, menusSpec)
end

-- Filters active page controls by keyword matching from Instant Search box
function ExplorerLayout:ApplySearchFilter(query)
	local q = tostring(query or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if not self.ActiveTab then
		return
	end

	local matchCount = 0
	for _, child in ipairs(self.ActiveTab.Container:GetChildren()) do
		if child:IsA("GuiObject") then
			if q == "" then
				child.Visible = true
				matchCount = matchCount + 1
			else
				local found = false
				if child.Name:lower():find(q, 1, true) then
					found = true
				end
				for _, desc in ipairs(child:GetDescendants()) do
					if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Text:lower():find(q, 1, true) then
						found = true
						break
					end
				end
				child.Visible = found
				if found then
					matchCount = matchCount + 1
				end
			end
		end
	end

	if q ~= "" then
		self.ItemCountLabel.Text = tostring(matchCount) .. " match(es)"
	else
		self:_UpdateStatusCount()
	end
end

return ExplorerLayout
