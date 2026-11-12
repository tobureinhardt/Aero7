--!nonstrict
-- Aero7: window/AeroWindow - Standard Windows 7 Aero Glass window chrome, caption buttons, client area, snap, and resize handles.

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local DWM = require("core/DWM")
local BlurController = require("core/BlurController")

local AeroWindow = {}
AeroWindow.__index = AeroWindow

-- Renders Minimize (-), Maximize (🗖), Restore and Close (✖) glyphs with Windows 7 drop shadows
local function buildCaptionGlyph(parent, glyphType)
	local holder = Utility.Create("Frame", {
		Name = "Glyph_" .. glyphType,
		Parent = parent,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 12),
		ZIndex = parent.ZIndex + 3,
	})

	if glyphType == "Minimize" then
		-- 3px thick horizontal bar at bottom with dark shadow
		local bar = Utility.Create("Frame", {
			Name = "MinBar",
			Parent = holder,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0, 2, 1, -4),
			Size = UDim2.new(0, 10, 0, 3),
			ZIndex = holder.ZIndex + 1,
		})
		Utility.AddStroke(bar, Color3.fromRGB(28, 44, 64), 1, 0.15, Enum.ApplyStrokeMode.Border)

	elseif glyphType == "Maximize" then
		-- Hollow rectangular frame with 2px top edge
		local box = Utility.Create("Frame", {
			Name = "MaxBox",
			Parent = holder,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 2, 0, 2),
			Size = UDim2.new(0, 10, 0, 8),
			ZIndex = holder.ZIndex + 1,
		})
		Utility.AddStroke(box, Color3.fromRGB(255, 255, 255), 1.4, 0, Enum.ApplyStrokeMode.Border)
		local topThick = Utility.Create("Frame", {
			Name = "TopBar",
			Parent = box,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, 2),
			ZIndex = box.ZIndex + 1,
		})
		local outerShadow = Utility.Create("Frame", {
			Name = "OuterShadow",
			Parent = holder,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(0, 12, 0, 10),
			ZIndex = holder.ZIndex,
		})
		Utility.AddStroke(outerShadow, Color3.fromRGB(28, 44, 64), 1, 0.25, Enum.ApplyStrokeMode.Border)

		-- Dual overlapping windows for Restore Down state
		local restoreGroup = Utility.Create("Frame", {
			Name = "RestoreBox",
			Parent = holder,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			ZIndex = holder.ZIndex + 1,
		})
		local backWin = Utility.Create("Frame", {
			Name = "BackWin",
			Parent = restoreGroup,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 4, 0, 1),
			Size = UDim2.new(0, 8, 0, 6),
			ZIndex = holder.ZIndex + 1,
		})
		Utility.AddStroke(backWin, Color3.fromRGB(255, 255, 255), 1.2, 0.1, Enum.ApplyStrokeMode.Border)
		local frontWin = Utility.Create("Frame", {
			Name = "FrontWin",
			Parent = restoreGroup,
			BackgroundColor3 = Color3.fromRGB(56, 102, 152),
			BackgroundTransparency = 0.4,
			Position = UDim2.new(0, 1, 0, 4),
			Size = UDim2.new(0, 8, 0, 6),
			ZIndex = holder.ZIndex + 2,
		})
		Utility.AddStroke(frontWin, Color3.fromRGB(255, 255, 255), 1.2, 0, Enum.ApplyStrokeMode.Border)

		return {
			Holder = holder,
			SetMaximized = function(_, isMax)
				box.Visible = not isMax
				topThick.Visible = not isMax
				outerShadow.Visible = not isMax
				restoreGroup.Visible = isMax
			end,
		}

	elseif glyphType == "Close" then
		-- Crisp 2px staircase X glyph for Windows 7 Close button
		Utility.CreateVectorCloseX(holder, Color3.fromRGB(255, 255, 255), Color3.fromRGB(52, 12, 12), holder.ZIndex)
	end

	return { Holder = holder }
end

