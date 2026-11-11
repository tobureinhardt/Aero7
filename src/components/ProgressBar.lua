--!nonstrict
-- Aero7: components/ProgressBar - Windows 7 progress bar with animated glossy specular pulse (msctls_progress32).

local Theme = require("core/Theme")
local Utility = require("core/Utility")

local ProgressBar = {}

function ProgressBar.new(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "Progress"
	local minVal = tonumber(options.Min) or 0
	local maxVal = tonumber(options.Max) or 100
	if maxVal <= minVal then
		maxVal = minVal + 100
	end
	local currentVal = math.clamp(tonumber(options.Default or options.Value) or 50, minVal, maxVal)
	local stateColor = options.State or "Green" -- "Green", "Blue", "Amber", "Red"
	local isMarquee = options.Marquee == true or options.Indeterminate == true

	local wrapper = Utility.Create("Frame", {
		Name = "ProgressBar_" .. title,
		Parent = parentContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})

	local headerRow = Utility.Create("Frame", {
		Name = "ProgressHeaderRow",
		Parent = wrapper,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		ZIndex = wrapper.ZIndex + 1,
	})

	local titleLbl = Utility.Create("TextLabel", {
		Name = "ProgressTitle",
		Parent = headerRow,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -55, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = headerRow.ZIndex + 1,
	})

	local pctLbl = Utility.Create("TextLabel", {
		Name = "ProgressPercent",
		Parent = headerRow,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -50, 0, 0),
		Size = UDim2.new(0, 50, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = "0%",
		TextColor3 = Theme.Colors.TextSecondary,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = headerRow.ZIndex + 1,
	})

	-- 17px track frame per Windows 7 standard
	local track = Utility.Create("Frame", {
		Name = "Win7ProgressTrack",
		Parent = wrapper,
		BackgroundColor3 = Theme.Colors.ProgressTrackBg,
		Position = UDim2.new(0, 0, 0, 19),
		Size = UDim2.new(1, 0, 0, 17),
		ClipsDescendants = true,
		ZIndex = wrapper.ZIndex + 1,
	})
	Utility.AddCorner(track, 2)
	Utility.AddStroke(track, Theme.Colors.ProgressTrackBorder, 1, 0, Enum.ApplyStrokeMode.Border)

	-- Track glossy glass sheen layer
	local trackGlass = Utility.Create("Frame", {
		Name = "TrackInnerGlass",
		Parent = track,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.5,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 0.5, -1),
		ZIndex = track.ZIndex + 1,
	})

	-- Internal progress fill bar
	local fillBar = Utility.Create("Frame", {
		Name = "Win7ProgressFill",
		Parent = track,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(0, 0, 1, -2),
		ClipsDescendants = true,
		ZIndex = track.ZIndex + 2,
	})
	Utility.AddCorner(fillBar, 1)

	local fillGrad = Instance.new("UIGradient")
	fillGrad.Rotation = 90
	fillGrad.Color = Theme.Gradients.ProgressGreen
	fillGrad.Parent = fillBar

	-- Animated specular gloss pulse across progress bar
	local pulseBar = Utility.Create("Frame", {
		Name = "Win7AnimatedPulse",
		Parent = fillBar,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.25,
		Position = UDim2.new(-0.35, 0, 0, 0),
		Size = UDim2.new(0.35, 0, 1, 0),
		ZIndex = fillBar.ZIndex + 2,
	})
	local pulseGrad = Instance.new("UIGradient")
	pulseGrad.Rotation = 0
	pulseGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1.00),
		NumberSequenceKeypoint.new(0.45, 0.35),
		NumberSequenceKeypoint.new(0.55, 0.25),
		NumberSequenceKeypoint.new(1.00, 1.00),
	})
	pulseGrad.Parent = pulseBar

	-- Runs continuous specular sweep loop (or indeterminate marquee)
	task.spawn(function()
		while wrapper and wrapper.Parent do
			if isMarquee then
				fillBar.Position = UDim2.new(-0.28, 0, 0, 1)
				fillBar.Size = UDim2.new(0.28, 0, 1, -2)
				Utility.Tween(fillBar, 1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, {
					Position = UDim2.new(1.02, 0, 0, 1),
				})
				task.wait(1.30)
			else
				pulseBar.Position = UDim2.new(-0.35, 0, 0, 0)
				Utility.Tween(pulseBar, 1.45, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, {
					Position = UDim2.new(1.15, 0, 0, 0),
				})
				task.wait(1.85)
			end
		end
	end)

	local controller = {
		Wrapper = wrapper,
		Value = currentVal,
		State = stateColor,
		Marquee = isMarquee,
	}

	function controller:SetMarquee(enabled)
		isMarquee = (enabled == true)
		self.Marquee = isMarquee
		if isMarquee then
			pctLbl.Text = "Working..."
			fillBar.Size = UDim2.new(0.28, 0, 1, -2)
		else
			fillBar.Position = UDim2.new(0, 1, 0, 1)
			self:SetValue(self.Value)
		end
	end

	function controller:SetState(newState)
		self.State = newState
		if newState == "Blue" then
			fillGrad.Color = Theme.Gradients.ProgressBlue
		elseif newState == "Amber" or newState == "Paused" then
			fillGrad.Color = Theme.Gradients.ProgressAmber
		elseif newState == "Red" or newState == "Error" then
			fillGrad.Color = Theme.Gradients.ProgressRed
		else
			fillGrad.Color = Theme.Gradients.ProgressGreen
		end
	end

	function controller:SetValue(newVal)
		local clamped = math.clamp(tonumber(newVal) or minVal, minVal, maxVal)
		self.Value = clamped
		local alpha = math.clamp((clamped - minVal) / (maxVal - minVal), 0, 1)
		local pct = math.floor(alpha * 100 + 0.5)
		pctLbl.Text = tostring(pct) .. "%"
		Utility.Tween(fillBar, 0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, {
			Size = UDim2.new(alpha, -2, 1, -2),
		})
	end

	function controller:SetTitle(newTitle)
		titleLbl.Text = tostring(newTitle or "")
	end

	controller:SetState(stateColor)
	controller:SetValue(currentVal)

	return controller
end

return ProgressBar
