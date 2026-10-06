--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The avatar gods (GodService's models with a Humanoid) on this device, using Roblox's own avatar animations: idle at
-- home, walk back home, run when chasing, sped up to the god's Speed; it points at the thief when alerted and laughs
-- when it catches them. A god whose Raise attribute is set (Zeus) keeps its right arm up with its symbol. Only gods
-- near the camera animate; the block figures (the fallback) are AnimController's.
local GodController = { Name = "GodController" }

type Entry = {
	Model: Model,
	Animator: Animator,
	Tracks: { [string]: AnimationTrack },
	Playing: string?,
	Shoulder: AnimationConstraint?,
}

local CLIPS: { [string]: string } = {
	Idle = "rbxassetid://507766388",
	Walk = "rbxassetid://507777826",
	Run = "rbxassetid://507767714",
	Point = "rbxassetid://507770453",
	Laugh = "rbxassetid://507770818",
}
local SCALE = 1.65 -- Avatar.Scale: their strides are this much longer than a player's
local WALK_STUDS = 6.4 * SCALE -- speeds at which Roblox's walk and run clips match their feet at 1x
local RUN_STUDS = 12.8 * SCALE
local RANGE = 220
local PICK_EVERY = 0.25
local FADE = 0.2
local RAISED = CFrame.Angles(math.rad(165), 0, 0)

local trove = Trove.new()
local gods: { [Model]: Entry } = {}
local near: { Entry } = {}
local sincePick = math.huge

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

local function wanted(model: Model): (string, number)
	local mood = model:GetAttribute("Mood")
	local speed = model:GetAttribute("Speed")
	local pace = if type(speed) == "number" then speed else 0
	if mood == "Run" then
		return "Run", math.clamp(pace / RUN_STUDS, 0.6, 2.4)
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
	local name, speed = wanted(entry.Model)
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
			table.insert(near, entry)
			animate(entry)
		elseif entry.Playing then
			stopAll(entry)
		end
	end
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
	gods[child] = {
		Model = child,
		Animator = animator,
		Tracks = {},
		Playing = nil,
		Shoulder = if shoulder and shoulder:IsA("AnimationConstraint") then shoulder else nil,
	}
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
	-- After the Animator has posed them: the raised arm overrides its clip's shoulder.
	trove:Connect(RunService.PreSimulation, function()
		for _, entry in near do
			local shoulder = entry.Shoulder
			if
				shoulder
				and entry.Model:GetAttribute("Raise")
				and entry.Playing ~= "Point"
				and entry.Playing ~= "Laugh"
			then
				shoulder.Transform = RAISED
			end
		end
	end)
end

function GodController.Destroy(_self: any)
	trove:Clean()
	for _, entry in gods do
		stopAll(entry)
	end
	table.clear(gods)
end

return GodController
