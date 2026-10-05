--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CarryPose = require(ReplicatedStorage.Utils.CarryPose)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)

-- A carrier's character measured and solved for the breed they carry: each arm joint with its Transform in the hold.
type Pose = {
	Character: Model,
	Body: CarryPose.Body,
	Joints: { CarryPose.Joint },
	Targets: { CFrame },
	Shoulder: CFrame, -- the right shoulder's C0 when measured: a rescaled avatar is measured again
}

type Carrier = {
	Player: Player,
	Holding: boolean, -- the server says they carry a sheep (Carrying)
	Weight: number, -- 0: Roblox's own arms, 1: the hold; eased on the way
	Breed: GameConfig.Breed?, -- the last breed they carried, so arms lowering after the put-down keep its pose
	Pose: Pose?,
	Phase: number, -- seconds into the sway, so carriers don't sway in step
}

local PICK_INTERVAL = 0.2 -- seconds between picks of which carriers to pose and checks that their rigs still stand

local Settings = GameConfig.Carry

-- Holds the sheep up (Shear a Sheep's carry): every player carrying a lamb, on this device, holds it over their head
-- with both arms (Utils/CarryPose), so everyone sees it without anything replicating. The arms blend in over
-- PickUpSeconds when the Carrying attribute turns on and back over PutDownSeconds when it turns off. The pose goes onto
-- the joints after the Animator has written them (PreSimulation) and comes off after the frame's physics
-- (PostSimulation), so the Animator always starts from its own pose and the legs stay its own. Only carriers within
-- PoseRange of the camera are posed.
local CarryController = { Name = "CarryController" }

local carriers: { [Player]: Carrier } = {}
local playerConnections: { [Player]: { RBXScriptConnection } } = {}
local connections: { RBXScriptConnection } = {}
local posed: { Carrier } = {}
local touched: { CarryPose.Joint } = {}
local befores: { CFrame } = {}
local sincePick = math.huge

local function smooth(x: number): number
	local t = math.clamp(x, 0, 1)
	return t * t * (3 - 2 * t)
end

-- The carried lamb's look at the size it's held: CarryPose reads a breed's Scale over GameConfig.SheepSize.
local function breedOf(player: Player): GameConfig.Breed?
	local family = player:GetAttribute("CarriedFamily")
	local scale = player:GetAttribute("CarriedScale")
	local breed = if type(family) == "string" then GameConfig.Breeds[family] else nil
	if not breed or type(scale) ~= "number" then
		return nil
	end
	local copy = table.clone(breed)
	copy.Scale = scale * GameConfig.SheepSize
	return copy
end

-- Measures the carrier's character and solves the hold for their breed; nil while the character isn't all there.
local function measure(carrier: Carrier): Pose?
	local character = carrier.Player.Character
	local breed = carrier.Breed
	local body = if character and breed then CarryPose.Measure(character) else nil
	if not character or not breed or not body then
		return nil
	end
	local hold = CarryPose.Solve(body.Shape, breed)
	local joints: { CarryPose.Joint } = {}
	local targets: { CFrame } = {}
	for armIndex, armJoints in body.Joints do
		local arm = body.Shape.Arms[armIndex]
		for index, joint in armJoints do
			table.insert(joints, joint)
			table.insert(targets, CarryPose.Transform(arm.Links[index].C0, hold.Rotations[armIndex][index]))
		end
	end
	return {
		Character = character,
		Body = body,
		Joints = joints,
		Targets = targets,
		Shoulder = (CarryPose.JointFrames(joints[1])),
	}
end

-- Whether a pose still fits its carrier: same character, every joint still in it, and the same size.
local function stillFits(pose: Pose, carrier: Carrier): boolean
	if carrier.Player.Character ~= pose.Character or pose.Body.Torso.Parent ~= pose.Character then
		return false
	end
	for _, joint in pose.Joints do
		if not joint.Parent then
			return false
		end
	end
	return (CarryPose.JointFrames(pose.Joints[1])) == pose.Shoulder
end

local function remeasure(carrier: Carrier)
	carrier.Breed = breedOf(carrier.Player) or carrier.Breed
	carrier.Pose = measure(carrier)
	-- Pick again next frame, so a pick-up starting now isn't left out for a whole interval.
	sincePick = math.huge
end

-- Picks the carriers to pose: arms off Roblox's own and within PoseRange of the camera. Rigs that changed (a
-- respawn, an avatar reloading its body parts) are measured again.
local function pick()
	table.clear(posed)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	for _, carrier in carriers do
		if not carrier.Holding and carrier.Weight <= 0 then
			continue
		end
		local pose = carrier.Pose
		if not pose or not stillFits(pose, carrier) then
			pose = measure(carrier)
			carrier.Pose = pose
		end
		if pose and (pose.Body.Torso.Position - eye).Magnitude <= Settings.PoseRange then
			table.insert(posed, carrier)
		end
	end
