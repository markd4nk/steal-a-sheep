--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ChaseFeel = require(ReplicatedStorage.Utils.ChaseFeel)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- How a chase feels to the thief, on top of the gods' own sounds (GodController) and the banner (the HUD): an alarm,
-- a red flash and a jolt of zoom on the steal, then one level (Utils/ChaseFeel: how near their god is) drives a
-- heartbeat, the chase music's drums (SoundController), red edges that throb with each beat and colour drained from
-- the world; the god's footfalls shake the view when it's right behind. Caught: the music cut dead, a white flash.
-- Across the safety line: a bright "safe" and everything winding down. Reduce Motion keeps the view still.
local ChaseController = { Name = "ChaseController" }

type Ending = "Caught" | "Escaped" | "Ended"
type Shake = { At: number, Degrees: number, Seconds: number }

local SHAKE_RENDER = "ChaseShake"
local RED = Color3.fromRGB(170, 0, 8)
local WHITE = Color3.new(1, 1, 1)
local WARM = Color3.fromRGB(255, 240, 200)
local EDGE_SHARE = 0.38 -- each edge's red reaches this far across the screen
-- Seconds the look takes to go after each ending (an escape's is GameConfig.Chase.FadeSeconds).
local CAUGHT_FADE = 0.8
local ENDED_FADE = 0.6
local STEP_SHAKE_SECONDS = 0.12
local ROAR_SHAKE_SECONDS = 0.5
local PUNCH_SHAKE_SECONDS = 0.4

local settings = GameConfig.Chase
local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local player = Players.LocalPlayer
local random = Random.new()

local tier: number? = nil -- the chasing god's tier, while a chase is on
local god: Model? = nil
local level = 0
local presence = 0 -- how much of the chase's look is on: 1 in a chase, falling to 0 after it
local ending: Ending? = nil
local endedAt = 0
local nextBeat = math.huge
local lastBeat = -math.huge
local flashColor = RED
local flashStrength = 0
local flashAt = -math.huge
local flashSeconds = 1
local zoomAt = -math.huge
local zoomed = 0 -- degrees taken off the view last frame, given back before this frame's
local shakes: { Shake } = {}

local screen: ScreenGui? = nil
local edges: { Frame } = {}
local flash: Frame? = nil
local grade: ColorCorrectionEffect? = nil

local function findGod(wanted: number): Model?
	local folder = workspace:FindFirstChild("Gods")
	if not folder then
		return nil
	end
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Tier") == wanted then
			return child
		end
	end
	return nil
end

-- Where the level is heading: how near the god is while it runs, the head start's level before.
local function wantedLevel(chasing: number): number
	local model = god
	if not model or not model.Parent then
		model = findGod(chasing)
		god = model
	end
	if not model or model:GetAttribute("Mood") ~= "Run" then
		return settings.HeadStartLevel
	end
	local godRoot = model.PrimaryPart
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not godRoot or not root or not root:IsA("BasePart") then
		return level
	end
	return ChaseFeel.Level((root.Position - godRoot.Position).Magnitude)
end

local function flashScreen(color: Color3, strength: number, seconds: number)
	flashColor, flashStrength, flashAt, flashSeconds = color, strength, os.clock(), seconds
end

local function shake(degrees: number, seconds: number)
	if not PlayerSettings.ReduceMotion() then
		table.insert(shakes, { At = os.clock(), Degrees = degrees, Seconds = seconds })
	end
end

local function begin(chasing: number)
	tier = chasing
	god = findGod(chasing)
	ending = nil
	level = settings.HeadStartLevel
	presence = 1
	nextBeat = os.clock() + 0.3
	local sound = registry.SoundController
	if sound then
		sound:Play("StealAlarm")
		sound:SetDanger(true)
	end
	flashScreen(RED, settings.StealFlash, 0.45)
	shake(settings.RoarShake, ROAR_SHAKE_SECONDS)
	if not PlayerSettings.ReduceMotion() then
		zoomAt = os.clock()
	end
end

local function finish(how: string?)
	if not tier then
		return
	end
	tier = nil
	god = nil
	endedAt = os.clock()
	local sound = registry.SoundController
	if how == "Caught" then
		ending = "Caught"
		nextBeat = math.huge
		if sound then
			sound:SetDanger(false, "Cut")
		end
		flashScreen(WHITE, settings.PunchFlash, 0.3)
		shake(settings.PunchShake, PUNCH_SHAKE_SECONDS)
	elseif how == "Escaped" then
		ending = "Escaped"
		if sound then
			sound:SetDanger(false, "Quick")
			sound:Play("ChaseSafe")
		end
		flashScreen(WARM, settings.SafeFlash, 0.5)
	else
		ending = "Ended"
		nextBeat = math.huge
		if sound then
			sound:SetDanger(false)
		end
	end
end

local function update(dt: number)
	local now = os.clock()
	local chasing = tier
	if chasing then
		level += (wantedLevel(chasing) - level) * (1 - math.exp(-settings.Smoothing * dt))
	elseif ending then
		local seconds = if ending == "Caught"
			then CAUGHT_FADE
			elseif ending == "Escaped" then settings.FadeSeconds
			else ENDED_FADE
		local t = math.clamp((now - endedAt) / seconds, 0, 1)
		presence = 1 - t
		if ending == "Escaped" then
			level = math.max(0, level - dt / seconds)
		end
		if t >= 1 then
			ending = nil
			nextBeat = math.huge
			level = 0
		end
	end
	local sound = registry.SoundController
	if sound and chasing then
		sound:SetDangerLevel(level)
	end
	if now >= nextBeat then
		local speed, volume = ChaseFeel.Beat(level)
		if sound then
			sound:Play("Heartbeat", speed, volume * presence)
		end
		lastBeat = now
		nextBeat = now + ChaseFeel.BeatSeconds(level)
	end

	local edgeAlpha = if presence > 0 then ChaseFeel.Edges(level, now - lastBeat) * presence else 0
	for _, edge in edges do
		edge.BackgroundTransparency = 1 - edgeAlpha
	end
	local flashing = false
	local overlay = flash
	if overlay then
		local t = (now - flashAt) / flashSeconds
		flashing = t >= 0 and t < 1
		overlay.Visible = flashing
		if flashing then
			overlay.BackgroundColor3 = flashColor
			overlay.BackgroundTransparency = 1 - flashStrength * (1 - t)
		end
	end
	if screen then
		screen.Enabled = edgeAlpha > 0 or flashing
	end
	local drained = level * presence
	if grade then
		grade.Enabled = drained > 0.001
		grade.Saturation = -settings.Drain * drained
		local keep = 1 - settings.Tint * drained
		grade.TintColor = Color3.new(1, keep, keep)
	end
end

-- After the camera has moved: the steal's zoom and the shakes, on top of where it put the view.
local function moveView()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if zoomed ~= 0 then
		camera.FieldOfView += zoomed
		zoomed = 0
	end
	if PlayerSettings.ReduceMotion() then
		table.clear(shakes)
		return
	end
	local now = os.clock()
	local t = (now - zoomAt) / settings.ZoomSeconds
	if t >= 0 and t < 1 then
		zoomed = settings.StealZoom * (1 - t)
		camera.FieldOfView -= zoomed
	end
	local degrees = 0
	for index = #shakes, 1, -1 do
		local one = shakes[index]
		local s = (now - one.At) / one.Seconds
		if s >= 1 then
			table.remove(shakes, index)
		else
			degrees = math.max(degrees, one.Degrees * (1 - s))
		end
	end
	if degrees > 0 then
		local r = math.rad(degrees)
		camera.CFrame *= CFrame.Angles(random:NextNumber(-r, r), random:NextNumber(-r, r), 0)
	end
end

local function edge(parent: Instance, name: string, size: UDim2, anchor: Vector2, rotation: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = RED
	frame.BackgroundTransparency = 1
	frame.Size = size
	frame.AnchorPoint = anchor
	frame.Position = UDim2.fromScale(anchor.X, anchor.Y)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.45, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = frame
	frame.Parent = parent
	return frame
end

-- Under every other screen (the HUD's DisplayOrder is 0): the red edges and the flashes.
local function build(playerGui: Instance)
	local gui = Instance.new("ScreenGui")
	gui.Name = "ChaseScreen"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.DisplayOrder = -1
	gui.Enabled = false
	edges = {
		edge(gui, "Top", UDim2.fromScale(1, EDGE_SHARE), Vector2.new(0, 0), 90),
		edge(gui, "Bottom", UDim2.fromScale(1, EDGE_SHARE), Vector2.new(0, 1), 270),
		edge(gui, "Left", UDim2.fromScale(EDGE_SHARE, 1), Vector2.new(0, 0), 0),
		edge(gui, "Right", UDim2.fromScale(EDGE_SHARE, 1), Vector2.new(1, 0), 180),
	}
	local overlay = Instance.new("Frame")
	overlay.Name = "Flash"
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Visible = false
	overlay.Parent = gui
	flash = overlay
	gui.Parent = playerGui
	screen = gui
	trove:Add(gui)
end

function ChaseController.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function ChaseController.Start(_self: any)
	local created = Instance.new("ColorCorrectionEffect")
	created.Name = "ChaseGrade"
	created.Enabled = false
	created.Parent = Lighting
	grade = created
	trove:Add(created)
	task.spawn(function()
		build(player:WaitForChild("PlayerGui"))
	end)
	trove:Add(Remotes.Chase:Connect(function(name: string?, chasing: number?, how: string?)
		if name and chasing then
			begin(chasing)
		else
			finish(how)
		end
	end))
	local gods = registry.GodController
	if gods then
		trove:Add(gods.Stepped:Connect(function(_model: Model, stepTier: number)
			if stepTier == tier and level >= settings.ShakeFrom then
				shake(settings.StepShake, STEP_SHAKE_SECONDS)
			end
		end))
	end
	trove:Connect(RunService.Heartbeat, update)
	RunService:BindToRenderStep(SHAKE_RENDER, Enum.RenderPriority.Camera.Value + 1, moveView)
	trove:Add(function()
		RunService:UnbindFromRenderStep(SHAKE_RENDER)
	end)
end

function ChaseController.Destroy(_self: any)
	trove:Clean()
	table.clear(edges)
	table.clear(shakes)
end

return ChaseController
