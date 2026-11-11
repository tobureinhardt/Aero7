--!nonstrict
-- Aero7: components/ComboBox - Standard Windows 7 ComboBox and Dropdown (CBS_DROPDOWNLIST and CBS_DROPDOWN).

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Tooltip = require("components/Tooltip")

local ComboBox = {}

function ComboBox.new(parentContainer, options)
	options = options or {}
	local title = options.Title or options.Text or "ComboBox"
	local items = options.Options or options.Values or options.Items or { "Option 1", "Option 2" }
	local isMulti = options.Multi == true
	local isEditable = options.Editable == true
	local callback = options.Callback or function() end

	local currentVal
	if isMulti then
		currentVal = {}
		if type(options.Default) == "table" then
			for k, v in pairs(options.Default) do
				if type(k) == "number" then
					currentVal[v] = true
				elseif v then
					currentVal[k] = true
				end
			end
		end
	else
		currentVal = options.Default or options.Value or (isEditable and "" or items[1])
	end

	local wrapper = Utility.Create("Frame", {
		Name = "ComboBox_" .. title,
		Parent = parentContainer,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 2,
	})

	local topRow = Utility.Create("Frame", {
		Name = "ComboTopRow",
		Parent = wrapper,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 25),
		ZIndex = wrapper.ZIndex + 1,
	})

	Utility.Create("TextLabel", {
		Name = "ComboLabel",
		Parent = topRow,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0.44, -6, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = title,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = topRow.ZIndex + 1,
	})

	local comboBtn
	local selectedLabel
	local editInput
	local arrowChevron
	local arrowTriggerBtn

	if isEditable then
		-- CBS_DROPDOWN: White Edit Box with separate right drop-down button
		local editWrap = Utility.Create("Frame", {
			Name = "Win7EditableComboFrame",
			Parent = topRow,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0.44, 0, 0, 1),
			Size = UDim2.new(0.56, 0, 0, 23),
			ZIndex = topRow.ZIndex + 2,
		})
		Utility.AddCorner(editWrap, 1)
		local editStroke = Utility.AddStroke(editWrap, Theme.Colors.EditBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

		local topShadow = Utility.Create("Frame", {
			Name = "TopInsetShadow",
			Parent = editWrap,
			BackgroundColor3 = Theme.Colors.EditInnerShadow,
			Position = UDim2.new(0, 1, 0, 0),
			Size = UDim2.new(1, -22, 0, 1),
			ZIndex = editWrap.ZIndex + 1,
		})

		editInput = Utility.Create("TextBox", {
			Name = "ComboEditInput",
			Parent = editWrap,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 6, 0, 1),
			Size = UDim2.new(1, -27, 1, -2),
			ClearTextOnFocus = false,
			Font = Theme.Fonts.Regular,
			PlaceholderText = options.Placeholder or "Select or type...",
			PlaceholderColor3 = Color3.fromRGB(142, 148, 156),
			Text = tostring(currentVal or ""),
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = editWrap.ZIndex + 2,
		})

		local dropBtn = Utility.Create("TextButton", {
			Name = "ComboDropDownButton",
			Parent = editWrap,
			Position = UDim2.new(1, -20, 0, 0),
			Size = UDim2.new(0, 20, 1, 0),
			Text = "",
			ZIndex = editWrap.ZIndex + 2,
		})
		Utility.BindWin7ButtonStates(dropBtn, { CornerRadius = 1 })

		local arrowHolder = Utility.Create("Frame", {
			Name = "DownArrowGlyph",
			Parent = dropBtn,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = dropBtn.ZIndex + 2,
		})
		arrowChevron = Utility.CreateVectorChevron(arrowHolder, "Down", Color3.fromRGB(48, 56, 66), dropBtn.ZIndex + 3)

		arrowTriggerBtn = dropBtn
		comboBtn = editWrap

		local focused = false
		editWrap.MouseEnter:Connect(function()
			if not focused then
				editStroke.Color = Theme.Colors.EditBorderHover
			end
		end)
		editWrap.MouseLeave:Connect(function()
			if not focused then
				editStroke.Color = Theme.Colors.EditBorderNormal
			end
		end)
		editInput.Focused:Connect(function()
			focused = true
			editStroke.Color = Theme.Colors.EditBorderFocused
			topShadow.BackgroundColor3 = Color3.fromRGB(192, 222, 246)
		end)
		editInput.FocusLost:Connect(function()
			focused = false
			editStroke.Color = Theme.Colors.EditBorderNormal
			topShadow.BackgroundColor3 = Theme.Colors.EditInnerShadow
		end)
	else
		-- CBS_DROPDOWNLIST: Full-width button style
		comboBtn = Utility.Create("TextButton", {
			Name = "Win7ComboBoxButton",
			Parent = topRow,
			Position = UDim2.new(0.44, 0, 0, 1),
			Size = UDim2.new(0.56, 0, 0, 23),
			Text = "",
			ZIndex = topRow.ZIndex + 2,
		})
		Utility.BindWin7ButtonStates(comboBtn, { CornerRadius = 3 })

		selectedLabel = Utility.Create("TextLabel", {
			Name = "SelectedValueText",
			Parent = comboBtn,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 0, 0),
			Size = UDim2.new(1, -30, 1, 0),
			Font = Theme.Fonts.Regular,
			Text = "",
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = comboBtn.ZIndex + 2,
		})

		Utility.Create("Frame", {
			Name = "ArrowCompartmentDivider",
			Parent = comboBtn,
			BackgroundColor3 = Color3.fromRGB(182, 186, 190),
			Position = UDim2.new(1, -20, 0, 2),
			Size = UDim2.new(0, 1, 1, -4),
			ZIndex = comboBtn.ZIndex + 2,
		})

		local arrowHolder = Utility.Create("Frame", {
			Name = "DownArrowGlyph",
			Parent = comboBtn,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -19, 0, 0),
			Size = UDim2.new(0, 19, 1, 0),
			ZIndex = comboBtn.ZIndex + 2,
		})
		arrowChevron = Utility.CreateVectorChevron(arrowHolder, "Down", Color3.fromRGB(48, 56, 66), comboBtn.ZIndex + 3)

		arrowTriggerBtn = comboBtn
	end

	-- Popup dropdown list frame
	local listPopup = Utility.Create("ScrollingFrame", {
		Name = "Win7DropdownPopupList",
		Parent = wrapper,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0.44, 0, 0, 26),
		Size = UDim2.new(0.56, 0, 0, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromRGB(168, 186, 208),
		Visible = false,
		ZIndex = wrapper.ZIndex + 20,
	})
	Utility.AddCorner(listPopup, 2)
	Utility.AddStroke(listPopup, Color3.fromRGB(100, 100, 100), 1, 0, Enum.ApplyStrokeMode.Border)

	local popPad = Instance.new("UIPadding")
	popPad.PaddingTop = UDim.new(0, 2)
	popPad.PaddingBottom = UDim.new(0, 2)
	popPad.PaddingLeft = UDim.new(0, 2)
	popPad.PaddingRight = UDim.new(0, 2)
	popPad.Parent = listPopup

	local popLayout = Instance.new("UIListLayout")
	popLayout.SortOrder = Enum.SortOrder.LayoutOrder
	popLayout.Padding = UDim.new(0, 1)
	popLayout.Parent = listPopup

	local isOpen = false

	local controller = {
		Wrapper = wrapper,
		Button = comboBtn,
		EditInput = editInput,
		Label = selectedLabel,
		Popup = listPopup,
		Value = currentVal,
		Options = items,
		IsEditable = isEditable,
	}

	local function formatDisplayText()
		if isEditable then
			if editInput then
				editInput.Text = tostring(controller.Value or "")
			end
		elseif isMulti then
			local selectedList = {}
			for opt, checked in pairs(controller.Value) do
				if checked then
					table.insert(selectedList, tostring(opt))
				end
			end
			if #selectedList == 0 then
				selectedLabel.Text = options.Placeholder or "None selected"
				selectedLabel.TextColor3 = Color3.fromRGB(142, 148, 156)
			else
				selectedLabel.Text = table.concat(selectedList, ", ")
				selectedLabel.TextColor3 = Theme.Colors.TextPrimary
			end
		else
			selectedLabel.Text = tostring(controller.Value or options.Placeholder or "")
			selectedLabel.TextColor3 = Theme.Colors.TextPrimary
		end
	end

	local function rebuildItems()
		for _, child in ipairs(listPopup:GetChildren()) do
			if child:IsA("GuiObject") and not child:IsA("UIPadding") and not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end

		for idx, opt in ipairs(controller.Options) do
			local itemBtn = Utility.Create("TextButton", {
				Name = "Option_" .. tostring(opt),
				Parent = listPopup,
				BackgroundColor3 = Color3.fromRGB(235, 244, 253),
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = idx,
				Text = "",
				ZIndex = listPopup.ZIndex + 1,
			})
			Utility.AddCorner(itemBtn, 2)
			local itemStroke = Utility.AddStroke(itemBtn, Color3.fromRGB(125, 162, 206), 1, 1, Enum.ApplyStrokeMode.Border)
			local itemGrad = Instance.new("UIGradient")
			itemGrad.Rotation = 90
			itemGrad.Color = Theme.Gradients.ExplorerItemHover
			itemGrad.Parent = itemBtn

			local checkMark = nil
			if isMulti then
				checkMark = Utility.Create("ImageLabel", {
					Name = "OptionCheckmark",
					Parent = itemBtn,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 5, 0, 4),
					Size = UDim2.new(0, 14, 0, 14),
					Visible = (controller.Value[opt] == true),
					ZIndex = itemBtn.ZIndex + 2,
				})
				Assets.BindIcon(checkMark, "Checkmark")
			end

			Utility.Create("TextLabel", {
				Name = "OptionText",
				Parent = itemBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, isMulti and 23 or 7, 0, 0),
				Size = UDim2.new(1, isMulti and -26 or -10, 1, 0),
				Font = Theme.Fonts.Regular,
				Text = tostring(opt),
				TextColor3 = Theme.Colors.TextPrimary,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = itemBtn.ZIndex + 2,
			})

			local function updateRowHighlight(hovered)
				local selected = isMulti and (controller.Value[opt] == true) or (controller.Value == opt)
				if hovered or selected then
					itemBtn.BackgroundTransparency = 0.05
					itemStroke.Transparency = 0.15
					itemGrad.Color = hovered and Theme.Gradients.ExplorerItemSelected or Theme.Gradients.ExplorerItemHover
				else
					itemBtn.BackgroundTransparency = 1
					itemStroke.Transparency = 1
				end
				if checkMark then
					checkMark.Visible = (controller.Value[opt] == true)
				end
			end

			updateRowHighlight(false)

			itemBtn.MouseEnter:Connect(function()
				updateRowHighlight(true)
			end)
			itemBtn.MouseLeave:Connect(function()
				updateRowHighlight(false)
			end)
			itemBtn.MouseButton1Click:Connect(function()
				if isMulti then
					controller.Value[opt] = not controller.Value[opt]
					updateRowHighlight(true)
					formatDisplayText()
					callback(controller.Value)
				else
					controller:SetValue(opt)
					isOpen = false
					listPopup.Visible = false
					arrowChevron:SetDirection("Down")
				end
			end)
		end

		local targetHeight = math.min(#controller.Options * 23 + 6, 142)
		listPopup.Size = UDim2.new(0.56, 0, 0, targetHeight)
	end

	arrowTriggerBtn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			rebuildItems()
			listPopup.Visible = true
			arrowChevron:SetDirection("Up")
		else
			listPopup.Visible = false
			arrowChevron:SetDirection("Down")
		end
	end)

	if isEditable and editInput then
		editInput.FocusLost:Connect(function()
			controller.Value = editInput.Text
			callback(controller.Value)
		end)
	end

	function controller:SetValue(newVal, silent)
		if isMulti and type(newVal) == "table" then
			self.Value = newVal
		else
			self.Value = newVal
		end
		formatDisplayText()
		if isOpen then
			rebuildItems()
		end
		if not silent then
			callback(self.Value)
		end
	end

	function controller:SetOptions(newOptions)
		self.Options = newOptions or {}
		if not isMulti and not isEditable and not table.find(self.Options, self.Value) then
			self.Value = self.Options[1]
		end
		formatDisplayText()
		rebuildItems()
	end

	formatDisplayText()
	rebuildItems()

	if options.Tooltip then
		Tooltip.Attach(comboBtn, options.Tooltip)
	end

	return controller
end

return ComboBox
