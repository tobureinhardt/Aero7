--!nonstrict
-- Aero7 library entrypoint
-- Initializes core subsystems, window managers, and Win32 common controls.

local Assets = require("core/Assets")
local Theme = require("core/Theme")
local Utility = require("core/Utility")
local DWM = require("core/DWM")

local AeroWindow = require("window/AeroWindow")
local ExplorerLayout = require("window/ExplorerLayout")
local DialogLayout = require("window/DialogLayout")
local SubDialog = require("window/SubDialog")
local ColorDialog = require("window/ColorDialog")

local GroupBox = require("components/GroupBox")
local Button = require("components/Button")
local CommandLink = require("components/CommandLink")
local Checkbox = require("components/Checkbox")
local RadioGroup = require("components/RadioGroup")
local Slider = require("components/Slider")
local Spinner = require("components/Spinner")
local ComboBox = require("components/ComboBox")
local Listbox = require("components/Listbox")
local TreeView = require("components/TreeView")
local TextBox = require("components/TextBox")
local Keybind = require("components/Keybind")
local ProgressBar = require("components/ProgressBar")
local ColorPicker = require("components/ColorPicker")
local ListView = require("components/ListView")
local Balloon = require("components/Balloon")
local MenuBar = require("components/MenuBar")
local Scrollbar = require("components/Scrollbar")
local Tooltip = require("components/Tooltip")
local StatusBar = require("components/StatusBar")
local Toolbar = require("components/Toolbar")
local SysLink = require("components/SysLink")
local DatePicker = require("components/DatePicker")
local TabControl = require("components/TabControl")
local LoadingSpinner = require("components/LoadingSpinner")

local Win7UI = {
	Version = "1.0.0-Aero7",
	Flags = {},
	Controls = {},
	Windows = DWM.Windows,
	Assets = Assets,
	Theme = Theme,
	Utility = Utility,
	DWM = DWM,
	ColorDialog = ColorDialog,
}

-- Automatically registers Flag for any control with a Flag property
local function bindFlag(options, controlObj)
	if type(options) == "table" and type(options.Flag) == "string" and options.Flag ~= "" then
		local flagName = options.Flag
		Win7UI.Controls[flagName] = controlObj
		if controlObj.Value ~= nil then
			Win7UI.Flags[flagName] = controlObj.Value
		end
		local origCb = options.Callback
		options.Callback = function(val, ...)
			Win7UI.Flags[flagName] = val
			if origCb then
				origCb(val, ...)
			end
		end
	end
end

-- Attaches all component factory builders to Tab or GroupBox containers
local ComponentFactory = {}

