--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Path = require(script.Path)

-- Films trailer shots in Studio playtests (BRAIN/PATTERNS/trailers.md; the OBS and ffmpeg half is in trailer/). Off
-- until a game adds it to the client Registry, and it does nothing outside Studio. MCP execute_luau calls drive it
-- through a local BindableFunction, ReplicatedStorage.TrailerRig, because those calls run with their own copies of
-- every module. Studio's Assistant puts the camera type back when it changes during a call, so the camera only turns
-- Scriptable a moment after the call returns. From a Client call:
--   local rig = game:GetService("ReplicatedStorage").TrailerRig
--   rig:Invoke("Play", { Seconds = 6, Follow = "Character", Offset = Vector3.new(0, 4, 12), OffsetTo = Vector3.new(0, 8, 20) })
--   rig:Invoke("Stop")

-- What a shot frames: an instance (a model, part or attachment), a point in the shot's space, or "Character" (this
-- player's).
type Target = Instance | string | Vector3

-- A frame the shot's points are given in: a CFrame, or an instance's pivot (a player's base, so one shot works on
-- any base). The world when left out.
type Space = Instance | CFrame

type Key = { Pos: Vector3, Look: Vector3? }

type Orbit = {
	Center: Target?, -- defaults to the shot's Follow
	Radius: number,
	RadiusTo: number?,
	Height: number,
	HeightTo: number?,
	From: number, -- degrees round the centre, 0 along the space's +Z
	To: number,
	LookHeight: number?,
}

type Dof = { Radius: number?, Near: number?, Far: number? }

type Shot = {
	Seconds: number,
	Delay: number?, -- holds the first frame this long before moving, so a take can start a little early
	Space: Space?,
	Ease: string?, -- "Linear", "In", "Out", or smootherstep when left out
	Keys: { Key }?, -- a glide: the camera's path, and optionally where it looks along the way
	Follow: Target?,
	Offset: Vector3?, -- the camera from Follow...
	OffsetTo: Vector3?, -- ...moving to here over the shot
	OffsetSpace: string?, -- "Facing" (the target's heading, default), "Space" or "World"
	LookAt: Target?, -- what the camera looks at, instead of the keys' Look or the Follow target
	LookOffset: Vector3?,
	Smooth: number?, -- seconds of lag when following a moving target
	Orbit: Orbit?,
	Fov: number?,
	FovTo: number?,
	Roll: number?, -- degrees
	Shake: number?, -- studs of slow handheld drift
	Dof: Dof?,
	Hud: boolean?, -- true keeps the game's screens up
	HideGuis: { string }?, -- screens to switch off anyway when Hud is true
	HideCharacter: boolean?,
	Clear: { string }?, -- tags of models (a crowd) that fade out while they stand between the camera and the subject
}

type Run = {
	Shot: Shot,
	Started: number,
	Space: CFrame,
	EyePath: Path.Built?,
	LookPath: Path.Built?,
	Eye: Vector3?,
	Look: Vector3?,
	Seed: number,
}

local RENDER_STEP = "Trailer"
local RIG_NAME = "TrailerRig"
local DEFAULT_FOV = 70
local DEFAULT_SMOOTH = 0.25
local FOLLOW_HEIGHT = Vector3.new(0, 1.5, 0) -- a character's eyes over its root, where a follow shot looks
-- Clear: studs of a crowd model's own size, and how much nearer than the subject it must be to fade, so models right
-- beside the subject stay in the picture.
local FADE_PAD = 1.8
local FADE_GAP = 2
local FADE_MIDDLE = Vector3.new(0, 1.2, 0)

local TrailerController = { Name = "TrailerController" }

local trove = Trove.new()
local player = Players.LocalPlayer
local current: Run? = nil
local characterHidden = false
local walkToken = 0
local dof: DepthOfFieldEffect? = nil
local hiddenGuis: { ScreenGui } = {}
local hudHidden = false
local faded: { [Model]: boolean } = {}

local function frameOf(space: Space?): CFrame
	if space == nil then
		return CFrame.identity
	elseif typeof(space) == "CFrame" then
		return space
	elseif typeof(space) == "Instance" then
		if space:IsA("Model") then
			return space:GetPivot()
		elseif space:IsA("BasePart") then
			return space.CFrame
		end
	end
	return CFrame.identity
end

local function resolve(target: Target?, space: CFrame): CFrame?
	if target == nil then
		return nil
	elseif typeof(target) == "Vector3" then
		return space * CFrame.new(target)
	elseif target == "Character" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return if root and root:IsA("BasePart") then root.CFrame else nil
	elseif typeof(target) == "Instance" then
		if target:IsA("Model") then
			return target:GetPivot()
		elseif target:IsA("BasePart") then
			return target.CFrame
		elseif target:IsA("Attachment") then
			return target.WorldCFrame
		end
	end
	return nil
end

local function heading(frame: CFrame): CFrame
	local look = frame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 1e-3 then
		return CFrame.identity
	end
	return CFrame.lookAt(Vector3.zero, look.Unit)
end

local function offsetAxes(shot: Shot, space: CFrame, followFrame: CFrame): CFrame
	if shot.OffsetSpace == "World" then
		return CFrame.identity
	elseif shot.OffsetSpace == "Space" then
		return space.Rotation
	end
	return heading(followFrame)
end

local function smoothed(from: Vector3?, to: Vector3, dt: number, lag: number): Vector3
	if not from or lag <= 0 then
		return to
	end
	return from:Lerp(to, 1 - math.exp(-dt / lag))
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function setTransparent(model: Instance, hidden: boolean)
	local amount = if hidden then 1 else 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = amount
		elseif part:IsA("Decal") then
			part.LocalTransparencyModifier = amount
		end
	end
end

local function setCharacterHidden(hidden: boolean)
	characterHidden = hidden
	local character = player.Character
	if character then
		setTransparent(character, hidden)
	end
end

local function restoreGuis()
	for _, gui in hiddenGuis do
		if gui.Parent then
			gui.Enabled = true
		end
	end
	table.clear(hiddenGuis)
end

-- The game's screens step aside for a shot (all of them, or only `names` and the debug panel when the HUD stays up).
local function hideGuis(all: boolean, names: { string }?)
	restoreGuis()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end
	for _, gui in playerGui:GetChildren() do
		local listed = gui.Name == "DebugPanel" or (names ~= nil and table.find(names, gui.Name) ~= nil)
		if gui:IsA("ScreenGui") and gui.Enabled and (all or listed) then
			gui.Enabled = false
			table.insert(hiddenGuis, gui)
		end
	end
end

local function setHud(shown: boolean, names: { string }?)
	hudHidden = not shown
	hideGuis(not shown, names)
	ProximityPromptService.Enabled = shown
	UserInputService.MouseIconEnabled = shown
end

-- Roblox's own screens (the player list, chat) stay off for every shot, the HUD ones included. Its menu buttons in
-- the top-left corner can't be hidden: crop them out of the footage.
local function setCoreGuis(shown: boolean)
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.All, shown)
end

