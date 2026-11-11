--!nonstrict
-- Aero7: components/Toolbar - Windows 7 flat toolbar command strip with toggles and dropdowns (ToolbarWindow32).

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")
local MenuBar = require("components/MenuBar")

local Toolbar = {}

function Toolbar.new(parentContainer, options)
	options = options or {}
	local items = options.Items or options.Buttons or options

	local bar = Utility.Create("Frame", {
		Name = "Win7Toolbar",
		Parent = parentContainer,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	Utility.AddCorner(bar, 2)
	Utility.AddStroke(bar, Color3.fromRGB(192, 208, 228), 1, 0, Enum.ApplyStrokeMode.Border)

	local barGrad = Instance.new("UIGradient")
	barGrad.Rotation = 90
	barGrad.Color = Theme.Gradients.ExplorerCommandBar
	barGrad.Parent = bar

	local listHost = Utility.Create("Frame", {
		Name = "ToolbarButtonsHost",
		Parent = bar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0, 2),
		Size = UDim2.new(1, -8, 1, -4),
		ZIndex = bar.ZIndex + 1,
	})
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 3)
	listLayout.Parent = listHost

	local toolControllers = {}

	for idx, spec in ipairs(items) do
		if spec.Separator == true or spec == "-" then
			local sep = Utility.Create("Frame", {
				Name = "ToolbarSeparator_" .. idx,
				Parent = listHost,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 6, 0, 18),
				LayoutOrder = idx,
				ZIndex = listHost.ZIndex + 1,
			})
			Utility.Create("Frame", {
				Name = "EtchDark",
				Parent = sep,
				BackgroundColor3 = Color3.fromRGB(182, 198, 218),
				Position = UDim2.new(0, 2, 0, 1),
				Size = UDim2.new(0, 1, 1, -2),
				ZIndex = sep.ZIndex + 1,
			})
			Utility.Create("Frame", {
				Name = "EtchLight",
				Parent = sep,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.25,
				Position = UDim2.new(0, 3, 0, 1),
				Size = UDim2.new(0, 1, 1, -2),
				ZIndex = sep.ZIndex + 1,
			})
		else
			local text = spec.Text or spec.Title or ""
			local iconName = spec.Icon
			local isToggle = spec.Toggle == true
			local checked = spec.Default == true or spec.Checked == true
			local menuItems = spec.MenuItems or spec.Items
			local hasDropdown = type(menuItems) == "table" and #menuItems > 0
			local cb = spec.Callback or function() end

			local btnWidth = spec.Width
			if not btnWidth then
				btnWidth = 8
				if iconName and iconName ~= "" then
					btnWidth = btnWidth + 18
				end
				if text ~= "" then
					btnWidth = btnWidth + (#text * 6) + 8
				end
				if hasDropdown then
					btnWidth = btnWidth + 14
				end
				btnWidth = math.max(24, btnWidth)
			end

			local btn = Utility.Create("TextButton", {
				Name = "ToolBtn_" .. (text ~= "" and text or tostring(idx)),
				Parent = listHost,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = checked and 0.05 or 1,
				Size = UDim2.new(0, btnWidth, 0, 22),
				LayoutOrder = idx,
				Text = "",
				ZIndex = listHost.ZIndex + 1,
			})
			Utility.AddCorner(btn, 2)

			local btnStroke = Utility.AddStroke(
				btn,
				checked and Theme.Colors.ControlBorderHover or Theme.Colors.SelectionBorder,
				1,
				checked and 0.1 or 1,
				Enum.ApplyStrokeMode.Border
			)

			local btnGrad = Instance.new("UIGradient")
			btnGrad.Rotation = 90
			btnGrad.Color = checked and Theme.Gradients.ButtonPressed or Theme.Gradients.ButtonHover
			btnGrad.Parent = btn

			local innerRow = Utility.Create("Frame", {
				Name = "InnerRow",
				Parent = btn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 4, 0, 0),
				Size = UDim2.new(1, -8, 1, 0),
				ZIndex = btn.ZIndex + 1,
			})
			local innerLayout = Instance.new("UIListLayout")
			innerLayout.FillDirection = Enum.FillDirection.Horizontal
			innerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			innerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			innerLayout.Padding = UDim.new(0, 4)
			innerLayout.Parent = innerRow

			if iconName and iconName ~= "" then
				local ico = Utility.Create("ImageLabel", {
					Name = "Icon",
					Parent = innerRow,
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 14, 0, 14),
					ZIndex = innerRow.ZIndex + 1,
				})
				Assets.BindIcon(ico, iconName)
			end

			if text ~= "" then
				Utility.Create("TextLabel", {
					Name = "Label",
					Parent = innerRow,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 0, 1, 0),
					Font = Theme.Fonts.Regular,
					Text = text,
					TextColor3 = Color3.fromRGB(24, 52, 92),
					TextSize = 12,
					ZIndex = innerRow.ZIndex + 1,
				})
			end

			if hasDropdown then
				local dropWrap = Utility.Create("Frame", {
					Name = "DropArrow",
					Parent = innerRow,
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 10, 1, 0),
					ZIndex = innerRow.ZIndex + 1,
				})
				Utility.CreateVectorChevron(dropWrap, "Down", Color3.fromRGB(40, 74, 118), innerRow.ZIndex + 2)
			end

			local hovered = false
			local pressed = false

			local function refreshVisual()
				if pressed or checked then
					btn.BackgroundTransparency = 0.05
					btnStroke.Color = Theme.Colors.ControlBorderPressed
					btnStroke.Transparency = 0.05
					btnGrad.Color = Theme.Gradients.ButtonPressed
				elseif hovered then
					btn.BackgroundTransparency = 0.08
					btnStroke.Color = Theme.Colors.ControlBorderHover
					btnStroke.Transparency = 0.1
					btnGrad.Color = Theme.Gradients.ButtonHover
				else
					btn.BackgroundTransparency = 1
					btnStroke.Transparency = 1
				end
			end

			btn.MouseEnter:Connect(function()
				hovered = true
				refreshVisual()
			end)
			btn.MouseLeave:Connect(function()
				hovered = false
				pressed = false
				refreshVisual()
			end)
			btn.MouseButton1Down:Connect(function()
				pressed = true
				refreshVisual()
			end)
			btn.MouseButton1Up:Connect(function()
				pressed = false
				refreshVisual()
			end)

			local activePopup = nil
			btn.MouseButton1Click:Connect(function()
				if isToggle then
					checked = not checked
					refreshVisual()
					cb(checked)
				elseif hasDropdown then
					if activePopup and activePopup.Frame and activePopup.Frame.Parent then
						activePopup:Destroy()
						activePopup = nil
						return
					end
					local screenGui = btn:FindFirstAncestorWhichIsA("ScreenGui") or parentContainer
					local absPos = btn.AbsolutePosition
					local absSize = btn.AbsoluteSize
					activePopup = MenuBar.ShowPopupMenu(
						screenGui,
						UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 2),
						menuItems,
						function()
							activePopup = nil
						end
					)
				else
					cb()
				end
			end)

			if spec.Tooltip then
				Tooltip.Attach(btn, spec.Tooltip)
			end

			table.insert(toolControllers, {
				Button = btn,
				SetChecked = function(_, val)
					checked = (val == true)
					refreshVisual()
				end,
				IsChecked = function()
					return checked
				end,
			})
		end
	end

	return {
		Bar = bar,
		Buttons = toolControllers,
	}
end

return Toolbar