function AeroWindow.new(options)
	options = options or {}
	local self = setmetatable({}, AeroWindow)

	self.Title = options.Title or "Windows 7 Aero Application"
	self.Icon = options.Icon or "WindowDefault"
	self.LayoutMode = options.Layout or "Explorer" -- "Explorer" or "Dialog"
	self.MinSize = options.MinSize or Vector2.new(480, 320)
	self.DefaultSize = options.Size or UDim2.new(0, 680, 0, 460)
	self.DefaultPosition = options.Position or UDim2.new(0.5, -340, 0.5, -230)
	self.ToggleKey = options.ToggleKey or options.AccessKey or Enum.KeyCode.RightShift
	self.CustomGlassColor = options.GlassColor
	self.CustomGlassTransparency = options.GlassTransparency

	self.IsVisible = (options.Visible ~= false)
	self.IsMinimized = false
	self.IsMaximized = false
	self.IsActive = true
	self.SavedBounds = {
		Position = self.DefaultPosition,
		Size = self.DefaultSize,
	}

	self.OnClosed = Utility.CreateSignal()
	self.OnMinimized = Utility.CreateSignal()
	self.OnMaximized = Utility.CreateSignal()
	self.OnFocused = Utility.CreateSignal()

	-- Root ScreenGui
	local guiParent = options.Parent or Utility.GetSafeGuiParent()
	local screenGui = Utility.Create("ScreenGui", {
		Name = "Win7Aero_" .. tostring(self.Title):gsub("%W", ""),
		Parent = guiParent,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
	})
	self.ScreenGui = screenGui

	-- Aero Snap preview frame when dragging window to screen edge
	self.SnapPreview = DWM.CreateSnapPreview(screenGui)

	-- 1. Primary Aero Glass window frame
	local windowFrame = Utility.Create("Frame", {
		Name = "AeroWindowFrame",
		Parent = screenGui,
		BackgroundColor3 = Color3.fromRGB(25, 42, 65),
		BackgroundTransparency = 0.85,
		Position = self.DefaultPosition,
		Size = self.DefaultSize,
		Active = true,
		ZIndex = 10,
	})
	self.WindowFrame = windowFrame

	local windowScale = Instance.new("UIScale")
	windowScale.Scale = 1
	windowScale.Parent = windowFrame
	self.WindowScale = windowScale

	-- Standard DWM dual-layer bevel (1px outer dark + 1px inner silver highlight)
	local outerStroke, innerStroke, innerBevel = Utility.ApplyDualBevel(
		windowFrame,
		Theme.Colors.WindowOuterBorder,
		0.35,
		Theme.Colors.WindowInnerHighlight,
		0.16,
		8
	)
	self.OuterStroke = outerStroke
	self.InnerStroke = innerStroke
	self.InnerBevel = innerBevel

	-- DWM glass layers (Tint, Top Gloss, 104° Specular Sheen, Frost Rim, Multi-layer DropShadow)
	self.GlassLayers = DWM.BuildAeroGlassLayers(windowFrame)

	-- Real glass blur controller (DepthOfField near-plane refraction standard)
	self.BlurEnabled = (options.Blur ~= false)
	self.BlurIntensity = options.BlurIntensity or 0.25
	self.BlurSize = options.BlurSize

	if self.BlurEnabled then
		local ok, blurInstance = pcall(function()
			return BlurController.new(windowFrame, options.BlurShape or "Rectangle", {
				BlurSize = self.BlurSize,
				Intensity = self.BlurIntensity,
			})
		end)
		if ok and blurInstance then
			self.BlurInstance = blurInstance
			if not self.IsVisible then
				blurInstance:SetVisible(false)
			end
		end
	end

	-- 2. Title Bar (Height: 30px)
	local titleBar = Utility.Create("Frame", {
		Name = "TitleBar",
		Parent = windowFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 30),
		Active = true,
		ZIndex = 5,
	})
	self.TitleBar = titleBar

	-- Transparent drag hit zone across titlebar (excluding right-side caption buttons) for reliable touch and mouse dragging
	local titleDragHitBox = Utility.Create("TextButton", {
		Name = "TitleDragHitBox",
		Parent = titleBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -110, 1, 0),
		Text = "",
		ZIndex = 7,
	})
	self.TitleDragHitBox = titleDragHitBox

	-- 16x16 window icon at top-left of titlebar
	local titleIcon = Utility.Create("ImageLabel", {
		Name = "WindowIcon",
		Parent = titleBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 9, 0, 7),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 6,
	})
	Assets.BindIcon(titleIcon, self.Icon)
	self.TitleIcon = titleIcon

	-- Title text with DWM glow halo
	self.TitleController = Utility.CreateGlowingTitle(titleBar, self.Title, 6)

	-- 3. 3 Caption Buttons anchored to top edge (Minimize 27x19, Maximize 27x19, Close 47x19)
	self:_BuildCaptionButtons(titleBar)

	-- 4. Client Area (8px padding from left/right/bottom, 30px from top)
	-- In Explorer mode (DwmExtendFrameIntoClientArea), outer frame is transparent so navigation bar floats directly on Aero Glass
	local isDialogLayout = (tostring(self.LayoutMode):lower() == "dialog" or tostring(self.LayoutMode):lower() == "tabbed" or tostring(self.LayoutMode):lower() == "propertysheet")
	local clientOuter = Utility.Create("Frame", {
		Name = "ClientOuterFrame",
		Parent = windowFrame,
		BackgroundColor3 = isDialogLayout and Theme.Colors.DialogFaceBg or Theme.Colors.ExplorerClientBg,
		BackgroundTransparency = isDialogLayout and 0 or 1,
		Position = UDim2.new(0, 8, 0, isDialogLayout and 30 or 26),
		Size = UDim2.new(1, -16, 1, isDialogLayout and -38 or -34),
		ClipsDescendants = true,
		ZIndex = 4,
	})
	self.ClientOuterFrame = clientOuter

	-- Client area border (for Explorer mode, top glass merges into titlebar so border begins at Y = 60 below navigation bar)
	local clientBorderBox = isDialogLayout and clientOuter or Utility.Create("Frame", {
		Name = "ExplorerClientSurfaceBorder",
		Parent = windowFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 60),
		Size = UDim2.new(1, -16, 1, -68),
		ZIndex = 6,
	})
	local clientStroke = Utility.AddStroke(
		clientBorderBox,
		Theme.Colors.ClientOuterBorder,
		1,
		0.15,
		Enum.ApplyStrokeMode.Border
	)
	self.ClientStroke = clientStroke

	local clientRimHighlight = Utility.Create("Frame", {
		Name = "ClientGlassRimHighlight",
		Parent = windowFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 7, 0, isDialogLayout and 29 or 59),
		Size = UDim2.new(1, -14, 1, isDialogLayout and -36 or -66),
		ZIndex = 3,
	})
	Utility.AddStroke(clientRimHighlight, Theme.Colors.ClientInnerHighlight, 1, 0.55, Enum.ApplyStrokeMode.Border)

	-- 5. Minimized Aero Titlebar Stub (standalone floating stub)
	self:_BuildMinimizedStub()

	-- 6. Responsive screen fitting (Mobile & PC), drag handling, and 8-way resize
	self:_FitToViewport()
	self:_SetupDragAndSnap()
	self:_SetupResizeHandles()

	-- Re-clamps on screen rotation or viewport resolution change
	pcall(function()
		local cam = Workspace.CurrentCamera
		if cam and cam.GetPropertyChangedSignal then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				if not self.IsMaximized then
					self:_FitToViewport()
				end
			end)
		end
	end)

	-- Focus window on any click within frame
	windowFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			DWM:FocusWindow(self)
		end
	end)

	-- Toggle visibility hotkey (default RightShift)
	self._KeybindConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and self.ToggleKey and input.KeyCode == self.ToggleKey then
			self:ToggleVisibility()
		end
	end)

	-- Registers with DWM and applies glass color (AnimateOpen invoked after interior layout construction)
	DWM:RegisterWindow(self)
	self:_RefreshGlassAppearance()
	if not self.IsVisible then
		windowFrame.Visible = false
	end

	return self
