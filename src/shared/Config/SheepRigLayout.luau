--!strict

-- The sheep rig's layout, for a Farm Sheep at scale 1: every piece's box, every joint's pivot and axes, the attachment
-- points and the add-ons. The pieces are the fluffy sheep's meshes (art/sheep/build_fluffy.py, 2026-10-03), and
-- studio/BuildSheep.luau builds the rig and the add-on templates from those meshes on these joints. Names never
-- change: code, animations and meshes all find pieces by name. Each piece's Size and CFrame are its mesh's box
-- (art/sheep/sheep_meshes.json), and its Pivot is where build_fluffy.py's RIG puts its joint.
--
-- Model space: the origin is on the ground under the sheep, the sheep faces -Z, +X is its right and +Y is up. Every
-- joint's axes line up with the sheep, so turning a joint around X tips it forward or back (positive X lifts a head or
-- swings a leg forward), around Y turns it left or right, and around Z rolls it sideways.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BreedBuilds = require(ReplicatedStorage.Config.BreedBuilds)

export type Shape = "Block" | "Ball" | "Wedge" | "CornerWedge" | "Cylinder"
export type JointKind = "Motor6D" | "Weld"

export type Piece = {
	Name: string,
	Parent: string?, -- the piece it hangs off; nil for Root
	Joint: JointKind?, -- Motor6D pieces bend in animations; welded pieces only follow
	Shape: Shape, -- the block a piece without a mesh is made of (Root)
	Size: Vector3,
	CFrame: CFrame, -- the box's centre and angle
	Pivot: CFrame, -- where its joint bends, with the joint's axes; a weld's pivot is the piece's centre
}

export type Attachment = {
	Name: string,
	Piece: string,
	CFrame: CFrame,
}

-- A small piece that only exists as a mesh, welded to a rig piece: the ears' pink insides.
export type Detail = {
	Name: string,
	Piece: string, -- the rig piece it's welded to, so it follows that piece's animations
	Tint: string, -- its colour in GameConfig.Sheep.DetailColors
}

export type Addon = {
	Kind: "Horns" | "Accessory" | "WoolStyle" | "Effect",
	Hides: { string }?, -- the sheep's own pieces it covers, hidden so none pokes out when they move
}

