--!strict
-- Mock-up of mystery lambs (2026-10-06, not the game's code): wild lambs as plain lambs with no wool, marked in the
-- colours of the sheep they'll grow into, the markings bolder the rarer the family, the size and plumpness from the
-- hidden weight. Run in Edit with execute_luau: it builds workspace.TEMP_LambMockup in Pan's pasture and returns the
-- camera spots for screen_capture. Set MODE at the bottom; "Clear" deletes it all. Nothing here is saved anywhere else.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local SheepService = ServerScriptService:WaitForChild("Services"):WaitForChild("SheepService")
local Looks = require(SheepService:WaitForChild("Looks")) :: any
local Extras = require(SheepService:WaitForChild("Extras")) :: any
local Economy = require(ReplicatedStorage.Utils.Economy) :: any
local Format = require(ReplicatedStorage.Utils.Format) :: any
local GameConfig = require(ReplicatedStorage.Config.GameConfig) :: any
local Herds = require(ReplicatedStorage.Config.Herds) :: any
local Mountain = require(ReplicatedStorage.Utils.Mountain) :: any
local Theme = require(ReplicatedStorage.Config.Theme) :: any

local rgb = Color3.fromRGB
local COAT = rgb(250, 248, 242)
local COAT_FACE = rgb(248, 238, 226)
local EAR_INNER = rgb(250, 186, 186)

local assets = ServerStorage:WaitForChild("Assets")
local kit = Looks.new(assets:FindFirstChild("SheepAddons"))

local FOLDER = "TEMP_LambMockup"
local folder: Folder

local function fresh(): Model
	local model = (assets:WaitForChild("SheepRig") :: Model):Clone()
	model:PivotTo(CFrame.identity)
	return model
end

local function settle(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
end

local function sparkle(model: Model, color: Color3, rate: number)
	local body = model:FindFirstChild("Body")
	if not body then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(0.6, 1)
	emitter.Speed = NumberRange.new(1, 2.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = body
end

-- The family's adult exactly as SheepService builds it.
local function adult(family: string, fleece: number, scale: number): Model
	local base = GameConfig.Breeds[family]
	local model = fresh()
	local breed = table.clone(base)
	breed.Scale = 1
	Looks.Dress(kit, model, breed)
	Looks.Paint(model, breed, if fleece >= 3 then "Gold" else base.Mutation)
	if base.Extra then
		Extras.Add(model, base.Extra)
	end
	if base.Extras then
		for _, e in base.Extras do
			Extras.Add(model, e.Kind, e.Color)
		end
	end
	if fleece == 2 then
		sparkle(model, rgb(140, 200, 255), 4)
	elseif fleece >= 3 then
		sparkle(model, rgb(255, 214, 90), 8)
	end
	Looks.Studs(model)
	model:ScaleTo(scale)
	return model
end

local function distance(a: Color3, b: Color3): number
	local dr, dg, db = (a.R - b.R) * 255, (a.G - b.G) * 255, (a.B - b.B) * 255
	return math.sqrt(dr * dr + dg * dg + db * db)
end

-- The adult's two main colours that aren't lamb white, by how much of the sheep wears them. The shorn body under the
-- fleece and the ears' pink insides don't count.
local SKIPPED = { Root = true, Body = true, EarInnerL = true, EarInnerR = true }

-- White, and the creams and beiges most sheep's faces and legs share: no hint on a white lamb.
local function isPlain(color: Color3): boolean
	if distance(color, COAT) < 45 then
		return true
	end
	local h, sat, v = color:ToHSV()
	return sat < 0.3 and v > 0.82 and h > 20 / 360 and h < 60 / 360
end
local hintCache: { [string]: { Color3 } } = {}
local function hintColors(family: string): (Color3, Color3)
	local cached = hintCache[family]
	if cached then
		return cached[1], cached[2]
	end
	local model = adult(family, 1, 1)
	local buckets: { { Color: Color3, Area: number } } = {}
	for _, d in model:GetDescendants() do
		if not d:IsA("BasePart") or d.Transparency > 0.6 or SKIPPED[d.Name] then
			continue
		end
		local s = d.Size
		local area = s.X * s.Y + s.Y * s.Z + s.X * s.Z
		local color = d.Color
		if isPlain(color) then
			continue
		end
		local found = nil
		for _, bucket in buckets do
			if distance(bucket.Color, color) < 40 then
				found = bucket
				break
			end
		end
		if found then
			found.Area += area
		else
			table.insert(buckets, { Color = color, Area = area })
		end
	end
	model:Destroy()
	table.sort(buckets, function(a, b)
		return a.Area > b.Area
	end)
	local first = if buckets[1] then buckets[1].Color else rgb(206, 200, 190)
	local second = nil
	for index = 2, #buckets do
		if distance(buckets[index].Color, first) > 70 then
			second = buckets[index].Color
			break
		end
	end
	if not second then
		local h, s, v = first:ToHSV()
		second = Color3.fromHSV(h, math.min(1, s * 1.1), v * 0.7)
	end
	hintCache[family] = { first, second :: Color3 }
	return first, second :: Color3
end

-- A lamb's size from its hidden weight: light ones small and slim, heavy ones bigger and rounder. Most wild lambs weigh
-- 1-1.1, so the curve spreads that range out.
local function lambScale(weight: number): number
	local t = math.clamp((weight - 1) / 0.5, 0, 1)
	return 0.55 + 0.33 * math.sqrt(t)
end
-- A lamb in the pen grows by this share of its starting size by the time it's grown, keeping its weight's hint.
local GROW_SHARE = 0.6

local function plumpness(weight: number): number
	return 0.92 + 0.38 * math.sqrt(math.clamp((weight - 1) / 0.5, 0, 1))
end

-- Turns the add-on horns into a lamb's buds: each side's pieces shrink towards the piece nearest the head.
local function budHorns(model: Model, factor: number)
	local head = model:FindFirstChild("Head") :: BasePart?
	local addons = model:FindFirstChild("Addons")
	if not head or not addons then
		return
	end
	for _, side in { -1, 1 } do
		local parts: { BasePart } = {}
		for _, d in addons:GetDescendants() do
			local tint = d:GetAttribute("Tint")
			if d:IsA("BasePart") and (tint == "Horn" or tint == "HornBand") then
				local localX = head.CFrame:PointToObjectSpace(d.Position).X
				if (localX >= 0) == (side > 0) then
					table.insert(parts, d)
				end
			end
		end
		local anchor: Vector3? = nil
		local best = math.huge
		for _, p in parts do
			local gap = (p.Position - head.Position).Magnitude
			if gap < best then
				best = gap
				anchor = p.Position
			end
		end
		if not anchor then
			continue
		end
		for _, p in parts do
			local at = (anchor :: Vector3) + (p.Position - (anchor :: Vector3)) * factor
			p.Size *= factor
			p.CFrame = CFrame.new(at) * p.CFrame.Rotation
			local weld = p:FindFirstChildOfClass("Weld")
			if weld and weld.Part0 then
				weld.C0 = weld.Part0.CFrame:ToObjectSpace(p.CFrame)
				weld.C1 = CFrame.identity
			end
		end
	end
end

-- A round patch on a piece (the body unless `pieceName` says), `dir` its direction from the piece's centre in its space
-- (+X its right, +Y up, -Z the head), `width` and `height` as shares of the piece's size.
local function patch(model: Model, dir: Vector3, width: number, height: number, color: Color3, pieceName: string?)
	local body = model:FindFirstChild(pieceName or "Body") :: BasePart?
	if not body then
		return
	end
	local half = body.Size / 2 * Vector3.new(0.97, 0.95, 0.95)
	local d = dir.Unit
	local t = 1 / math.sqrt((d.X / half.X) ^ 2 + (d.Y / half.Y) ^ 2 + (d.Z / half.Z) ^ 2)
	local p = d * t
	local n = Vector3.new(p.X / half.X ^ 2, p.Y / half.Y ^ 2, p.Z / half.Z ^ 2).Unit
	local span = (body.Size.X + body.Size.Z) / 2
	local depth = span * 0.12
	local spot = Instance.new("Part")
	spot.Name = "Marking"
	spot.Size = Vector3.new(span * width, span * height, depth)
	spot.Color = color
	spot.Material = Enum.Material.SmoothPlastic
	spot.TopSurface = Enum.SurfaceType.Smooth
	spot.BottomSurface = Enum.SurfaceType.Smooth
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = spot
	local up = if math.abs(n.Y) > 0.9 then Vector3.new(0, 0, -1) else Vector3.yAxis
	spot.CFrame = body.CFrame * CFrame.lookAt(p - n * depth * 0.38, p + n, up)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = spot
	weld.Parent = spot
	spot.Parent = model
end

-- A soft, uneven patch: three overlapping rounds around `dir`.
local function blob(model: Model, dir: Vector3, size: number, color: Color3)
	local d = dir.Unit
	local side = d:Cross(Vector3.yAxis)
	if side.Magnitude < 0.1 then
		side = Vector3.xAxis
	end
	side = side.Unit
	local up = side:Cross(d).Unit
	patch(model, d, size, size * 0.85, color)
	patch(model, d + side * size * 0.55 + up * size * 0.2, size * 0.7, size * 0.6, color)
	patch(model, d - side * size * 0.45 - up * size * 0.3, size * 0.6, size * 0.55, color)
end

local LEFT, RIGHT, BACK, REAR = Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)

-- The markings by the family's rarity, plainest first, from Shear a Sheep's basic breeds: a Farm lamb's couple of
-- spots, socks and ear tips, a Jacob's patches, patches with socks and ears, a Soay's coloured coat with spots, and the
-- Mythic's two-tone coat with a soft glow. The face always stays a lamb's.
local function markBold(model: Model, rarity: number, first: Color3, second: Color3): { [string]: Color3 }
	local paint: { [string]: Color3 } = {}
	if rarity == 1 then
		patch(model, Vector3.new(-1, 0.55, -0.1), 0.3, 0.27, first)
		patch(model, Vector3.new(1, 0.7, 0.35), 0.24, 0.22, first)
	elseif rarity == 2 then
		paint.Legs = first
		paint.Ears = first
		patch(model, Vector3.new(-1, 0.5, 0.3), 0.28, 0.25, first)
		patch(model, Vector3.new(1, 0.6, -0.2), 0.24, 0.22, first)
	elseif rarity == 3 then
		blob(model, Vector3.new(-1, 0.45, -0.25), 0.36, first)
		blob(model, Vector3.new(1, 0.5, 0.25), 0.36, first)
		patch(model, Vector3.new(-0.6, 0.9, 0.7), 0.24, 0.22, second)
		blob(model, BACK + Vector3.new(0.3, 0, -0.3), 0.28, second)
	elseif rarity == 4 then
		paint.Ears = second
		paint.Legs = first
		blob(model, Vector3.new(-1, 0.5, 0), 0.38, second)
		blob(model, Vector3.new(1, 0.5, 0), 0.38, second)
		patch(model, BACK + Vector3.new(0, 0, 0.35), 0.34, 0.3, first)
	elseif rarity == 5 then
		paint.Coat = first
		paint.Legs = second
		paint.Ears = second
		blob(model, Vector3.new(-1, 0.5, 0.1), 0.3, second)
		blob(model, Vector3.new(1, 0.5, -0.1), 0.3, second)
	else
		paint.Coat = first
		paint.Ears = second
		paint.Legs = second
		patch(model, BACK + Vector3.new(0, 0, 0.05), 0.7, 0.62, second)
		blob(model, Vector3.new(-1, 0.4, 0.2), 0.28, second)
		blob(model, Vector3.new(1, 0.4, -0.2), 0.28, second)
		paint.Glow = first
		paint.Neon = second
	end
	return paint
end

-- Every lamb's couple of spots (style B, and the start of the subtle ones).
local function twoSpots(model: Model, color: Color3, size: number)
	patch(model, Vector3.new(-1, 0.55, -0.1), size, size * 0.9, color)
	patch(model, Vector3.new(1, 0.7, 0.35), size * 0.8, size * 0.72, color)
end

-- C: the couple of spots, plus one small touch more each rarity, in this order: a coloured tail, coloured ear insides,
-- coloured hooves, a spot on the head, and a faint twinkle.
local function markDetails(model: Model, rarity: number, first: Color3, second: Color3): { [string]: Color3 }
	local paint: { [string]: Color3 } = {}
	twoSpots(model, first, 0.26)
	if rarity >= 2 then
		paint.Tail = first
	end
	if rarity >= 3 then
		paint.EarInner = first
	end
	if rarity >= 4 then
		paint.Hooves = second
	end
	if rarity >= 5 then
		patch(model, Vector3.new(-0.35, 1, 0.1), 0.26, 0.24, first, "Head")
	end
	if rarity >= 6 then
		paint.Twinkle = first
	end
	return paint
end

-- D: one small spot per rarity step, Common one, Mythic six, all alike.
local COUNT_SPOTS = {
	Vector3.new(-1, 0.55, -0.1),
	Vector3.new(1, 0.6, 0.3),
	Vector3.new(0.2, 1, 0.45),
	Vector3.new(-1, 0.45, 0.55),
	Vector3.new(1, 0.5, -0.4),
	Vector3.new(-0.25, 1, -0.35),
}
local function markCount(model: Model, rarity: number, first: Color3, _second: Color3): { [string]: Color3 }
	for index = 1, rarity do
		patch(model, COUNT_SPOTS[index], 0.24, 0.22, first)
	end
	return {}
end

-- E: the couple of spots, a little bigger each rarity step.
local function markGrow(model: Model, rarity: number, first: Color3, _second: Color3): { [string]: Color3 }
	twoSpots(model, first, 0.18 + 0.07 * (rarity - 1))
	return {}
end

local function markSpots(model: Model, _rarity: number, first: Color3, _second: Color3): { [string]: Color3 }
	twoSpots(model, first, 0.3)
	return {}
end

local STYLES = {
	Bold = markBold,
	Spots = markSpots,
	Details = markDetails,
	Count = markCount,
	Grow = markGrow,
}

export type LambSpec = {
	Family: string,
	Fleece: number?, -- 1 Plain, 2 Shiny, 3 Royal
	Weight: number?,
	Pattern: number?, -- override the rarity's markings
	Style: string?, -- the markings' style (STYLES), Details by default
	Growth: number?, -- 0 to 1: grown this far in the pen, bigger the further
}

local function paintPieces(model: Model, names: { string }, color: Color3)
	for _, name in names do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end
end

local function lamb(spec: LambSpec): Model
	local family = spec.Family
	local weight = spec.Weight or 1
	local fleece = spec.Fleece or 1
	local base = GameConfig.Breeds[family]
	local rarity = spec.Pattern or Herds.RarityOf[family] or 1
	local first, second = hintColors(family)
	local model = fresh()
	local breed = table.clone(base)
	breed.Scale = 1
	breed.Build = nil
	breed.WoolStyle = "Puffs"
	breed.WoolSize = 1
	breed.Accessory = nil
	breed.SpecialFX = nil
	breed.Extra = nil
	breed.Extras = nil
	breed.FaceOverlay = nil
	breed.Mutation = nil
	breed.Face = "Idle"
	breed.SkinColor = COAT
	breed.SkinMaterial = Enum.Material.SmoothPlastic
	breed.WoolColor = COAT
	breed.FaceColor = COAT_FACE
	breed.LegColor = COAT_FACE
	breed.EarInnerColor = EAR_INNER
	Looks.Dress(kit, model, breed)
	local wool = model:FindFirstChild("Wool")
	if wool then
		wool:Destroy()
	end
	budHorns(model, 0.45)
	local body = model:FindFirstChild("Body") :: BasePart
	local plump = plumpness(weight)
	body.Size *= Vector3.new(plump, 0.9 + 0.12 * plump, 0.95 + 0.05 * plump)
	-- With no fleece over the neck, the head sits back against the body, and the tail on its rump.
	local neck = (model:FindFirstChild("Head") :: BasePart):FindFirstChild("Head") :: Motor6D
	neck.C0 += Vector3.new(0, -0.06, 0.18)
	local dock = (model:FindFirstChild("Tail") :: BasePart):FindFirstChild("Tail") :: Motor6D
	dock.C0 += Vector3.new(0, 0, -0.06)
	local throat = Instance.new("Part")
	throat.Name = "Neck"
	throat.Size = Vector3.new(0.78, 0.72, 0.8)
	throat.CFrame = CFrame.new(0, 1.52, -0.62) * CFrame.Angles(math.rad(-30), 0, 0)
	throat.Color = COAT
	throat.Material = Enum.Material.SmoothPlastic
	local round = Instance.new("SpecialMesh")
	round.MeshType = Enum.MeshType.Sphere
	round.Parent = throat
	local holdNeck = Instance.new("WeldConstraint")
	holdNeck.Part0 = body
	holdNeck.Part1 = throat
	holdNeck.Parent = throat
	throat.Parent = model
	local paint = STYLES[spec.Style or "Details"](model, rarity, first, second)
	if paint.Coat then
		paintPieces(model, { "Body", "Tail", "Neck" }, paint.Coat)
	end
	if paint.Ears then
		paintPieces(model, { "EarL", "EarR" }, paint.Ears)
	end
	if paint.Tail then
		paintPieces(model, { "Tail" }, paint.Tail)
	end
	if paint.EarInner then
		paintPieces(model, { "EarInnerL", "EarInnerR" }, paint.EarInner)
	end
	if paint.Hooves then
		for _, name in { "LegFL", "LegFR", "LegBL", "LegBR" } do
			local leg = model:FindFirstChild(name) :: BasePart
			local hoof = Instance.new("Part")
			hoof.Name = "Hoof"
			hoof.Shape = Enum.PartType.Cylinder
			hoof.Size = Vector3.new(0.2, leg.Size.X * 1.08, leg.Size.Z * 1.08)
			hoof.CFrame = leg.CFrame * CFrame.new(0, -leg.Size.Y / 2 + 0.1, 0) * CFrame.Angles(0, 0, math.rad(90))
			hoof.Color = paint.Hooves
			hoof.Material = Enum.Material.SmoothPlastic
			local hold = Instance.new("WeldConstraint")
			hold.Part0 = leg
			hold.Part1 = hoof
			hold.Parent = hoof
			hoof.Parent = model
		end
	end
	if paint.Twinkle then
		local h, sat, v = paint.Twinkle:ToHSV()
		local twinkle = Instance.new("ParticleEmitter")
		twinkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		twinkle.Color = ColorSequence.new(Color3.fromHSV(h, math.max(sat, 0.6), math.max(v, 0.9)))
		twinkle.LightEmission = 1
		twinkle.Rate = 1.5
		twinkle.Lifetime = NumberRange.new(0.5, 0.9)
		twinkle.Speed = NumberRange.new(0.3, 0.8)
		twinkle.SpreadAngle = Vector2.new(180, 180)
		twinkle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.4, 0.22),
			NumberSequenceKeypoint.new(1, 0),
		})
		twinkle.Parent = body
	end
	if paint.Legs then
		paintPieces(model, { "LegFL", "LegFR", "LegBL", "LegBR" }, paint.Legs)
	end
	if paint.Neon then
		-- Pale colours glow almost white, so the glowing socks and ears take the colour at full strength.
		local h, sat, v = paint.Neon:ToHSV()
		local glowing = Color3.fromHSV(h, math.max(sat, 0.75), math.max(v, 0.85))
		for _, name in { "LegFL", "LegFR", "LegBL", "LegBR", "EarL", "EarR" } do
			local part = model:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				part.Material = Enum.Material.Neon
				part.Color = glowing
			end
		end
	end
	if paint.Glow then
		local glow = Instance.new("PointLight")
		glow.Color = paint.Glow
		glow.Brightness = 1.2
		glow.Range = 6
		glow.Parent = body
	end
	if fleece == 2 then
		sparkle(model, rgb(140, 200, 255), 4)
	elseif fleece >= 3 then
		sparkle(model, rgb(255, 214, 90), 8)
	end
	model:ScaleTo(GameConfig.SheepSize * lambScale(weight) * (1 + GROW_SHARE * (spec.Growth or 0)))
	model.Name = `Lamb_{family}`
	return model
