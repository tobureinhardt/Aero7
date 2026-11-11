--!nonstrict
-- Aero7 Component Showcase
-- Demonstrates Windows 7 Aero Explorer and Dialog layout components.
-- Hotkeys: RightShift (Explorer window), F4 (Dialog window)

local AERO7_URL = "https://raw.githubusercontent.com/tobureinhardt/Aero7/refs/heads/main/dist/Win7UI.lua"

local Win7UI
if type(_G.__WIN7UI_INSTANCE) == "table" then
	Win7UI = _G.__WIN7UI_INSTANCE
elseif type(_G.__WIN7UI_LOADER) == "function" then
	Win7UI = _G.__WIN7UI_LOADER()
else
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(AERO7_URL))()
	end)
	if ok and type(result) == "table" then
		Win7UI = result
	elseif type(loadfile) == "function" then
		local ok2, chunk = pcall(loadfile, "/root/Win7UI/dist/Win7UI.lua")
		if ok2 and chunk then
			Win7UI = chunk()
		end
	end
end

if not Win7UI then
	error("Cant install dist (Win7UI.lua)")
end

-- Configure Windows 7 icon asset bindings
Win7UI:SetIcons({
	WindowDefault = "rbxassetid://112608491209701",
	Explorer      = "rbxassetid://106058928575906",
	ControlPanel  = "rbxassetid://100649829514645",
	Security      = "rbxassetid://103575125619019",
	Shield        = "rbxassetid://97982816838055",
	Network       = "rbxassetid://138866783938913",
	Performance   = "rbxassetid://125913141305144",
	Display       = "rbxassetid://82086079677836",
	ColorMixer    = "rbxassetid://106529931412969",
	SearchFolder  = "rbxassetid://129680943410694",
	CheckBadge    = "rbxassetid://101956620876006",
	CommandArrow  = "rbxassetid://117920961430628",
	Info          = "rbxassetid://92553486978944",
	Warning       = "rbxassetid://117006830626407",
	Error         = "rbxassetid://77725948120292",
	Question      = "rbxassetid://70444122159867",
	Folder        = "rbxassetid://138534442365847",
	Computer      = "rbxassetid://138443400357331",
	Personalize   = "rbxassetid://82086079677836",
	Favorites     = "rbxassetid://77332440442948",
})

-- Main showcase window using the Explorer layout
local ExampleWin = Win7UI:CreateWindow({
	Title = "Example\\All Control Panel Items\\Aero7 Component Showcase",
	Icon = "ControlPanel",
	HierarchyIcon = "ControlPanel",
	DefaultTabIcon = "ControlPanel",
	Layout = "Explorer",
	Size = UDim2.new(0, 720, 0, 480),
	Position = UDim2.new(0.5, -360, 0.5, -240),
	ToggleKey = Enum.KeyCode.RightShift,
	StatusText = "Aero7 DWM Compositor Active",
})

-- Secondary window using the classic tabbed Dialog property sheet layout
local PropSheetWin = Win7UI:CreateWindow({
	Title = "System Properties",
	Icon = "Performance",
	Layout = "Dialog",
	Size = UDim2.new(0, 440, 0, 420),
	Position = UDim2.new(0.5, -220, 0.5, -210),
	ToggleKey = Enum.KeyCode.F4,
	StatusText = "Ready",
	Visible = false,
})
PropSheetWin:ToggleVisibility(false)

-- Command bar actions
ExampleWin:AddCommandBarButton("System Properties...", function()
	PropSheetWin:ToggleVisibility(true)
end, "Performance")

