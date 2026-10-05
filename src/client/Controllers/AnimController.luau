--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local SheepClips = require(ReplicatedStorage.Utils.SheepClips)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Wander = require(ReplicatedStorage.Utils.Wander)

-- Presentation on this device only. The sheep in the pens walk where the server sends them (their Spot and WalkAt
-- attributes, Utils/Wander) and hop down off their thief's head when put down (DropFrom, DroppedAt). The nearest come
-- to life: lambs graze nearly all the time (head down to the grass, nibbling, then up to chew with a chewing face),
-- grown sheep now and then; between times they breathe, look about, wag and blink (Utils/SheepClips), and baa now and
-- then. A carried lamb sways on its thief's head. The gods swing their limbs as they run, shake their arms when
-- alerted and hop when they catch someone. Offsets go onto the joints in PreSimulation and come off in PostSimulation,
-- so nothing piles up.
local AnimController = { Name = "AnimController" }

-- A sheep put down: an arc from where it was held to its spot.
type Hop = {
	From: CFrame,
	Start: number,
	Duration: number,
	Height: number,
}

type Grazing = {
	Bout: SheepClips.Bout,
	Start: number,
	Length: number,
	StoppedAt: number?, -- cut short (it set off walking): fading out from here
}

type Rigged = {
	Model: Model,
	Joints: { [string]: Motor6D },
	Seed: number,
	-- In a pen (the model has a Spot): where this device shows it and how it gets there.
	Penned: boolean,
	Spot: CFrame?,
	At: CFrame?, -- where this device last put it
	Walk: Wander.Walk?, -- the stroll it's on, on os.clock()
	Hop: Hop?,
	Stride: number, -- walk cycles so far, so the legs keep in step with the ground
	Pace: number, -- 0 to 1: how much its legs walk, eased in and out
	Grazing: Grazing?,
	NextAction: number, -- os.clock() it next starts grazing or decides not to
	HappyAt: number, -- os.clock() it lands from a hop: a happy hop and face from then
	BaaUntil: number,
	Face: Decal?,
	OwnFace: string, -- its breed's own picture, put back whenever it isn't making a face
	FaceShown: string?,
	BlinkAt: number,
	Connections: { RBXScriptConnection },
}

local PICK_EVERY = 0.25
local GOD_RANGE = 220
local SHEEP_TAG = "Sheep"
local PACE_EASE = 6 -- per second, how fast the legs blend into and out of walking
local GRAZE_FADE = 0.35 -- seconds a cut-short bout takes to stand up
local HAPPY_HOP = SheepClips.Get("HappyHop")
local Settings = GameConfig.SheepMotion
local Pictures = GameConfig.Sheep.Faces
local rad = math.rad

local trove = Trove.new()
local random = Random.new()
local sheep: { [Model]: Rigged } = {}
local gods: { [Model]: Rigged } = {}
local animated: { Rigged } = {}
local isAnimated: { [Rigged]: boolean } = {}
local animatedGods: { Rigged } = {}
local touched: { Motor6D } = {}
local befores: { CFrame } = {}
local sincePick = math.huge
local nextBaa = 0

local function smooth(x: number): number
	local t = math.clamp(x, 0, 1)
	return t * t * (3 - 2 * t)
end

local function between(range: { number }): number
	return random:NextNumber(range[1], range[2])
end

local function move(entry: Rigged, at: CFrame)
	entry.At = at
	entry.Model:PivotTo(at)
end

