--!nonstrict
-- Aero7 test suite: verify_win7ui.lua
-- Verification suite for Aero7 bundle, layouts, components, DWM chrome, and responsive behavior.

-- Builds complete mock Roblox environment to execute UI code under LuaJIT / Lua 5.1
math.clamp = math.clamp or function(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

table.find = table.find or function(t, val)
	for i, v in ipairs(t) do
		if v == val then return i end
	end
	return nil
end

task = {
	spawn = function(fn, ...)
		-- Prevents infinite loops in synchronous test environment
		local info = debug.getinfo(fn, "S")
		if info and info.linedefined and info.ShortSrc and info.ShortSrc:find("ProgressBar") then
			return
		end
		-- For while-loop animations, run one step or skip
		local co = coroutine.create(fn)
		coroutine.resume(co, ...)
	end,
	delay = function(_, fn)
		if fn then fn() end
	end,
	wait = function()
		coroutine.yield()
	end,
}

Color3 = {}
function Color3.fromRGB(r, g, b)
	return { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 }
end
function Color3.fromHSV(h, s, v)
	return { R = h or 0, G = s or 0, B = v or 0 }
end
function Color3.toHSV(c)
	return c and c.R or 0.5, c and c.G or 0.5, c and c.B or 0.8
end

Vector2 = {
	new = function(x, y)
		return setmetatable({ X = x or 0, Y = y or 0 }, {
			__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end,
			__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end,
		})
	end,
}

UDim = {
	new = function(s, o) return { Scale = s or 0, Offset = o or 0 } end,
}

UDim2 = {
	new = function(sx, ox, sy, oy)
		return {
			X = UDim.new(sx, ox),
			Y = UDim.new(sy, oy),
		}
	end,
}

Rect = {
	new = function(minX, minY, maxX, maxY)
		return {
			Min = Vector2.new(minX or 0, minY or 0),
			Max = Vector2.new(maxX or 0, maxY or 0),
		}
	end,
}

ColorSequenceKeypoint = {
	new = function(t, col) return { Time = t, Value = col } end,
}
ColorSequence = {
	new = function(kps) return { Keypoints = kps } end,
}

NumberSequenceKeypoint = {
	new = function(t, val) return { Time = t, Value = val } end,
}
NumberSequence = {
	new = function(kps) return { Keypoints = kps } end,
}

TweenInfo = {
	new = function(d, es, ed) return { Time = d, EasingStyle = es, EasingDirection = ed } end,
}

Font = {
	new = function(familyAsset, weight, style)
		return {
			Family = familyAsset,
			Weight = weight or "FontWeight.Regular",
			Style = style or "FontStyle.Normal",
		}
	end,
}

-- Executor filesystem and getcustomasset environment pointing to repository root
local function resolveWorkspacePath(rel)
	if rel:find("^/") then
		return rel
	end
	if rel:find("^Win7UI/") then
		return "/root/" .. rel
	end
	return "/root/Win7UI/" .. rel
end

function isfile(rel)
	local f = io.open(resolveWorkspacePath(rel), "rb")
	if f then
		f:close()
		return true
	end
	return false
end

function isfolder(_)
	return true
end

function makefolder(_)
	return true
end

function writefile(rel, data)
	local p = resolveWorkspacePath(rel)
	local f = io.open(p, "wb")
	if f then
		f:write(data)
		f:close()
		return true
	end
	return false
end

function getcustomasset(rel)
	return "rbxasset://custom_fonts/" .. tostring(rel)
end

Enum = setmetatable({}, {
	__index = function(_, group)
		return setmetatable({}, {
			__index = function(_, item)
				return group .. "." .. item
			end,
		})
	end,
})
Enum.KeyCode = {
	RightShift = { Name = "RightShift" },
	RightControl = { Name = "RightControl" },
	F4 = { Name = "F4" },
	Q = { Name = "Q" },
	E = { Name = "E" },
	Backspace = { Name = "Backspace" },
	Escape = { Name = "Escape" },
	Unknown = { Name = "Unknown" },
}

local function makeRBXSignal()
	local conns = {}
	return {
		Connect = function(_, fn)
			local c = { Connected = true, _fn = fn }
			function c:Disconnect() c.Connected = false end
			table.insert(conns, c)
			return c
		end,
		Fire = function(_, ...)
			for _, c in ipairs(conns) do
				if c.Connected then c._fn(...) end
			end
		end,
	}
end

Instance = {}
function Instance.new(className)
	local children = {}
	local propSignals = {}
	local props = {
		ClassName = className,
		Name = className,
		Parent = nil,
		Visible = true,
		ZIndex = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 100, 0, 100),
		AbsolutePosition = Vector2.new(100, 100),
		AbsoluteSize = Vector2.new(600, 400),
		Text = "",
		Image = "",
		ImageTransparency = 0,
		BackgroundTransparency = 0,
		GroupTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		MouseEnter = makeRBXSignal(),
		MouseLeave = makeRBXSignal(),
		MouseButton1Down = makeRBXSignal(),
		MouseButton1Up = makeRBXSignal(),
		MouseButton1Click = makeRBXSignal(),
		InputBegan = makeRBXSignal(),
		InputChanged = makeRBXSignal(),
		InputEnded = makeRBXSignal(),
		Focused = makeRBXSignal(),
		FocusLost = makeRBXSignal(),
	}
	local methods = {
		GetChildren = function()
			local copy = {}
			for i, v in ipairs(children) do copy[i] = v end
			return copy
		end,
		GetDescendants = function(self)
			local out = {}
			local function walk(node)
				for _, ch in ipairs(node:GetChildren()) do
					table.insert(out, ch)
					walk(ch)
				end
			end
			walk(self)
			return out
		end,
		FindFirstChild = function(self, name, recursive)
			for _, ch in ipairs(children) do
				if ch.Name == name then return ch end
			end
			if recursive then
				for _, desc in ipairs(self:GetDescendants()) do
					if desc.Name == name then return desc end
				end
			end
			return nil
		end,
		FindFirstChildOfClass = function(_, cls)
			for _, ch in ipairs(children) do
				if ch.ClassName == cls then return ch end
			end
			return nil
		end,
		FindFirstAncestorWhichIsA = function(self, cls)
			local p = self.Parent
			while p do
				if p:IsA(cls) then return p end
				p = p.Parent
			end
			return nil
		end,
		IsA = function(self, cls)
			if self.ClassName == cls then return true end
			if cls == "GuiObject" then
				return self.ClassName == "Frame"
					or self.ClassName == "ScrollingFrame"
					or self.ClassName == "TextLabel"
					or self.ClassName == "TextButton"
					or self.ClassName == "TextBox"
					or self.ClassName == "ImageLabel"
					or self.ClassName == "ImageButton"
					or self.ClassName == "CanvasGroup"
			end
			return false
		end,
		GetPropertyChangedSignal = function(_, prop)
			if not propSignals[prop] then
				propSignals[prop] = makeRBXSignal()
			end
			return propSignals[prop]
		end,
		Destroy = function(self)
			if self.Parent and self.Parent._removeChild then
				self.Parent:_removeChild(self)
			end
			props.Parent = nil
		end,
		_addChild = function(_, ch)
			table.insert(children, ch)
		end,
		_removeChild = function(_, ch)
			for i = #children, 1, -1 do
				if children[i] == ch then
					table.remove(children, i)
					break
				end
			end
		end,
	}
	local inst = setmetatable({}, {
		__index = function(_, k)
			if methods[k] ~= nil then
				return methods[k]
			end
			if props[k] ~= nil then
				return props[k]
			end
			for _, ch in ipairs(children) do
				if ch.Name == k then
					return ch
				end
			end
			return nil
		end,
		__newindex = function(t, k, v)
			if k == "Parent" then
				local oldP = props.Parent
				if oldP and oldP._removeChild then
					oldP:_removeChild(t)
				end
				props.Parent = v
				if v and v._addChild then
					v:_addChild(t)
				end
			else
				props[k] = v
				if propSignals[k] then
					propSignals[k]:Fire()
				end
			end
		end,
	})
	return inst
