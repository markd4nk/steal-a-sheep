--!strict

-- Every sound the game plays except the baas (GameConfig.SheepMotion.BaaSounds) and the wolf alert's howl
-- (StarterGui.WolfAlert.Howl, whose volume is WarningHowlVolume). All are Roblox's own licensed Creator Store audio (Pro Sound Effects sounds, APM Music
-- tracks), which any experience may play. SoundController plays them; nothing here is secret.

export type Group = "Effects" | "Music" | "Ambience"

-- A one-shot. 2D copies are pooled (Voices); 3D ones are made at the spot and fade out past Range.
export type Effect = {
	Id: string,
	Volume: number,
	Group: Group?, -- Effects when left out
	Speed: number?, -- playback speed (higher is higher-pitched and shorter); 1 when left out
	Jitter: number?, -- each play's speed is off by up to this share either way, so repeats don't sound canned
	Gap: number?, -- seconds before it can play again; plays inside the gap are dropped
	Voices: number?, -- 2D copies that can ring at once; the oldest is cut off after that (1 when left out)
	Start: number?, -- seconds into the audio each play starts, to skip silence at its head
	Length: number?, -- seconds of audio played from Start; the rest is cut (one hit out of a clip of several)
	Range: number?, -- studs a 3D play carries (DefaultRange when left out)
	Near: number?, -- studs from a 3D play inside which it's at full volume (10 when left out)
}

export type Track = {
	Name: string,
	Id: string,
	Volume: number,
}