-- Whether two placements are the same to the eye (CFrames that went through PivotTo never compare equal).
local function same(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 0.01 and a.LookVector:Dot(b.LookVector) > 0.99999
end

-- A new stroll (WalkAt set: walk there from wherever this device shows it, caught up by however long the news took
-- to arrive), or a new spot without one (jump there).
local function spotChanged(entry: Rigged)
	local spot = entry.Model:GetAttribute("Spot")
	if typeof(spot) ~= "CFrame" then
		return
	end
	entry.Spot = spot
	if entry.Hop then
		-- Still hopping in: it lands on the new spot.
		return
	end
	local clock = os.clock()
	local walkAt = entry.Model:GetAttribute("WalkAt")
	local from = entry.At or entry.Model:GetPivot()
	local walk = if typeof(walkAt) == "number"
		then Wander.Plan(from, spot, clock - math.max(0, workspace:GetServerTimeNow() - walkAt))
		else nil
	if walk and clock < Wander.Ends(walk) then
		entry.Walk = walk
		local grazing = entry.Grazing
		if grazing and not grazing.StoppedAt then
			grazing.StoppedAt = clock
		end
	else
		entry.Walk = nil
		move(entry, spot)
	end
end

local function rig(model: Model): Rigged
	local joints: { [string]: Motor6D } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Motor6D") then
			joints[descendant.Name] = descendant
		end
	end
	local head = model:FindFirstChild("Head")
	local decal = head and head:FindFirstChild("Face")
	local face = if decal and decal:IsA("Decal") then decal else nil
	local clock = os.clock()
	return {
		Model = model,
		Joints = joints,
		Seed = random:NextNumber(0, 100),
		Penned = false,
		Spot = nil,
		At = nil,
		Walk = nil,
		Hop = nil,
		Stride = random:NextNumber(),
		Pace = 0,
		Grazing = nil,
		-- Lambs start grazing soon after they come into view; grown sheep stand about first.
		NextAction = clock + random:NextNumber(0, 3),
		HappyAt = -math.huge,
		BaaUntil = 0,
		Face = face,
		OwnFace = if face then face.Texture else "",
		FaceShown = nil,
		BlinkAt = clock + between(Settings.BlinkEvery),
		Connections = {},
	}
end

local function forget(model: Model)
	local entry = sheep[model]
	if not entry then
		return
	end
	sheep[model] = nil
	for _, connection in entry.Connections do
		connection:Disconnect()
	end
end

local function addSheep(instance: Instance)
	if not instance:IsA("Model") or not instance:IsDescendantOf(workspace) or sheep[instance] then
		return
	end
	local entry = rig(instance)
	sheep[instance] = entry
	local spot = instance:GetAttribute("Spot")
	if typeof(spot) ~= "CFrame" then
		return
	end
	entry.Penned = true
	entry.Spot = spot
	local from = instance:GetAttribute("DropFrom")
	local droppedAt = instance:GetAttribute("DroppedAt")
	local hop = Settings.DropHop
	local late = if typeof(droppedAt) == "number" then workspace:GetServerTimeNow() - droppedAt else math.huge
	if typeof(from) == "CFrame" and late < hop.Seconds then
		-- Just put down: from its thief's head (or above its spot) to the ground, then happy to be home.
		local clock = os.clock()
		entry.Hop = { From = from, Start = clock - math.max(late, 0), Duration = hop.Seconds, Height = hop.Height }
		entry.HappyAt = clock - math.max(late, 0) + hop.Seconds
		entry.NextAction = entry.HappyAt + Settings.HappySeconds
		move(entry, from)
	else
		spotChanged(entry)
	end
	table.insert(
		entry.Connections,
		instance:GetAttributeChangedSignal("Spot"):Connect(function()
			spotChanged(entry)
		end)
	)
end

-- Every penned sheep, near or far, goes where it should be on this device: along its hop or stroll, or on its spot
-- (again, if the server moved the model meanwhile).
local function place(entry: Rigged, clock: number, dt: number)
	local hop = entry.Hop
	local spot = entry.Spot
	if not spot then
		return
	end
	local target: CFrame
	local walking = false
	if hop then
		local t = math.clamp((clock - hop.Start) / hop.Duration, 0, 1)
		if t >= 1 then
			entry.Hop = nil
			target = spot
		else
			local position = hop.From.Position:Lerp(spot.Position, t) + Vector3.new(0, hop.Height * 4 * t * (1 - t), 0)
			target = CFrame.new(position) * hop.From.Rotation:Lerp(spot.Rotation, smooth(t))
		end
	elseif entry.Walk then
		local pose, done = Wander.PoseAt(entry.Walk :: Wander.Walk, clock)
		target = pose
		walking = not done
		if done then
			entry.Walk = nil
		end
	else
		target = spot
	end
	local before = entry.At
	if not before or not same(before, target) or not same(entry.Model:GetPivot(), target) then
		if before and walking then
			local scale = entry.Model:GetScale()
			local travelled = Vector3.new(target.X - before.X, 0, target.Z - before.Z).Magnitude
			entry.Stride += travelled / (2 * Settings.StrideStuds * scale)
		end
		move(entry, target)
	end
	local wanted = if walking then 1 else 0
	entry.Pace += math.clamp(wanted - entry.Pace, -PACE_EASE * dt, PACE_EASE * dt)
end

local function pick()
	for _, entry in animated do
		isAnimated[entry] = nil
	end
	local wasAnimated = table.clone(animated)
	table.clear(animated)
	table.clear(animatedGods)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local near: { { Rigged | number } } = {}
	for model, entry in sheep do
		if not model.Parent then
			forget(model)
			continue
		end
		local distance = (model:GetPivot().Position - eye).Magnitude
		if distance <= Settings.AnimationRange then
			table.insert(near, { entry, distance })
		end
	end
	table.sort(near, function(a, b)
		return (a[2] :: number) < (b[2] :: number)
	end)
	for index = 1, math.min(#near, Settings.MaxAnimatedSheep) do
		local entry = near[index][1] :: Rigged
		table.insert(animated, entry)
		isAnimated[entry] = true
	end
	-- Sheep that stopped animating show their own face again.
	for _, entry in wasAnimated do
		if not isAnimated[entry] and entry.Face and entry.FaceShown then
			entry.Face.Texture = entry.OwnFace
			entry.FaceShown = nil
		end
	end
	for model, entry in gods do
		if not model.Parent then
			gods[model] = nil
		elseif (model:GetPivot().Position - eye).Magnitude <= GOD_RANGE then
			table.insert(animatedGods, entry)
		end
	end
end

local function set(joint: Motor6D?, offset: CFrame)
	if not joint then
		return
	end
	local before = joint.Transform
	table.insert(touched, joint)
	table.insert(befores, before)
	joint.Transform = before * offset
end

local function baa()
	local now = os.clock()
	if now < nextBaa or #animated == 0 then
		return
	end
	local range = GameConfig.SheepMotion.BaaEvery
	nextBaa = now + random:NextNumber(range[1], range[2])
	local entry = animated[random:NextInteger(1, #animated)]
	local root = entry.Model.PrimaryPart
	if not root then
		return
	end
	entry.BaaUntil = now + 0.5
	local sounds = GameConfig.SheepMotion.BaaSounds
	local sound = Instance.new("Sound")
	sound.SoundId = sounds[random:NextInteger(1, #sounds)]
	sound.Volume = GameConfig.SheepMotion.BaaVolume * 4
	sound.RollOffMaxDistance = GameConfig.SheepMotion.BaaHearing
	sound.PlaybackSpeed = random:NextNumber(0.94, 1.06)
	sound.Parent = root
	sound:Play()
	task.delay(4, function()
		sound:Destroy()
	end)
end

-- Starts a grazing bout when it's time (lambs nearly always, grown sheep now and then), and ends finished ones.
local function decide(entry: Rigged, clock: number)
	local lamb = entry.Model:GetAttribute("Lamb") == true
	local grazing = entry.Grazing
	if grazing then
		local over = if grazing.StoppedAt
			then clock - grazing.StoppedAt >= GRAZE_FADE
			else clock - grazing.Start >= grazing.Length
		if over then
			entry.Grazing = nil
			entry.NextAction = clock + between(if lamb then Settings.LambPause else Settings.AdultPause)
		end
		return
	end
	if clock < entry.NextAction or entry.Walk or entry.Hop then
		return
	end
	local chance = if lamb then Settings.LambGrazeChance else Settings.AdultGrazeChance
	if random:NextNumber() < chance then
		local bout: SheepClips.Bout = {
			Bite = between(Settings.BiteSeconds),
			Chew = between(Settings.ChewSeconds),
			Count = random:NextInteger(Settings.BitesPerBout[1], Settings.BitesPerBout[2]),
		}
		entry.Grazing = { Bout = bout, Start = clock, Length = SheepClips.GrazeLength(bout), StoppedAt = nil }
	else
		entry.NextAction = clock + between(if lamb then Settings.LambPause else Settings.AdultPause)
	end
end

-- The face it should show: Happy just after landing, Baa while it baas, chewing faces while it chews, a blink now
-- and then on a plain face, else its own.
local function faceFor(entry: Rigged, clock: number, stage: string?): string?
	if clock >= entry.HappyAt and clock < entry.HappyAt + Settings.HappySeconds then
		return "Happy"
	elseif clock < entry.BaaUntil then
		return "Baa"
	elseif stage == "Chew" then
		local faces = GameConfig.Sheep.ChewFaces
		return faces[1 + math.floor(clock / Settings.ChewFrameSeconds) % #faces]
	end
	if entry.OwnFace == Pictures.Idle and clock >= entry.BlinkAt then
		if clock < entry.BlinkAt + Settings.BlinkSeconds then
			return "Blink"
		end
		entry.BlinkAt = clock + between(Settings.BlinkEvery)
	end
	return nil
end

local function showFace(entry: Rigged, face: string?)
	local decal = entry.Face
	if not decal or face == entry.FaceShown then
		return
	end
	entry.FaceShown = face
	decal.Texture = if face then Pictures[face] or entry.OwnFace else entry.OwnFace
end

local function animateSheep(entry: Rigged, clock: number, pose: SheepClips.Pose)
	local model = entry.Model
	if model:GetAttribute("State") == "Carried" then
		local root = model.PrimaryPart
		if root then
			SheepClips.Carried(clock + entry.Seed, root.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity), pose)
		end
		entry.Grazing = nil
		showFace(entry, nil)
		return
	end
	decide(entry, clock)
	local scale = model:GetScale()
	local level = 0
	local stage: string? = nil
	local grazing = entry.Grazing
	if grazing then
		local t = clock - grazing.Start
		local stopped = grazing.StoppedAt
		local weight = if stopped then 1 - smooth((clock - stopped) / GRAZE_FADE) else 1
		local down, doing = SheepClips.GrazeStage(grazing.Bout, t)
		stage = if stopped then nil else doing
		-- The idle makes way as the head goes down; it's laid first, so the bout goes on top.
		SheepClips.Idle(clock, entry.Seed, (1 - math.min(down * weight / 0.3, 1)) * (1 - entry.Pace), pose)
		level = SheepClips.Graze(grazing.Bout, t, weight, pose)
	else
		SheepClips.Idle(clock, entry.Seed, 1 - entry.Pace, pose)
	end
	SheepClips.Walk(entry.Stride, entry.Pace, scale, pose)
	local landed = clock - entry.HappyAt
	if HAPPY_HOP and landed >= 0 and landed < HAPPY_HOP.Length and level <= 0 then
		HAPPY_HOP.Sample(landed, pose)
	end
	showFace(entry, faceFor(entry, clock, stage))
end

local function apply(dt: number)
	sincePick += dt
	if sincePick >= PICK_EVERY then
		sincePick = 0
		pick()
	end
	local clock = os.clock()
	for _, entry in sheep do
		if entry.Penned then
			place(entry, clock, dt)
		end
	end
	local pose: SheepClips.Pose = {}
	for _, entry in animated do
		table.clear(pose)
		animateSheep(entry, clock, pose)
		for name, offset in pose do
			set(entry.Joints[name], offset)
		end
	end
	for _, entry in animatedGods do
		local model = entry.Model
		local mood = model:GetAttribute("Mood")
		local speed = model:GetAttribute("Speed")
		local pace = if type(speed) == "number" then speed else 0
		local joints = entry.Joints
		if mood == "Run" or mood == "Return" then
			local swing = math.sin(clock * (4 + pace * 0.25)) * rad(45)
			set(joints.LeftHip, CFrame.Angles(swing, 0, 0))
			set(joints.RightHip, CFrame.Angles(-swing, 0, 0))
			set(joints.LeftShoulder, CFrame.Angles(-swing, 0, 0))
			set(joints.RightShoulder, CFrame.Angles(swing, 0, 0))
		elseif mood == "Alert" then
			local shake = math.sin(clock * 30) * rad(12)
			set(joints.LeftShoulder, CFrame.Angles(rad(150), 0, shake))
			set(joints.RightShoulder, CFrame.Angles(rad(150), 0, -shake))
		elseif mood == "Taunt" then
			local hop = math.abs(math.sin(clock * 9)) * 0.8
			set(joints.RootJoint, CFrame.new(0, hop, 0))
			set(joints.LeftShoulder, CFrame.Angles(rad(170), 0, 0))
			set(joints.RightShoulder, CFrame.Angles(rad(170), 0, 0))
		else
			local breath = math.sin(clock * 1.6 + entry.Seed)
			set(joints.LeftShoulder, CFrame.Angles(0, 0, rad(4 * breath)))
			set(joints.RightShoulder, CFrame.Angles(0, 0, rad(-4 * breath)))
			set(joints.Neck, CFrame.Angles(0, rad(15 * math.sin(clock * 0.4 + entry.Seed)), 0))
		end
	end
	baa()
end

local function restore()
	for index, joint in touched do
		joint.Transform = befores[index]
	end
	table.clear(touched)
	table.clear(befores)
end

function AnimController.Init(_self: any, _systems: Lifecycle.Registry) end

function AnimController.Start(_self: any)
	for _, instance in CollectionService:GetTagged(SHEEP_TAG) do
		addSheep(instance)
	end
	trove:Connect(CollectionService:GetInstanceAddedSignal(SHEEP_TAG), addSheep)
	trove:Connect(CollectionService:GetInstanceRemovedSignal(SHEEP_TAG), function(instance: Instance)
		if instance:IsA("Model") then
			forget(instance)
		end
	end)
	task.spawn(function()
		local folder = workspace:WaitForChild("Gods", 60)
		if not folder then
			return
		end
		local function addGod(child: Instance)
			if child:IsA("Model") then
				gods[child] = rig(child)
			end
		end
		for _, child in folder:GetChildren() do
			addGod(child)
		end
		trove:Connect(folder.ChildAdded, addGod)
	end)
	trove:Connect(RunService.PreSimulation, apply)
	trove:Connect(RunService.PostSimulation, restore)
end

function AnimController.Destroy(_self: any)
	trove:Clean()
	restore()
	for model in sheep do
		forget(model)
	end
end

return AnimController
