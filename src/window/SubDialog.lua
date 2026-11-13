--!nonstrict
-- Aero7: window/SubDialog - Windows 7 TaskDialog / MessageBox modal with white content area and button footer.

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local DWM = require("core/DWM")

local UserInputService = game:GetService("UserInputService")

local SubDialog = {}

function SubDialog.Show(parentWindow, options)
	options = options or {}
	local title = options.Title or (parentWindow and parentWindow.Title) or "Windows 7"
	local instruction = options.Instruction or options.Header or "Do you want to apply these changes?"
	local content = options.Content or options.Message or "Changes will take effect immediately."
	local iconType = options.Icon or "Info" -- "Info", "Warning", "Error", "Question", "Shield"
	local buttons = options.Buttons or {
		{ Text = "OK", IsDefault = true, Value = true },
		{ Text = "Cancel", IsDefault = false, Value = false },
	}
	local callback = options.Callback

	local screenGui = (parentWindow and parentWindow.ScreenGui) or Utility.GetSafeGuiParent()

	-- Invisible modal layer: still blocks clicks behind the dialog, but does not dim the screen
	local overlay = Utility.Create("TextButton", {
		Name = "Win7ModalOverlay",
		Parent = screenGui,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		ZIndex = 80,
	})

	local dialogFrame = Utility.Create("Frame", {
		Name = "Win7TaskDialogFrame",
		Parent = overlay,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(25, 42, 65),
		BackgroundTransparency = 0.82,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 390, 0, 186),
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

	-- Dialog titlebar (supports touch and mouse dragging)
	local titleBar = Utility.Create("Frame", {
		Name = "DialogTitleBar",
		Parent = dialogFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 28),
		Active = true,
		ZIndex = 84,
	})
	local titleCtrl = Utility.CreateGlowingTitle(titleBar, title, 85)
	titleCtrl.Container.Position = UDim2.new(0, 10, 0, 0)

	-- Top-anchored 44x19 Close button with red radial glow and vector X glyph
	local closeRedHalo = Utility.Create("Frame", {
		Name = "CloseRedGlowHalo",
		Parent = titleBar,
		BackgroundColor3 = Color3.fromRGB(230, 142, 117),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -52, 0, 0),
		Size = UDim2.new(0, 44, 0, 19),
		ZIndex = 85,
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
		ZIndex = 86,
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
		ZIndex = 87,
	})
	Utility.AddCorner(innerRim, 2)
	local innerStroke = Utility.AddStroke(innerRim, Color3.fromRGB(255, 255, 255), 1, 0.45, Enum.ApplyStrokeMode.Border)

	-- Renders vector X glyph for crisp scaling
	Utility.CreateVectorCloseX(closeBtn, Color3.fromRGB(255, 255, 255), Color3.fromRGB(52, 12, 12), 88)

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

	-- Drag the dialog by its title bar (position only, kept inside the screen)
	local stopDrag
	do
		local dragging = false
		local dragStart, startPos
		local moveConn, endConn

		stopDrag = function()
			dragging = false
			if moveConn then
				moveConn:Disconnect()
				moveConn = nil
			end
			if endConn then
				endConn:Disconnect()
				endConn = nil
			end
		end

		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			stopDrag()
			dragging = true
			dragStart = input.Position
			startPos = dialogFrame.Position

			moveConn = UserInputService.InputChanged:Connect(function(changed)
				if not dragging then
					return
				end
				if changed.UserInputType ~= Enum.UserInputType.MouseMovement and changed.UserInputType ~= Enum.UserInputType.Touch then
					return
				end
				local delta = changed.Position - dragStart
				local x = startPos.X.Offset + delta.X
				local y = startPos.Y.Offset + delta.Y
				-- The frame is centred (scale 0.5), so its offset may range +-(screen - dialog) / 2
				local area = overlay.AbsoluteSize
				local dialogSize = dialogFrame.AbsoluteSize
				if area.X > 0 and area.Y > 0 then
					local limitX = math.max(0, (area.X - dialogSize.X) / 2)
					local limitY = math.max(0, (area.Y - dialogSize.Y) / 2)
					x = math.clamp(x, -limitX, limitX)
					y = math.clamp(y, -limitY, limitY)
				end
				dialogFrame.Position = UDim2.new(startPos.X.Scale, x, startPos.Y.Scale, y)
			end)
			endConn = UserInputService.InputEnded:Connect(function(ended)
				if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
					stopDrag()
				end
			end)
		end)
	end

	-- TaskDialog client area (8px padding from glass frame)
	local clientBox = Utility.Create("Frame", {
		Name = "DialogClientBox",
		Parent = dialogFrame,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 8, 0, 28),
		Size = UDim2.new(1, -16, 1, -36),
		ClipsDescendants = true,
		ZIndex = 84,
	})
	Utility.AddStroke(clientBox, Theme.Colors.ClientOuterBorder, 1, 0.15, Enum.ApplyStrokeMode.Border)

	-- Upper white content pane
	local bodyWhite = Utility.Create("Frame", {
		Name = "MainInstructionPane",
		Parent = clientBox,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, -42),
		ZIndex = 85,
	})

	local iconImg = Utility.Create("ImageLabel", {
		Name = "DialogStatusIcon",
		Parent = bodyWhite,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 16),
		Size = UDim2.new(0, 32, 0, 32),
		ZIndex = 86,
	})
	Assets.BindIcon(iconImg, iconType)

	Utility.Create("TextLabel", {
		Name = "MainInstructionText",
		Parent = bodyWhite,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 60, 0, 14),
		Size = UDim2.new(1, -74, 0, 22),
		Font = Theme.Fonts.Regular,
		Text = instruction,
		TextColor3 = Theme.Colors.TextInstruction, -- #003399
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 86,
	})

	Utility.Create("TextLabel", {
		Name = "ContentMessageText",
		Parent = bodyWhite,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 60, 0, 40),
		Size = UDim2.new(1, -74, 1, -48),
		Font = Theme.Fonts.Regular,
		Text = content,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 86,
	})

	-- Footer command bar (#F0F0F0)
	local footerBar = Utility.Create("Frame", {
		Name = "TaskDialogFooter",
		Parent = clientBox,
		BackgroundColor3 = Theme.Colors.DialogFaceBg,
		Position = UDim2.new(0, 0, 1, -42),
		Size = UDim2.new(1, 0, 0, 42),
		ZIndex = 85,
	})
	Utility.Create("Frame", {
		Name = "FooterTopBorder",
		Parent = footerBar,
		BackgroundColor3 = Color3.fromRGB(223, 223, 223),
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 86,
	})

	local btnRow = Utility.Create("Frame", {
		Name = "ButtonRow",
		Parent = footerBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 9),
		Size = UDim2.new(1, -24, 0, 24),
		ZIndex = 86,
	})
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.Parent = btnRow

	local closed = false
	local function closeDialog(resultValue, buttonText)
		if closed then
			return
		end
		closed = true
		stopDrag()
		DWM.AnimateClose(dialogFrame, scale, function()
			if overlay and overlay.Parent then
				overlay:Destroy()
			end
			if callback then
				callback(resultValue, buttonText)
			end
		end, dialogGlass)
	end

	closeBtn.MouseButton1Click:Connect(function()
		closeDialog(false, "Close")
	end)

	for idx, btnSpec in ipairs(buttons) do
		local bText = btnSpec.Text or ("Button " .. tostring(idx))
		local b = Utility.Create("TextButton", {
			Name = "DialogBtn_" .. bText,
			Parent = btnRow,
			LayoutOrder = idx,
			Size = UDim2.new(0, math.max(75, #bText * 7 + 22), 0, 23),
			Font = Theme.Fonts.Regular,
			Text = bText,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			ZIndex = 87,
		})
		Utility.BindWin7ButtonStates(b, {
			CornerRadius = 3,
			IsDefault = btnSpec.IsDefault == true,
		})
		b.MouseButton1Click:Connect(function()
			local val = btnSpec.Value
			if val == nil then
				val = bText
			end
			if btnSpec.Callback then
				btnSpec.Callback()
			end
			closeDialog(val, bText)
		end)
	end

	DWM.AnimateOpen(dialogFrame, scale, dialogGlass)

	return {
		Overlay = overlay,
		DialogFrame = dialogFrame,
		Close = closeDialog,
	}
end

return SubDialog
