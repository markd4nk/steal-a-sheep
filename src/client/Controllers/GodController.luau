--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ChaseFeel = require(ReplicatedStorage.Utils.ChaseFeel)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Sounds = require(ReplicatedStorage.Config.Sounds)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The gods (GodService's models) on this device. The avatars use Roblox's own avatar animations: idle at home, walk
-- back home, run when chasing, sped up to the god's Speed; it points at the thief when alerted and laughs when it
-- catches them. A god whose Raise attribute is set (Zeus) keeps its right arm up with its symbol. Only gods near the
-- camera animate; the block figures (the fallback) are AnimController's. Every god also sounds, from itself, by its
-- Mood: a roar on seeing a thief, footfalls and yells while it runs (a snarl when it's right behind this player with
-- its lamb), the punch and a laugh on a catch, an angry yell when the thief gets away; a goddess has her own voice.
-- Each moment has a few lines (Config/Sounds Voices): a god says one at random, never the take it said last nor the one
-- it said at that moment last time, so three laughs never come out as the same laugh twice running.
local GodController = {
	Name = "GodController",
	-- A running god's foot came down: (the god's model, its tier).
	Stepped = Signal.new() :: Signal.Signal<Model, number>,
}

type Entry = {
	Model: Model,
	Tier: number,
	Root: BasePart?,
	Head: BasePart?,
	Animator: Animator?,
	Tracks: { [string]: AnimationTrack },
	Playing: string?,
	Shoulder: AnimationConstraint?,
	Mood: string,
	NextStep: number,
	NextYell: number,
	LastLine: string?, -- the sound id of the god's last line
	LastFor: { [string]: string }, -- and of its last line at each moment
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
local VOICE_RANGE = 400 -- the furthest a god's sounds carry (Config/Sounds' Range)
local PICK_EVERY = 0.25
local FADE = 0.2
local RAISED = CFrame.Angles(math.rad(165), 0, 0)
local LAUGH_DELAY = 0.35 -- after the punch lands

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local gods: { [Model]: Entry } = {}
local near: { Entry } = {}
local sincePick = math.huge
local random = Random.new()
local chase = GameConfig.Chase

local function track(entry: Entry, name: string): AnimationTrack?
	local existing = entry.Tracks[name]
	if existing then
		return existing
	end
	local animator = entry.Animator
	if not animator then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = CLIPS[name]
	local loaded = animator:LoadAnimation(animation)
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

local function speedOf(model: Model): number
	local speed = model:GetAttribute("Speed")
	return if type(speed) == "number" then speed else 0
end

local function wanted(model: Model): (string, number)
	local mood = model:GetAttribute("Mood")
	local pace = speedOf(model)
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
	if not entry.Animator then
		return
	end
	local name, speed = wanted(entry.Model)
	local current = entry.Playing and entry.Tracks[entry.Playing]
	if entry.Playing ~= name then
		if current then
			current:Stop(FADE)
		end
		local nextTrack = track(entry, name)
		if nextTrack then
			nextTrack:Play(FADE)
		end
		entry.Playing = name
		current = nextTrack
	end
	if current then
		current:AdjustSpeed(speed)
	end
end

-- How far the god is from whoever's listening: the camera, or the character when nearer (a teleport moves the
-- character a frame before the camera follows).
local function listenerDistance(entry: Entry): number
	local root = entry.Root
	if not root then
		return math.huge
	end
	local nearest = math.huge
	local camera = workspace.CurrentCamera
	if camera then
		nearest = (root.Position - camera.CFrame.Position).Magnitude
	end
	local character = Players.LocalPlayer.Character
	local own = character and character:FindFirstChild("HumanoidRootPart")
	if own and own:IsA("BasePart") then
		nearest = math.min(nearest, (root.Position - own.Position).Magnitude)
	end
	return nearest
end

local function isGoddess(entry: Entry): boolean
	local tier = Olympus.Tiers[entry.Tier]
	return tier ~= nil and tier.Goddess == true
end

local function say(entry: Entry, name: string, part: BasePart?)
	local sound = registry.SoundController
	local from = part or entry.Head or entry.Root
	if sound and from then
		sound:PlayOn(name, from)
	end
end

