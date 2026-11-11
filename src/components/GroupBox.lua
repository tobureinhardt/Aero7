--!nonstrict
-- Aero7: components/GroupBox - Windows 7 GroupBox container (<fieldset> + <legend>).

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")

local GroupBox = {}

function GroupBox.new(parentContainer, options, componentFactory, onChildAdded)
	if type(options) == "string" then
		options = { Title = options }
	end
	options = options or {}

	local title = options.Title or "GroupBox"
	local iconName = options.Icon
	local bgMaskColor = options.BackgroundColor or Color3.fromRGB(255, 255, 255)

	local wrapper = Utility.Create("Frame", {
		Name = "GroupBox_" .. title,
		Parent = parentContainer,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})

	-- Border frame starting at Y = 8px so legend label centers over top border line
	local borderBox = Utility.Create("Frame", {
		Name = "FieldsetBorderBox",
		Parent = wrapper,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.new(1, 0, 0, 28),
		ZIndex = wrapper.ZIndex,
	})
	Utility.AddCorner(borderBox, 3)
	Utility.AddStroke(borderBox, Theme.Colors.GroupBoxBorder, 1, 0, Enum.ApplyStrokeMode.Border)

	-- Legend label masking top border line at X = 10px (supports 14x14 icon)
	local legendMask = Utility.Create("Frame", {
		Name = "LegendTitleMask",
		Parent = wrapper,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = bgMaskColor,
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 9, 0, 0),
		Size = UDim2.new(0, 0, 0, 16),
		ZIndex = wrapper.ZIndex + 2,
	})
	local maskPad = Instance.new("UIPadding")
	maskPad.PaddingLeft = UDim.new(0, 5)
	maskPad.PaddingRight = UDim.new(0, 5)
	maskPad.Parent = legendMask

	local maskList = Instance.new("UIListLayout")
	maskList.FillDirection = Enum.FillDirection.Horizontal
	maskList.VerticalAlignment = Enum.VerticalAlignment.Center
	maskList.SortOrder = Enum.SortOrder.LayoutOrder
	maskList.Padding = UDim.new(0, 4)
	maskList.Parent = legendMask

	if iconName and iconName ~= "" then
		local legendIcon = Utility.Create("ImageLabel", {
			Name = "LegendIcon",
			Parent = legendMask,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(0, 14, 0, 14),
			ZIndex = wrapper.ZIndex + 3,
		})
		Assets.BindIcon(legendIcon, iconName)
	end

	local legendLabel = Utility.Create("TextLabel", {
		Name = "LegendTitleText",
		Parent = legendMask,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Theme.Colors.TextGroupTitle, -- #1E395B
		TextSize = 13,
		ZIndex = wrapper.ZIndex + 3,
	})

	-- Inner container hosting child controls
	local innerContent = Utility.Create("Frame", {
		Name = "GroupBoxContent",
		Parent = borderBox,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = wrapper.ZIndex + 1,
	})
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = innerContent

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = innerContent

	local groupObj = {
		Wrapper = wrapper,
		Container = innerContent,
		LegendLabel = legendLabel,
		SetTitle = function(_, newTitle)
			legendLabel.Text = tostring(newTitle or "")
		end,
	}

	if componentFactory then
		componentFactory:AttachToContainer(groupObj, innerContent, onChildAdded)
	end

	if onChildAdded then
		onChildAdded()
	end

	return groupObj
end

return GroupBox