function ComponentFactory:AttachToContainer(targetObj, containerFrame, onChildAdded)
	local function notifyAdded(ctrl)
		if onChildAdded then
			onChildAdded(ctrl)
		end
		return ctrl
	end

	-- 1. GroupBox (<fieldset> + <legend>)
	function targetObj:AddGroupBox(opts)
		return GroupBox.new(containerFrame, opts, ComponentFactory, onChildAdded)
	end
	targetObj.AddSection = targetObj.AddGroupBox

	-- 2. Split into dual parallel columns (Left & Right GroupBox or Column)
	function targetObj:AddColumns(leftTitle, rightTitle)
		local row = Utility.Create("Frame", {
			Name = "TwoColumnSplitRow",
			Parent = containerFrame,
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = #containerFrame:GetChildren() + 1,
			ZIndex = containerFrame.ZIndex + 1,
		})
		local leftHost = Utility.Create("Frame", {
			Name = "LeftColumnHost",
			Parent = row,
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0.5, -5, 0, 0),
			ZIndex = row.ZIndex,
		})
		local leftLayout = Instance.new("UIListLayout")
		leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
		leftLayout.Padding = UDim.new(0, 8)
		leftLayout.Parent = leftHost

		local rightHost = Utility.Create("Frame", {
			Name = "RightColumnHost",
			Parent = row,
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 5, 0, 0),
			Size = UDim2.new(0.5, -5, 0, 0),
			ZIndex = row.ZIndex,
		})
		local rightLayout = Instance.new("UIListLayout")
		rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rightLayout.Padding = UDim.new(0, 8)
		rightLayout.Parent = rightHost

		local leftGroup = GroupBox.new(leftHost, { Title = leftTitle or "Left Group" }, ComponentFactory, onChildAdded)
		local rightGroup = GroupBox.new(rightHost, { Title = rightTitle or "Right Group" }, ComponentFactory, onChildAdded)
		return leftGroup, rightGroup
	end

	-- 3. Standard Windows 7 PushButton
	function targetObj:AddButton(opts)
		local ctrl = Button.new(containerFrame, opts)
		return notifyAdded(ctrl)
	end

	-- 3b. Standard Windows 7 SplitButton (BS_SPLITBUTTON - primary button with drop-down arrow)
	function targetObj:AddSplitButton(opts)
		local ctrl = Button.CreateSplitButton(containerFrame, opts)
		return notifyAdded(ctrl)
	end

	-- 4. Standard Windows 7 Control Panel Command Link button
	function targetObj:AddCommandLink(opts)
		local ctrl = CommandLink.new(containerFrame, opts)
		return notifyAdded(ctrl)
	end

	-- 5. Standard Windows 7 14x14px Checkbox (supports AddCheckbox and AddToggle)
	function targetObj:AddCheckbox(opts)
		opts = opts or {}
		bindFlag(opts, {})
		local ctrl = Checkbox.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end
	targetObj.AddToggle = targetObj.AddCheckbox

	-- 6. Standard Windows 7 RadioGroup with Aero teal gemstone center
	function targetObj:AddRadioGroup(opts)
		opts = opts or {}
		bindFlag(opts, {})
		local ctrl = RadioGroup.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end

	-- 7. Standard Windows 7 Slider / Trackbar
	function targetObj:AddSlider(opts)
		opts = opts or {}
		bindFlag(opts, {})
		local ctrl = Slider.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end

	-- 8. ComboBox / Dropdown (Single & Multi-Select)
	function targetObj:AddComboBox(opts)
		opts = opts or {}
		bindFlag(opts, {})
		local ctrl = ComboBox.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end
	targetObj.AddDropdown = targetObj.AddComboBox

	-- 9. TextBox / Edit Control
	function targetObj:AddTextBox(opts)
		opts = opts or {}
		bindFlag(opts, {})
		local ctrl = TextBox.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end
	targetObj.AddInput = targetObj.AddTextBox

	-- 10. Keybind / Shortcut Key Box
	function targetObj:AddKeybind(opts)
		opts = opts or {}
		bindFlag(opts, {})
		local ctrl = Keybind.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end

	-- 11. ProgressBar (green progress bar with animated gloss pulse)
	function targetObj:AddProgressBar(opts)
		local ctrl = ProgressBar.new(containerFrame, opts)
		return notifyAdded(ctrl)
	end

	-- 12. ColorPicker (color swatch preview + Windows 7 ChooseColor dialog)
	function targetObj:AddColorPicker(opts)
		opts = opts or {}
		bindFlag(opts, {})
		local ctrl = ColorPicker.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end

	-- 12b. GlassColorPicker (16 personalization glass presets + HSV/opacity mixer)
	function targetObj:AddGlassColorPicker(opts)
		opts = opts or {}
		opts.BindToWindowGlass = (opts.BindToWindowGlass ~= false)
		return targetObj:AddColorPicker(opts)
	end

	function targetObj:ShowColorDialog(opts)
		return ColorDialog.Show(nil, opts)
	end

	-- 13. ListView (multi-column table with 50/50 split-gradient header)
	function targetObj:AddListView(opts)
		local ctrl = ListView.new(containerFrame, opts)
		return notifyAdded(ctrl)
	end

	-- 14. Spinner / NumericUpDown (numeric input with up/down spin buttons)
	function targetObj:AddSpinner(opts)
		opts = opts or {}
		bindFlag(opts, {})
		local ctrl = Spinner.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end
	targetObj.AddNumber = targetObj.AddSpinner

	-- 15. TreeView (hierarchical tree with chevron indicators)
	function targetObj:AddTreeView(opts)
		local ctrl = TreeView.new(containerFrame, opts)
		return notifyAdded(ctrl)
	end

	-- 16. Listbox (multi-select list with Windows 7 scrollbar)
	function targetObj:AddListbox(opts)
		opts = opts or {}
		bindFlag(opts, {})
		local ctrl = Listbox.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end

	-- 17. Standalone search box
	function targetObj:AddSearchBox(opts)
		local ctrl = Listbox.CreateSearchBox(containerFrame, opts)
		return notifyAdded(ctrl)
	end

	-- 18. Expander / CollapseBox (progressive disclosure container)
	function targetObj:AddExpander(opts)
		return Listbox.CreateExpander(containerFrame, opts, ComponentFactory, onChildAdded)
	end
	targetObj.AddCollapseBox = targetObj.AddExpander

	-- 19. Balloon tooltip speech bubble (TTS_BALLOON)
	function targetObj:AddBalloon(opts)
		local ctrl = Balloon.new(containerFrame, opts)
		return notifyAdded(ctrl)
	end

	-- 20. Horizontal MenuBar (File, Edit, View, Tools, Help)
	function targetObj:AddMenuBar(menusSpec)
		local ctrl = MenuBar.new(containerFrame, menusSpec)
		return notifyAdded(ctrl)
	end

	-- 21. Standard Windows 7 flat toolbar (ToolbarWindow32)
	function targetObj:AddToolbar(opts)
		local ctrl = Toolbar.new(containerFrame, opts)
		return notifyAdded(ctrl)
	end

	-- 22. Standard Windows 7 multi-pane StatusBar (msctls_statusbar32)
	function targetObj:AddStatusBar(opts)
		local ctrl = StatusBar.new(containerFrame, opts)
		return notifyAdded(ctrl)
	end

	-- 23. Windows 7 Control Panel SysLink hyperlink (#0066CC)
	function targetObj:AddLink(opts)
		local ctrl = SysLink.new(containerFrame, opts)
		return notifyAdded(ctrl)
	end
	targetObj.AddSysLink = targetObj.AddLink

	-- 24. PropertyGrid system summary with Windows Experience Index badge (WEI 1.0 - 7.9)
	function targetObj:AddPropertyGrid(opts)
		local ctrl = SysLink.CreatePropertyGrid(containerFrame, opts)
		return notifyAdded(ctrl)
	end
	targetObj.AddDetailsPane = targetObj.AddPropertyGrid

	-- 25. Windows 7 DatePicker & MonthCalendar (SysDateTimePick32 & SysMonthCal32)
	function targetObj:AddDatePicker(opts)
		opts = opts or {}
		bindFlag(opts, {})
		local ctrl = DatePicker.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end
	targetObj.AddCalendar = targetObj.AddDatePicker

	-- 26. In-page TabControl (SysTabControl32 / 7.css menu[role="tablist"])
	function targetObj:AddTabControl(opts)
		local ctrl = TabControl.new(containerFrame, opts, ComponentFactory, onChildAdded)
		return notifyAdded(ctrl)
	end
	targetObj.AddTabs = targetObj.AddTabControl

	-- 27. Multi-line TextArea (WC_EDIT ES_MULTILINE / 7.css textarea)
	function targetObj:AddTextArea(opts)
		opts = opts or {}
		opts.MultiLine = true
		bindFlag(opts, {})
		local ctrl = TextBox.CreateTextArea(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end

	-- 28. Editable drop-down ComboBox (CBS_DROPDOWN)
	function targetObj:AddEditableComboBox(opts)
		opts = opts or {}
		opts.Editable = true
		bindFlag(opts, {})
		local ctrl = ComboBox.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end

	-- 29. Vertical Slider / Trackbar (msctls_trackbar32 TBS_VERT)
	function targetObj:AddVerticalSlider(opts)
		opts = opts or {}
		opts.Vertical = true
		bindFlag(opts, {})
		local ctrl = Slider.new(containerFrame, opts)
		if type(opts.Flag) == "string" and opts.Flag ~= "" then
			Win7UI.Controls[opts.Flag] = ctrl
			Win7UI.Flags[opts.Flag] = ctrl.Value
		end
		return notifyAdded(ctrl)
	end

	-- 30. Windows 7 loading spinner activity indicator (7.css .spinner.animate)
	function targetObj:AddLoadingSpinner(opts)
		local ctrl = LoadingSpinner.new(containerFrame, opts)
		return notifyAdded(ctrl)
	end
	targetObj.AddLoader = targetObj.AddLoadingSpinner

	-- 31. Text labels and horizontal separator rules
	function targetObj:AddLabel(textOrOpts)
		local text = type(textOrOpts) == "table" and (textOrOpts.Text or textOrOpts.Title) or tostring(textOrOpts or "")
		local isHeader = type(textOrOpts) == "table" and textOrOpts.IsInstruction == true
		local lbl = Utility.Create("TextLabel", {
			Name = "Label_" .. text:sub(1, 16),
			Parent = containerFrame,
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = #containerFrame:GetChildren() + 1,
			Font = Theme.Fonts.Regular,
			Text = text,
			TextColor3 = isHeader and Theme.Colors.TextInstruction or Theme.Colors.TextPrimary,
			TextSize = isHeader and 15 or 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = containerFrame.ZIndex + 1,
		})
		return notifyAdded({
			Label = lbl,
			SetText = function(_, t)
				lbl.Text = tostring(t or "")
			end,
		})
	end

	function targetObj:AddDivider()
		local div = Utility.Create("Frame", {
			Name = "Win7HorizontalRule",
			Parent = containerFrame,
			BackgroundColor3 = Theme.Colors.GroupBoxBorder,
			Size = UDim2.new(1, 0, 0, 1),
			LayoutOrder = #containerFrame:GetChildren() + 1,
			ZIndex = containerFrame.ZIndex + 1,
		})
		return notifyAdded(div)
	end
end

Win7UI.ComponentFactory = ComponentFactory

-- Creates a new Windows 7 Aero Glass window (Layout = "Explorer" or "Dialog")
function Win7UI:CreateWindow(options)
	options = options or {}
	local aeroWin = AeroWindow.new(options)
	local layoutMode = tostring(options.Layout or "Explorer")

	local interior
	if layoutMode:lower() == "dialog" or layoutMode:lower() == "tabbed" or layoutMode:lower() == "propertysheet" then
		interior = DialogLayout.new(aeroWin, options, ComponentFactory)
	else
		interior = ExplorerLayout.new(aeroWin, options, ComponentFactory)
	end

	if aeroWin.IsVisible then
		DWM.AnimateOpen(aeroWin.WindowFrame, aeroWin.WindowScale, aeroWin.GlassLayers)
	end

	-- Binds controller methods directly to returned window object
	local windowController = setmetatable({
		AeroWindow = aeroWin,
		Interior = interior,
		ScreenGui = aeroWin.ScreenGui,
		WindowFrame = aeroWin.WindowFrame,
		Tabs = interior.Tabs,
	}, {
		__index = function(_, key)
			if interior[key] ~= nil then
				local val = interior[key]
				if type(val) == "function" then
					return function(_, ...)
						return val(interior, ...)
					end
				end
				return val
			end
			if aeroWin[key] ~= nil then
				local val = aeroWin[key]
				if type(val) == "function" then
					return function(_, ...)
						return val(aeroWin, ...)
					end
				end
				return val
			end
			return nil
		end,
	})

	function windowController:CreateTab(tabOpts)
		return interior:CreateTab(tabOpts)
	end
	windowController.AddTab = windowController.CreateTab

	function windowController:ShowDialog(dialogOpts)
		return SubDialog.Show(aeroWin, dialogOpts)
	end
	windowController.Prompt = windowController.ShowDialog

	function windowController:ShowColorDialog(colorOpts)
		return ColorDialog.Show(aeroWin, colorOpts)
	end
	windowController.ChooseColor = windowController.ShowColorDialog

	function windowController:Notify(balloonOpts)
		return Balloon.Notify(aeroWin, balloonOpts)
	end
	windowController.ShowBalloon = windowController.Notify

	function windowController:AttachContextMenu(targetGui, menuItems)
		return MenuBar.AttachContextMenu(targetGui or aeroWin.ClientOuterFrame, menuItems, aeroWin.ScreenGui)
	end

	return windowController
end

-- Opens Windows 7 ChooseColor modal dialog
function Win7UI:ShowColorDialog(colorOpts)
	if type(self) == "table" and self ~= Win7UI and colorOpts == nil then
		colorOpts = self
	end
	return ColorDialog.Show(nil, colorOpts)
end
Win7UI.ChooseColor = Win7UI.ShowColorDialog

-- Registers custom Frutiger Aero rbxassetid icon pack table
function Win7UI:SetIcons(iconTable)
	Assets.SetIcons(iconTable)
end

-- Sets global Aero Glass tint (preset name e.g. "Sky", "Ruby", "Leaf" or Color3)
function Win7UI:SetGlassColor(colorOrPresetName, transparency, glowColor)
	DWM:SetGlassColor(colorOrPresetName, transparency, glowColor)
end

-- Loads and activates Segoe UI custom TTF font on supported executors
function Win7UI:LoadSegoeFont(options)
	return Theme.LoadSegoeFont(options)
end

-- Sets custom FontFamily asset ID directly
function Win7UI:SetFontFamily(familyAssetId)
	return Theme.SetFontFamily(familyAssetId)
end

-- Boots Segoe UI TTF font loader on library initialization
task.spawn(function()
	pcall(function()
		Theme.LoadSegoeFont()
	end)
end)

setmetatable(Win7UI, {
	__call = function(self, ...)
		return self
	end,
})

return Win7UI