end

-- The wild lamb's card as it is now, and the mystery card.
local function textLine(parent: Instance, text: string, height: number, color: Color3)
	local words = Instance.new("TextLabel")
	words.BackgroundTransparency = 1
	words.Size = UDim2.new(1, 0, 0, height)
	words.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	words.TextScaled = true
	words.TextColor3 = color
	words.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = words
	words.Parent = parent
end

local cardFacing = Vector3.new(-1, 0, 0)

-- A card over the model's head, drawn on a see-through plate turned to the camera: the game's cards are billboards,
-- which Studio's captures leave out.
local function board(model: Model, width: number, height: number, lift: number): Instance
	local root = model.PrimaryPart :: BasePart
	local plate = Instance.new("Part")
	plate.Name = "CardPlate"
	plate.Anchored = true
	plate.CanCollide = false
	plate.CanQuery = false
	plate.Transparency = 1
	plate.Size = Vector3.new(width / 48, height / 48, 0.05)
	local at = root.Position + Vector3.new(0, lift, 0)
	plate.CFrame = CFrame.lookAt(at, at + cardFacing)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(width, height)
	gui.LightInfluence = 0
	gui.Parent = plate
	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Parent = gui
	plate.Parent = folder
	return gui
end

local function oldCard(model: Model, family: string, fleece: number, weight: number)
	local sheep = {
		Id = "",
		Family = family,
		Rarity = fleece,
		Weight = weight,
		Size = 1,
		Grown = 0,
		Rank = 0,
		Locked = false,
		Slot = 0,
		Pinned = false,
	}
	local low, high = Economy.FutureRange(sheep)
	local billboard = board(model, 190, 64, 3.6)
	local kind = Economy.FamilyRarities[Economy.FamilyRarity(family)].Name
	textLine(billboard, string.upper(kind), 18, Theme.Fleece.Rarity[kind].Hi)
	textLine(billboard, Economy.Name(sheep), 24, Color3.new(1, 1, 1))
	textLine(billboard, `Grows to +{Format.Rate(low)}-{Format.Rate(high)}/s`, 20, rgb(190, 255, 90))
