--!nonstrict
-- Aero7: components/Spinner - Windows 7 NumericUpDown (input[type="number"]) with up/down spin buttons and loader delegate.

local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")
local LoadingSpinner = require("components/LoadingSpinner")

local Spinner = {}

-- Renders 4-tier solid triangle arrow per 7.css gui/icon/button-up.svg & button-down.svg:
-- button-up.svg:   <path d="M8 6H7V7H6V8H5V9H4V10H11V9H10V8H9V7H8V6Z" fill="url(#grad)"/>
-- button-down.svg: <path d="M11 6H4V7H5V8H6V9H7V10H8V9H9V8H10V7H11V6Z" fill="url(#grad)"/>
-- linearGradient x1="0%" y1="0%" x2="100%" y2="0%": stop 0% #333333 -> stop 100% #aaaaaa
local function create7CssButtonArrow(parentBtn, direction, zIndex)
	local arrowHost = Utility.Create("Frame", {
		Name = "Win7SvgArrow_" .. direction,
		Parent = parentBtn,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 7, 0, 4),
		ZIndex = zIndex,
	})

	local widths = (direction == "Up") and { 1, 3, 5, 7 } or { 7, 5, 3, 1 }
	for rowIdx, w in ipairs(widths) do
		local xOff = math.floor((7 - w) / 2)
		local bar = Utility.Create("Frame", {
			Name = "ArrowRow_" .. tostring(rowIdx),
			Parent = arrowHost,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Position = UDim2.new(0, xOff, 0, rowIdx - 1),
			Size = UDim2.new(0, w, 0, 1),
			ZIndex = zIndex + 1,
		})
		local grad = Instance.new("UIGradient")
		grad.Rotation = 0
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(51, 51, 51)),    -- #333333
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(170, 170, 170)), -- #aaaaaa
		})
		grad.Parent = bar
	end

	return arrowHost
end