end

-- Builds standard Windows 7 top-anchored caption buttons
function AeroWindow:_BuildCaptionButtons(titleBar)
	-- Caption button cluster container (Top = 0, Right = -8, Width = 101, Height = 20)
	local clusterWrap = Utility.Create("Frame", {
		Name = "CaptionButtonsCluster",
		Parent = titleBar,
		BackgroundColor3 = Color3.fromRGB(18, 32, 48),
		BackgroundTransparency = 0.65,
		Position = UDim2.new(1, -109, 0, 0),
		Size = UDim2.new(0, 101, 0, 20),
		ZIndex = 7,
	})
	Utility.AddCorner(clusterWrap, 4)
	Utility.AddStroke(clusterWrap, Color3.fromRGB(16, 26, 38), 1, 0.22, Enum.ApplyStrokeMode.Border)
	self.CaptionCluster = clusterWrap

	-- Clips top rounded corners for flush alignment with window edge
	local topEdgeMask = Utility.Create("Frame", {
		Name = "TopEdgeFlushLine",
		Parent = clusterWrap,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.55,
		Position = UDim2.new(0, 1, 0, 0),
		Size = UDim2.new(1, -2, 0, 1),
		ZIndex = 9,
	})

	-- Close button red radial halo (7.css box-shadow: 0 0 7px 3px #e68e75)
	local closeRedHalo = Utility.Create("Frame", {
		Name = "CloseRedGlowHalo",
		Parent = clusterWrap,
		BackgroundColor3 = Color3.fromRGB(230, 142, 117),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 54, 0, 0),
		Size = UDim2.new(0, 47, 1, 0),
		ZIndex = 6,
	})
	local closeGlowCtrl = Utility.AttachGaussianGlow(closeRedHalo, Color3.fromRGB(230, 142, 117), 3, 9)

	-- Minimize / Maximize cyan radial halo (7.css box-shadow: 0 0 7px 3px #5dc4f0)
	local minMaxBlueHalo = Utility.Create("Frame", {
		Name = "MinMaxBlueGlowHalo",
		Parent = clusterWrap,
		BackgroundColor3 = Color3.fromRGB(93, 196, 240),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 27, 1, 0),
		ZIndex = 6,
	})
	local minMaxGlowCtrl = Utility.AttachGaussianGlow(minMaxBlueHalo, Color3.fromRGB(93, 196, 240), 3, 8)

	local function createCaptionBtn(name, xOffset, width, isCloseBtn)
		local btn = Utility.Create("TextButton", {
			Name = name .. "Button",
			Parent = clusterWrap,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = isCloseBtn and 0.14 or 0.58,
			Position = UDim2.new(0, xOffset, 0, 0),
			Size = UDim2.new(0, width, 1, 0),
			Text = "",
			ZIndex = 8,
		})
		Utility.AddCorner(btn, 3)

		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Color = isCloseBtn and Theme.Gradients.CloseButtonNormal or Theme.MakeSplitSequence(
			Color3.fromRGB(245, 250, 255),
			Color3.fromRGB(210, 228, 245),
			Color3.fromRGB(145, 175, 205),
			Color3.fromRGB(185, 212, 238)
		)
		grad.Parent = btn

		local innerRim = Utility.Create("Frame", {
			Name = "InnerHighlight",
			Parent = btn,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 1, 0, 1),
			Size = UDim2.new(1, -2, 1, -2),
			ZIndex = 9,
		})
		Utility.AddCorner(innerRim, 2)
		local innerStroke = Utility.AddStroke(innerRim, Color3.fromRGB(255, 255, 255), 1, 0.45, Enum.ApplyStrokeMode.Border)

		local glyphCtrl = buildCaptionGlyph(btn, name)

		btn.MouseEnter:Connect(function()
			if isCloseBtn then
				grad.Color = Theme.Gradients.CloseButtonHover
				Utility.Tween(btn, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
					BackgroundTransparency = 0.02,
				})
				innerStroke.Color = Color3.fromRGB(255, 215, 200)
				innerStroke.Transparency = 0.15
				closeGlowCtrl:Fade(1, 0.12)
			else
				grad.Color = Theme.Gradients.CaptionButtonHover
				Utility.Tween(btn, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
					BackgroundTransparency = 0.08,
				})
				innerStroke.Color = Color3.fromRGB(215, 245, 255)
				innerStroke.Transparency = 0.15
				minMaxBlueHalo.Position = UDim2.new(0, xOffset, 0, 0)
				minMaxBlueHalo.Size = UDim2.new(0, width, 1, 0)
				minMaxGlowCtrl:Fade(1, 0.12)
			end
		end)

		btn.MouseLeave:Connect(function()
			if isCloseBtn then
				grad.Color = Theme.Gradients.CloseButtonNormal
				Utility.Tween(btn, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
					BackgroundTransparency = self.IsActive and 0.14 or 0.45,
				})
				innerStroke.Color = Color3.fromRGB(255, 255, 255)
				innerStroke.Transparency = 0.45
				closeGlowCtrl:Fade(0, 0.20)
			else
				grad.Color = Theme.MakeSplitSequence(
					Color3.fromRGB(245, 250, 255),
					Color3.fromRGB(210, 228, 245),
					Color3.fromRGB(145, 175, 205),
					Color3.fromRGB(185, 212, 238)
				)
				Utility.Tween(btn, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
					BackgroundTransparency = 0.58,
				})
				innerStroke.Color = Color3.fromRGB(255, 255, 255)
				innerStroke.Transparency = 0.45
				minMaxGlowCtrl:Fade(0, 0.20)
			end
		end)

		btn.MouseButton1Down:Connect(function()
			if isCloseBtn then
				grad.Color = Theme.Gradients.CloseButtonPressed
			else
				grad.Color = Theme.Gradients.CaptionButtonPressed
			end
		end)

		return btn, glyphCtrl, grad
	end

	-- 1px separator line between caption buttons
	local function addDivider(xPos)
		Utility.Create("Frame", {
			Name = "CaptionDivider",
			Parent = clusterWrap,
			BackgroundColor3 = Color3.fromRGB(22, 36, 52),
			BackgroundTransparency = 0.25,
			Position = UDim2.new(0, xPos, 0, 0),
			Size = UDim2.new(0, 1, 1, 0),
			ZIndex = 10,
		})
	end

	local minBtn = createCaptionBtn("Minimize", 0, 27, false)
	addDivider(27)
	local maxBtn, maxGlyph = createCaptionBtn("Maximize", 27, 27, false)
	addDivider(54)
	local closeBtn, _, closeGrad = createCaptionBtn("Close", 54, 47, true)

	self.MinimizeButton = minBtn
	self.MaximizeButton = maxBtn
	self.MaximizeGlyph = maxGlyph
	self.CloseButton = closeBtn
	self.CloseButtonGradient = closeGrad

	minBtn.MouseButton1Click:Connect(function()
		self:Minimize()
	end)

	maxBtn.MouseButton1Click:Connect(function()
		self:ToggleMaximize()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		self:Close()
	end)
