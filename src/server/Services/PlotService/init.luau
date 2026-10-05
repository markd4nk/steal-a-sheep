--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Utils.Format)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Build = require(script.Build)

-- The map's five player plots (workspace.Base.PlayerPlots): one per player, first come first served, with the pieces
-- Build adds to each (pen pads, delivery pad, stair walker, sign). Players spawn inside their own plot's gate.
local PlotService = {
	Name = "PlotService",
	PlotAssigned = Signal.new() :: Signal.Signal<Player, Plot>,
}

export type Plot = {
	Index: number,
	Model: Model,
	Origin: CFrame,
	Pieces: Build.Pieces,
	Owner: Player?,
}

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local plots: { Plot } = {}
local byPlayer: { [Player]: Plot } = {}

local function setSign(plot: Plot)
	local owner = plot.Owner
	plot.Pieces.Sign.Text = if owner then `{owner.DisplayName}'s Pen` else "Empty plot"
	plot.Pieces.SignIncome.Text = ""
end

local function spawnAt(player: Player, character: Model)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	-- After the character's own spawn placement.
	task.defer(function()
		if character.Parent and byPlayer[player] == plot then
			registry.MountainService:Teleported(player, plot.Pieces.Spawn.Position.X)
			character:PivotTo(plot.Pieces.Spawn)
		end
	end)
end

local function assign(player: Player)
	if byPlayer[player] then
		return
	end
	for _, plot in plots do
		if not plot.Owner then
			plot.Owner = player
			byPlayer[player] = plot
			player:SetAttribute("Plot", plot.Index)
			setSign(plot)
			PlotService.PlotAssigned:Fire(player, plot)
			if player.Character then
				spawnAt(player, player.Character)
			end
			return
		end
	end
	-- Every plot has an owner: the server's player limit should match the plot count (DESIGN/STUDIO_CONTENT.md).
	player:Kick("This server is full. Please join another one.")
end

local function release(player: Player)
	local plot = byPlayer[player]
	if plot then
		byPlayer[player] = nil
		plot.Owner = nil
		setSign(plot)
		Build.PaintPads(plot.Pieces.Pads, 0)
	end
end

function PlotService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function PlotService.Start(_self: any)
	local base = workspace:FindFirstChild("Base")
	local holder = base and base:FindFirstChild("PlayerPlots")
	if not holder then
		warn("[PlotService] workspace.Base.PlayerPlots is missing: the map isn't in this place")
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	folder.Parent = workspace
	trove:Add(folder)
	local models: { Model } = {}
	for _, child in holder:GetChildren() do
		if child:IsA("Model") then
			table.insert(models, child)
		end
	end
	-- A stable order across servers: by position along the row of plots.
	table.sort(models, function(a: Model, b: Model)
		return a:GetBoundingBox().Position.Z < b:GetBoundingBox().Position.Z
	end)
	for index, model in models do
		local pieces, origin = Build.Plot(index, model, folder)
		local plot: Plot = { Index = index, Model = model, Origin = origin, Pieces = pieces, Owner = nil }
		Build.PaintPads(pieces.Pads, 0)
		Build.PaintWalker(pieces.Walker, 0)
		setSign(plot)
		table.insert(plots, plot)
	end
	trove:Add(registry.DataService:ObserveLoaded(function(player: Player)
		assign(player)
	end))
	trove:Connect(Players.PlayerRemoving, release)
	local function watch(player: Player)
		trove:Connect(player.CharacterAdded, function(character: Model)
			spawnAt(player, character)
		end)
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	trove:Connect(Players.PlayerAdded, watch)
end

function PlotService.Destroy(_self: any)
	trove:Clean()
end

function PlotService.GetPlot(_self: any, player: Player): Plot?
	return byPlayer[player]
end

function PlotService.Plots(_self: any): { Plot }
	return plots
end

-- Where a pen slot's sheep stands, facing the gate.
function PlotService.SlotCFrame(_self: any, plot: Plot, slot: number): CFrame?
	local pad = plot.Pieces.Pads[slot]
	if not pad then
		return nil
	end
	return CFrame.new(pad.Position + Vector3.new(0, pad.Size.Y / 2, 0))
		* CFrame.Angles(0, math.rad(-90 + (slot * 37) % 21 - 10), 0)
end

function PlotService.Refresh(_self: any, player: Player, penSlots: number, walkerLevel: number, income: number)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	Build.PaintPads(plot.Pieces.Pads, penSlots)
	Build.PaintWalker(plot.Pieces.Walker, walkerLevel)
	plot.Pieces.SignIncome.Text = if income > 0 then `+{Format.Rate(income)}/s` else ""
	plot.Pieces.WalkerScreen.Text = `STAIR WALKER LV {walkerLevel + 1}`
end

-- Whether the player stands on their own stair walker's base.
function PlotService.IsOnWalker(_self: any, player: Player): boolean
	local plot = byPlayer[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not plot or not root or not root:IsA("BasePart") then
		return false
	end
	local zone = plot.Pieces.WalkerZone
	local offset = zone.CFrame:PointToObjectSpace(root.Position)
	local half = zone.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

-- Puts the player back inside their own gate.
function PlotService.SendHome(_self: any, player: Player)
	local plot = byPlayer[player]
	local character = player.Character
	if plot and character then
		registry.MountainService:Teleported(player, plot.Pieces.Spawn.Position.X)
		character:PivotTo(plot.Pieces.Spawn)
	end
end

return PlotService
