--!nonstrict
-- Aero7: window/ExplorerLayout - Standard Windows 7 Explorer / Control Panel layout with jewel buttons, breadcrumbs, search, sidebar, and client pages.

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Scrollbar = require("components/Scrollbar")
local MenuBar = require("components/MenuBar")

local ExplorerLayout = {}
ExplorerLayout.__index = ExplorerLayout

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
	local navOrbHousing = Utility.Create("Frame", {
		Name = "BackForwardHousing",
		Parent = navBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0, 2),
		Size = UDim2.new(0, 70, 0, 29),
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

	-- Back (27x27px) and Forward (25x25px) buttons per Windows 7 ExplorerFrame.dll
	self.BackOrb = createNavOrb("Back", 1, 27, "Left")
	self.ForwardOrb = createNavOrb("Forward", 30, 25, "Right")

	-- Recent pages history chevron at right edge of Back/Forward cluster
	local historyDropBtn = Utility.Create("TextButton", {
		Name = "HistoryDropdownButton",
		Parent = navOrbHousing,
		BackgroundColor3 = Color3.fromRGB(196, 226, 255),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 56, 0, 2),
		Size = UDim2.new(0, 14, 1, -4),
		AutoButtonColor = false,
		Text = "",
		ZIndex = 9,
	})
	Utility.AddCorner(historyDropBtn, 6)
	local histChevron = Utility.CreateVectorChevron(historyDropBtn, "Down", Color3.fromRGB(238, 246, 255), 10)
	historyDropBtn.MouseEnter:Connect(function()
		historyDropBtn.BackgroundTransparency = 0.45
		histChevron:SetColor(Color3.fromRGB(255, 255, 255))
	end)
	historyDropBtn.MouseLeave:Connect(function()
		historyDropBtn.BackgroundTransparency = 1
		histChevron:SetColor(Color3.fromRGB(238, 246, 255))
	end)
	historyDropBtn.MouseButton1Click:Connect(function()
		if #self.Tabs > 1 then
			local nextIdx = 1
			for i, t in ipairs(self.Tabs) do
				if t == self.ActiveTab then
					nextIdx = (i % #self.Tabs) + 1
					break
				end
			end
			self:SelectTab(self.Tabs[nextIdx])
		end
	end)

	self.BackOrb.Button.MouseButton1Click:Connect(function()
		if self.HistoryIndex > 1 then
			self._NavigatingHistory = true
			self.HistoryIndex = self.HistoryIndex - 1
			self:SelectTab(self.History[self.HistoryIndex])
			self._NavigatingHistory = false
			self:_UpdateHistoryButtons()
		end
	end)

	self.ForwardOrb.Button.MouseButton1Click:Connect(function()
		if self.HistoryIndex < #self.History then
			self._NavigatingHistory = true
			self.HistoryIndex = self.HistoryIndex + 1
			self:SelectTab(self.History[self.HistoryIndex])
			self._NavigatingHistory = false
			self:_UpdateHistoryButtons()
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

	-- 3. Horizontal scrolling container holding breadcrumb hierarchy segments
	local breadcrumbContainer = Utility.Create("ScrollingFrame", {
		Name = "BreadcrumbSegments",
		Parent = addressBar,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 40, 0, 1),
		Size = UDim2.new(1, -64, 1, -2),
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

	-- Refresh button at right edge of address bar
	local refreshBtn = Utility.Create("TextButton", {
		Name = "AddressRefreshButton",
		Parent = addressBar,
		BackgroundColor3 = Color3.fromRGB(234, 246, 253),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -22, 0, 1),
		Size = UDim2.new(0, 21, 1, -2),
		Text = "",
		ZIndex = 9,
	})
	local refreshIcon = Utility.Create("ImageLabel", {
		Name = "RefreshIcon",
		Parent = refreshBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, -7, 0.5, -7),
		Size = UDim2.new(0, 14, 0, 14),
		ZIndex = 10,
	})
	Assets.BindIcon(refreshIcon, "Refresh")

	refreshBtn.MouseEnter:Connect(function()
		refreshBtn.BackgroundTransparency = 0.1
		addrStroke.Color = Theme.Colors.EditBorderHover
		addrStroke.Transparency = 0
	end)
	refreshBtn.MouseLeave:Connect(function()
		refreshBtn.BackgroundTransparency = 1
		addrStroke.Color = Color3.fromRGB(58, 82, 108)
		addrStroke.Transparency = 0.18
	end)
	refreshBtn.MouseButton1Click:Connect(function()
		if self.SearchBox then
			self.SearchBox.Text = ""
		end
		self.HierarchyExpanded = false
		self:_UpdateBreadcrumbs(self.ActiveTab)
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

	local searchIcon = Utility.Create("ImageLabel", {
		Name = "SearchMagnifier",
		Parent = searchActionBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, -8, 0.5, -8),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 10,
	})
	Assets.BindIcon(searchIcon, "Search")

	local searchClearGlyph = Utility.Create("Frame", {
		Name = "SearchClearGlyph",
		Parent = searchActionBtn,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ZIndex = 10,
	})
	Utility.CreateVectorCloseX(searchClearGlyph, Color3.fromRGB(72, 118, 172), Color3.fromRGB(220, 235, 250), 11)

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
		local adaptiveNavW = baseNavPaneWidth
		local searchW = 176
		if w < 440 then
			adaptiveNavW = 128
			searchW = 124
		elseif w < 500 then
			adaptiveNavW = 148
			searchW = 148
		end
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
	return btn
end

function ExplorerLayout:_UpdateHistoryButtons()
	self.BackOrb:SetEnabled(self.HistoryIndex > 1)
	self.ForwardOrb:SetEnabled(self.HistoryIndex < #self.History)
end

-- Updates breadcrumb address bar segments (supports ellipsis collapse + full horizontal scroll)
function ExplorerLayout:_UpdateBreadcrumbs(tabObj)
	for _, child in ipairs(self.BreadcrumbContainer:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Splits window title path by "\\" or "/" into distinct hierarchy segments
	local allSegments = {}
	local winTitle = tostring(self.AeroWindow and self.AeroWindow.Title or "Control Panel")
	for part in winTitle:gmatch("[^\\/]+") do
		local trimmed = part:gsub("^%s+", ""):gsub("%s+$", "")
		if trimmed ~= "" then
			table.insert(allSegments, { Label = trimmed, Tab = self.Tabs[1] })
		end
	end
	if #allSegments == 0 then
		table.insert(allSegments, { Label = winTitle, Tab = self.Tabs[1] })
	end

	if tabObj then
		if tabObj.Category and tabObj.Category ~= "" then
			local lastLbl = allSegments[#allSegments] and allSegments[#allSegments].Label
			if lastLbl ~= tabObj.Category then
				table.insert(allSegments, { Label = tabObj.Category, Tab = tabObj })
			end
		end
		table.insert(allSegments, { Label = tabObj.Title, Tab = tabObj })
	end

	local totalChars = 0
	for _, seg in ipairs(allSegments) do
		totalChars = totalChars + #tostring(seg.Label) + 3
	end
	local isLongHierarchy = (#allSegments > 2) or (totalChars > 28)

	if self.HierarchyDoubleChevron then
		self.HierarchyDoubleChevron:SetDirection(self.HierarchyExpanded and "Right" or "Left")
	end

	-- When collapsed and path is long: shows leading "..." button + 2 trailing segments
	local displaySegments = {}
	if isLongHierarchy and not self.HierarchyExpanded then
		self.BreadcrumbContainer.ScrollBarThickness = 0
		self.BreadcrumbContainer.CanvasPosition = Vector2.new(0, 0)
		table.insert(displaySegments, {
			Label = "...",
			IsEllipsis = true,
			Tab = self.Tabs[1],
		})
		if #allSegments >= 2 then
			table.insert(displaySegments, allSegments[#allSegments - 1])
		end
		table.insert(displaySegments, allSegments[#allSegments])
	else
		self.BreadcrumbContainer.ScrollBarThickness = isLongHierarchy and 2 or 0
		for _, seg in ipairs(allSegments) do
			table.insert(displaySegments, seg)
		end
	end

	for idx, seg in ipairs(displaySegments) do
		local isLast = (idx == #displaySegments)
		local labelText = tostring(seg.Label)
		local segWidth
		if seg.IsEllipsis then
			segWidth = 24
		elseif self.HierarchyExpanded then
			segWidth = math.max(36, #labelText * 7 + 14)
		else
			-- Collapsed mode: constrains segment widths with text ellipsis
			segWidth = math.clamp(#labelText * 7 + 12, 36, isLast and 138 or 96)
		end

		local segBtn = Utility.Create("TextButton", {
			Name = seg.IsEllipsis and "Breadcrumb_Ellipsis" or ("Breadcrumb_" .. tostring(idx)),
			Parent = self.BreadcrumbContainer,
			BackgroundColor3 = Color3.fromRGB(234, 246, 253),
			BackgroundTransparency = 1,
			Size = UDim2.new(0, segWidth, 0, 20),
			LayoutOrder = idx * 2,
			Font = isLast and Theme.Fonts.Semibold or Theme.Fonts.Regular,
			Text = " " .. labelText .. " ",
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = seg.IsEllipsis and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
			TextTruncate = self.HierarchyExpanded and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
			ZIndex = 9,
		})
		Utility.AddCorner(segBtn, 2)
		local segStroke = Utility.AddStroke(segBtn, Theme.Colors.SelectionBorder, 1, 1, Enum.ApplyStrokeMode.Border)

		segBtn.MouseEnter:Connect(function()
			segBtn.BackgroundTransparency = 0.15
			segStroke.Transparency = 0.2
		end)
		segBtn.MouseLeave:Connect(function()
			segBtn.BackgroundTransparency = 1
			segStroke.Transparency = 1
		end)
		segBtn.MouseButton1Click:Connect(function()
			if seg.IsEllipsis then
				-- Clicking "..." expands full hierarchy path and enables horizontal scroll
				self.HierarchyExpanded = true
				self:_UpdateBreadcrumbs(self.ActiveTab)
			elseif not self.HierarchyExpanded and isLongHierarchy and isLast then
				self.HierarchyExpanded = true
				self:_UpdateBreadcrumbs(self.ActiveTab)
			elseif seg.Tab then
				self:SelectTab(seg.Tab)
			end
		end)

		if idx < #displaySegments then
			local arrowHolder = Utility.Create("Frame", {
				Name = "Arrow_" .. tostring(idx),
				Parent = self.BreadcrumbContainer,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 12, 0, 20),
				LayoutOrder = idx * 2 + 1,
				ZIndex = 9,
			})
			Utility.CreateVectorChevron(arrowHolder, "Right", Color3.fromRGB(86, 104, 126), 10)
		end
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
