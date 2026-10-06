--!strict

-- Each god's herd: the six sheep families that graze on their tier, Common to Mythic. The Common is the god's own
-- family (GameConfig.Breeds); the other five are its rarer cousins, made from Shear a Sheep's builds, wool styles,
-- materials and paints, with primitive extras (SheepService/Extras). Keyed by god, so it holds whatever order the gods
-- climb in. GameConfig turns each look here into a Breed (its Name is the display name; the rest are Breed fields).

export type Extra = { Kind: string, Color: Color3? }

local rgb = Color3.fromRGB
local Material = Enum.Material

local function extra(kind: string, color: Color3?): Extra
	return { Kind = kind, Color = color }
end

local Herds = {}

Herds.Rarities = table.freeze({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }) :: { string }

-- Family ids, Common first.
Herds.ByGod = table.freeze({
	Pan = { "Wild", "Clover", "Ram", "Toadstool", "Blossom", "GroveSpirit" },
	Tyche = { "Fortune", "Coin", "Dice", "Gambler", "Diamond", "Fate" },
	Hecate = { "Spirit", "Candle", "Witch", "Wisp", "Hellhound", "Moonwitch" },
	Phobos = { "Fright", "Shiver", "Spiked", "Peeper", "Nightmare", "Phantom" },
	Eris = { "Chaos", "Mismatch", "Apple", "Strife", "Scribble", "Discord" },
	Eros = { "Cupid", "Heart", "Ribbon", "Sweetheart", "Cherub", "Lovestruck" },
	Hebe = { "Ambrosia", "Honey", "Peach", "Nectar", "BerryCake", "NectarAngel" },
	Themis = { "Justice", "Marble", "Judge", "Gavel", "Verdict", "DivineLaw" },
	Asclepius = { "Potion", "Mint", "Remedy", "Elixir", "Panacea", "GoldenElixir" },
	Iris = { "Prism", "Sky", "Raindrop", "RainbowCloud", "Aurora", "Unicorn" },
	Nike = { "Victory", "Medal", "Racer", "Glory", "WingedVictory", "Triumph" },
	Aeolus = { "Gale", "Breeze", "Gust", "Windswept", "Tempest", "Cyclone" },
	Hypnos = { "Slumber", "Poppy", "Snooze", "Pillow", "Dreamcloud", "Sandman" },
	Morpheus = { "Starlit", "Stardust", "Dreamer", "Comet", "Nebula", "Dreamweaver" },
	Deimos = { "Dread", "Gloom", "Bat", "Crater", "Eclipse", "VoidWatcher" },
	Thanatos = { "Bone", "Ash", "Shade", "Reaper", "Soul", "BoneKing" },
	Nemesis = { "Avenger", "Iron", "Blade", "ShadowMecha", "Reckoning", "Vengeance" },
	Dionysus = { "Grape", "Vine", "Berry", "Reveler", "GrapeKing", "Festival" },
	Hermes = { "Wingfoot", "Swift", "Trickster", "Herald", "Express", "Quicksilver" },
	Hephaestus = { "Ember", "Soot", "Bronze", "Smith", "Molten", "Automaton" },
	Ares = { "War", "Recruit", "BattleRam", "Warlord", "Gladiator", "Wrath" },
	Aphrodite = { "Rose", "Rosebud", "Pearl", "Darling", "CrystalRose", "LoveGoddess" },
	Artemis = { "Moon", "Fawn", "Stag", "Huntress", "SilverStag", "Moonbeam" },
	Apollo = { "Sun", "Sunny", "Dawn", "Sunflower", "Radiant", "SolarFlare" },
	Athena = { "Laurel", "Olive", "Weaver", "Owl", "Aegis", "OwlGoddess" },
	Demeter = { "Meadow", "Wheat", "Haystack", "Pumpkin", "HarvestQueen", "EternalHarvest" },
	Hestia = { "Hearth", "Cozy", "Cinnamon", "Loaf", "Hearthkeeper", "EternalFlame" },
	Poseidon = { "Tide", "Wave", "Coral", "Trident", "Kraken", "SeaKing" },
	Hera = { "Crown", "Lady", "Peacock", "Empress", "SilverQueen", "PeacockRoyal" },
	Zeus = { "Thunder", "Thundercloud", "Eagle", "Lightning", "GoldenFleece", "KingOfOlympus" },
}) :: { [string]: { string } }

-- Each family's rarity (an index into Rarities) and its god.
local rarityOf: { [string]: number } = {}
local godOf: { [string]: string } = {}
for god, herd in Herds.ByGod do
	for index, family in herd do
		rarityOf[family] = index
		godOf[family] = god
	end
end
Herds.RarityOf = table.freeze(rarityOf)
Herds.GodOf = table.freeze(godOf)

