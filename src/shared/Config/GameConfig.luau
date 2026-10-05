--!strict

-- Tunable numbers shared with clients (nothing here is secret). The mountain's tiers and their gods are in
-- Config/Olympus; the economy's formulas are in Utils/Economy. The sheep, carry and UI sections are Shear a Sheep's,
-- kept in the same shape so its Looks, CarryPose, SheepRigLayout and UI kit work unchanged.

export type WoolStyle = "Puffs" | "Ringlets" | "Cloud" | "Icicle" | "Spotted"
export type HornStyle = "SmallCurl" | "BigCurl" | "Spiral" | "FourHorn"
export type Accessory = "Antennae" | "WolfHead"
export type SpecialFX =
	"LavaGlow"
	| "LavaLight"
	| "StormSparks"
	| "Stars"
	| "Sparkles"
	| "MoonGlow"
	| "Spores"
	| "Wisps"

-- One sheep look (Shear a Sheep's Breed record): every family is one of these on the shared sheep rig.
export type Breed = {
	Id: string,
	DisplayName: string,
	WoolColor: Color3,
	WoolSpotColor: Color3?,
	WoolMaterial: Enum.Material,
	WoolSize: number,
	WoolStyle: WoolStyle,
	FaceColor: Color3,
	Face: string,
	LegColor: Color3,
	SkinColor: Color3,
	SkinMaterial: Enum.Material,
	Scale: number,
	HornStyle: HornStyle?,
	HornColor: Color3,
	Accessory: Accessory?,
	Build: string?,
	EarInnerColor: Color3?,
	FaceOverlay: string?,
	BaaPitch: number,
	SpecialFX: SpecialFX?,
	Mutation: string?, -- a fleece paint laid over the wool (Silver, Rainbow, Gold)
	Extra: string?, -- a primitive accessory SheepService adds (Leaf, Helmet, Wreath, Wings, BackWings, Blindfold, Flame)
}

export type Mutation = {
	Id: string,
	DisplayName: string,
	Color: Color3,
	Material: Enum.Material,
	Rainbow: boolean?,
	SparkleColor: Color3?,
}

local rgb = Color3.fromRGB

local function deepFreeze<T>(value: T): T
	if type(value) == "table" and not table.isfrozen(value :: any) then
		for _, child in value :: any do
			deepFreeze(child)
		end
		table.freeze(value :: any)
	end
	return value
end

-- Every sheep's base size. Adults grow to this times their size class (Economy.Sizes); lambs are smaller.
local SHEEP_SIZE = 1.6

local function look(id: string, name: string, overrides: { [string]: any }): Breed
	local breed: Breed = {
		Id = id,
		DisplayName = name,
		WoolColor = rgb(248, 248, 242),
		WoolMaterial = Enum.Material.SmoothPlastic,
		WoolSize = 1,
		WoolStyle = "Puffs",
		FaceColor = rgb(238, 216, 182),
		Face = "Idle",
		LegColor = rgb(238, 216, 182),
		SkinColor = rgb(242, 186, 180),
		SkinMaterial = Enum.Material.SmoothPlastic,
		Scale = SHEEP_SIZE,
		HornColor = rgb(238, 222, 190),
		BaaPitch = 1,
	}
	for key, value in overrides do
		(breed :: any)[key] = value
	end
	return breed
end

-- The thirty families' looks, keyed by family id (Config/Olympus). Most are Shear a Sheep breeds as they are, in its
-- colours; the Grape, War, Laurel, Cupid, Justice, Victory and Hearth sheep are its plain breeds recoloured, with a
-- primitive extra, and the Prism Sheep a plain one in rainbow puffs.
local breeds: { [string]: Breed } = {
	Meadow = look("Meadow", "Meadow Sheep", {
		Build = "ScarecrowSheep",
		WoolColor = rgb(227, 192, 95),
		FaceColor = rgb(200, 164, 112),
		FaceOverlay = "Seams",
		LegColor = rgb(200, 164, 112),
		EarInnerColor = rgb(176, 138, 92),
	}),
	Grape = look("Grape", "Grape Sheep", {
		WoolColor = rgb(128, 70, 170),
		WoolStyle = "Ringlets",
		FaceColor = rgb(214, 196, 236),
		LegColor = rgb(214, 196, 236),
		Extra = "Leaf",
	}),
	Moon = look("Moon", "Moon Sheep", {
		Build = "MoonSheep",
		WoolColor = rgb(255, 226, 130),
		WoolSpotColor = rgb(214, 178, 96),
		FaceColor = rgb(150, 156, 186),
		LegColor = rgb(120, 126, 160),
		EarInnerColor = rgb(220, 210, 240),
		SpecialFX = "MoonGlow",
		Mutation = "Silver",
	}),
	Ember = look("Ember", "Ember Sheep", {
		Build = "LavaSheep",
		WoolColor = rgb(54, 46, 48),
		WoolSpotColor = rgb(68, 58, 58),
		FaceColor = rgb(124, 34, 30),
		LegColor = rgb(92, 30, 28),
		SkinColor = rgb(132, 38, 32),
		EarInnerColor = rgb(255, 140, 90),
		SpecialFX = "LavaLight",
	}),
	War = look("War", "War Sheep", {
		WoolColor = rgb(178, 40, 36),
		FaceColor = rgb(40, 36, 38),
		LegColor = rgb(40, 36, 38),
		HornStyle = "Spiral",
		HornColor = rgb(72, 48, 34),
		Extra = "Helmet",
	}),
	Rose = look("Rose", "Rose Sheep", {
		Build = "CottonCandySheep",
		WoolColor = rgb(255, 170, 214),
		WoolSpotColor = rgb(214, 186, 255),
		SpecialFX = "Wisps",
		Face = "Love",
	}),
	Sun = look("Sun", "Sun Sheep", {
		Build = "SolarSystemSheep",
		WoolColor = rgb(255, 214, 80),
		WoolSpotColor = rgb(255, 180, 60),
		FaceColor = rgb(255, 196, 96),
		LegColor = rgb(220, 130, 50),
		EarInnerColor = rgb(255, 230, 160),
	}),
	Laurel = look("Laurel", "Laurel Sheep", {
		WoolColor = rgb(250, 250, 246),
		WoolSize = 1.3,
		FaceColor = rgb(240, 228, 198),
		LegColor = rgb(240, 228, 198),
		Extra = "Wreath",
	}),
	Tide = look("Tide", "Tide Sheep", {
		Build = "OceanSheep",
		WoolColor = rgb(250, 252, 255),
		FaceColor = rgb(150, 212, 242),
		LegColor = rgb(150, 210, 228),
		EarInnerColor = rgb(180, 225, 245),
	}),
	Wingfoot = look("Wingfoot", "Wingfoot Sheep", {
		Build = "CloudSheep",
		WoolColor = rgb(253, 254, 255),
		WoolSpotColor = rgb(196, 222, 250),
		FaceColor = rgb(140, 200, 250),
		LegColor = rgb(140, 200, 250),
		Extra = "Wings",
	}),
	Crown = look("Crown", "Crown Sheep", { Build = "RoyalSheep" }),
	Gale = look("Gale", "Gale Sheep", {
		Build = "FrostSheep",
		WoolColor = rgb(170, 222, 255),
		SkinColor = rgb(196, 226, 250),
		FaceColor = rgb(214, 238, 255),
		LegColor = rgb(196, 228, 252),
		EarInnerColor = rgb(160, 205, 250),
	}),
	Prism = look("Prism", "Prism Sheep", { WoolSize = 1.15, Face = "Happy", Mutation = "Rainbow" }),
	Wild = look("Wild", "Wild Sheep", {
		Build = "MossSheep",
		WoolColor = rgb(84, 138, 58),
		WoolSpotColor = rgb(108, 160, 68),
		FaceColor = rgb(122, 96, 70),
		LegColor = rgb(98, 76, 56),
		EarInnerColor = rgb(206, 172, 140),
		HornStyle = "SmallCurl",
		HornColor = rgb(122, 84, 58),
		SpecialFX = "Spores",
	}),
	Ambrosia = look("Ambrosia", "Ambrosia Sheep", { Build = "CupcakeSheep", WoolColor = rgb(255, 214, 140) }),
	Cupid = look("Cupid", "Cupid Sheep", {
		WoolColor = rgb(255, 196, 214),
		WoolStyle = "Cloud",
		FaceColor = rgb(255, 228, 234),
		LegColor = rgb(255, 228, 234),
		Face = "Love",
		Extra = "BackWings",
	}),
	Fortune = look("Fortune", "Fortune Sheep", { Build = "PirateSheep", FaceOverlay = "Eyepatch" }),
	Potion = look("Potion", "Potion Sheep", {
		Build = "SlimeSheep",
		WoolColor = rgb(120, 225, 90),
		FaceColor = rgb(120, 225, 90),
		LegColor = rgb(120, 225, 90),
		EarInnerColor = rgb(170, 240, 140),
	}),
	Chaos = look("Chaos", "Chaos Sheep", { Build = "GlitchSheep" }),
	Spirit = look("Spirit", "Spirit Sheep", { Build = "GhostSheep", WoolColor = rgb(246, 246, 252), Face = "Ghost" }),
	Slumber = look("Slumber", "Slumber Sheep", {
		Build = "DreamSheep",
		WoolColor = rgb(255, 198, 222),
		WoolSpotColor = rgb(214, 190, 255),
		FaceColor = rgb(190, 170, 240),
		Face = "Blink",
		LegColor = rgb(190, 170, 240),
		EarInnerColor = rgb(255, 196, 224),
		SpecialFX = "Sparkles",
	}),
	Starlit = look("Starlit", "Starlit Sheep", {
		Build = "GalaxySheep",
		WoolColor = rgb(58, 40, 120),
		FaceColor = rgb(84, 60, 160),
		Face = "CosmicNebula",
		LegColor = rgb(31, 29, 71),
		EarInnerColor = rgb(200, 150, 255),
		SpecialFX = "Stars",
	}),
	Fright = look("Fright", "Fright Sheep", { Build = "WolfInSheepsClothing", Face = "Sly", BaaPitch = 0.95 }),
	Dread = look("Dread", "Dread Sheep", {
		Build = "BlackHoleSheep",
		FaceColor = rgb(236, 230, 246),
		Face = "Dizzy",
		LegColor = rgb(210, 200, 230),
	}),
	Bone = look("Bone", "Bone Sheep", {
		Build = "SkeletonSheep",
		FaceColor = rgb(244, 236, 216),
		LegColor = rgb(244, 236, 216),
	}),
	Avenger = look("Avenger", "Avenger Sheep", {
		Build = "MechaSheep",
		WoolColor = rgb(238, 241, 246),
		FaceColor = rgb(238, 241, 246),
		Face = "Visor",
		LegColor = rgb(238, 241, 246),
	}),
	Justice = look("Justice", "Justice Sheep", {
		WoolColor = rgb(246, 244, 236),
		WoolStyle = "Ringlets",
		WoolSize = 1.2,
		FaceColor = rgb(238, 226, 200),
		LegColor = rgb(238, 226, 200),
		Extra = "Blindfold",
	}),
	Victory = look("Victory", "Victory Sheep", {
		WoolColor = rgb(255, 226, 140),
		WoolSize = 1.2,
		FaceColor = rgb(250, 236, 200),
		LegColor = rgb(250, 236, 200),
		Face = "Happy",
		Extra = "BackWings",
	}),
	Hearth = look("Hearth", "Hearth Sheep", {
		WoolColor = rgb(232, 128, 72),
		WoolSpotColor = rgb(250, 176, 90),
		WoolStyle = "Ringlets",
		FaceColor = rgb(120, 70, 50),
		LegColor = rgb(120, 70, 50),
		EarInnerColor = rgb(255, 170, 110),
		SpecialFX = "LavaLight",
		Extra = "Flame",
	}),
	Thunder = look("Thunder", "Thunder Sheep", {
		Build = "StormSheep",
		WoolColor = rgb(66, 62, 104),
		WoolSpotColor = rgb(52, 50, 86),
		FaceColor = rgb(92, 98, 136),
		LegColor = rgb(72, 76, 104),
		EarInnerColor = rgb(200, 210, 250),
		SpecialFX = "StormSparks",
	}),
}

local mutations: { [string]: Mutation } = {
	Silver = {
		Id = "Silver",
		DisplayName = "Silver",
		Color = rgb(206, 214, 226),
		Material = Enum.Material.Metal,
	},
	-- Iris's Prism Sheep: every puff its own colour of the rainbow (Utils/Mutations.PuffColor).
	Rainbow = {
		Id = "Rainbow",
		DisplayName = "Rainbow",
		Color = rgb(190, 160, 255),
		Material = Enum.Material.SmoothPlastic,
		Rainbow = true,
	},
	Gold = {
		Id = "Gold",
		DisplayName = "Gold",
		Color = rgb(255, 190, 36),
		Material = Enum.Material.Metal,
		SparkleColor = rgb(255, 214, 90),
	},
}

local GameConfig = {
	Name = "Steal a Sheep",

	SheepSize = SHEEP_SIZE,
	Breeds = breeds,
	Mutations = mutations,

	-- Studs per second.
	Movement = {
		WalkSpeed = 18,
		JumpPower = 50,
		SlideMinStart = 6, -- moving downhill at least this fast on the ramp starts a slide
		SlideAccel = 26, -- studs a second a slide gains each second, before a sheep's burden
		SlideBrake = 40, -- studs a second pulling back takes off each second (the same with any burden)
		SlideStopSpeed = 4, -- under this a slide ends
		SlideHeading = 0.7, -- how far either side of straight downhill a slider can steer (0 none, 1 sideways)
		SlideTurnRate = 2.5, -- how fast the heading follows the stick, per second
	},

	-- Aimed slides into uphill players.
	SlideHit = {
		MinSpeed = 16, -- the slider's speed for a hit to count
		Reach = 4.5, -- studs between the two roots
		KnockStuds = 7,
		KnockSeconds = 0.32,
		StunSeconds = 0.5,
		ProtectSeconds = 2,
		SpeedLoss = 0.2, -- of the slider's speed, after a hit
		SeparateStuds = 8, -- the slider must get this far away before hitting the same player again
	},

	-- Picking up a wild lamb and running home with it.
	Theft = {
		HoldSeconds = 0.5,
		HeadStart = 1.5, -- seconds before the god sets off
		RefillSeconds = 15, -- an empty spawn after a delivery
		PromptDistance = 10,
		CatchStuds = 3.5,
		CatchCheckEvery = 0.1,
		InventoryLimit = 100,
		DeliverStuds = 9, -- from the delivery pad's centre
	},

	Training = {
		TickSeconds = 0.25,
	},

	-- Offline earnings: a quarter of at most two hours.
	Offline = {
		MaxSeconds = 2 * 60 * 60,
		Share = 0.25,
		MinCredit = 1, -- coins under this aren't worth a summary
	},

	Sheep = {
		DetailColors = {
			EarInner = rgb(250, 176, 180),
		} :: { [string]: Color3 },
		Faces = {
			Idle = "rbxassetid://127611410912862",
			Blink = "rbxassetid://101894320718110",
			Happy = "rbxassetid://139092813398281",
			Laughing = "rbxassetid://109043028377642",
			Love = "rbxassetid://94746343676017",
			Scared = "rbxassetid://137849782290355",
			Shy = "rbxassetid://114475926758943",
			Sleepy = "rbxassetid://139297296211110",
			Dizzy = "rbxassetid://71188327105861",
			Baa = "rbxassetid://130392269182249",
			Sly = "rbxassetid://75523291480618",
			Seams = "rbxassetid://94306971506667",
			Alien = "rbxassetid://73494463527401",
			CosmicNebula = "rbxassetid://119697508448923",
			Visor = "rbxassetid://82292653566945",
			Ghost = "rbxassetid://75213874763495",
			Eyepatch = "rbxassetid://119654690639983",
		} :: { [string]: string },
		WoolSpread = 0.5,
	},

	SheepMotion = {
		AnimationRange = 70,
		MaxAnimatedSheep = 50,
		BaaEvery = { 6, 16 } :: { number },
		BaaVolume = 0.125,
		BaaHearing = 60,
		BaaSounds = {
			"rbxassetid://9119066777",
			"rbxassetid://9119065374",
			"rbxassetid://9119066036",
			"rbxassetid://9119065840",
			"rbxassetid://9119065619",
			"rbxassetid://9119066033",
		} :: { string },
	},

	-- Shear a Sheep's overhead carry: arms up, the sheep held like a trophy (Utils/CarryPose, CarryController).
	Carry = {
		ShrinkFrom = 1.5,
		ShrunkScale = 1.3,
		PickUpSeconds = 0.3,
		PutDownSeconds = 0.3,
		ShoulderRaise = 165,
		ShoulderRollMin = -10,
		ShoulderRollMax = 30,
		PalmSpread = 0.7,
		ArmClearance = 0.05,
		ElbowBend = 20,
		WristBend = 35,
		PalmSink = 0.1,
		HeadClearance = 0.15,
		WaistLean = 4,
		WaistSteady = 0.5,
		SwayDegrees = 2,
		SwaySeconds = 2.6,
		PoseRange = 100,
	},

	Settings = {
		VolumeStep = 0.1,
		Defaults = {
			MusicVolume = 1,
			SfxVolume = 1,
			ReduceMotion = false,
			LowGraphics = false,
		},
	},

	Ui = {
		NoticeSeconds = 2.5,
		NoticeQueue = 4,
		BannerSeconds = 4,
	},
}

return deepFreeze(GameConfig)
