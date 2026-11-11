--!nonstrict
-- Aero7: components/TabControl - In-page tab control (SysTabControl32 / 7.css menu[role="tablist"] & [role="tabpanel"]).

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")

local TabControl = {}

function TabControl.new(parentContainer, options, componentFactory, onChildAdded)
	options = options or {}
	local title = options.Title or "TabControl"
	local height = tonumber(options.Height) or 180
	local autoHeight = options.AutomaticSize == true or options.Height == "Auto"
	local onTabChanged = options.Callback or options.OnTabChanged or function() end

	local wrapper = Utility.Create("Frame", {
		Name = "Win7TabControl_" .. title,
		Parent = parentContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		AutomaticSize = autoHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		LayoutOrder = options.LayoutOrder or (#parentContainer:GetChildren() + 1),
		ZIndex = parentContainer.ZIndex + 1,
	})

	-- Tab buttons strip (menu[role="tablist"])
	local tabListRow = Utility.Create("Frame", {
		Name = "TabListRow",
		Parent = wrapper,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 24),
		ZIndex = wrapper.ZIndex + 2,
	})
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = tabListRow

	-- Tab page panel frame (role="tabpanel")
	local tabPanel = Utility.Create("Frame", {
		Name = "TabPanel",
		Parent = wrapper,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.new(0, 0, 0, 23),
		Size = autoHeight and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 1, -23),
		AutomaticSize = autoHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		ClipsDescendants = not autoHeight,
		ZIndex = wrapper.ZIndex + 1,
	})
	Utility.AddCorner(tabPanel, 2)
	Utility.AddStroke(tabPanel, Theme.Colors.DialogTabBorder, 1, 0, Enum.ApplyStrokeMode.Border)

	local tabs = {}
	local activeIndex = 0

	local controller = {
		Wrapper = wrapper,
		TabListRow = tabListRow,
		TabPanel = tabPanel,
		Tabs = tabs,
	}

	local function selectTab(idx)
		if idx == activeIndex or not tabs[idx] then
			return
		end
		activeIndex = idx

		for i, t in ipairs(tabs) do
			local isSelected = (i == idx)
			t.Page.Visible = isSelected

			if isSelected then
				t.Button.Size = UDim2.new(0, t.TabWidth, 0, 24)
				t.Button.Position = UDim2.new(0, 0, 0, -1)
				t.Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				t.Gradient.Enabled = false
				t.Stroke.Color = Theme.Colors.DialogTabBorder
				t.BottomBridge.Visible = true
				t.Label.TextColor3 = Color3.fromRGB(0, 0, 0)
			else
				t.Button.Size = UDim2.new(0, t.TabWidth, 0, 22)
				t.Button.Position = UDim2.new(0, 0, 0, 1)
				t.Button.BackgroundColor3 = Color3.fromRGB(244, 244, 244)
				t.Gradient.Enabled = true
				t.Stroke.Color = Theme.Colors.DialogTabBorder
				t.BottomBridge.Visible = false
				t.Label.TextColor3 = Theme.Colors.TextPrimary
			end
		end

		local sel = tabs[idx]
		if sel then
			onTabChanged(sel.Title, idx)
		end
	end

	function controller:AddTab(tabDef)
		if type(tabDef) == "string" then
			tabDef = { Title = tabDef }
		end
		tabDef = tabDef or {}
		local tTitle = tostring(tabDef.Title or ("Tab " .. tostring(#tabs + 1)))
		local tIcon = tabDef.Icon
		local hasIcon = (tIcon ~= nil and tIcon ~= false and tIcon ~= "")
		local tabWidth = math.max(68, #tTitle * 7 + (hasIcon and 36 or 18))

		local tabIndex = #tabs + 1

		local tabBtn = Utility.Create("TextButton", {
			Name = "TabBtn_" .. tTitle,
			Parent = tabListRow,
			BackgroundColor3 = Color3.fromRGB(244, 244, 244),
			Size = UDim2.new(0, tabWidth, 0, 22),
			LayoutOrder = tabIndex,
			Text = "",
			ZIndex = tabListRow.ZIndex + 2,
		})
		Utility.AddCorner(tabBtn, 2)
		local tabStroke = Utility.AddStroke(tabBtn, Theme.Colors.DialogTabBorder, 1, 0, Enum.ApplyStrokeMode.Border)
		local tabGrad = Instance.new("UIGradient")
		tabGrad.Rotation = 90
		tabGrad.Color = Theme.Gradients.ButtonNormal
		tabGrad.Parent = tabBtn

		local tabContent = Utility.Create("Frame", {
			Name = "TabLabelWrap",
			Parent = tabBtn,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = tabBtn.ZIndex + 1,
		})
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Padding = UDim.new(0, 4)
		list.Parent = tabContent

		local ico = nil
		if hasIcon then
			ico = Utility.Create("ImageLabel", {
				Name = "TabIcon",
				Parent = tabContent,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 14, 0, 14),
				ZIndex = tabContent.ZIndex + 1,
			})
			Assets.BindIcon(ico, tIcon)
		end

		local tabLbl = Utility.Create("TextLabel", {
			Name = "TabTitleText",
			Parent = tabContent,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = Theme.Fonts.Regular,
			Text = tTitle,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 12,
			ZIndex = tabContent.ZIndex + 1,
		})

		-- Bottom bridge masking active tab bottom edge
		local bottomBridge = Utility.Create("Frame", {
			Name = "ActiveBottomBridge",
			Parent = tabBtn,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.new(0, 1, 1, -1),
			Size = UDim2.new(0, tabWidth - 2, 0, 3),
			Visible = false,
			ZIndex = tabBtn.ZIndex + 3,
		})

		-- Page content host frame
		local pageFrame = Utility.Create("Frame", {
			Name = "TabPage_" .. tTitle,
			Parent = tabPanel,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = autoHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
			Visible = false,
			ZIndex = tabPanel.ZIndex + 1,
		})
		local pagePad = Instance.new("UIPadding")
		pagePad.PaddingTop = UDim.new(0, 10)
		pagePad.PaddingBottom = UDim.new(0, 10)
		pagePad.PaddingLeft = UDim.new(0, 10)
		pagePad.PaddingRight = UDim.new(0, 10)
		pagePad.Parent = pageFrame

		local pageContainer = Utility.Create("Frame", {
			Name = "PageContainer",
			Parent = pageFrame,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = autoHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
			ZIndex = pageFrame.ZIndex + 1,
		})
		local pageList = Instance.new("UIListLayout")
		pageList.SortOrder = Enum.SortOrder.LayoutOrder
		pageList.Padding = UDim.new(0, 8)
		pageList.Parent = pageContainer

		local tabObj = {
			Index = tabIndex,
			Title = tTitle,
			TabWidth = tabWidth,
			Button = tabBtn,
			Stroke = tabStroke,
			Gradient = tabGrad,
			Label = tabLbl,
			Icon = ico,
			BottomBridge = bottomBridge,
			Page = pageFrame,
			Container = pageContainer,
		}

		if componentFactory then
			if type(componentFactory.AttachToContainer) == "function" then
				componentFactory:AttachToContainer(tabObj, pageContainer, onChildAdded)
			elseif type(componentFactory) == "function" then
				componentFactory(tabObj, pageContainer, onChildAdded)
			end
		end

		tabBtn.MouseEnter:Connect(function()
			if activeIndex ~= tabIndex then
				tabStroke.Color = Color3.fromRGB(125, 162, 206)
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if activeIndex ~= tabIndex then
				tabStroke.Color = Theme.Colors.DialogTabBorder
			end
		end)
		tabBtn.MouseButton1Click:Connect(function()
			selectTab(tabIndex)
		end)

		table.insert(tabs, tabObj)

		if #tabs == 1 then
			selectTab(1)
		end

		return tabObj
	end

	function controller:SelectTab(query)
		if type(query) == "number" then
			selectTab(query)
		elseif type(query) == "string" then
			for i, t in ipairs(tabs) do
				if t.Title:lower() == query:lower() then
					selectTab(i)
					break
				end
			end
		end
	end

	function controller:GetTab(query)
		if type(query) == "number" then
			return tabs[query]
		elseif type(query) == "string" then
			for _, t in ipairs(tabs) do
				if t.Title:lower() == query:lower() then
					return t
				end
			end
		end
		return nil
	end

	if options.Tabs and type(options.Tabs) == "table" then
		for _, tDef in ipairs(options.Tabs) do
			controller:AddTab(tDef)
		end
	end

	return controller
end

return TabControl