ExampleWin:AddCommandBarButton("Window Color Mixer", function()
	ExampleWin:SelectTab(ExampleWin.Tabs[#ExampleWin.Tabs])
end, "ColorMixer")

ExampleWin:AddCommandBarButton("About Aero7", function()
	ExampleWin:ShowDialog({
		Title = "About Aero7 UI Library",
		Instruction = "Aero7 - Windows 7 Aero Glass UI Library for Roblox",
		Content = "Authentic reproduction of Windows 7 Desktop Window Manager (DWM),\n50/50 split gradients, dual-layer glass bevels, and Common Controls v6.",
		Icon = "Info",
		Buttons = {
			{ Text = "OK", IsDefault = true, Value = true },
		},
	})
end, "Info")

-- Tab 1: System and Security
local SystemTab = ExampleWin:CreateTab({
	Title = "System and Security",
	Category = "Control Panel Home",
	Icon = "Security",
	Subtitle = "Review system status, security parameters, and action centers.",
})

local actionsGroup = SystemTab:AddGroupBox("Common Administrative Tasks")

actionsGroup:AddCommandLink({
	Title = "Review your computer's status",
	Description = "Check security status, firewall configuration, and automated maintenance schedules.",
	Icon = "Shield",
	Callback = function()
		ExampleWin:ShowDialog({
			Title = "Action Center",
			Instruction = "Windows Security Center Status",
			Content = "All security subsystems are operating normally.\nFirewall is active and real-time scanning is enabled.",
			Icon = "Security",
			Buttons = {
				{ Text = "Close", IsDefault = true, Value = true },
			},
		})
	end,
})

actionsGroup:AddCommandLink({
	Title = "Change User Account Control settings",
	Description = "Configure notification levels when applications request elevated privileges.",
	Icon = "Shield",
	Callback = function()
		ExampleWin:ShowDialog({
			Title = "User Account Control",
			Instruction = "Choose when to be notified about changes to your computer",
			Content = "Notify me only when programs try to make changes to my computer (default).",
			Icon = "Shield",
			Buttons = {
				{ Text = "OK", IsDefault = true, Value = true },
				{ Text = "Cancel", Value = false },
			},
		})
	end,
})

local LeftParamsGroup, RightParamsGroup = SystemTab:AddColumns("Targeting Parameters", "Compositor Options")

LeftParamsGroup:AddCheckbox({
	Title = "Enable Assisted Targeting",
	Default = true,
	Flag = "AssistedTargeting",
	Tooltip = "Enables hardware focus alignment and targeting telemetry.",
	Callback = function(val)
		ExampleWin:SetStatus("Assisted Targeting: " .. tostring(val))
	end,
})

LeftParamsGroup:AddCheckbox({
	Title = "Verify Line of Sight (Raycast)",
	Default = true,
	Flag = "WallCheck",
})

LeftParamsGroup:AddSlider({
	Title = "Field of View Radius:",
	Min = 10,
	Max = 360,
	Step = 5,
	Default = 120,
	Suffix = " px",
	Flag = "FOVRadius",
})

LeftParamsGroup:AddSlider({
	Title = "Smoothing Factor:",
	Min = 1,
	Max = 20,
	Step = 0.5,
	Default = 4.5,
	Suffix = "x",
	Flag = "AimSmoothness",
})

LeftParamsGroup:AddSpinner({
	Title = "Prediction Tick Offset:",
	Min = 0,
	Max = 64,
	Step = 1,
	Default = 6,
	Suffix = " ms",
	Flag = "PredictionSpinner",
	Tooltip = "Windows 7 NumericUpDown Spinner control with 50/50 split step buttons.",
})

RightParamsGroup:AddComboBox({
	Title = "Target Hitbox:",
	Options = { "Head", "UpperTorso", "HumanoidRootPart", "Closest Point" },
	Default = "Head",
	Flag = "TargetHitbox",
})

RightParamsGroup:AddComboBox({
	Title = "Priority Filters:",
	Options = { "Ignore Friends", "Ignore Team", "Ignore ForceField", "Visible Only" },
	Multi = true,
	Default = { "Ignore Team", "Ignore ForceField" },
	Flag = "PriorityFilters",
})

RightParamsGroup:AddKeybind({
	Title = "Activation Key:",
	Default = Enum.KeyCode.Q,
	Mode = "Hold",
	Flag = "AimKeybind",
	Callback = function(active, key)
		ExampleWin:SetStatus("Activation Key (" .. tostring(key.Name) .. ") active: " .. tostring(active))
	end,
})

RightParamsGroup:AddButton({
	Description = "Reset targeting profile:",
	ButtonText = "Restore Defaults",
	Shield = true,
	Callback = function()
		ExampleWin:ShowDialog({
			Title = "User Account Control",
			Instruction = "Do you want to restore default targeting parameters?",
			Content = "This action will reset Field of View and Smoothing back to factory settings.",
			Icon = "Shield",
			Buttons = {
				{
					Text = "Yes",
					IsDefault = true,
					Value = true,
					Callback = function()
						Win7UI.Controls.FOVRadius:SetValue(120)
						Win7UI.Controls.AimSmoothness:SetValue(4.5)
					end,
				},
				{ Text = "Cancel", IsDefault = false, Value = false },
			},
		})
	end,
})

-- Tab 2: Network and Internet
local NetworkTab = ExampleWin:CreateTab({
	Title = "Network and Internet",
	Category = "Control Panel Home",
	Icon = "Network",
	Subtitle = "Manage network connections, subsystem routing, and telemetry.",
})

local PhysicsGroup = NetworkTab:AddGroupBox({
	Title = "Locomotion & Telemetry",
	Icon = "Performance",
})

PhysicsGroup:AddCheckbox({
	Title = "Override WalkSpeed & JumpPower",
	Default = false,
	Flag = "OverrideMovement",
})

PhysicsGroup:AddSlider({
	Title = "Character WalkSpeed:",
	Min = 16,
	Max = 250,
	Step = 1,
	Default = 24,
	Suffix = " stud/s",
	Flag = "WalkSpeedVal",
})

PhysicsGroup:AddRadioGroup({
	Title = "Network Synchronization Mode:",
	Options = {
		"Standard Replication (Recommended)",
		"Low-Latency Desync Buffer",
		"Velocity CFrame Interpolation",
	},
	Default = "Standard Replication (Recommended)",
	Flag = "NetSyncMode",
})

PhysicsGroup:AddTextBox({
	Title = "Custom Profile Tag:",
	Default = "Win7_Aero_Profile",
	Placeholder = "Enter profile identifier...",
	Flag = "ProfileTag",
})

local ProgressDemo = PhysicsGroup:AddProgressBar({
	Title = "Memory & Packet Buffer Integrity:",
	Min = 0,
	Max = 100,
	Default = 78,
	State = "Green",
})

PhysicsGroup:AddListView({
	Title = "Active Connections",
	Height = 125,
	Columns = { "Process / Module", "Status", "Memory" },
	RowIcons = { "Display", "Explorer", "ColorMixer", "Settings" },
	Rows = {
		{ "dwm.exe (Aero Glass Compositor)", "Running", "18,420 KB" },
		{ "explorer.exe (Navigation Host)", "Running", "24,110 KB" },
		{ "uxtheme.dll (Split-Gradient Engine)", "Loaded", "4,280 KB" },
		{ "comctl32.dll (Common Controls v6)", "Loaded", "6,912 KB" },
	},
	Callback = function(_, cells)
		ExampleWin:SetStatus("Selected process: " .. tostring(cells[1]) .. " [" .. tostring(cells[2]) .. "]")
	end,
})

local TreeAndListLeft, TreeAndListRight = NetworkTab:AddColumns("Directory TreeView (SysTreeView32)", "Module Listbox & Expander")

TreeAndListLeft:AddTreeView({
	Title = "System Hierarchy:",
	Height = 135,
	Nodes = {
		{
			Text = "Computer (Windows 7 Ultimate)",
			Icon = "Explorer",
			Expanded = true,
			Children = {
				{
					Text = "Local Disk (C:)\\Windows\\System32",
					Icon = "Folder",
					Expanded = true,
					Children = {
						{ Text = "dwm.exe (Aero Glass)", Icon = "Display" },
						{ Text = "uxtheme.dll (50/50 Gradients)", Icon = "ColorMixer" },
					},
				},
				{
					Text = "Security Policies",
					Icon = "Shield",
					Expanded = false,
					Children = {
						{ Text = "AntiTamperGuard.sys", Icon = "Security" },
					},
				},
			},
		},
	},
	Callback = function(nodeName)
		ExampleWin:SetStatus("TreeView selected: " .. tostring(nodeName))
	end,
})

TreeAndListRight:AddSearchBox({
	Placeholder = "Filter listbox modules...",
	Callback = function(q)
		ExampleWin:SetStatus("SearchBox query: " .. tostring(q))
	end,
})

TreeAndListRight:AddListbox({
	Title = "Loaded Subsystems (<select multiple>):",
	Height = 95,
	Multi = true,
	Options = {
		"Direct3D 10.1 Aero Shader",
		"Win32 Common Controls v6",
		"Specular Reflection Parallax",
		"Aero Snap Geometry Engine",
	},
	Default = { "Direct3D 10.1 Aero Shader", "Win32 Common Controls v6" },
	Flag = "LoadedSubsystems",
})

local AdvExpander = TreeAndListRight:AddExpander({
	Title = "Hide/Show Advanced Telemetry Options",
	Default = true,
})
AdvExpander:AddBalloon({
	Title = "Windows 7 Aero Balloon Tip",
	Content = "All controls inside this window follow authentic 7.css and MSDN Windows 7 UX guidelines.",
	Icon = "Info",
	Tail = "TopLeft",
})

-- Tab 3: Appearance and Personalization
local PersonalizeTab = ExampleWin:CreateTab({
	Title = "Personalization",
	Category = "Appearance",
	Icon = "ColorMixer",
	Subtitle = "Change the color of your window borders, Start menu, and glass transparency.",
})

local GlassGroup = PersonalizeTab:AddGroupBox({
	Title = "Window Color and Appearance",
	Icon = "ColorMixer",
})

GlassGroup:AddColorPicker({
	Title = "Select a glass color for your Windows 7 borders:",
	BindToWindowGlass = true,
	ShowMixer = true,
	Flag = "AeroGlassColor",
	Callback = function(_, trans)
		local intensity = math.floor((1 - (trans or 0.26)) * 100 + 0.5)
		ProgressDemo:SetValue(intensity)
	end,
})

local ColorPickerGroup = PersonalizeTab:AddGroupBox({
	Title = "Color Dialog (comdlg32 ChooseColor)",
	Icon = "ColorMixer",
})

ColorPickerGroup:AddColorPicker({
	Title = "Accent / Highlight Color:",
	Default = Color3.fromRGB(0, 120, 215),
	Flag = "HighlightColor",
	Callback = function(col)
		-- Callback invoked on color selection
	end,
})

ColorPickerGroup:AddButton({
	Title = "Open Windows 7 Color Picker...",
	Callback = function()
		ExampleWin:ShowColorDialog({
			Title = "Color",
			InitialColor = Win7UI.Flags.HighlightColor or Color3.fromRGB(0, 120, 215),
			FullOpen = true,
			Callback = function(chosenColor)
				local r = math.floor(chosenColor.R * 255 + 0.5)
				local g = math.floor(chosenColor.G * 255 + 0.5)
				local b = math.floor(chosenColor.B * 255 + 0.5)
				ExampleWin:Notify({
					Title = "Color Selected",
					Content = string.format("Chosen: RGB(%d, %d, %d)", r, g, b),
					Icon = "Info",
				})
			end,
		})
	end,
})

-- Secondary window: Property Sheet Dialog Layout
local GeneralPropTab = PropSheetWin:CreateTab({ Title = "General", Icon = "Computer" })
GeneralPropTab:AddMenuBar({
	{
		Title = "File",
		Items = {
			{ Text = "Apply Configuration", Shortcut = "Ctrl+S", Checked = true },
			{ Separator = true },
			{ Text = "Close Properties", Shortcut = "Alt+F4", Callback = function() PropSheetWin:ToggleVisibility(false) end },
		},
	},
	{
		Title = "View",
		Items = {
			{ Text = "Aero Glass Reflection", Checked = true, Checkable = true },
			{ Text = "Show Status Bar", Checked = true, Checkable = true },
		},
	},
})

local GeneralBox = GeneralPropTab:AddGroupBox({ Title = "Windows Edition", Icon = "Settings" })
GeneralBox:AddPropertyGrid({
	Title = "Windows 7 Ultimate — System Summary",
	Rating = "7.9",
	Properties = {
		{ "Edition", "Windows 7 Ultimate Service Pack 1" },
		{ "Typography", "Segoe UI Custom .TTF Font Family" },
		{ "DWM Compositor", "Aero Glass 104° Specular Active" },
		{ "Common Controls", "comctl32.dll v6.10 (50/50 Gradients)" },
	},
})
GeneralBox:AddDivider()
GeneralBox:AddToolbar({
	Items = {
		{ Text = "Organize", Icon = "Folder", MenuItems = { { Text = "Layout", Checked = true }, { Text = "Folder and search options" } } },
		{ Separator = true },
		{ Text = "System properties", Icon = "Display" },
		{ Text = "Aero Peek", Icon = "ColorMixer", Toggle = true, Default = true },
	},
})
GeneralBox:AddCheckbox({
	Title = "Enable Desktop Composition (Aero Glass)",
	Default = true,
})
GeneralBox:AddCheckbox({
	Title = "Partial Feature Set (Tri-State Indeterminate BS_3STATE)",
	TriState = true,
	Default = "Indeterminate",
	Flag = "TriStateDemo",
})
GeneralBox:AddSplitButton({
	Description = "Power & profile action:",
	ButtonText = "Apply Profile",
	Shield = true,
	MenuItems = {
		{ Text = "Save as Default Profile", Shortcut = "Ctrl+S" },
		{ Text = "Export Registry (.reg)" },
		{ Separator = true },
		{ Text = "Reset All to Factory" },
	},
	Callback = function()
		ExampleWin:SetStatus("SplitButton primary action triggered")
	end,
})
GeneralBox:AddDatePicker({
	Title = "Scheduled Restore Point:",
	Year = 2026,
	Month = 11,
	Day = 5,
	Flag = "RestorePointDate",
})
GeneralBox:AddLink({
	Prefix = "See also:",
	Text = "Read more about Windows Experience Index and Segoe UI typography",
	Icon = "Info",
})
GeneralBox:AddStatusBar({
	Fields = { "Ready", "8 Segoe UI .TTF Faces", "WEI 7.9", "Aero Active" },
	ShowGrip = true,
})

local PerfPropTab = PropSheetWin:CreateTab({ Title = "Visual Effects", Icon = "Display" })
local PerfBox = PerfPropTab:AddGroupBox({ Title = "Performance Options", Icon = "Performance" })
PerfBox:AddRadioGroup({
	Title = "Select the settings you want to use for the appearance and performance of Windows:",
	Options = {
		"Let Windows choose what's best for my computer",
		"Adjust for best appearance",
		"Adjust for best performance",
		"Custom:",
	},
	Default = "Adjust for best appearance",
})
PerfBox:AddSlider({
	Title = "DWM Specular Reflection Intensity:",
	Min = 0,
	Max = 100,
	Default = 85,
	Suffix = "%",
})

PerfPropTab:AddSpinner({
	Title = "Evaluating Windows Aero desktop performance...",
})

local SubTabControl = PerfPropTab:AddTabControl({
	Title = "Advanced Tuning",
	Tabs = { "Visual Settings", "Log Notes" },
})

local subVisualPage = SubTabControl:GetTab("Visual Settings")
subVisualPage:AddCheckbox({
	Title = "Animate controls and elements inside windows",
	Default = true,
})
subVisualPage:AddEditableComboBox({
	Title = "Smoothing Algorithm:",
	Options = { "Bicubic Filtering", "Lanczos 3-Pass", "Bilinear Interpolation" },
	Default = "Bicubic Filtering",
	Flag = "SmoothAlgo",
})

local subLogPage = SubTabControl:GetTab("Log Notes")
subLogPage:AddTextArea({
	Title = "Configuration Notes (Multi-Line Edit):",
	Default = "Windows 7 Aero Glass compositing active.\nDesktop Window Manager hardware acceleration enabled.\n12-dot activity spinner running.",
	Height = 72,
	Flag = "ConfigNotes",
})

return {
	Win7UI = Win7UI,
	Example = ExampleWin,
	MainWindow = ExampleWin,
	PropertySheetWindow = PropSheetWin,
}
