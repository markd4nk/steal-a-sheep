--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BodyClips = require(ReplicatedStorage.Utils.BodyClips)
local CarryPose = require(ReplicatedStorage.Utils.CarryPose)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The avatar gods (GodService's models with a Humanoid) on this device. Roblox's own avatar animations idle at home,
-- walk back home, point at the thief when alerted and laugh at a catch. A chase is this game's (Utils/BodyClips, the
-- user's pick, 2026-10-06): the god lunges face first, then glides on its belly towards its thief like a penguin,
-- leaning into its turns, and gets up when the chase ends. A god whose Raise attribute is set (Zeus) keeps its right
-- arm up with its symbol while standing. Only gods near the camera animate; the block figures (the fallback) are
-- AnimController's.
local GodController = { Name = "GodController" }

type Entry = {
	Model: Model,
	Animator: Animator,
	Tracks: { [string]: AnimationTrack },
	Playing: string?,
	Shoulder: AnimationConstraint?,
	Rig: BodyClips.Rig?, -- nil until measured, or for a body BodyClips can't pose
	Mood: string?,
	RunStart: number, -- os.clock() its chase began here, and ended
	RunEnd: number,
	Weight: number, -- how far its clip is blended over Roblox's
}

local CLIPS: { [string]: string } = {
	Idle = "rbxassetid://507766388",
	Walk = "rbxassetid://507777826",
	Point = "rbxassetid://507770453",
	Laugh = "rbxassetid://507770818",
}
local SCALE = 1.65 -- Avatar.Scale: their strides are this much longer than a player's
local WALK_STUDS = 6.4 * SCALE -- the speed at which Roblox's walk matches their feet at 1x
local RANGE = 220
local PICK_EVERY = 0.25
local FADE = 0.2
local RAISED = CFrame.Angles(math.rad(165), 0, 0)
local BLEND_IN = 14 -- a clip's weight per second towards 1, and back out
local BLEND_OUT = 8

local trove = Trove.new()
local gods: { [Model]: Entry } = {}
local near: { Entry } = {}
local sincePick = math.huge
local touched: { CarryPose.Joint } = {}
local befores: { CFrame } = {}

local function track(entry: Entry, name: string): AnimationTrack
	local existing = entry.Tracks[name]
	if existing then
		return existing
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = CLIPS[name]
	local loaded = entry.Animator:LoadAnimation(animation)
	loaded.Looped = name ~= "Point"
	entry.Tracks[name] = loaded
	return loaded
end

local function stopAll(entry: Entry)
	for _, playing in entry.Tracks do
		playing:Stop(0)
	end
	entry.Playing = nil
end

-- This game's clip for the god now and how far into it, or nil for Roblox's own: the lunge as a chase starts, then
-- the belly glide, and getting up just after it ends.
local function clipOf(entry: Entry, now: number): (BodyClips.ClipName?, number)
	if entry.Mood == "Run" then
		local age = now - entry.RunStart
		if age < BodyClips.LungeSeconds then
			return "Lunge", age
		end
		return "Belly", age - BodyClips.LungeSeconds
	end
	local since = now - entry.RunEnd
	if since < BodyClips.GetUpSeconds and entry.RunEnd > entry.RunStart then
		return "GetUp", since
	end
	return nil, 0
end

local function wanted(entry: Entry): (string, number)
	local model = entry.Model
	local mood = entry.Mood
	local speed = model:GetAttribute("Speed")
	local pace = if type(speed) == "number" then speed else 0
	if mood == "Run" then
		-- Under the lunge and the glide: their clips pose every joint.
		return "Idle", 1
	elseif mood == "Return" then
		return "Walk", math.clamp(pace / WALK_STUDS, 0.6, 1.8)
	elseif mood == "Alert" then
		return "Point", 1
	elseif mood == "Taunt" then
		return "Laugh", 1.4
	end
	return "Idle", 1
end

local function animate(entry: Entry)
	local name, speed = wanted(entry)
	local current = entry.Playing and entry.Tracks[entry.Playing]
	if entry.Playing ~= name then
		if current then
			current:Stop(FADE)
		end
		local nextTrack = track(entry, name)
		nextTrack:Play(FADE)
		entry.Playing = name
		current = nextTrack
	end
	if current then
		current:AdjustSpeed(speed)
	end
end

local function pick()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	table.clear(near)
	for model, entry in gods do
		if not model.Parent then
			gods[model] = nil
		elseif (model:GetPivot().Position - eye).Magnitude <= RANGE then
			local rig = entry.Rig
			if not rig or not BodyClips.Intact(rig) then
				entry.Rig = BodyClips.Measure(model)
			end
			table.insert(near, entry)
			animate(entry)
		elseif entry.Playing then
			stopAll(entry)
			entry.Weight = 0
		end
	end
end

-- The mood's clock: when its chase began and ended, so a god coming into view mid-chase is already gliding.
local function moodChanged(entry: Entry)
	local mood = entry.Model:GetAttribute("Mood")
	local now = os.clock()
	if mood == "Run" and entry.Mood ~= "Run" then
		entry.RunStart = now
	elseif mood ~= "Run" and entry.Mood == "Run" then
		entry.RunEnd = now
	end
	entry.Mood = if type(mood) == "string" then mood else nil
end

local function add(child: Instance)
	if not child:IsA("Model") then
		return
	end
	local humanoid = child:WaitForChild("Humanoid", 10)
	local animator = humanoid and humanoid:WaitForChild("Animator", 10)
	if not animator or not animator:IsA("Animator") then
		return
	end
	local upper = child:FindFirstChild("RightUpperArm")
	local shoulder = upper and upper:FindFirstChild("RightShoulder")
	local entry: Entry = {
		Model = child,
		Animator = animator,
		Tracks = {},
		Playing = nil,
		Shoulder = if shoulder and shoulder:IsA("AnimationConstraint") then shoulder else nil,
		Rig = BodyClips.Measure(child),
		Mood = nil,
		RunStart = 0,
		RunEnd = 0,
		Weight = 0,
	}
	moodChanged(entry)
	gods[child] = entry
	trove:Connect(child:GetAttributeChangedSignal("Mood"), function()
		moodChanged(entry)
	end)
end

-- After the Animator has posed them: a chase's clip over every joint, or the raised arm over its clip's shoulder.
local function pose(dt: number)
	local now = os.clock()
	for _, entry in near do
		local rig = entry.Rig
		local clip, t = clipOf(entry, now)
		if rig and (clip or entry.Weight > 0) then
			entry.Weight += ((if clip then 1 else 0) - entry.Weight) * math.clamp(
				dt * (if clip then BLEND_IN else BLEND_OUT),
				0,
				1
			)
			if not clip and entry.Weight < 0.01 then
				entry.Weight = 0
			else
				-- Fading out after the get-up, its last frame (standing) is what fades.
				local shown: BodyClips.ClipName = clip or "GetUp"
				local frame = BodyClips.Sample(shown, if clip then t else BodyClips.GetUpSeconds, rig.Body)
				frame.Root = BodyClips.Ground(rig, shown, dt) * (frame.Root or CFrame.identity)
				BodyClips.Apply(rig, frame, entry.Weight, nil, touched, befores)
				continue
			end
		end
		local shoulder = entry.Shoulder
		if shoulder and entry.Model:GetAttribute("Raise") and entry.Playing ~= "Point" and entry.Playing ~= "Laugh" then
			shoulder.Transform = RAISED
		end
	end
end

function GodController.Init(_self: any, _systems: Lifecycle.Registry) end

function GodController.Start(_self: any)
	task.spawn(function()
		local folder = workspace:WaitForChild("Gods", 60)
		if not folder then
			return
		end
		for _, child in folder:GetChildren() do
			task.spawn(add, child)
		end
		trove:Connect(folder.ChildAdded, function(child: Instance)
			task.spawn(add, child)
		end)
	end)
	trove:Connect(RunService.Heartbeat, function(dt: number)
		sincePick += dt
		if sincePick >= PICK_EVERY then
			sincePick = 0
			pick()
		end
	end)
	trove:Connect(RunService.PreSimulation, pose)
	trove:Connect(RunService.PostSimulation, function()
		BodyClips.Restore(touched, befores)
	end)
end

function GodController.Destroy(_self: any)
	trove:Clean()
	BodyClips.Restore(touched, befores)
	for _, entry in gods do
		stopAll(entry)
	end
	table.clear(gods)
end

return GodController
