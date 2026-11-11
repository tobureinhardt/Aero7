# Aero7 API Reference

This document provides technical documentation for the Aero7 library, including window management, layout engines, component constructors, and theming subsystems.

## Table of Contents

- [Core Library](#core-library)
- [Window Management](#window-management)
  - [Window Options](#window-options)
  - [Window Methods](#window-methods)
- [Tab Management](#tab-management)
- [Component Reference](#component-reference)
  - [Button](#button)
  - [SplitButton](#splitbutton)
  - [CommandLink](#commandlink)
  - [Checkbox](#checkbox)
  - [RadioGroup](#radiogroup)
  - [Slider & Vertical Slider](#slider--vertical-slider)
  - [Spinner (NumericUpDown)](#spinner-numericupdown)
  - [ComboBox & Editable ComboBox](#combobox--editable-combobox)
  - [TextBox & TextArea](#textbox--textarea)
  - [Keybind](#keybind)
  - [ProgressBar](#progressbar)
  - [ColorPicker](#colorpicker)
  - [ListView](#listview)
  - [TreeView](#treeview)
  - [TabControl](#tabcontrol)
  - [MenuBar](#menubar)
  - [DatePicker](#datepicker)
  - [TaskDialog & MessageBox](#taskdialog--messagebox)
- [Theming and Configuration](#theming-and-configuration)
  - [Glass Presets](#glass-presets)
  - [Icon Binding](#icon-binding)
  - [Font Subsystem](#font-subsystem)
- [Global Registries](#global-registries)

---

## Core Library

The library table is returned upon loading the bundle.

```lua
local Aero7 = loadstring(game:HttpGet("https://raw.githubusercontent.com/tobureinhardt/Time-machine/main/dist/Win7UI.lua"))()
```

### Static Properties

| Property | Type | Description |
| :--- | :--- | :--- |
| `Version` | string | Library version string (e.g., `"1.0.0-Aero7"`). |
| `Theme` | table | Color definitions, 50/50 split gradients, and font faces. |
| `Assets` | table | Icon catalogs, asset IDs, and procedural fallbacks. |
| `Flags` | table | Key-value store of registered control values. |
| `Controls` | table | Registry of active control controller objects. |

---

## Window Management

Windows are created using `Aero7:CreateWindow(options)`.

```lua
local Window = Aero7:CreateWindow({
    Title = "Example\\All Control Panel Items\\Aero7",
    Icon = "ControlPanel",
    Layout = "Explorer",
    Size = UDim2.fromOffset(720, 480),
    Position = UDim2.new(0.5, -360, 0.5, -240),
    ToggleKey = Enum.KeyCode.RightShift,
    StatusText = "Aero7 DWM Compositor Active",
})
```

### Window Options

| Field | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `Title` | string | `"Window"` | Window title. In `"Explorer"` layout, backslash (`\`) characters delimit breadcrumb segments. |
| `Icon` | string | `"WindowDefault"` | Named semantic icon key or `rbxassetid://` URI displayed in the caption bar. |
| `Layout` | string | `"Explorer"` | Window visual layout: `"Explorer"` (Control Panel / Explorer) or `"Dialog"` (Property Sheet). |
| `Size` | UDim2 | `UDim2.fromOffset(680, 440)` | Initial window pixel dimensions. |
| `Position` | UDim2 | Centered | Initial screen position. |
| `ToggleKey` | Enum.KeyCode | `nil` | Optional hotkey to toggle window visibility. |
| `StatusText` | string | `""` | Initial status bar text displayed at the bottom of the window. |
| `HierarchyIcon` | string | `"Explorer"` | Icon displayed at the root of the Explorer address bar. |
| `DefaultTabIcon`| string | `"Folder"` | Fallback icon applied to tabs that do not specify an explicit icon. |

### Window Methods

#### `Window:CreateTab(options)`
Registers a new navigation page or tab strip page within the window. Returns a `Tab` controller object.

#### `Window:SelectTab(tabObject)`
Switches the active display to the specified tab, updating history stacks and navigation controls.

#### `Window:AddCommandBarButton(text, callback, icon)`
*(Explorer layout only)* Adds an action button to the command bar beneath the address bar.

#### `Window:SetStatus(text)`
Updates the text content displayed within the window status bar.

#### `Window:ToggleVisibility(visible)`
Sets window visibility. If `visible` is omitted, inverts the current visibility state.

#### `Window:ShowDialog(options)`
Displays an Aero TaskDialog overlay within the window.

| Option | Type | Description |
| :--- | :--- | :--- |
| `Title` | string | Dialog window title. |
| `Instruction` | string | Main high-contrast header text. |
| `Content` | string | Secondary descriptive body text. |
| `Icon` | string | Named icon key (e.g., `"Info"`, `"Warning"`, `"Error"`, `"Shield"`). |
| `Buttons` | table | Array of button definitions: `{ Text = string, IsDefault = boolean, Value = any }`. |

#### `Window:ShowColorDialog(options, callback)`
Displays the Win32 `comdlg32 ChooseColor` palette and HSL mixer dialog.

#### `Window:Destroy()`
Unbinds all event connections and destroys window ScreenGui instances.

---

## Tab Management

Tabs manage child component layout, scrolling canvases, and sidebar item bindings.

```lua
local Tab = Window:CreateTab({
    Title = "System and Security",
    Category = "Control Panel Home",
    Icon = "Security",
    Subtitle = "System status and security parameters.",
})
```

### Tab Methods

#### `Tab:AddGroupBox(titleOrOptions)`
Constructs a native Windows 7 etched border GroupBox container. Returns a `GroupBox` object.

#### `Tab:AddColumns(leftTitle, rightTitle)`
Creates a two-column responsive grid container. Returns `leftGroup, rightGroup`.

All component constructor methods documented below can be called directly on both `Tab` and `GroupBox` instances.

---

## Component Reference

### Button

Native Windows 7 push button with 50/50 horizontal split gradient.

```lua
Group:AddButton({
    Title = "Check for Updates",
    Description = "Checks the remote repository for library updates.",
    ButtonText = "Check Now",
    Disabled = false,
    Shield = false,
    Callback = function()
        print("Button clicked")
    end,
})
```

### SplitButton

Push button with an integrated dropdown chevron menu (BS_SPLITBUTTON).

```lua
Group:AddSplitButton({
    Title = "Deploy Configuration",
    ButtonText = "Deploy",
    Shield = true,
    MenuItems = {
        { Text = "Deploy to Production", Shortcut = "Ctrl+P" },
        { Text = "Deploy to Staging" },
        { Separator = true },
        { Text = "Validate Only" },
    },
    Callback = function()
        print("Primary action executed")
    end,
})
```

### CommandLink

Windows Vista / 7 elevated action link with arrow glyph, primary headline, and descriptive subtitle.

```lua
Group:AddCommandLink({
    Title = "Change User Account Control settings",
    Description = "Configure notification levels when applications request elevated permissions.",
    Icon = "Shield",
    Callback = function()
        -- Handler
    end,
})
```

### Checkbox

Two-state or tri-state (BS_3STATE) checkbox with etched checkmark glyph.

```lua
Group:AddCheckbox({
    Title = "Enable Desktop Composition",
    Default = true,
    TriState = false,
    Flag = "AeroComposition",
    Callback = function(checked)
        print("Checkbox state:", checked)
    end,
})
```

*Tri-state mode:* When `TriState = true`, valid states are `true`, `false`, and `"Indeterminate"`.

### RadioGroup

Mutual-exclusion option group with circular radio glyphs.

```lua
Group:AddRadioGroup({
    Title = "Performance Profile:",
    Options = { "Balanced", "High Performance", "Power Saver" },
    Default = "Balanced",
    Flag = "PowerProfile",
    Callback = function(selected)
        print("Selected profile:", selected)
    end,
})
```

### Slider & Vertical Slider

Trackbar control (msctls_trackbar32) with drag handle and value indicator.

```lua
-- Horizontal Slider
Group:AddSlider({
    Title = "Field of View:",
    Min = 60,
    Max = 120,
    Step = 1,
    Default = 90,
    Suffix = " deg",
    Flag = "CameraFOV",
    Callback = function(value)
        print("FOV:", value)
    end,
})

-- Vertical Slider
Tab:AddVerticalSlider({
    Title = "Master Volume",
    Min = 0,
    Max = 100,
    Default = 75,
    Suffix = "%",
    Flag = "VolumeSlider",
    Callback = function(value)
        print("Volume:", value)
    end,
})
```

### Spinner (NumericUpDown)

Numeric edit field paired with split up/down increment buttons.

```lua
Group:AddSpinner({
    Title = "Sample Rate Limit:",
    Min = 0,
    Max = 120,
    Step = 5,
    Default = 60,
    Suffix = " fps",
    Flag = "SampleRate",
    Callback = function(val)
        print("Sample rate:", val)
    end,
})
```

### ComboBox & Editable ComboBox

Single-select, multi-select, and editable (CBS_DROPDOWN) selection dropdowns.

```lua
-- Standard Dropdown
Group:AddComboBox({
    Title = "Anti-Aliasing Quality:",
    Options = { "Disabled", "FXAA Low", "MSAA 4x", "TAA High" },
    Default = "MSAA 4x",
    Multi = false,
    Flag = "AAQuality",
    Callback = function(selected)
        print("Selected:", selected)
    end,
})

-- Editable Dropdown (Text input + Dropdown button)
Group:AddEditableComboBox({
    Title = "Filter Algorithm:",
    Options = { "Bicubic", "Bilinear", "Nearest Neighbor" },
    Default = "Bicubic",
    Flag = "FilterAlgo",
    Callback = function(val)
        print("Filter set to:", val)
    end,
})
```

### TextBox & TextArea

Single-line (WC_EDIT) and multi-line edit fields.

```lua
-- Single-Line
Group:AddTextBox({
    Title = "Identifier:",
    Default = "HostSession_01",
    Placeholder = "Enter session ID...",
    Flag = "SessionId",
    Callback = function(text)
        print("Text changed:", text)
    end,
})

-- Multi-Line Edit
Group:AddTextArea({
    Title = "Configuration Notes:",
    Default = "Line 1 notes\nLine 2 notes",
    Height = 80,
    Flag = "NotesField",
    Callback = function(text)
        print("Notes updated:", text)
    end,
})
```

### Keybind

Interactive hotkey capture control supporting both "Toggle" and "Hold" modes.

```lua
Group:AddKeybind({
    Title = "Overlay Toggle Key:",
    Default = Enum.KeyCode.RightShift,
    Mode = "Toggle",
    Flag = "OverlayHotkey",
    Callback = function(key)
        print("Key updated:", key.Name)
    end,
})
```

### ProgressBar

Native Windows 7 progress bar supporting multiple state colors and marquee animation.

```lua
local Bar = Group:AddProgressBar({
    Title = "Operation Progress:",
    Min = 0,
    Max = 100,
    Default = 45,
    State = "Green", -- "Green", "Blue", "Amber", "Red", "Marquee"
})

Bar:SetValue(80)
Bar:SetState("Blue")
```

### ColorPicker

Glass tint swatch palette or inline HSL color selector.

```lua
Group:AddColorPicker({
    Title = "Accent Tint Color:",
    Default = Color3.fromRGB(0, 120, 215),
    Flag = "AccentColor",
    Callback = function(color)
        print("Selected color:", color)
    end,
})
```

### ListView

SysListView32 report view with resizable header columns and alternating row shading.

```lua
local List = Group:AddListView({
    Title = "System Services",
    Height = 140,
    Columns = {
        { Title = "Process / Module", Width = 160 },
        { Title = "Status", Width = 90 },
        { Title = "Memory", Width = 90 },
    },
    Rows = {
        { "dwm.exe", "Running", "18,420 KB" },
        { "explorer.exe", "Running", "24,110 KB" },
    },
    Callback = function(rowIndex, rowValues)
        print("Selected row:", rowValues[1])
    end,
})
```

### TreeView

SysTreeView32 hierarchical node browser with expand/collapse chevrons.

```lua
Group:AddTreeView({
    Title = "System Namespace:",
    Height = 140,
    Nodes = {
        {
            Text = "Root",
            Icon = "Folder",
            Expanded = true,
            Children = {
                { Text = "Configuration", Icon = "Settings" },
                { Text = "Security", Icon = "Shield" },
            },
        },
    },
    Callback = function(nodeName)
        print("Selected node:", nodeName)
    end,
})
```

### TabControl

In-page tabbed container (SysTabControl32) for nesting secondary tab strips inside a page.

```lua
local SubTabs = Tab:AddTabControl({
    Title = "Subsystem Options",
    Tabs = { "General", "Advanced" },
})

local generalPage = SubTabs:GetTab("General")
generalPage:AddCheckbox({ Title = "Option A", Default = true })
```

### MenuBar

Standard top-level application menu bar with dropdown menus.

```lua
Tab:AddMenuBar({
    Menus = {
        {
            Title = "File",
            Items = {
                { Text = "Save", Shortcut = "Ctrl+S", Callback = function() end },
                { Separator = true },
                { Text = "Exit", Callback = function() end },
            },
        },
        {
            Title = "View",
            Items = {
                { Text = "Status Bar", Checked = true, Checkable = true },
            },
        },
    },
})
```

### DatePicker

Calendar date selection control (SysMonthCal32).

```lua
Group:AddDatePicker({
    Title = "Snapshot Date:",
    Year = 2026,
    Month = 11,
    Day = 5,
    Flag = "SnapshotDate",
    Callback = function(formattedDate)
        print("Date selected:", formattedDate)
    end,
})
```

### TaskDialog & MessageBox

Window-modal dialogs following the Windows Vista and Windows 7 TaskDialog specification.

```lua
-- Informational dialog
Window:ShowDialog({
    Title = "Security Notice",
    Instruction = "Security Center Configuration",
    Content = "All telemetry filters are active.",
    Icon = "Security",
    Buttons = {
        { Text = "OK", IsDefault = true, Value = true },
    },
})
```

---

## Theming and Configuration

### Glass Presets

Aero7 includes the 16 original Windows 7 Personalization glass colors.

```lua
Aero7:SetGlassColor("Twilight")
```

Available presets:
`"Default"`, `"Frost"`, `"Twilight"`, `"Sea"`, `"Leaf"`, `"Sky"`, `"Blush"`, `"Sun"`, `"Pumpkin"`, `"Ruby"`, `"Fuchsia"`, `"Lavender"`, `"Taupe"`, `"Slate"`, `"Carbon"`, `"Emerald"`.

Custom colors can also be applied directly:

```lua
Aero7:SetGlassColor(Color3.fromRGB(45, 95, 145), 0.28)
```

### Icon Binding

Icons are resolved through `Aero7.Assets`. Custom asset mappings can be injected at runtime:

```lua
Aero7:SetIcons({
    CustomAction = "rbxassetid://1234567890",
})
```

### Font Subsystem

Aero7 automatically provisions the Segoe UI font family using executor filesystem capabilities (`writefile` + `getcustomasset` + `Font.new`).

```lua
-- Apply a custom font family asset ID
Aero7:SetFontFamily("rbxassetid://9876543210")
```

---

## Global Registries

### `Aero7.Flags`
Key-value table storing current states of all controls that specify a `Flag` property:

```lua
local isTargeting = Aero7.Flags.AssistedTargeting
```

### `Aero7.Controls`
Registry containing controller instances for all flagged controls, exposing programmatical update methods:

```lua
Aero7.Controls.AssistedTargeting:SetValue(false)
Aero7.Controls.FOVRadius:SetValue(90)
```