local function unfadeAll()
	for model in faded do
		if model.Parent then
			setTransparent(model, false)
		end
	end
	table.clear(faded)
end

-- Whether a point stands between the camera and its subject `depth` studs ahead: in view, and nearer than the subject
-- by more than FADE_GAP.
local function obstructs(view: CFrame, fov: number, aspect: number, depth: number, point: Vector3): boolean
	local here = view:PointToObjectSpace(point)
	local ahead = -here.Z
	if ahead < -FADE_PAD or ahead > depth - FADE_GAP then
		return false
	end
	local halfHeight = math.tan(math.rad(fov / 2)) * math.max(ahead, 0)
	return math.abs(here.Y) < halfHeight + FADE_PAD and math.abs(here.X) < halfHeight * aspect + FADE_PAD
end

local function clearView(shot: Shot, tags: { string }, camera: Camera, look: Vector3)
	local keep: { [Instance]: boolean } = {}
	for _, target in { shot.Follow, shot.LookAt, shot.Orbit and shot.Orbit.Center } do
		if typeof(target) == "Instance" then
			keep[target] = true
		end
	end
	local view = camera.CFrame
	local size = camera.ViewportSize
	local aspect = if size.Y > 0 then size.X / size.Y else 16 / 9
	local depth = (look - view.Position).Magnitude
	for _, tag in tags do
		for _, model in CollectionService:GetTagged(tag) do
			if model:IsA("Model") and not keep[model] then
				local near = obstructs(view, camera.FieldOfView, aspect, depth, model:GetPivot().Position + FADE_MIDDLE)
				if near ~= (faded[model] == true) then
					if near then
						faded[model] = true
					else
						faded[model] = nil
					end
					setTransparent(model, near)
				end
			end
		end
	end
