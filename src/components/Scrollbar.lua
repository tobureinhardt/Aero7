--!nonstrict
-- Aero7: components/Scrollbar - Standard Windows 7 16px vertical scrollbar with 50/50 split-gradient thumb and grip lines.

local UserInputService = game:GetService("UserInputService")
local Theme = require("core/Theme")
local Utility = require("core/Utility")

local Scrollbar = {}

function Scrollbar.Attach(scrollingFrame)
	if not scrollingFrame or not scrollingFrame:IsA("ScrollingFrame") then
		return nil
	end

	-- Hides Roblox default flat scrollbar and offsets content for Win7 scrollbar
	scrollingFrame.ScrollBarThickness = 0

	local parent = scrollingFrame.Parent
	local barFrame = Utility.Create("Frame", {
		Name = "Win7VerticalScrollbar",
		Parent = parent,
		BackgroundColor3 = Color3.fromRGB(240, 240, 240),
		Position = UDim2.new(1, -16, scrollingFrame.Position.Y.Scale, scrollingFrame.Position.Y.Offset),
		Size = UDim2.new(0, 16, scrollingFrame.Size.Y.Scale, scrollingFrame.Size.Y.Offset),
		ZIndex = scrollingFrame.ZIndex + 4,
	})
	Utility.AddStroke(barFrame, Color3.fromRGB(212, 216, 222), 1, 0, Enum.ApplyStrokeMode.Border)

	-- Subtle horizontal gradient on track per Win7 standard
	local trackGrad = Instance.new("UIGradient")
	trackGrad.Rotation = 0
	trackGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(228, 228, 228)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(242, 242, 242)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(234, 234, 234)),
	})
	trackGrad.Parent = barFrame

	-- Up Arrow button (16x16)
	local upBtn = Utility.Create("TextButton", {
		Name = "ScrollUpButton",
		Parent = barFrame,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "",
		ZIndex = barFrame.ZIndex + 2,
	})
	Utility.BindWin7ButtonStates(upBtn, { CornerRadius = 1 })
	Utility.CreateVectorChevron(upBtn, "Up", Color3.fromRGB(56, 68, 82), upBtn.ZIndex + 2)

	-- Down Arrow button (16x16)
	local downBtn = Utility.Create("TextButton", {
		Name = "ScrollDownButton",
		Parent = barFrame,
		Position = UDim2.new(0, 0, 1, -16),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "",
		ZIndex = barFrame.ZIndex + 2,
	})
	Utility.BindWin7ButtonStates(downBtn, { CornerRadius = 1 })
	Utility.CreateVectorChevron(downBtn, "Down", Color3.fromRGB(56, 68, 82), downBtn.ZIndex + 2)

	-- Thumb travel track
	local trackZone = Utility.Create("Frame", {
		Name = "ScrollThumbTrack",
		Parent = barFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 16),
		Size = UDim2.new(1, 0, 1, -32),
		ZIndex = barFrame.ZIndex + 1,
	})

	-- Thumb handle with Windows 7 3-line grip
	local thumb = Utility.Create("TextButton", {
		Name = "ScrollThumb",
		Parent = trackZone,
		Position = UDim2.new(0, 1, 0, 0),
		Size = UDim2.new(1, -2, 0.35, 0),
		Text = "",
		ZIndex = trackZone.ZIndex + 2,
	})
	Utility.BindWin7ButtonStates(thumb, { CornerRadius = 2 })

	-- 3 horizontal grip bars at thumb center
	local gripLines = Utility.Create("Frame", {
		Name = "ThumbGripBars",
		Parent = thumb,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 6, 0, 7),
		ZIndex = thumb.ZIndex + 2,
	})
	for i = 0, 2 do
		Utility.Create("Frame", {
			Name = "GripLine_" .. tostring(i + 1),
			Parent = gripLines,
			BackgroundColor3 = Color3.fromRGB(118, 128, 140),
			Position = UDim2.new(0, 0, 0, i * 3),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = gripLines.ZIndex + 1,
		})
	end

	local function getCanvasHeight()
		local absCanvasY = scrollingFrame.AbsoluteCanvasSize and scrollingFrame.AbsoluteCanvasSize.Y
		if absCanvasY and absCanvasY > 0 then
			return absCanvasY
		end
		return scrollingFrame.CanvasSize.Y.Offset
	end

	local function syncThumbFromScroll()
		local winH = math.max(scrollingFrame.AbsoluteSize.Y, 1)
		local canvasH = math.max(getCanvasHeight(), winH)
		local maxScroll = math.max(canvasH - winH, 0)
		if maxScroll <= 2 then
			thumb.Size = UDim2.new(1, -2, 1, 0)
			thumb.Position = UDim2.new(0, 1, 0, 0)
			gripLines.Visible = true
			return
		end
		local ratio = math.clamp(winH / canvasH, 0.14, 0.92)
		local scrollAlpha = math.clamp((scrollingFrame.CanvasPosition and scrollingFrame.CanvasPosition.Y or 0) / maxScroll, 0, 1)
		thumb.Size = UDim2.new(1, -2, ratio, 0)
		thumb.Position = UDim2.new(0, 1, scrollAlpha * (1 - ratio), 0)
	end

	upBtn.MouseButton1Click:Connect(function()
		local curY = scrollingFrame.CanvasPosition and scrollingFrame.CanvasPosition.Y or 0
		scrollingFrame.CanvasPosition = Vector2.new(0, math.max(0, curY - 36))
		syncThumbFromScroll()
	end)

	downBtn.MouseButton1Click:Connect(function()
		local curY = scrollingFrame.CanvasPosition and scrollingFrame.CanvasPosition.Y or 0
		local winH = math.max(scrollingFrame.AbsoluteSize.Y, 1)
		local maxScroll = math.max(getCanvasHeight() - winH, 0)
		scrollingFrame.CanvasPosition = Vector2.new(0, math.min(maxScroll, curY + 36))
		syncThumbFromScroll()
	end)

	local dragging = false
	local dragStartY = 0
	local startScrollY = 0

	thumb.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStartY = input.Position.Y
			startScrollY = scrollingFrame.CanvasPosition and scrollingFrame.CanvasPosition.Y or 0
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local trackH = math.max(trackZone.AbsoluteSize.Y, 1)
			local winH = math.max(scrollingFrame.AbsoluteSize.Y, 1)
			local maxScroll = math.max(getCanvasHeight() - winH, 0)
			local dy = input.Position.Y - dragStartY
			local scrollDelta = (dy / trackH) * maxScroll
			scrollingFrame.CanvasPosition = Vector2.new(0, math.clamp(startScrollY + scrollDelta, 0, maxScroll))
			syncThumbFromScroll()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(syncThumbFromScroll)

	return {
		BarFrame = barFrame,
		UpButton = upBtn,
		DownButton = downBtn,
		Thumb = thumb,
		Refresh = syncThumbFromScroll,
	}
end

return Scrollbar
