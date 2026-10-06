--!strict

local RunService = game:GetService("RunService")

-- The merge as the user approved it in the mock-up video (studio/MergeShrineTake.luau, 2026-10-05): the three sheep
-- shrink into balls of gold light (1 s), fly together over the altar and merge into one (0.8 s and a pulse), the ball
-- rises (1 s) on a pole of light growing up from the altar while the orb forms at the top, the orb flashes and gives
-- way to the lamb, which pops out, hangs there a beat with a spin and drops onto the altar. The pole and the orb exist
-- only during it. About GameConfig.Shrine.MergeSeconds from start to landing. Everything here is this device's own.
local Show = {}

export type Pieces = {
	Shrine: Model,
	Sheep: { Model }, -- the three on their pedestals
	Lamb: Model, -- the lamb to pop out, its scale already set; Show parents and places it
	LambScale: number,
	Sparkle: Color3, -- the lamb's fleece: white-gold, blue for Rare, gold for Royal
	Beat: (name: string) -> (), -- "Merge", "Rise", "Pop" and "Land", for the sounds
}

local GOLD = Color3.fromRGB(255, 196, 60)
local SPARK = Color3.fromRGB(255, 230, 140)
local BEAM_TRANSPARENCY = 0.45
local MERGE_HEIGHT = 4.6 -- where the three meet, above the altar's top
local LAMB_DROP = 1.2 -- the lamb pops out this far under the orb's centre

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

