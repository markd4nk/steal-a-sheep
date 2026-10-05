--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local PenArea = require(ReplicatedStorage.Utils.PenArea)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Build = require(script.Build)

-- The map's five player plots (workspace.Base.PlayerPlots): one per player, first come first served, with the pieces
-- Build adds to each (the pen, stair walker, sign). Players spawn inside their own plot's gate. Also answers where a
-- sheep may stand in a pen: inside the fence, off the walker, clear of the map's trees and hay (the plot's decor stays
-- where the map put it, and the sheep walk round it).
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

local PATH_STEP = 1.5 -- studs between the keep-out checks along a stroll

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local plots: { Plot } = {}
local byPlayer: { [Player]: Plot } = {}
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
overlap.RespectCanCollide = true
local sweep = RaycastParams.new()
sweep.FilterType = Enum.RaycastFilterType.Exclude
sweep.RespectCanCollide = true

-- What a sheep can't stand in or walk through: anything solid but the ground, the game's own sheep, gods, gates and
-- plot pieces (the walker has its keep-out box), and players.
local function refreshFilters()
	local skip: { Instance } = {}
	local base = workspace:FindFirstChild("Base")
	local ground = base and base:FindFirstChild("Terrain")
	if ground then
		table.insert(skip, ground)
	end
	for _, name in { "Plots", "PenSheep", "WildSheep", "CarriedSheep", "Gods", "ClimbGates", "Stations" } do
		local folder = workspace:FindFirstChild(name)
		if folder then
			table.insert(skip, folder)
		end
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(skip, player.Character)
		end
	end
	overlap.FilterDescendantsInstances = skip
	sweep.FilterDescendantsInstances = skip
end

local function inKeepout(plot: Plot, position: Vector3, radius: number): boolean
	for _, box in plot.Pieces.Keepouts do
		local offset = box.CFrame:PointToObjectSpace(position)
		local half = box.Size / 2
		if math.abs(offset.X) <= half.X + radius and math.abs(offset.Z) <= half.Z + radius then
			return true
		end
	end
	return false
end

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

-- The plot whose pen `position` is in (`margin` studs inside its fence; negative reaches past it), or nil.
function PlotService.PenAt(_self: any, position: Vector3, margin: number): Plot?
	for _, plot in plots do
		if PenArea.Contains(plot.Pieces.Pen, position, margin) then
			return plot
		end
	end
	return nil
end

-- A spot on the plot's floor, from studs off its middle (+X towards the gate), and back.
function PlotService.ToWorld(_self: any, plot: Plot, x: number, z: number): Vector3
	return plot.Origin:PointToWorldSpace(Vector3.new(x, 0, z))
end

function PlotService.ToLocal(_self: any, plot: Plot, position: Vector3): (number, number)
	local offset = plot.Origin:PointToObjectSpace(position)
	return offset.X, offset.Z
end

-- The nearest point on the plot's floor to `position` that's at least `margin` inside the fence.
function PlotService.ClampToPen(_self: any, plot: Plot, position: Vector3, margin: number): Vector3
	local inside = PenArea.Clamp(plot.Pieces.Pen, position, margin)
	return Vector3.new(inside.X, plot.Origin.Y, inside.Z)
end

-- Whether a sheep `radius` studs round could stand at `position` (its feet, on the plot's floor): inside the fence by
-- WanderFenceGap, off the walker and clear of anything solid.
function PlotService.CanStand(_self: any, plot: Plot, position: Vector3, radius: number): boolean
	if not PenArea.Contains(plot.Pieces.Pen, position, GameConfig.SheepMotion.WanderFenceGap + radius) then
		return false
	end
	if inKeepout(plot, position, radius) then
		return false
	end
	refreshFilters()
	local height = radius * 2
	local box = CFrame.new(position + Vector3.new(0, 0.4 + height / 2, 0))
	return #workspace:GetPartBoundsInBox(box, Vector3.new(radius * 2, height, radius * 2), overlap) == 0
end

-- Whether a sheep `radius` studs round can walk straight from `from` to `to` (both on the floor) without going
-- through the walker or anything solid.
function PlotService.PathClear(_self: any, plot: Plot, from: Vector3, to: Vector3, radius: number): boolean
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local length = flat.Magnitude
	if length < 0.05 then
		return true
	end
	for step = 1, math.ceil(length / PATH_STEP) do
		local along = from + flat * math.min(step * PATH_STEP / length, 1)
		if inKeepout(plot, along, radius) then
			return false
		end
	end
	refreshFilters()
	local lift = Vector3.new(0, radius + 0.4, 0)
	return workspace:Spherecast(from + lift, radius, flat, sweep) == nil
end

function PlotService.Refresh(_self: any, player: Player, walkerLevel: number, income: number)
	local plot = byPlayer[player]
	if not plot then
		return
	end
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
		character:PivotTo(plot.Pieces.Spawn)
	end
end

return PlotService
