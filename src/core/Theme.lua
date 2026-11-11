--!nonstrict
-- Aero7: core/Theme - Windows 7 Aero color system, 50/50 split gradients, and personalization glass presets.

local Theme = {}

-- Helper for standard Windows 7 50/50 split-gradients
function Theme.MakeSplitSequence(topStart, topMid, botMid, botEnd)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0.000, topStart),
		ColorSequenceKeypoint.new(0.495, topMid),
		ColorSequenceKeypoint.new(0.505, botMid),
		ColorSequenceKeypoint.new(1.000, botEnd),
	})
end

-- 16 Personalization glass color presets ("Window Color and Appearance")
Theme.GlassPresets = {
	{ Name = "Sky",       Color = Color3.fromRGB(69, 130, 212),  Transparency = 0.26, Glow = Color3.fromRGB(115, 182, 255) },
	{ Name = "Twilight",  Color = Color3.fromRGB(24, 72, 156),   Transparency = 0.20, Glow = Color3.fromRGB(72, 136, 235) },
	{ Name = "Seafoam",   Color = Color3.fromRGB(43, 158, 168),  Transparency = 0.26, Glow = Color3.fromRGB(98, 216, 224) },
	{ Name = "Leaf",      Color = Color3.fromRGB(68, 156, 56),   Transparency = 0.26, Glow = Color3.fromRGB(124, 218, 108) },
	{ Name = "Lime",      Color = Color3.fromRGB(132, 184, 36),  Transparency = 0.28, Glow = Color3.fromRGB(186, 235, 88) },
	{ Name = "Sun",       Color = Color3.fromRGB(219, 152, 24),  Transparency = 0.26, Glow = Color3.fromRGB(255, 206, 84) },
	{ Name = "Pumpkin",   Color = Color3.fromRGB(214, 96, 28),   Transparency = 0.25, Glow = Color3.fromRGB(255, 148, 82) },
	{ Name = "Ruby",      Color = Color3.fromRGB(186, 34, 42),   Transparency = 0.24, Glow = Color3.fromRGB(255, 92, 98) },
	{ Name = "Rose",      Color = Color3.fromRGB(209, 68, 128),  Transparency = 0.26, Glow = Color3.fromRGB(255, 132, 184) },
	{ Name = "Fuchsia",   Color = Color3.fromRGB(156, 52, 172),  Transparency = 0.25, Glow = Color3.fromRGB(218, 114, 235) },
	{ Name = "Violet",    Color = Color3.fromRGB(98, 56, 178),   Transparency = 0.24, Glow = Color3.fromRGB(158, 118, 240) },
	{ Name = "Lavender",  Color = Color3.fromRGB(138, 132, 204), Transparency = 0.28, Glow = Color3.fromRGB(192, 188, 248) },
	{ Name = "Taupe",     Color = Color3.fromRGB(138, 124, 112), Transparency = 0.26, Glow = Color3.fromRGB(194, 182, 170) },
	{ Name = "Chocolate", Color = Color3.fromRGB(108, 68, 42),   Transparency = 0.22, Glow = Color3.fromRGB(172, 124, 92) },
	{ Name = "Slate",     Color = Color3.fromRGB(64, 74, 86),    Transparency = 0.20, Glow = Color3.fromRGB(128, 142, 158) },
	{ Name = "Frost",     Color = Color3.fromRGB(198, 214, 230), Transparency = 0.24, Glow = Color3.fromRGB(238, 246, 255) },
}

Theme.GlassPresetByName = {}
for _, preset in ipairs(Theme.GlassPresets) do
	Theme.GlassPresetByName[preset.Name] = preset
end

-- Current glass color state
Theme.CurrentGlass = {
	Color = Theme.GlassPresets[1].Color,
	Transparency = Theme.GlassPresets[1].Transparency,
	Glow = Theme.GlassPresets[1].Glow,
	InactiveColor = Color3.fromRGB(168, 184, 204),
	InactiveTransparency = 0.44,
}