-- One of the god's lines for `moment` (Roar, Yell, Snarl, Laugh, Frustrated): not the take it said last, nor its last
-- one at this moment, while there's another to choose.
local function speak(entry: Entry, moment: string)
	local lines = Sounds.Voices[if isGoddess(entry) then "Goddess" else "God"][moment]
	if not lines or #lines == 0 then
		return
	end
	local fresh: { string } = {}
	for _, name in lines do
		local effect = Sounds.Effects[name]
		if effect and effect.Id ~= entry.LastLine and effect.Id ~= entry.LastFor[moment] then
			table.insert(fresh, name)
		end
	end
	local pool = if #fresh > 0 then fresh else lines
	local name = pool[random:NextInteger(1, #pool)]
	local effect = Sounds.Effects[name]
	if effect then
		entry.LastLine = effect.Id
		entry.LastFor[moment] = effect.Id
	end
	say(entry, name)
end

-- Whether this god is chasing the local player, close behind: it's their tier's lamb they carry, and they're near.
local function rightBehind(entry: Entry): boolean
	local player = Players.LocalPlayer
	if player:GetAttribute("CarryTier") ~= entry.Tier or player:GetAttribute("Carrying") ~= true then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local godRoot = entry.Root
	if not root or not root:IsA("BasePart") or not godRoot then
		return false
	end
	return (root.Position - godRoot.Position).Magnitude <= chase.SnarlStuds
end

local function onMood(entry: Entry)
	local mood = entry.Model:GetAttribute("Mood")
	local was = entry.Mood
	entry.Mood = if type(mood) == "string" then mood else "Idle"
	if entry.Mood == was or listenerDistance(entry) > VOICE_RANGE then
		return
	end
	local now = os.clock()
	if entry.Mood == "Alert" then
		speak(entry, "Roar")
	elseif entry.Mood == "Run" then
		entry.NextStep = now
		entry.NextYell = now + random:NextNumber(1.2, 2.2)
	elseif entry.Mood == "Taunt" then
		say(entry, "PunchSwing", entry.Root)
		say(entry, "PunchHit", entry.Root)
		say(entry, "PunchSmack", entry.Root)
		task.delay(LAUGH_DELAY, function()
			if entry.Model.Parent then
				speak(entry, "Laugh")
			end
		end)
	elseif entry.Mood == "Return" and (was == "Run" or was == "Alert") then
		speak(entry, "Frustrated")
	end
end

-- A running god's footfalls and yells, for the gods near enough to hear.
local function voice(entry: Entry, now: number)
	if entry.Mood ~= "Run" then
		return
	end
	if now >= entry.NextStep then
		entry.NextStep = now + ChaseFeel.StepSeconds(speedOf(entry.Model), RUN_STUDS)
		say(entry, "GodStep", entry.Root)
		GodController.Stepped:Fire(entry.Model, entry.Tier)
	end
	if now >= entry.NextYell then
		if rightBehind(entry) then
			speak(entry, "Snarl")
			entry.NextYell = now + random:NextNumber(chase.Snarl[1], chase.Snarl[2])
		else
			speak(entry, "Yell")
			entry.NextYell = now + random:NextNumber(chase.Yell[1], chase.Yell[2])
		end
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
	local tier = child:GetAttribute("Tier")
	if type(tier) ~= "number" then
		return
	end
	-- The avatars animate here; a block figure (no Humanoid) only sounds.
	local humanoid = child:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:WaitForChild("Animator", 10)
	local upper = child:FindFirstChild("RightUpperArm")
	local shoulder = upper and upper:FindFirstChild("RightShoulder")
	local head = child:FindFirstChild("Head")
	local entry: Entry = {
		Model = child,
		Tier = tier,
		Root = child.PrimaryPart,
		Head = if head and head:IsA("BasePart") then head else nil,
		Animator = if animator and animator:IsA("Animator") then animator else nil,
		Tracks = {},
		Playing = nil,
		Shoulder = if shoulder and shoulder:IsA("AnimationConstraint") then shoulder else nil,
		Mood = "Idle",
		NextStep = 0,
		NextYell = 0,
		LastLine = nil,
		LastFor = {},
	}
	gods[child] = entry
	onMood(entry)
	trove:Connect(child:GetAttributeChangedSignal("Mood"), function()
		onMood(entry)
	end)
end

function GodController.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

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
		local now = os.clock()
		for _, entry in near do
			voice(entry, now)
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
