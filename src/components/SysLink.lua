--!nonstrict
-- Aero7: components/SysLink - Windows 7 SysLink hyperlink and PropertyGrid system summary with WEI score badge.

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")

local SysLink = {}

function SysLink.new(parentContainer, options)
	if type(options) == "string" then
		options = { Text = options }
	end
	options = options or {}

	local text = options.Text or options.Title or "Learn more about Windows 7 Aero settings"
	local prefix = options.Prefix or ""
	local iconName = options.Icon
	local callback = options.Callback or function() end

	local row = Utility.Create("Frame", {
		Name = "SysLinkRow_" .. text:sub(1, 16),
		Parent = parentContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 5)
	list.Parent = row

	if iconName and iconName ~= "" then
		local ico = Utility.Create("ImageLabel", {
			Name = "LinkIcon",
			Parent = row,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 14, 0, 14),
			LayoutOrder = 1,
			ZIndex = row.ZIndex + 1,
		})
		Assets.BindIcon(ico, iconName)
	end

	if prefix ~= "" then
		Utility.Create("TextLabel", {
			Name = "PrefixText",
			Parent = row,
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 1, 0),
			LayoutOrder = 2,
			Font = Theme.Fonts.Regular,
			Text = prefix,
			TextColor3 = Theme.Colors.TextSecondary,
			TextSize = 12,
			ZIndex = row.ZIndex + 1,
		})
	end

	local linkBtn = Utility.Create("TextButton", {
		Name = "SysLinkButton",
		Parent = row,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 18),
		LayoutOrder = 3,
		Font = Theme.Fonts.Regular,
		Text = text,
		TextColor3 = Theme.Colors.TextLink,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = row.ZIndex + 1,
	})

	local underline = Utility.Create("Frame", {
		Name = "LinkUnderline",
		Parent = linkBtn,
		BackgroundColor3 = Theme.Colors.TextLinkHover,
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 1),
		Visible = false,
		ZIndex = linkBtn.ZIndex + 1,
	})

	linkBtn.MouseEnter:Connect(function()
		linkBtn.TextColor3 = Theme.Colors.TextLinkHover
		underline.Visible = true
	end)
	linkBtn.MouseLeave:Connect(function()
		linkBtn.TextColor3 = Theme.Colors.TextLink
		underline.Visible = false
	end)
	linkBtn.MouseButton1Click:Connect(function()
		callback()
	end)

	if options.Tooltip then
		Tooltip.Attach(linkBtn, options.Tooltip)
	end

	return {
		Row = row,
		Button = linkBtn,
		SetText = function(_, newText)
			linkBtn.Text = tostring(newText or "")
		end,
		Fire = function()
			callback()
		end,
	}
end

-- Key-value summary panel for Control Panel > System ("Windows Experience Index" / Details Pane)
function SysLink.CreatePropertyGrid(parentContainer, options)
	options = options or {}
	local title = options.Title or "System Summary"
	local rows = options.Properties or options.Rows or {}
	local weiScore = options.Rating or options.WEIScore -- e.g. 7.9

	local card = Utility.Create("Frame", {
		Name = "PropertyGrid_" .. title,
		Parent = parentContainer,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(249, 252, 255),
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	Utility.AddCorner(card, 3)
	Utility.AddStroke(card, Theme.Colors.GroupBoxBorder, 1, 0, Enum.ApplyStrokeMode.Border)

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = card

	local header = Utility.Create("TextLabel", {
		Name = "SummaryHeader",
		Parent = card,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, weiScore and -66 or 0, 0, 18),
		Font = Theme.Fonts.Semibold,
		Text = title,
		TextColor3 = Theme.Colors.TextInstruction,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = card.ZIndex + 1,
	})

	-- Windows Experience Index badge (1.0 - 7.9) from Windows 7 System Properties
	local badgeScoreLbl = nil
	if weiScore ~= nil then
		local badge = Utility.Create("Frame", {
			Name = "WEIBadge",
			Parent = card,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(1, -54, 0, 0),
			Size = UDim2.new(0, 54, 0, 38),
			ZIndex = card.ZIndex + 2,
		})
		Utility.AddCorner(badge, 4)
		Utility.AddStroke(badge, Color3.fromRGB(54, 114, 176), 1, 0, Enum.ApplyStrokeMode.Border)
		local bGrad = Instance.new("UIGradient")
		bGrad.Rotation = 90
		bGrad.Color = Theme.MakeSplitSequence(
			Color3.fromRGB(224, 242, 255),
			Color3.fromRGB(168, 214, 250),
			Color3.fromRGB(84, 154, 222),
			Color3.fromRGB(134, 194, 245)
		)
		bGrad.Parent = badge

		badgeScoreLbl = Utility.Create("TextLabel", {
			Name = "ScoreValue",
			Parent = badge,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 1),
			Size = UDim2.new(1, 0, 0, 22),
			Font = Theme.Fonts.Bold,
			Text = tostring(weiScore),
			TextColor3 = Color3.fromRGB(14, 44, 88),
			TextSize = 18,
			ZIndex = badge.ZIndex + 1,
		})
		Utility.Create("TextLabel", {
			Name = "ScoreSub",
			Parent = badge,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 22),
			Size = UDim2.new(1, 0, 0, 13),
			Font = Theme.Fonts.Regular,
			Text = "WEI Base",
			TextColor3 = Color3.fromRGB(22, 62, 114),
			TextSize = 10,
			ZIndex = badge.ZIndex + 1,
		})
	end

	local rowsHost = Utility.Create("Frame", {
		Name = "RowsContainer",
		Parent = card,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 22),
		Size = UDim2.new(1, weiScore and -62 or 0, 0, 0),
		ZIndex = card.ZIndex + 1,
	})
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 3)
	list.Parent = rowsHost

	local valueLabels = {}

	local function renderRows()
		for _, child in ipairs(rowsHost:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
		valueLabels = {}

		for idx, entry in ipairs(rows) do
			local k = entry.Key or entry.Name or entry[1] or ("Property " .. idx)
			local v = entry.Value or entry[2] or ""
			local r = Utility.Create("Frame", {
				Name = "PropRow_" .. tostring(idx),
				Parent = rowsHost,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				LayoutOrder = idx,
				ZIndex = rowsHost.ZIndex + 1,
			})
			Utility.Create("TextLabel", {
				Name = "PropKey",
				Parent = r,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(0.42, -4, 1, 0),
				Font = Theme.Fonts.Regular,
				Text = tostring(k) .. ":",
				TextColor3 = Theme.Colors.TextSecondary,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = r.ZIndex + 1,
			})
			local vLbl = Utility.Create("TextLabel", {
				Name = "PropValue",
				Parent = r,
				BackgroundTransparency = 1,
				Position = UDim2.new(0.42, 4, 0, 0),
				Size = UDim2.new(0.58, -4, 1, 0),
				Font = Theme.Fonts.Semibold,
				Text = tostring(v),
				TextColor3 = Theme.Colors.TextPrimary,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = r.ZIndex + 1,
			})
			valueLabels[k] = vLbl
		end
	end

	renderRows()

	return {
		Card = card,
		Header = header,
		SetProperty = function(_, key, newValue)
			if valueLabels[key] then
				valueLabels[key].Text = tostring(newValue or "")
				return
			end
			table.insert(rows, { Key = key, Value = newValue })
			renderRows()
		end,
		SetRating = function(_, newScore)
			if badgeScoreLbl then
				badgeScoreLbl.Text = tostring(newScore)
			end
		end,
	}
end

return SysLink