end

-- Builds compact floating Aero Titlebar Stub when minimized
function AeroWindow:_BuildMinimizedStub()
	local stub = Utility.Create("Frame", {
		Name = "MinimizedAeroStub",
		Parent = self.ScreenGui,
		BackgroundColor3 = Theme.CurrentGlass.Color,
		BackgroundTransparency = Theme.CurrentGlass.Transparency,
		Position = UDim2.new(0, 18, 1, -44),
		Size = UDim2.new(0, 220, 0, 28),
		Visible = false,
		Active = true,
		ZIndex = 20,
	})
	Utility.ApplyDualBevel(stub, Theme.Colors.WindowOuterBorder, 0.32, Theme.Colors.WindowInnerHighlight, 0.16, 6)

	local stubSheen = Utility.Create("Frame", {
		Name = "StubSheen",
		Parent = stub,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.65,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 0, 13),
		ZIndex = 21,
	})
	Utility.AddCorner(stubSheen, 5)

	local stubIcon = Utility.Create("ImageLabel", {
		Name = "StubIcon",
		Parent = stub,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 6),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = 22,
	})
	Assets.BindIcon(stubIcon, self.Icon)

	local stubTitle = Utility.CreateGlowingTitle(stub, self.Title, 22)
	stubTitle.Container.Position = UDim2.new(0, 28, 0, 0)
	stubTitle.Container.Size = UDim2.new(1, -86, 1, 0)
	self.StubTitleController = stubTitle

	-- Restore & Close buttons on stub
	local restoreBtn = Utility.Create("TextButton", {
		Name = "RestoreButton",
		Parent = stub,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.45,
		Position = UDim2.new(1, -54, 0, 4),
		Size = UDim2.new(0, 24, 0, 20),
		Text = "",
		ZIndex = 23,
	})
	Utility.AddCorner(restoreBtn, 3)
	Utility.AddStroke(restoreBtn, Color3.fromRGB(32, 54, 78), 1, 0.3, Enum.ApplyStrokeMode.Border)
	local restoreGlyph = buildCaptionGlyph(restoreBtn, "Maximize")
	restoreGlyph:SetMaximized(true)

	local closeStubBtn = Utility.Create("TextButton", {
		Name = "CloseStubButton",
		Parent = stub,
		BackgroundColor3 = Color3.fromRGB(214, 54, 42),
		BackgroundTransparency = 0.15,
		Position = UDim2.new(1, -28, 0, 4),
		Size = UDim2.new(0, 24, 0, 20),
		Text = "",
		ZIndex = 23,
	})
	Utility.AddCorner(closeStubBtn, 3)
	Utility.AddStroke(closeStubBtn, Color3.fromRGB(64, 16, 12), 1, 0.25, Enum.ApplyStrokeMode.Border)
	buildCaptionGlyph(closeStubBtn, "Close")

	restoreBtn.MouseButton1Click:Connect(function()
		self:Restore()
	end)

	closeStubBtn.MouseButton1Click:Connect(function()
		self:Close()
	end)

	-- Allows dragging stub or double-clicking to restore
	local draggingStub = false
	local dragStartPos, stubStartPos
	stub.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingStub = true
			dragStartPos = input.Position
			stubStartPos = stub.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if draggingStub and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStartPos
			stub.Position = UDim2.new(
				stubStartPos.X.Scale,
				stubStartPos.X.Offset + delta.X,
				stubStartPos.Y.Scale,
				stubStartPos.Y.Offset + delta.Y
			)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingStub = false
		end
	end)

	self.MinimizedStub = stub
