--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)

-- A lamb's marks (the user, 2026-10-06, mock-up D): a plain lamb (SheepService's templates in
-- ReplicatedStorage.SheepLooks, "Lamb" or "Lamb" and its horns' style) gets one spot for each step of the rarity of the
-- family it will grow into, in that sheep's main colour, and a body as plump as it is heavy. The server marks the lambs
-- in the world with it; the menus mark their previews the same way.
local LambLook = {}

-- What shows on a lamb: its spots' colour and count, and the horns it'll grow (as buds), if any.
export type Look = {
	Color: Color3,
	Spots: number,
	Horns: string?,
}

local Settings = GameConfig.Sheep.Lamb
local COAT = GameConfig.LambBreed.WoolColor

-- Where each spot sits, from the body's middle in its own space (+X its right, +Y up, -Z the head): the first on its
-- left flank, then round both sides and the back, so from any one side only some show.
local SPOTS = {
	Vector3.new(-1, 0.55, -0.1),
	Vector3.new(1, 0.6, 0.3),
	Vector3.new(0.2, 1, 0.45),
	Vector3.new(-1, 0.45, 0.55),
	Vector3.new(1, 0.5, -0.4),
	Vector3.new(-0.25, 1, -0.35),
}
-- A spot is a flattened ball this deep (a share of the body's size), sunk into the body so only its cap shows.
local SPOT_DEPTH = 0.12
local SPOT_SINK = 0.38

-- The name of the plain lamb with `horns` (a HornStyle, or none) among the SheepLooks.
function LambLook.TemplateName(horns: string?): string
	return if horns then `Lamb{horns}` else "Lamb"
end

-- How much wider than the template a lamb of `weight` is: thin at the lightest, round at the heaviest wild weight.
function LambLook.Plumpness(weight: number): number
	local plump = Settings.Plump
	return plump[1] + plump[2] * math.sqrt(math.clamp((weight - 1) / 0.5, 0, 1))
end

-- One spot on the body, `direction` from its middle: found on the ellipsoid that fills the body's box and turned to
-- its surface there.
local function spot(model: Model, body: BasePart, direction: Vector3, color: Color3)
	local half = body.Size / 2 * Vector3.new(0.97, 0.95, 0.95)
	local d = direction.Unit
	local reach = 1 / math.sqrt((d.X / half.X) ^ 2 + (d.Y / half.Y) ^ 2 + (d.Z / half.Z) ^ 2)
	local at = d * reach
	local normal = Vector3.new(at.X / half.X ^ 2, at.Y / half.Y ^ 2, at.Z / half.Z ^ 2).Unit
	local span = (body.Size.X + body.Size.Z) / 2
	local depth = span * SPOT_DEPTH
	local part = Instance.new("Part")
	part.Name = "Spot"
	part.Size = Vector3.new(span * Settings.Spot, span * Settings.Spot * 0.92, depth)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	local up = if math.abs(normal.Y) > 0.9 then Vector3.new(0, 0, -1) else Vector3.yAxis
	part.CFrame = body.CFrame * CFrame.lookAt(at - normal * depth * SPOT_SINK, at + normal, up)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = part
	weld.Parent = part
	part.Parent = model
end

-- Marks a plain lamb (a clone of its template, at the template's size) for `look` and `weight`: its body's plumpness,
-- then its spots. Scale it afterwards.
function LambLook.Dress(model: Model, look: Look, weight: number)
	local body = model:FindFirstChild("Body")
	if not body or not body:IsA("BasePart") then
		return
	end
	local plump = LambLook.Plumpness(weight)
	body.Size *= Vector3.new(plump, 0.9 + 0.12 * plump, 0.95 + 0.05 * plump)
	for index = 1, math.clamp(look.Spots, 0, #SPOTS) do
		spot(model, body, SPOTS[index], look.Color)
	end
end

-- The colour a lamb's spots take from its grown sheep (`adult`, a plain one): the one most of it wears that isn't lamb
-- white or a face's cream, which a lamb's coat already is. The shorn body under the fleece and the ears' pink insides
-- don't count. Grey when the whole sheep is white.
local SKIPPED = { Root = true, Body = true, EarInnerL = true, EarInnerR = true }
local PLAIN_GREY = Color3.fromRGB(206, 200, 190)

local function distance(a: Color3, b: Color3): number
	local dr, dg, db = (a.R - b.R) * 255, (a.G - b.G) * 255, (a.B - b.B) * 255
	return math.sqrt(dr * dr + dg * dg + db * db)
end

local function isPlain(color: Color3): boolean
	if distance(color, COAT) < 45 then
		return true
	end
	local hue, saturation, value = color:ToHSV()
	return saturation < 0.3 and value > 0.82 and hue > 20 / 360 and hue < 60 / 360
end

function LambLook.MainColor(adult: Model): Color3
	local buckets: { { Color: Color3, Area: number } } = {}
	for _, descendant in adult:GetDescendants() do
		if not descendant:IsA("BasePart") or descendant.Transparency > 0.6 or SKIPPED[descendant.Name] then
			continue
		end
		local color = descendant.Color
		if isPlain(color) then
			continue
		end
		local size = descendant.Size
		local area = size.X * size.Y + size.Y * size.Z + size.X * size.Z
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
	local main: { Color: Color3, Area: number }? = nil
	for _, bucket in buckets do
		if not main or bucket.Area > main.Area then
			main = bucket
		end
	end
	return if main then main.Color else PLAIN_GREY
end

return table.freeze(LambLook)