-- Static color palette from aero.msstyles & Common Controls v6
Theme.Colors = {
	-- Aero Glass window borders
	WindowOuterBorder = Color3.fromRGB(12, 18, 26),
	WindowInnerHighlight = Color3.fromRGB(255, 255, 255),
	ClientOuterBorder = Color3.fromRGB(62, 82, 104),
	ClientInnerHighlight = Color3.fromRGB(242, 247, 252),

	-- Titlebar text colors
	TitleTextActive = Color3.fromRGB(20, 28, 38),
	TitleTextLight = Color3.fromRGB(255, 255, 255),
	TitleGlowLight = Color3.fromRGB(255, 255, 255),
	TitleGlowDark = Color3.fromRGB(0, 0, 0),

	-- Client area backgrounds
	ExplorerClientBg = Color3.fromRGB(255, 255, 255),
	ExplorerNavPaneBg = Color3.fromRGB(241, 245, 251),
	ExplorerNavPaneDivider = Color3.fromRGB(214, 226, 240),
	ExplorerStatusBarTop = Color3.fromRGB(241, 245, 251),
	ExplorerStatusBarBot = Color3.fromRGB(225, 235, 247),
	ExplorerStatusBarBorder = Color3.fromRGB(204, 217, 234),

	DialogFaceBg = Color3.fromRGB(240, 240, 240), -- #F0F0F0 standard Win32/Win7 Dialog
	DialogTabPageBg = Color3.fromRGB(255, 255, 255),
	DialogTabBorder = Color3.fromRGB(137, 140, 149), -- #898C95

	-- Windows 7 typography
	TextPrimary = Color3.fromRGB(30, 30, 30),
	TextSecondary = Color3.fromRGB(92, 102, 112),
	TextDisabled = Color3.fromRGB(160, 160, 160),
	TextInstruction = Color3.fromRGB(0, 51, 153),   -- #003399 (Control Panel main instruction)
	TextLink = Color3.fromRGB(0, 102, 204),         -- #0066CC
	TextLinkHover = Color3.fromRGB(51, 153, 255),   -- #3399FF
	TextGroupTitle = Color3.fromRGB(30, 57, 91),    -- #1E395B

	-- Control borders from Common Controls v6
	ControlBorderNormal = Color3.fromRGB(112, 112, 112),   -- #707070
	ControlBorderHover = Color3.fromRGB(60, 127, 177),     -- #3C7FB1
	ControlBorderPressed = Color3.fromRGB(44, 98, 139),    -- #2C628B
	ControlBorderDisabled = Color3.fromRGB(173, 178, 181), -- #ADB2B5
	ControlInnerGlowHover = Color3.fromRGB(133, 212, 255),

	-- Text input fields (TextBox / Edit)
	EditBorderNormal = Color3.fromRGB(171, 173, 179),      -- #ABADB3
	EditBorderHover = Color3.fromRGB(87, 148, 191),        -- #5794BF
	EditBorderFocused = Color3.fromRGB(60, 127, 177),      -- #3C7FB1
	EditInnerShadow = Color3.fromRGB(227, 233, 239),       -- #E3E9EF

	-- GroupBox (<fieldset>)
	GroupBoxBorder = Color3.fromRGB(213, 223, 229),        -- #D5DFE5
	RuleDivider = Color3.fromRGB(176, 199, 222),

	-- Selection Box trong Explorer / ComboBox / TreeView
	SelectionBorder = Color3.fromRGB(125, 162, 206),       -- #7DA2CE
	SelectionHoverBorder = Color3.fromRGB(184, 214, 251),  -- #B8D6FB

	-- Slider Track
	TrackFill = Color3.fromRGB(231, 234, 234),
	TrackBorderTop = Color3.fromRGB(181, 184, 184),
	TrackBorderBot = Color3.fromRGB(255, 255, 255),
	TrackTick = Color3.fromRGB(164, 168, 172),

	-- ProgressBar Track
	ProgressTrackBg = Color3.fromRGB(230, 230, 230),
	ProgressTrackBorder = Color3.fromRGB(188, 188, 188),

	-- Windows 7 tooltips
	TooltipTop = Color3.fromRGB(255, 255, 255),
	TooltipBot = Color3.fromRGB(228, 229, 240),
	TooltipBorder = Color3.fromRGB(118, 118, 118),
	TooltipText = Color3.fromRGB(42, 42, 42),
}

