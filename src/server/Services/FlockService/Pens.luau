--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Wander = require(ReplicatedStorage.Utils.Wander)

type Sheep = Economy.Sheep

-- The sheep living in a plot: one model per sheep in the pen, put down where its owner chose and strolling about the
-- plot from there like Shear a Sheep's (Utils/Wander), with a small label over it (its income, and a lamb's growth).
-- The server picks every stroll and keeps where the sheep is along it (Position); the model itself only moves when it
-- is shown, grows or is rebuilt, and clients walk it from the Spot and WalkAt attributes (AnimController). Plain
-- functions over FlockService's per-player models.
local Pens = {}

export type Shown = {
	Model: Model,
	Scale: number,
	Adult: boolean,
	Label: TextLabel,
	Spot: CFrame, -- where it stands, or where the stroll it's on ends
	Walk: Wander.Walk?, -- the stroll it's on, on the server's clock (workspace:GetServerTimeNow())
	Position: Vector3, -- where it is now, along any stroll
	NextStroll: number, -- os.clock() it next thinks about strolling
}

-- What Pens asks of the plot: whether a sheep this wide can stand somewhere, and walk somewhere (PlotService).
export type Ground = {
	CanStand: (position: Vector3, radius: number) -> boolean,
	PathClear: (from: Vector3, to: Vector3, radius: number) -> boolean,
}

-- Lambs grow from their weight's size to this share of a Standard adult before their size shows.
local LAMB_GROWN_SHARE = 0.85
-- A sheep at rig scale 1 is about this many studs from its middle to its wool's edge, nose and tail included.
local RADIUS_PER_SCALE = 1.1
-- A sheep put down on another, or somewhere it can't stand, moves to the nearest clear spot on rings this many
-- SheepGaps out, this many spots a ring.
local LANDING_RINGS = 4
local LANDING_STEPS = 10
local FREE_SPOT_TRIES = 40

local Motion = GameConfig.SheepMotion
local random = Random.new()

function Pens.Scale(sheep: Sheep): number
	if Economy.IsAdult(sheep) then
		return Economy.Scale(sheep, GameConfig.SheepSize)
	end
	local start = Economy.LambScale(sheep.Weight)
	local share = math.clamp(sheep.Grown / Economy.GrowthSeconds(sheep), 0, 1)
	return GameConfig.SheepSize * (start + (LAMB_GROWN_SHARE - start) * share)
end

-- How far round its feet a sheep of `scale` reaches, for spacing and for what it can walk past.
function Pens.Radius(scale: number): number
	return RADIUS_PER_SCALE * scale
end

local function makeLabel(model: Model): TextLabel
	local root = model.PrimaryPart
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PenLabel"
	billboard.Size = UDim2.fromOffset(120, 34)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	billboard.MaxDistance = 70
	billboard.LightInfluence = 0
	billboard.Parent = root or model
	local words = Instance.new("TextLabel")
	words.BackgroundTransparency = 1
	words.Size = UDim2.fromScale(1, 1)
	words.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	words.TextScaled = true
	words.TextColor3 = Color3.fromRGB(190, 255, 90)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Parent = words
	words.Parent = billboard
	return words
end

function Pens.LabelText(sheep: Sheep): string
	local rate = `+{Format.Rate(Economy.Income(sheep))}/s`
	if Economy.IsAdult(sheep) then
		return rate
	end
	local share = math.clamp(sheep.Grown / Economy.GrowthSeconds(sheep), 0, 1)
	return `{rate}  {math.floor(share * 100)}%`
end

local function nextStroll(sheep: Sheep): number
	if Economy.IsAdult(sheep) then
		return os.clock() + random:NextNumber(Motion.StrollMinWait, Motion.StrollMaxWait)
	end
	return os.clock() + random:NextNumber(Motion.LambStrollMinWait, Motion.LambStrollMaxWait)
end

-- Puts it straight on `spot`, ending any stroll. Clients show the jump (or the hop, for a sheep just put down).
local function setSpot(shown: Shown, spot: CFrame)
	shown.Walk = nil
	shown.Spot = spot
	shown.Position = spot.Position
	shown.Model:SetAttribute("WalkAt", nil)
	shown.Model:SetAttribute("Spot", spot)
