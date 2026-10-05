--!strict

-- The mountain: twelve tiers up one ramp, each a god's pasture with its own sheep family. The commissioned map
-- (vvs_map) is one corridor climbing east (+X) from the plots, in seven themed stages that get steeper: 2, 7, 12, 17,
-- 22, 29 and 31 degrees. Long stages hold two or three tiers. Gods are ordered to fit each stage's theme (meadow,
-- bamboo, snow, lava, rose garden, marble temple, golden cloud path); every tier keeps the design's numbers in order
-- (reach threshold, income), so swapping two gods is a matter of swapping their rows' names and looks.

export type Tier = {
	Tier: number,
	God: string,
	Area: string,
	Family: string, -- GameConfig.Breeds key
	FamilyName: string,
	Reach: number, -- Climb Power to climb into this tier
	XStart: number, -- the tier's gate on the ramp (studs along +X)
	XEnd: number,
	SlideSpeed: number, -- an empty-handed slide's target speed on this stretch
	-- The god's primitive look.
	Robe: Color3,
	Skin: Color3,
	Accent: Color3,
	Sign: string, -- their signature accessory (GodService builds it)
}

local rgb = Color3.fromRGB

local tiers: { Tier } = {
	{
		Tier = 1,
		God = "Demeter",
		Area = "Foothill Meadow",
		Family = "Meadow",
		FamilyName = "Meadow Sheep",
		Reach = 0,
		XStart = 330,
		XEnd = 580,
		SlideSpeed = 24,
		Robe = rgb(110, 168, 72),
		Skin = rgb(234, 196, 160),
		Accent = rgb(236, 196, 74),
		Sign = "WheatCrown",
	},
	{
		Tier = 2,
		God = "Dionysus",
		Area = "Vineyard Terraces",
		Family = "Grape",
		FamilyName = "Grape Sheep",
		Reach = 100,
		XStart = 580,
		XEnd = 840,
		SlideSpeed = 28,
		Robe = rgb(118, 62, 160),
		Skin = rgb(226, 182, 150),
		Accent = rgb(96, 170, 70),
		Sign = "VineCrown",
	},
	{
		Tier = 3,
		God = "Artemis",
		Area = "Moonlit Snowfield",
		Family = "Moon",
		FamilyName = "Moon Sheep",
		Reach = 800,
		XStart = 840,
		XEnd = 1080,
		SlideSpeed = 32,
		Robe = rgb(200, 210, 228),
		Skin = rgb(240, 214, 190),
		Accent = rgb(150, 190, 255),
		Sign = "Crescent",
	},
	{
		Tier = 4,
		God = "Hephaestus",
		Area = "Forge Ledge",
		Family = "Ember",
		FamilyName = "Ember Sheep",
		Reach = 3200,
		XStart = 1080,
		XEnd = 1200,
		SlideSpeed = 36,
		Robe = rgb(70, 64, 66),
		Skin = rgb(176, 120, 90),
		Accent = rgb(255, 128, 40),
		Sign = "Hammer",
	},
	{
		Tier = 5,
		God = "Ares",
		Area = "Redstone Pass",
		Family = "War",
		FamilyName = "War Sheep",
		Reach = 12800,
		XStart = 1200,
		XEnd = 1320,
		SlideSpeed = 36,
		Robe = rgb(176, 36, 32),
		Skin = rgb(210, 160, 128),
		Accent = rgb(196, 150, 70),
		Sign = "Plume",
	},
	{
		Tier = 6,
		God = "Aphrodite",
		Area = "Rose Garden",
		Family = "Rose",
		FamilyName = "Rose Sheep",
		Reach = 51200,
		XStart = 1320,
		XEnd = 1550,
		SlideSpeed = 40,
		Robe = rgb(255, 150, 196),
		Skin = rgb(246, 214, 196),
		Accent = rgb(230, 40, 90),
		Sign = "Rose",
	},
	{
		Tier = 7,
		God = "Apollo",
		Area = "Sun Terrace",
		Family = "Sun",
		FamilyName = "Sun Sheep",
		Reach = 180000,
		XStart = 1550,
		XEnd = 1780,
		SlideSpeed = 40,
		Robe = rgb(255, 204, 64),
		Skin = rgb(236, 190, 150),
		Accent = rgb(255, 120, 30),
		Sign = "SunHalo",
	},
	{
		Tier = 8,
		God = "Athena",
		Area = "Marble Steps",
		Family = "Laurel",
		FamilyName = "Laurel Sheep",
		Reach = 720000,
		XStart = 1780,
		XEnd = 2000,
		SlideSpeed = 44,
		Robe = rgb(236, 236, 230),
		Skin = rgb(222, 186, 156),
		Accent = rgb(70, 110, 190),
		Sign = "Shield",
	},
	{
		Tier = 9,
		God = "Poseidon",
		Area = "Cloudwater Falls",
		Family = "Tide",
		FamilyName = "Tide Sheep",
		Reach = 2900000,
		XStart = 2000,
		XEnd = 2220,
		SlideSpeed = 44,
		Robe = rgb(40, 150, 170),
		Skin = rgb(200, 170, 150),
		Accent = rgb(230, 250, 255),
		Sign = "Trident",
	},
	{
		Tier = 10,
		God = "Hermes",
		Area = "Wind Path",
		Family = "Wingfoot",
		FamilyName = "Wingfoot Sheep",
		Reach = 9000000,
		XStart = 2220,
		XEnd = 2500,
		SlideSpeed = 48,
		Robe = rgb(120, 190, 240),
		Skin = rgb(236, 200, 166),
		Accent = rgb(255, 214, 90),
		Sign = "WingedCap",
	},
	{
		Tier = 11,
		God = "Hera",
		Area = "Royal Courtyard",
		Family = "Crown",
		FamilyName = "Crown Sheep",
		Reach = 27000000,
		XStart = 2500,
		XEnd = 2780,
		SlideSpeed = 48,
		Robe = rgb(110, 50, 150),
		Skin = rgb(240, 210, 186),
		Accent = rgb(255, 200, 60),
		Sign = "Crown",
	},
	{
		Tier = 12,
		God = "Zeus",
		Area = "Olympus Summit",
		Family = "Thunder",
		FamilyName = "Thunder Sheep",
		Reach = 81000000,
		XStart = 2780,
		XEnd = 3060,
		SlideSpeed = 48,
		Robe = rgb(246, 246, 250),
		Skin = rgb(226, 190, 160),
		Accent = rgb(255, 226, 60),
		Sign = "Bolt",
	},
}

