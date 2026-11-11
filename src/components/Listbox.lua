--!nonstrict
-- Aero7: components/Listbox - Multi-select Listbox (<select multiple>), standalone SearchBox, and Expander.

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Scrollbar = require("components/Scrollbar")

local Listbox = {}

function Listbox.new(parentContainer, options)
	options = options or {}
	local title = options.Title
	local items = options.Options or options.Items or { "Item 1", "Item 2", "Item 3" }
	local isMulti = options.Multi == true
	local height = tonumber(options.Height) or 110
	local callback = options.Callback or function() end

	local selected = {}
	if isMulti and type(options.Default) == "table" then
		for k, v in pairs(options.Default) do
			if type(k) == "number" then
				selected[v] = true
			elseif v then
				selected[k] = true
			end
		end
	elseif not isMulti then
		selected = options.Default or items[1]
	end

	local wrap = Utility.Create("Frame", {
		Name = "Listbox_" .. tostring(title or "Select"),
		Parent = parentContainer,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	local wList = Instance.new("UIListLayout")
	wList.SortOrder = Enum.SortOrder.LayoutOrder
	wList.Padding = UDim.new(0, 4)
	wList.Parent = wrap

	if title and title ~= "" then
		Utility.Create("TextLabel", {
			Name = "ListboxHeader",
			Parent = wrap,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = 1,
			Font = Theme.Fonts.Regular,
			Text = title,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = wrap.ZIndex + 1,
		})
	end

	local boxFrame = Utility.Create("Frame", {
		Name = "Win7ListboxFrame",
		Parent = wrap,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, height),
		ClipsDescendants = true,
		LayoutOrder = 2,
		ZIndex = wrap.ZIndex + 1,
	})
	Utility.AddStroke(boxFrame, Theme.Colors.EditBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

	local scroll = Utility.Create("ScrollingFrame", {
		Name = "ListboxScroll",
		Parent = boxFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = boxFrame.ZIndex + 1,
	})
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 2)
	pad.PaddingLeft = UDim.new(0, 2)
	pad.PaddingRight = UDim.new(0, 2)
	pad.Parent = scroll

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 1)
	list.Parent = scroll

	Scrollbar.Attach(scroll)

	local controller = {
		Wrapper = wrap,
		Value = selected,
	}

	local itemEntries = {}
	local function refreshAll()
		for _, entry in ipairs(itemEntries) do
			local isSel = isMulti and (controller.Value[entry.Item] == true) or (controller.Value == entry.Item)
			if isSel then
				entry.Grad.Color = Theme.Gradients.ExplorerItemSelected
				entry.Btn.BackgroundTransparency = 0.05
				entry.Stroke.Transparency = 0.1
			else
				entry.Btn.BackgroundTransparency = 1
				entry.Stroke.Transparency = 1
			end
		end
	end

	for idx, item in ipairs(items) do
		local rBtn = Utility.Create("TextButton", {
			Name = "ListItem_" .. tostring(item),
			Parent = scroll,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			LayoutOrder = idx,
			Text = "",
			ZIndex = scroll.ZIndex + 1,
		})
		Utility.AddCorner(rBtn, 2)
		local rStroke = Utility.AddStroke(rBtn, Theme.Colors.SelectionBorder, 1, 1, Enum.ApplyStrokeMode.Border)
		local rGrad = Instance.new("UIGradient")
		rGrad.Rotation = 90
		rGrad.Color = Theme.Gradients.ExplorerItemSelected
		rGrad.Parent = rBtn

		Utility.Create("TextLabel", {
			Name = "ItemText",
			Parent = rBtn,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 6, 0, 0),
			Size = UDim2.new(1, -12, 1, 0),
			Font = Theme.Fonts.Regular,
			Text = tostring(item),
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = rBtn.ZIndex + 1,
		})

		rBtn.MouseEnter:Connect(function()
			local isSel = isMulti and (controller.Value[item] == true) or (controller.Value == item)
			if not isSel then
				rGrad.Color = Theme.Gradients.ExplorerItemHover
				rBtn.BackgroundTransparency = 0.1
				rStroke.Transparency = 0.25
			end
		end)
		rBtn.MouseLeave:Connect(function()
			refreshAll()
		end)
		rBtn.MouseButton1Click:Connect(function()
			if isMulti then
				controller.Value[item] = not controller.Value[item]
			else
				controller.Value = item
			end
			refreshAll()
			callback(controller.Value)
		end)

		table.insert(itemEntries, { Item = item, Btn = rBtn, Stroke = rStroke, Grad = rGrad })
	end

	refreshAll()

	function controller:SetValue(newVal, silent)
		self.Value = newVal
		refreshAll()
		if not silent then
			callback(self.Value)
		end
	end

	return controller
end