end

-- Where the sheep stands right now, along any stroll.
local function poseNow(shown: Shown, now: number): CFrame
	local walk = shown.Walk
	if walk then
		return (Wander.PoseAt(walk, now))
	end
	return shown.Spot
end

local function dress(model: Model, sheep: Sheep, ownerId: number, scale: number)
	model.Name = `Pen_{ownerId}_{sheep.Id}`
	model:SetAttribute("OwnerId", ownerId)
	model:SetAttribute("SheepId", sheep.Id)
	model:SetAttribute("Lamb", if Economy.IsAdult(sheep) then nil else true)
	model:SetAttribute("Radius", Pens.Radius(scale))
end

-- Stands a freshly built model on `at` (its feet, on the floor), at home there. `build` makes the model
-- (SheepService.Build). `from`, for a sheep arriving in the pen: where it hops in from (its carrier's head).
function Pens.Show(
	sheep: Sheep,
	at: CFrame,
	ownerId: number,
	folder: Instance,
	build: (string, number, number) -> Model?,
	from: CFrame?
): Shown?
	local scale = Pens.Scale(sheep)
	local model = build(sheep.Family, sheep.Rarity, scale)
	if not model then
		return nil
	end
	dress(model, sheep, ownerId, scale)
	model:PivotTo(at)
	if from then
		-- Before Spot, so a client that sees it arrive already knows it hops in.
		model:SetAttribute("DropFrom", from)
		model:SetAttribute("DroppedAt", workspace:GetServerTimeNow())
	end
	local label = makeLabel(model)
	label.Text = Pens.LabelText(sheep)
	local shown: Shown = {
		Model = model,
		Scale = scale,
		Adult = Economy.IsAdult(sheep),
		Label = label,
		Spot = at,
		Walk = nil,
		Position = at.Position,
		NextStroll = nextStroll(sheep),
	}
	setSpot(shown, at)
	model.Parent = folder
	return shown
end

-- Grows a lamb's model a little and updates its label; returns false when it needs rebuilding (it just grew up).
function Pens.Update(shown: Shown, sheep: Sheep, now: number): boolean
	if Economy.IsAdult(sheep) ~= shown.Adult then
		return false
	end
	local scale = Pens.Scale(sheep)
	if math.abs(scale - shown.Scale) > 0.02 then
		shown.Model:ScaleTo(scale)
		-- Where it really is now, so the move that replicates with the new size doesn't pull it back.
		shown.Model:PivotTo(poseNow(shown, now))
		shown.Model:SetAttribute("Radius", Pens.Radius(scale))
		shown.Scale = scale
	end
	shown.Label.Text = Pens.LabelText(sheep)
	return true
end

-- A new model for a sheep whose look changed (a lamb grown up), standing where the old one was; the old one goes.
function Pens.Rebuild(
	shown: Shown,
	sheep: Sheep,
	ownerId: number,
	folder: Instance,
	build: (string, number, number) -> Model?,
	now: number
): boolean
	local scale = Pens.Scale(sheep)
	local model = build(sheep.Family, sheep.Rarity, scale)
	if not model then
		return false
	end
	local at = poseNow(shown, now)
	dress(model, sheep, ownerId, scale)
	model:PivotTo(at)
	shown.Model:Destroy()
	shown.Model = model
	shown.Scale = scale
	shown.Adult = Economy.IsAdult(sheep)
	shown.Label = makeLabel(model)
	shown.Label.Text = Pens.LabelText(sheep)
	shown.NextStroll = nextStroll(sheep)
	setSpot(shown, at)
	model.Parent = folder
	return true
end

-- Whether `position` is too close to where another of the flock stands or is heading, for a sheep `radius` round.
local function crowded(flock: { [string]: Shown }, self: Shown?, position: Vector3, radius: number): boolean
	for _, other in flock do
		if other ~= self then
			local gap = math.max(Motion.SheepGap, radius + Pens.Radius(other.Scale))
			local flatSpot = Vector3.new(other.Spot.X - position.X, 0, other.Spot.Z - position.Z)
			local flatNow = Vector3.new(other.Position.X - position.X, 0, other.Position.Z - position.Z)
			if flatSpot.Magnitude < gap or flatNow.Magnitude < gap then
				return true
			end
		end
	end
	return false
end

local function fits(flock: { [string]: Shown }, ground: Ground, position: Vector3, radius: number): boolean
	return ground.CanStand(position, radius) and not crowded(flock, nil, position, radius)
end

-- Where a sheep of `scale` put down at `at` lands: there, or the nearest clear spot round it, so it doesn't land in a
-- tree, on the walker or on another sheep. Nil when nothing near is clear.
function Pens.Landing(flock: { [string]: Shown }, ground: Ground, at: CFrame, scale: number): CFrame?
	local radius = Pens.Radius(scale)
	if fits(flock, ground, at.Position, radius) then
		return at
	end
	for ring = 1, LANDING_RINGS do
		local distance = ring * Motion.SheepGap
		for step = 1, LANDING_STEPS do
			local angle = 2 * math.pi * (step + ring * 0.5) / LANDING_STEPS
			local spot = at + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
			if fits(flock, ground, spot.Position, radius) then
				return spot
			end
		end
	end
	return nil
end

-- A clear spot anywhere in the pen, from `pick` (a random point on the plot's floor inside the fence), or nil.
function Pens.FreeSpot(flock: { [string]: Shown }, ground: Ground, pick: () -> Vector3, scale: number): CFrame?
	local radius = Pens.Radius(scale)
	for _ = 1, FREE_SPOT_TRIES do
		local position = pick()
		if fits(flock, ground, position, radius) then
			return CFrame.new(position) * CFrame.Angles(0, random:NextNumber(0, 2 * math.pi), 0)
		end
	end
	return nil
end

-- Where a stroll from where it stands could end: inside the pen, off the walker, clear of the decor and the flock, or
-- nil if no roll fitted.
local function pickStroll(flock: { [string]: Shown }, shown: Shown, ground: Ground): CFrame?
	if random:NextNumber() < Motion.TurnAroundChance then
		return Wander.TurnAround(shown.Spot, random:NextNumber())
	end
	local radius = Pens.Radius(shown.Scale)
	for _ = 1, Motion.StrollTries do
		local spot = Wander.Stroll(shown.Spot, random:NextNumber(), random:NextNumber())
		if
			not crowded(flock, shown, spot.Position, radius)
			and ground.CanStand(spot.Position, radius)
			and ground.PathClear(shown.Spot.Position, spot.Position, radius)
		then
			return spot
		end
	end
	return nil
end

-- One pass over a flock: moves every strolling sheep's position along its way, and sets off the ones whose standing
-- about is over. Two attributes per stroll; every client walks it.
function Pens.Wander(flock: { [string]: Shown }, sheepById: { [string]: Sheep }, ground: Ground, now: number)
	local clock = os.clock()
	for id, shown in flock do
		local walk = shown.Walk
		if walk then
			local pose, done = Wander.PoseAt(walk, now)
			shown.Position = pose.Position
			if done then
				shown.Walk = nil
				local sheep = sheepById[id]
				shown.NextStroll = if random:NextNumber() < Motion.ChainChance
					then clock + random:NextNumber(Motion.ChainPauseMin, Motion.ChainPauseMax)
					elseif sheep then nextStroll(sheep)
					else clock + Motion.StrollMaxWait
			end
			continue
		end
		if clock < shown.NextStroll then
			continue
		end
		local sheep = sheepById[id]
		shown.NextStroll = if sheep then nextStroll(sheep) else clock + Motion.StrollMaxWait
		local spot = pickStroll(flock, shown, ground)
		if spot then
			shown.Walk = Wander.Plan(shown.Spot, spot, now)
			shown.Spot = spot
			shown.Model:SetAttribute("WalkAt", now)
			shown.Model:SetAttribute("Spot", spot)
		end
	end
end

return table.freeze(Pens)