-- Standard 50/50 split-gradients
Theme.Gradients = {
	-- PushButton / ComboBox / Slider Thumb: Normal state
	ButtonNormal = Theme.MakeSplitSequence(
		Color3.fromRGB(242, 242, 242), -- #F2F2F2
		Color3.fromRGB(235, 235, 235), -- #EBEBEB
		Color3.fromRGB(221, 221, 221), -- #DDDDDD
		Color3.fromRGB(207, 207, 207)  -- #CFCFCF
	),

	-- PushButton / ComboBox / Slider Thumb: Hover state (Aero Blue)
	ButtonHover = Theme.MakeSplitSequence(
		Color3.fromRGB(234, 246, 253), -- #EAF6FD
		Color3.fromRGB(217, 240, 252), -- #D9F0FC
		Color3.fromRGB(190, 230, 253), -- #BEE6FD
		Color3.fromRGB(167, 217, 245)  -- #A7D9F5
	),

	-- PushButton / ComboBox / Slider Thumb: Pressed state
	ButtonPressed = Theme.MakeSplitSequence(
		Color3.fromRGB(229, 244, 252), -- #E5F4FC
		Color3.fromRGB(196, 229, 246), -- #C4E5F6
		Color3.fromRGB(152, 209, 239), -- #98D1EF
		Color3.fromRGB(104, 179, 219)  -- #68B3DB
	),

	-- Disabled buttons
	ButtonDisabled = Theme.MakeSplitSequence(
		Color3.fromRGB(244, 244, 244),
		Color3.fromRGB(244, 244, 244),
		Color3.fromRGB(244, 244, 244),
		Color3.fromRGB(244, 244, 244)
	),

	-- Titlebar Close button (Normal: wine red glass)
	CloseButtonNormal = Theme.MakeSplitSequence(
		Color3.fromRGB(235, 148, 140),
		Color3.fromRGB(206, 92, 82),
		Color3.fromRGB(172, 34, 24),
		Color3.fromRGB(196, 68, 56)
	),

	-- Titlebar Close button (Hover: glowing crimson red)
	CloseButtonHover = Theme.MakeSplitSequence(
		Color3.fromRGB(255, 182, 172),
		Color3.fromRGB(252, 108, 94),
		Color3.fromRGB(232, 17, 35),
		Color3.fromRGB(255, 96, 72)
	),

	-- Titlebar Close button (Pressed)
	CloseButtonPressed = Theme.MakeSplitSequence(
		Color3.fromRGB(214, 114, 102),
		Color3.fromRGB(178, 52, 42),
		Color3.fromRGB(128, 12, 6),
		Color3.fromRGB(158, 34, 24)
	),

	-- Minimize / Maximize buttons (Hover: luminous cyan)
	CaptionButtonHover = Theme.MakeSplitSequence(
		Color3.fromRGB(222, 244, 255),
		Color3.fromRGB(158, 216, 252),
		Color3.fromRGB(58, 152, 224),
		Color3.fromRGB(116, 202, 255)
	),

	-- Minimize / Maximize buttons (Pressed)
	CaptionButtonPressed = Theme.MakeSplitSequence(
		Color3.fromRGB(168, 212, 240),
		Color3.fromRGB(108, 168, 212),
		Color3.fromRGB(32, 96, 154),
		Color3.fromRGB(68, 138, 196)
	),

	-- Explorer Command Bar (glossy silver-blue)
	ExplorerCommandBar = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(246, 250, 254)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(224, 235, 248)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(210, 224, 242)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(225, 236, 250)),
	}),

	-- Item selection box in Explorer / TreeView / ComboBox (Selected)
	ExplorerItemSelected = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(235, 244, 253)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(196, 221, 252)),
	}),

	-- Item selection box in Explorer / TreeView / ComboBox (Hover)
	ExplorerItemHover = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(246, 250, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(226, 240, 254)),
	}),

	-- CommandLink Hover
	CommandLinkHover = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(250, 253, 255)),
		ColorSequenceKeypoint.new(0.48, Color3.fromRGB(236, 246, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(212, 233, 252)),
	}),

	-- ProgressBar: Standard Windows 7 green
	ProgressGreen = Theme.MakeSplitSequence(
		Color3.fromRGB(142, 238, 146),
		Color3.fromRGB(76, 212, 82),
		Color3.fromRGB(26, 166, 32),
		Color3.fromRGB(58, 198, 64)
	),

	-- ProgressBar: Aero blue
	ProgressBlue = Theme.MakeSplitSequence(
		Color3.fromRGB(154, 218, 255),
		Color3.fromRGB(84, 178, 245),
		Color3.fromRGB(24, 128, 214),
		Color3.fromRGB(58, 162, 238)
	),

	-- ProgressBar: Warning yellow (Paused)
	ProgressAmber = Theme.MakeSplitSequence(
		Color3.fromRGB(255, 232, 138),
		Color3.fromRGB(245, 198, 54),
		Color3.fromRGB(214, 152, 12),
		Color3.fromRGB(238, 182, 32)
	),

	-- ProgressBar: Error red
	ProgressRed = Theme.MakeSplitSequence(
		Color3.fromRGB(255, 154, 148),
		Color3.fromRGB(238, 78, 68),
		Color3.fromRGB(192, 24, 18),
		Color3.fromRGB(224, 54, 46)
	),
}

