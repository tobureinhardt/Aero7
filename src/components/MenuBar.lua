--!nonstrict
-- Aero7: components/MenuBar - Windows 7 horizontal MenuBar and Popup Flyout / ContextMenu (7.css gui/_menu.scss).

local UserInputService = game:GetService("UserInputService")
local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")

local MenuBar = {}

-- Builds a standard Windows 7 Popup Menu (shared by MenuBar, SplitButton, Toolbar and ContextMenu)
function MenuBar.CreatePopupMenu(parentGui, items, posUDim2, zBase, onItemSelected)
	zBase = zBase or 180
	items = items or {}

	-- Calculates pixel dimensions per 7.css gui/_menu.scss (min-width: 150px; padding: 2px)
	local totalHeight = 4
	local maxRowWidth = 214
	for _, item in ipairs(items) do
		if item.Separator or item == "-" then
			totalHeight = totalHeight + 7
		else
			totalHeight = totalHeight + 22
			local textLen = #tostring(item.Text or "")
			local shortLen = (item.Shortcut and item.Shortcut ~= "") and (#tostring(item.Shortcut) + 3) or 0
			local hasSub = (type(item.Items) == "table" and #item.Items > 0) or (type(item.Submenu) == "table" and #item.Submenu > 0)
			local estW = 36 + (textLen * 7) + (shortLen * 7) + (hasSub and 18 or 14)
			if estW > maxRowWidth then
				maxRowWidth = estW
			end
		end
	end
	totalHeight = math.max(26, totalHeight)
	local menuWidth = math.clamp(maxRowWidth, 150, 268)

	local menuFrame = Utility.Create("Frame", {
		Name = "Win7PopupMenu",
		Parent = parentGui,
		BackgroundColor3 = Color3.fromRGB(240, 240, 240), -- var(--w7-surface) = #F0F0F0 per 7.css ul[role="menu"]
		Position = posUDim2 or UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, menuWidth, 0, totalHeight),
		Visible = false,
		ZIndex = zBase,
	})
	-- border: 1px solid #0006 (#979797 on #F0F0F0) per 7.css _menu.scss
	Utility.AddStroke(menuFrame, Color3.fromRGB(151, 151, 151), 1, 0, Enum.ApplyStrokeMode.Border)

	local innerWhiteInset = Utility.Create("Frame", {
		Name = "MenuInnerWhiteInset",
		Parent = menuFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = zBase + 1,
	})

	-- Drop shadow at right and bottom edges per 7.css (box-shadow: 4px 4px 3px -2px #00000080)
	-- Note: Child elements render above menuFrame under Sibling ZIndexBehavior.
	-- MenuDropShadow is transparent (BackgroundTransparency = 1) and renders only exterior edge shadows.
	local shadow = Utility.Create("Frame", {
		Name = "MenuDropShadow",
		Parent = menuFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = zBase - 1,
	})
	Utility.Create("Frame", {
		Name = "ShadowRightEdge",
		Parent = shadow,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 1, 0, 3),
		Size = UDim2.new(0, 2, 1, -1),
		ZIndex = zBase - 1,
	})
	Utility.Create("Frame", {
		Name = "ShadowBottomEdge",
		Parent = shadow,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 3, 1, 1),
		Size = UDim2.new(1, -2, 0, 2),
		ZIndex = zBase - 1,
	})

	-- ul[role="menu"]::before trong 7.css _menu.scss:
	-- left: var(--w7-mn-left) (28px); width: 2px; height: calc(100% - 4px); box-shadow: inset 1px 0 #00000026, inset -1px 0 #fff;
	Utility.Create("Frame", {
		Name = "LeftIconGutterBg",
		Parent = menuFrame,
		BackgroundColor3 = Color3.fromRGB(240, 240, 240),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(0, 26, 1, -4),
		ZIndex = zBase + 1,
	})
	Utility.Create("Frame", {
		Name = "GutterSeparatorDark",
		Parent = menuFrame,
		BackgroundColor3 = Color3.fromRGB(217, 217, 217), -- inset 1px 0 #00000026 over #F0F0F0
		BorderSizePixel = 0,
		Position = UDim2.new(0, 28, 0, 2),
		Size = UDim2.new(0, 1, 1, -4),
		ZIndex = zBase + 2,
	})
	Utility.Create("Frame", {
		Name = "GutterSeparatorLight",
		Parent = menuFrame,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- inset -1px 0 #FFFFFF
		BorderSizePixel = 0,
		Position = UDim2.new(0, 29, 0, 2),
		Size = UDim2.new(0, 1, 1, -4),
		ZIndex = zBase + 2,
	})

	local itemHolder = Utility.Create("Frame", {
		Name = "MenuItemsList",
		Parent = menuFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = zBase + 3,
	})
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 2)
	pad.PaddingLeft = UDim.new(0, 2)
	pad.PaddingRight = UDim.new(0, 2)
	pad.Parent = itemHolder

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 0)
	list.Parent = itemHolder

	for idx, item in ipairs(items) do
		if item.Separator or item == "-" then
			-- .has-divider::after trong 7.css _menu.scss:
			-- margin: 3px 0 2px; height: 2px; margin-left: var(--w7-mn-left) (28px); box-shadow: inset 0 1px #00000026, inset 0 -1px #fff;
			local sepWrap = Utility.Create("Frame", {
				Name = "MenuSeparator_" .. tostring(idx),
				Parent = itemHolder,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 7),
				LayoutOrder = idx,
				ZIndex = zBase + 3,
			})
			Utility.Create("Frame", {
				Name = "SepLineDark",
				Parent = sepWrap,
				BackgroundColor3 = Color3.fromRGB(217, 217, 217),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 26, 0, 3),
				Size = UDim2.new(1, -26, 0, 1),
				ZIndex = zBase + 4,
			})
			Utility.Create("Frame", {
				Name = "SepLineLight",
				Parent = sepWrap,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 26, 0, 4),
				Size = UDim2.new(1, -26, 0, 1),
				ZIndex = zBase + 4,
			})
		else
			local rowBtn = Utility.Create("TextButton", {
				Name = "MenuItem_" .. tostring(item.Text or idx),
				Parent = itemHolder,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = idx,
				Text = "",
				ZIndex = zBase + 4,
			})
			Utility.AddCorner(rowBtn, 3)
			-- Hover styling per 7.css _menu.scss & _variables.scss:
			-- --w7-li-bd-hl: #aaddfa;
			-- --w7-li-bg-hl: linear-gradient(#fff9, #e6ecf5cc 90%, #fffc);
			local itemStroke = Utility.AddStroke(rowBtn, Color3.fromRGB(170, 221, 250), 1, 1, Enum.ApplyStrokeMode.Border)
			local itemGrad = Instance.new("UIGradient")
			itemGrad.Rotation = 90
			itemGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.9, Color3.fromRGB(230, 236, 245)),
				ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
			})
			itemGrad.Parent = rowBtn

			-- Checkmark or icon box (22x22, top: 0, left: 0, border #b3d3f9 per 7.css _menu.scss)
			local gutterBox = Utility.Create("Frame", {
				Name = "GutterIconBox",
				Parent = rowBtn,
				BackgroundColor3 = Color3.fromRGB(230, 236, 245),
				BackgroundTransparency = (item.Checked == true) and 0.15 or 1,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(0, 22, 0, 22),
				ZIndex = zBase + 5,
			})
			Utility.AddCorner(gutterBox, 3)
			local gutterStroke = Utility.AddStroke(
				gutterBox,
				Color3.fromRGB(179, 211, 249), -- #b3d3f9 per 7.css
				1,
				(item.Checked == true) and 0 or 1,
				Enum.ApplyStrokeMode.Border
			)

			local iconOrCheck = Utility.Create("ImageLabel", {
				Name = "GutterGlyph",
				Parent = gutterBox,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 3, 0, 3),
				Size = UDim2.new(0, 16, 0, 16),
				Visible = (item.Checked == true) or (item.Icon ~= nil and item.Icon ~= ""),
				ZIndex = zBase + 6,
			})
			if item.Checked ~= nil then
				Assets.BindIcon(iconOrCheck, "Checkmark")
			elseif item.Icon then
				Assets.BindIcon(iconOrCheck, item.Icon)
			end

			-- Item text label (padding: 4px 10px 4px 32px per 7.css _menu.scss)
			Utility.Create("TextLabel", {
				Name = "ItemText",
				Parent = rowBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 30, 0, 0),
				Size = UDim2.new(1, -90, 1, 0),
				Font = Theme.Fonts.Regular,
				Text = tostring(item.Text or "Command"),
				TextColor3 = item.Disabled and Theme.Colors.TextDisabled or Theme.Colors.TextPrimary,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = zBase + 5,
			})

			-- Right-aligned shortcut key text (Ctrl+S, F5...)
			if item.Shortcut and item.Shortcut ~= "" then
				Utility.Create("TextLabel", {
					Name = "ShortcutText",
					Parent = rowBtn,
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -66, 0, 0),
					Size = UDim2.new(0, 56, 1, 0),
					Font = Theme.Fonts.Regular,
					Text = tostring(item.Shortcut),
					TextColor3 = item.Disabled and Theme.Colors.TextDisabled or Theme.Colors.TextSecondary,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					ZIndex = zBase + 5,
				})
			end

			rowBtn.MouseEnter:Connect(function()
				if not item.Disabled then
					rowBtn.BackgroundTransparency = 0.22
					itemStroke.Transparency = 0
				end
			end)
			rowBtn.MouseLeave:Connect(function()
				rowBtn.BackgroundTransparency = 1
				itemStroke.Transparency = 1
			end)
			rowBtn.MouseButton1Click:Connect(function()
				if item.Disabled then
					return
				end
				if item.Checkable or item.Checked ~= nil then
					item.Checked = not item.Checked
					iconOrCheck.Visible = item.Checked
					gutterBox.BackgroundTransparency = item.Checked and 0.15 or 1
					gutterStroke.Transparency = item.Checked and 0 or 1
				end
				menuFrame.Visible = false
				if onItemSelected then
					onItemSelected()
				end
				if item.Callback then
					item.Callback(item.Checked)
				end
			end)
		end
	end

	return menuFrame
