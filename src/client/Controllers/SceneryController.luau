--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- High Olympus's scenery moving on this device: islands, clouds and dream shapes bob, cogs and Nemesis's wheel turn,
-- flocks of birds circle and flap. tools/UpperMountain.luau tags them (OlympusBob, OlympusSpin, OlympusFlock) with
-- their numbers as attributes. Only what's near the camera moves, in one BulkMoveTo a frame; the server's copies stay
-- where they were built (a cog turns in place, so its footprint is the same). Reduce motion holds everything still.
local SceneryController = { Name = "SceneryController" }

type Kind = string -- "Bob", "Spin" or "Flock"
type Mover = {
	Kind: Kind,
	Parts: { BasePart },
	-- Each part relative to the mover's frame at rest (a wing: relative to its bird's body).
	Rest: { CFrame },
	-- A flock's wings: which side, and their body relative to the flock's frame at rest.
	Sides: { [number]: number },
	Bodies: { [number]: CFrame },
	Center: Vector3,
	Axis: Vector3,
	Speed: number, -- radians a second
	Height: number,
	Period: number,
	Radius: number,
	Phase: number,
}

local TAGS: { [string]: Kind } =
	{ OlympusBob = "Bob" :: Kind, OlympusSpin = "Spin" :: Kind, OlympusFlock = "Flock" :: Kind }
local RANGE = 600 -- studs from the camera within which scenery moves
local FLAP_RATE = 2.2 -- wing beats a second
local FLAP_ANGLE = math.rad(28)

local trove = Trove.new()
local movers: { [Instance]: Mover } = {}
local moveParts: { BasePart } = {}
local moveFrames: { CFrame } = {}

local function partsOf(instance: Instance): { BasePart }
	local list: { BasePart } = {}
	if instance:IsA("BasePart") then
		table.insert(list, instance)
	end
	for _, item in instance:GetDescendants() do
		if item:IsA("BasePart") then
			table.insert(list, item)
		end
	end
	return list
end

-- Where a flock is on its circle after turning `angle`, facing the way it flies (as the builder laid it out).
local function flockFrame(mover: Mover, angle: number): CFrame
	return CFrame.new(mover.Center)
		* CFrame.Angles(0, angle, 0)
		* CFrame.new(mover.Radius, 0, 0)
		* CFrame.Angles(0, if mover.Speed > 0 then math.pi else 0, 0)
end

local function number(instance: Instance, name: string, fallback: number): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else fallback
end

local function vector(instance: Instance, name: string): Vector3?
	local value = instance:GetAttribute(name)
	return if typeof(value) == "Vector3" then value else nil
end

local function add(instance: Instance, kind: Kind)
	if movers[instance] then
		return
	end
	local parts = partsOf(instance)
	if #parts == 0 then
		return
	end
	local sum = Vector3.zero
	for _, part in parts do
		sum += part.Position
	end
	local mover: Mover = {
		Kind = kind,
		Parts = parts,
		Rest = {},
		Sides = {},
		Bodies = {},
		Center = sum / #parts,
		Axis = Vector3.yAxis,
		Speed = 0,
		Height = number(instance, "BobHeight", 2),
		Period = math.max(number(instance, "BobPeriod", 8), 0.5),
		Radius = number(instance, "FlockRadius", 30),
		-- Neighbours start out of step.
		Phase = (sum.X * 0.37 + sum.Z * 0.71) / #parts % (math.pi * 2),
	}
	if kind == "Bob" then
		for index, part in parts do
			mover.Rest[index] = part.CFrame
		end
	elseif kind == "Spin" then
		mover.Center = vector(instance, "SpinCenter") or mover.Center
		mover.Axis = (vector(instance, "SpinAxis") or Vector3.yAxis).Unit
		mover.Speed = math.rad(number(instance, "SpinSpeed", 20))
		local inverse = CFrame.new(mover.Center):Inverse()
		for index, part in parts do
			mover.Rest[index] = inverse * part.CFrame
		end
	else
		mover.Center = vector(instance, "FlockCenter") or mover.Center
		mover.Speed = math.rad(number(instance, "FlockSpeed", 14))
		local inverse = flockFrame(mover, 0):Inverse()
		for index, part in parts do
			local side = if part.Name == "WingL" then -1 elseif part.Name == "WingR" then 1 else nil
			local body = part.Parent and part.Parent:FindFirstChild("Body")
			if side and body and body:IsA("BasePart") then
				mover.Sides[index] = side
				mover.Bodies[index] = inverse * body.CFrame
				mover.Rest[index] = body.CFrame:Inverse() * part.CFrame
			else
				mover.Rest[index] = inverse * part.CFrame
			end
		end
	end
	movers[instance] = mover
end

local function step()
	if PlayerSettings.ReduceMotion() then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local now = os.clock()
	table.clear(moveParts)
	table.clear(moveFrames)
	for _, mover in movers do
		if (mover.Center - eye).Magnitude > RANGE then
			continue
		end
		local parts, rest = mover.Parts, mover.Rest
		if mover.Kind == "Bob" then
			local lift = Vector3.new(0, math.sin(now * math.pi * 2 / mover.Period + mover.Phase) * mover.Height, 0)
			for index, part in parts do
				table.insert(moveParts, part)
				table.insert(moveFrames, rest[index] + lift)
			end
		elseif mover.Kind == "Spin" then
			local turn = CFrame.new(mover.Center) * CFrame.fromAxisAngle(mover.Axis, mover.Speed * now)
			for index, part in parts do
				table.insert(moveParts, part)
				table.insert(moveFrames, turn * rest[index])
			end
		else
			local frame = flockFrame(mover, mover.Speed * now + mover.Phase)
			local flap = math.sin(now * math.pi * 2 * FLAP_RATE + mover.Phase) * FLAP_ANGLE
			for index, part in parts do
				local side = mover.Sides[index]
				table.insert(moveParts, part)
				if side then
					table.insert(
						moveFrames,
						frame * mover.Bodies[index] * CFrame.Angles(0, 0, side * flap) * rest[index]
					)
				else
					table.insert(moveFrames, frame * rest[index])
				end
			end
		end
	end
	if #moveParts > 0 then
		workspace:BulkMoveTo(moveParts, moveFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function SceneryController.Init(_self: any, _systems: Lifecycle.Registry) end

function SceneryController.Start(_self: any)
	-- After the map has arrived: a mover is measured from its parts once.
	trove:Add(task.spawn(function()
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		for tag, kind in TAGS do
			for _, instance in CollectionService:GetTagged(tag) do
				add(instance, kind)
			end
			trove:Connect(CollectionService:GetInstanceAddedSignal(tag), function(instance: Instance)
				task.defer(add, instance, kind)
			end)
			trove:Connect(CollectionService:GetInstanceRemovedSignal(tag), function(instance: Instance)
				movers[instance] = nil
			end)
		end
		trove:Connect(RunService.RenderStepped, step)
	end))
end

function SceneryController.Destroy(_self: any)
	trove:Clean()
	table.clear(movers)
end

return SceneryController