Theme.Fonts = {
	Regular = Enum.Font.SourceSans,
	Semibold = Enum.Font.SourceSansSemibold,
	Bold = Enum.Font.SourceSansBold,
	Italic = Enum.Font.SourceSansItalic,
	Light = Enum.Font.SourceSansLight,
}

-- Custom Segoe UI font family configuration (.ttf on executor via writefile + getcustomasset)
Theme.FontConfig = {
	FamilyName = "Segoe UI",
	Folder = "Win7UI/fonts",
	DescriptorPath = "Win7UI/fonts/SegoeUI.json",
	RawBaseUrl = "https://raw.githubusercontent.com/tobureinhardt/Time-machine/main/fonts/",
	FallbackBaseUrl = "https://raw.githubusercontent.com/mrbvrz/segoe-ui-linux/master/font/",
	Files = {
		{ Name = "Light",          File = "segoeuil.ttf",  Weight = 300, Style = "normal" },
		{ Name = "SemiLight",      File = "segoeuisl.ttf", Weight = 350, Style = "normal" },
		{ Name = "Regular",        File = "segoeui.ttf",   Weight = 400, Style = "normal" },
		{ Name = "Italic",         File = "segoeuii.ttf",  Weight = 400, Style = "italic" },
		{ Name = "Semibold",       File = "seguisb.ttf",   Weight = 600, Style = "normal" },
		{ Name = "SemiboldItalic", File = "seguisbi.ttf",  Weight = 600, Style = "italic" },
		{ Name = "Bold",           File = "segoeuib.ttf",  Weight = 700, Style = "normal" },
		{ Name = "BoldItalic",     File = "segoeuiz.ttf",  Weight = 700, Style = "italic" },
	},
	IsLoaded = false,
	ActiveFamilyAsset = nil,
}

Theme.FontFaces = {
	Regular = nil,
	Semibold = nil,
	Bold = nil,
	Italic = nil,
	BoldItalic = nil,
	Light = nil,
	SemiLight = nil,
}

Theme._TextBindings = {}

local function makeFontFaceSafe(familyAsset, weightEnum, styleEnum)
	if type(Font) == "table" and type(Font.new) == "function" and type(familyAsset) == "string" and familyAsset ~= "" then
		local ok, face = pcall(function()
			return Font.new(familyAsset, weightEnum or Enum.FontWeight.Regular, styleEnum or Enum.FontStyle.Normal)
		end)
		if ok and face then
			return face
		end
	end
	return nil