end

-- Auto-fits and clamps window bounds within screen (mobile and desktop)
function AeroWindow:_FitToViewport()
	local cam = Workspace and Workspace.CurrentCamera
	local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
	if vp.X <= 0 or vp.Y <= 0 then
		vp = Vector2.new(1280, 720)
	end

	local isCompactScreen = (vp.Y < 540 or vp.X < 860)
	local marginX = isCompactScreen and 20 or 10
	local marginY = isCompactScreen and 18 or 8
	local availW = math.max(260, vp.X - marginX * 2)
	local availH = math.max(190, vp.Y - marginY * 2)

	-- On small screens/mobile: caps maximum dimensions to ~78% width and ~80% height
	-- ensuring sufficient surrounding space for free movement without accidental Aero Snap triggers
	if isCompactScreen then
		availW = math.min(availW, math.max(320, math.floor(vp.X * 0.78)))
		availH = math.min(availH, math.max(210, math.floor(vp.Y * 0.80)))
	end

	-- Responsive MinSize adjustment for small screens
	self.MinSize = Vector2.new(
		math.min(self.MinSize.X, math.max(260, math.floor(availW * 0.72))),
		math.min(self.MinSize.Y, math.max(185, math.floor(availH * 0.72)))
	)

	local defSize = self.DefaultSize
	local reqW = math.floor(vp.X * defSize.X.Scale + defSize.X.Offset)
	local reqH = math.floor(vp.Y * defSize.Y.Scale + defSize.Y.Offset)
	if reqW <= 0 then reqW = 680 end
	if reqH <= 0 then reqH = 460 end

	local finalW = math.clamp(reqW, self.MinSize.X, availW)
	local finalH = math.clamp(reqH, self.MinSize.Y, availH)

	local defPos = self.DefaultPosition
	local reqX = math.floor(vp.X * defPos.X.Scale + defPos.X.Offset)
	local reqY = math.floor(vp.Y * defPos.Y.Scale + defPos.Y.Offset)

	-- Centers window within safe viewport area when shrunk for mobile
	if isCompactScreen or reqW > availW then
		reqX = math.floor((vp.X - finalW) * 0.5)
	end
	if isCompactScreen or reqH > availH then
		reqY = math.floor((vp.Y - finalH) * 0.5)
	end

	local finalX = math.clamp(reqX, marginX, math.max(marginX, vp.X - finalW - marginX))
	local finalY = math.clamp(reqY, marginY, math.max(marginY, vp.Y - finalH - marginY))

	self.WindowFrame.Size = UDim2.new(0, finalW, 0, finalH)
	self.WindowFrame.Position = UDim2.new(0, finalX, 0, finalY)
	DWM.RestPositions[self.WindowFrame] = self.WindowFrame.Position
	self.SavedBounds = {
		Position = self.WindowFrame.Position,
		Size = self.WindowFrame.Size,
	}
end

