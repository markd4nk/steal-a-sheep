--!strict

-- Each god's Roblox avatar (Avatar.Build): a dynamic head (the classic angry face), catalog accessories by asset id
-- (rigid: Hair, Hat, Face, Neck, Shoulder, Front, Back, Waist; layered clothing: Shirt, Pants, Jacket, Sweater,
-- Shorts, DressSkirt, TShirt, LeftShoe, RightShoe), classic clothing, and the symbol held in its fist (Props).
-- Skin is the tier's (Config/Olympus). A game may dress its NPCs in any catalog item without owning it; an item
-- Roblox removes just stops loading, so prefer Roblox's own items and established creators.

export type Item = { Id: number, Type: string }

export type Look = {
	Head: number,
	Accessories: { Item },
	Shirt: number?,
	Pants: number?,
	Torso: Color3?, -- the body's colour under the clothes when it isn't skin
	Legs: Color3?,
	Prop: string?,
	Raise: boolean?, -- holds the symbol overhead (the client lifts the arm)
}

local ANGRY = 90077016726721 -- "Classic Style Angry Face" (Lastinker), the user's pick
local FURIOUS = 76927731769378 -- "Furious Woman Face" (pull my finger): the goddesses' match, lashes and lipstick

local Looks: { [string]: Look } = {
	Pan = {
		Head = ANGRY,
		Accessories = {
			{ Id = 15596439186, Type = "Hair" }, -- Messy Brown Curly Hair (deathraces)
			{ Id = 108705374974944, Type = "Face" }, -- Greek Mythology God Beard Brown (U8DEV)
			{ Id = 511982542, Type = "Hat" }, -- Satyr Horns (Roblox)
			{ Id = 114506513540672, Type = "Hat" }, -- Elf Leaf Crown (NS's)
			{ Id = 10321646893, Type = "Pants" }, -- Satyr Goat Pants (Reverse_Polarity)
		},
		Prop = "Pipes",
	},
	Tyche = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 80690138914100, Type = "Hair" }, -- Curly Up-do Roman Beauty Hair in Brown (Dynasty of Dragons)
			{ Id = 90912729242834, Type = "Hat" }, -- Gold Crown (What's Cooking UGC): her city-wall crown
			{ Id = 89998676807311, Type = "Neck" }, -- Gold Coin Chain (trapstas)
			{ Id = 140163363347672, Type = "DressSkirt" }, -- Green Halter Fey Goddess Gold Thorned Dress (Dollirious)
		},
		Prop = "Cornucopia",
	},
	Hecate = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 112502348835139, Type = "Hair" }, -- Black Goddess Wave Curly Wind Swept Hair (PearlLilac Studios)
			{ Id = 101597828204104, Type = "Hat" }, -- Black Moon Flower Tiara (Flowers'3): three crescents
			{ Id = 100022125281293, Type = "Back" }, -- Blue Celestial Long Ornate Veil (Embryo)
			{ Id = 70712942788847, Type = "DressSkirt" }, -- Black & gold lunar goddess dress (Blue infinity studios)
		},
		Prop = "Torch",
	},
	Phobos = {
		Head = ANGRY,
		Accessories = {
			{ Id = 114387329234064, Type = "Hat" }, -- Silver & Red Spartan Armor Helmet (Yams.)
			{ Id = 133997633918776, Type = "Front" }, -- Silver Spartan Armor Chestplate (Yams.)
			{ Id = 80328335083467, Type = "Waist" }, -- Silver & Red Spartan Armor Waist (Yams.)
			{ Id = 92061872936251, Type = "Back" }, -- Red Greek Shoulder Cloak (Hearthpoint)
		},
		Prop = "DarkSpear",
	},
	Eris = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 83692489742591, Type = "Hair" }, -- Wild messy big bed hair, dark purple (B.C. Boutique)
			{ Id = 97080565331375, Type = "Hat" }, -- Gold Star Spire Crown (Starlait)
			{ Id = 18889375918, Type = "Neck" }, -- Golden Apple Necklace (MadeByMilan)
			{ Id = 134832436952102, Type = "DressSkirt" }, -- Dark purple & gold gown (Blue infinity studios)
		},
		Prop = "Apple",
	},
	Eros = {
		Head = ANGRY,
		Accessories = {
			{ Id = 89993136416566, Type = "Hair" }, -- Blonde Curly Messy Beach Hair Men (Crooner)
			{ Id = 107066015789581, Type = "Back" }, -- Cupid Angel Wings White (rusalka)
			{ Id = 134273227108503, Type = "Waist" }, -- Red Royal Lower Cloak / Chiton with golden chains (Embryo)
		},
		Shirt = 6385312834, -- Cupid Shirt (FancySuitandTie): a bow strap and a heart
		Prop = "PinkBow",
	},
	Hebe = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 128885797383834, Type = "Hair" }, -- Curly Up-do Roman Beauty Hair in Blonde (Dynasty of Dragons)
			{ Id = 8918679960, Type = "Hat" }, -- Flower Crown (inkwaves)
			{ Id = 97145004642533, Type = "DressSkirt" }, -- White and gold celestial goddess dress (Blue infinity)
		},
		Prop = "Cup",
	},
	Themis = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 18701454932, Type = "Hair" }, -- Black Roman Goddess Hair with Gold Diadem (The Roman Empire)
			{ Id = 3984208381, Type = "Hat" }, -- White Blindfold (Yourius)
			{ Id = 10858158528, Type = "Shoulder" }, -- Libra Judgement Scales (Dev_R0VER)
			{ Id = 125560695476525, Type = "DressSkirt" }, -- White divine goddess dress (Blue infinity studios)
		},
		Prop = "Sword",
	},
	Asclepius = {
		Head = ANGRY,
		Accessories = {
			{ Id = 78729006611667, Type = "Hair" }, -- Curly Beach Messy Boy Hair, White (vsae)
			{ Id = 83727794341050, Type = "Face" }, -- Greek Mythology God Beard White (U8DEV)
			{ Id = 121356827064508, Type = "Hat" }, -- Epiarchos' Green Laurel (Ancient World)
			{ Id = 125611679044161, Type = "Neck" }, -- green snake scarf (WX+)
			{ Id = 17534280016, Type = "Shirt" }, -- Robe - Gilded White (Hund Corp)
		},
		Prop = "Serpent",
	},
	Iris = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 133583483202813, Type = "Hair" }, -- Aqua Blue Goddess Wave Curly Wind Swept Hair (PearlLilac Studios)
			{ Id = 4773876737, Type = "Hat" }, -- Rainbow Halo (Jazzyx3)
			{ Id = 335080396, Type = "Back" }, -- Rainbow Wings (Roblox)
			{ Id = 122606047590904, Type = "DressSkirt" }, -- White greek goddess dress (Blue infinity studios)
		},
		Prop = "Rainbow",
	},
	Ares = {
		Head = ANGRY,
		Accessories = {
			{ Id = 77644039974503, Type = "Hat" }, -- Spartan Helmet (Imperial Emporium): bronze, red crest
			{ Id = 72775095656198, Type = "Face" }, -- Greek Mythology God Beard Black (U8DEV)
			{ Id = 98377862985485, Type = "Front" }, -- Greek Hoplite Cuirass, Gold & Red (Olympus Reforged)
			{ Id = 96582076759122, Type = "Back" }, -- Red Cape (The orange squid)
		},
		Shirt = 9673807193, -- Red Tunic [+]
		Pants = 9673807979, -- Red Tunic [-]
		Prop = "Spear",
	},
	Aphrodite = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 131707094706813, Type = "Hair" }, -- Long Mermaid Flowy Hair in Golden Blonde (Rosemary N ' Thyme)
			{ Id = 71428476755706, Type = "Hat" }, -- Rose Crown (TYC Limiteds)
			{ Id = 86492220957063, Type = "DressSkirt" }, -- Cute pink greek goddess dress (Blue infinity studios)
		},
		Prop = "Rose",
	},
	Artemis = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 83952525173944, Type = "Hair" }, -- Auburn Artemis Braided Princess Hair (Dynasty of Dragons)
			{ Id = 95965657488620, Type = "Hat" }, -- White Moon Flower Tiara (Flowers'3)
			{ Id = 7245489970, Type = "Back" }, -- Retro Arrow Quiver, Dark Brown (144hertz)
			{ Id = 126855889696633, Type = "DressSkirt" }, -- Baby blue greek goddess dress (Blue infinity studios)
		},
		Prop = "SilverBow",
	},
	Apollo = {
		Head = ANGRY,
		Accessories = {
			{ Id = 71369467772630, Type = "Hair" }, -- Blonde Messy Classical Greek Curly Hair (Crooner)
			{ Id = 133254339316338, Type = "Hat" }, -- The Sun's Halo (ShadedSmiles Co)
			{ Id = 73572433663172, Type = "Jacket" }, -- Rulai Golden Robe (Talisman Studios)
		},
		Prop = "Lyre",
	},
	Athena = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 8852944318, Type = "Hair" }, -- Divinité Athena Swirls in Black (BUNNEXH)
			{ Id = 18564331174, Type = "Hat" }, -- Tribune Helmet with Blue Plume (The Roman Empire)
			{ Id = 77835895361919, Type = "Back" }, -- Athenian Shield (Shed Out Back): an owl
			{ Id = 103223636900069, Type = "DressSkirt" }, -- White Greek Dress (Tilted Tree Studios)
		},
		Prop = "Spear",
	},
	Demeter = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 91555226687899, Type = "Hair" }, -- Blonde Princess Curls w/ Braids Hair (Dynasty of Dragons)
			{ Id = 77058499029907, Type = "Hat" }, -- Harvest Festival Wheat Crown (OtisLittleUGC)
			{ Id = 72278982864491, Type = "DressSkirt" }, -- Lime green draped column dress (Blue infinity studios)
		},
		Prop = "Wheat",
	},
	Hestia = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 77274794104816, Type = "Hair" }, -- Brown Simple Braid Straight Princess Hair (Dynasty of Dragons)
			{ Id = 131535467836022, Type = "Back" }, -- Red Celestial Long Ornate Veil (Embryo)
			{ Id = 138587417354165, Type = "DressSkirt" }, -- Light Greek Tunic (Tilted Tree Studios): flame colours
		},
		Prop = "Flame",
	},
	Poseidon = {
		Head = ANGRY,
		Accessories = {
			{ Id = 124783930035651, Type = "Hair" }, -- Teal Long Wavy Styled Hair (exactly ablimity)
			{ Id = 16756576370, Type = "Face" }, -- Stylized Blue Beard (Fun First Studio)
			{ Id = 82986468953483, Type = "Hat" }, -- Ocean's Shell Coral Crown, Blue (Dollirious)
			{ Id = 140177046199076, Type = "DressSkirt" }, -- Snow Greek Tunic (Tilted Tree Studios): sea blue
		},
		Prop = "Trident",
	},
	Hera = {
		Head = FURIOUS,
		Accessories = {
			{ Id = 12359280292, Type = "Hair" }, -- Black Goddess Aesthetic Messy Curly Updo (ComfySunday)
			{ Id = 74785981738938, Type = "Hat" }, -- Amethyst Crown (plàtan)
			{ Id = 129913829039644, Type = "Back" }, -- Majestic Peacock Tail Feathers (Mercina)
		},
		Shirt = 113044949531391, -- Purple Toga [+]
		Pants = 95807529558217, -- Purple Toga [-]
		Prop = "Sceptre",
	},
	Zeus = {
		Head = ANGRY,
		Accessories = {
			{ Id = 126795757748952, Type = "Hair" }, -- Greek Mythology God Hair White (U8DEV)
			{ Id = 76239336562150, Type = "Face" }, -- Greek Mythology God Beard Grey (U8DEV)
			{ Id = 10770304, Type = "Hat" }, -- Crown of Golden Laurels (Roblox)
			{ Id = 87233169181342, Type = "Back" }, -- Ancient Greece Greek God Robe (Manga Infinite)
		},
		Prop = "Bolt",
		Raise = true,
	},
}

return table.freeze(Looks)