end

local services = {
	TweenService = {
		Create = function(_, target, _, goal)
			local tw = {
				Cancelled = false,
				Play = function(self)
					if not self.Cancelled and target and goal then
						for k, v in pairs(goal) do
							target[k] = v
						end
					end
				end,
				Cancel = function(self)
					self.Cancelled = true
				end,
			}
			return tw
		end,
	},
	UserInputService = {
		InputBegan = makeRBXSignal(),
		InputChanged = makeRBXSignal(),
		InputEnded = makeRBXSignal(),
		GetMouseLocation = function() return Vector2.new(300, 200) end,
	},
	Players = {
		LocalPlayer = Instance.new("Player"),
	},
	CoreGui = Instance.new("CoreGui"),
	Workspace = {
		CurrentCamera = { ViewportSize = Vector2.new(1920, 1080) },
	},
}

game = {
	GetService = function(_, name)
		return services[name] or Instance.new(name)
	end,
}

-- Verification assertions start
local passCount = 0
local function check(cond, msg)
	if not cond then
		error("[TEST FAILED] " .. tostring(msg), 2)
	end
	passCount = passCount + 1
end

local function getDistPath(filename)
	local candidates = {
		"dist/" .. filename,
		"/root/Aero7/dist/" .. filename,
		"/storage/emulated/0/Aero7/dist/" .. filename,
		"/root/Win7UI/dist/" .. filename,
	}
	for _, p in ipairs(candidates) do
		local f = io.open(p, "rb")
		if f then
			f:close()
			return p
		end
	end
	return "dist/" .. filename
end

print("=== [1/6] Loading bundled dist/Win7UI.lua ===")
local bundleChunk, loadErr = loadfile(getDistPath("Win7UI.lua"))
check(bundleChunk ~= nil, "Failed to compile dist/Win7UI.lua: " .. tostring(loadErr))

_G.__WIN7UI_LOADER = bundleChunk
local Win7UI = bundleChunk()
_G.__WIN7UI_INSTANCE = Win7UI
check(type(Win7UI) == "table", "Win7UI table returned")
check(Win7UI.Version == "1.0.0-Aero7", "Win7UI version matches")