end

-- Displays a standalone Popup Menu (used for SplitButton, Toolbar dropdowns)
function MenuBar.ShowPopupMenu(hostGui, posUDim2, items, onClose)
	local host = hostGui
	if host and not host:IsA("ScreenGui") then
		host = host:FindFirstAncestorWhichIsA("ScreenGui") or host
	end
	local popup = MenuBar.CreatePopupMenu(host, items, posUDim2, 195, function()
		if onClose then
			onClose()
		end
	end)
	popup.Visible = true
	return {
		Frame = popup,
		Destroy = function()
			if popup and popup.Parent then
				popup:Destroy()
			end
			if onClose then
				onClose()
			end
		end,
	}
end

-- Builds horizontal MenuBar (File, Edit, View, Tools, Help)
function MenuBar.new(parentContainer, menusSpec)
	menusSpec = menusSpec or {}

	local bar = Utility.Create("Frame", {
		Name = "Win7MenuBar",
		Parent = parentContainer,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 0,
		ZIndex = parentContainer.ZIndex + 6,
	})
	Utility.AddCorner(bar, 2)
	Utility.AddStroke(bar, Color3.fromRGB(192, 208, 228), 1, 0, Enum.ApplyStrokeMode.Border)

	local barGrad = Instance.new("UIGradient")
	barGrad.Rotation = 90
	barGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(248, 252, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(232, 241, 252)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(214, 227, 244)),
	})
	barGrad.Parent = bar

	Utility.Create("Frame", {
		Name = "MenuBarTopHighlight",
		Parent = bar,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.25,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 0, 1),
		ZIndex = bar.ZIndex + 1,
	})

	Utility.Create("Frame", {
		Name = "MenuBarBottomLine",
		Parent = bar,
		BackgroundColor3 = Color3.fromRGB(176, 192, 212),
		Position = UDim2.new(0, 1, 1, -1),
		Size = UDim2.new(1, -2, 0, 1),
		ZIndex = bar.ZIndex + 1,
	})

	local itemRow = Utility.Create("Frame", {
		Name = "MenuBarItemsRow",
		Parent = bar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0, 2),
		Size = UDim2.new(1, -8, 1, -4),
		ZIndex = bar.ZIndex + 2,
	})
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 3)
	rowLayout.Parent = itemRow

	local popups = {}
	local function closeAllPopups()
		for _, p in ipairs(popups) do
			p.Popup.Visible = false
			p.Button.BackgroundTransparency = 1
			p.Stroke.Transparency = 1
		end
	end

	-- Locates root ScreenGui so Popup Menu is not clipped by scrolling containers
	local popupHost = bar:FindFirstAncestorWhichIsA("ScreenGui") or parentContainer
	local cumulativeX = 4

	for idx, menuDef in ipairs(menusSpec) do
		local mTitle = tostring(menuDef.Title or ("Menu " .. tostring(idx)))
		local btnWidth = math.max(38, #mTitle * 7 + 16)
		local btnX = cumulativeX
		cumulativeX = cumulativeX + btnWidth + 3

		local topBtn = Utility.Create("TextButton", {
			Name = "TopMenu_" .. mTitle,
			Parent = itemRow,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.new(0, btnWidth, 0, 20),
			LayoutOrder = idx,
			Font = Theme.Fonts.Regular,
			Text = mTitle,
			TextColor3 = Color3.fromRGB(24, 52, 92),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = bar.ZIndex + 3,
		})
		Utility.AddCorner(topBtn, 2)
		local topStroke = Utility.AddStroke(topBtn, Color3.fromRGB(125, 162, 206), 1, 1, Enum.ApplyStrokeMode.Border)
		local topGrad = Instance.new("UIGradient")
		topGrad.Rotation = 90
		topGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(250, 253, 255)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(214, 232, 252)),
		})
		topGrad.Parent = topBtn

		local popup = MenuBar.CreatePopupMenu(
			popupHost,
			menuDef.Items or {},
			UDim2.new(0, btnX, 0, 25),
			190,
			function()
				topBtn.BackgroundTransparency = 1
				topStroke.Transparency = 1
			end
		)
		table.insert(popups, { Button = topBtn, Stroke = topStroke, Popup = popup, FallbackX = btnX })

		topBtn.MouseEnter:Connect(function()
			topBtn.BackgroundTransparency = 0.08
			topStroke.Transparency = 0.1
		end)
		topBtn.MouseLeave:Connect(function()
			if not popup.Visible then
				topBtn.BackgroundTransparency = 1
				topStroke.Transparency = 1
			end
		end)
		topBtn.MouseButton1Click:Connect(function()
			local wasVisible = popup.Visible
			closeAllPopups()
			if not wasVisible then
				-- Positions popup directly beneath top menu button
				local absPos = topBtn.AbsolutePosition
				local absSize = topBtn.AbsoluteSize
				if absSize and absSize.Y > 0 and popupHost:IsA("ScreenGui") then
					popup.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 1)
				else
					popup.Position = UDim2.new(0, btnX, 0, 25)
				end
				popup.Visible = true
				topBtn.BackgroundTransparency = 0.04
				topStroke.Transparency = 0
			end
		end)
	end

	return {
		Bar = bar,
		CloseAll = closeAllPopups,
	}
end

-- Attaches right-click context menu to any GuiObject
function MenuBar.AttachContextMenu(targetGui, items, hostGui)
	local host = hostGui or targetGui:FindFirstAncestorWhichIsA("ScreenGui") or targetGui.Parent
	local popup = MenuBar.CreatePopupMenu(host, items, UDim2.new(0, 100, 0, 100), 190)

	targetGui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local mPos = UserInputService:GetMouseLocation()
			popup.Position = UDim2.new(0, mPos.X, 0, mPos.Y)
			popup.Visible = not popup.Visible
		end
	end)

	return popup
end

return MenuBar
