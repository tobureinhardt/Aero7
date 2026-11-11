--!nonstrict
-- Aero7: components/Balloon - Standard Windows 7 notification balloon and tooltip bubble (TTS_BALLOON).

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")

local Balloon = {}

-- Renders a Balloon component (inline or floating overlay)
function Balloon.new(parentContainer, options)
	options = options or {}
	local title = options.Title or "Windows 7 Balloon Tip"
	local content = options.Content or options.Text or "This is an authentic Windows 7 balloon notification."
	local iconType = options.Icon or "Info"
	local closable = (options.Closable ~= false)
	local tailPosition = options.Tail or "TopLeft" -- "TopLeft", "BottomLeft", "BottomRight"

	local wrapper = Utility.Create("Frame", {
		Name = "Balloon_" .. title,
		Parent = parentContainer,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 66),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 3,
	})

	-- Balloon body (#FFFFFF -> #E4E5F0, border #767676)
	local bubble = Utility.Create("Frame", {
		Name = "Win7BalloonBubble",
		Parent = wrapper,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 0, (tailPosition == "TopLeft") and 9 or 0),
		Size = UDim2.new(1, 0, 0, 56),
		ZIndex = wrapper.ZIndex + 1,
	})
	Utility.AddCorner(bubble, 5)
	Utility.AddStroke(bubble, Theme.Colors.TooltipBorder, 1, 0, Enum.ApplyStrokeMode.Border)

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(228, 229, 240)),
	})
	grad.Parent = bubble

	-- Pointer beak rotated 45 degrees per 7.css _balloon.scss
	local beak = Utility.Create("Frame", {
		Name = "BalloonPointerBeak",
		Parent = wrapper,
		BackgroundColor3 = (tailPosition == "TopLeft") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(228, 229, 240),
		Position = (tailPosition == "TopLeft") and UDim2.new(0, 18, 0, 4)
			or (tailPosition == "BottomRight" and UDim2.new(1, -28, 1, -5) or UDim2.new(0, 18, 1, -5)),
		Size = UDim2.new(0, 10, 0, 10),
		Rotation = 45,
		ZIndex = wrapper.ZIndex,
	})
	Utility.AddStroke(beak, Theme.Colors.TooltipBorder, 1, 0, Enum.ApplyStrokeMode.Border)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = bubble

	local iconImg = Utility.Create("ImageLabel", {
		Name = "BalloonIcon",
		Parent = bubble,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 1),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = bubble.ZIndex + 2,
	})
	Assets.BindIcon(iconImg, iconType)

	local titleLbl = Utility.Create("TextLabel", {
		Name = "BalloonHeaderTitle",
		Parent = bubble,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 22, 0, 0),
		Size = UDim2.new(1, -44, 0, 18),
		Font = Theme.Fonts.Semibold,
		Text = title,
		TextColor3 = Theme.Colors.TextInstruction, -- #003399 Windows 7 Balloon Title standard
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = bubble.ZIndex + 2,
	})

	local bodyLbl = Utility.Create("TextLabel", {
		Name = "BalloonBodyText",
		Parent = bubble,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 22, 0, 20),
		Size = UDim2.new(1, -28, 0, 18),
		Font = Theme.Fonts.Regular,
		Text = content,
		TextColor3 = Color3.fromRGB(51, 51, 51),
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = bubble.ZIndex + 2,
	})

	if closable then
		local closeBtn = Utility.Create("TextButton", {
			Name = "BalloonCloseBtn",
			Parent = bubble,
			BackgroundColor3 = Color3.fromRGB(234, 246, 253),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -16, 0, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Text = "",
			ZIndex = bubble.ZIndex + 3,
		})
		Utility.AddCorner(closeBtn, 2)
		local xGlyph = Utility.CreateVectorCloseX(
			closeBtn,
			Color3.fromRGB(118, 118, 118),
			Color3.fromRGB(240, 240, 240),
			bubble.ZIndex + 4
		)
		closeBtn.MouseEnter:Connect(function()
			for _, ch in ipairs(xGlyph:GetChildren()) do
				if ch.Name == "MainArm" then
					ch.BackgroundColor3 = Color3.fromRGB(214, 36, 36)
				end
			end
			closeBtn.BackgroundTransparency = 0.2
		end)
		closeBtn.MouseLeave:Connect(function()
			for _, ch in ipairs(xGlyph:GetChildren()) do
				if ch.Name == "MainArm" then
					ch.BackgroundColor3 = Color3.fromRGB(118, 118, 118)
				end
			end
			closeBtn.BackgroundTransparency = 1
		end)
		closeBtn.MouseButton1Click:Connect(function()
			wrapper.Visible = false
			if options.OnClose then
				options.OnClose()
			end
		end)
	end

	return {
		Wrapper = wrapper,
		Bubble = bubble,
		SetTitle = function(_, t)
			titleLbl.Text = tostring(t or "")
		end,
		SetText = function(_, c)
			bodyLbl.Text = tostring(c or "")
		end,
		Show = function()
			wrapper.Visible = true
		end,
		Hide = function()
			wrapper.Visible = false
		end,
	}
end

-- Displays floating Balloon notification at bottom-right of window (Notify)
function Balloon.Notify(windowObj, options)
	options = options or {}
	local host = (windowObj and windowObj.WindowFrame) or Utility.GetSafeGuiParent()
	local holder = host:FindFirstChild("_Win7BalloonTrayHolder")
	if not holder then
		holder = Utility.Create("Frame", {
			Name = "_Win7BalloonTrayHolder",
			Parent = host,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -270, 1, -108),
			Size = UDim2.new(0, 256, 0, 76),
			ZIndex = 120,
		})
	end

	for _, ch in ipairs(holder:GetChildren()) do
		ch:Destroy()
	end

	options.Tail = "BottomRight"
	local b = Balloon.new(holder, options)
	local duration = tonumber(options.Duration) or 4.5
	if duration > 0 then
		task.delay(duration, function()
			if b.Wrapper and b.Wrapper.Parent then
				b.Wrapper:Destroy()
			end
		end)
	end
	return b
end

return Balloon
