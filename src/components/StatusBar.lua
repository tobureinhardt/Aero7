--!nonstrict
-- Aero7: components/StatusBar - Multi-pane StatusBar with sunken well cells and resize gripper (msctls_statusbar32).

local Theme = require("core/Theme")
local Utility = require("core/Utility")

local StatusBar = {}

function StatusBar.new(parentContainer, options)
	options = options or {}
	local fields = options.Fields or options.Items or { options.Text or "Ready" }
	local showGrip = (options.ShowGrip ~= false)

	local bar = Utility.Create("Frame", {
		Name = "Win7StatusBar",
		Parent = parentContainer,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 23),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	Utility.AddStroke(bar, Theme.Colors.ExplorerStatusBarBorder, 1, 0, Enum.ApplyStrokeMode.Border)

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Theme.Colors.ExplorerStatusBarTop),
		ColorSequenceKeypoint.new(1.0, Theme.Colors.ExplorerStatusBarBot),
	})
	grad.Parent = bar

	local fieldsHost = Utility.Create("Frame", {
		Name = "StatusFieldsContainer",
		Parent = bar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, showGrip and -18 or -4, 1, -4),
		ZIndex = bar.ZIndex + 1,
	})

	local fieldLabels = {}

	local function rebuildFields()
		for _, child in ipairs(fieldsHost:GetChildren()) do
			child:Destroy()
		end
		fieldLabels = {}

		local count = math.max(1, #fields)
		local widthScale = 1 / count

		for i, item in ipairs(fields) do
			local text = type(item) == "table" and (item.Text or item.Title or "") or tostring(item or "")
			local cell = Utility.Create("Frame", {
				Name = "StatusBarField_" .. tostring(i),
				Parent = fieldsHost,
				BackgroundColor3 = Color3.fromRGB(236, 242, 249),
				BackgroundTransparency = 0.45,
				Position = UDim2.new(widthScale * (i - 1), (i == 1) and 0 or 2, 0, 0),
				Size = UDim2.new(widthScale, (i == 1) and -1 or -3, 1, 0),
				ZIndex = fieldsHost.ZIndex + 1,
			})
			Utility.AddStroke(cell, Color3.fromRGB(204, 216, 230), 1, 0.15, Enum.ApplyStrokeMode.Border)

			-- 1px bottom/right light edge for sunken well (inset recessed cell per msctls_statusbar32)
			Utility.Create("Frame", {
				Name = "BottomHighlight",
				Parent = cell,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.25,
				Position = UDim2.new(0, 0, 1, -1),
				Size = UDim2.new(1, 0, 0, 1),
				ZIndex = cell.ZIndex + 1,
			})

			local lbl = Utility.Create("TextLabel", {
				Name = "FieldText",
				Parent = cell,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 6, 0, 0),
				Size = UDim2.new(1, -10, 1, 0),
				Font = Theme.Fonts.Regular,
				Text = text,
				TextColor3 = Theme.Colors.TextPrimary,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = cell.ZIndex + 2,
			})
			fieldLabels[i] = lbl
		end
	end

	if showGrip then
		local grip = Utility.Create("Frame", {
			Name = "StatusBarGripDots",
			Parent = bar,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -13, 1, -13),
			Size = UDim2.new(0, 11, 0, 11),
			ZIndex = bar.ZIndex + 2,
		})
		local dotCoords = {
			{ 7, 7 },
			{ 4, 7 }, { 7, 4 },
			{ 1, 7 }, { 4, 4 }, { 7, 1 },
		}
		for idx, pt in ipairs(dotCoords) do
			Utility.Create("Frame", {
				Name = "GripLight_" .. idx,
				Parent = grip,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Position = UDim2.new(0, pt[1] + 1, 0, pt[2] + 1),
				Size = UDim2.new(0, 2, 0, 2),
				ZIndex = grip.ZIndex + 1,
			})
			Utility.Create("Frame", {
				Name = "GripDark_" .. idx,
				Parent = grip,
				BackgroundColor3 = Color3.fromRGB(142, 158, 178),
				Position = UDim2.new(0, pt[1], 0, pt[2]),
				Size = UDim2.new(0, 2, 0, 2),
				ZIndex = grip.ZIndex + 2,
			})
		end
	end

	rebuildFields()

	local controller = {
		Bar = bar,
		Fields = fields,
	}

	function controller:SetField(index, newText)
		fields[index] = tostring(newText or "")
		if fieldLabels[index] then
			fieldLabels[index].Text = fields[index]
		else
			rebuildFields()
		end
	end

	function controller:SetFields(newFields)
		if type(newFields) == "table" then
			fields = newFields
			self.Fields = fields
			rebuildFields()
		end
	end

	return controller
end

return StatusBar
