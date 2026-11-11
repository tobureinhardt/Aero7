--!nonstrict
-- Aero7: components/CommandLink - Windows 7 Control Panel Command Link button with teal arrow glyph.

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")

local CommandLink = {}

function CommandLink.new(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "Command Link Instruction"
	local note = options.Note or options.Description or "Click to execute this Windows 7 action."
	local iconName = options.Icon or "CommandArrow"
	local callback = options.Callback or function() end

	local btn = Utility.Create("TextButton", {
		Name = "CommandLink_" .. title,
		Parent = parentContainer,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 52),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		Text = "",
		ZIndex = parentContainer.ZIndex + 1,
	})
	Utility.AddCorner(btn, 3)

	local outerStroke = Utility.AddStroke(btn, Color3.fromRGB(152, 197, 230), 1, 1, Enum.ApplyStrokeMode.Border)
	local innerRim = Utility.Create("Frame", {
		Name = "InnerHighlight",
		Parent = btn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = btn.ZIndex + 1,
	})
	Utility.AddCorner(innerRim, 2)
	local innerStroke = Utility.AddStroke(innerRim, Color3.fromRGB(255, 255, 255), 1, 1, Enum.ApplyStrokeMode.Border)

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = Theme.Gradients.CommandLinkHover
	grad.Parent = btn

	local iconImg = Utility.Create("ImageLabel", {
		Name = "CommandArrowIcon",
		Parent = btn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(0, 20, 0, 20),
		ZIndex = btn.ZIndex + 2,
	})
	Assets.BindIcon(iconImg, iconName)

	local titleLbl = Utility.Create("TextLabel", {
		Name = "MainInstruction",
		Parent = btn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 38, 0, 7),
		Size = UDim2.new(1, -46, 0, 20),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Theme.Colors.TextInstruction, -- #003399
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = btn.ZIndex + 2,
	})

	local noteLbl = Utility.Create("TextLabel", {
		Name = "SubNote",
		Parent = btn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 38, 0, 27),
		Size = UDim2.new(1, -46, 0, 18),
		Font = Theme.Fonts.Regular,
		Text = note,
		TextColor3 = Theme.Colors.TextGroupTitle, -- #1E395B
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = btn.ZIndex + 2,
	})

	btn.MouseEnter:Connect(function()
		grad.Color = Theme.Gradients.CommandLinkHover
		btn.BackgroundTransparency = 0.05
		outerStroke.Color = Color3.fromRGB(152, 197, 230)
		outerStroke.Transparency = 0
		innerStroke.Transparency = 0.15
		titleLbl.TextColor3 = Color3.fromRGB(0, 76, 204)
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundTransparency = 1
		outerStroke.Transparency = 1
		innerStroke.Transparency = 1
		titleLbl.TextColor3 = Theme.Colors.TextInstruction
	end)

	btn.MouseButton1Down:Connect(function()
		grad.Color = Theme.Gradients.ButtonPressed
		outerStroke.Color = Theme.Colors.ControlBorderPressed
	end)

	btn.MouseButton1Up:Connect(function()
		grad.Color = Theme.Gradients.CommandLinkHover
		outerStroke.Color = Color3.fromRGB(152, 197, 230)
	end)

	btn.MouseButton1Click:Connect(function()
		callback()
	end)

	if options.Tooltip then
		Tooltip.Attach(btn, options.Tooltip)
	end

	return {
		Button = btn,
		SetTitle = function(_, t)
			titleLbl.Text = tostring(t or "")
		end,
		SetNote = function(_, n)
			noteLbl.Text = tostring(n or "")
		end,
		Fire = callback,
	}
end

return CommandLink