end

local function mysteryCard(model: Model, god: string)
	local billboard = board(model, 190, 44, 2.6)
	textLine(billboard, `{god}'s Lamb`, 24, Color3.new(1, 1, 1))
	textLine(billboard, "???", 20, rgb(255, 220, 110))
end

local function stand(model: Model, x: number, z: number, yaw: number)
	local y = Mountain.Floor(x, z)
	model:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0))
	settle(model)
	model.Parent = folder
end

local function reset()
	local old = workspace:FindFirstChild(FOLDER)
	if old then
		old:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = FOLDER
	folder.Parent = workspace
end

-- Shots. The camera stands west of each row (-X) and looks east; sheep face the camera, turned a little.
local FACING = 62
local LAMB_FACING = 38
local Shots = {}

-- One god's six: the adult behind, its lamb in front, Common on the left. `adults` false for the lambs alone.
function Shots.Herd(
	god: string,
	x: number,
	adults: boolean?,
	pattern: number?,
	style: string?
): { Camera: Vector3, Target: Vector3 }
	local herd = Herds.ByGod[god]
	local spacing = if adults == false then 3.2 else 5
	local z0 = 194 - spacing * 2.5
	for index, family in herd do
		local z = z0 + (index - 1) * spacing
		if adults ~= false then
			stand(adult(family, 1, GameConfig.SheepSize), x + 5, z, FACING)
		end
		stand(lamb({ Family = family, Weight = 1.05, Pattern = pattern, Style = style }), x, z, LAMB_FACING)
	end
	local y = Mountain.Floor(x, 194)
	if adults == false then
		return { Camera = Vector3.new(x - 10, y + 3.2, 194), Target = Vector3.new(x, y + 0.8, 194) }
	end
	return { Camera = Vector3.new(x - 15, y + 6, 194), Target = Vector3.new(x + 2.5, y + 1.6, 194) }