-- One of an add-on's meshes (art/sheep/sheep_addons.fbx, or a base piece's mesh reused): studio/BuildSheep.luau makes
-- the add-on's template from these. Tint says which breed colour it takes ("Horn", "HornBand", "Face", "Wool", "Spot");
-- without one it keeps Color.
export type AddonMesh = {
	Mesh: string, -- its name in the files, e.g. SmallCurlL or RingletsWool3
	Name: string, -- its name on the sheep: a wool style's pieces take the slots' names, so shearing still finds them
	Piece: string, -- the rig piece it's welded to
	Puff: string?, -- instead, hangs under this wool slot of the same add-on (Jacob's spots), growing and shearing with it
	Scale: Vector3?, -- stretches the mesh about its centre
	Offset: Vector3?, -- moves it from where the mesh build put it
	Tint: string?,
	Color: Color3?,
	Material: Enum.Material?,
	Transparency: number?,
	Texture: string?, -- a patterned material's picture (BreedBuilds.Textures), laid on by the mesh's UVs
	-- A breed build's moving and changing pieces (SheepController/Builds): it shows from ShowAt of its wool, turns
	-- SpinSpeed degrees a second about SpinAxis through SpinPivot (model space at scale 1) or rocks SwingAngle degrees
	-- either way, settles by Settle while the wool under it is gone, or, wool, turns ShornColor when shorn instead of
	-- going.
	ShowAt: number?,
	HideAt: number?,
	SpinAxis: Vector3?,
	SpinSpeed: number?,
	SpinPivot: Vector3?,
	SwingAngle: number?,
	SwingPeriod: number?,
	SwingPhase: number?,
	SwingTicks: number?,
	Hop: number?,
	Settle: Vector3?,
	SettleFrom: number?,
	SettleTo: number?,
	ShornColor: Color3?,
}

-- The wool's underside seen from the front, for a carrier's palms (CarryPose.Fleece): the lowest wool either side of
-- the middle as a half ellipse, measured from the meshes (build_fluffy.py). Heights are above the feet.
export type Underside = {
	PuffX: number, -- how far either side of the middle the lowest wool is
	PuffY: number, -- the underside's height at its edge (PuffX + HalfWidth out)
	HalfWidth: number,
	Hang: number, -- how far the lowest wool hangs below PuffY
}

local Layout = {}

-- The wool's middle: the body bends here, and Root sits here.
local BODY_CENTER = Vector3.new(0, 1.32, 0.22)

local pieces: { Piece } = {}

local function add(name: string, parent: string?, joint: JointKind?, size: Vector3, center: Vector3, pivot: Vector3?)
	table.insert(pieces, {
		Name = name,
		Parent = parent,
		Joint = joint,
		Shape = "Block",
		Size = size,
		CFrame = CFrame.new(center),
		Pivot = CFrame.new(pivot or center),
	})
end

add("Root", nil, nil, Vector3.one * 0.2, BODY_CENTER)
-- The shorn body, smaller than the wool round it.
add("Body", "Root", "Motor6D", Vector3.new(1.56, 1.24, 1.6), Vector3.new(0, 1.15, 0.22), BODY_CENTER)
-- A rounded cube half out of the wool's front, its face a Decal (the mouth is in the picture, so there's no jaw);
-- it turns on the neck, inside the wool behind it.
add("Head", "Body", "Motor6D", Vector3.new(1.1, 1.02, 0.95), Vector3.new(0, 1.75, -1.12), Vector3.new(0, 1.45, -0.77))
-- Floppy ears out of the head's sides, hanging from their roots.
for _, side: { name: string, sign: number } in { { name = "EarL", sign = -1 }, { name = "EarR", sign = 1 } } do
	local sign = side.sign
	add(
		side.name,
		"Head",
		"Motor6D",
		Vector3.new(0.5642, 0.438, 0.2545),
		Vector3.new(0.7655 * sign, 1.7798, -1.0634),
		Vector3.new(0.5 * sign, 1.93, -1.16)
	)
end

-- Stubby legs, bending where they meet the body; their tops reach 0.14 further up, inside it, so a swinging leg never
-- shows a gap.
local legs: { { name: string, side: number, z: number } } = {
	{ name = "LegFL", side = -1, z = -0.38 },
	{ name = "LegFR", side = 1, z = -0.38 },
	{ name = "LegBL", side = -1, z = 0.68 },
	{ name = "LegBR", side = 1, z = 0.68 },
}
for _, leg in legs do
	local x = 0.42 * leg.side
	add(
		leg.name,
		"Body",
		"Motor6D",
		Vector3.new(0.349, 1, 0.349),
		Vector3.new(x, 0.5, leg.z),
		Vector3.new(x, 0.86, leg.z)
	)
end

-- A woolly puff on the rump, wagging from inside it.
add(
	"Tail",
	"Body",
	"Motor6D",
	Vector3.new(0.4385, 0.4929, 0.4704),
	Vector3.new(0, 1.4451, 1.2267),
	Vector3.new(0, 1.42, 0.98)
)