-- Window drag handler with specular parallax and Aero Snap support
function AeroWindow:_SetupDragAndSnap()
	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startOffsetX = 0
	local startOffsetY = 0
	local hasMovedEnoughForSnap = false
	local lastClickTime = 0

	local function beginDragFromInput(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		DWM:FocusWindow(self)

		-- Double-click maximize enabled only for PC mouse input
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local now = os.clock()
			if now - lastClickTime < 0.26 then
				self:ToggleMaximize()
				lastClickTime = 0
				return
			end
			lastClickTime = now
		end

		local cam = Workspace and Workspace.CurrentCamera
		local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)

		-- Pulling down from maximized state restores window smoothly beneath cursor/touch
		if self.IsMaximized then
			local restoreW = self.SavedBounds.Size.X.Offset > 0 and self.SavedBounds.Size.X.Offset or math.min(680, vp.X - 20)
			local ratioX = math.clamp(input.Position.X / math.max(vp.X, 1), 0.15, 0.85)
			self.IsMaximized = false
			if self.MaximizeGlyph then
				self.MaximizeGlyph:SetMaximized(false)
			end
			self.GlassLayers.ShadowOuter.Visible = true
			self.GlassLayers.ShadowMid.Visible = true
			self.WindowFrame.Size = self.SavedBounds.Size
			self.WindowFrame.Position = UDim2.new(0, math.floor(input.Position.X - restoreW * ratioX), 0, math.max(12, input.Position.Y - 14))
		end

		-- Converts position to absolute pixel offsets for scale-independent dragging
		local curPos = self.WindowFrame.Position
		startOffsetX = math.floor(vp.X * curPos.X.Scale + curPos.X.Offset)
		startOffsetY = math.floor(vp.Y * curPos.Y.Scale + curPos.Y.Offset)
		self.WindowFrame.Position = UDim2.new(0, startOffsetX, 0, startOffsetY)

		dragging = true
		hasMovedEnoughForSnap = false
		dragInput = input
		dragStart = input.Position

		if input.Changed then
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end

	function self:BindDragHandle(guiObject)
		if not guiObject or not guiObject.InputBegan then
			return
		end
		guiObject.InputBegan:Connect(beginDragFromInput)
	end

	self:BindDragHandle(self.TitleBar)
	if self.TitleDragHitBox then
		self:BindDragHandle(self.TitleDragHitBox)
	end

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local cam = Workspace and Workspace.CurrentCamera
			local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
			local delta = input.Position - dragStart
			if delta.Magnitude >= 18 then
				hasMovedEnoughForSnap = true
			end

			local winW = self.WindowFrame.Size.X.Offset > 0 and self.WindowFrame.Size.X.Offset or self.WindowFrame.AbsoluteSize.X

			-- Clamps titlebar within viewport bounds
			local newX = math.clamp(startOffsetX + delta.X, -winW + 96, vp.X - 96)
			local newY = math.clamp(startOffsetY + delta.Y, 2, math.max(2, vp.Y - 34))
			self.WindowFrame.Position = UDim2.new(0, newX, 0, newY)
			DWM.RestPositions[self.WindowFrame] = self.WindowFrame.Position

			-- Updates specular sheen parallax across glass surface
			DWM.UpdateSpecularParallax(self.GlassLayers, newX, newY)

			-- Triggers Aero Snap only on PC mouse drag beyond 18px threshold
			-- (disabled on touch to prevent accidental fullscreen snapping while panning)
			local isTouchDrag = (dragInput and dragInput.UserInputType == Enum.UserInputType.Touch)
				or (input.UserInputType == Enum.UserInputType.Touch)
			if not isTouchDrag and hasMovedEnoughForSnap then
				local mx, my = input.Position.X, input.Position.Y
				if my <= 4 then
					self.SnapPreview:ShowZone("TopMaximize", UDim2.new(0, 4, 0, 4), UDim2.new(1, -8, 1, -8), self.WindowFrame.Position)
				elseif mx <= 4 then
					self.SnapPreview:ShowZone("LeftHalf", UDim2.new(0, 4, 0, 4), UDim2.new(0.5, -6, 1, -8), self.WindowFrame.Position)
				elseif mx >= vp.X - 4 then
					self.SnapPreview:ShowZone("RightHalf", UDim2.new(0.5, 2, 0, 4), UDim2.new(0.5, -6, 1, -8), self.WindowFrame.Position)
				else
					self.SnapPreview:Hide()
				end
			else
				self.SnapPreview:Hide()
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not dragging then
			return
		end
		if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			local snapZone = self.SnapPreview.ActiveZone
			self.SnapPreview:Hide()

			if snapZone == "TopMaximize" then
				self:Maximize()
			elseif snapZone == "LeftHalf" then
				self.SavedBounds = {
					Position = self.WindowFrame.Position,
					Size = self.WindowFrame.Size,
				}
				Utility.Tween(self.WindowFrame, 0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0.5, 0, 1, 0),
				})
			elseif snapZone == "RightHalf" then
				self.SavedBounds = {
					Position = self.WindowFrame.Position,
					Size = self.WindowFrame.Size,
				}
				Utility.Tween(self.WindowFrame, 0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
					Position = UDim2.new(0.5, 0, 0, 0),
					Size = UDim2.new(0.5, 0, 1, 0),
				})
			end
		end
	end)
end

-- Configures 8-way resize handles with 16x16 corner hitboxes
function AeroWindow:_SetupResizeHandles()
	local handleDefs = {
		{ Name = "Right",       Pos = UDim2.new(1, -6, 0, 12), Size = UDim2.new(0, 8, 1, -28), DX = 0, DY = 0, DW = 1, DH = 0 },
		{ Name = "Bottom",      Pos = UDim2.new(0, 12, 1, -6), Size = UDim2.new(1, -28, 0, 8), DX = 0, DY = 0, DW = 0, DH = 1 },
		{ Name = "Left",        Pos = UDim2.new(0, -2, 0, 12), Size = UDim2.new(0, 8, 1, -28), DX = 1, DY = 0, DW = -1, DH = 0 },
		{ Name = "Top",         Pos = UDim2.new(0, 12, 0, -2), Size = UDim2.new(1, -125, 0, 6), DX = 0, DY = 1, DW = 0, DH = -1 },
		{ Name = "BottomRight", Pos = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 18, 0, 18), DX = 0, DY = 0, DW = 1, DH = 1 },
		{ Name = "BottomLeft",  Pos = UDim2.new(0, -2, 1, -16), Size = UDim2.new(0, 16, 0, 16), DX = 1, DY = 0, DW = -1, DH = 1 },
		{ Name = "TopLeft",     Pos = UDim2.new(0, -2, 0, -2), Size = UDim2.new(0, 14, 0, 14), DX = 1, DY = 1, DW = -1, DH = -1 },
	}

	local activeHandle = nil
	local startMouse = nil
	local startX, startY, startW, startH = 0, 0, 0, 0

	for _, def in ipairs(handleDefs) do
		local grip = Utility.Create("TextButton", {
			Name = "ResizeGrip_" .. def.Name,
			Parent = self.WindowFrame,
			BackgroundTransparency = 1,
			Position = def.Pos,
			Size = def.Size,
			Text = "",
			ZIndex = 15,
		})

		grip.InputBegan:Connect(function(input)
			if self.IsMaximized then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				DWM:FocusWindow(self)
				local cam = Workspace and Workspace.CurrentCamera
				local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)

				-- Uses WindowFrame Position/Size coordinates to avoid layout drift across varying UIScales
				-- preserving exact position during resize
				local pos = self.WindowFrame.Position
				local size = self.WindowFrame.Size
				startX = math.floor(vp.X * pos.X.Scale + pos.X.Offset)
				startY = math.floor(vp.Y * pos.Y.Scale + pos.Y.Offset)
				startW = math.floor(vp.X * size.X.Scale + size.X.Offset)
				startH = math.floor(vp.Y * size.Y.Scale + size.Y.Offset)
				self.WindowFrame.Position = UDim2.new(0, startX, 0, startY)
				self.WindowFrame.Size = UDim2.new(0, startW, 0, startH)

				activeHandle = def
				startMouse = input.Position
			end
		end)
	end

	UserInputService.InputChanged:Connect(function(input)
		if not activeHandle then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local cam = Workspace and Workspace.CurrentCamera
			local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
			local delta = input.Position - startMouse
			local edge = 4
			local topEdge = 2

			-- Horizontal: dragging left anchor keeps right edge stationary; dragging right keeps left stationary
			local newW = startW + delta.X * activeHandle.DW
			local maxW = (activeHandle.DX ~= 0) and (startX + startW - edge) or (vp.X - startX - edge)
			newW = math.clamp(newW, math.min(self.MinSize.X, maxW), math.max(self.MinSize.X, maxW))
			local newX = (activeHandle.DX ~= 0) and (startX + startW - newW) or startX

			-- Vertical: adjusts height only without shifting window position when dragging bottom handles
			local newH = startH + delta.Y * activeHandle.DH
			local maxH = (activeHandle.DY ~= 0) and (startY + startH - topEdge) or (vp.Y - startY - edge)
			newH = math.clamp(newH, math.min(self.MinSize.Y, maxH), math.max(self.MinSize.Y, maxH))
			local newY = (activeHandle.DY ~= 0) and (startY + startH - newH) or startY

			self.WindowFrame.Position = UDim2.new(0, newX, 0, newY)
			self.WindowFrame.Size = UDim2.new(0, newW, 0, newH)
			DWM.RestPositions[self.WindowFrame] = self.WindowFrame.Position
			DWM.UpdateSpecularParallax(self.GlassLayers, newX, newY)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if activeHandle then
				self.SavedBounds = {
					Position = self.WindowFrame.Position,
					Size = self.WindowFrame.Size,
				}
			end
			activeHandle = nil
		end
	end)