end

-- PreSimulation: moves every carrier's blend on, then poses the picked ones over what the Animator wrote. The arms
-- blend all the way to the hold (the walk swings them, and they must hold still under the sheep); the waist only
-- leans and sways on top of its own motion, a little steadied.
local function apply(deltaTime: number)
	for _, carrier in carriers do
		if carrier.Holding then
			carrier.Weight = math.min(carrier.Weight + deltaTime / Settings.PickUpSeconds, 1)
		else
			carrier.Weight = math.max(carrier.Weight - deltaTime / Settings.PutDownSeconds, 0)
		end
	end
	sincePick += deltaTime
	if sincePick >= PICK_INTERVAL then
		sincePick = 0
		pick()
	end
	local now = workspace:GetServerTimeNow()
	for _, carrier in posed do
		local pose = carrier.Pose
		local weight = smooth(carrier.Weight)
		if not pose or weight <= 0 then
			continue
		end
		for index, joint in pose.Joints do
			local before = joint.Transform
			table.insert(touched, joint)
			table.insert(befores, before)
			CarryPose.SetTransform(joint, before:Lerp(pose.Targets[index], weight))
		end
		local waist = pose.Body.Waist
		if waist then
			local sway = Settings.SwayDegrees * math.sin((now + carrier.Phase) * 2 * math.pi / Settings.SwaySeconds)
			local tilt = CFrame.Angles(math.rad(Settings.WaistLean * weight), 0, math.rad(sway * weight))
			local before = waist.Transform
			table.insert(touched, waist)
			table.insert(befores, before)
			local steadied = before:Lerp(CFrame.identity, Settings.WaistSteady * weight)
			CarryPose.SetTransform(waist, steadied * CarryPose.Transform(CarryPose.JointFrames(waist), tilt))
		end
	end
end

-- PostSimulation: takes the pose off again, so next frame starts from what the Animator writes.
local function restore()
	for index, joint in touched do
		CarryPose.SetTransform(joint, befores[index])
	end
	table.clear(touched)
	table.clear(befores)
end

local function track(player: Player)
	local holding = player:GetAttribute("Carrying") == true
	local carrier: Carrier = {
		Player = player,
		Holding = holding,
		-- Already carrying when first seen: straight to the hold, the pick-up happened before we looked.
		Weight = if holding then 1 else 0,
		Breed = breedOf(player),
		Pose = nil,
		Phase = (player.UserId % 97) * 0.37,
	}
	carriers[player] = carrier
	playerConnections[player] = {
		player:GetAttributeChangedSignal("Carrying"):Connect(function()
			carrier.Holding = player:GetAttribute("Carrying") == true
			sincePick = math.huge
		end),
		player:GetAttributeChangedSignal("CarriedFamily"):Connect(function()
			if breedOf(player) then
				remeasure(carrier)
			end
		end),
		player:GetAttributeChangedSignal("CarriedScale"):Connect(function()
			if breedOf(player) then
				remeasure(carrier)
			end
		end),
		player.CharacterAdded:Connect(function()
			-- A respawn mid-carry goes straight to the hold: the sheep comes back on the new character, no pick-up.
			carrier.Weight = if carrier.Holding then 1 else 0
			remeasure(carrier)
		end),
	}
end

local function untrack(player: Player)
	local list: { RBXScriptConnection } = playerConnections[player] or {}
	for _, connection in list do
		connection:Disconnect()
	end
	playerConnections[player] = nil
	carriers[player] = nil
	sincePick = math.huge
end

function CarryController.Init(_self: any, _systems: Lifecycle.Registry) end

function CarryController.Start(_self: any)
	for _, player in Players:GetPlayers() do
		track(player)
	end
	table.insert(connections, Players.PlayerAdded:Connect(track))
	table.insert(connections, Players.PlayerRemoving:Connect(untrack))
	table.insert(connections, RunService.PreSimulation:Connect(apply))
	table.insert(connections, RunService.PostSimulation:Connect(restore))
end

function CarryController.Destroy(_self: any)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for player in playerConnections do
		untrack(player)
	end
	restore()
	table.clear(posed)
end

return CarryController
