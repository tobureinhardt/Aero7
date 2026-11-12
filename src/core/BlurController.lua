--!nonstrict
-- Aero7: core/BlurController - Glass UI DepthOfField blur controller for Aero Glass (DevForum near-plane refraction standard).

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local tableCreate = (table and table.create) or function(count, val)
	local t = {}
	for i = 1, count do
		t[i] = val
	end
	return t
end

local BLUR_SIZE = Vector2.new(10, 10)
local PART_SIZE = 0.01
local PART_TRANSPARENCY = 1 - 1e-7
local START_INTENSITY = 0.25

local currentIntensity = START_INTENSITY
local BLUR_OBJ = nil

local function getOrCreateBlurEffect()
	if not BLUR_OBJ or not BLUR_OBJ.Parent then
		local existing = Lighting:FindFirstChild("AeroGlassDepthOfField")
		if existing and existing:IsA("DepthOfFieldEffect") then
			BLUR_OBJ = existing
		else
			local ok, dof = pcall(function()
				local inst = Instance.new("DepthOfFieldEffect")
				inst.Name = "AeroGlassDepthOfField"
				inst.FarIntensity = 0
				inst.NearIntensity = currentIntensity
				inst.FocusDistance = 0.25
				inst.InFocusRadius = 0
				inst.Parent = Lighting
				return inst
			end)
			if ok and dof then
				BLUR_OBJ = dof
			end
		end
	end
	return BLUR_OBJ
end

local PartsList = {}
local BlursList = {}
local BlurObjects = {}
local BlurredGui = {}

BlurredGui.__index = BlurredGui

local isRenderBound = false
local RENDER_STEP_NAME = "Aero7_GlassBlurUpdate"

local function rayPlaneIntersect(planePos, planeNormal, rayOrigin, rayDirection)
	local n = planeNormal
	local d = rayDirection
	local v = rayOrigin - planePos

	local nx = n.X or n.x or 0
	local ny = n.Y or n.y or 0
	local nz = n.Z or n.z or 0
	local dx = d.X or d.x or 0
	local dy = d.Y or d.y or 0
	local dz = d.Z or d.z or 0
	local vx = v.X or v.x or 0
	local vy = v.Y or v.y or 0
	local vz = v.Z or v.z or 0

	local num = nx * vx + ny * vy + nz * vz
	local den = nx * dx + ny * dy + nz * dz
	if den == 0 then
		return rayOrigin, 0
	end
	local a = -num / den

	return rayOrigin + a * rayDirection, a
end

local function rebuildPartsList()
	PartsList = {}
	BlursList = {}
	for blurObj, part in pairs(BlurObjects) do
		table.insert(PartsList, part)
		table.insert(BlursList, blurObj)
	end
end

local function updateGui(blurObj)
	local frame = blurObj.Frame
	local part = blurObj.Part
	local mesh = blurObj.Mesh

	if not part or not mesh then
		return
	end

	if not blurObj.Visible or not frame or not frame.Visible then
		part.Transparency = 1
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		part.Transparency = 1
		return
	end

	part.Transparency = PART_TRANSPARENCY

	local blurSize = blurObj.BlurSize or BLUR_SIZE
	local corner0 = frame.AbsolutePosition + blurSize
	local corner1 = corner0 + frame.AbsoluteSize - blurSize * 2
	local ray0, ray1

	if blurObj.IgnoreGuiInset then
		ray0 = camera:ViewportPointToRay(corner0.X, corner0.Y, 1)
		ray1 = camera:ViewportPointToRay(corner1.X, corner1.Y, 1)
	else
		ray0 = camera:ScreenPointToRay(corner0.X, corner0.Y, 1)
		ray1 = camera:ScreenPointToRay(corner1.X, corner1.Y, 1)
	end

	if not ray0 or not ray1 then
		return
	end

	local nearZ = camera.NearPlaneZ or 0.1
	local planeOrigin = camera.CFrame.Position + camera.CFrame.LookVector * (0.05 - nearZ)
	local planeNormal = camera.CFrame.LookVector
	local pos0 = rayPlaneIntersect(planeOrigin, planeNormal, ray0.Origin, ray0.Direction)
	local pos1 = rayPlaneIntersect(planeOrigin, planeNormal, ray1.Origin, ray1.Direction)

	pos0 = camera.CFrame:PointToObjectSpace(pos0)
	pos1 = camera.CFrame:PointToObjectSpace(pos1)

	local size = pos1 - pos0
	local center = (pos0 + pos1) / 2

	mesh.Offset = center
	mesh.Scale = size / PART_SIZE