print("=== [2/6] Verifying 50/50 Split-Gradients & 16 Windows 7 Glass Presets ===")
local btnNormalKps = Win7UI.Theme.Gradients.ButtonNormal.Keypoints
check(#btnNormalKps == 4, "ButtonNormal uses 4-stop split ColorSequence")
check(math.abs(btnNormalKps[2].Time - 0.495) < 0.01 and math.abs(btnNormalKps[3].Time - 0.505) < 0.01, "ButtonNormal has sharp 50/50 midpoint split")
check(#Win7UI.Theme.GlassPresets == 16, "Exactly 16 Windows 7 Personalization Glass Presets present")

print("=== [3/6] Executing dist/Example.lua Showcase ===")
local exampleChunk, exErr = loadfile(getDistPath("Example.lua"))
check(exampleChunk ~= nil, "Failed to compile dist/Example.lua: " .. tostring(exErr))
local demo = exampleChunk()
check(demo and demo.MainWindow and demo.PropertySheetWindow, "Both Explorer and Dialog windows created")

local mainWin = demo.MainWindow
local propWin = demo.PropertySheetWindow

print("=== [4/6] Auditing Aero Glass Window Anatomy (No AI Slop Check) ===")
local winFrame = mainWin.WindowFrame
check(winFrame:FindFirstChild("OuterBevelStroke") ~= nil, "Outer dark 1px bevel border exists")
check(winFrame:FindFirstChild("InnerBevelFrame") ~= nil, "Inner specular 1px bevel highlight exists")
check(winFrame:FindFirstChild("AeroSpecularSheen") ~= nil, "104-degree diagonal specular reflection layer exists")

local sheenGrad = winFrame.AeroSpecularSheen:FindFirstChild("SpecularStreakGradient")
check(sheenGrad and sheenGrad.Rotation == 104, "Specular reflection angle is 104 degrees")

local titleBar = winFrame:FindFirstChild("TitleBar")
local captionCluster = titleBar and titleBar:FindFirstChild("CaptionButtonsCluster")
check(captionCluster ~= nil, "Unified top-edge CaptionButtonsCluster exists")
check(captionCluster.Position.Y.Offset == 0, "CaptionButtonsCluster is attached flush to top edge (Y=0)")
check(captionCluster:FindFirstChild("CloseRedGlowHalo") ~= nil, "Iconic Windows 7 Close Red Glow Halo exists")
check(captionCluster.CloseRedGlowHalo:FindFirstChild("GaussianGlowSlice") ~= nil, "CloseRedGlowHalo uses 9-Slice GaussianGlowSlice per 7.css box-shadow: 0 0 7px 3px #e68e75")
captionCluster.CloseButton.MouseEnter:Fire()
check(captionCluster.CloseRedGlowHalo.BackgroundTransparency == 1 and captionCluster.CloseRedGlowHalo.GaussianGlowSlice.ImageTransparency < 0.25, "Close button hover fades in GaussianGlowSlice while keeping halo Frame BackgroundTransparency=1 (never a flat pale circle)")
captionCluster.CloseButton.MouseLeave:Fire()
check(captionCluster.CloseRedGlowHalo.GaussianGlowSlice.ImageTransparency == 1, "Close button MouseLeave fades GaussianGlowSlice back to 1")
check(captionCluster.CloseButton.Size.X.Offset == 47, "Close button is wider (47px) than Minimize/Maximize (27px)")

print("=== [5/6] Testing Interactive Components, Instant Search, Back/Forward & DWM Transitions ===")
-- Verify Flags & Controls
check(Win7UI.Flags.AssistedTargeting == true, "Checkbox default flag value stored")
Win7UI.Controls.AssistedTargeting:SetValue(false)
check(Win7UI.Flags.AssistedTargeting == false, "Checkbox SetValue updates Flag")

Win7UI.Controls.FOVRadius:SetValue(185)
check(Win7UI.Flags.FOVRadius == 185, "Slider SetValue snaps and updates Flag")

Win7UI.Controls.TargetHitbox:SetValue("UpperTorso")
check(Win7UI.Flags.TargetHitbox == "UpperTorso", "ComboBox SetValue updates Flag")

-- Verify Spinner (NumericUpDown)
check(Win7UI.Flags.PredictionSpinner == 6, "Spinner default value stored")
Win7UI.Controls.PredictionSpinner:SetValue(12)
check(Win7UI.Flags.PredictionSpinner == 12, "Spinner SetValue updates Flag")

-- Verify Listbox multi-select
check(type(Win7UI.Flags.LoadedSubsystems) == "table", "Listbox Multi-select flag table exists")

-- Verify Balloon notification
local balloonNotif = mainWin:Notify({
	Title = "DWM Notification",
	Content = "Testing Balloon Notification with pointer beak.",
	Icon = "Info",
	Duration = 0,
})
check(balloonNotif and balloonNotif.Bubble ~= nil, "Balloon Notify created with Speech Bubble")

-- Verify standard Windows 7 scrollbar (Scrollbar.lua UpButton, DownButton, ThumbGripBars)
local firstTabScrollWrap = mainWin.Tabs[1].PageFrame
local win7Scrollbar = firstTabScrollWrap:FindFirstChild("Win7VerticalScrollbar")
check(win7Scrollbar ~= nil, "Custom Windows 7 Vertical Scrollbar attached to Page")
check(win7Scrollbar:FindFirstChild("ScrollUpButton") ~= nil and win7Scrollbar:FindFirstChild("ScrollDownButton") ~= nil, "Win7 Scrollbar has Up/Down arrow buttons")
check(win7Scrollbar.ScrollThumbTrack.ScrollThumb:FindFirstChild("ThumbGripBars") ~= nil, "Win7 Scrollbar Thumb has 3 horizontal grip lines")

-- Verify Back / Forward navigation history in ExplorerLayout
check(#mainWin.Tabs == 3, "Main Explorer window has 3 tabs")
mainWin:SelectTab(mainWin.Tabs[2])
check(mainWin.Interior.ActiveTab == mainWin.Tabs[2], "Switched to Tab 2")
check(mainWin.Interior.BackOrb.Enabled == true, "Back orb button enabled after tab switch")
mainWin.Interior.BackOrb.Button.MouseButton1Click:Fire()
check(mainWin.Interior.ActiveTab == mainWin.Tabs[1], "Back orb navigated back to Tab 1")
check(mainWin.Interior.ForwardOrb.Enabled == true, "Forward orb button enabled after going back")

-- Orb sprite states (Default 0 | Hover 100 | Pressed 200 | Disabled 300 on the HD sheet)
local fwdBtn = mainWin.Interior.ForwardOrb.Button
local backBtn = mainWin.Interior.BackOrb.Button
check(backBtn.ImageRectOffset.X == 300, "Disabled Back orb shows the Disabled sprite cell (x = 300)")
check(fwdBtn.ImageRectOffset.X == 0, "Enabled Forward orb shows the Default sprite cell (x = 0)")
fwdBtn.MouseEnter:Fire()
check(fwdBtn.ImageRectOffset.X == 100, "Hovered Forward orb shows the Hover sprite cell (x = 100)")
fwdBtn.MouseButton1Down:Fire()
check(fwdBtn.ImageRectOffset.X == 200, "Pressed Forward orb shows the Pressed sprite cell (x = 200)")
fwdBtn.MouseButton1Up:Fire()
check(fwdBtn.ImageRectOffset.X == 100, "Released Forward orb returns to the Hover sprite cell while the cursor is over it")
fwdBtn.MouseLeave:Fire()
check(fwdBtn.ImageRectOffset.X == 0, "Forward orb returns to the Default sprite cell when the cursor leaves")
backBtn.MouseEnter:Fire()
backBtn.MouseButton1Down:Fire()
check(backBtn.ImageRectOffset.X == 300, "Disabled Back orb ignores hover/press and stays on the Disabled sprite cell")
backBtn.MouseLeave:Fire()

-- Verify Instant Search filtering
mainWin.Interior.SearchBox.Text = "Targeting"
check(mainWin.Interior.ItemCountLabel.Text:find("match") ~= nil, "Instant Search filtered controls and updated status count")
mainWin.Interior.SearchBox.Text = ""

-- Verify Minimize to Aero Stub & Restore / Maximize
mainWin:Minimize()
check(mainWin.AeroWindow.IsMinimized == true and mainWin.AeroWindow.MinimizedStub.Visible == true, "Minimize hides window and reveals MinimizedAeroStub")
mainWin:Restore()
check(mainWin.AeroWindow.IsMinimized == false and mainWin.WindowFrame.Visible == true, "Restore brings back AeroWindowFrame")
mainWin:Maximize()
check(mainWin.AeroWindow.IsMaximized == true, "Maximize expands window")
mainWin:RestoreDown()
check(mainWin.AeroWindow.IsMaximized == false, "RestoreDown restores saved bounds")

-- Verify TaskDialog / SubDialog with vector X close button
local dlg = mainWin:ShowDialog({
	Title = "Test TaskDialog",
	Instruction = "Confirm Test",
	Content = "Testing modal subdialog.",
	Icon = "Warning",
})
check(dlg and dlg.DialogFrame ~= nil, "SubDialog TaskDialog created")
check(dlg.DialogFrame.DialogTitleBar.DialogCloseButton:FindFirstChild("Glyph_Close") ~= nil, "SubDialog Close button renders crisp vector Glyph_Close (X) instead of missing font char")
check(dlg.Overlay.BackgroundTransparency == 1, "SubDialog does not dim the screen behind it")
do
	-- Dragging the title bar moves the dialog (position only) and keeps it inside the screen
	dlg.Overlay.AbsoluteSize = Vector2.new(1920, 1080)
	dlg.DialogFrame.AbsoluteSize = Vector2.new(390, 186)
	local dialogBar = dlg.DialogFrame.DialogTitleBar
	local startPos = dlg.DialogFrame.Position
	local startSize = dlg.DialogFrame.Size
	dialogBar.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector2.new(200, 200) })
	services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector2.new(230, 215) })
	check(dlg.DialogFrame.Position.X.Offset == startPos.X.Offset + 30 and dlg.DialogFrame.Position.Y.Offset == startPos.Y.Offset + 15, "SubDialog moves with its title bar drag")
	services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector2.new(5200, 5200) })
	check(dlg.DialogFrame.Position.X.Offset == (1920 - 390) / 2 and dlg.DialogFrame.Position.Y.Offset == (1080 - 186) / 2, "SubDialog drag is clamped to the screen")
	services.UserInputService.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = Vector2.new(5200, 5200) })
	services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = Vector2.new(0, 0) })
	check(dlg.DialogFrame.Position.X.Offset == (1920 - 390) / 2, "SubDialog stops following the mouse after the button is released")
	check(dlg.DialogFrame.Size.X.Offset == startSize.X.Offset and dlg.DialogFrame.Size.Y.Offset == startSize.Y.Offset, "SubDialog size is unchanged by dragging")
end
dlg.Close(true, "OK")

