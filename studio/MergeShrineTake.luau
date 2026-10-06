--!strict
-- The Merge Shrine mock-up video's take (2026-10-05, the user asked for it): the merge played on the client, the
-- reference for the real effect. Run studio/MergeShrineMockup.luau in Edit, Play, remove workspace.Stations'
-- MergeShrine and MergeStation on the server (the old shrine stands on the same spot), then run this in a Client
-- execute_luau and call _G.ShrineTake(delay). It puts everything back afterwards, so takes repeat.
-- The beats: the three sheep shrink into balls of gold light (1 s), fly together over the altar and merge into one
-- (0.8 s + a 0.35 s pulse), the ball rises (1 s) on a pole of light that grows up from the altar under it while the
-- orb forms at the top, the orb flashes and gives way to the lamb, which pops out (0.35 s), hangs there a beat with a
-- spin (0.7 s) and drops onto the altar (0.3 s, a squash). The pole and the orb exist only during the merge (the user,
-- 2026-10-05): they vanish at the pop, and the shrine stands without them otherwise.
-- The character walks up, lifts it with the game's carry pose (CarryPose + the CarriedFamily/CarriedScale
-- attributes CarryController reads) and carries it away.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CarryPose = require(ReplicatedStorage.Utils.CarryPose)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local ORIGIN = CFrame.new(287, 59.46, 245) * CFrame.Angles(0, math.rad(90), 0)
local FLOOR = 3
local GOLD = Color3.fromRGB(255, 196, 60)
local SPARK = Color3.fromRGB(255, 230, 140)
local LAMB = 1.25
local START = Vector3.new(274, 63, 252)
local VIA = Vector3.new(278, 63, 247.5)
local AT_ALTAR = Vector3.new(283.4, 63, 245)
local OUT = Vector3.new(268, 63, 251)
local BEAM_TRANSPARENCY = 0.45

local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end

local function backOut(t: number): number
	local c = 2.2
	return 1 + (c + 1) * (t - 1) ^ 3 + c * (t - 1) ^ 2
end

local function tween(duration: number, step: (number) -> ())
	local started = os.clock()
	while true do
		local alpha = math.min((os.clock() - started) / duration, 1)
		step(alpha)
		if alpha >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end
end

local function ball(size: number, position: Vector3): Part
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = GOLD
	part.Size = Vector3.one * size
	part.CFrame = CFrame.new(position)
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 12
	light.Brightness = 2.5
	light.Parent = part
	local trail = Instance.new("ParticleEmitter")
	trail.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	trail.Rate = 30
	trail.Lifetime = NumberRange.new(0.4, 0.7)
	trail.Speed = NumberRange.new(0.5, 1.5)
	trail.SpreadAngle = Vector2.new(180, 180)
	trail.Color = ColorSequence.new(SPARK)
	trail.LightEmission = 1
	trail.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	trail.Parent = part
	part.Parent = workspace
	return part
end

local function burst(position: Vector3, count: number, speed: number, size: number?)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.CFrame = CFrame.new(position)
	holder.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Color = ColorSequence.new(SPARK)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 1.2), NumberSequenceKeypoint.new(1, 0) })
	emitter.Parent = holder
	emitter:Emit(count)
	task.delay(2, function()
		holder:Destroy()
	end)
end

local function walk(humanoid: Humanoid, target: Vector3, timeout: number)
	humanoid:MoveTo(target)
	local arrived = false
	local connection = humanoid.MoveToFinished:Connect(function()
		arrived = true
	end)
	local started = os.clock()
	while not arrived and os.clock() - started < timeout do
		RunService.RenderStepped:Wait()
	end
	connection:Disconnect()
end

type Saved = { Model: Model, Scale: number, Pivot: CFrame, Centre: Vector3 }