end

-- Synchronizes window focus state with DWM
function AeroWindow:_ApplyFocusState(isFocused)
	self.IsActive = isFocused
	self.TitleController:SetActive(isFocused)

	local glassColor = self.CustomGlassColor or Theme.CurrentGlass.Color
	local glassTrans = self.CustomGlassTransparency or Theme.CurrentGlass.Transparency

	if isFocused then
		Utility.Tween(self.GlassLayers.TintLayer, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
			BackgroundColor3 = glassColor,
			BackgroundTransparency = glassTrans,
		})
		self.OuterStroke.Transparency = 0.35
		self.InnerStroke.Transparency = 0.16
		if self.GlassLayers.ShadowSlice then
			self.GlassLayers.ShadowSlice.ImageTransparency = 0.04
		end
		if self.GlassLayers.ShadowRings then
			for _, ring in ipairs(self.GlassLayers.ShadowRings) do
				ring.Stroke.Transparency = ring.ActiveTrans
			end
		end
		if self.CloseButton then
			self.CloseButton.BackgroundTransparency = 0.14
		end
	else
		-- Inactive window desaturates to light silver-blue with softened shadow
		Utility.Tween(self.GlassLayers.TintLayer, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
			BackgroundColor3 = Theme.CurrentGlass.InactiveColor,
			BackgroundTransparency = Theme.CurrentGlass.InactiveTransparency,
		})
		self.OuterStroke.Transparency = 0.58
		self.InnerStroke.Transparency = 0.48
		if self.GlassLayers.ShadowSlice then
			self.GlassLayers.ShadowSlice.ImageTransparency = 0.45
		end
		if self.GlassLayers.ShadowRings then
			for _, ring in ipairs(self.GlassLayers.ShadowRings) do
				ring.Stroke.Transparency = ring.InactiveTrans
			end
		end
		if self.CloseButton then
			self.CloseButton.BackgroundTransparency = 0.45
		end
	end

	self.OnFocused:Fire(isFocused)
end

-- Updates Aero Glass accent tint
function AeroWindow:_RefreshGlassAppearance()
	local glassColor = self.CustomGlassColor or Theme.CurrentGlass.Color
	local glassTrans = self.CustomGlassTransparency or Theme.CurrentGlass.Transparency
	local glowColor = Theme.CurrentGlass.Glow

	if self.IsActive then
		self.GlassLayers.TintLayer.BackgroundColor3 = glassColor
		self.GlassLayers.TintLayer.BackgroundTransparency = glassTrans
	end
	self.GlassLayers.FrostStroke.Color = glowColor
	if self.MinimizedStub then
		self.MinimizedStub.BackgroundColor3 = glassColor
		self.MinimizedStub.BackgroundTransparency = glassTrans
	end
end

function AeroWindow:SetGlassColor(color3, transparency)
	if type(color3) == "string" and Theme.GlassPresetByName[color3] then
		local p = Theme.GlassPresetByName[color3]
		self.CustomGlassColor = p.Color
		self.CustomGlassTransparency = transparency or p.Transparency
	else
		self.CustomGlassColor = color3
		if transparency ~= nil then
			self.CustomGlassTransparency = math.clamp(transparency, 0.05, 0.85)
		end
	end
	self:_RefreshGlassAppearance()
end

function AeroWindow:SetTitle(newTitle)
	self.Title = tostring(newTitle or "")
	self.TitleController:SetText(self.Title)
	if self.StubTitleController then
		self.StubTitleController:SetText(self.Title)
	end
