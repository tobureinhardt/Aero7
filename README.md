# Aero7

Aero7 is a comprehensive, pixel-faithful recreation of the Windows 7 Aero Glass visual design system and Windows Common Controls for Roblox.

## Installation

### Remote Execution

Load the pre-bundled release directly into your Roblox environment:

```lua
local Aero7 = loadstring(game:HttpGet("https://raw.githubusercontent.com/tobureinhardt/Aero7/main/dist/Win7UI.lua"))()
```

### Local Build

To build the single-file distribution from source:

```bash
python3 tools/build.py
```

Darklua transforms and bundles all modular sources from `src/` into `dist/Win7UI.lua`.

## Quick Start

```lua
local Aero7 = loadstring(game:HttpGet("https://raw.githubusercontent.com/tobureinhardt/Time-machine/main/dist/Win7UI.lua"))()

-- Create an Explorer-style window
local Window = Aero7:CreateWindow({
    Title = "Example\\All Control Panel Items\\Aero7",
    Icon = "ControlPanel",
    Layout = "Explorer",
    Size = UDim2.fromOffset(720, 480),
    ToggleKey = Enum.KeyCode.RightShift,
    StatusText = "Aero7 DWM Compositor Active",
})

-- Create a tab inside the window
local Tab = Window:CreateTab({
    Title = "General Settings",
    Category = "Control Panel Home",
    Icon = "Security",
    Subtitle = "Configure system and visual options.",
})

-- Add controls
local Group = Tab:AddGroupBox("Visual Options")

Group:AddCheckbox({
    Title = "Enable Glass Blur-Behind",
    Default = true,
    Callback = function(enabled)
        print("Glass blur state:", enabled)
    end,
})

Group:AddSlider({
    Title = "Glass Opacity",
    Min = 0,
    Max = 100,
    Default = 75,
    Suffix = " %",
    Callback = function(value)
        print("Opacity set to:", value)
    end,
})

Group:AddButton({
    Title = "Show System Assessment",
    Callback = function()
        Window:ShowDialog({
            Title = "System Assessment",
            Instruction = "Windows Experience Index",
            Content = "Your system rating has been determined based on the hardware configuration.",
            Icon = "Info",
            Buttons = {
                { Text = "OK", IsDefault = true, Value = true },
            },
        })
    end,
})
```

## Repository Structure

```
Aero7/
├── .darklua.json          Darklua transformation and bundling rules
├── dist/
│   ├── Win7UI.lua         Single-file bundled library processed with Darklua
│   └── Example.lua        Component showcase script
├── docs/
│   └── API.md             Comprehensive API Reference documentation
├── fonts/                 Segoe UI TTF font assets and configuration
├── src/
│   ├── init.lua           Library entrypoint
│   ├── core/              Assets, DWM compositor, theme definitions, utilities
│   ├── window/            Window architectures (AeroWindow, ExplorerLayout, DialogLayout, SubDialog)
│   └── components/        25+ modular Win32 common controls
├── tests/
│   └── verify_win7ui.lua  Headless verification test suite
└── tools/
    └── build.py           Darklua-driven build pipeline
```

## Verification

Run the automated headless test suite via LuaJIT:

```bash
luajit tests/verify_win7ui.lua
```

All window layers, gradient stops, DWM feather shadows, component state controllers, search filters, and mobile viewports are validated without requiring a GUI display.

## License

This project is licensed under the MIT License.