end

function Theme.ResolveFontVariant(fontVal)
	if fontVal == "Semibold" or fontVal == Enum.Font.SourceSansSemibold or fontVal == Enum.Font.GothamSemibold or fontVal == Enum.Font.BuilderSansMedium then
		return "Semibold"
	elseif fontVal == "Bold" or fontVal == Enum.Font.SourceSansBold or fontVal == Enum.Font.GothamBold or fontVal == Enum.Font.BuilderSansBold then
		return "Bold"
	elseif fontVal == "Italic" or fontVal == Enum.Font.SourceSansItalic then
		return "Italic"
	elseif fontVal == "BoldItalic" then
		return "BoldItalic"
	elseif fontVal == "Light" or fontVal == Enum.Font.SourceSansLight then
		return "Light"
	elseif fontVal == "SemiLight" then
		return "SemiLight"
	end
	return "Regular"
end

function Theme.ApplyFont(inst, variantOrEnum)
	if not inst then
		return
	end
	local variant = Theme.ResolveFontVariant(variantOrEnum)
	local enumFallback = Theme.Fonts[variant] or Theme.Fonts.Regular
	pcall(function()
		inst.Font = enumFallback
	end)
	local customFace = Theme.FontFaces[variant] or Theme.FontFaces.Regular
	if customFace then
		pcall(function()
			inst.FontFace = customFace
		end)
	end
	for i = #Theme._TextBindings, 1, -1 do
		local entry = Theme._TextBindings[i]
		if entry.Instance == inst then
			entry.Variant = variant
			return
		end
	end
	table.insert(Theme._TextBindings, {
		Instance = inst,
		Variant = variant,
	})
end

function Theme.RegisterTextObject(inst, fontProp)
	if not inst then
		return
	end
	local variant = Theme.ResolveFontVariant(fontProp or inst.Font)
	local customFace = Theme.FontFaces[variant] or Theme.FontFaces.Regular
	if customFace then
		pcall(function()
			inst.FontFace = customFace
		end)
	end
	table.insert(Theme._TextBindings, {
		Instance = inst,
		Variant = variant,
	})
end

function Theme.RefreshAllTextFonts()
	for i = #Theme._TextBindings, 1, -1 do
		local entry = Theme._TextBindings[i]
		local inst = entry.Instance
		if inst and inst.Parent then
			local face = Theme.FontFaces[entry.Variant] or Theme.FontFaces.Regular
			if face then
				pcall(function()
					inst.FontFace = face
				end)
			end
		elseif not inst then
			table.remove(Theme._TextBindings, i)
		end
	end
end