end

function BlurredGui.updateAll()
	if #BlursList == 0 then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local effect = getOrCreateBlurEffect()
	if effect then
		effect.Enabled = true
		effect.NearIntensity = currentIntensity
		local nearZ = camera.NearPlaneZ or 0.1
		effect.FocusDistance = 0.25 - nearZ
	end

	for i = 1, #BlursList do
		updateGui(BlursList[i])
	end

	local cframes = tableCreate(#BlursList, camera.CFrame)
	if workspace.BulkMoveTo then
		workspace:BulkMoveTo(PartsList, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	else
		for _, p in ipairs(PartsList) do
			p.CFrame = camera.CFrame
		end
	end
end

local function ensureRenderBinding()
	if not isRenderBound and RunService.BindToRenderStep then
		isRenderBound = true
		pcall(function()
			RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, function()
				BlurredGui.updateAll()
			end)
		end)
	end
end

local function cleanupRenderBinding()
	if isRenderBound and #BlursList == 0 and RunService.UnbindFromRenderStep then
		isRenderBound = false
		pcall(function()
			RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
		end)
	end
end

function BlurredGui.new(frame, shape, options)
	shape = shape or "Rectangle"
	options = options or {}

	local camera = workspace.CurrentCamera
	local blurPart = Instance.new("Part")
	blurPart.Name = "AeroGlassBlurPart"
	blurPart.Size = Vector3.new(1, 1, 1) * PART_SIZE
	blurPart.Anchored = true
	blurPart.CanCollide = false
	blurPart.CanTouch = false
	blurPart.Material = Enum.Material.Glass
	blurPart.Transparency = PART_TRANSPARENCY
	blurPart.Parent = camera or workspace

	local mesh
	if shape == "Rectangle" then
		mesh = Instance.new("BlockMesh")
		mesh.Parent = blurPart
	elseif shape == "Oval" then
		mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = blurPart
	end

	local ignoreInset = false
	local currentObj = frame

	while currentObj do
		if currentObj:IsA("ScreenGui") then
			ignoreInset = currentObj.IgnoreGuiInset
			break
		end
		currentObj = currentObj.Parent
	end

	local new = setmetatable({
		Frame = frame,
		Part = blurPart,
		Mesh = mesh,
		IgnoreGuiInset = ignoreInset,
		BlurSize = options.BlurSize or BLUR_SIZE,
		Visible = true,
	}, BlurredGui)

	BlurObjects[new] = blurPart
	rebuildPartsList()
	getOrCreateBlurEffect()

	ensureRenderBinding()
	BlurredGui.updateAll()

	return new
end

function BlurredGui:SetVisible(visible)
	self.Visible = (visible ~= false)
	if self.Part then
		if self.Visible and self.Frame and self.Frame.Visible then
			self.Part.Transparency = PART_TRANSPARENCY
		else
			self.Part.Transparency = 1
		end
	end
end

function BlurredGui:Destroy()
	if self.Part then
		self.Part:Destroy()
		self.Part = nil
	end
	BlurObjects[self] = nil
	rebuildPartsList()
	if #BlursList == 0 then
		if BLUR_OBJ then
			BLUR_OBJ.Enabled = false
		end
		cleanupRenderBinding()
	end
end

function BlurredGui.SetIntensity(intensity)
	currentIntensity = tonumber(intensity) or START_INTENSITY
	if BLUR_OBJ then
		BLUR_OBJ.NearIntensity = currentIntensity
	end
end

function BlurredGui.GetIntensity()
	return currentIntensity
end

function BlurredGui.SetEnabled(enabled)
	local isEnabled = (enabled ~= false)
	if BLUR_OBJ then
		BLUR_OBJ.Enabled = isEnabled
	end
	if not isEnabled then
		for _, part in ipairs(PartsList) do
			part.Transparency = 1
		end
	end
end

return BlurredGui