end

-- The same family at four weights, light to heavy: the lightest, a typical one, a heavier one and the heaviest wild.
function Shots.Weights(family: string, x: number): { Camera: Vector3, Target: Vector3 }
	local z0 = 188
	for index, weight in { 1, 1.05, 1.1, 1.5 } do
		local z = z0 + (index - 1) * 4
		stand(lamb({ Family = family, Weight = weight }), x, z, LAMB_FACING)
	end
	local y = Mountain.Floor(x, z0 + 6)
	return { Camera = Vector3.new(x - 17, y + 5, z0 + 6), Target = Vector3.new(x, y + 1, z0 + 6) }
end

-- Before and after: today's wild lamb with its card, and the mystery lamb with its own.
function Shots.Cards(family: string, god: string, x: number): { Camera: Vector3, Target: Vector3 }
	local z = 194
	local weight = 1.05
	local now = adult(family, 1, GameConfig.SheepSize * Economy.LambScale(weight))
	stand(now, x, z - 3.5, FACING)
	oldCard(now, family, 1, weight)
	local next = lamb({ Family = family, Weight = weight })
	stand(next, x, z + 3.5, FACING)
	mysteryCard(next, god)
	local y = Mountain.Floor(x, z)
	return { Camera = Vector3.new(x - 13, y + 4, z), Target = Vector3.new(x, y + 2.2, z) }