function Theme.SetFontFamily(familyAssetId)
	if type(familyAssetId) ~= "string" or familyAssetId == "" then
		return false
	end
	Theme.FontConfig.ActiveFamilyAsset = familyAssetId
	Theme.FontFaces.Regular = makeFontFaceSafe(familyAssetId, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	Theme.FontFaces.Semibold = makeFontFaceSafe(familyAssetId, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	Theme.FontFaces.Bold = makeFontFaceSafe(familyAssetId, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	Theme.FontFaces.Italic = makeFontFaceSafe(familyAssetId, Enum.FontWeight.Regular, Enum.FontStyle.Italic)
	Theme.FontFaces.BoldItalic = makeFontFaceSafe(familyAssetId, Enum.FontWeight.Bold, Enum.FontStyle.Italic)
	Theme.FontFaces.Light = makeFontFaceSafe(familyAssetId, Enum.FontWeight.Light, Enum.FontStyle.Normal)
	Theme.FontFaces.SemiLight = makeFontFaceSafe(familyAssetId, Enum.FontWeight.ExtraLight, Enum.FontStyle.Normal)
	Theme.FontConfig.IsLoaded = (Theme.FontFaces.Regular ~= nil)
	Theme.RefreshAllTextFonts()
	return Theme.FontConfig.IsLoaded
end

-- Automatically loads and registers Segoe UI TTF fonts on executors
function Theme.LoadSegoeFont(options)
	options = options or {}
	if type(options.FamilyAsset) == "string" and options.FamilyAsset ~= "" then
		return Theme.SetFontFamily(options.FamilyAsset)
	end

	local getAssetFn = (type(getcustomasset) == "function" and getcustomasset)
		or (type(getsynasset) == "function" and getsynasset)
		or options.GetCustomAsset
	local writeFileFn = (type(writefile) == "function" and writefile) or options.WriteFile
	local isFileFn = (type(isfile) == "function" and isfile) or options.IsFile
	local isFolderFn = (type(isfolder) == "function" and isfolder) or options.IsFolder
	local makeFolderFn = (type(makefolder) == "function" and makefolder) or options.MakeFolder

	if not getAssetFn or not writeFileFn then
		return false, "Executor lacks getcustomasset/writefile"
	end

	local folder = options.Folder or Theme.FontConfig.Folder
	local baseUrl = options.RawBaseUrl or Theme.FontConfig.RawBaseUrl

	if makeFolderFn then
		pcall(function()
			if not (isFolderFn and isFolderFn("Win7UI")) then
				makeFolderFn("Win7UI")
			end
			if not (isFolderFn and isFolderFn(folder)) then
				makeFolderFn(folder)
			end
		end)
	end

	local facesList = {}
	for _, spec in ipairs(Theme.FontConfig.Files) do
		local targetPath = folder .. "/" .. spec.File
		local alternatePaths = {
			targetPath,
			"segoe_ui_font/" .. spec.File,
			"fonts/" .. spec.File,
			spec.File,
		}

		local foundPath = nil
		if isFileFn then
			for _, candidate in ipairs(alternatePaths) do
				local okExists, exists = pcall(isFileFn, candidate)
				if okExists and exists then
					foundPath = candidate
					break
				end
			end
		end

		if not foundPath then
			local urlsToTry = {
				baseUrl .. spec.File,
				Theme.FontConfig.FallbackBaseUrl .. spec.File,
			}
			for _, dlUrl in ipairs(urlsToTry) do
				local okHttp, bytes = pcall(function()
					if type(options.HttpGet) == "function" then
						return options.HttpGet(dlUrl)
					end
					return game:HttpGet(dlUrl)
				end)
				if okHttp and type(bytes) == "string" and #bytes > 1024 then
					local okWrite = pcall(writeFileFn, targetPath, bytes)
					if okWrite then
						foundPath = targetPath
						break
					end
				end
			end
		end

		if foundPath then
			local okAsset, assetUrl = pcall(getAssetFn, foundPath)
			if okAsset and type(assetUrl) == "string" and assetUrl ~= "" then
				table.insert(facesList, {
					name = spec.Name,
					weight = spec.Weight,
					style = spec.Style,
					assetId = assetUrl,
				})
			end
		end
	end

	if #facesList == 0 then
		return false, "No Segoe UI .ttf faces could be resolved"
	end

	-- Creates Roblox FontFamily JSON definition
	local faceEntries = {}
	for _, f in ipairs(facesList) do
		table.insert(
			faceEntries,
			string.format(
				'{"name":%q,"weight":%d,"style":%q,"assetId":%q}',
				f.name,
				f.weight,
				f.style,
				f.assetId
			)
		)
	end
	local familyJson = string.format(
		'{"name":%q,"faces":[%s]}',
		Theme.FontConfig.FamilyName,
		table.concat(faceEntries, ",")
	)

	local descriptorPath = options.DescriptorPath or (folder .. "/SegoeUI.json")
	local okWriteJson = pcall(writeFileFn, descriptorPath, familyJson)
	if not okWriteJson then
		return false, "Failed to write SegoeUI.json"
	end

	local okFamAsset, familyAssetId = pcall(getAssetFn, descriptorPath)
	if not okFamAsset or type(familyAssetId) ~= "string" or familyAssetId == "" then
		return false, "Failed to resolve getcustomasset for SegoeUI.json"
	end

	return Theme.SetFontFamily(familyAssetId), familyAssetId
end

return Theme