print("=== [6/7] Testing 686 Uploaded Frutiger Aero Icons & SetIcons() Live Binding ===")
check(mainWin.AeroWindow.TitleIcon.Image == "rbxassetid://100649829514645", "Window TitleIcon bound to uploaded imageres/control-panel rbxassetid by default")
check(Win7UI.Assets.GetIcon("Shield") == "rbxassetid://97982816838055", "Shield resolves to uploaded imageres/shield-uac")
check(Win7UI.Assets.GetIcon("imageres/folder-explorer") == "rbxassetid://106058928575906", "Full DLL/name lookup works across 686 icons")
check(Win7UI.Assets.GetIcon("gamepad") == "rbxassetid://82107150961791", "Short-name lookup resolves DDORes/gamepad")
check(Win7UI.Assets.Catalog.shell32["folder-up"] == "rbxassetid://117212475893548", "Assets.Catalog.shell32 lookup works")
Win7UI:SetIcons({
	ControlPanel = "rbxassetid://100649829514645",
	Checkmark = "rbxassetid://101956620876006",
})
check(mainWin.AeroWindow.TitleIcon.Image == "rbxassetid://100649829514645", "SetIcons live-updated Window TitleIcon to rbxassetid")
check(mainWin.AeroWindow.TitleIcon:FindFirstChild("_Win7ProceduralIcon") ~= nil, "Procedural fallback backdrop stays ready until ImageLabel.IsLoaded is true so icons are never blank")

print("=== [7/7] Testing Segoe UI .TTF Custom Font Family & New Windows 7 Components ===")
local fontLoaded, familyAsset = Win7UI:LoadSegoeFont()
check(fontLoaded == true, "Win7UI:LoadSegoeFont() loaded local Segoe UI .ttf files and built SegoeUI.json")
check(type(familyAsset) == "string" and familyAsset:find("SegoeUI%.json") ~= nil, "SegoeUI.json custom asset bound")
check(Win7UI.Theme.FontFaces.Regular ~= nil and Win7UI.Theme.FontFaces.Semibold ~= nil and Win7UI.Theme.FontFaces.Bold ~= nil, "Segoe UI Regular/Semibold/Bold FontFaces constructed")
check(mainWin.AeroWindow.TitleController.MainLabel.FontFace == Win7UI.Theme.FontFaces.Regular, "Window titlebar TextLabel uses Segoe UI FontFace")

-- Verify Tri-State Checkbox (BS_3STATE Indeterminate)
check(Win7UI.Flags.TriStateDemo == "Indeterminate", "Tri-state checkbox initialized to Indeterminate")
Win7UI.Controls.TriStateDemo:SetValue(true)
check(Win7UI.Flags.TriStateDemo == true, "Tri-state checkbox switched to Checked")
Win7UI.Controls.TriStateDemo:SetIndeterminate()
check(Win7UI.Flags.TriStateDemo == "Indeterminate", "Tri-state checkbox SetIndeterminate works")

-- Verify DatePicker / SysMonthCal32
check(Win7UI.Flags.RestorePointDate == "2026-11-05", "DatePicker initialized to 2026-11-05")
Win7UI.Controls.RestorePointDate:SetDate(2026, 12, 25)
check(Win7UI.Flags.RestorePointDate == "2026-12-25", "DatePicker SetDate updates formatted value & Flag")

-- Verify PropertyGrid WEIBadge, Toolbar, SplitButton, StatusBar, SysLink in PropSheetWin
local propGeneralPage = propWin.Tabs[1].PageFrame
local foundWEI, foundToolbar, foundSplitBtn, foundStatusBar, foundSysLink = false, false, false, false, false
for _, desc in ipairs(propGeneralPage:GetDescendants()) do
	if desc.Name == "WEIBadge" then foundWEI = true end
	if desc.Name == "Win7Toolbar" then foundToolbar = true end
	if desc.Name == "Win7SplitButton" then foundSplitBtn = true end
	if desc.Name == "Win7StatusBar" then foundStatusBar = true end
	if desc.Name == "SysLinkButton" then foundSysLink = true end
end
check(foundWEI, "PropertyGrid with Windows Experience Index (WEIBadge 7.9) rendered")
check(foundToolbar, "Windows 7 Aero Flat Toolbar (ToolbarWindow32) rendered")
check(foundSplitBtn, "Windows 7 SplitButton (BS_SPLITBUTTON) rendered")
check(foundStatusBar, "Windows 7 Multi-field StatusBar (msctls_statusbar32) rendered")
check(foundSysLink, "Windows 7 SysLink Hyperlink control rendered")