local function light(size: number, position: Vector3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = "MergeLight"
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = GOLD
	part.Size = Vector3.one * size
	part.CFrame = CFrame.new(position)
	local glow = Instance.new("PointLight")
	glow.Color = GOLD
	glow.Range = 12
	glow.Brightness = 2.5
	glow.Parent = part
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
	part.Parent = parent
	return part
end

local function burst(position: Vector3, count: number, speed: number, color: Color3, size: number, parent: Instance)
	local holder = Instance.new("Part")
	holder.Name = "MergeBurst"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.CFrame = CFrame.new(position)
	holder.Parent = parent
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	emitter.Parent = holder
	emitter:Emit(count)
	task.delay(2, function()
		holder:Destroy()
	end)
end

-- Where the lamb rests on the altar: its top, the lamb facing the shrine's front.
function Show.AltarSpot(shrine: Model): CFrame?
	local altar = shrine:FindFirstChild("Altar")
	if not altar or not altar:IsA("BasePart") then
		return nil
	end
	local top = (altar.CFrame * CFrame.new(0, altar.Size.Y / 2, 0)).Position
	return CFrame.new(top) * altar.CFrame.Rotation * CFrame.Angles(0, math.rad(200), 0)
end

-- Plays the merge and yields until the lamb has landed on the altar (where it stays, parented to `parent`).
function Show.Play(pieces: Pieces, parent: Instance)
	local shrine = pieces.Shrine
	local orb = shrine:FindFirstChild("Orb")
	local beam = shrine:FindFirstChild("Beam")
	local altarAt = Show.AltarSpot(shrine)
	if not orb or not orb:IsA("BasePart") or not altarAt then
		return
	end
	local glow = orb:FindFirstChildWhichIsA("PointLight")
	local orbSize, orbColor = orb.Size, orb.Color
	local altarTopY = altarAt.Position.Y
	local beamPart = if beam and beam:IsA("BasePart") then beam else nil
	local beamSize = if beamPart then beamPart.Size else Vector3.new(0.6, 10, 0.6)
	local beamAt = if beamPart then beamPart.CFrame else CFrame.new()
	local mergeAt = altarAt.Position + Vector3.new(0, MERGE_HEIGHT, 0)
	local topAt = orb.Position
	local topCFrame = CFrame.new(topAt - Vector3.new(0, LAMB_DROP, 0)) * altarAt.Rotation

	-- The three shrink into balls of light.
	local starts: { { Model: Model, Scale: number, Pivot: CFrame } } = {}
	local balls: { Part } = {}
	for index, sheep in pieces.Sheep do
		local box = sheep:GetBoundingBox()
		starts[index] = { Model = sheep, Scale = sheep:GetScale(), Pivot = sheep:GetPivot() }
		balls[index] = light(0.3, box.Position, parent)
	end
	tween(1.0, function(alpha)
		local eased = smooth(alpha)
		for index, start in starts do
			start.Model:ScaleTo(math.max(start.Scale * (1 - eased), 0.03))
			start.Model:PivotTo(start.Pivot)
			balls[index].Size = Vector3.one * (0.3 + 1.9 * eased)
		end
	end)
	for _, start in starts do
		start.Model:Destroy()
	end
	if #balls == 0 then
		table.insert(balls, light(2.2, mergeAt, parent))
	end

	-- They fly together over the altar and merge into one.
	local from: { Vector3 } = {}
	for index, ball in balls do
		from[index] = ball.Position
	end
	tween(0.8, function(alpha)
		local eased = smooth(alpha)
		for index, ball in balls do
			ball.CFrame =
				CFrame.new(from[index]:Lerp(mergeAt, eased) + Vector3.new(0, math.sin(eased * math.pi) * 2.5, 0))
		end
	end)
	for index = 2, #balls do
		balls[index]:Destroy()
	end
	local one = balls[1]
	pieces.Beat("Merge")
	burst(mergeAt, 35, 7, SPARK, 1.2, parent)
	tween(0.35, function(alpha)
		one.Size = Vector3.one * (2.2 + 1.6 * math.sin(alpha * math.pi) + 1.0 * alpha)
	end)

	-- It rises on a pole of light growing up from the altar; the orb forms at the top as it arrives.
	if glow then
		glow.Enabled = true
	end
	pieces.Beat("Rise")
	orb.Size = Vector3.one * 0.2
	tween(1.0, function(alpha)
		local at = mergeAt:Lerp(topAt, smooth(alpha))
		one.CFrame = CFrame.new(at)
		if beamPart then
			local height = math.max(at.Y - altarTopY, 0.05)
			beamPart.Transparency = BEAM_TRANSPARENCY + (1 - BEAM_TRANSPARENCY) * math.max(1 - alpha * 5, 0)
			beamPart.Size = Vector3.new(beamSize.X, height, beamSize.Z)
			beamPart.CFrame = CFrame.new(beamAt.Position.X, altarTopY + height / 2, beamAt.Position.Z)
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
	orb.Size = orbSize
	orb.Color = orbColor
	if glow then
		glow.Enabled = false
	end
	if beamPart then
		beamPart.Transparency = 1
		beamPart.Size = beamSize
		beamPart.CFrame = beamAt
	end
	local lamb = pieces.Lamb
	local scale = pieces.LambScale
	lamb:ScaleTo(0.05)
	lamb:PivotTo(topCFrame)
	lamb.Parent = parent
	pieces.Beat("Pop")
	burst(topAt, 70, 15, pieces.Sparkle, 1.7, parent)
	tween(0.35, function(alpha)
		lamb:ScaleTo(math.max(0.05 + (scale - 0.05) * backOut(alpha), 0.05))
		lamb:PivotTo(topCFrame)
	end)
	tween(0.7, function(alpha)
		lamb:PivotTo(
			topCFrame * CFrame.new(0, math.sin(alpha * math.pi) * 0.5, 0) * CFrame.Angles(0, alpha * math.pi * 2, 0)
		)
	end)

	-- It drops quickly back onto the altar.
	tween(0.3, function(alpha)
		lamb:PivotTo(topCFrame:Lerp(altarAt, alpha * alpha))
	end)
	pieces.Beat("Land")
	burst(altarAt.Position, 30, 8, pieces.Sparkle, 1.2, parent)
	tween(0.2, function(alpha)
		lamb:ScaleTo(scale * (1 - 0.2 * math.sin(alpha * math.pi)))
		lamb:PivotTo(altarAt)
	end)
end

return Show