-- The wool slots, in the order they grow back: the lower puffs round the body (back left, back right, front left,
-- front right), the top (the back, then the front's left and right), the chest puffs behind the head, and the head's
-- puffs. Each is a group of puffs and the patch of wool under them; a slot's box is its mesh's.
local woolSlots: { { any } } = {
	{ "Wool1", Vector3.new(1.45, 1.5086, 1.3932), Vector3.new(-0.354, 1.0657, 0.9166) },
	{ "Wool2", Vector3.new(1.3493, 1.2638, 1.4462), Vector3.new(0.6746, 1.0184, 0.6285) },
	{ "Wool3", Vector3.new(1.4595, 1.3068, 1.6452), Vector3.new(-0.7298, 0.9957, -0.1006) },
	{ "Wool4", Vector3.new(1.4434, 1.5636, 1.4022), Vector3.new(0.7217, 1.086, -0.223) },
	{ "Wool5", Vector3.new(2.6868, 1.5516, 1.5603), Vector3.new(-0.0245, 1.8359, 0.811) },
	{ "Wool6", Vector3.new(1.7239, 1.4152, 1.5789), Vector3.new(-0.4449, 1.8, -0.1427) },
	{ "Wool7", Vector3.new(1.4083, 1.5566, 1.6346), Vector3.new(0.4406, 1.8384, -0.2142) },
	{ "Wool8", Vector3.new(0.9691, 1.1818, 1.4054), Vector3.new(-0.0366, 1.0661, -0.4827) },
}
for _, slot in woolSlots do
	add(slot[1] :: string, "Body", "Weld", slot[2] :: Vector3, slot[3] :: Vector3)
end
add("WoolHead", "Head", "Weld", Vector3.new(1.275, 0.7746, 1.012), Vector3.new(-0.0184, 2.3481, -1.0736))

Layout.Pieces = pieces

Layout.WoolOrder = { "Wool1", "Wool2", "Wool3", "Wool4", "Wool5", "Wool6", "Wool7", "Wool8", "WoolHead" }

-- The ears' pink insides, welded where the mesh build put them, the same on every breed.
local details: { Detail } = {
	{ Name = "EarInnerL", Piece = "EarL", Tint = "EarInner" },
	{ Name = "EarInnerR", Piece = "EarR", Tint = "EarInner" },
}
Layout.Details = details

local attachments: { Attachment } = {
	{ Name = "HornL", Piece = "Head", CFrame = CFrame.new(-0.34, 2.17, -1.06) },
	{ Name = "HornR", Piece = "Head", CFrame = CFrame.new(0.34, 2.17, -1.06) },
	{ Name = "HornTop", Piece = "Head", CFrame = CFrame.new(0, 2.26, -1.2) },
	{ Name = "Back", Piece = "Body", CFrame = CFrame.new(0, 2.08, 0.3) },
	{ Name = "FX", Piece = "Body", CFrame = CFrame.new(BODY_CENTER) },
}
Layout.Attachments = attachments

local addons: { [string]: Addon } = {
	SmallCurl = { Kind = "Horns" },
	BigCurl = { Kind = "Horns" },
	Spiral = { Kind = "Horns" },
	FourHorn = { Kind = "Horns" },
	Antennae = { Kind = "Accessory" },
	-- A wolf's pointed ears up through the wool and its bushy tail out the back, in place of the sheep's own.
	WolfHead = { Kind = "Accessory", Hides = { "EarL", "EarR", "EarInnerL", "EarInnerR", "Tail" } },
	Ringlets = { Kind = "WoolStyle" },
	Cloud = { Kind = "WoolStyle" },
	Icicle = { Kind = "WoolStyle" },
	-- The plain puffs with patches of them in the breed's second colour (Jacob).
	Spotted = { Kind = "WoolStyle" },
	LavaGlow = { Kind = "Effect" },
}
Layout.Addons = addons

local WOLF_EAR_INNER = Color3.fromRGB(240, 164, 172)
local WOLF_TAIL_TIP = Color3.fromRGB(246, 246, 240)
local LAVA = Color3.fromRGB(255, 120, 30)

-- The add-ons' meshes, each standing where it goes on a Farm Sheep at the origin.
local addonMeshes: { [string]: { AddonMesh } } = {}

-- Each horn and its stripes: every other ring of the same tube, tinted a shade off the horn (Looks, HornBand).
for _, style in { "SmallCurl", "BigCurl", "Spiral", "FourHorn" } do
	addonMeshes[style] = {
		{ Mesh = `{style}L`, Name = `{style}L`, Piece = "Head", Tint = "Horn" },
		{ Mesh = `{style}BandsL`, Name = `{style}BandsL`, Piece = "Head", Tint = "HornBand" },
		{ Mesh = `{style}R`, Name = `{style}R`, Piece = "Head", Tint = "Horn" },
		{ Mesh = `{style}BandsR`, Name = `{style}BandsR`, Piece = "Head", Tint = "HornBand" },
	}
end
addonMeshes.Antennae = {
	{ Mesh = "AntennaeL", Name = "AntennaeL", Piece = "Head", Tint = "Face" },
	{ Mesh = "AntennaeR", Name = "AntennaeR", Piece = "Head", Tint = "Face" },
	{ Mesh = "AntennaeTipL", Name = "AntennaeTipL", Piece = "Head", Tint = "Wool" },
	{ Mesh = "AntennaeTipR", Name = "AntennaeTipR", Piece = "Head", Tint = "Wool" },
}
addonMeshes.WolfHead = {
	{ Mesh = "WolfEarL", Name = "WolfEarL", Piece = "Head", Tint = "Face" },
	{ Mesh = "WolfEarR", Name = "WolfEarR", Piece = "Head", Tint = "Face" },
	{ Mesh = "WolfEarInnerL", Name = "WolfEarInnerL", Piece = "Head", Color = WOLF_EAR_INNER },
	{ Mesh = "WolfEarInnerR", Name = "WolfEarInnerR", Piece = "Head", Color = WOLF_EAR_INNER },
	{ Mesh = "WolfTail", Name = "WolfTail", Piece = "Tail", Tint = "Face" },
	{ Mesh = "WolfTailTip", Name = "WolfTailTip", Piece = "Tail", Color = WOLF_TAIL_TIP },
}
-- Each wool style is a whole set of slots, named after the slots they replace.
for _, style in { "Ringlets", "Cloud", "Icicle" } do
	local list: { AddonMesh } = {}
	for _, slot in Layout.WoolOrder do
		table.insert(list, {
			Mesh = `{style}{slot}`,
			Name = slot,
			Piece = if slot == "WoolHead" then "Head" else "Body",
			Tint = "Wool",
		})
	end
	addonMeshes[style] = list
end
-- Jacob's patches (art/sheep/build_fluffy.py, JACOB_SPOTS): the slots with spot puffs carry them as a part hanging
-- under the slot ("Spots"); every puff of WoolHead is in a patch, so the slot itself takes the second colour.
local SPOT_PATCHES = { "Wool1", "Wool3", "Wool4", "Wool5", "Wool6", "Wool7" }
local ALL_SPOT = { WoolHead = true }
local spotted: { AddonMesh } = {}
for _, slot in Layout.WoolOrder do
	table.insert(spotted, {
		Mesh = `Spotted{slot}`,
		Name = slot,
		Piece = if slot == "WoolHead" then "Head" else "Body",
		Tint = if ALL_SPOT[slot] then "Spot" else "Wool",
	})
	if table.find(SPOT_PATCHES, slot) then
		table.insert(spotted, {
			Mesh = `Spotted{slot}Spots`,
			Name = "Spots",
			Piece = "Body",
			Puff = slot,
			Tint = "Spot",
		})
	end
end
addonMeshes.Spotted = spotted
-- LavaGlow's stripes are thin slices of the shorn body's own mesh, a little bigger than it, so each shows as a glowing
-- band round it.
local LAVA_STRIPE_SPREAD = 1.03
local LAVA_STRIPE_DEPTH = 0.14
local body = pieces[2]
addonMeshes.LavaGlow = {}
for index, z in { -0.5, 0.05, 0.6 } do
	table.insert(addonMeshes.LavaGlow, {
		Mesh = "Body",
		Name = `Stripe{index}`,
		Piece = "Body",
		Scale = Vector3.new(LAVA_STRIPE_SPREAD, LAVA_STRIPE_SPREAD, LAVA_STRIPE_DEPTH / body.Size.Z),
		Offset = Vector3.new(0, 0, z),
		Color = LAVA,
		Material = Enum.Material.Neon,
	})
end
Layout.AddonMeshes = addonMeshes

-- Measured from each style's slots: the plain puffs, the Wensleydale's hanging locks, the Cloud's bigger wool.
local undersides: { [string]: Underside } = {
	Puffs = { PuffX = 0.55, PuffY = 0.62, HalfWidth = 0.75, Hang = 0.31 },
	Ringlets = { PuffX = 0.6, PuffY = 0.55, HalfWidth = 0.7, Hang = 0.5 },
	Cloud = { PuffX = 0.65, PuffY = 0.6, HalfWidth = 0.8, Hang = 0.35 },
	Icicle = { PuffX = 0.55, PuffY = 0.62, HalfWidth = 0.75, Hang = 0.31 },
	Spotted = { PuffX = 0.55, PuffY = 0.62, HalfWidth = 0.75, Hang = 0.31 },
}
Layout.Undersides = undersides

-- The breeds with their own designs (Config/BreedBuilds, from art/sheep/build_breeds.py): each breed's wool is a wool
-- style of its own (<Breed>Wool) and its extras an accessory (<Breed>Extras) hiding the rig pieces they replace.
local function copyMeshes(list: { BreedBuilds.Mesh }): { AddonMesh }
	local out: { AddonMesh } = {}
	for _, mesh in list do
		table.insert(out, {
			Mesh = mesh.Mesh,
			Name = mesh.Name,
			Piece = mesh.Piece,
			Puff = mesh.Puff,
			Tint = mesh.Tint,
			Color = mesh.Color,
			Material = mesh.Material,
			Transparency = mesh.Transparency,
			Texture = mesh.Texture,
			ShowAt = mesh.ShowAt,
			HideAt = mesh.HideAt,
			SpinAxis = mesh.SpinAxis,
			SpinSpeed = mesh.SpinSpeed,
			SpinPivot = mesh.SpinPivot,
			SwingAngle = mesh.SwingAngle,
			SwingPeriod = mesh.SwingPeriod,
			SwingPhase = mesh.SwingPhase,
			SwingTicks = mesh.SwingTicks,
			Hop = mesh.Hop,
			Settle = mesh.Settle,
			SettleFrom = mesh.SettleFrom,
			SettleTo = mesh.SettleTo,
			ShornColor = mesh.ShornColor,
		})
	end
	return out
end
for id, build in BreedBuilds.Builds do
	addons[`{id}Wool`] = { Kind = "WoolStyle" }
	addons[`{id}Extras`] = { Kind = "Accessory", Hides = build.Hides }
	addonMeshes[`{id}Wool`] = copyMeshes(build.Wool)
	addonMeshes[`{id}Extras`] = copyMeshes(build.Extras)
	undersides[`{id}Wool`] = build.Underside
end

-- Where the ears hang (art/sheep/mock_fluffy.py's EAR_PLACES): the meshes are built Level; a horned breed's sit Back,
-- higher and swept back inside the horns' curl (Mark's pick), which Looks gets by turning each ear's joint. Lift is
-- above the head's middle and Back behind its front, in studs; Droop tips the ear down and Sweep turns it back, in
-- degrees.
export type EarPlace = { Lift: number, Back: number, Droop: number, Sweep: number }
local earPlaces: { [string]: EarPlace } = {
	Level = { Lift = 0.18, Back = 0, Droop = 28, Sweep = 20 },
	Back = { Lift = 0.24, Back = 0.16, Droop = 22, Sweep = 48 },
}
Layout.EarPlaces = earPlaces
Layout.EarRoot = Vector3.new(0.5, 1.75, -1.16) -- the right ear's root at Lift and Back 0; the left's is mirrored

return table.freeze(Layout)