end

function AeroWindow:SetIcon(iconNameOrAssetId)
	self.Icon = iconNameOrAssetId
	Assets.BindIcon(self.TitleIcon, iconNameOrAssetId)
end

-- Minimizes window to floating Aero Stub (synchronized DWM FadeOut + Scale 0.85)
function AeroWindow:Minimize()
	if self.IsMinimized then
		return
	end
	self.IsMinimized = true
	if self.BlurInstance then
		self.BlurInstance:SetVisible(false)
	end
	if not self.IsMaximized then
		self.SavedBounds = {
			Position = self.WindowFrame.Position,
			Size = self.WindowFrame.Size,
		}
	end

	local tok = DWM.NextAnimToken(self.WindowFrame)
	local stubPos = self.MinimizedStub.Position
	DWM.FadeOut(self.WindowFrame, 0.16)
	Utility.Tween(self.WindowScale, 0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.In, {
		Scale = 0.85,
	})
	Utility.Tween(self.WindowFrame, 0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.In, {
		Position = UDim2.new(
			stubPos.X.Scale,
			stubPos.X.Offset,
			stubPos.Y.Scale,
			stubPos.Y.Offset - 16
		),
	})

	task.delay(0.18, function()
		if self.IsMinimized and DWM.GetAnimToken(self.WindowFrame) == tok then
			self.WindowFrame.Visible = false
			DWM.RestoreFade(self.WindowFrame)
			self.WindowFrame.Position = self.SavedBounds.Position
			self.WindowScale.Scale = 1.0
			self.MinimizedStub.Visible = true
		end
	end)

	self.OnMinimized:Fire(true)
end

-- Restores window from stub (synchronized DWM FadeIn + Scale 0.88 -> 1.0)
function AeroWindow:Restore()
	if not self.IsMinimized then
		return
	end
	self.IsMinimized = false
	if self.BlurInstance then
		self.BlurInstance:SetVisible(true)
	end
	self.MinimizedStub.Visible = false
	DWM.NextAnimToken(self.WindowFrame)
	self.WindowFrame.Visible = true

	local targetBounds = self.IsMaximized and {
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
	} or self.SavedBounds

	self.WindowFrame.Size = targetBounds.Size
	self.WindowFrame.Position = targetBounds.Position
	DWM.FadeIn(self.WindowFrame, 0.17)
	self.WindowScale.Scale = 0.88
	Utility.Tween(self.WindowScale, 0.17, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
		Scale = 1.0,
	})
	DWM:FocusWindow(self)
	self.OnMinimized:Fire(false)
end

-- Maximizes window to fullscreen
function AeroWindow:Maximize()
	if self.IsMaximized then
		return
	end
	self.SavedBounds = {
		Position = self.WindowFrame.Position,
		Size = self.WindowFrame.Size,
	}
	self.IsMaximized = true
	if self.MaximizeGlyph then
		self.MaximizeGlyph:SetMaximized(true)
	end
	self.GlassLayers.ShadowOuter.Visible = false
	self.GlassLayers.ShadowMid.Visible = false

	Utility.Tween(self.WindowFrame, 0.18, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
	})
	self.OnMaximized:Fire(true)
end

-- Restores window to normal dimensions (Restore Down)
function AeroWindow:RestoreDown()
	if not self.IsMaximized then
		return
	end
	self.IsMaximized = false
	if self.MaximizeGlyph then
		self.MaximizeGlyph:SetMaximized(false)
	end
	self.GlassLayers.ShadowOuter.Visible = true
	self.GlassLayers.ShadowMid.Visible = true

	Utility.Tween(self.WindowFrame, 0.18, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
		Position = self.SavedBounds.Position,
		Size = self.SavedBounds.Size,
	})
	self.OnMaximized:Fire(false)
end

function AeroWindow:ToggleMaximize()
	if self.IsMaximized then
		self:RestoreDown()
	else
		self:Maximize()
	end
end

function AeroWindow:ToggleVisibility(state)
	local nextState = state
	if nextState == nil then
		nextState = not self.IsVisible
	end
	self.IsVisible = nextState
	if self.BlurInstance then
		self.BlurInstance:SetVisible(nextState)
	end

	if nextState then
		if self.IsMinimized then
			self:Restore()
		else
			DWM.AnimateOpen(self.WindowFrame, self.WindowScale, self.GlassLayers)
			DWM:FocusWindow(self)
		end
	else
		self.MinimizedStub.Visible = false
		if not self.WindowFrame.Visible then
			return
		end
		DWM.AnimateClose(self.WindowFrame, self.WindowScale, nil, self.GlassLayers)
	end
end

function AeroWindow:SetIcon(iconNameOrAssetId)
	self.Icon = iconNameOrAssetId or "WindowDefault"
	if self.TitleIcon then
		Assets.BindIcon(self.TitleIcon, self.Icon)
	end
end

function AeroWindow:Close()
	self.IsVisible = false
	if self.BlurInstance then
		self.BlurInstance:SetVisible(false)
	end
	self.MinimizedStub.Visible = false
	DWM.AnimateClose(self.WindowFrame, self.WindowScale, function()
		self.OnClosed:Fire()
	end, self.GlassLayers)
end

function AeroWindow:Destroy()
	if self.BlurInstance then
		self.BlurInstance:Destroy()
		self.BlurInstance = nil
	end
	if self._KeybindConn then
		self._KeybindConn:Disconnect()
		self._KeybindConn = nil
	end
	DWM:UnregisterWindow(self)
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

return AeroWindow