-- Applies --w7-el-* variables from 7.css for step buttons
local function style7CssStepButton(btn)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.AutoButtonColor = false
	Utility.AddCorner(btn, 2)

	-- border: 1px solid var(--w7-el-bd) (#8e8f8f)
	local outerStroke = Utility.AddStroke(btn, Color3.fromRGB(142, 143, 143), 1, 0, Enum.ApplyStrokeMode.Border)

	-- box-shadow: var(--w7-el-sd) (inset 0 0 0 1px #fffc)
	local innerRim = Utility.Create("Frame", {
		Name = "InnerHighlightRim",
		Parent = btn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = btn.ZIndex + 1,
	})
	Utility.AddCorner(innerRim, 1)
	local innerStroke = Utility.AddStroke(innerRim, Color3.fromRGB(255, 255, 255), 1, 0.20, Enum.ApplyStrokeMode.Border)

	local bgGrad = Instance.new("UIGradient")
	bgGrad.Rotation = 90
	-- --w7-el-grad: linear-gradient(#f2f2f2 45%, #ebebeb 45%, #cfcfcf)
	local gradNormal = ColorSequence.new({
		ColorSequenceKeypoint.new(0.000, Color3.fromRGB(242, 242, 242)), -- #f2f2f2
		ColorSequenceKeypoint.new(0.449, Color3.fromRGB(242, 242, 242)), -- #f2f2f2 45%
		ColorSequenceKeypoint.new(0.450, Color3.fromRGB(235, 235, 235)), -- #ebebeb 45%
		ColorSequenceKeypoint.new(1.000, Color3.fromRGB(207, 207, 207)), -- #cfcfcf 100%
	})
	-- --w7-el-grad-h: linear-gradient(#eaf6fd 45%, #bee6fd 45%, #a7d9f5)
	local gradHover = ColorSequence.new({
		ColorSequenceKeypoint.new(0.000, Color3.fromRGB(234, 246, 253)), -- #eaf6fd
		ColorSequenceKeypoint.new(0.449, Color3.fromRGB(234, 246, 253)), -- #eaf6fd 45%
		ColorSequenceKeypoint.new(0.450, Color3.fromRGB(190, 230, 253)), -- #bee6fd 45%
		ColorSequenceKeypoint.new(1.000, Color3.fromRGB(167, 217, 245)), -- #a7d9f5 100%
	})
	-- --w7-el-grad-a: linear-gradient(#e5f4fc, #c4e5f6 30% 50%, #98d1ef 50%, #68b3db)
	local gradActive = ColorSequence.new({
		ColorSequenceKeypoint.new(0.000, Color3.fromRGB(229, 244, 252)), -- #e5f4fc
		ColorSequenceKeypoint.new(0.300, Color3.fromRGB(196, 229, 246)), -- #c4e5f6 30%
		ColorSequenceKeypoint.new(0.499, Color3.fromRGB(196, 229, 246)), -- #c4e5f6 50%
		ColorSequenceKeypoint.new(0.500, Color3.fromRGB(152, 209, 239)), -- #98d1ef 50%
		ColorSequenceKeypoint.new(1.000, Color3.fromRGB(104, 179, 219)), -- #68b3db 100%
	})
	bgGrad.Color = gradNormal
	bgGrad.Parent = btn

	local isHovered = false
	local isPressed = false

	local function syncState()
		if isPressed then
			outerStroke.Color = Color3.fromRGB(109, 145, 171) -- --w7-el-bd-a: #6d91ab
			innerStroke.Color = Color3.fromRGB(0, 0, 0)       -- --w7-el-sd-a: inset 1px 1px 0 #0003
			innerStroke.Transparency = 0.80
			bgGrad.Color = gradActive
		elseif isHovered then
			outerStroke.Color = Color3.fromRGB(60, 127, 177)  -- --w7-el-bd-h: #3c7fb1
			innerStroke.Color = Color3.fromRGB(255, 255, 255) -- --w7-el-sd: inset 0 0 0 1px #fffc
			innerStroke.Transparency = 0.20
			bgGrad.Color = gradHover
		else
			outerStroke.Color = Color3.fromRGB(142, 143, 143) -- --w7-el-bd: #8e8f8f
			innerStroke.Color = Color3.fromRGB(255, 255, 255) -- --w7-el-sd: inset 0 0 0 1px #fffc
			innerStroke.Transparency = 0.20
			bgGrad.Color = gradNormal
		end
	end

	btn.MouseEnter:Connect(function()
		isHovered = true
		syncState()
	end)
	btn.MouseLeave:Connect(function()
		isHovered = false
		isPressed = false
		syncState()
	end)
	btn.MouseButton1Down:Connect(function()
		isPressed = true
		syncState()
	end)
	btn.MouseButton1Up:Connect(function()
		isPressed = false
		syncState()
	end)
end

function Spinner.new(parentContainer, options)
	options = options or {}

	-- If invoked as loader (.spinner/.loader without min/max/step/value), delegates to LoadingSpinner
	if
		options.Mode == "Loader"
		or options.Animate ~= nil
		or (
			options.Min == nil
			and options.Max == nil
			and options.Step == nil
			and options.Default == nil
			and options.Value == nil
		)
	then
		return LoadingSpinner.new(parentContainer, options)
	end

	local title = options.Title or options.Text or "Number Spinner"
	local minVal = tonumber(options.Min) or 0
	local maxVal = tonumber(options.Max) or 100
	local step = tonumber(options.Step) or 1
	local suffix = options.Suffix or ""
	local currentVal = math.clamp(tonumber(options.Default or options.Value) or minVal, minVal, maxVal)
	local callback = options.Callback or function() end

	local row = Utility.Create("Frame", {
		Name = "Spinner_" .. title,
		Parent = parentContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 25),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})

	Utility.Create("TextLabel", {
		Name = "SpinnerLabel",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0.54, -6, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Color3.fromRGB(0, 0, 0), -- --w7-el-c: #000000
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = row.ZIndex + 1,
	})

	-- input[type="number"] frame per 7.css gui/_textbox.scss:
	-- height: 23px; padding: 3px 4px 5px; border: 1px solid; border-radius: 2px; background-color: #fff;
	local boxWrap = Utility.Create("Frame", {
		Name = "Win7SpinnerFrame",
		Parent = row,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- #ffffff
		Position = UDim2.new(0.54, 0, 0, 1),
		Size = UDim2.new(0.46, 0, 0, 23), -- height: 23px
		ZIndex = row.ZIndex + 1,
	})
	Utility.AddCorner(boxWrap, 2) -- border-radius: 2px

	-- 4-edge border per 7.css gui/_textbox.scss (vertical UIGradient from top to bottom):
	-- Normal: border-color: #abadb3 #dbdfe6 #e3e9ef #e2e3ea
	-- Hover:  border-color: #5794bf #b7d5ea #c7e2f1 #c5daed
	-- Focus:  border-color: #3d7bad #a4c9e3 #b7d9ed #b5cfe7
	local boxStroke = Utility.AddStroke(boxWrap, Color3.fromRGB(255, 255, 255), 1, 0, Enum.ApplyStrokeMode.Border)
	local strokeGrad = Instance.new("UIGradient")
	strokeGrad.Rotation = 90

	local borderNormalSeq = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(171, 173, 179)), -- #abadb3 (top)
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(219, 223, 230)), -- #dbdfe6 / #e2e3ea (left/right)
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(227, 233, 239)), -- #e3e9ef (bottom)
	})
	local borderHoverSeq = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(87, 148, 191)),  -- #5794bf (top)
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(183, 213, 234)), -- #b7d5ea / #c5daed (left/right)
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(199, 226, 241)), -- #c7e2f1 (bottom)
	})
	local borderFocusSeq = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(61, 123, 173)),  -- #3d7bad (top)
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(164, 201, 227)), -- #a4c9e3 / #b5cfe7 (left/right)
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(183, 217, 237)), -- #b7d9ed (bottom)
	})
	strokeGrad.Color = borderNormalSeq
	strokeGrad.Parent = boxStroke

	local inputBox = Utility.Create("TextBox", {
		Name = "SpinnerInput",
		Parent = boxWrap,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0, 3), -- padding: 3px 4px 5px
		Size = UDim2.new(1, -23, 1, -6),
		ClearTextOnFocus = false,
		Font = Theme.Fonts.Regular,
		Text = tostring(currentVal) .. suffix,
		TextColor3 = Color3.fromRGB(0, 0, 0), -- --w7-el-c: #000000
		TextSize = 12,                        -- --w7-font: 9pt Segoe UI (12px)
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = boxWrap.ZIndex + 2,
	})

	-- Stacked Up / Down spin button pair at right edge (16x21px)
	local spinButtonsCol = Utility.Create("Frame", {
		Name = "UpDownButtonsColumn",
		Parent = boxWrap,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -17, 0, 1),
		Size = UDim2.new(0, 16, 1, -2),
		ZIndex = boxWrap.ZIndex + 2,
	})

	local upBtn = Utility.Create("TextButton", {
		Name = "SpinUpButton",
		Parent = spinButtonsCol,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 10),
		Text = "",
		ZIndex = spinButtonsCol.ZIndex + 1,
	})
	style7CssStepButton(upBtn)
	create7CssButtonArrow(upBtn, "Up", spinButtonsCol.ZIndex + 3)

	local downBtn = Utility.Create("TextButton", {
		Name = "SpinDownButton",
		Parent = spinButtonsCol,
		Position = UDim2.new(0, 0, 0, 11),
		Size = UDim2.new(1, 0, 0, 10),
		Text = "",
		ZIndex = spinButtonsCol.ZIndex + 1,
	})
	style7CssStepButton(downBtn)
	create7CssButtonArrow(downBtn, "Down", spinButtonsCol.ZIndex + 3)

	local controller = {
		Row = row,
		Value = currentVal,
	}

	function controller:SetValue(newVal, silent)
		local n = tonumber(newVal) or self.Value
		local snapped = minVal + math.floor(((n - minVal) / step) + 0.5) * step
		snapped = math.clamp(snapped, minVal, maxVal)
		self.Value = snapped
		inputBox.Text = tostring(snapped) .. suffix
		if not silent then
			callback(snapped)
		end
	end

	upBtn.MouseButton1Click:Connect(function()
		controller:SetValue(controller.Value + step)
	end)

	downBtn.MouseButton1Click:Connect(function()
		controller:SetValue(controller.Value - step)
	end)

	local isFocused = false
	local isBoxHovered = false

	boxWrap.MouseEnter:Connect(function()
		isBoxHovered = true
		if not isFocused then
			strokeGrad.Color = borderHoverSeq
		end
	end)

	boxWrap.MouseLeave:Connect(function()
		isBoxHovered = false
		if not isFocused then
			strokeGrad.Color = borderNormalSeq
		end
	end)

	inputBox.Focused:Connect(function()
		isFocused = true
		strokeGrad.Color = borderFocusSeq
	end)

	inputBox.FocusLost:Connect(function()
		isFocused = false
		strokeGrad.Color = isBoxHovered and borderHoverSeq or borderNormalSeq
		local numStr = inputBox.Text:gsub("[^%d%.%-]", "")
		local parsed = tonumber(numStr)
		if parsed then
			controller:SetValue(parsed)
		else
			inputBox.Text = tostring(controller.Value) .. suffix
		end
	end)

	if options.Tooltip then
		Tooltip.Attach(boxWrap, options.Tooltip)
	end

	return controller
end

return Spinner