print("=== [8/8] Testing Gaussian Feather Shadow Rings, Jewel Orbs, Vector Chevrons & Mobile Viewport Clamping ===")
-- 1. Verify 9-slice Gaussian shadow and 12 cumulative outward feather shadow rings
check(mainWin.AeroWindow.GlassLayers.ShadowSlice ~= nil and mainWin.AeroWindow.GlassLayers.ShadowSlice.ScaleType == Enum.ScaleType.Slice, "9-Slice Gaussian DWMDropShadowSlice created with ScaleType.Slice")
check(mainWin.AeroWindow.GlassLayers.ShadowRings ~= nil and #mainWin.AeroWindow.GlassLayers.ShadowRings == 12, "12 continuous cumulative Gaussian Feather ShadowRings created")
check(winFrame.DWMDropShadowMid:FindFirstChild("FeatherRing_1") ~= nil and winFrame.DWMDropShadowMid.FeatherRing_1.BackgroundTransparency == 1, "FeatherRing_1 is hollow (BackgroundTransparency=1) so glass stays bright")
check(winFrame.DWMDropShadowOuter.FeatherRing_12.Position.Y.Offset == 0 and winFrame.DWMDropShadowOuter.FeatherRing_12.Size.Y.Offset == 0, "All FeatherRings are anchored flush to window border (zero yShift step discontinuity)")

-- 2. Verify Back / Forward jewel orbs, bloom halo, inner glass ring, vector arrow, and history dropdown
local navBar = mainWin.Interior.Root.ExplorerNavigationBar
check(navBar.BackgroundTransparency == 1 and mainWin.Interior.Root.BackgroundTransparency == 1, "ExplorerNavigationBar & ClientOuterFrame are transparent (DwmExtendFrameIntoClientArea - no opaque background under Back/Forward/Address/Search)")
local bfHousing = navBar:FindFirstChild("BackForwardHousing")
check(bfHousing ~= nil and bfHousing.BackgroundTransparency == 1, "BackForwardHousing has no full pill background (BackgroundTransparency=1)")
local navFrame = bfHousing:FindFirstChild("BackForwardFrame")
check(navFrame ~= nil and navFrame.ClassName == "ImageLabel" and navFrame.ImageRectSize.X == 244 and navFrame.ImageRectSize.Y == 120 and navFrame.ImageRectOffset.X == 0 and navFrame.ImageRectOffset.Y == 208, "BackForwardFrame glass capsule sprite sits beneath both orbs (244x120 @4x cell cut from the HD sheet)")
check(navFrame.Size.X.Offset == 61 and navFrame.Size.Y.Offset == 30 and bfHousing.Size.Y.Offset == 30, "BackForwardFrame is 61x30 logical px and the housing matches its height")
check(bfHousing.ConcaveBridge3D.Visible == false, "UI-built ConcaveBridge3D fallback is hidden once the HD frame sprite is available")
check(bfHousing.HistoryDropdownButton.Position.X.Offset >= navFrame.Size.X.Offset, "HistoryDropdownButton chevron sits just right of the frame (never overlapping the orbs)")
check(navBar.InstantSearchBoxWrap.Size.X.Offset == 176 and navBar.InstantSearchBoxWrap.Position.X.Offset == -182, "InstantSearchBoxWrap restored to 176px width with 6px right margin (-182) so right border is never clipped")
local backSprite, fwdSprite = mainWin.Interior.BackOrb.Button, mainWin.Interior.ForwardOrb.Button
check(backSprite.ClassName == "ImageButton" and fwdSprite.ClassName == "ImageButton", "Back/Forward orbs are ImageButtons using the HD vector-rendered sprite sheet")
check(backSprite.Size.X.Offset == 25 and backSprite.Size.Y.Offset == 26 and fwdSprite.Size.X.Offset == 25 and fwdSprite.Size.Y.Offset == 26, "Orbs are 25x26 logical px (SVG artwork size)")
check(backSprite.ImageRectSize.X == 100 and backSprite.ImageRectSize.Y == 104 and backSprite.ImageRectOffset.Y == 0 and fwdSprite.ImageRectOffset.Y == 104, "Back uses sheet row 0, Forward uses sheet row 1 (100x104 cells)")
check(backSprite.Position.X.Offset == 3 and fwdSprite.Position.X.Offset == 33, "Orbs centered in the frame lobes (centers x = 15.5 / 45.5)")
check(bfHousing:FindFirstChild("HistoryDropdownButton") ~= nil, "HistoryDropdownButton chevron exists in BackForwardHousing")
check(bfHousing.HistoryDropdownButton.Win7VectorChevron:FindFirstChild("ChevronArm_1") ~= nil and bfHousing.HistoryDropdownButton.Win7VectorChevron.ChevronArm_1.Rotation ~= 0, "Win7VectorChevron uses smooth rotated arms (no pixel staircase)")

-- 3. Verify mobile viewport clamping (~78%x80% small screen) and touch drag hitbox
check(titleBar:FindFirstChild("TitleDragHitBox") ~= nil, "Dedicated TitleDragHitBox exists for Mobile touch dragging")
services.Workspace.CurrentCamera.ViewportSize = Vector2.new(640, 360) -- Simulate small landscape mobile screen
mainWin.AeroWindow:_FitToViewport()
check(mainWin.WindowFrame.Size.X.Offset <= 500 and mainWin.WindowFrame.Size.Y.Offset <= 290, "Mobile _FitToViewport scaled window to comfortable ~78%x80% mobile screen with breathing room")
check(mainWin.WindowFrame.Position.X.Offset >= 20 and mainWin.WindowFrame.Position.Y.Offset >= 18, "Mobile _FitToViewport centered window with >=18px top margin so dragging never triggers top Aero Snap")
services.Workspace.CurrentCamera.ViewportSize = Vector2.new(1920, 1080)

print("=== [9/9] Testing Search Ellipsis, Hierarchy Bar («, ..., Scroll), Default Tab Icons, MenuBar & Collapsible Sidebar ===")
-- 1. Verify search box text ellipsis (TextTruncate.AtEnd)
local searchWrap = mainWin.Interior.Root.ExplorerNavigationBar:FindFirstChild("InstantSearchBoxWrap")
check(searchWrap ~= nil and searchWrap:FindFirstChild("SearchPlaceholderLabel") ~= nil, "InstantSearchBoxWrap has dedicated SearchPlaceholderLabel")
check(searchWrap.SearchPlaceholderLabel.TextTruncate == Enum.TextTruncate.AtEnd, "SearchPlaceholderLabel truncates long placeholder with '...'")
check(mainWin.Interior.SearchBox.TextTruncate == Enum.TextTruncate.AtEnd, "SearchInput truncates long query with '...'")

-- 2. Verify Hierarchy bar (AddressIcon, double-chevron «, ellipsis collapse, horizontal scroll)
local addrBar = mainWin.Interior.AddressBar
check(addrBar:FindFirstChild("HierarchyIconButton") ~= nil and mainWin.Interior.AddressIcon ~= nil, "Hierarchy bar has AddressIcon at the start")
check(addrBar:FindFirstChild("HierarchyOverflowButton") ~= nil and addrBar.HierarchyOverflowButton:FindFirstChild("Win7VectorDoubleChevron") ~= nil, "Hierarchy bar has double-chevron («) button pointing into the icon")
check(mainWin.Interior.BreadcrumbContainer.ClassName == "ScrollingFrame" and mainWin.Interior.BreadcrumbContainer.ScrollingDirection == Enum.ScrollingDirection.X, "BreadcrumbSegments is a horizontal ScrollingFrame")
check(mainWin.Interior.BreadcrumbContainer:FindFirstChild("Breadcrumb_Ellipsis") ~= nil, "Long hierarchy path shows '...' (Breadcrumb_Ellipsis) by default")
-- Click "..." to expand full hierarchy path and enable horizontal scroll
mainWin.Interior.BreadcrumbContainer.Breadcrumb_Ellipsis.MouseButton1Click:Fire()
check(mainWin.Interior.HierarchyExpanded == true, "Clicking '...' expands full hierarchy path for horizontal scrolling")
check(mainWin.Interior.BreadcrumbContainer:FindFirstChild("Breadcrumb_Ellipsis") == nil, "Expanded hierarchy shows all full path segments without ellipsis")
-- Test updating hierarchy icon via API
mainWin:SetHierarchyIcon("Explorer")
check(mainWin.Interior.AddressIcon.Image == Win7UI.Assets.GetIcon("Explorer"), "Window:SetHierarchyIcon() updates the hierarchy bar icon")

-- 3. Verify default icons on Tab and DialogTab banners
check(mainWin.Tabs[1].HeaderIcon ~= nil and mainWin.Tabs[1].HeaderIcon.Image ~= "", "Main Tab Banner (ControlPanelBanner) HeaderIcon displays bound icon")
check(propWin.Tabs[1].TabIcon ~= nil and propWin.Tabs[1].TabIcon.Image == Win7UI.Assets.GetIcon("Computer"), "DialogLayout General tab resolves and displays 'Computer' icon")

-- 4. Verify MenuBar ("File" and "View" in PropSheetWin) dimensions and ScreenGui popup binding
local menuBarInstance = propGeneralPage:FindFirstChild("Win7MenuBar", true)
check(menuBarInstance ~= nil, "Win7MenuBar rendered in GeneralPropTab")
local fileMenuBtn = menuBarInstance.MenuBarItemsRow:FindFirstChild("TopMenu_File")
local viewMenuBtn = menuBarInstance.MenuBarItemsRow:FindFirstChild("TopMenu_View")
check(fileMenuBtn ~= nil and fileMenuBtn.Size.X.Offset >= 38, "TopMenu_File button has explicit non-zero width")
check(viewMenuBtn ~= nil and viewMenuBtn.Size.X.Offset >= 38, "TopMenu_View button has explicit non-zero width")
fileMenuBtn.MouseButton1Click:Fire()
local popupOnScreenGui = propWin.ScreenGui:FindFirstChild("Win7PopupMenu")
check(popupOnScreenGui ~= nil and popupOnScreenGui.Visible == true and popupOnScreenGui.Size.Y.Offset >= 40, "Clicking TopMenu_File opens Win7PopupMenu on root ScreenGui with explicit pixel height")
check(popupOnScreenGui:FindFirstChild("MenuInnerWhiteInset") ~= nil and popupOnScreenGui:FindFirstChild("GutterSeparatorDark") ~= nil and popupOnScreenGui:FindFirstChild("GutterSeparatorLight") ~= nil, "Win7PopupMenu has 1px white inset rim (MenuInnerWhiteInset) and etched double gutter divider per 7.css _menu.scss")

-- 5. Verify collapsible sidebar categories with Windows 7 animation
local homeCat = mainWin.Interior.Categories["Control Panel Home"]
check(homeCat ~= nil and homeCat.Expanded == true and homeCat.ItemsHolder.Size.Y.Offset > 0, "Sidebar category 'Control Panel Home' starts expanded with items visible")
homeCat.Header.MouseButton1Click:Fire()
check(homeCat.Expanded == false and homeCat.Chevron.Direction == "Right" and homeCat.ItemsHolder.Size.Y.Offset == 0, "Clicking Sidebar category collapses its items to height 0 and rotates chevron to Right")
homeCat.Header.MouseButton1Click:Fire()
check(homeCat.Expanded == true and homeCat.Chevron.Direction == "Down" and homeCat.ItemsHolder.Size.Y.Offset > 0, "Clicking Sidebar category again expands its items back with Down chevron")

print("=== [10/10] Testing In-Page TabControl, Multi-line TextArea, Editable ComboBox, Vertical Slider, ListView Resizing & Spinner ===")
local perfPage = propWin.Tabs[2].PageFrame

-- 1. In-Page TabControl (SysTabControl32 / 7.css menu[role="tablist"] & [role="tabpanel"])
local inPageTabControl = perfPage:FindFirstChild("Win7TabControl_Advanced Tuning", true)
check(inPageTabControl ~= nil, "In-Page TabControl (SysTabControl32) rendered inside Visual Effects page")
local tabListRow = inPageTabControl:FindFirstChild("TabListRow")
local visualTabBtn = tabListRow:FindFirstChild("TabBtn_Visual Settings")
local logTabBtn = tabListRow:FindFirstChild("TabBtn_Log Notes")
check(visualTabBtn ~= nil and logTabBtn ~= nil, "In-Page TabControl has both tab buttons in TabListRow")
check(visualTabBtn.ActiveBottomBridge.Visible == true, "Active in-page tab has ActiveBottomBridge visible to merge with panel")
check(logTabBtn.ActiveBottomBridge.Visible == false, "Inactive in-page tab has ActiveBottomBridge hidden")

-- Test switching in-page tab
logTabBtn.MouseButton1Click:Fire()
check(logTabBtn.ActiveBottomBridge.Visible == true and visualTabBtn.ActiveBottomBridge.Visible == false, "Clicking in-page tab switches active tab and bottom bridge")

-- 2. Multi-line TextArea (WC_EDIT ES_MULTILINE / 7.css textarea)
local textAreaWrap = inPageTabControl:FindFirstChild("TextArea_Configuration Notes (Multi-Line Edit):", true)
check(textAreaWrap ~= nil, "Multi-Line TextArea rendered inside in-page tab")
local textInput = textAreaWrap:FindFirstChild("EditInput", true)
check(textInput ~= nil and textInput.MultiLine == true and textInput.TextWrapped == true, "EditInput has MultiLine=true and TextWrapped=true")
check(Win7UI.Flags.ConfigNotes:find("Windows 7 Aero Glass") ~= nil, "ConfigNotes flag initialized with multi-line default string")
Win7UI.Controls.ConfigNotes:SetValue("Updated multi-line notes\nLine 2")
check(Win7UI.Flags.ConfigNotes == "Updated multi-line notes\nLine 2", "TextArea SetValue updates Flag and multiline string")

-- 3. Editable ComboBox (CBS_DROPDOWN - Text Box + Dropdown Arrow Button)
local editableCombo = inPageTabControl:FindFirstChild("ComboBox_Smoothing Algorithm:", true)
check(editableCombo ~= nil, "Editable ComboBox rendered inside in-page tab")
local editComboFrame = editableCombo:FindFirstChild("Win7EditableComboFrame", true)
check(editComboFrame ~= nil, "Win7EditableComboFrame exists for CBS_DROPDOWN")
check(editComboFrame:FindFirstChild("ComboEditInput") ~= nil, "CBS_DROPDOWN has active ComboEditInput for typing")
check(editComboFrame:FindFirstChild("ComboDropDownButton") ~= nil, "CBS_DROPDOWN has dedicated ComboDropDownButton")
check(Win7UI.Flags.SmoothAlgo == "Bicubic Filtering", "Editable ComboBox flag initialized to Bicubic Filtering")
Win7UI.Controls.SmoothAlgo:SetValue("Custom Filter 4x")
check(Win7UI.Flags.SmoothAlgo == "Custom Filter 4x", "Editable ComboBox allows setting custom typed text")

-- 4. Vertical Slider (msctls_trackbar32 TBS_VERT / 7.css .is-vertical)
local vSlider = propWin.Tabs[1]:AddVerticalSlider({
	Title = "Master Volume",
	Min = 0,
	Max = 100,
	Default = 65,
	Suffix = "%",
	Flag = "MasterVolumeSlider",
})
check(vSlider ~= nil and vSlider.IsVertical == true, "Vertical Slider created with IsVertical=true")
local vSliderWrap = propWin.Tabs[1].PageFrame:FindFirstChild("Slider_Vert_Master Volume", true)
check(vSliderWrap ~= nil, "Slider_Vert_Master Volume frame rendered in Dialog page")
check(Win7UI.Flags.MasterVolumeSlider == 65, "Vertical Slider flag initialized to 65")
vSlider:SetValue(90)
check(Win7UI.Flags.MasterVolumeSlider == 90, "Vertical Slider SetValue updates to 90")

-- 5. ListView Column Resizing (SysHeader32 column divider drag handles)
local listViewInstance = mainWin.Tabs[2].PageFrame:FindFirstChild("ListView_Active Connections", true)
check(listViewInstance ~= nil, "ListView_Active Connections found")
local headerBar = listViewInstance:FindFirstChild("ListViewHeaderBar")
check(headerBar ~= nil, "ListViewHeaderBar exists")
local col1 = headerBar:FindFirstChild("ColHeader_Process / Module")
check(col1 ~= nil and col1:FindFirstChild("ResizeHandle_1") ~= nil, "ColHeader has interactive ResizeHandle_1 for drag resizing")

-- 6. Loading Spinner / Activity Indicator (7.css gui/_spinner.scss - 20x20px Aero Torus Ring & 18-frame Sprite Sheet)
local spinnerInstance = perfPage:FindFirstChild("LoadingSpinner_Evaluating Windows Aero desktop performance...", true)
check(spinnerInstance ~= nil, "LoadingSpinner found in Visual Effects page")
local ringHolder = spinnerInstance:FindFirstChild("SpinnerRingHolder")
check(ringHolder ~= nil and ringHolder.Size.X.Offset == 20 and ringHolder.Size.Y.Offset == 20, "SpinnerRingHolder exists with exact 20x20px size per 7.css _spinner.scss")
check(ringHolder:FindFirstChild("AeroTorusRing") ~= nil and ringHolder:FindFirstChild("SpinnerSpriteImage") ~= nil, "SpinnerRingHolder has AeroTorusRing and 18-frame SpinnerSpriteImage (no fake radial dots)")
local spriteImg = ringHolder:FindFirstChild("SpinnerSpriteImage")
check(spriteImg ~= nil and spriteImg.ImageRectSize.X == 160 and spriteImg.ImageRectSize.Y == 160, "SpinnerSpriteImage configured with 8x HD 160x160px frame resolution")

print("=== [11/11] Testing Sidebar Selection Edge Padding, Corner Resize Anchoring (Mobile) & Window Fade ===")
-- 1. Sidebar: item container has UIPadding so selection stroke is not clipped
local homeItems = mainWin.Interior.Categories["Control Panel Home"].ItemsHolder
local foundPad = nil
for _, ch in ipairs(homeItems:GetChildren()) do
	if ch.ClassName == "UIPadding" then foundPad = ch end
end
check(foundPad ~= nil and foundPad.PaddingLeft.Offset >= 2 and foundPad.PaddingRight.Offset >= 2, "Sidebar CategoryItems holder has 2px side padding so selection border is not clipped")

-- 2. Dragging bottom-right handle resizes window without shifting position
services.Workspace.CurrentCamera.ViewportSize = Vector2.new(640, 360)
mainWin.AeroWindow:_FitToViewport()
local wf = mainWin.WindowFrame
local posBefore = wf.Position
local sizeBefore = wf.Size
local grip = wf:FindFirstChild("ResizeGrip_BottomRight")
check(grip ~= nil, "ResizeGrip_BottomRight exists")
do
	local gripCount = 0
	for _, child in ipairs(wf:GetChildren()) do
		if child.Name:find("^ResizeGrip_") then
			gripCount = gripCount + 1
		end
	end
	check(gripCount == 1, "Only the bottom-right corner can resize a window (no edge/other-corner grips)")
end
grip.InputBegan:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector2.new(300, 250) })
services.UserInputService.InputChanged:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector2.new(330, 270) })
check(wf.Position.X.Offset == posBefore.X.Offset and wf.Position.Y.Offset == posBefore.Y.Offset, "BottomRight resize keeps window Position unchanged (no push to top edge)")
check(wf.Size.X.Offset >= sizeBefore.X.Offset and wf.Size.Y.Offset >= sizeBefore.Y.Offset, "BottomRight resize grows Size")
check(wf.Position.Y.Offset + wf.Size.Y.Offset <= 360, "Resize keeps bottom edge inside the viewport")
services.UserInputService.InputEnded:Fire({ UserInputType = Enum.UserInputType.Touch, Position = Vector2.new(330, 270) })
services.Workspace.CurrentCamera.ViewportSize = Vector2.new(1920, 1080)

