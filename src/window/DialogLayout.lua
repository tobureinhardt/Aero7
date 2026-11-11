--!nonstrict
-- Aero7: window/DialogLayout - Windows 7 tabbed property sheet / control dialog layout (SysTabControl32).

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local Scrollbar = require("components/Scrollbar")
local MenuBar = require("components/MenuBar")

local DialogLayout = {}
DialogLayout.__index = DialogLayout

function DialogLayout.new(aeroWindow, options, componentFactory)
	options = options or {}
	local self = setmetatable({}, DialogLayout)

	self.AeroWindow = aeroWindow
	self.ComponentFactory = componentFactory
	self.Root = aeroWindow.ClientOuterFrame
	self.DefaultTabIcon = options.DefaultTabIcon or options.TabIcon or options.Icon or "TabDefault"
	self.Tabs = {}
	self.ActiveTab = nil

	self:_BuildChrome(options)
	return self
end

function DialogLayout:_BuildChrome(options)
	local root = self.Root
	root.BackgroundColor3 = Theme.Colors.DialogFaceBg -- #F0F0F0

	-- 1. Upper TabStrip bar (Height: 24px, 8px padding)
	local tabStrip = Utility.Create("Frame", {
		Name = "Win7SysTabControlStrip",
		Parent = root,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 7),
		Size = UDim2.new(1, -16, 0, 24),
		ZIndex = 8,
	})
	if self.AeroWindow and self.AeroWindow.BindDragHandle then
		self.AeroWindow:BindDragHandle(tabStrip)
	end
	local stripLayout = Instance.new("UIListLayout")
	stripLayout.FillDirection = Enum.FillDirection.Horizontal
	stripLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
	stripLayout.Padding = UDim.new(0, 2)
	stripLayout.Parent = tabStrip
	self.TabStrip = tabStrip

	-- 2. Tab page sheet frame (#FFFFFF, border #898C95)
	local pageBox = Utility.Create("Frame", {
		Name = "TabPageSheetFrame",
		Parent = root,
		BackgroundColor3 = Theme.Colors.DialogTabPageBg, -- #FFFFFF
		Position = UDim2.new(0, 8, 0, 30),
		Size = UDim2.new(1, -16, 1, -72),
		ClipsDescendants = true,
		ZIndex = 6,
	})
	Utility.AddStroke(pageBox, Theme.Colors.DialogTabBorder, 1, 0, Enum.ApplyStrokeMode.Border)
	self.PageBox = pageBox

	-- 3. Bottom command bar (#F0F0F0 with status area and OK / Cancel / Apply buttons)
	local bottomBar = Utility.Create("Frame", {
		Name = "DialogBottomCommandBar",
		Parent = root,
		BackgroundColor3 = Theme.Colors.DialogFaceBg,
		Position = UDim2.new(0, 8, 1, -36),
		Size = UDim2.new(1, -16, 0, 30),
		ZIndex = 7,
	})
	if self.AeroWindow and self.AeroWindow.BindDragHandle then
		self.AeroWindow:BindDragHandle(bottomBar)
	end
	self.BottomBar = bottomBar

	local statusLbl = Utility.Create("TextLabel", {
		Name = "DialogStatusText",
		Parent = bottomBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 2, 0, 0),
		Size = UDim2.new(1, -250, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = options.StatusText or "Windows 7 Aero Property Sheet",
		TextColor3 = Theme.Colors.TextSecondary,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 8,
	})
	self.StatusTextLabel = statusLbl

	local btnHolder = Utility.Create("Frame", {
		Name = "DialogButtonsRight",
		Parent = bottomBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -242, 0, 3),
		Size = UDim2.new(0, 240, 0, 23),
		ZIndex = 8,
	})
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	btnLayout.Padding = UDim.new(0, 6)
	btnLayout.Parent = btnHolder
	self.DialogButtonsHolder = btnHolder

	local function makeDialogBtn(label, order, isDefault, onClick)
		local btn = Utility.Create("TextButton", {
			Name = label .. "Button",
			Parent = btnHolder,
			LayoutOrder = order,
			Size = UDim2.new(0, 75, 0, 23),
			Font = Theme.Fonts.Regular,
			Text = label,
			TextColor3 = Theme.Colors.TextPrimary,
			TextSize = 13,
			ZIndex = 9,
		})
		local state = Utility.BindWin7ButtonStates(btn, {
			CornerRadius = 3,
			IsDefault = isDefault,
		})
		btn.MouseButton1Click:Connect(function()
			if not state.Disabled and onClick then
				onClick()
			end
		end)
		return btn, state
	end

	self.OkButton = makeDialogBtn("OK", 1, true, function()
		if options.OnOK then
			options.OnOK()
		else
			self.StatusTextLabel.Text = "Configuration applied."
		end
	end)

	self.CancelButton = makeDialogBtn("Cancel", 2, false, function()
		if options.OnCancel then
			options.OnCancel()
		else
			self.AeroWindow:ToggleVisibility(false)
		end
	end)

	self.ApplyButton, self.ApplyState = makeDialogBtn("Apply", 3, false, function()
		if options.OnApply then
			options.OnApply()
		end
		self.StatusTextLabel.Text = "Changes applied at " .. os.date("%H:%M:%S")
	end)
end

function DialogLayout:CreateTab(tabOptions)
	if type(tabOptions) == "string" then
		tabOptions = { Title = tabOptions }
	end
	tabOptions = tabOptions or {}

	local tabTitle = tabOptions.Title or ("Tab " .. tostring(#self.Tabs + 1))
	local tabIcon = (tabOptions.Icon ~= nil) and tabOptions.Icon or (self.DefaultTabIcon or "TabDefault")
	local hasIcon = (tabIcon ~= false and tabIcon ~= "")
	local tabWidth = math.max(72, #tabTitle * 7 + (hasIcon and 40 or 22))

	local tabBtn = Utility.Create("TextButton", {
		Name = "SysTab_" .. tabTitle,
		Parent = self.TabStrip,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0, tabWidth, 0, 21),
		LayoutOrder = #self.Tabs + 1,
		Text = "",
		ZIndex = 8,
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
		ZIndex = 9,
	})
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = tabContent

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 5)
	list.Parent = tabContent

	local ico = nil
	if hasIcon then
		ico = Utility.Create("ImageLabel", {
			Name = "TabIcon",
			Parent = tabContent,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 14, 0, 14),
			ZIndex = 10,
		})
		Assets.BindIcon(ico, tabIcon)
	end

	local tabLbl = Utility.Create("TextLabel", {
		Name = "TabTitleText",
		Parent = tabContent,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Theme.Fonts.Regular,
		Text = tabTitle,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		ZIndex = 10,
	})

	-- Active bottom bridge to seamlessly blend active tab into page sheet
	local bottomBridge = Utility.Create("Frame", {
		Name = "ActiveBottomBridge",
		Parent = tabBtn,
		BackgroundColor3 = Theme.Colors.DialogTabPageBg,
		Position = UDim2.new(0, 1, 1, -1),
		Size = UDim2.new(0, tabWidth - 2, 0, 3),
		Visible = false,
		ZIndex = 11,
	})

	-- Scrollable client page with standard Windows 7 scrollbar
	local pageWrap = Utility.Create("Frame", {
		Name = "DialogPageWrap_" .. tabTitle,
		Parent = self.PageBox,
		BackgroundColor3 = Theme.Colors.DialogTabPageBg,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ZIndex = 7,
	})

	local pageScroll = Utility.Create("ScrollingFrame", {
		Name = "DialogPage_" .. tabTitle,
		Parent = pageWrap,
		BackgroundColor3 = Theme.Colors.DialogTabPageBg,
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ZIndex = 7,
	})
	Scrollbar.Attach(pageScroll)

	local pagePad = Instance.new("UIPadding")
	pagePad.PaddingTop = UDim.new(0, 12)
	pagePad.PaddingBottom = UDim.new(0, 12)
	pagePad.PaddingLeft = UDim.new(0, 12)
	pagePad.PaddingRight = UDim.new(0, 12)
	pagePad.Parent = pageScroll

	local pageContainer = Utility.Create("Frame", {
		Name = "PageContentContainer",
		Parent = pageScroll,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 7,
	})
	local pageList = Instance.new("UIListLayout")
	pageList.SortOrder = Enum.SortOrder.LayoutOrder
	pageList.Padding = UDim.new(0, 10)
	pageList.Parent = pageContainer

	local tabObj = {
		Title = tabTitle,
		Icon = tabIcon,
		TabWidth = tabWidth,
		TabIcon = ico,
		TabButton = tabBtn,
		TabStroke = tabStroke,
		TabGradient = tabGrad,
		TabLabel = tabLbl,
		BottomBridge = bottomBridge,
		PageFrame = pageWrap,
		ScrollFrame = pageScroll,
		Container = pageContainer,
		SetIcon = function(selfTab, newIcon)
			selfTab.Icon = newIcon or "TabDefault"
			if selfTab.TabIcon then
				Assets.BindIcon(selfTab.TabIcon, selfTab.Icon)
			end
		end,
	}

	if self.ComponentFactory then
		self.ComponentFactory:AttachToContainer(tabObj, pageContainer)
	end

	tabBtn.MouseEnter:Connect(function()
		if self.ActiveTab ~= tabObj then
			tabGrad.Color = Theme.Gradients.ButtonHover
			tabStroke.Color = Theme.Colors.ControlBorderHover
		end
	end)

	tabBtn.MouseLeave:Connect(function()
		if self.ActiveTab ~= tabObj then
			tabGrad.Color = Theme.Gradients.ButtonNormal
			tabStroke.Color = Theme.Colors.DialogTabBorder
		end
	end)

	tabBtn.MouseButton1Click:Connect(function()
		self:SelectTab(tabObj)
	end)

	table.insert(self.Tabs, tabObj)
	if #self.Tabs == 1 then
		self:SelectTab(tabObj)
	end

	return tabObj
end

function DialogLayout:SelectTab(tabObj)
	if not tabObj then
		return
	end
	self.ActiveTab = tabObj

	for _, t in ipairs(self.Tabs) do
		local isSelected = (t == tabObj)
		t.PageFrame.Visible = isSelected
		t.BottomBridge.Visible = isSelected
		local w = t.TabWidth or 80
		if isSelected then
			t.TabButton.Size = UDim2.new(0, w, 0, 23)
			t.TabGradient.Enabled = false
			t.TabButton.BackgroundColor3 = Theme.Colors.DialogTabPageBg
			t.TabStroke.Color = Theme.Colors.DialogTabBorder
		else
			t.TabButton.Size = UDim2.new(0, w, 0, 21)
			t.TabGradient.Enabled = true
			t.TabGradient.Color = Theme.Gradients.ButtonNormal
			t.TabStroke.Color = Theme.Colors.DialogTabBorder
		end
	end
end

function DialogLayout:SetStatus(text)
	self.StatusTextLabel.Text = tostring(text or "")
end

return DialogLayout
