--!nonstrict
-- Aero7: components/ListView - Multi-column ListView with resizable split-gradient headers (SysListView32).

local UserInputService = game:GetService("UserInputService")
local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Scrollbar = require("components/Scrollbar")

local ListView = {}

function ListView.new(parentContainer, options)
	options = options or {}
	local columns = options.Columns or { "Name", "Status", "Value" }
	local rowsData = options.Rows or {}
	local rowIcons = options.RowIcons or {}
	local height = tonumber(options.Height) or 140
	local onSelect = options.Callback or options.OnSelect or function() end

	local numCols = math.max(#columns, 1)
	local colScales = {}
	for i = 1, numCols do
		colScales[i] = 1 / numCols
	end

	local wrapper = Utility.Create("Frame", {
		Name = "ListView_" .. tostring(options.Title or "Table"),
		Parent = parentContainer,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, height),
		ClipsDescendants = true,
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	Utility.AddStroke(wrapper, Theme.Colors.EditBorderNormal, 1, 0, Enum.ApplyStrokeMode.Border)

	-- Column header bar (SysHeader32)
	local headerBar = Utility.Create("Frame", {
		Name = "ListViewHeaderBar",
		Parent = wrapper,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 22),
		ZIndex = wrapper.ZIndex + 2,
	})
	local headerGrad = Instance.new("UIGradient")
	headerGrad.Rotation = 90
	headerGrad.Color = Theme.Gradients.ButtonNormal
	headerGrad.Parent = headerBar

	Utility.Create("Frame", {
		Name = "HeaderBottomBorder",
		Parent = headerBar,
		BackgroundColor3 = Color3.fromRGB(213, 213, 213),
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = headerBar.ZIndex + 2,
	})

	local headerCells = {}
	local rowButtons = {}

	local function getCumulativePos(idx)
		local sum = 0
		for i = 1, idx - 1 do
			sum = sum + colScales[i]
		end
		return sum
	end

	local function layoutAllColumns()
		for cIdx, hBtn in ipairs(headerCells) do
			local xPos = getCumulativePos(cIdx)
			local w = colScales[cIdx]
			hBtn.Position = UDim2.new(xPos, 0, 0, 0)
			hBtn.Size = UDim2.new(w, 0, 1, -1)
		end

		for _, rEntry in ipairs(rowButtons) do
			local rBtn = rEntry.Btn
			for cIdx = 1, numCols do
				local cell = rBtn:FindFirstChild("Cell_" .. tostring(cIdx))
				if cell then
					local xPos = getCumulativePos(cIdx)
					local w = colScales[cIdx]
					local leftOffset = (cIdx == 1 and rEntry.HasIcon) and 25 or 6
					cell.Position = UDim2.new(xPos, leftOffset, 0, 0)
					cell.Size = UDim2.new(w, -(leftOffset + 4), 1, 0)
				end
			end
		end
	end

	for cIdx, colName in ipairs(columns) do
		local colCell = Utility.Create("TextButton", {
			Name = "ColHeader_" .. tostring(colName),
			Parent = headerBar,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Position = UDim2.new(getCumulativePos(cIdx), 0, 0, 0),
			Size = UDim2.new(colScales[cIdx], 0, 1, -1),
			Font = Theme.Fonts.Regular,
			Text = "  " .. tostring(colName),
			TextColor3 = Color3.fromRGB(30, 57, 91),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = headerBar.ZIndex + 2,
		})
		headerCells[cIdx] = colCell

		if cIdx == 1 then
			local sortWrap = Utility.Create("Frame", {
				Name = "HeaderSortChevron",
				Parent = colCell,
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, -6, 0, 0),
				Size = UDim2.new(0, 12, 0, 8),
				ZIndex = colCell.ZIndex + 1,
			})
			Utility.CreateVectorChevron(sortWrap, "Up", Color3.fromRGB(110, 148, 192), colCell.ZIndex + 2)
		end

		if cIdx < numCols then
			Utility.Create("Frame", {
				Name = "ColDivider",
				Parent = colCell,
				BackgroundColor3 = Color3.fromRGB(212, 216, 222),
				Position = UDim2.new(1, -1, 0, 2),
				Size = UDim2.new(0, 1, 1, -4),
				ZIndex = colCell.ZIndex + 1,
			})

			-- Column resizer drag handle
			local resizeHandle = Utility.Create("TextButton", {
				Name = "ResizeHandle_" .. tostring(cIdx),
				Parent = colCell,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -4, 0, 0),
				Size = UDim2.new(0, 8, 1, 0),
				Text = "",
				ZIndex = colCell.ZIndex + 3,
			})

			local resizing = false
			local startX = 0
			local origScaleA = 0
			local origScaleB = 0

			resizeHandle.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					resizing = true
					startX = input.Position.X
					origScaleA = colScales[cIdx]
					origScaleB = colScales[cIdx + 1]
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local headerWidth = math.max(headerBar.AbsoluteSize.X, 100)
					local deltaScale = (input.Position.X - startX) / headerWidth
					local minScale = 0.08
					local newScaleA = math.clamp(origScaleA + deltaScale, minScale, (origScaleA + origScaleB) - minScale)
					local newScaleB = (origScaleA + origScaleB) - newScaleA
					colScales[cIdx] = newScaleA
					colScales[cIdx + 1] = newScaleB
					layoutAllColumns()
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					resizing = false
				end
			end)
		end
	end

	-- Scrollable data row container
	local rowsScroll = Utility.Create("ScrollingFrame", {
		Name = "ListViewRowsScroll",
		Parent = wrapper,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 22),
		Size = UDim2.new(1, -16, 1, -22),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ZIndex = wrapper.ZIndex + 1,
	})
	Scrollbar.Attach(rowsScroll)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 2)
	pad.PaddingBottom = UDim.new(0, 2)
	pad.PaddingLeft = UDim.new(0, 2)
	pad.PaddingRight = UDim.new(0, 2)
	pad.Parent = rowsScroll

	local rowList = Instance.new("UIListLayout")
	rowList.SortOrder = Enum.SortOrder.LayoutOrder
	rowList.Padding = UDim.new(0, 1)
	rowList.Parent = rowsScroll

	local selectedIndex = nil

	local controller = {
		Wrapper = wrapper,
		Rows = {},
		ColumnScales = colScales,
	}

	function controller:SetColumnWidths(newScales)
		if type(newScales) == "table" and #newScales == numCols then
			for i = 1, numCols do
				colScales[i] = tonumber(newScales[i]) or colScales[i]
			end
			layoutAllColumns()
		end
	end

	function controller:AddRow(cells, customIcon)
		local idx = #self.Rows + 1
		local rowIcon = customIcon or (type(cells) == "table" and cells.Icon) or rowIcons[idx]
		local hasIcon = (rowIcon ~= nil and rowIcon ~= "")
		table.insert(self.Rows, cells)

		local rBtn = Utility.Create("TextButton", {
			Name = "Row_" .. tostring(idx),
			Parent = rowsScroll,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 21),
			LayoutOrder = idx,
			Text = "",
			ZIndex = rowsScroll.ZIndex + 1,
		})
		Utility.AddCorner(rBtn, 2)
		local rStroke = Utility.AddStroke(rBtn, Theme.Colors.SelectionBorder, 1, 1, Enum.ApplyStrokeMode.Border)
		local rGrad = Instance.new("UIGradient")
		rGrad.Rotation = 90
		rGrad.Color = Theme.Gradients.ExplorerItemSelected
		rGrad.Parent = rBtn

		if hasIcon then
			local ico = Utility.Create("ImageLabel", {
				Name = "RowIcon",
				Parent = rBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				ZIndex = rBtn.ZIndex + 2,
			})
			Assets.BindIcon(ico, rowIcon)
		end

		for cIdx = 1, numCols do
			local xPos = getCumulativePos(cIdx)
			local w = colScales[cIdx]
			local leftOffset = (cIdx == 1 and hasIcon) and 25 or 6

			Utility.Create("TextLabel", {
				Name = "Cell_" .. tostring(cIdx),
				Parent = rBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(xPos, leftOffset, 0, 0),
				Size = UDim2.new(w, -(leftOffset + 4), 1, 0),
				Font = Theme.Fonts.Regular,
				Text = tostring(cells[cIdx] or ""),
				TextColor3 = (cIdx == 1) and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = rBtn.ZIndex + 1,
			})
		end

		rBtn.MouseEnter:Connect(function()
			if selectedIndex ~= idx then
				rGrad.Color = Theme.Gradients.ExplorerItemHover
				rBtn.BackgroundTransparency = 0.1
				rStroke.Transparency = 0.25
			end
		end)
		rBtn.MouseLeave:Connect(function()
			if selectedIndex ~= idx then
				rBtn.BackgroundTransparency = 1
				rStroke.Transparency = 1
			end
		end)
		rBtn.MouseButton1Click:Connect(function()
			selectedIndex = idx
			for i, entry in ipairs(rowButtons) do
				if i == idx then
					entry.Grad.Color = Theme.Gradients.ExplorerItemSelected
					entry.Btn.BackgroundTransparency = 0.05
					entry.Stroke.Transparency = 0.1
				else
					entry.Btn.BackgroundTransparency = 1
					entry.Stroke.Transparency = 1
				end
			end
			onSelect(idx, cells)
		end)

		table.insert(rowButtons, { Btn = rBtn, Stroke = rStroke, Grad = rGrad, HasIcon = hasIcon })
		return rBtn
	end

	function controller:Clear()
		self.Rows = {}
		selectedIndex = nil
		for _, entry in ipairs(rowButtons) do
			if entry.Btn and entry.Btn.Parent then
				entry.Btn:Destroy()
			end
		end
		rowButtons = {}
	end

	for _, r in ipairs(rowsData) do
		controller:AddRow(r)
	end

	return controller
end

return ListView
