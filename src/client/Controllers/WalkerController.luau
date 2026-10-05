--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Remotes = require(ReplicatedStorage.Remotes)
local StairClimb = require(ReplicatedStorage.Utils.StairClimb)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The stair walkers on this device. A machine near the camera runs its steps while someone is on it, at its level's
-- speed, and everyone on a machine near the camera climbs its steps (Utils/StairClimb). Poses don't replicate, so each
-- device poses every climber it can see. Jumping while on your own machine steps you off.
local WalkerController = { Name = "WalkerController" }

type Machine = {
	Model: Model,
	Folder: Instance?,
	Parts: { BasePart },
	Shown: { boolean },
	Cycle: number,
	Placed: number?, -- the cycle the steps were last put at
}
type Climber = { Character: Model, Rig: StairClimb.Rig? }

local RESCAN = 1
local LEAVE_GAP = 0.4

local trove = Trove.new()
local player = Players.LocalPlayer
local machines: { [Model]: Machine } = {}
local climbers: { [Player]: Climber } = {}
local lastLeave = 0

local function rescan()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return
	end
	for _, plot in plots:GetChildren() do
		local model = plot:FindFirstChild("StairWalker")
		if model and model:IsA("Model") and not machines[model] then
			machines[model] = { Model = model, Folder = nil, Parts = {}, Shown = {}, Cycle = 0, Placed = nil }
		end
	end
end

-- The step parts in order (Step1's tread, nose, riser, then Step2's ...), re-read when the server rebuilt them.
local function partsOf(machine: Machine): { BasePart }
	local folder = machine.Model:FindFirstChild("Steps")
	if folder ~= machine.Folder then
		machine.Folder = folder
		machine.Placed = nil
		table.clear(machine.Parts)
		table.clear(machine.Shown)
		for index = 1, StairClimb.Steps do
			local step = folder and folder:FindFirstChild(`Step{index}`)
			for _, name in { "Tread", "Nose", "Riser" } do
				local found = step and step:FindFirstChild(name)
				if found and found:IsA("BasePart") then
					table.insert(machine.Parts, found)
				end
			end
		end
	end
	return machine.Parts
end

local function placeSteps(machine: Machine)
	local parts = partsOf(machine)
	if #parts ~= StairClimb.Steps * 3 or machine.Placed == machine.Cycle then
		return
	end
	machine.Placed = machine.Cycle
	local frame = machine.Model:GetPivot()
	local cframes: { CFrame } = {}
	for index = 1, StairClimb.Steps do
		local u = StairClimb.StepAt(index, machine.Cycle)
		local tread, nose, riser = StairClimb.StepParts(u)
		table.insert(cframes, frame * tread)
		table.insert(cframes, frame * nose)
		table.insert(cframes, frame * riser)
		local shown = StairClimb.Shown(u)
		if machine.Shown[index] ~= shown then
			machine.Shown[index] = shown
			for slot = index * 3 - 2, index * 3 do
				parts[slot].Transparency = if shown then 0 else 1
			end
		end
	end
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

local function machineOf(index: number): Machine?
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild(`Plot{index}`)
	local model = plot and plot:FindFirstChild("StairWalker")
	return if model and model:IsA("Model") then machines[model] else nil
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local range = GameConfig.StairWalker.AnimateRange
	for model, machine in machines do
		if not model.Parent then
			machines[model] = nil
			continue
		end
		if model:GetAttribute("Climber") ~= nil then
			local level = model:GetAttribute("Level")
			machine.Cycle += dt / StairClimb.StepSeconds(if type(level) == "number" then level else 1)
		end
		if (model:GetPivot().Position - eye).Magnitude < range then
			placeSteps(machine)
		end
	end
	for _, other in Players:GetPlayers() do
		local index = other:GetAttribute("OnWalker")
		local character = other.Character
		local climber = climbers[other]
		if type(index) == "number" and character then
			local current: Climber = if climber and climber.Character == character
				then climber
				else { Character = character, Rig = StairClimb.Rig(character) }
			climbers[other] = current
			local machine = machineOf(index)
			local rig = current.Rig
			if machine and rig and (character:GetPivot().Position - eye).Magnitude < range then
				StairClimb.Pose(rig, machine.Cycle)
			end
		elseif climber then
			climbers[other] = nil
			if climber.Rig and climber.Character.Parent then
				StairClimb.Release(climber.Rig)
			end
		end
	end
end

function WalkerController.Init(_self: any, _systems: Lifecycle.Registry) end

function WalkerController.Start(_self: any)
	local elapsed = RESCAN
	-- After the Animator has posed everyone this frame, before physics.
	trove:Connect(RunService.PreSimulation, function(dt: number)
		elapsed += dt
		if elapsed >= RESCAN then
			elapsed = 0
			rescan()
		end
		update(dt)
	end)
	trove:Connect(UserInputService.JumpRequest, function()
		local now = os.clock()
		if player:GetAttribute("OnWalker") ~= nil and now - lastLeave > LEAVE_GAP then
			lastLeave = now
			Remotes.LeaveWalker:Fire()
		end
	end)
	trove:Connect(Players.PlayerRemoving, function(other: Player)
		climbers[other] = nil
	end)
end

function WalkerController.Destroy(_self: any)
	trove:Clean()
	table.clear(machines)
	table.clear(climbers)
end

return WalkerController