local Sounds = {
	-- Mix volumes: every sound in a group is multiplied by its group's.
	Groups = {
		Effects = 0.8,
		Music = 0.5,
		Ambience = 0.6,
	} :: { [string]: number },

	DefaultRange = 80,

	-- The warning howl when a wolf comes for your sheep (StarterGui.WolfAlert.Howl, Pro Sound Effects 9120790529), in
	-- the Effects group (Mark, 2026-10-02: a little louder, so nobody misses it; it was the place's 0.8).
	WarningHowlVolume = 1.05,

	-- Each comment gives the asset's Creator Store name. Picked from their descriptions, checked to load, and measured
	-- for silence at the head (Start); not listened to yet.
	Effects = {
		-- Shearing: a crisp snip and the pop of the wool coming off, together on every shear, the player's own and
		-- (heard from the sheep) everyone else's, the same on every device. Mark, 2026-10-04: the pop in place of the
		-- cash's ding and coin, and of Poof's cloth flap, which couldn't be heard under the snip. Loudest 0.1 s,
		-- A-weighted, at these volumes: the pop about 5 dB over the snip (the ding and coin together were level with it).
		-- Scissors Various Cuts Squeaky Snips 10: the user's pick, one loud snip at 0.05 s and a short tail, played whole.
		-- (Before it: Scissors Snap 21, a thin click, then one snip out of Garden Shears Cutting Brush Ivy Leaves Snips 11.)
		Snip = { Id = "rbxassetid://9118830476", Volume = 1.2, Voices = 4, Gap = 0.04, Jitter = 0.08, Range = 50 },
		-- Pacifier 2 ("Comic Pops and Plops"): one 30 ms pop right at the head. It was PenDrop's until 2026-10-04.
		WoolPop = { Id = "rbxassetid://9117183621", Volume = 0.5, Voices = 4, Gap = 0.04, Jitter = 0.08, Range = 40 },
		-- A sheep leaving the pen for good bursts with it (SheepController/Poofs). Cloth Flap 10.
		Poof = { Id = "rbxassetid://9113819587", Volume = 0.25, Voices = 3, Gap = 0.06, Jitter = 0.12, Range = 40 },
		-- A sheep's wool full again: Poof's cloth flap, softer and lower, like a shake of the fleece.
		WoolFull = {
			Id = "rbxassetid://9113819587",
			Volume = 0.16,
			Speed = 0.7,
			Voices = 3,
			Gap = 0.12,
			Jitter = 0.1,
			Range = 30,
		},
		-- The cash: a ding and a coin's clink together (the daily gift's bills landing), the ding alone as a purchase's
		-- pictures land and in the rebirth moment. Every shear had them until 2026-10-04.
		-- Large Metal Triangle Single Ringing Hits 12: the metallic coin ding, one muted tone, so it stays clean pitched
		-- up (a violin pluck was tried and didn't feel like cash). One fixed note and no jitter: a run of slightly
		-- different notes sounded like a xylophone (a playtest, 2026-10-02). Rings for about 0.23 s.
		Ding = { Id = "rbxassetid://9116224467", Volume = 0.2, Speed = 1.2, Voices = 4 },
		-- Coin Throws 7 (Pro Sound Effects, "Single Quarters On Concrete"): one bright coin hit at the head, no bounces,
		-- gone by 0.32 s.
		Coin = { Id = "rbxassetid://9113850116", Volume = 0.3, Voices = 4, Jitter = 0.1 },

		-- Menus and notices.
		Click = { Id = "rbxassetid://9120917813", Volume = 0.5, Voices = 2, Gap = 0.03 }, -- Soft Impacts On Temple Blocks 6
		MenuOpen = { Id = "rbxassetid://9120705181", Volume = 0.4 }, -- Whooshes Quick Airy Slices 5
		-- Can't afford, can't do that, bad news. APM "Wrong Answer 2": 0.8 s of sound, then silence.
		Denied = { Id = "rbxassetid://1841012024", Volume = 0.5, Gap = 0.2, Start = 0.2 },
		Notice = { Id = "rbxassetid://9048764475", Volume = 0.4, Gap = 0.3 }, -- good news; APM "Magical Meetup - Hit2"
		-- A sheep, a dog or a raid wolf bought with cash. Coin Throws 3 (Roblox has no licensed cash register).
		Purchase = { Id = "rbxassetid://9113849651", Volume = 0.6 },
		Release = { Id = "rbxassetid://9120705181", Volume = 0.5, Speed = 0.8 }, -- the menu whoosh, lower
		OfferPop = { Id = "rbxassetid://9117848037", Volume = 0.5, Start = 0.1 }, -- Pops Mouth Popping 5
		RobuxThanks = { Id = "rbxassetid://9045132884", Volume = 0.6 }, -- APM "Country Romp - Hit1", bluegrass banjos

		-- The mutation machine.
		SpinStart = { Id = "rbxassetid://9116259834", Volume = 0.6 }, -- Lever Two Large Metal Pulls 1
		ReelTick = { Id = "rbxassetid://9118138193", Volume = 0.35, Voices = 3, Gap = 0.045, Jitter = 0.05 }, -- Relay Clicks 6
		ReelStop = { Id = "rbxassetid://9116672071", Volume = 0.6 }, -- Metal Impact Dropping Clanky Piece 2
		SpinNothing = { Id = "rbxassetid://1839997989", Volume = 0.5 }, -- APM "Wrong Answer 3", a descending "aww"
		SpinWin = { Id = "rbxassetid://9040476898", Volume = 0.6 }, -- APM "Early Bird - Hit1"
		SpinBigWin = { Id = "rbxassetid://9043138254", Volume = 0.8 }, -- APM "Best Is Yet To Come - Hit2"
		-- The machine's lab (the machine menu). Its builds play only their ends (SoundController:PlayEnding), so they stop
		-- dead on the beat. The machine powering up: APM "REVERSE HARD STOP-Metal Build 02", a 4 s metal build.
		LabCharge = { Id = "rbxassetid://1837834352", Volume = 0.45 },
		-- Bolts round the crown: the crackle's first 0.35 s of Lightning Flashes Quick Electrical Bursts 56.
		LabZap = { Id = "rbxassetid://9116279560", Volume = 0.2, Voices = 2, Gap = 0.12, Jitter = 0.15, Length = 0.35 },
		LabStrip = { Id = "rbxassetid://9120705181", Volume = 0.45, Speed = 1.25 }, -- a strip opening: the menu whoosh
		-- The sheep landing in the chamber: the mutation sparkle's chimes, brighter.
		LabSpecimen = { Id = "rbxassetid://9119447936", Volume = 0.45, Speed = 1.3 },
		-- Under the mutation strip: APM "REVERSE HARD STOP-Noise Build 01", 3.4 s of rising noise with a hard stop.
		LabRiser = { Id = "rbxassetid://1837834257", Volume = 0.3 },
		-- The chamber discharging as the mutation shows: Lightning Flashes Quick Electrical Bursts 11.
		LabFlash = { Id = "rbxassetid://9116276051", Volume = 0.5 },
		-- At the sheep, for everyone near. Sparkle Bell Tree Wind Chimes 1.
		Reveal = { Id = "rbxassetid://9119447936", Volume = 0.7, Range = 120 },
		-- The lab's result shows climb a ladder (Screens/MachineLab/Shows): each rarer result layers more of these over
		-- SpinWin or SpinBigWin. Added 2026-10-01 (Mark: his Rainbow "felt like the same thing as getting a silver"),
		-- picked from the store's names and descriptions only: not loaded, measured or heard yet.
		-- Gold and up: a coin toss (Coin Throws 2, DexReward's) and the sparkle chimes, brighter.
		RevealCoins = { Id = "rbxassetid://9113849583", Volume = 0.5 },
		RevealChimes = { Id = "rbxassetid://9119447936", Volume = 0.45, Speed = 1.15 },
		-- Diamond and up. The build swelling into the flash (played so it ends there): Magic Glow Short Pulsing Bursts 9
		-- (SFX), "Magic Glow, Short Pulsing Burst, Fast Humming Swell, Some Pitch Bend", 1.8 s.
		RevealSwell = { Id = "rbxassetid://9116393976", Volume = 0.5 },
		-- The flash: Magic Burst 2 (SFX), "Magic Burst, Big Beefy Impact, Thudding Hits, Light Rattling, Glowing Tonal
		-- Decay", 3.2 s; and the chamber's glass going, Glass Break 1 (SFX), "Glass Break, Juice Glass, Smash", 3.4 s,
		-- quieter and higher so it sparkles rather than crashes.
		RevealBoom = { Id = "rbxassetid://9116384473", Volume = 0.6 },
		RevealShatter = { Id = "rbxassetid://9114590297", Volume = 0.35, Speed = 1.15 },
		-- The shards falling, a moment later: Glass Tinks 2 (SFX), "Glass Tinks, Tonal Varieties, CU", 3 s.
		RevealCrystal = { Id = "rbxassetid://9114619050", Volume = 0.5 },
		-- Rainbow only. Under the party lights' build: APM "Space Chimes" (Juice Music, Game Play: "Outerspace fx and
		-- chimes fx", 5 s), its first 3 s.
		RevealSparkle = { Id = "rbxassetid://1839901334", Volume = 0.45, Length = 3 },
		-- The fanfare: APM "Triumphant Fanfare" (no description; 6 s or less). If it doesn't suit, APM "1812 Overture
		-- (sting d)" (9045751388, "An upbeat orchestral sting version of Tchaikovsky's 1812 Overture", 4 s) is the
		-- next pick.
		RevealFanfare = { Id = "rbxassetid://1845287239", Volume = 0.8 },
		-- Kids cheering: APM "Yeah" (KPM, Sonic Logos 2: "Vocals - Children's voices", 2 s).
		RevealCheer = { Id = "rbxassetid://1841221347", Volume = 0.6 },
		-- Fireworks through the hold, in the lab and at the machine for everyone near: Fireworks Fast 2 (SFX),
		-- "Fireworks, Whistler, Fast", 5.3 s.
		RevealFireworks = { Id = "rbxassetid://9114447104", Volume = 0.4, Range = 160 },
		-- A Diamond or Rainbow bursting out of someone's machine (Components/MachineFx), heard by everyone near but its
		-- owner (whose lab played it): SpinBigWin's APM "Best Is Yet To Come - Hit2", carrying further than Reveal.
		MachineBigWin = { Id = "rbxassetid://9043138254", Volume = 0.8, Range = 140 },

		-- Progress.
		Pickup = { Id = "rbxassetid://9113537810", Volume = 0.5 }, -- a bought sheep lifted onto the head; cartoon boink
		-- And put down in the pen, heard as it lands off the head; also a lab result's sheep landing in the lab's pen
		-- counter. Comic Tube Bounce 8: a hollow tube's bonk ringing for about 0.2 s, picked from its measurements and
		-- not heard yet, about as loud as Pacifier 2 was here (2026-10-04, when Pacifier 2 went to the shear). If it
		-- doesn't suit: Comic Tube Bounce 6 (9113863640), the same bonk a little softer, or Comic Boinks 1
		-- (9113854234), a springy synth boing.
		PenDrop = { Id = "rbxassetid://9113863785", Volume = 0.8 },
		LandUp = { Id = "rbxassetid://1841214240", Volume = 0.6 }, -- APM "Accordion Link", jolly and rustic
		Upgrade = { Id = "rbxassetid://1839997938", Volume = 0.5 }, -- APM "Correct Answer 3", rising sparkles
		Rebirth = { Id = "rbxassetid://1839997865", Volume = 0.7 }, -- APM "Orchestral Bumper", swoosh into a sting
		StepDone = { Id = "rbxassetid://9125485591", Volume = 0.4, Start = 0.1 }, -- a tutorial step; Desk Bell Single Ding 1
		Lock = { Id = "rbxassetid://9116722865", Volume = 0.6 }, -- the gate lock; Metal Latches 4
		-- The gate's leaves swinging shut against the post, heard by everyone near: ReelStop's clanky drop, lower.
		GateClunk = { Id = "rbxassetid://9116672071", Volume = 0.45, Speed = 0.75, Gap = 0.2, Range = 60 },
		Unlock = { Id = "rbxassetid://9116722779", Volume = 0.5 }, -- the gate lock or the Wolf Guard running out; Latches 3
		DexEntry = { Id = "rbxassetid://9048777613", Volume = 0.6 }, -- APM "Enchanted Butterflies - Hit2"
		DexReward = { Id = "rbxassetid://9113849583", Volume = 0.6 }, -- a Sheepdex tier's cash; Coin Throws 2
		DexPage = { Id = "rbxassetid://9114898840", Volume = 0.7, Start = 0.25 }, -- Kazoo Fanfare 9
		-- A badge's toast (UIController/BadgeCard): the machine's win hit; the rarest badges' moment: its big win.
		Badge = { Id = "rbxassetid://9040476898", Volume = 0.6 }, -- APM "Early Bird - Hit1"
		BadgeBig = { Id = "rbxassetid://9043138254", Volume = 0.8 }, -- APM "Best Is Yet To Come - Hit2"

		-- The steal and the god chase (2026-10-06): the user picked the chase, "right behind you" and the god's laugh by
		-- ear from art/chase's mock-up and sound boards (its README has the sounds' store names and how each was
		-- measured), and asked for every voice to be one person in one take, never two sounds layered. Volumes match the
		-- mock-up's mix: each sound's loudness was measured, then set against the calm music's. The god's own sounds
		-- (Gods, Goddesses below) play from the god, so they grow as it closes.
		-- The alarm on a steal (2D, the thief only): APM "Electronic Alarms (D)" (KPM's "(d)": "Low pitched pulsing"),
		-- a clean electronic wenh... wenh..., from its first pulse. The user's pick (option C) over the mock-up's APM
		-- "Wild Intruder Alarm Tag 2" ("sounds like heavy metal") and the buzzier Red Alert Alarm (A, 9118113271).
		-- Quieter than A for the same loudness: a 2 kHz tone sounds louder.
		StealAlarm = { Id = "rbxassetid://1840227705", Volume = 2.4, Start = 1.9, Length = 4 },
		-- The thief's heartbeat, retriggered faster and louder as the god closes: one lub-dub of APM "HEARTBEAT 01
		-- 96BPM" (Epic Score, Horror Tools).
		Heartbeat = { Id = "rbxassetid://9043365727", Volume = 1.6, Length = 0.62, Voices = 2 },
		-- Flying off from the punch, and landing (2D, the thief): Whoosh Fast Swish By 7, slowed; Body Impact 2.
		Fly = { Id = "rbxassetid://9120711172", Volume = 0.5, Speed = 0.75 },
		Land = { Id = "rbxassetid://9113524237", Volume = 1.9, Speed = 0.8 },
		-- Across the safety line with the lamb: the Notice hit (APM "Magical Meetup - Hit2").
		ChaseSafe = { Id = "rbxassetid://9048764475", Volume = 0.9 },

		-- From the god, for everyone near (Voices below picks which line). Its roar as it sees the thief, one of three
		-- single takes, slowed so they sound huge (voice board M2-M4; the user turned down M1, and a growl layered
		-- under a yell, as "more than one person"): Goblin Growl 1 (SFX), "Human Generated Roar", and two of the Male
		-- Scream Short Yelling Bursts.
		GodRoar1 = { Id = "rbxassetid://9114624345", Volume = 1.6, Speed = 0.85, Near = 30, Range = 300 },
		GodRoar2 = { Id = "rbxassetid://9125651408", Volume = 0.8, Speed = 0.72, Near = 30, Range = 300 },
		GodRoar3 = { Id = "rbxassetid://9125652955", Volume = 0.7, Speed = 0.72, Near = 30, Range = 300 },
		-- Its footfalls while it runs: the first 0.32 s of Boomy Footsteps Giant Thumpy Dinosaur Footstep 1 (SFX).
		GodStep = {
			Id = "rbxassetid://9125404769",
			Volume = 1,
			Speed = 1.2,
			Length = 0.32,
			Jitter = 0.05,
			Voices = 3,
			Near = 12,
			Range = 220,
		},
		-- Yells every few seconds while it runs (two of the Male Scream Short Yelling Bursts, slowed), and a snarl
		-- (Goblin Growl 1 (SFX), "Human Generated Roar", slowed, a cut of it) when it's right behind the thief.
		GodYell1 = { Id = "rbxassetid://9125651083", Volume = 0.9, Speed = 0.8, Jitter = 0.04, Near = 15, Range = 260 },
		GodYell2 = { Id = "rbxassetid://9125651408", Volume = 0.9, Speed = 0.76, Jitter = 0.04, Near = 15, Range = 260 },
		GodSnarl = {
			Id = "rbxassetid://9114624345",
			Volume = 1.1,
			Speed = 0.72,
			Start = 0.2,
			Length = 0.6,
			Jitter = 0.04,
			Near = 10,
			Range = 160,
		},
		-- The catch: Whoosh Heavy Punches 1 and Body Impact 2 with Boxing Hits 5 over it, then a laugh: Laugh Evil Male
		-- Various Versions 4, 3 or 5 (voice board ML1-ML3), slowed: a deep HA HA HA, each one man in one take.
		PunchSwing = { Id = "rbxassetid://9120728815", Volume = 1, Near = 20, Range = 160 },
		PunchHit = { Id = "rbxassetid://9113524237", Volume = 3.4, Near = 20, Range = 160 },
		PunchSmack = { Id = "rbxassetid://9113570506", Volume = 6, Near = 20, Range = 160 },
		GodLaugh1 = { Id = "rbxassetid://9116239313", Volume = 1.6, Speed = 0.8, Start = 0.3, Near = 25, Range = 260 },
		GodLaugh2 = {
			Id = "rbxassetid://9116239157",
			Volume = 0.9,
			Speed = 0.8,
			Start = 0.3,
			Length = 2.6,
			Near = 25,
			Range = 260,
		},
		GodLaugh3 = {
			Id = "rbxassetid://9116239334",
			Volume = 0.8,
			Speed = 0.8,
			Start = 0.3,
			Length = 3.2,
			Near = 25,
			Range = 260,
		},
		-- The thief got away: another of the man's yells, slowed, heard from wherever the god stopped.
		GodFrustrated = { Id = "rbxassetid://9125652955", Volume = 0.5, Speed = 0.7, Near = 10, Range = 400 },
		-- The goddesses (Olympus Goddess), each sound one woman in one take (the user, 2026-10-06; the first ones were
		-- from a set of two women and a file of several laughs): single yells from Female Voices 2 Women Short Screams
		-- Yells (voice board F1-F3, FY1, FY2) and laughs from Adult Female Laughter 3 and 1 and Female Laugh 1 (SFX),
		-- a cackle, a giggle into a cackle, a bigger laugh (FL1-FL3). All slowed "a little bit deeper because they're
		-- still huge beings" (the user).
		GoddessRoar1 = { Id = "rbxassetid://9114399675", Volume = 2.2, Speed = 0.77, Near = 30, Range = 300 },
		GoddessRoar2 = { Id = "rbxassetid://9114399696", Volume = 2.1, Speed = 0.77, Near = 30, Range = 300 },
		GoddessRoar3 = { Id = "rbxassetid://9114399178", Volume = 2.4, Speed = 0.77, Near = 30, Range = 300 },
		GoddessYell1 = {
			Id = "rbxassetid://9114399869",
			Volume = 2.6,
			Speed = 0.77,
			Jitter = 0.04,
			Near = 15,
			Range = 260,
		},
		GoddessYell2 = {
			Id = "rbxassetid://9114399465",
			Volume = 2.1,
			Speed = 0.77,
			Jitter = 0.04,
			Near = 15,
			Range = 260,
		},
		GoddessLaugh1 = {
			Id = "rbxassetid://9113043479",
			Volume = 1.8,
			Speed = 0.8,
			Start = 0.2,
			Near = 25,
			Range = 260,
		},
		GoddessLaugh2 = { Id = "rbxassetid://9113043410", Volume = 3.7, Speed = 0.8, Near = 25, Range = 260 },
		GoddessLaugh3 = {
			Id = "rbxassetid://9114396740",
			Volume = 1.15,
			Speed = 0.8,
			Start = 0.2,
			Near = 25,
			Range = 260,
		},
		GoddessFrustrated = { Id = "rbxassetid://9114399696", Volume = 1.45, Speed = 0.7, Near = 10, Range = 400 },

		-- Wolves and dogs, heard from the animal by everyone near.
		-- Coyotes Gruff Barking 9: Roblox has no licensed dog bark, and this one is quiet at the source.
		Bark = { Id = "rbxassetid://9113955402", Volume = 3, Jitter = 0.1, Range = 90 },
		-- The wolf sounds dated 2026-10-01 (Mark: "a lot more creepy... a lot more scary") were picked from the store's
		-- descriptions only: not loaded, measured or heard yet.
		-- A wolf biting a sheep, and the first wolf breaking cover (Config/Cutscenes), 2026-10-01: Wolf Snarl 1 (SFX),
		-- "Wolf Snarl, CU, Snapping, Growling, Quite Angry", 2.7 s (was Lion Cub Short Growls 9, too cute).
		Growl = { Id = "rbxassetid://9120790837", Volume = 0.9, Range = 100 },
		-- A wolf jumping into a pen (WolfCues; 2D and loud for the owner), 2026-10-01: Wolf Snarl 6 (SFX), "Wolf
		-- Snarl, CU, Snapping, Growling, Quite Angry", 1.8 s.
		WolfLeap = { Id = "rbxassetid://9120791326", Volume = 1, Range = 100 },
		Panic = { Id = "rbxassetid://9113443288", Volume = 0.7, Range = 100 }, -- the grabbed sheep; Billy Goat 5
		Scuffle = { Id = "rbxassetid://9125819208", Volume = 0.7, Range = 100 }, -- comic metal clangs and clunks
		Yelp = { Id = "rbxassetid://9118862367", Volume = 0.7, Range = 100 }, -- Seahorse Whine 10, a cartoon yelp

		-- A wild wolf's warning, for the owner only (2D, WolfCues), over the wolf alert's howl: the jump scare, 2026-10-01.
		-- APM "FEAR HIT 12" (Epic Score, Horror Tools: "Scary hit", 7 s) and a close snarl, Wolf Snarl 1 (SFX) ("Wolf
		-- Snarl, CU, Whiplash Snarls, Definitely Not in a Petting Mood", 2 s; not the Growl's Wolf Snarl 1).
		WolfScare = { Id = "rbxassetid://9043338954", Volume = 0.9 },
		WolfSnarl = { Id = "rbxassetid://9120790555", Volume = 1 },
		-- The owner's sheep gone for good: the pack baying out in the woods, 2026-10-01. Wolf Howl Bay 1 (SFX), "Wolf
		-- Howl, Multiple Wolves, Bay, Classic", 7.8 s.
		WolfGone = { Id = "rbxassetid://9120789309", Volume = 0.5 },

		-- Wolf and raid outcomes, for the players they happen to (with the notice).
		Grabbed = { Id = "rbxassetid://9113443288", Volume = 0.8, Speed = 1.1 }, -- your sheep crying out: Panic, wherever you are
		Rescued = { Id = "rbxassetid://95422811917977", Volume = 0.7 }, -- APM "Fun Adventure - Hit1"
		Saved = { Id = "rbxassetid://9048764475", Volume = 0.6, Speed = 1.12 }, -- dogs, lock or guard kept it out; Notice, brighter
		Lost = { Id = "rbxassetid://1839853689", Volume = 0.7, Start = 0.25 }, -- APM "Fun Effect 24", run down
		RaidWin = { Id = "rbxassetid://9045131350", Volume = 0.7 }, -- APM "Red Handed - Hit2", sneaky pizzicato
		RaidFail = { Id = "rbxassetid://1836245036", Volume = 0.6 }, -- APM "Comic Falling Sting"

		-- The join teaser's camera whipping back to the player (Config/Cutscenes). The first wild wolf's scene has none:
		-- the wolf sounds as every later one does (WolfCues, the danger music, the howl), and its feeding plays on.
		IntroWhip = { Id = "rbxassetid://9120711172", Volume = 0.5 }, -- Whoosh Fast Swish By 7: back to the player
		-- The first wolf feeding out in the woods once it has got away (WolfCues), heard from where it vanished, never
		-- seen (Mark, 2026-10-02): a snapping snarl (the Growl's Wolf Snarl 1, slower and lower), chewing (Goat Eating 1
		-- (SFX), "Goat Eating, CU, Grain, Constant", slowed into something heavier) and a low purring growl over it
		-- (Tiger Snarl 7 (SFX), "Tiger Snarl, CU, Intense Purring, Growl"). Picked from their descriptions, not heard.
		FeedSnarl = { Id = "rbxassetid://9120790837", Volume = 1, Speed = 0.85, Range = 140 },
		FeedChew = { Id = "rbxassetid://9114623570", Volume = 1.2, Speed = 0.7, Start = 1, Length = 3.2, Range = 140 },
		FeedGrowl = { Id = "rbxassetid://9120051461", Volume = 0.7, Speed = 0.9, Length = 3, Range = 140 },
		-- The join teaser's wolf, heard from far off: the wolf alert's howl (StarterGui.WolfAlert.Howl), and a sheep's
		-- baa (Sheep Blats 18, the brightest of GameConfig.SheepMotion.BaaSounds), quiet and a little low.
		Howl = { Id = "rbxassetid://9120790529", Volume = 0.6 },
		DistantBleat = { Id = "rbxassetid://9119066777", Volume = 0.25, Speed = 0.92 },
	} :: { [string]: Effect },

	-- A god's lines for each moment, by voice (Olympus Goddess): GodController picks one at random each time, never the
	-- take that god said last (the user, 2026-10-06: "a little bit more variety every time, different voice lines").
	Voices = {
		God = {
			Roar = { "GodRoar1", "GodRoar2", "GodRoar3" },
			Yell = { "GodYell1", "GodYell2" },
			Snarl = { "GodSnarl" },
			Laugh = { "GodLaugh1", "GodLaugh2", "GodLaugh3" },
			Frustrated = { "GodFrustrated" },
		},
		Goddess = {
			Roar = { "GoddessRoar1", "GoddessRoar2", "GoddessRoar3" },
			Yell = { "GoddessYell1", "GoddessYell2" },
			Snarl = { "GodSnarl" },
			Laugh = { "GoddessLaugh1", "GoddessLaugh2", "GoddessLaugh3" },
			Frustrated = { "GoddessFrustrated" },
		},
	} :: { [string]: { [string]: { string } } },

	-- The player's own shears (Snip and WoolPop together). Shears that land together, a sweep through the flock in one
	-- frame, play one every Spacing seconds with at most MaxQueued waiting: a big sweep sounds like a handful of
	-- shears, not one, and not twenty at once. Spacing stays over Snip's and WoolPop's Gaps, so neither is dropped.
	ShearQueue = {
		Spacing = 0.06,
		MaxQueued = 6,
	},

	-- The machine's landing: mutations at this rank (Mutations.Rank) and rarer get SpinBigWin (Screens/MachineLab/Shows
	-- says which sounds each show layers), and the whole screen's celebration when the lab was closed before it showed.
	Machine = {
		BigWinRank = 3, -- Diamond and Rainbow
	},

	Music = {
		-- In turn, round and round: APM tracks for a sunny valley.
		Calm = {
			{ Name = "Playtime", Id = "rbxassetid://1839857481", Volume = 0.5 }, -- "happy and carefree"
			{ Name = "PeacefulWhistlingFast", Id = "rbxassetid://1839464262", Volume = 0.5 }, -- acoustic, whistling
			{ Name = "SailBoat", Id = "rbxassetid://1840007459", Volume = 0.5 }, -- bright, breezy folk
		} :: { Track },
		-- While a god chases you (2026-10-06, the user: "the chase I think sounds good", heard in art/chase's mock-up):
		-- APM "Run For Your Life", "up-tempo relentless action, sweeping pads over dramatic bass and electronic jungle
		-- drum pattern", about 90 BPM. Two of APM's mixes of it play together: the drumless one ("(80%)") all along,
		-- the full one (with drums) faded in as the god closes (GameConfig.Chase). They line up to about 10 ms, and
		-- both jump from DangerLoop's End back to its Start (16 bars, the best match in the track), before the ending.
		-- It was APM "Evasion" (1840028287), never heard.
		Danger = { Name = "RunForYourLife", Id = "rbxassetid://1845015064", Volume = 2.5 } :: Track,
		DangerDrums = { Name = "RunForYourLifeDrums", Id = "rbxassetid://1845015012", Volume = 1.12 } :: Track,
		DangerLoop = { Start = 8.21, End = 50.88 },
		FadeSeconds = 1.5,
		DangerInSeconds = 0.25, -- the calm music cut on a steal
		QuickSeconds = 0.3, -- the chase music cut on reaching safety
		CalmDelay = 3, -- seconds after a chase ends before the calm music comes back
	},

	-- A looping meadow: Pro Sound Effects "Birds Park 1" (made to loop; quiet at the source).
	Ambience = { Id = "rbxassetid://9112749254", Volume = 1.2 },
}

return table.freeze(Sounds)