end

local function ensureDof(): DepthOfFieldEffect
	local effect = dof
	if effect and effect.Parent then
		return effect
	end
	local created = Instance.new("DepthOfFieldEffect")
	created.Name = "TrailerDof"
	created.Enabled = false
	created.Parent = Lighting
	dof = created
	return created
end

local function step(dt: number)
	local run = current
	local camera = workspace.CurrentCamera
	if not run or not camera then
		return
	end
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end
	local shot = run.Shot
	local space = run.Space
	local elapsed = os.clock() - run.Started - (shot.Delay or 0)
	local t = Path.Ease(elapsed / math.max(shot.Seconds, 1e-3), shot.Ease)
	local lag = shot.Smooth or DEFAULT_SMOOTH
	local followFrame = resolve(shot.Follow, space)

	local eye: Vector3? = nil
	local look: Vector3? = nil
	local orbit = shot.Orbit
	if orbit then
		local centerFrame = resolve(orbit.Center, space) or followFrame
		if centerFrame then
			local center = centerFrame.Position
			local angle = math.rad(lerp(orbit.From, orbit.To, t))
			local around = space.Rotation * Vector3.new(math.sin(angle), 0, math.cos(angle))
			local radius = lerp(orbit.Radius, orbit.RadiusTo or orbit.Radius, t)
			local height = lerp(orbit.Height, orbit.HeightTo or orbit.Height, t)
			local target = center + around * radius + Vector3.new(0, height, 0)
			eye = smoothed(run.Eye, target, dt, if orbit.Center then 0 else lag)
			look = center + Vector3.new(0, orbit.LookHeight or 0, 0)
		end
	elseif followFrame and shot.Offset then
		local offset = shot.Offset:Lerp(shot.OffsetTo or shot.Offset, t)
		eye = smoothed(run.Eye, followFrame.Position + offsetAxes(shot, space, followFrame) * offset, dt, lag)
	elseif run.EyePath then
		eye = Path.At(run.EyePath, t)
	end

	local lookFrame = resolve(shot.LookAt, space)
	local lookOffset = shot.LookOffset or Vector3.zero
	if lookFrame then
		look = smoothed(run.Look, lookFrame.Position + lookOffset, dt, lag)
	elseif look == nil and run.LookPath then
		look = Path.At(run.LookPath, t)
	elseif look == nil and followFrame then
		-- Turned with the camera's offset, so "ahead" stays ahead of whoever it follows.
		local ahead = offsetAxes(shot, space, followFrame) * lookOffset
		look = smoothed(run.Look, followFrame.Position + FOLLOW_HEIGHT + ahead, dt, lag)
	end
	if not eye or not look then
		return
	end
	run.Eye = eye
	run.Look = look

	local shake = shot.Shake
	local drift = Vector3.zero
	if shake and shake > 0 then
		local clock = os.clock() * 0.6
		drift = Vector3.new(
			math.noise(clock, run.Seed, 0),
			math.noise(run.Seed, clock, 0) * 0.6,
			math.noise(0, run.Seed, clock)
		) * shake
	end
	local frame = CFrame.lookAt(eye + drift, look)
	if shot.Roll then
		frame *= CFrame.Angles(0, 0, math.rad(shot.Roll))
	end
	camera.CFrame = frame
	camera.Focus = CFrame.new(look)
	local fov = shot.Fov or DEFAULT_FOV
	camera.FieldOfView = lerp(fov, shot.FovTo or fov, t)

	local effect = dof
	if effect then
		effect.FocusDistance = (look - eye).Magnitude
	end
	if characterHidden then
		setCharacterHidden(true)
	end
	local clear = shot.Clear
	if clear then
		clearView(shot, clear, camera, look)
	end
end

local function stop()
	current = nil
	RunService:UnbindFromRenderStep(RENDER_STEP)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = DEFAULT_FOV
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
	if dof then
		dof.Enabled = false
	end
	setCharacterHidden(false)
	unfadeAll()
	restoreGuis()
	if hudHidden then
		hudHidden = false
		ProximityPromptService.Enabled = true
		UserInputService.MouseIconEnabled = true
	end
	setCoreGuis(true)
