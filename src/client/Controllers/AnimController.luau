--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local SheepClips = require(ReplicatedStorage.Utils.SheepClips)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Presentation on this device only: the sheep's procedural idle from Shear a Sheep (Utils/SheepClips: breathing,
-- glances, tail wags; the carried sway on a thief's head) on the nearest sheep, a baa now and then, and the gods' limbs
-- swinging as they run, shaking their arms when alerted and hopping when they catch someone. Offsets go onto the
-- joints in PreSimulation and come off in PostSimulation, so nothing piles up.
local AnimController = { Name = "AnimController" }

type Rigged = {
	Model: Model,
	Joints: { [string]: Motor6D },
	Seed: number,
}

local PICK_EVERY = 0.25
local GOD_RANGE = 220
local SHEEP_TAG = "Sheep"
local rad = math.rad

local trove = Trove.new()
local random = Random.new()
local sheep: { [Model]: Rigged } = {}
local gods: { [Model]: Rigged } = {}
local animated: { Rigged } = {}
local animatedGods: { Rigged } = {}
local touched: { Motor6D } = {}
local befores: { CFrame } = {}
local sincePick = math.huge
local nextBaa = 0

local function rig(model: Model): Rigged
	local joints: { [string]: Motor6D } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Motor6D") then
			joints[descendant.Name] = descendant
		end
	end
	return { Model = model, Joints = joints, Seed = random:NextNumber(0, 100) }
end

local function addSheep(instance: Instance)
	if instance:IsA("Model") and instance:IsDescendantOf(workspace) then
		sheep[instance] = rig(instance)
	end
end

local function pick()
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
			sheep[model] = nil
			continue
		end
		local distance = (model:GetPivot().Position - eye).Magnitude
		if distance <= GameConfig.SheepMotion.AnimationRange then
			table.insert(near, { entry, distance })
		end
	end
	table.sort(near, function(a, b)
		return (a[2] :: number) < (b[2] :: number)
	end)
	for index = 1, math.min(#near, GameConfig.SheepMotion.MaxAnimatedSheep) do
		table.insert(animated, near[index][1] :: Rigged)
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

local function apply(dt: number)
	sincePick += dt
	if sincePick >= PICK_EVERY then
		sincePick = 0
		pick()
	end
	local clock = os.clock()
	local pose: SheepClips.Pose = {}
	for _, entry in animated do
		table.clear(pose)
		local model = entry.Model
		if model:GetAttribute("State") == "Carried" then
			local root = model.PrimaryPart
			if root then
				SheepClips.Carried(
					clock + entry.Seed,
					root.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity),
					pose
				)
			end
		else
			SheepClips.Idle(clock, entry.Seed, 1, pose)
		end
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
			sheep[instance] = nil
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
end

return AnimController
