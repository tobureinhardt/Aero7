--!nonstrict
-- Aero7: components/Tooltip - Standard Windows 7 tooltip bubble (#FFFFFF -> #E4E5F0, border #767676).

local UserInputService = game:GetService("UserInputService")
local Theme = require("core/Theme")
local Utility = require("core/Utility")

local Tooltip = {}

function Tooltip.Attach(targetGuiObject, tooltipText, screenGui)
	if not targetGuiObject or not tooltipText or tooltipText == "" then
		return nil
	end

	local hostGui = screenGui or targetGuiObject:FindFirstAncestorWhichIsA("ScreenGui")
	if not hostGui then
		return nil
	end

	local tipFrame = hostGui:FindFirstChild("_Win7SharedTooltip")
	local tipLabel
	if not tipFrame then
		tipFrame = Utility.Create("Frame", {
			Name = "_Win7SharedTooltip",
			Parent = hostGui,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0, 0, 0, 22),
			Visible = false,
			ZIndex = 200,
		})
		Utility.AddCorner(tipFrame, 2)
		Utility.AddStroke(tipFrame, Theme.Colors.TooltipBorder, 1, 0, Enum.ApplyStrokeMode.Border)

		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Theme.Colors.TooltipTop),
			ColorSequenceKeypoint.new(1.0, Theme.Colors.TooltipBot),
		})
		grad.Parent = tipFrame

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 3)
		pad.PaddingBottom = UDim.new(0, 3)
		pad.PaddingLeft = UDim.new(0, 6)
		pad.PaddingRight = UDim.new(0, 6)
		pad.Parent = tipFrame

		tipLabel = Utility.Create("TextLabel", {
			Name = "TooltipText",
			Parent = tipFrame,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Font = Theme.Fonts.Regular,
			Text = "",
			TextColor3 = Theme.Colors.TooltipText,
			TextSize = 12,
			ZIndex = 201,
		})
	else
		tipLabel = tipFrame:FindFirstChild("TooltipText")
	end

	local hovering = false
	local moveConn = nil

	targetGuiObject.MouseEnter:Connect(function()
		hovering = true
		if tipLabel then
			tipLabel.Text = tostring(tooltipText)
		end
		local mPos = UserInputService:GetMouseLocation()
		tipFrame.Position = UDim2.new(0, mPos.X + 14, 0, mPos.Y + 18)
		tipFrame.Visible = true

		if moveConn then
			moveConn:Disconnect()
		end
		moveConn = UserInputService.InputChanged:Connect(function(input)
			if hovering and input.UserInputType == Enum.UserInputType.MouseMovement then
				tipFrame.Position = UDim2.new(0, input.Position.X + 14, 0, input.Position.Y + 18)
			end
		end)
	end)

	targetGuiObject.MouseLeave:Connect(function()
		hovering = false
		tipFrame.Visible = false
		if moveConn then
			moveConn:Disconnect()
			moveConn = nil
		end
	end)

	return {
		SetText = function(_, newText)
			tooltipText = tostring(newText or "")
			if hovering and tipLabel then
				tipLabel.Text = tooltipText
			end
		end,
	}
end

return Tooltip