end

-- Fleeces on a lamb: no gold paint, just the sparkle.
function Shots.Fleeces(family: string, x: number): { Camera: Vector3, Target: Vector3 }
	local z0 = 188
	for index = 1, 3 do
		local z = z0 + (index - 1) * 5
		stand(lamb({ Family = family, Weight = 1.05, Fleece = index }), x, z, FACING)
	end
	local y = Mountain.Floor(x, z0 + 5)
	return { Camera = Vector3.new(x - 14, y + 4.5, z0 + 5), Target = Vector3.new(x, y + 1.2, z0 + 5) }
end

-- Two herds' lambs in one style, `gods[1]` in front: for judging how much the markings give away.
function Shots.Styles(style: string, gods: { string }, x: number)
	for row, god in gods do
		for index, family in Herds.ByGod[god] do
			stand(lamb({ Family = family, Weight = 1.05, Style = style }), x + (row - 1) * 4.5, 186 + (index - 1) * 3.4, LAMB_FACING)
		end
	end
end

-- The pen's label over a sheep: a growing lamb's clock and time left, or a grown sheep's income.
local function penLabel(model: Model, lift: number, text: string, clock: boolean)
	local gui = board(model, 150, 40, lift)
	local list = gui:FindFirstChildOfClass("UIListLayout") :: UIListLayout
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 4)
	if clock then
		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.fromOffset(30, 30)
		icon.Image = Theme.Icons.Clock
		icon.Parent = gui
	end
	local words = Instance.new("TextLabel")
	words.BackgroundTransparency = 1
	words.AutomaticSize = Enum.AutomaticSize.X
	words.Size = UDim2.fromOffset(0, 34)
	words.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	words.TextSize = 30
	words.TextColor3 = if clock then Color3.new(1, 1, 1) else rgb(190, 255, 90)
	words.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Parent = words
	words.Parent = gui