-- The five rarer families of each herd, in the order above.
Herds.Looks = table.freeze({
	-- Pan: the shepherds' meadow.
	Clover = {
		Name = "Clover Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(246, 250, 236),
		WoolSpotColor = rgb(96, 176, 72),
		Face = "Happy",
		Extras = { extra("Clover") },
	},
	Ram = {
		Name = "Ram Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(150, 105, 70),
		FaceColor = rgb(214, 190, 160),
		LegColor = rgb(120, 86, 60),
		HornStyle = "BigCurl",
		HornColor = rgb(238, 222, 190),
		Extras = { extra("Bell") },
	},
	Toadstool = {
		Name = "Toadstool Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(215, 45, 45),
		WoolSpotColor = rgb(250, 245, 235),
		Face = "Happy",
		Extras = { extra("Mushroom") },
	},
	Blossom = {
		Name = "Blossom Sheep",
		Build = "CactusSheep",
		WoolColor = rgb(110, 190, 90),
		Face = "Happy",
		Extras = { extra("Wreath", rgb(255, 150, 200)) },
	},
	GroveSpirit = {
		Name = "Grove Spirit Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(60, 220, 100),
		WoolMaterial = Material.Neon,
		FaceColor = rgb(210, 255, 220),
		LegColor = rgb(170, 230, 180),
		Face = "Happy",
		Extras = { extra("Antlers", rgb(255, 214, 90)), extra("Wreath", rgb(255, 150, 200)) },
	},

	-- Tyche: luck and fortune.
	Coin = {
		Name = "Coin Sheep",
		WoolColor = rgb(255, 238, 200),
		Face = "Happy",
		Extras = { extra("Coin") },
	},
	Dice = {
		Name = "Dice Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(250, 250, 250),
		WoolSpotColor = rgb(30, 30, 34),
		Extras = { extra("Dice") },
	},
	Gambler = {
		Name = "Gambler Sheep",
		WoolColor = rgb(40, 120, 70),
		WoolMaterial = Material.Fabric,
		Face = "Sly",
		Extras = { extra("TopHat"), extra("Shades") },
	},
	Diamond = {
		Name = "Diamond Sheep",
		WoolColor = rgb(150, 235, 255),
		WoolMaterial = Material.Glass,
		WoolSize = 1.15,
		FaceColor = rgb(220, 245, 255),
		LegColor = rgb(200, 235, 250),
		Face = "Happy",
		Extras = { extra("Crown", rgb(220, 230, 245)) },
	},
	Fate = {
		Name = "Fate Sheep",
		Build = "TimeSheep",
		WoolColor = rgb(120, 70, 200),
		FaceColor = rgb(200, 180, 240),
		LegColor = rgb(150, 120, 210),
		Face = "Sly",
		Extras = { extra("Halo") },
	},

	-- Hecate: witchcraft at the crossroads.
	Candle = {
		Name = "Candle Sheep",
		WoolColor = rgb(70, 60, 92),
		FaceColor = rgb(200, 190, 220),
		LegColor = rgb(170, 160, 200),
		Extras = { extra("Candle") },
	},
	Witch = {
		Name = "Witch Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(130, 76, 180),
		FaceColor = rgb(170, 220, 150),
		LegColor = rgb(150, 200, 130),
		Face = "Sly",
		Extras = { extra("WitchHat") },
	},
	Wisp = {
		Name = "Wisp Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(0, 220, 190),
		WoolMaterial = Material.Neon,
		FaceColor = rgb(210, 255, 245),
		LegColor = rgb(170, 240, 225),
		Face = "Shy",
	},
	Hellhound = {
		Name = "Hellhound Sheep",
		Build = "SheepInWolfsClothing",
		WoolColor = rgb(40, 36, 46),
		Face = "Sly",
		Extras = { extra("Flame", rgb(190, 90, 255)) },
	},
	Moonwitch = {
		Name = "Moonwitch Sheep",
		Mutation = "Silver",
		WoolStyle = "Ringlets",
		FaceColor = rgb(200, 190, 230),
		LegColor = rgb(150, 140, 190),
		Face = "Sly",
		Extras = { extra("WitchHat", rgb(60, 40, 110)), extra("Moon") },
	},

	-- Phobos: fear.
	Shiver = {
		Name = "Shiver Sheep",
		WoolStyle = "Icicle",
		WoolColor = rgb(160, 160, 176),
		FaceColor = rgb(214, 214, 226),
		LegColor = rgb(180, 180, 196),
		Face = "Scared",
	},
	Spiked = {
		Name = "Spiked Sheep",
		WoolColor = rgb(80, 46, 100),
		FaceColor = rgb(60, 50, 70),
		LegColor = rgb(50, 40, 60),
		Face = "Sly",
		HornStyle = "Spiral",
		HornColor = rgb(30, 26, 34),
		Extras = { extra("BackSpikes", rgb(40, 24, 50)) },
	},
	Peeper = {
		Name = "Peeper Sheep",
		WoolColor = rgb(240, 236, 230),
		Face = "Scared",
		Extras = { extra("Eyeball") },
	},
	Nightmare = {
		Name = "Nightmare Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(28, 24, 36),
		FaceColor = rgb(70, 60, 80),
		LegColor = rgb(40, 34, 48),
		Face = "Sly",
		HornStyle = "FourHorn",
		HornColor = rgb(210, 30, 40),
		Extras = { extra("BackSpikes", rgb(200, 30, 40)) },
	},
	Phantom = {
		Name = "Phantom Sheep",
		Build = "GhostSheep",
		WoolColor = rgb(44, 34, 60),
		Face = "Ghost",
		Extras = { extra("Eyeball", rgb(255, 60, 60)), extra("Halo", rgb(230, 40, 60)) },
	},

	-- Eris: chaos and the golden apple.
	Mismatch = {
		Name = "Mismatch Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(255, 130, 40),
		WoolSpotColor = rgb(60, 200, 255),
		Face = "Dizzy",
	},
	Apple = {
		Name = "Apple Sheep",
		WoolColor = rgb(244, 240, 230),
		Face = "Sly",
		Extras = { extra("Apple") },
	},
	Strife = {
		Name = "Strife Sheep",
		Build = "LongSheep",
		WoolColor = rgb(130, 56, 170),
		FaceColor = rgb(214, 190, 236),
		LegColor = rgb(170, 140, 200),
		Face = "Dizzy",
		Extras = { extra("Apple") },
	},
	Scribble = {
		Name = "Scribble Sheep",
		Build = "DoodleSheep",
		Face = "Laughing",
		Extras = { extra("Crown") },
	},

	Discord = {
		Name = "Discord Sheep",
		Build = "GlitchSheep",
		Mutation = "Rainbow",
		Face = "Laughing",
		Extras = { extra("Apple"), extra("Halo") },
	},

	-- Eros: love.
	Heart = {
		Name = "Heart Sheep",
		WoolColor = rgb(255, 244, 246),
		Face = "Shy",
		Extras = { extra("Heart", rgb(230, 30, 70)) },
	},
	Ribbon = {
		Name = "Ribbon Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(255, 242, 246),
		Face = "Shy",
		Extras = { extra("Bow"), extra("Collar", rgb(255, 120, 170)) },
	},
	Sweetheart = {
		Name = "Sweetheart Sheep",
		Build = "CottonCandySheep",
		WoolColor = rgb(255, 120, 150),
		WoolSpotColor = rgb(230, 30, 70),
		Face = "Love",
		Extras = { extra("Heart", rgb(230, 30, 70)) },
	},
	Cherub = {
		Name = "Cherub Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 252, 250),
		FaceColor = rgb(255, 225, 215),
		LegColor = rgb(255, 214, 205),
		Face = "Happy",
		Extras = { extra("BackWings"), extra("Halo") },
	},
	Lovestruck = {
		Name = "Lovestruck Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 40, 140),
		WoolMaterial = Material.Neon,
		FaceColor = rgb(255, 220, 235),
		LegColor = rgb(255, 200, 225),
		Face = "Love",
		Extras = { extra("BackWings", rgb(255, 200, 230)), extra("Halo", rgb(255, 120, 190)), extra("Heart") },
	},

	-- Hebe: youth and the gods' nectar.
	Honey = {
		Name = "Honey Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(255, 190, 60),
		FaceColor = rgb(250, 230, 190),
		Face = "Happy",
	},
	Peach = {
		Name = "Peach Sheep",
		WoolColor = rgb(255, 186, 150),
		FaceColor = rgb(255, 226, 200),
		Face = "Shy",
		Extras = { extra("Leaf") },
	},
	Nectar = {
		Name = "Nectar Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 232, 200),
		Face = "Happy",
		Extras = { extra("Potion", rgb(255, 170, 40)) },
	},
	BerryCake = {
		Name = "Berry Cake Sheep",
		Build = "CupcakeSheep",
		WoolColor = rgb(235, 90, 150),
		Face = "Happy",
		Extras = { extra("Crown") },
	},
	NectarAngel = {
		Name = "Nectar Angel Sheep",
		Build = "CottonCandySheep",
		WoolColor = rgb(255, 240, 180),
		WoolSpotColor = rgb(255, 196, 80),
		Face = "Happy",
		Extras = { extra("BackWings", rgb(255, 220, 120)), extra("Halo") },
	},

	-- Themis: law and justice.
	Marble = {
		Name = "Marble Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(250, 250, 248),
		WoolSpotColor = rgb(196, 198, 210),
	},
	Judge = {
		Name = "Judge Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(44, 44, 52),
		WoolSize = 1.15,
		Face = "Sly",
		Extras = { extra("Collar", rgb(250, 250, 255)) },
	},
	Gavel = {
		Name = "Gavel Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(170, 170, 180),
		Face = "Sly",
		Extras = { extra("Hammer", rgb(130, 84, 50)) },
	},
	Verdict = {
		Name = "Verdict Sheep",
		Mutation = "Silver",
		WoolStyle = "Ringlets",
		Extras = { extra("Sword"), extra("Wreath", rgb(255, 200, 60)) },
	},
	DivineLaw = {
		Name = "Divine Law Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 255, 255),
		Extras = {
			extra("BackWings", rgb(255, 214, 90)),
			extra("Blindfold"),
			extra("Sword", rgb(255, 214, 90)),
			extra("Halo"),
		},
	},

	-- Asclepius: healing.
	Mint = {
		Name = "Mint Sheep",
		WoolColor = rgb(170, 240, 200),
		Face = "Happy",
		Extras = { extra("Leaf") },
	},
	Remedy = {
		Name = "Remedy Sheep",
		WoolColor = rgb(250, 250, 250),
		Face = "Happy",
		Extras = { extra("Potion", rgb(255, 90, 170)) },
	},
	Elixir = {
		Name = "Elixir Sheep",
		Build = "SlimeSheep",
		WoolColor = rgb(90, 170, 255),
		FaceColor = rgb(90, 170, 255),
		LegColor = rgb(90, 170, 255),
		EarInnerColor = rgb(160, 210, 255),
	},
	Panacea = {
		Name = "Panacea Sheep",
		WoolColor = rgb(180, 255, 210),
		WoolMaterial = Material.Glass,
		Face = "Happy",
		Extras = { extra("Potion", rgb(255, 210, 60)), extra("Halo", rgb(120, 255, 170)) },
	},
	GoldenElixir = {
		Name = "Golden Elixir Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 206, 50),
		Face = "Happy",
		Extras = { extra("Potion", rgb(120, 255, 200)), extra("Crystal", rgb(120, 255, 200)), extra("Halo") },
	},

	-- Iris: the rainbow.
	Sky = {
		Name = "Sky Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(160, 214, 255),
		Face = "Happy",
	},
	Raindrop = {
		Name = "Raindrop Sheep",
		WoolStyle = "Icicle",
		WoolColor = rgb(110, 180, 255),
		FaceColor = rgb(214, 234, 255),
		Extras = { extra("Cloud", rgb(200, 210, 225)) },
	},
	RainbowCloud = {
		Name = "Rainbow Cloud Sheep",
		Build = "CloudSheep",
		WoolColor = rgb(255, 255, 255),
		Face = "Happy",
	},
	Aurora = {
		Name = "Aurora Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(80, 230, 170),
		WoolSpotColor = rgb(170, 90, 255),
		Face = "Happy",
		Extras = { extra("Star", rgb(255, 150, 255)) },
	},
	Unicorn = {
		Name = "Unicorn Sheep",
		Mutation = "Rainbow",
		WoolStyle = "Ringlets",
		Face = "Happy",
		Extras = { extra("UnicornHorn"), extra("BackWings") },
	},

	-- Nike: victory.
	Medal = {
		Name = "Medal Sheep",
		WoolColor = rgb(255, 248, 232),
		Face = "Happy",
		Extras = { extra("Bell", rgb(40, 90, 200)) },
	},
	Racer = {
		Name = "Racer Sheep",
		WoolColor = rgb(220, 40, 44),
		Face = "Happy",
		Extras = { extra("Shades") },
	},
	Glory = {
		Name = "Glory Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(252, 252, 248),
		Face = "Happy",
		Extras = { extra("Wreath", rgb(255, 200, 60)), extra("HeadWings") },
	},
	WingedVictory = {
		Name = "Winged Victory Sheep",
		Mutation = "Silver",
		Extras = { extra("BackWings"), extra("Wreath", rgb(255, 200, 60)) },
	},
	Triumph = {
		Name = "Triumph Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 200, 40),
		Face = "Happy",
		Extras = { extra("BackWings", rgb(255, 236, 170)), extra("Wreath", rgb(110, 170, 70)), extra("Halo") },
	},

	-- Aeolus: the winds.
	Breeze = {
		Name = "Breeze Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(226, 242, 255),
		Face = "Blink",
	},
	Gust = {
		Name = "Gust Sheep",
		WoolStyle = "Icicle",
		WoolColor = rgb(176, 216, 255),
		Face = "Dizzy",
		Extras = { extra("Cloud") },
	},
	Windswept = {
		Name = "Windswept Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(60, 170, 190),
		Face = "Dizzy",
		Extras = { extra("HeadWings") },
	},
	Tempest = {
		Name = "Tempest Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(110, 100, 170),
		Face = "Sly",
		Extras = { extra("Cloud", rgb(80, 80, 110)) },
	},
	Cyclone = {
		Name = "Cyclone Sheep",
		Build = "FrostSheep",
		WoolColor = rgb(240, 248, 255),
		SkinColor = rgb(220, 235, 250),
		FaceColor = rgb(230, 242, 255),
		LegColor = rgb(220, 235, 250),
		Face = "Dizzy",
		Extras = { extra("Cloud"), extra("Halo", rgb(200, 230, 255)) },
	},

	-- Hypnos: sleep.
	Poppy = {
		Name = "Poppy Sheep",
		WoolColor = rgb(252, 248, 246),
		Face = "Sleepy",
		Extras = { extra("Flower", rgb(230, 40, 40)) },
	},
	Snooze = {
		Name = "Snooze Sheep",
		WoolColor = rgb(196, 214, 255),
		Face = "Sleepy",
		Extras = { extra("Nightcap") },
	},
	Pillow = {
		Name = "Pillow Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 230, 240),
		WoolSize = 1.35,
		Face = "Sleepy",
		Extras = { extra("Star") },
	},
	Dreamcloud = {
		Name = "Dreamcloud Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(206, 180, 255),
		Face = "Sleepy",
		Extras = { extra("Cloud", rgb(240, 230, 255)), extra("Star") },
	},
	Sandman = {
		Name = "Sandman Sheep",
		Build = "DreamSheep",
		WoolColor = rgb(70, 80, 170),
		WoolSpotColor = rgb(240, 214, 120),
		FaceColor = rgb(170, 170, 230),
		Face = "Sleepy",
		Extras = { extra("Halo", rgb(240, 214, 120)) },
	},

	-- Morpheus: dreams.
	Stardust = {
		Name = "Stardust Sheep",
		WoolColor = rgb(44, 54, 120),
		FaceColor = rgb(200, 190, 240),
		LegColor = rgb(150, 140, 210),
		Face = "Happy",
		Extras = { extra("Star") },
	},
	Dreamer = {
		Name = "Dreamer Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(232, 192, 255),
		Face = "Blink",
		Extras = { extra("Moon") },
	},
	Comet = {
		Name = "Comet Sheep",
		Build = "CloudSheep",
		WoolColor = rgb(70, 80, 160),
		FaceColor = rgb(170, 180, 240),
		LegColor = rgb(130, 140, 210),
	},
	Nebula = {
		Name = "Nebula Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(200, 80, 255),
		WoolMaterial = Material.Neon,
		Face = "CosmicNebula",
		Extras = { extra("Star", rgb(120, 230, 255)) },
	},
	Dreamweaver = {
		Name = "Dreamweaver Sheep",
		Build = "BiblicallyAccurateFarmSheep",
		WoolColor = rgb(170, 140, 255),
		Extras = { extra("Halo", rgb(200, 170, 255)) },
	},

	-- Deimos: dread.
	Gloom = {
		Name = "Gloom Sheep",
		WoolColor = rgb(74, 74, 86),
		FaceColor = rgb(150, 150, 164),
		LegColor = rgb(110, 110, 124),
		Face = "Scared",
	},
	Bat = {
		Name = "Bat Sheep",
		WoolColor = rgb(92, 70, 112),
		FaceColor = rgb(60, 50, 70),
		LegColor = rgb(50, 44, 58),
		Face = "Sly",
		Extras = { extra("HeadWings", rgb(30, 26, 34)) },
	},
	Crater = {
		Name = "Crater Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(186, 186, 196),
		WoolSpotColor = rgb(96, 96, 108),
		Face = "Dizzy",
	},
	Eclipse = {
		Name = "Eclipse Sheep",
		WoolColor = rgb(22, 20, 30),
		FaceColor = rgb(60, 54, 70),
		LegColor = rgb(40, 36, 50),
		Extras = { extra("Moon", rgb(255, 90, 60)), extra("Halo", rgb(255, 90, 60)) },
	},
	VoidWatcher = {
		Name = "Void Watcher Sheep",
		Build = "AlienSheep",
		WoolColor = rgb(50, 26, 70),
		FaceColor = rgb(150, 110, 200),
		Extras = { extra("Eyeball", rgb(160, 60, 255)) },
	},

	-- Thanatos: a peaceful death.
	Ash = {
		Name = "Ash Sheep",
		WoolColor = rgb(176, 170, 166),
		Face = "Blink",
		Extras = { extra("Flower") },
	},
	Shade = {
		Name = "Shade Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(190, 200, 230),
		WoolMaterial = Material.Glass,
		Face = "Ghost",
	},
	Reaper = {
		Name = "Reaper Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(32, 30, 36),
		FaceColor = rgb(220, 214, 200),
		Face = "Sly",
		Extras = { extra("Scythe") },
	},
	Soul = {
		Name = "Soul Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(40, 200, 255),
		WoolMaterial = Material.Neon,
		Face = "Shy",
		Extras = { extra("Halo", rgb(160, 240, 255)) },
	},
	BoneKing = {
		Name = "Bone King Sheep",
		Build = "SkeletonSheep",
		FaceColor = rgb(244, 236, 216),
		LegColor = rgb(244, 236, 216),
		Extras = { extra("Crown"), extra("Scythe") },
	},

	-- Nemesis: retribution.
	Iron = {
		Name = "Iron Sheep",
		WoolColor = rgb(150, 156, 166),
		WoolMaterial = Material.Metal,
		Face = "Sly",
	},
	Blade = {
		Name = "Blade Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(64, 64, 76),
		Face = "Sly",
		Extras = { extra("Sword") },
	},
	ShadowMecha = {
		Name = "Shadow Mecha Sheep",
		Build = "MechaSheep",
		WoolColor = rgb(44, 44, 54),
		FaceColor = rgb(44, 44, 54),
		LegColor = rgb(44, 44, 54),
		Face = "Visor",
	},
	Reckoning = {
		Name = "Reckoning Sheep",
		Mutation = "Silver",
		Face = "Sly",
		Extras = { extra("Sword"), extra("Shield", rgb(200, 40, 40)) },
	},
	Vengeance = {
		Name = "Vengeance Sheep",
		Build = "MechaSheep",
		WoolColor = rgb(200, 40, 50),
		FaceColor = rgb(200, 40, 50),
		LegColor = rgb(160, 30, 40),
		Face = "Visor",
		Extras = { extra("Halo", rgb(255, 60, 60)) },
	},

	-- Dionysus: the vineyard.
	Vine = {
		Name = "Vine Sheep",
		WoolColor = rgb(140, 196, 90),
		Face = "Happy",
		Extras = { extra("Grapes") },
	},
	Berry = {
		Name = "Berry Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(220, 60, 110),
		WoolSpotColor = rgb(255, 230, 120),
		Face = "Happy",
		Extras = { extra("Leaf") },
	},
	Reveler = {
		Name = "Reveler Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(150, 30, 70),
		Face = "Laughing",
		Extras = { extra("Wreath"), extra("Grapes") },
	},
	GrapeKing = {
		Name = "Grape King Sheep",
		Build = "RoyalSheep",
		WoolColor = rgb(130, 70, 180),
		Extras = { extra("Grapes") },
	},
	Festival = {
		Name = "Festival Sheep",
		Build = "CottonCandySheep",
		WoolColor = rgb(150, 60, 200),
		WoolSpotColor = rgb(255, 200, 80),
		Face = "Laughing",
		Extras = { extra("Wreath", rgb(255, 200, 60)), extra("Grapes", rgb(255, 214, 90)) },
	},

	-- Hermes: the messenger.
	Swift = {
		Name = "Swift Sheep",
		WoolColor = rgb(236, 244, 255),
		Face = "Happy",
		Extras = { extra("HeadWings", rgb(120, 190, 255)) },
	},
	Trickster = {
		Name = "Trickster Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(240, 140, 50),
		Face = "Sly",
		Extras = { extra("Shades") },
	},
	Herald = {
		Name = "Herald Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 236, 196),
		Face = "Happy",
		Extras = { extra("HeadWings", rgb(255, 214, 90)), extra("Wings") },
	},
	Express = {
		Name = "Express Sheep",
		Build = "LongSheep",
		WoolColor = rgb(120, 190, 255),
		Face = "Happy",
		Extras = { extra("HeadWings") },
	},
	Quicksilver = {
		Name = "Quicksilver Sheep",
		Build = "CloudSheep",
		Mutation = "Silver",
		Face = "Happy",
		Extras = { extra("HeadWings", rgb(255, 214, 90)), extra("Halo") },
	},

	-- Hephaestus: the forge.
	Soot = {
		Name = "Soot Sheep",
		WoolColor = rgb(62, 60, 64),
		FaceColor = rgb(120, 110, 104),
		Face = "Blink",
	},
	Bronze = {
		Name = "Bronze Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(196, 124, 62),
		WoolMaterial = Material.Metal,
	},
	Smith = {
		Name = "Smith Sheep",
		WoolColor = rgb(124, 84, 54),
		Face = "Happy",
		Extras = { extra("Hammer") },
	},
	Molten = {
		Name = "Molten Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 90, 0),
		WoolMaterial = Material.Neon,
		FaceColor = rgb(90, 40, 30),
		Extras = { extra("Flame") },
	},
	Automaton = {
		Name = "Automaton Sheep",
		Build = "MechaSheep",
		WoolColor = rgb(214, 150, 60),
		FaceColor = rgb(214, 150, 60),
		LegColor = rgb(170, 110, 40),
		Face = "Visor",
		Extras = { extra("Flame"), extra("Hammer", rgb(255, 196, 60)) },
	},

	-- Ares: war.
	Recruit = {
		Name = "Recruit Sheep",
		WoolColor = rgb(124, 124, 76),
		Face = "Happy",
		Extras = { extra("Shield") },
	},
	BattleRam = {
		Name = "Battle Ram Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(110, 110, 122),
		Face = "Sly",
		HornStyle = "BigCurl",
		HornColor = rgb(40, 36, 40),
	},
	Warlord = {
		Name = "Warlord Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(130, 20, 26),
		Face = "Sly",
		Extras = { extra("Helmet"), extra("Sword") },
	},
	Gladiator = {
		Name = "Gladiator Sheep",
		WoolColor = rgb(170, 34, 34),
		WoolMaterial = Material.Metal,
		Extras = { extra("Helmet"), extra("Shield", rgb(255, 196, 60)) },
	},
	Wrath = {
		Name = "Wrath Sheep",
		Build = "LavaSheep",
		WoolColor = rgb(120, 20, 24),
		WoolSpotColor = rgb(60, 10, 14),
		FaceColor = rgb(40, 20, 20),
		LegColor = rgb(40, 20, 20),
		HornStyle = "FourHorn",
		HornColor = rgb(20, 16, 18),
		Extras = { extra("Flame", rgb(255, 50, 30)) },
	},

	-- Aphrodite: beauty and roses.
	Rosebud = {
		Name = "Rosebud Sheep",
		WoolColor = rgb(255, 196, 214),
		Face = "Shy",
		Extras = { extra("Flower", rgb(230, 30, 60)) },
	},
	Pearl = {
		Name = "Pearl Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(246, 242, 250),
		Face = "Happy",
		Extras = { extra("Collar", rgb(250, 250, 255)) },
	},
	Darling = {
		Name = "Darling Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 110, 170),
		Face = "Love",
		Extras = { extra("Bow", rgb(255, 255, 255)) },
	},
	CrystalRose = {
		Name = "Crystal Rose Sheep",
		WoolColor = rgb(220, 30, 70),
		WoolMaterial = Material.Glass,
		Face = "Love",
		Extras = { extra("Crown") },
	},
	LoveGoddess = {
		Name = "Love Goddess Sheep",
		Build = "CottonCandySheep",
		WoolColor = rgb(255, 250, 240),
		WoolSpotColor = rgb(255, 210, 120),
		Face = "Love",
		Extras = { extra("BackWings", rgb(255, 236, 170)), extra("Crown") },
	},

	-- Artemis: the hunt and the moon.
	Fawn = {
		Name = "Fawn Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(196, 132, 78),
		WoolSpotColor = rgb(250, 240, 225),
		FaceColor = rgb(170, 110, 64),
		LegColor = rgb(150, 96, 56),
		EarInnerColor = rgb(240, 200, 170),
	},
	Stag = {
		Name = "Stag Sheep",
		WoolColor = rgb(150, 105, 70),
		FaceColor = rgb(200, 160, 120),
		LegColor = rgb(130, 90, 60),
		Extras = { extra("Antlers") },
	},
	Huntress = {
		Name = "Huntress Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(50, 96, 64),
		Face = "Sly",
		Extras = { extra("Moon", rgb(230, 236, 255)) },
	},
	SilverStag = {
		Name = "Silver Stag Sheep",
		Mutation = "Silver",
		Extras = { extra("Antlers", rgb(225, 230, 245)) },
	},
	Moonbeam = {
		Name = "Moonbeam Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(70, 50, 240),
		WoolMaterial = Material.Neon,
		FaceColor = rgb(200, 205, 240),
		Extras = { extra("Antlers", rgb(220, 230, 255)), extra("Moon") },
	},

	-- Apollo: the sun.
	Sunny = {
		Name = "Sunny Sheep",
		WoolColor = rgb(255, 222, 90),
		Face = "Happy",
	},
	Dawn = {
		Name = "Dawn Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(255, 160, 110),
		Face = "Happy",
		Extras = { extra("Star", rgb(255, 230, 150)) },
	},
	Sunflower = {
		Name = "Sunflower Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 204, 40),
		FaceColor = rgb(110, 72, 40),
		LegColor = rgb(110, 72, 40),
		Face = "Happy",
		Extras = { extra("Leaf") },
	},
	Radiant = {
		Name = "Radiant Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 246, 220),
		Face = "Happy",
		Extras = { extra("SunRays") },
	},
	SolarFlare = {
		Name = "Solar Flare Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(255, 120, 0),
		WoolMaterial = Material.Neon,
		FaceColor = rgb(255, 220, 150),
		Face = "Happy",
		Extras = { extra("SunRays", rgb(255, 230, 90)), extra("Halo") },
	},

	-- Athena: wisdom and the olive.
	Olive = {
		Name = "Olive Sheep",
		WoolColor = rgb(150, 160, 90),
		Extras = { extra("Leaf", rgb(110, 130, 60)) },
	},
	Weaver = {
		Name = "Weaver Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(250, 248, 240),
		WoolSpotColor = rgb(60, 100, 190),
		WoolMaterial = Material.Fabric,
		Face = "Happy",
	},
	Owl = {
		Name = "Owl Sheep",
		WoolColor = rgb(140, 100, 60),
		FaceColor = rgb(230, 210, 170),
		Face = "Shy",
		Extras = { extra("HeadWings", rgb(110, 76, 46)) },
	},
	Aegis = {
		Name = "Aegis Sheep",
		Mutation = "Silver",
		Extras = { extra("Shield", rgb(255, 196, 60)), extra("Wreath", rgb(110, 130, 60)) },
	},
	OwlGoddess = {
		Name = "Owl Goddess Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(250, 250, 246),
		Face = "Happy",
		Extras = { extra("Helmet"), extra("Shield", rgb(255, 196, 60)), extra("BackWings") },
	},

	-- Demeter: the harvest.
	Wheat = {
		Name = "Wheat Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(235, 200, 110),
		Face = "Happy",
		Extras = { extra("Wheat") },
	},
	Haystack = {
		Name = "Haystack Sheep",
		WoolStyle = "Icicle",
		WoolColor = rgb(230, 190, 90),
		Face = "Happy",
	},
	Pumpkin = {
		Name = "Pumpkin Sheep",
		WoolColor = rgb(240, 130, 40),
		Face = "Happy",
		Extras = { extra("Leaf") },
	},
	HarvestQueen = {
		Name = "Harvest Queen Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(150, 60, 40),
		Face = "Happy",
		Extras = { extra("Wreath", rgb(235, 190, 80)), extra("Crown") },
	},
	EternalHarvest = {
		Name = "Eternal Harvest Sheep",
		Build = "MossSheep",
		WoolColor = rgb(255, 200, 60),
		WoolSpotColor = rgb(255, 226, 120),
		FaceColor = rgb(150, 110, 70),
		LegColor = rgb(120, 90, 60),
		HornStyle = "SmallCurl",
		HornColor = rgb(255, 214, 90),
		Extras = { extra("Wheat", rgb(255, 230, 120)), extra("Halo") },
	},

	-- Hestia: home and hearth.
	Cozy = {
		Name = "Cozy Sheep",
		WoolColor = rgb(250, 236, 212),
		Face = "Sleepy",
		Extras = { extra("Collar") },
	},
	Cinnamon = {
		Name = "Cinnamon Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(176, 104, 60),
		Face = "Happy",
	},
	Loaf = {
		Name = "Loaf Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(222, 160, 90),
		FaceColor = rgb(250, 230, 200),
		Face = "Happy",
	},
	Hearthkeeper = {
		Name = "Hearthkeeper Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(255, 80, 0),
		WoolMaterial = Material.Neon,
		FaceColor = rgb(120, 70, 50),
		Extras = { extra("Flame"), extra("Halo", rgb(255, 160, 60)) },
	},
	EternalFlame = {
		Name = "Eternal Flame Sheep",
		Build = "LavaSheep",
		WoolColor = rgb(255, 236, 190),
		WoolSpotColor = rgb(255, 200, 120),
		FaceColor = rgb(255, 214, 150),
		LegColor = rgb(240, 180, 110),
		Extras = { extra("Flame", rgb(255, 220, 90)), extra("Crown") },
	},

	-- Poseidon: the sea.
	Wave = {
		Name = "Wave Sheep",
		WoolColor = rgb(60, 140, 220),
		FaceColor = rgb(200, 230, 250),
		Face = "Happy",
	},
	Coral = {
		Name = "Coral Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(255, 120, 100),
		Face = "Happy",
	},
	Trident = {
		Name = "Trident Sheep",
		WoolColor = rgb(60, 180, 170),
		Face = "Sly",
		Extras = { extra("Trident") },
	},
	Kraken = {
		Name = "Kraken Sheep",
		Build = "SlimeSheep",
		WoolColor = rgb(120, 60, 170),
		FaceColor = rgb(120, 60, 170),
		LegColor = rgb(120, 60, 170),
		EarInnerColor = rgb(180, 130, 230),
		Face = "Sly",
	},
	SeaKing = {
		Name = "Sea King Sheep",
		Build = "OceanSheep",
		WoolColor = rgb(80, 150, 255),
		FaceColor = rgb(150, 200, 250),
		LegColor = rgb(120, 180, 240),
		Extras = { extra("Crown"), extra("Trident") },
	},

	-- Hera: the queen.
	Lady = {
		Name = "Lady Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(204, 176, 232),
		Face = "Shy",
		Extras = { extra("Bow", rgb(140, 70, 200)) },
	},
	Peacock = {
		Name = "Peacock Sheep",
		WoolStyle = "Spotted",
		WoolColor = rgb(40, 150, 140),
		WoolSpotColor = rgb(40, 90, 210),
		Face = "Happy",
	},
	Empress = {
		Name = "Empress Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(252, 250, 255),
		Extras = { extra("Crown"), extra("Collar", rgb(250, 250, 255)) },
	},
	SilverQueen = {
		Name = "Silver Queen Sheep",
		Mutation = "Silver",
		WoolStyle = "Ringlets",
		Extras = { extra("Crown"), extra("Halo", rgb(200, 220, 255)) },
	},
	PeacockRoyal = {
		Name = "Peacock Royal Sheep",
		Build = "RoyalSheep",
		WoolColor = rgb(40, 160, 150),
		Extras = { extra("Halo") },
	},

	-- Zeus: the king of the gods.
	Thundercloud = {
		Name = "Thundercloud Sheep",
		WoolStyle = "Cloud",
		WoolColor = rgb(96, 100, 122),
		Face = "Sly",
		Extras = { extra("Bolt") },
	},
	Eagle = {
		Name = "Eagle Sheep",
		WoolColor = rgb(124, 84, 54),
		FaceColor = rgb(250, 250, 245),
		Extras = { extra("HeadWings", rgb(100, 66, 40)) },
	},
	Lightning = {
		Name = "Lightning Sheep",
		WoolStyle = "Icicle",
		WoolColor = rgb(255, 210, 0),
		WoolMaterial = Material.Neon,
		FaceColor = rgb(90, 96, 136),
		Face = "Sly",
		Extras = { extra("Bolt", rgb(120, 200, 255)) },
	},
	GoldenFleece = {
		Name = "Golden Fleece Sheep",
		WoolStyle = "Ringlets",
		WoolColor = rgb(255, 205, 60),
		WoolMaterial = Material.Foil,
		WoolSize = 1.25,
		Face = "Happy",
		HornStyle = "BigCurl",
		HornColor = rgb(190, 110, 40),
		Extras = { extra("Wreath", rgb(110, 170, 70)) },
	},
	KingOfOlympus = {
		Name = "King of Olympus Sheep",
		Build = "BiblicallyAccurateFarmSheep",
		WoolColor = rgb(255, 250, 235),
		Extras = { extra("Crown"), extra("Bolt") },
	},
}) :: { [string]: { [string]: any } }

return table.freeze(Herds)
