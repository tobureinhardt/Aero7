--!nonstrict
-- Aero7: components/TreeView - Hierarchical TreeView with chevron disclosure indicators and Windows 7 selection boxes (SysTreeView32).

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Scrollbar = require("components/Scrollbar")

local TreeView = {}

function TreeView.new(parentContainer, options)
	options = options or {}
	local title = options.Title
	local nodesData = options.Nodes or options.Items or {}
	local height = tonumber(options.Height) or 150
	local callback = options.Callback or options.OnSelect or function() end

	local outerWrap = Utility.Create("Frame", {
		Name = "TreeView_" .. tostring(title or "Hierarchy"),
		Parent = parentContainer,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})
	local outerList = Instance.new("UIListLayout")
	outerList.SortOrder = Enum.SortOrder.LayoutOrder
	outerList.Padding = UDim.new(0, 4)
	outerList.Parent = outerWrap

	if title and title ~= "" then
		Utility.Create("TextLabel", {
			Name = "TreeViewHeader",
			Parent = outerWrap,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = 1,
			Font = Theme.Fonts.Regular,
			Text = title,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = outerWrap.ZIndex + 1,
		})
	end

	local treeBox = Utility.Create("Frame", {
		Name = "Win7SysTreeViewBox",
		Parent = outerWrap,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, height),
		ClipsDescendants = true,
		LayoutOrder = 2,
		ZIndex = outerWrap.ZIndex + 1,
	})
	Utility.AddStroke(treeBox, Color3.fromRGB(130, 135, 144), 1, 0, Enum.ApplyStrokeMode.Border)

	local scroll = Utility.Create("ScrollingFrame", {
		Name = "TreeViewScroll",
		Parent = treeBox,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = treeBox.ZIndex + 1,
	})
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = scroll

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 1)
	list.Parent = scroll

	-- Attaches standard Windows 7 scrollbar
	Scrollbar.Attach(scroll)

	local selectedNodeBtn = nil
	local selectedNodeStroke = nil
	local orderCounter = 0

	local controller = {
		Wrapper = outerWrap,
		TreeBox = treeBox,
		Selected = nil,
	}

	local function renderNodeList(parentGui, nodeArray, depth)
		for _, node in ipairs(nodeArray) do
			orderCounter = orderCounter + 1
			local nodeText = type(node) == "table" and (node.Text or node.Title or "Node") or tostring(node)
			local children = type(node) == "table" and node.Children or nil
			local hasChildren = children and #children > 0
			local isExpanded = (type(node) == "table" and node.Expanded ~= false)
			local iconName = type(node) == "table" and node.Icon or (hasChildren and "Folder" or "WindowDefault")

			local nodeGroup = Utility.Create("Frame", {
				Name = "TreeNodeGroup_" .. nodeText,
				Parent = parentGui,
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = orderCounter,
				ZIndex = scroll.ZIndex + 1,
			})
			local groupLayout = Instance.new("UIListLayout")
			groupLayout.SortOrder = Enum.SortOrder.LayoutOrder
			groupLayout.Padding = UDim.new(0, 1)
			groupLayout.Parent = nodeGroup

			local rowBtn = Utility.Create("TextButton", {
				Name = "TreeItemRow",
				Parent = nodeGroup,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = 1,
				Text = "",
				ZIndex = nodeGroup.ZIndex + 1,
			})
			Utility.AddCorner(rowBtn, 2)
			local rStroke = Utility.AddStroke(rowBtn, Theme.Colors.SelectionBorder, 1, 1, Enum.ApplyStrokeMode.Border)
			local rGrad = Instance.new("UIGradient")
			rGrad.Rotation = 90
			rGrad.Color = Theme.Gradients.ExplorerItemSelected
			rGrad.Parent = rowBtn

			local indentX = depth * 16 + 4

			local arrowBtn
			local arrowChevron
			if hasChildren then
				arrowBtn = Utility.Create("TextButton", {
					Name = "ExpandTriangle",
					Parent = rowBtn,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, indentX, 0, 0),
					Size = UDim2.new(0, 14, 1, 0),
					Text = "",
					ZIndex = rowBtn.ZIndex + 2,
				})
				arrowChevron = Utility.CreateVectorChevron(
					arrowBtn,
					isExpanded and "Down" or "Right",
					isExpanded and Color3.fromRGB(30, 57, 91) or Color3.fromRGB(100, 108, 118),
					rowBtn.ZIndex + 3
				)
			end

			local ico = Utility.Create("ImageLabel", {
				Name = "NodeIcon",
				Parent = rowBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, indentX + 16, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				ZIndex = rowBtn.ZIndex + 2,
			})
			Assets.BindIcon(ico, iconName)

			Utility.Create("TextLabel", {
				Name = "NodeLabel",
				Parent = rowBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, indentX + 36, 0, 0),
				Size = UDim2.new(1, -(indentX + 40), 1, 0),
				Font = Theme.Fonts.Regular,
				Text = nodeText,
				TextColor3 = Theme.Colors.TextPrimary,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = rowBtn.ZIndex + 2,
			})

			local childrenContainer
			if hasChildren then
				childrenContainer = Utility.Create("Frame", {
					Name = "ChildrenBranch",
					Parent = nodeGroup,
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					Visible = isExpanded,
					LayoutOrder = 2,
					ZIndex = nodeGroup.ZIndex + 1,
				})
				local chLayout = Instance.new("UIListLayout")
				chLayout.SortOrder = Enum.SortOrder.LayoutOrder
				chLayout.Padding = UDim.new(0, 1)
				chLayout.Parent = childrenContainer

				renderNodeList(childrenContainer, children, depth + 1)

				local function toggleBranch()
					isExpanded = not isExpanded
					childrenContainer.Visible = isExpanded
					if arrowChevron then
						arrowChevron:SetDirection(isExpanded and "Down" or "Right")
						arrowChevron:SetColor(isExpanded and Color3.fromRGB(30, 57, 91) or Color3.fromRGB(100, 108, 118))
					end
				end

				arrowBtn.MouseButton1Click:Connect(toggleBranch)
			end

			rowBtn.MouseEnter:Connect(function()
				if selectedNodeBtn ~= rowBtn then
					rGrad.Color = Theme.Gradients.ExplorerItemHover
					rowBtn.BackgroundTransparency = 0.1
					rStroke.Transparency = 0.25
				end
			end)
			rowBtn.MouseLeave:Connect(function()
				if selectedNodeBtn ~= rowBtn then
					rowBtn.BackgroundTransparency = 1
					rStroke.Transparency = 1
				end
			end)
			rowBtn.MouseButton1Click:Connect(function()
				if selectedNodeBtn and selectedNodeStroke then
					selectedNodeBtn.BackgroundTransparency = 1
					selectedNodeStroke.Transparency = 1
				end
				selectedNodeBtn = rowBtn
				selectedNodeStroke = rStroke
				rGrad.Color = Theme.Gradients.ExplorerItemSelected
				rowBtn.BackgroundTransparency = 0.05
				rStroke.Transparency = 0.1
				controller.Selected = nodeText
				callback(nodeText, node)
			end)
		end
	end

	renderNodeList(scroll, nodesData, 0)

	return controller
end

return TreeView