-- 3. Fade Open/Close: closing and reopening restores baseline glass and content transparency
local bgBefore = wf.BackgroundTransparency
local titleBefore = wf.TitleBar:FindFirstChild("TitleDragHitBox") and wf.TitleBar.TitleDragHitBox.BackgroundTransparency
mainWin:ToggleVisibility(false)
check(wf.Visible == false and wf.BackgroundTransparency == bgBefore, "Close fade restores original glass transparency after hiding")
mainWin:ToggleVisibility(true)
check(wf.Visible == true and wf.BackgroundTransparency == bgBefore, "Open fade ends at original glass transparency")
local titleAfter = wf.TitleBar:FindFirstChild("TitleDragHitBox") and wf.TitleBar.TitleDragHitBox.BackgroundTransparency
check(titleBefore == titleAfter, "Content transparency preserved across Close/Open fade cycle")

-- 4. Verify System Properties (PropSheetWin) on reopening after initial hidden state:
--    Ensures TabPageSheetFrame, ClientOuterFrame (#F0F0F0) and caption button icons are intact
propWin:ToggleVisibility(true)
propWin:ToggleVisibility(false)
propWin:ToggleVisibility(true)
local propWf = propWin.WindowFrame
local propClient = propWf:FindFirstChild("ClientOuterFrame")
local propPageSheet = propClient and propClient:FindFirstChild("TabPageSheetFrame")
local propCluster = propWf.TitleBar:FindFirstChild("CaptionButtonsCluster")
local minBar = propCluster.MinimizeButton.Glyph_Minimize:FindFirstChild("MinBar")
local maxTopBar = propCluster.MaximizeButton.Glyph_Maximize.MaxBox:FindFirstChild("TopBar")
local closeX1 = propCluster.CloseButton:FindFirstChild("MainBar_1", true)
check(propClient ~= nil and propClient.BackgroundTransparency == 0, "System Properties ClientOuterFrame (#F0F0F0) remains visible (BackgroundTransparency=0)")
check(propPageSheet ~= nil and propPageSheet.BackgroundTransparency == 0, "System Properties white content box (TabPageSheetFrame #FFFFFF) remains visible (BackgroundTransparency=0)")
check(minBar ~= nil and minBar.BackgroundTransparency == 0, "System Properties Minimize button icon (MinBar) remains visible")
check(maxTopBar ~= nil and maxTopBar.BackgroundTransparency == 0, "System Properties Maximize button icon (MaxBox/TopBar) remains visible")
check(closeX1 ~= nil and closeX1.BackgroundTransparency == 0, "System Properties Close button icon (Win7VectorCloseX) remains visible")

print("=== [12/12] Testing Windows 7 Color Picker (ChooseColor Dialog 0x12b0 & Inline ColorPicker) ===")
-- 1. Win7UI.ColorDialog module exists and exports authentic 48 basic colors
check(Win7UI.ColorDialog ~= nil, "Win7UI.ColorDialog module is exported")
check(type(Win7UI.ColorDialog.BasicColors) == "table" and #Win7UI.ColorDialog.BasicColors == 48, "BasicColors contains exactly 48 colors from comdlg32.dll 0x66ae0")
check(Win7UI.ColorDialog.BasicColors[1].R == 1 and math.floor(Win7UI.ColorDialog.BasicColors[1].G * 255 + 0.5) == 128, "First basic color is #FF8080")
check(math.floor(Win7UI.ColorDialog.BasicColors[41].R * 255) == 0 and math.floor(Win7UI.ColorDialog.BasicColors[48].R * 255) == 255, "Includes Black #000000 and White #FFFFFF")

-- 2. HLS <-> RGB algorithms match Win32 ColorRGBToHLS and ColorHLSToRGB
local h1, s1, l1 = Win7UI.ColorDialog.RgbToHls(255, 0, 0)
check(h1 == 0 and s1 == 240 and l1 == 120, "Pure Red RGB(255,0,0) converts to HLS(0, 240, 120)")
local r1, g1, b1 = Win7UI.ColorDialog.HlsToRgb(h1, l1, s1)
check(r1 == 255 and g1 == 0 and b1 == 0, "HLS(0, 240, 120) converts back to pure Red RGB(255,0,0)")

local h2, s2, l2 = Win7UI.ColorDialog.RgbToHls(0, 255, 0)
check(h2 == 80 and s2 == 240 and l2 == 120, "Pure Green RGB(0,255,0) converts to HLS(80, 240, 120)")
local r2, g2, b2 = Win7UI.ColorDialog.HlsToRgb(h2, l2, s2)
check(r2 == 0 and g2 == 255 and b2 == 0, "HLS(80, 240, 120) converts back to pure Green RGB(0,255,0)")

local h3, s3, l3 = Win7UI.ColorDialog.RgbToHls(0, 0, 255)
check(h3 == 160 and s3 == 240 and l3 == 120, "Pure Blue RGB(0,0,255) converts to HLS(160, 240, 120)")
local r3, g3, b3 = Win7UI.ColorDialog.HlsToRgb(h3, l3, s3)
check(r3 == 0 and g3 == 0 and b3 == 255, "HLS(160, 240, 120) converts back to pure Blue RGB(0,0,255)")

-- 3. ShowColorDialog API on Win7UI and windowController
local dialogInstance = Win7UI:ShowColorDialog({
	Title = "Color",
	InitialColor = Color3.fromRGB(0, 128, 255),
	FullOpen = true,
})
check(dialogInstance ~= nil, "Win7UI:ShowColorDialog creates dialog instance")
check(dialogInstance.Overlay ~= nil and dialogInstance.Overlay.Name == "Win7ColorModalOverlay", "Modal overlay Win7ColorModalOverlay exists")
check(dialogInstance.Overlay.BackgroundTransparency == 1, "ColorDialog does not dim the screen behind it")
check(dialogInstance.DialogFrame ~= nil and dialogInstance.DialogFrame.Name == "Win7ChooseColorDialog", "DialogFrame Win7ChooseColorDialog exists")

local colorClientBox = dialogInstance.DialogFrame:FindFirstChild("DialogClientBox")
check(colorClientBox ~= nil, "DialogClientBox found")
local basicGrid = colorClientBox:FindFirstChild("BasicColorsGrid")
check(basicGrid ~= nil and #basicGrid:GetChildren() == 48, "BasicColorsGrid has all 48 swatch buttons")
local customGrid = colorClientBox:FindFirstChild("CustomColorsGrid")
check(customGrid ~= nil and #customGrid:GetChildren() == 16, "CustomColorsGrid has 16 custom swatch buttons")
local defineBtn = colorClientBox:FindFirstChild("DefineCustomColorsButton")
check(defineBtn ~= nil, "DefineCustomColorsButton exists")
local okBtn = colorClientBox:FindFirstChild("ColorDialogOKButton")
check(okBtn ~= nil, "ColorDialogOKButton exists")
local cancelBtn = colorClientBox:FindFirstChild("ColorDialogCancelButton")
check(cancelBtn ~= nil, "ColorDialogCancelButton exists")

local rightPanel = colorClientBox:FindFirstChild("RightCustomTuningPanel")
check(rightPanel ~= nil, "RightCustomTuningPanel exists")
check(rightPanel:FindFirstChild("Spectrum2DBox") ~= nil, "Spectrum2DBox exists in right panel")
check(rightPanel:FindFirstChild("LuminositySliderBar") ~= nil, "LuminositySliderBar exists in right panel")
check(rightPanel:FindFirstChild("ColorSolidPreviewBox") ~= nil, "ColorSolidPreviewBox exists in right panel")
check(rightPanel:FindFirstChild("AddToCustomColorsButton") ~= nil, "AddToCustomColorsButton exists in right panel")

-- Test Add to Custom Colors
local addBtn = rightPanel:FindFirstChild("AddToCustomColorsButton")
addBtn.MouseButton1Click:Fire()
check(Win7UI.DWM.CustomColors[1] ~= nil, "Win7UI.DWM.CustomColors[1] updated with current tuned color")

-- Test selecting Basic Swatch (Swatch 9 = Pure Red #FF0000)
local basicSwatch9 = basicGrid:FindFirstChild("BasicSwatch_9")
check(basicSwatch9 ~= nil, "BasicSwatch_9 found")
basicSwatch9.MouseButton1Click:Fire()
local previewBox = rightPanel:FindFirstChild("ColorSolidPreviewBox")
check(previewBox ~= nil and previewBox.BackgroundColor3.R == 1 and previewBox.BackgroundColor3.G == 0 and previewBox.BackgroundColor3.B == 0, "Clicking BasicSwatch_9 updates preview to pure Red")

-- Test Define Custom Colors Toggle
local dialogWidthExpanded = dialogInstance.DialogFrame.Size.X.Offset
check(dialogWidthExpanded == 484, "Expanded dialog width is 484px")
defineBtn.MouseButton1Click:Fire()
check(defineBtn.Text:find("Define Custom Colors") ~= nil, "DefineCustomColorsButton toggles correctly")

dialogInstance.Close()

-- 4. Inline AddColorPicker Component in Tab
local testPickerRow = mainWin.Tabs[3].PageFrame:FindFirstChild("ColorPickerRow_Accent / Highlight Color:", true)
check(testPickerRow ~= nil, "ColorPickerRow found in Personalize tab")
check(Win7UI.Flags.HighlightColor ~= nil, "HighlightColor flag registered")
local swatchBtn = testPickerRow:FindFirstChild("ColorSwatchButton")
check(swatchBtn ~= nil, "ColorSwatchButton exists in row")
local hexValue = testPickerRow:FindFirstChild("ColorHexValue")
check(hexValue ~= nil and hexValue.Text == "#0078D7", "ColorHexValue displays correct initial hex #0078D7")

-- Test opening ChooseColor dialog by clicking inline swatch button
swatchBtn.MouseButton1Click:Fire()
local overlayFromSwatch = services.CoreGui:FindFirstChild("Win7ColorModalOverlay", true) or services.Workspace:FindFirstChild("Win7ColorModalOverlay", true)
check(overlayFromSwatch ~= nil, "Clicking inline swatch button opened ChooseColor dialog")
local frameFromSwatch = overlayFromSwatch:FindFirstChild("Win7ChooseColorDialog")
check(frameFromSwatch ~= nil, "ChooseColor dialog frame is visible")
local okBtnFromSwatch = frameFromSwatch:FindFirstChild("ColorDialogOKButton", true)
check(okBtnFromSwatch ~= nil, "ColorDialogOKButton found in dialog")
okBtnFromSwatch.MouseButton1Click:Fire()

print(string.format("\n[SUCCESS] All %d verification assertions passed with 0 errors!", passCount))
