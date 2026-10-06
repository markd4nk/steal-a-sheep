--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Remotes = require(ReplicatedStorage.Remotes)
local StairClimb = require(ReplicatedStorage.Utils.StairClimb)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Motion = require(script.Parent.UIController.Motion)

-- The stair walkers on this device. A machine near the camera runs its steps while someone is on it, at that
-- climber's training rate, and everyone on a machine near the camera climbs its steps (Utils/StairClimb). Poses don't
-- replicate, so each device poses every climber it can see. Jumping while on your own machine steps you off.
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
type Gain = { Billboard: BillboardGui, Label: TextLabel, Punch: UIScale, Since: number }

local RESCAN = 1
local LEAVE_GAP = 0.4
local GAIN_HEIGHT = 40

local trove = Trove.new()
local player = Players.LocalPlayer
local machines: { [Model]: Machine } = {}
local climbers: { [Player]: Climber } = {}
local gain: Gain? = nil
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

-- The climber's training rate (the server's TrainRate), or the machine's own level's until it arrives.
local function rateOn(model: Model, climberId: number): number
	local climber = Players:GetPlayerByUserId(climberId)
	local rate = climber and climber:GetAttribute("TrainRate")
	if type(rate) == "number" then
		return rate
	end
	local level = model:GetAttribute("Level")
	return Economy.WalkerRate(if type(level) == "number" then level - 1 else 0)
end

-- What you're gaining a second, over your own head while you train: the walker's only words.
local function buildGain(): (BillboardGui, TextLabel, UIScale)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TrainGain"
	billboard.Size = UDim2.fromOffset(220, GAIN_HEIGHT)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.Enabled = false
	local row = UIKit.Frame(billboard, "Row", UDim2.fromScale(1, 1))
	UIKit.List(row, true, 4, Enum.HorizontalAlignment.Center)
	local punch = Instance.new("UIScale")
	punch.Name = "Punch"
	punch.Parent = row
	UIKit.Icon(row, "Icon", Theme.Icons.HudShoe, GAIN_HEIGHT).LayoutOrder = 1
	local label = UIKit.Text(row, "RateLabel", "", 34, Theme.Color.Lime, UDim2.fromOffset(0, GAIN_HEIGHT), {
		Stroke = Theme.Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 2,
	})
	local stroke = label:FindFirstChild("TextStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Thickness = 3
	end
	return billboard, label, punch
end

local function showGain(dt: number)
	local rate = player:GetAttribute("TrainRate")
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local on = type(rate) == "number" and head ~= nil and head:IsA("BasePart")
	if not gain then
		if not on then
			return
		end
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if not playerGui then
			return
		end
		local billboard, label, punch = buildGain()
		billboard.Parent = playerGui
		gain = { Billboard = billboard, Label = label, Punch = punch, Since = 0 }
	end
	local shown = gain :: Gain
	shown.Billboard.Enabled = on
	if not on or type(rate) ~= "number" then
		shown.Since = 0
		return
	end
	shown.Billboard.Adornee = head :: BasePart
	shown.Label.Text = `+{Format.Rate(rate)}/s`
	-- A beat a second, as the Climbing comes in.
	shown.Since += dt
	if shown.Since >= 1 then
		shown.Since -= 1
		Motion.Punch(shown.Punch, 1.1)
	end
end

local function update(dt: number)
	showGain(dt)
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
		local climberId = model:GetAttribute("Climber")
		if type(climberId) == "number" then
			machine.Cycle += dt / StairClimb.StepSeconds(rateOn(model, climberId))
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
	if gain then
		gain.Billboard:Destroy()
		gain = nil
	end
end

return WalkerController