local byFamily: { [string]: Tier } = {}
for _, tier in tiers do
	byFamily[tier.Family] = tier
end

local Olympus = {
	Tiers = tiers,
	ByFamily = byFamily,
	Count = #tiers,

	-- The foothill safety line: the map's StartingLine. A chase ends when its carrier crosses it going home, and
	-- nothing below it (the plots and the hub) allows slides or slide hits.
	SafeLineX = 330,
	-- The ramp's floor along its middle (z 191), measured with raycasts in the map: x, height. Ground checks snap to
	-- the real floor near this line, which keeps them off the temple roofs and cloud platforms above it.
	Ramp = {
		{ 300, 60 },
		{ 580, 69.6 },
		{ 840, 100 },
		{ 1080, 152 },
		{ 1320, 226 },
		{ 1780, 412 },
		{ 1900, 478.6 },
		{ 2220, 654.8 },
		{ 2700, 936 },
		{ 3060, 1148.8 },
	} :: { { number } },
	RampSnap = 10, -- studs above and below the line a ground check accepts
	-- The corridor's walkable width (z) on every stage: wider stages keep the same middle lane.
	LaneZ = { 140, 244 } :: { number },
	LaneMiddleZ = 191,
	-- Where on its tier a god's pasture sits: from this share of the tier's length to its top.
	PastureFrom = 0.45,
	SpawnsPerTier = 4,
	GateHeight = 140,
	GateWidth = 700, -- z, wide enough to cover every stage's side terraces
}

return table.freeze(Olympus)