end

local function play(shot: Shot): number
	local space = frameOf(shot.Space)
	local run: Run = {
		Shot = shot,
		Started = os.clock(),
		Space = space,
		EyePath = nil,
		LookPath = nil,
		Eye = nil,
		Look = nil,
		Seed = math.random() * 100,
	}
	local keys = shot.Keys
	if keys and #keys > 0 then
		local eyes: { Vector3 } = {}
		local looks: { Vector3 } = {}
		for _, key in keys do
			table.insert(eyes, space:PointToWorldSpace(key.Pos))
			if key.Look then
				table.insert(looks, space:PointToWorldSpace(key.Look))
			end
		end
		run.EyePath = Path.Build(eyes)
		if #looks > 0 then
			run.LookPath = Path.Build(looks)
		end
	end
	unfadeAll()
	setHud(shot.Hud == true, shot.HideGuis)
	setCoreGuis(false)
	setCharacterHidden(shot.HideCharacter == true)
	local settings = shot.Dof
	if settings then
		local effect = ensureDof()
		effect.InFocusRadius = settings.Radius or 6
		effect.NearIntensity = settings.Near or 0.25
		effect.FarIntensity = settings.Far or 0.35
		effect.Enabled = true
	elseif dof then
		dof.Enabled = false
	end
	current = run
	-- After the execute_luau call that sent the shot has returned (see the header).
	task.delay(0.1, function()
		if current == run then
			RunService:UnbindFromRenderStep(RENDER_STEP)
			RunService:BindToRenderStep(RENDER_STEP, Enum.RenderPriority.Camera.Value + 1, step)
		end
	end)
	return (shot.Delay or 0) + shot.Seconds
end

-- Walks this player's character through points (in `space`), one after another, for shots of the game's verb.
local function walk(points: { Vector3 }, space: Space?, speed: number?)
	walkToken += 1
	local token = walkToken
	local frame = frameOf(space)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if speed then
		humanoid.WalkSpeed = speed
	end
	task.spawn(function()
		for _, point in points do
			if token ~= walkToken or humanoid.Health <= 0 then
				return
			end
			humanoid:MoveTo(frame:PointToWorldSpace(point))
			humanoid.MoveToFinished:Wait()
		end
	end)
end

local function place(point: Vector3, facing: Vector3?, space: Space?)
	local frame = frameOf(space)
	local character = player.Character
	if not character then
		return
	end
	local at = frame:PointToWorldSpace(point)
	local toward = if facing then frame:PointToWorldSpace(facing) else at + frame.LookVector
	character:PivotTo(CFrame.lookAt(at, Vector3.new(toward.X, at.Y, toward.Z)))
end

local function handle(command: string, a: any, b: any, c: any): any
	if command == "Play" then
		return play(a)
	elseif command == "Stop" then
		stop()
	elseif command == "Hud" then
		setHud(a == true, nil)
	elseif command == "Walk" then
		walk(a, b, c)
	elseif command == "StopWalk" then
		walkToken += 1
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and root and root:IsA("BasePart") then
			humanoid:MoveTo(root.Position)
		end
	elseif command == "Place" then
		place(a, b, c)
	elseif command == "Fade" then
		-- Models with tag b near a point ({ Point, Radius, Undo? } in space c) turn invisible for this player, for a
		-- clear line to the subject.
		local center = frameOf(c):PointToWorldSpace(a.Point)
		for _, model in CollectionService:GetTagged(b) do
			if model:IsA("Model") then
				local near = (model:GetPivot().Position - center).Magnitude < a.Radius
				setTransparent(model, near and not a.Undo)
			end
		end
	else
		error(`unknown trailer command {command}`)
	end
	return true
end

function TrailerController.Init(_self: any, _systems: Lifecycle.Registry) end

function TrailerController.Start(_self: any)
	if not RunService:IsStudio() then
		return
	end
	local rig = Instance.new("BindableFunction")
	rig.Name = RIG_NAME
	rig.OnInvoke = handle
	rig.Parent = ReplicatedStorage
	trove:Add(rig)
	trove:Connect(player.CharacterRemoving, function()
		if current then
			stop()
		end
	end)
end

function TrailerController.Destroy(_self: any)
	if current then
		stop()
	end
	if dof then
		dof:Destroy()
	end
	trove:Clean()
end

return TrailerController
