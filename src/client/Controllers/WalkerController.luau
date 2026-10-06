--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Remotes = require(ReplicatedStorage.Remotes)
local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local StairClimb = require(ReplicatedStorage.Utils.StairClimb)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)

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
type Pops = { Billboard: BillboardGui, Canvas: Frame, Fit: UIScale, Step: number?, Tag: BillboardGui? }

local RESCAN = 1
local LEAVE_GAP = 0.4
-- The pops are drawn in points on a canvas POP_WIDTH x (POP_RISE + POP_HEIGHT), scaled to POP_STUDS studs tall over the
-- head, so they keep their size next to the character on any screen and at any distance.
local POP_WIDTH = 260
local POP_HEIGHT = 34
local POP_RISE = 130 -- how far a pop rises before it's gone
local POP_STUDS = 6
local POP_SPREAD = 0.5 -- of the width, where a pop starts across
local POP_ABOVE_HEAD = 0.4 -- studs from the head's top to the pops' bottom edge
local POP_SECONDS = 0.9
local POP_IN = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_UP = TweenInfo.new(POP_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_FADE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local trove = Trove.new()
local player = Players.LocalPlayer
local machines: { [Model]: Machine } = {}
local climbers: { [Player]: Climber } = {}
local pops: Pops? = nil
local random = Random.new()
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

-- One "+N" a step rising off your own head while you train, N being what that step earned: the faster the machine,
-- the more of them, the walker's only words.
local function buildPops(): (BillboardGui, Frame, UIScale)
	local tall = POP_RISE + POP_HEIGHT
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TrainGain"
	billboard.Size = UDim2.fromScale(POP_STUDS * POP_WIDTH / tall, POP_STUDS)
	billboard.SizeOffset = Vector2.new(0, 0.5) -- its bottom edge on the point over the head
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.Enabled = false
	local canvas = UIKit.Frame(billboard, "Canvas", UDim2.fromOffset(POP_WIDTH, tall))
	canvas.AnchorPoint = Vector2.new(0.5, 0.5)
	canvas.Position = UDim2.fromScale(0.5, 0.5)
	local fit = Instance.new("UIScale")
	fit.Name = "Fit"
	fit.Parent = canvas
	return billboard, canvas, fit
end

local function pop(canvas: Frame, amount: number)
	local item = UIKit.Frame(canvas, "Pop", UDim2.fromOffset(0, POP_HEIGHT))
	item.AutomaticSize = Enum.AutomaticSize.X
	item.AnchorPoint = Vector2.new(0.5, 1)
	local x = 0.5 + (random:NextNumber() - 0.5) * POP_SPREAD
	item.Position = UDim2.fromScale(x, 1)
	UIKit.List(item, true, 2, Enum.HorizontalAlignment.Center)
	local icon = UIKit.Icon(item, "Icon", Theme.Icons.HudShoe, POP_HEIGHT)
	icon.LayoutOrder = 1
	local label =
		UIKit.Text(item, "Label", `+{Format.Rate(amount, 1)}`, 30, Theme.Color.Lime, UDim2.fromOffset(0, POP_HEIGHT), {
			Stroke = Theme.Color.Line,
			Auto = Enum.AutomaticSize.X,
			Order = 2,
		})
	local stroke = label:FindFirstChild("TextStroke") :: UIStroke?
	if stroke then
		stroke.Thickness = 3
	end
	if not PlayerSettings.ReduceMotion() then
		local scale = Instance.new("UIScale")
		scale.Scale = 0.5
		scale.Parent = item
		TweenService:Create(scale, POP_IN, { Scale = 1 }):Play()
		TweenService:Create(item, POP_UP, { Position = UDim2.new(x, 0, 0, POP_HEIGHT) }):Play()
	end
	task.delay(POP_SECONDS - POP_FADE.Time, function()
		TweenService:Create(label, POP_FADE, { TextTransparency = 1 }):Play()
		TweenService:Create(icon, POP_FADE, { ImageTransparency = 1 }):Play()
		if stroke then
			TweenService:Create(stroke, POP_FADE, { Transparency = 1 }):Play()
		end
	end)
	task.delay(POP_SECONDS, function()
		item:Destroy()
	end)
end

local function showPops()
	local rate = player:GetAttribute("TrainRate")
	local index = player:GetAttribute("OnWalker")
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local machine = if type(index) == "number" then machineOf(index) else nil
	if type(rate) ~= "number" or not machine or not head or not head:IsA("BasePart") then
		if pops then
			pops.Billboard.Enabled = false
			pops.Step = nil
			if pops.Tag then
				pops.Tag.Enabled = true
				pops.Tag = nil
			end
		end
		return
	end
	if not pops then
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if not playerGui then
			return
		end
		local billboard, canvas, fit = buildPops()
		billboard.Parent = playerGui
		pops = { Billboard = billboard, Canvas = canvas, Fit = fit, Step = nil }
	end
	local shown = pops :: Pops
	shown.Billboard.Enabled = true
	-- Your machine's floating level hides on your screen while you climb, or the pops would rise through it (its
	-- console still shows the level; other players still see it).
	local anchor = machine.Model:FindFirstChild("TagAnchor", true)
	local tag = anchor and anchor:FindFirstChildOfClass("BillboardGui")
	if tag then
		tag.Enabled = false
		shown.Tag = tag
	end
	shown.Billboard.Adornee = head
	-- Just over the head, under the machine's floating level tag.
	shown.Billboard.StudsOffset = Vector3.new(0, head.Size.Y / 2 + POP_ABOVE_HEAD, 0)
	local tall = shown.Billboard.AbsoluteSize.Y
	if tall > 0 then
		shown.Fit.Scale = tall / (POP_RISE + POP_HEIGHT)
	end
	local step = math.floor(machine.Cycle)
	if shown.Step and step > shown.Step then
		pop(shown.Canvas, rate * StairClimb.StepSeconds(rate))
	end
	shown.Step = step
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
	showPops()
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
	if pops then
		pops.Billboard:Destroy()
		pops = nil
	end
end

return WalkerController