local function take(delay: number)
	local player = Players.LocalPlayer
	local character = player.Character :: Model
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local shrine = workspace:FindFirstChild("TEMP_ShrineC") :: Model
	local orb = shrine:FindFirstChild("Orb") :: Part
	local beam = shrine:FindFirstChild("Beam") :: Part?
	local saved: { Saved } = {}
	for _, child in shrine:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Family") then
			local box = child:GetBoundingBox()
			table.insert(saved, { Model = child, Scale = child:GetScale(), Pivot = child:GetPivot(), Centre = box.Position })
		end
	end
	character:PivotTo(CFrame.lookAt(START, Vector3.new(AT_ALTAR.X, START.Y, AT_ALTAR.Z)))
	local orbSize, orbColor = orb.Size, orb.Color
	local beamSize = if beam then beam.Size else Vector3.new(0.6, 10.6, 0.6)
	local beamCFrame = if beam then beam.CFrame else CFrame.new()
	local altarTopY = (ORIGIN * CFrame.new(0, FLOOR + 1.9, 0)).Position.Y
	local glow = orb:FindFirstChildWhichIsA("PointLight")
	local mergeAt = (ORIGIN * CFrame.new(0, FLOOR + 6.5, 0)).Position
	local topAt = orb.Position
	local facing = ORIGIN.Rotation * CFrame.Angles(0, math.rad(200), 0)
	local altarAt = CFrame.new((ORIGIN * CFrame.new(0, FLOOR + 1.9, 0)).Position) * facing
	local topCFrame = CFrame.new(topAt - Vector3.new(0, 1.2, 0)) * facing

	task.wait(delay + 0.8)
	-- The three shrink into balls of light.
	local balls: { Part } = {}
	for index, sheep in saved do
		balls[index] = ball(0.3, sheep.Centre)
	end
	tween(1.0, function(alpha)
		local eased = smooth(alpha)
		for index, sheep in saved do
			sheep.Model:ScaleTo(math.max(sheep.Scale * (1 - eased), 0.03))
			sheep.Model:PivotTo(sheep.Pivot)
			balls[index].Size = Vector3.one * (0.3 + 1.9 * eased)
		end
	end)
	for _, sheep in saved do
		sheep.Model.Parent = nil
	end
	-- They fly together over the altar and merge into one.
	local from: { Vector3 } = {}
	for index, light in balls do
		from[index] = light.Position
	end
	tween(0.8, function(alpha)
		local eased = smooth(alpha)
		for index, light in balls do
			light.CFrame = CFrame.new(from[index]:Lerp(mergeAt, eased) + Vector3.new(0, math.sin(eased * math.pi) * 2.5, 0))
		end
	end)
	for index = 2, #balls do
		balls[index]:Destroy()
	end
	local one = balls[1]
	burst(mergeAt, 35, 7)
	tween(0.35, function(alpha)
		one.Size = Vector3.one * (2.2 + 1.6 * math.sin(alpha * math.pi) + 1.0 * alpha)
	end)
	-- It rises on a pole of light growing up from the altar, and the orb forms at the top as it arrives.
	if glow then
		glow.Enabled = true
	end
	orb.Size = Vector3.one * 0.2
	tween(1.0, function(alpha)
		local at = mergeAt:Lerp(topAt, smooth(alpha))
		one.CFrame = CFrame.new(at)
		if beam then
			local height = math.max(at.Y - altarTopY, 0.05)
			beam.Transparency = BEAM_TRANSPARENCY + (1 - BEAM_TRANSPARENCY) * math.max(1 - alpha * 5, 0)
			beam.Size = Vector3.new(beamSize.X, height, beamSize.Z)
			beam.CFrame = CFrame.new(beamCFrame.Position.X, altarTopY + height / 2, beamCFrame.Position.Z)
		end
		local forming = math.clamp((alpha - 0.4) / 0.6, 0, 1)
		orb.Transparency = 1 - forming
		orb.Size = Vector3.one * (0.2 + (orbSize.X - 0.2) * smooth(forming))
	end)
	-- The orb flashes and gives way to the lamb; the pole goes with it.
	orb.Color = GOLD
	tween(0.3, function(alpha)
		orb.Size = orbSize * (1 + 0.9 * math.sin(alpha * math.pi))
		one.Size = Vector3.one * math.max(3.2 * (1 - alpha), 0.05)
	end)
	one:Destroy()
	orb.Transparency = 1
	if glow then
		glow.Enabled = false
	end
	if beam then
		beam.Transparency = 1
	end
	local looks = ReplicatedStorage:FindFirstChild("SheepLooks") :: Folder
	local lamb = (looks:FindFirstChild("Sun") :: Model):Clone()
	lamb.Name = "TEMP_TakeLamb"
	lamb:ScaleTo(0.05)
	lamb:PivotTo(topCFrame)
	lamb.Parent = workspace
	burst(topAt, 70, 15, 1.7)
	tween(0.35, function(alpha)
		lamb:ScaleTo(math.max(0.05 + (LAMB - 0.05) * backOut(alpha), 0.05))
		lamb:PivotTo(topCFrame)
	end)
	tween(0.7, function(alpha)
		lamb:PivotTo(topCFrame * CFrame.new(0, math.sin(alpha * math.pi) * 0.5, 0) * CFrame.Angles(0, alpha * math.pi * 2, 0))
	end)
	-- It drops quickly back onto the altar.
	tween(0.3, function(alpha)
		lamb:PivotTo(topCFrame:Lerp(altarAt, alpha * alpha))
	end)
	burst(altarAt.Position, 30, 8)
	tween(0.2, function(alpha)
		lamb:ScaleTo(LAMB * (1 - 0.2 * math.sin(alpha * math.pi)))
		lamb:PivotTo(altarAt)
	end)
	orb.Size = orbSize
	orb.Color = orbColor
	if beam then
		beam.Size = beamSize
		beam.CFrame = beamCFrame
	end
	task.wait(0.35)
	-- The player walks up, lifts it overhead and carries it home.
	walk(humanoid, VIA, 2)
	walk(humanoid, AT_ALTAR, 3)
	root.CFrame = CFrame.lookAt(root.Position, Vector3.new(287, root.Position.Y, 245))
	task.wait(0.25)
	local breed = table.clone(GameConfig.Breeds.Sun)
	breed.Scale = lamb:GetScale() * GameConfig.SheepSize
	local holder, at = CarryPose.HoldSpot(character, root, breed)
	for _, descendant in lamb:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.Massless = true
			descendant.CanCollide = false
		end
	end
	local lambRoot = lamb.PrimaryPart :: BasePart
	local weld = Instance.new("Weld")
	weld.Part0 = holder
	weld.Part1 = lambRoot
	weld.C0 = at * lambRoot.PivotOffset:Inverse()
	weld.Parent = lambRoot
	lamb:PivotTo(holder.CFrame * at)
	player:SetAttribute("CarriedFamily", "Sun")
	player:SetAttribute("CarriedScale", lamb:GetScale())
	task.wait(0.8)
	walk(humanoid, OUT, 2.5)
	task.wait(1.5)
	-- Back to the start for the next take.
	player:SetAttribute("CarriedFamily", nil)
	player:SetAttribute("CarriedScale", nil)
	lamb:Destroy()
	for _, sheep in saved do
		sheep.Model.Parent = shrine
		sheep.Model:ScaleTo(sheep.Scale)
		sheep.Model:PivotTo(sheep.Pivot)
	end
	character:PivotTo(CFrame.lookAt(START, Vector3.new(AT_ALTAR.X, START.Y, AT_ALTAR.Z)))
end

(_G :: any).ShrineTake = take
return "call _G.ShrineTake(delay)"