end

-- One lamb growing up in a plot's pen (`x`, `z0`: the first spot): just put down, halfway, nearly grown, then grown,
-- its wool and its real size showing. Stood on whatever floor is under each spot.
function Shots.Growing(family: string, weight: number, size: number, x: number, z0: number): { Camera: Vector3, Target: Vector3 }
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder }
	local function floorAt(px: number, pz: number): number
		local hit = workspace:Raycast(Vector3.new(px, 300, pz), Vector3.new(0, -600, 0), params)
		return if hit then hit.Position.Y else 0
	end
	local function put(model: Model, px: number, pz: number)
		model:PivotTo(CFrame.new(px, floorAt(px, pz), pz) * CFrame.Angles(0, math.rad(LAMB_FACING), 0))
		settle(model)
		model.Parent = folder
	end
	local seconds = 45
	for index, growth in { 0, 0.5, 0.95 } do
		local model = lamb({ Family = family, Weight = weight, Growth = growth })
		put(model, x, z0 + (index - 1) * 5)
		local left = math.ceil(seconds * (1 - growth))
		penLabel(model, 1.6 + 1.2 * growth, string.format("%d:%02d", left // 60, left % 60), true)
	end
	local grown = adult(family, 1, GameConfig.SheepSize * Economy.Sizes[size].Scale)
	put(grown, x + 1, z0 + 17)
	local sheep = {
		Id = "",
		Family = family,
		Rarity = 1,
		Weight = weight,
		Size = size,
		Grown = 1e9,
		Rank = 0,
		Locked = false,
		Slot = 1,
		Pinned = false,
	}
	penLabel(grown, 3.4 * Economy.Sizes[size].Scale, `+{Format.Rate(Economy.AdultIncome(sheep))}/s`, false)
	local y = floorAt(x, z0 + 8)
	return { Camera = Vector3.new(x - 20, y + 7, z0 + 8.5), Target = Vector3.new(x, y + 2, z0 + 8.5) }
end

-- One lamb on its own, for a close look; with `god`, its mystery card over it.
function Shots.One(spec: LambSpec, x: number, z: number, yaw: number, god: string?)
	local model = lamb(spec)
	stand(model, x, z, yaw)
	if god then
		mysteryCard(model, god)
	end
end

-- Where each of the folder's sheep stands in the current camera's view, as shares of its width and height, for labels.
local function onScreen(): { [string]: { number } }
	folder = workspace:FindFirstChild(FOLDER) :: Folder
	local camera = workspace.CurrentCamera
	local size = camera.ViewportSize
	local spots: { [string]: { number } } = {}
	for _, model in folder:GetChildren() do
		if model:IsA("Model") then
			local point = camera:WorldToViewportPoint(model:GetPivot().Position)
			spots[`{model.Name}@{math.floor(model:GetPivot().Position.Z + 0.5)}`] = { point.X / size.X, point.Y / size.Y }
		end
	end
	return spots
end

return {
	OnScreen = onScreen,
	Reset = reset,
	Shots = Shots,
	Lamb = lamb,
	Adult = adult,
	HintColors = hintColors,
	Clear = function()
		local old = workspace:FindFirstChild(FOLDER)
		if old then
			old:Destroy()
		end
	end,
}