-- Standalone SearchBox per 7.css gui/_searchbox.scss
function Listbox.CreateSearchBox(parentContainer, options)
	options = options or {}
	local placeholder = options.Placeholder or "Search..."
	local callback = options.Callback or function() end

	local wrap = Utility.Create("Frame", {
		Name = "Win7StandaloneSearchBox",
		Parent = parentContainer,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 23),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	Utility.AddCorner(wrap, 1)
	local stroke = Utility.AddStroke(wrap, Theme.Colors.EditBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

	Utility.Create("Frame", {
		Name = "TopInsetShadow",
		Parent = wrap,
		BackgroundColor3 = Theme.Colors.EditInnerShadow,
		Position = UDim2.new(0, 1, 0, 0),
		Size = UDim2.new(1, -2, 0, 1),
		ZIndex = wrap.ZIndex + 1,
	})

	local placeholderLbl = Utility.Create("TextLabel", {
		Name = "SearchPlaceholderLabel",
		Parent = wrap,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 7, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Font = Theme.Fonts.Italic,
		Text = placeholder,
		TextColor3 = Color3.fromRGB(118, 128, 140),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = wrap.ZIndex + 2,
	})

	local box = Utility.Create("TextBox", {
		Name = "SearchInput",
		Parent = wrap,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 7, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Font = Theme.Fonts.Regular,
		PlaceholderText = "",
		PlaceholderColor3 = Color3.fromRGB(118, 128, 140),
		Text = "",
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = wrap.ZIndex + 3,
	})

	local actionBtn = Utility.Create("TextButton", {
		Name = "SearchActionButton",
		Parent = wrap,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -22, 0, 1),
		Size = UDim2.new(0, 21, 1, -2),
		Text = "",
		ZIndex = wrap.ZIndex + 3,
	})

	local ico = Utility.Create("ImageLabel", {
		Name = "SearchGlyph",
		Parent = actionBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, -8, 0.5, -8),
		Size = UDim2.new(0, 16, 0, 16),
		ZIndex = actionBtn.ZIndex + 1,
	})
	Assets.BindIcon(ico, "Search")

	local clearLbl = Utility.Create("Frame", {
		Name = "ClearGlyph",
		Parent = actionBtn,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ZIndex = actionBtn.ZIndex + 2,
	})
	Utility.CreateVectorCloseX(clearLbl, Color3.fromRGB(72, 118, 172), Color3.fromRGB(220, 235, 250), actionBtn.ZIndex + 3)

	local isFocused = false
	box.Focused:Connect(function()
		isFocused = true
		stroke.Color = Theme.Colors.EditBorderFocused
		placeholderLbl.Visible = false
	end)
	box.FocusLost:Connect(function()
		isFocused = false
		stroke.Color = Theme.Colors.EditBorderNormal
		placeholderLbl.Visible = (box.Text == "")
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local hasText = box.Text ~= ""
		placeholderLbl.Visible = (not isFocused) and (not hasText)
		ico.Visible = not hasText
		clearLbl.Visible = hasText
		callback(box.Text)
	end)
	actionBtn.MouseButton1Click:Connect(function()
		if box.Text ~= "" then
			box.Text = ""
		end
	end)

	return {
		Wrapper = wrap,
		Input = box,
		SetText = function(_, t)
			box.Text = tostring(t or "")
		end,
	}
end

-- Windows 7 progressive disclosure Expander / CollapseBox
function Listbox.CreateExpander(parentContainer, options, componentFactory, onChildAdded)
	options = options or {}
	local title = options.Title or "More options"
	local expanded = (options.Default ~= false)

	local wrap = Utility.Create("Frame", {
		Name = "Expander_" .. title,
		Parent = parentContainer,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	list.Parent = wrap

	local headerBtn = Utility.Create("TextButton", {
		Name = "ExpanderHeaderButton",
		Parent = wrap,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 1,
		Text = "",
		ZIndex = wrap.ZIndex + 1,
	})

	-- Circular chevron expander button
	local chevronOrb = Utility.Create("Frame", {
		Name = "ChevronCircleButton",
		Parent = headerBtn,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 0.5, -9),
		Size = UDim2.new(0, 18, 0, 18),
		ZIndex = headerBtn.ZIndex + 1,
	})
	Utility.AddCorner(chevronOrb, 9)
	local orbStroke = Utility.AddStroke(chevronOrb, Theme.Colors.ControlBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)
	local orbGrad = Instance.new("UIGradient")
	orbGrad.Rotation = 90
	orbGrad.Color = Theme.Gradients.ButtonNormal
	orbGrad.Parent = chevronOrb

	local chevronChevron = Utility.CreateVectorChevron(
		chevronOrb,
		expanded and "Up" or "Down",
		Color3.fromRGB(30, 57, 91),
		chevronOrb.ZIndex + 1
	)

	local titleLbl = Utility.Create("TextLabel", {
		Name = "ExpanderTitle",
		Parent = headerBtn,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Theme.Colors.TextInstruction,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = headerBtn.ZIndex + 1,
	})

	local bodyContent = Utility.Create("Frame", {
		Name = "ExpanderBodyContent",
		Parent = wrap,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = expanded,
		LayoutOrder = 2,
		ZIndex = wrap.ZIndex + 1,
	})
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 18)
	pad.PaddingTop = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = bodyContent

	local bodyList = Instance.new("UIListLayout")
	bodyList.SortOrder = Enum.SortOrder.LayoutOrder
	bodyList.Padding = UDim.new(0, 6)
	bodyList.Parent = bodyContent

	headerBtn.MouseEnter:Connect(function()
		orbStroke.Color = Theme.Colors.ControlBorderHover
		orbGrad.Color = Theme.Gradients.ButtonHover
		titleLbl.TextColor3 = Theme.Colors.TextLinkHover
	end)
	headerBtn.MouseLeave:Connect(function()
		orbStroke.Color = Theme.Colors.ControlBorderNormal
		orbGrad.Color = Theme.Gradients.ButtonNormal
		titleLbl.TextColor3 = Theme.Colors.TextInstruction
	end)
	headerBtn.MouseButton1Click:Connect(function()
		expanded = not expanded
		bodyContent.Visible = expanded
		chevronChevron:SetDirection(expanded and "Up" or "Down")
	end)

	local expObj = {
		Wrapper = wrap,
		Container = bodyContent,
		SetExpanded = function(_, state)
			expanded = state == true
			bodyContent.Visible = expanded
			chevronChevron:SetDirection(expanded and "Up" or "Down")
		end,
	}

	if componentFactory then
		componentFactory:AttachToContainer(expObj, bodyContent, onChildAdded)
	end

	return expObj
end

return Listbox
