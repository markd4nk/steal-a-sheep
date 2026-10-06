--!strict

-- The UI's look, "Blue Ribbon" (DESIGN/ui/UI_SPEC.md) turning "Ranch Studs" (DESIGN/ui/mockups/look-test.html, the
-- picked frames): every colour, font, size, corner, line and tween the screens use. Screens and the studio/ build scripts read these and never hard-code one. Sizes are points at UIScale 1 (a
-- phone held sideways); each screen's UIScale turns them into pixels (UIController/Scale).

export type ButtonKind =
	"Buy"
	| "Action"
	| "Danger"
	| "Soft"
	| "Robux"
	| "CantAfford"
	| "Locked"
	| "Disabled"
	| "NightDisabled"
	| "Owned"

export type ButtonLook = {
	Face: Color3,
	Lip: Color3?, -- nil: flat, no lip and no shine (Locked, Disabled)
	Label: Color3,
	LabelStroke: Color3?, -- snow text on a colour wears an outline in that colour's dark shade
	Outline: Color3,
}

export type TierLook = {
	Gem: Color3,
	Chip: Color3,
	ChipText: Color3,
	Rainbow: boolean?, -- the chip and gem take the rainbow gradient (Secret)
}

export type ChipLook = {
	Chip: Color3,
	ChipText: Color3,
	Gem: Color3, -- the icon's colour on the chip
	Rainbow: boolean?,
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

-- Ribbon blue, snow to night: the one main colour. Green, red and gold are kept for what they mean.
local Color = {
	Blue0 = rgb(247, 250, 255), -- snow: text on colour, cards, rows, the close button
	Blue50 = rgb(234, 242, 254), -- panel body, locked buttons
	Blue100 = rgb(214, 229, 252), -- strips, tracks, chips, disabled buttons
	Blue200 = rgb(179, 206, 248), -- snow buttons' lip, icons' second fill
	Blue300 = rgb(134, 175, 240), -- disabled outline, scrollbar thumb
	Blue400 = rgb(90, 145, 232), -- pointers, disabled text
	Blue500 = rgb(62, 121, 224), -- the main colour: panel frames, tiles, tabs bar, the cash pill, action buttons
	Blue600 = rgb(47, 99, 198), -- pressed, locked text
	Blue700 = rgb(38, 79, 160), -- lips, header chips, the sheep chip, small text
	Blue800 = rgb(29, 59, 120), -- the night panel's frame, body text
	Blue900 = rgb(21, 42, 85), -- ink: titles, outlines, text strokes
	Blue950 = rgb(14, 29, 60), -- the backdrop, the night panel's body

	-- Buying with cash you have, success, good news, cash itself.
	Green100 = rgb(221, 247, 218),
	Green300 = rgb(142, 227, 143),
	Green400 = rgb(91, 209, 99), -- the bill's light face
	Green500 = rgb(54, 184, 75),
	Green600 = rgb(38, 146, 58),
	Green800 = rgb(19, 92, 34),

	-- Can't afford, problems, a full pen, wolves and raids, things that can't be undone.
	Red100 = rgb(255, 225, 223),
	Red300 = rgb(255, 157, 149),
	Red400 = rgb(255, 107, 99),
	Red500 = rgb(236, 67, 67),
	Red600 = rgb(194, 47, 49),
	Red700 = rgb(150, 24, 30), -- a wolf's "WOLF!" and its pointer
	Red800 = rgb(126, 26, 29),

	-- Cash on the HUD, in a thick ink outline straight on the world (Ranch Studs).
	Lime = rgb(109, 255, 61),

	-- Ranch Studs' thick black edge: round buttons, panels and rows, and round white words on the world or the glass.
	Line = rgb(13, 13, 13),
	-- The menus' see-through glass panel, and the pale line just inside its edge.
	Glass = rgb(30, 36, 42),

	-- The world's studded boards (Ranch Studs, look A): the signs' faces and the prompt cards, orange like the mockup's
	-- upgrade card, with a darker lip.
	Board = rgb(240, 160, 72),
	BoardLip = rgb(196, 118, 40),

	-- Robux: every Robux button, as loud as the cash button beside it (Ranch Studs, 2026-09-30).
	Purple500 = rgb(165, 38, 242),
	Purple600 = rgb(118, 22, 184),
	Purple800 = rgb(70, 10, 112),

	-- Short of cash: the cash button goes grey while the Robux one beside it stays loud.
	Grey500 = rgb(125, 131, 140),
	Grey600 = rgb(92, 97, 105),
	Grey800 = rgb(52, 56, 62),

	-- Rare: mutations, the Legendary tier, a rare result. Never a button, never decoration.
	Gold100 = rgb(255, 242, 198),
	Gold300 = rgb(255, 216, 102),
	Gold500 = rgb(255, 190, 33),
	Gold600 = rgb(219, 152, 0),
	Gold800 = rgb(138, 90, 0),

	Ink = rgb(21, 42, 85),
	Snow = rgb(247, 250, 255),
	Shadow = rgb(14, 29, 60),
	Blush = rgb(242, 156, 152),
}

-- Tiers are collection labels, not meanings: a pale chip with a gem in the tier's colour.
local Tier: { [string]: TierLook } = {
	Common = { Gem = rgb(154, 167, 189), Chip = rgb(230, 234, 241), ChipText = rgb(78, 91, 114) },
	Uncommon = { Gem = rgb(29, 174, 147), Chip = rgb(212, 243, 236), ChipText = rgb(13, 107, 89) },
	Rare = { Gem = rgb(30, 150, 230), Chip = rgb(214, 236, 252), ChipText = rgb(11, 92, 148) },
	Epic = { Gem = rgb(139, 85, 232), Chip = rgb(234, 223, 253), ChipText = rgb(90, 43, 174) },
	Legendary = { Gem = Color.Gold500, Chip = Color.Gold100, ChipText = Color.Gold800 },
	Mythic = { Gem = rgb(230, 66, 143), Chip = rgb(252, 221, 235), ChipText = rgb(155, 31, 91) },
	Secret = { Gem = Color.Snow, Chip = Color.Snow, ChipText = Color.Ink, Rainbow = true },
}

-- Mutation chips; the wool and token colours stay GameConfig.Mutations' own.
local Mutation: { [string]: ChipLook } = {
	Silver = { Chip = rgb(238, 241, 246), ChipText = rgb(86, 98, 122), Gem = rgb(206, 214, 226) },
	Gold = { Chip = Color.Gold100, ChipText = Color.Gold800, Gem = Color.Gold500 },
	Diamond = { Chip = rgb(221, 247, 255), ChipText = rgb(29, 111, 134), Gem = rgb(168, 238, 255) },
	Rainbow = { Chip = Color.Snow, ChipText = Color.Ink, Gem = Color.Snow, Rainbow = true },
}

local RAINBOW = {
	rgb(255, 138, 138),
	rgb(255, 201, 107),
	rgb(245, 238, 122),
	rgb(139, 229, 158),
	rgb(126, 194, 255),
	rgb(201, 160, 255),
}
local rainbowKeys: { ColorSequenceKeypoint } = {}
for index, color in RAINBOW do
	table.insert(rainbowKeys, ColorSequenceKeypoint.new((index - 1) / (#RAINBOW - 1), color))
end

-- The eight kinds of button (UI_SPEC 1.4). Code never colours a button itself; it asks Buttons.Set for a kind. Since
-- Ranch Studs the Robux button is purple and as loud as the cash one, and a price the player can't pay is grey.
local Button: { [ButtonKind]: ButtonLook } = {
	Buy = {
		Face = Color.Green500,
		Lip = Color.Green600,
		Label = Color.Snow,
		LabelStroke = Color.Line,
		Outline = Color.Line,
	},
	Action = {
		Face = Color.Blue500,
		Lip = Color.Blue700,
		Label = Color.Snow,
		LabelStroke = Color.Line,
		Outline = Color.Line,
	},
	Danger = {
		Face = Color.Red500,
		Lip = Color.Red600,
		Label = Color.Snow,
		LabelStroke = Color.Line,
		Outline = Color.Line,
	},
	-- The quiet second choice (Cancel, Later, Release sheep): slate, like Prize Fleece's panels it sits on.
	Soft = {
		Face = Color3.fromRGB(78, 88, 110),
		Lip = Color3.fromRGB(43, 49, 65),
		Label = Color.Snow,
		LabelStroke = Color.Line,
		Outline = Color.Line,
	},
	Robux = {
		Face = Color.Purple500,
		Lip = Color.Purple600,
		Label = Color.Snow,
		LabelStroke = Color.Line,
		Outline = Color.Line,
	},
	CantAfford = {
		Face = Color.Grey500,
		Lip = Color.Grey600,
		Label = Color.Snow,
		LabelStroke = Color.Line,
		Outline = Color.Line,
	},
	-- Nothing to press (Prize Fleece): flat dark slate with muted words, on the menus' slate.
	Locked = { Face = Color3.fromRGB(52, 59, 75), Label = Color3.fromRGB(133, 144, 166), Outline = Color.Line },
	Disabled = { Face = Color3.fromRGB(52, 59, 75), Label = Color3.fromRGB(133, 144, 166), Outline = Color.Line },
	-- On the night panel (the machine, the den): disabled from the dark end, and the wolf you own.
	NightDisabled = { Face = Color.Blue800, Label = Color.Blue300, Outline = Color.Blue700 },
	Owned = { Face = Color.Blue800, Label = Color.Green300, Outline = Color.Green600 },
}

local Theme = {
	Color = Color,
	Tier = Tier,
	Mutation = Mutation,
	-- Rainbow as a UIGradient's colours (115 degrees on screen: UIGradient.Rotation 25).
	Rainbow = ColorSequence.new(rainbowKeys),
	RainbowRotation = 25,

	Font = {
		Display = Font.fromEnum(Enum.Font.FredokaOne), -- anything read at a glance
		Text = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold), -- small print
		TextHeavy = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold), -- chips
	},

	TextSize = {
		Hero = 44, -- celebrations
		Display = 32, -- cash on the HUD
		CashPill = 30,
		Title = 24, -- panel titles, the guide's words, a detail card's name
		Big = 22, -- banners, a hero button's second line
		Label = 18, -- buttons, row names, notices
		Tab = 16,
		Body = 14, -- descriptions, strips
		Caption = 12, -- chips, sub-lines, details
		Min = 12, -- the smallest a TextScaled label may shrink to
	},

	-- A 4 pt grid.
	Space = {
		Icon = 4, -- an icon to its text
		Row = 8, -- between rows, inside chips
		Inside = 12, -- inside rows and cards
		Group = 16, -- between groups
		Panel = 24, -- around a panel's content
		Edge = 32, -- the screen's edge on PC
	},

	-- Each layer sits 6 in with a radius 6 smaller, so the gap round a corner stays even.
	Radius = {
		Panel = 30,
		Body = 24,
		Card = 18,
		Button = 12,
		Tag = 6,
	},

	-- Outline widths: ink, outside the shape.
	Line = {
		Thin = 2,
		Normal = 2.5,
		Thick = 3, -- panels and the HUD's big pieces
	},

	-- The darker band under a button, tile or panel.
	Lip = {
		Button = 4,
		Small = 3, -- the close button, chips on the HUD
		Panel = 6,
	},

	Button = Button,
	-- A tab on a menu's header: a small studded button, blue while it's the page showing, grey otherwise.
	Tab = {
		On = Color.Blue500,
		OnLip = Color.Blue700,
		Off = Color.Grey500,
		OffLip = Color.Grey600,
	},
	-- The menus' see-through panel (Ranch Studs, look B): the glass, its thick black edge, the pale line inside it, and a
	-- row on it, tinted by its sheep's tier.
	Glass = {
		Transparency = 0.38,
		Edge = 4,
		Inner = 2.5,
		InnerTransparency = 0.72,
		Radius = 8,
		Row = 0.22, -- a row's transparency
		Card = 0.3, -- a card's (UIKit.Card): darker glass over the glass
		RowTint = 0.6, -- how much of the tier's colour a row takes over the glass colour
	},
	-- The studs on every coloured face (buttons, the close, the HUD's pills, the menus' headers, the signs): four faint
	-- squares in black and white on a clear ground, two raised and two sunk in a checkerboard (art/ui/make_studs.py,
	-- after Mark's references), tiled `Tile` points a side over the face's own colour, so 16 points from stud to stud.
	-- With no image ("") faces stay plain.
	Studs = {
		Image = "rbxassetid://99819959236667",
		Tile = 32,
		Sign = 40, -- pixels a tile on a sign's face (50 pixels a stud: Server/Utils/SignFace)
	},
	-- Heights: in rows, standard, a panel's main button, the round close, tabs.
	ButtonHeight = {
		Row = 36,
		Standard = 44,
		Hero = 52,
		Close = 40,
		Tab = 30,
	},
	MinTouch = 44, -- nothing smaller than this is pressed; smaller drawings get a bigger hit area

	-- Every tween eases; nothing is Linear (UI_SPEC 1.8).
	Motion = {
		PopIn = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		PopInFrom = 0.85,
		PopOut = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		PopOutTo = 0.92,
		BackdropIn = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Backdrop = 0.62, -- the backdrop's transparency: blue 950 at 38%, so the world shows through the glass
		ConfirmBackdrop = 0.55, -- a confirm card's: 45%
		SquishDown = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		SquishUp = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		Squish = 0.94,
		SquishDrop = 3,
		PressShade = 0.84, -- a row, cell or tab held down: ink over it at this transparency
		PressLight = 0.75, -- a clear one (a tab not picked): snow at this transparency
		Wobble = { 0, -7, 6, -4, 2, 0 }, -- degrees a still button (locked, owned) turns through when tapped
		WobbleSeconds = 0.3,
		-- A flashed colour holds a moment, then fades back.
		FlashFade = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.15),
		HoverBrighten = 0.08,
		PictureHover = 1.06, -- a picture button (UIKit.PictureButton) under the mouse grows this much instead
		TickUp = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		TickDown = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Punch = 1.12,
		Shake = { 0, -8, 7, -5, 3, 0 },
		ShakeSeconds = 0.32,
		NoticeIn = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		NoticeOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		NoticeDrop = 10,
		Glow = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		GlowDim = 0.5,
		Celebrate = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		CelebrateFrom = 0.2,
		CelebrateHold = 3,
		CelebrateFade = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		CashAppear = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		CashAppearFrom = 0.3,
		Slide = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		BarFill = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- a progress bar sliding to its new length
		BarReady = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), -- a full bar breathing
		Reveal = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		RevealFrom = 0.4,
		Dots = 0.4, -- seconds per step of the loading dots
	},

	-- One UIScale per screen: 1 + (short side - Base) x PerPoint, clamped (UI_SPEC 3.3).
	Scale = {
		Base = 390,
		PerPoint = 0.0006,
		Min = 0.85,
		Max = 1.8,
		TV = 1.15,
		-- The HUD on a computer (no touch screen, not a TV) is drawn this much bigger than the rest: at the one scale a
		-- 1080p screen's buttons looked small (Mark, 2026-10-03). Menus keep the one scale.
		Computer = 1.5,
		-- And the guide's words at the top (and its celebration): beside the bigger HUD they read small (Mark: twice
		-- as big).
		ComputerText = 2,
	},

	-- Menus: the safe area's height minus Margin, up to MaxHeight; Aspect times as wide, up to MaxWidth and the safe
	-- width minus SideMargin.
	Menu = {
		Margin = 16,
		MaxHeight = 404,
		Aspect = 2.35,
		MaxWidth = 760,
		SideMargin = 24,
		HeaderHeight = 50,
		Inset = 6, -- the body inside the frame, rows inside the body
	},

	-- Each server-wide event's banner at the bottom middle (UIController/EventBanner, GameConfig.Events.Kinds; Mark's
	-- pick D3 of DESIGN/ui/mockups/events-mid.html, 2026-10-03): its picture (a Theme.Icons key), its title's colours
	-- from top to bottom, the fill of the ring round its picture and the colour of the rays behind it.
	Events = {
		GoldenHour = {
			Icon = "HudClock",
			Title = { rgb(255, 246, 184), rgb(255, 210, 63), rgb(255, 157, 28) },
			Fill = rgb(255, 184, 28),
			Rays = rgb(255, 214, 90),
		},
		LuckyHour = {
			Icon = "HudClover",
			Title = { rgb(226, 255, 239), rgb(92, 245, 162), rgb(20, 196, 110) },
			Fill = rgb(47, 214, 124),
			Rays = rgb(110, 255, 170),
		},
		WoolRush = {
			Icon = "HudCloud",
			Title = { rgb(255, 232, 246), rgb(255, 154, 214), rgb(255, 79, 168) },
			Fill = rgb(255, 98, 184),
			Rays = rgb(255, 160, 215),
		},
	} :: { [string]: { Icon: string, Title: { Color3 }, Fill: Color3, Rays: Color3 } },

	-- "Prize Fleece" (DESIGN/ui/fleece/SPEC.md, Mark's pick 2026-10-03): every menu and pop-up is one panel, an opaque
	-- slate body under a header in its family's colour with its picture breaking the top-left corner. Only the colour,
	-- the picture, the size and the body change between menus.
	Fleece = {
		Body = { Hi = rgb(58, 66, 87), Base = rgb(47, 54, 71), Lo = rgb(39, 45, 60) },
		-- Sunk (lists, the tab bar) and raised (facts, rows) pieces on the body.
		Well = rgb(10, 12, 20),
		WellTransparency = 0.58,
		Tile = { Hi = rgb(74, 84, 105), Base = rgb(60, 68, 87), Lo = rgb(44, 50, 66) },
		Muted = rgb(169, 179, 200), -- the one line under a name, eyebrows
		Faint = rgb(111, 122, 144),
		Gold = rgb(255, 210, 63), -- the wool bonus
		-- Each family's header: lit top, face, lip.
		Accent = {
			Shop = { Hi = rgb(108, 196, 255), Base = rgb(47, 143, 240), Lo = rgb(27, 95, 176) },
			Upgrade = { Hi = rgb(255, 192, 97), Base = rgb(242, 138, 30), Lo = rgb(168, 88, 11) },
			Rebirth = { Hi = rgb(255, 127, 189), Base = rgb(230, 60, 140), Lo = rgb(156, 28, 90) },
			Dex = { Hi = rgb(82, 227, 207), Base = rgb(23, 173, 158), Lo = rgb(11, 111, 102) },
			Store = { Hi = rgb(200, 121, 255), Base = rgb(155, 48, 236), Lo = rgb(95, 26, 153) },
			Daily = { Hi = rgb(255, 224, 102), Base = rgb(255, 179, 26), Lo = rgb(176, 111, 0) },
			Kennel = { Hi = rgb(228, 171, 114), Base = rgb(191, 123, 64), Lo = rgb(122, 74, 32) },
			Den = { Hi = rgb(141, 137, 255), Base = rgb(87, 82, 214), Lo = rgb(46, 42, 143) },
			Lab = { Hi = rgb(111, 240, 255), Base = rgb(34, 184, 224), Lo = rgb(16, 111, 146) },
			Settings = { Hi = rgb(183, 194, 209), Base = rgb(127, 140, 160), Lo = rgb(79, 89, 107) },
			Confirm = { Hi = rgb(108, 196, 255), Base = rgb(47, 143, 240), Lo = rgb(27, 95, 176) },
			Warning = { Hi = rgb(255, 138, 122), Base = rgb(232, 70, 60), Lo = rgb(158, 29, 23) },
			Sell = { Hi = rgb(138, 240, 106), Base = rgb(60, 191, 53), Lo = rgb(34, 125, 32) }, -- the Sell Stall
			Gold = { Hi = rgb(255, 230, 128), Base = rgb(245, 176, 0), Lo = rgb(165, 107, 0) },
		} :: { [string]: { Hi: Color3, Base: Color3, Lo: Color3 } },
		-- A card's fill by its sheep's tier: lit top, face, lip. Secret is night with a rainbow ring.
		Rarity = {
			Common = { Hi = rgb(195, 204, 219), Base = rgb(142, 155, 176), Lo = rgb(93, 106, 128) },
			Uncommon = { Hi = rgb(82, 227, 194), Base = rgb(29, 174, 147), Lo = rgb(13, 117, 99) },
			Rare = { Hi = rgb(99, 193, 255), Base = rgb(30, 150, 230), Lo = rgb(14, 95, 161) },
			Epic = { Hi = rgb(189, 145, 255), Base = rgb(139, 85, 232), Lo = rgb(86, 42, 171) },
			Legendary = { Hi = rgb(255, 227, 107), Base = rgb(255, 178, 28), Lo = rgb(183, 115, 0) },
			Mythic = { Hi = rgb(255, 134, 194), Base = rgb(230, 66, 143), Lo = rgb(158, 31, 92) },
			Secret = { Hi = rgb(75, 61, 118), Base = rgb(44, 35, 71), Lo = rgb(23, 17, 43) },
			Locked = { Hi = rgb(61, 67, 82), Base = rgb(43, 48, 60), Lo = rgb(28, 32, 41) },
		} :: { [string]: { Hi: Color3, Base: Color3, Lo: Color3 } },
		-- Panel sizes in points: L for shops and collections, M for one thing's page, S (a width) for pop-ups.
		Large = Vector2.new(700, 400),
		Medium = Vector2.new(620, 380),
		Small = 360,
		-- The shortest a panel gets laid out: on a screen with less room (a small phone held sideways) the whole panel is
		-- drawn at this height and scaled down to fit (the window's Fit attribute), so nothing in it gets squeezed.
		CompactHeight = 318,
		Header = 58, -- the header's height
		HeaderLip = 5,
		Badge = 88, -- the family's picture, hanging over the top-left corner
		BadgeTilt = -9,
		BadgeCompact = 66, -- tucked into the header when the panel reaches the top of the safe area (a phone)
		Title = 34,
		PopTitle = 30,
		Radius = 18,
		Outline = 3,
		Lip = 7,
		Inset = 12, -- the body's margin, and the gap between its pieces
		TabBar = 44, -- the tab bar's height, its well's padding included
		Card = Vector2.new(100, 124), -- a sheep card in a grid
		CardGap = 10,
		CardRadius = 14,
		TileRadius = 14,
	},

	-- Images uploaded from DESIGN/ui/export (node DESIGN/ui/render.mjs --assets). An icon's `_fill` is its face in
	-- white, for ImageColor3, under its `_ink` layer; `_white` is a one-colour mark to tint.
	Icons = {
		Alert = "rbxassetid://136975511022270",
		AlertFill = "rbxassetid://95466154090599",
		AlertInk = "rbxassetid://114796721879853",
		Avatar = "rbxassetid://80893772540553",
		Book = "rbxassetid://99977283755957",
		Boot = "rbxassetid://100112488311966",
		Cash = "rbxassetid://117747981856000",
		Check = "rbxassetid://88168249115112",
		CheckWhite = "rbxassetid://122500405106507",
		Chevron = "rbxassetid://126571121772666",
		ChevronWhite = "rbxassetid://71288440197887",
		Clock = "rbxassetid://70527632334133",
		Close = "rbxassetid://109207626189921",
		CloseWhite = "rbxassetid://75064462428407",
		Dog = "rbxassetid://131914019914566",
		Fence = "rbxassetid://89405766922863",
		Flag = "rbxassetid://101167291973433",
		Gem = "rbxassetid://132771989559735",
		GemFill = "rbxassetid://117867700628825",
		GemInk = "rbxassetid://74432366717947",
		Gift = "rbxassetid://134340766603087",
		Helix = "rbxassetid://127298080403176",
		Info = "rbxassetid://86401185074322",
		Lock = "rbxassetid://133022271040823",
		LockWhite = "rbxassetid://136795864568216",
		Paw = "rbxassetid://83069746337573",
		Pointer = "rbxassetid://104761709557868",
		PointerFill = "rbxassetid://95452734051178",
		PointerInk = "rbxassetid://127689181528431",
		Rebirth = "rbxassetid://74306120144077",
		Rosette = "rbxassetid://139223633204084",
		RosetteGold = "rbxassetid://90042585332631",
		RosetteGreen = "rbxassetid://104059205323589",
		WolfFill = "rbxassetid://124458579584130",
		WolfInk = "rbxassetid://126085280017509",
		Shears = "rbxassetid://98219095730622",
		Shield = "rbxassetid://106266206430506",
		ShieldFill = "rbxassetid://134814767560413",
		ShieldInk = "rbxassetid://78116555967190",
		Sparkle = "rbxassetid://72408773149877",
		SparkleFill = "rbxassetid://120343560072094",
		SparkleInk = "rbxassetid://131769556579199",
		Star = "rbxassetid://135778923790201",
		StarFill = "rbxassetid://97636486166110",
		StarInk = "rbxassetid://134850754738303",
		Tag = "rbxassetid://124309677857739",
		Wolf = "rbxassetid://121890156108554",
		-- The wolf alert's pointer, a plain triangle drawn pointing down: a face to tint and its thin black edge
		-- (art/ui/make_wolf_pointer.py).
		WolfPointerFill = "rbxassetid://97144110971874",
		WolfPointerInk = "rbxassetid://86354653030744",
		Wool = "rbxassetid://110245919270834",
		WoolFill = "rbxassetid://73488718350897",
		WoolInk = "rbxassetid://122105155688435",
		Yarn = "rbxassetid://74059868787082",
		Robux = "rbxasset://textures/ui/common/robux.png",

		-- The sheep token's layers, bottom to top (UI_SPEC 1.5).
		TokenLegs = "rbxassetid://71284420013184",
		TokenWool = "rbxassetid://81490818370349",
		TokenShine = "rbxassetid://80972901709075",
		TokenSpots = "rbxassetid://83259137297884",
		TokenHorns = "rbxassetid://72584934055562",
		TokenAntennae = "rbxassetid://90780938504656",
		TokenFace = "rbxassetid://120375013714088",
		TokenTuft = "rbxassetid://109038231444851",
		TokenFeatures = "rbxassetid://132969152053757",
		TokenFeaturesDark = "rbxassetid://84973023180691",

		Burst = "rbxassetid://109961169782256", -- the rays behind a celebration
		DangerGlow = "rbxassetid://136294112658361", -- white at the edges, clear in the middle; tinted red

		-- The HUD's menu buttons, 256 px pictures in the Mozert "Cartoon Vectors" style (art/menu/make_menu_icons.py):
		-- the Sheepdex book with the Farm Sheep in its portrait, the Store's basket, the Settings gear and the Wolf
		-- Guard's plain shield with a steel rim.
		MenuSheepdex = "rbxassetid://117365379042641",
		MenuStore = "rbxassetid://102712309475207",
		MenuSettings = "rbxassetid://117783435651159",
		MenuGuard = "rbxassetid://75719608173335",
		-- The Starter Pack's gift on the HUD's offers, the pack's own gift (Ranch Studs).
		MenuGift = "rbxassetid://108751218281504",
		-- A raid's chance in the wolf den, the pack's own clover (2026-10-03).
		MenuClover = "rbxassetid://131073994954175",

		-- The HUD's other pictures, 256 px from gvesster's Free Icon Pack v3.1 (art/menu/export_pack_icons.py): the
		-- cash stack on the cash pill, a fire (unused since the shear combo went), Fast Wool's lightning, the rebirth
		-- arrows and the leaderboard's trophy.
		HudCash = "rbxassetid://137456956486696",
		HudFire = "rbxassetid://137412988009372",
		HudBoost = "rbxassetid://73099413007540",
		-- The events' banners (2026-10-03): Golden Hour's golden clock, Lucky Hour's clover and Wool Rush's cloud (a
		-- wool puff).
		HudClock = "rbxassetid://83925573813617",
		HudClover = "rbxassetid://109010649176135",
		HudCloud = "rbxassetid://110760075293464",
		HudRebirth = "rbxassetid://139634266473406",
		HudTrophy = "rbxassetid://80868090980266",
		-- The friend boost's HUD tile (2026-10-05), from the same pack: two friends while any are in the server, one with a
		-- green plus (Add Player) as the invite while none are.
		HudFriend = "rbxassetid://106767967764586",
		HudInvite = "rbxassetid://136775580096135",
		-- The pack's red "!": over things the player can afford (UIController/Bangs) and on the HUD's Rebirth.
		HudAlert = "rbxassetid://93541923107912",
		-- The pack's golden calendar: the daily gift's card and its HUD button.
		HudDaily = "rbxassetid://139738111276874",
		-- The OP Pack's crown and the Pro Pack's golden upgrade arrow (Mark, 2026-10-02): their pictures on the Store's
		-- cards and the HUD's pack offer.
		HudCrown = "rbxassetid://72910266249238",
		HudUpgrade = "rbxassetid://135690982244686",
		-- Prize Fleece (2026-10-03): the pack's shoe (the Upgrades menu's Walk speed), warning sign (Pen Full), dog (the
		-- kennel), paw (the wolf den), house (the land a rebirth keeps), tick and padlock (a requirement met or still to
		-- do); and the shears drawn to the packs' rules for Shear size (art/menu/make_shears_icon.py).
		HudShoe = "rbxassetid://115583544742451",
		-- The Robux store's pictures (art/store, drawn 2026-10-05): each Climbing and Cash pack's, growing with its size,
		-- 2x Speed's gold-winged sandal, the passes', the stair walker's, and the HUD's store button.
		StoreClimb1 = "rbxassetid://115583544742451",
		StoreClimb2 = "rbxassetid://115583544742451",
		StoreClimb3 = "rbxassetid://115583544742451",
		StoreClimb4 = "rbxassetid://115583544742451",
		StoreClimb5 = "rbxassetid://115583544742451",
		StoreClimb6 = "rbxassetid://115583544742451",
		StoreCash1 = "rbxassetid://137456956486696",
		StoreCash2 = "rbxassetid://137456956486696",
		StoreCash3 = "rbxassetid://137456956486696",
		StoreCash4 = "rbxassetid://137456956486696",
		StoreCash5 = "rbxassetid://137456956486696",
		StoreSpeed = "rbxassetid://73099413007540",
		StoreMoney = "rbxassetid://137456956486696",
		StoreGrowth = "rbxassetid://83925573813617",
		StoreWalker = "rbxassetid://115583544742451",
		HudRobux = "rbxassetid://102712309475207",
		HudWarning = "rbxassetid://79323446999830",
		HudDog = "rbxassetid://130996484032696",
		HudPaw = "rbxassetid://119373941015314",
		HudHouse = "rbxassetid://86601372459717",
		HudCheck = "rbxassetid://136863909489350",
		HudLock = "rbxassetid://87178792033174",
		-- The wolf den: a ranch whose gate lock is recharging (2026-10-03).
		HudUnlock = "rbxassetid://131436481681869",
		MenuShears = "rbxassetid://92336704328286",
	},

	-- The same images drawn smaller (export/32, export/64 and export/128), in pixels. Roblox draws UI images without
	-- mipmaps, so one shown at under half its size skips pixels and its outlines break up; IconSizeController swaps
	-- in the copy that fits. An icon in Icons is 128 px and a token layer or menu button 256, twice its largest copy
	-- here.
	IconSizes = {
		Alert = { [32] = "rbxassetid://100018595037658", [64] = "rbxassetid://98229327547052" },
		AlertFill = { [32] = "rbxassetid://81528422401135", [64] = "rbxassetid://94254990046320" },
		AlertInk = { [32] = "rbxassetid://100668890810883", [64] = "rbxassetid://137317054250400" },
		Avatar = { [32] = "rbxassetid://113261489845455", [64] = "rbxassetid://82709263723627" },
		Book = { [32] = "rbxassetid://75897645613957", [64] = "rbxassetid://92992608190816" },
		Boot = { [32] = "rbxassetid://140053709543478", [64] = "rbxassetid://107613201248152" },
		Cash = { [32] = "rbxassetid://107175892145910", [64] = "rbxassetid://124239197221507" },
		Check = { [32] = "rbxassetid://96607783627370", [64] = "rbxassetid://117884961154375" },
		CheckWhite = { [32] = "rbxassetid://89449746216699", [64] = "rbxassetid://112182881996168" },
		Chevron = { [32] = "rbxassetid://84235178284317", [64] = "rbxassetid://132994134027789" },
		ChevronWhite = { [32] = "rbxassetid://90671173053147", [64] = "rbxassetid://93729229027711" },
		Clock = { [32] = "rbxassetid://128474880660100", [64] = "rbxassetid://123566536479483" },
		Close = { [32] = "rbxassetid://97661376855183", [64] = "rbxassetid://79848192043116" },
		CloseWhite = { [32] = "rbxassetid://113768777800459", [64] = "rbxassetid://97926706776965" },
		Dog = { [32] = "rbxassetid://120256297185784", [64] = "rbxassetid://113097695966663" },
		Fence = { [32] = "rbxassetid://71723660199604", [64] = "rbxassetid://73034878982204" },
		Flag = { [32] = "rbxassetid://137643630268110", [64] = "rbxassetid://123845207763643" },
		Gem = { [32] = "rbxassetid://103930965550898", [64] = "rbxassetid://123960368480121" },
		GemFill = { [32] = "rbxassetid://127581245262370", [64] = "rbxassetid://79930680085134" },
		GemInk = { [32] = "rbxassetid://137240560658405", [64] = "rbxassetid://76761278176953" },
		Gift = { [32] = "rbxassetid://134924955084410", [64] = "rbxassetid://112780689193110" },
		Helix = { [32] = "rbxassetid://119017205596093", [64] = "rbxassetid://70931766788345" },
		Info = { [32] = "rbxassetid://121621457251927", [64] = "rbxassetid://112715923714347" },
		Lock = { [32] = "rbxassetid://76198005027670", [64] = "rbxassetid://108444419603973" },
		LockWhite = { [32] = "rbxassetid://94613636332078", [64] = "rbxassetid://136632984458858" },
		Paw = { [32] = "rbxassetid://108236605679869", [64] = "rbxassetid://122235516032339" },
		Pointer = { [32] = "rbxassetid://92552019851690", [64] = "rbxassetid://83894773218454" },
		PointerFill = { [32] = "rbxassetid://72951171989206", [64] = "rbxassetid://119908275449605" },
		PointerInk = { [32] = "rbxassetid://105379344088663", [64] = "rbxassetid://76096248913518" },
		Rebirth = { [32] = "rbxassetid://105737304605067", [64] = "rbxassetid://115352285036733" },
		Rosette = { [32] = "rbxassetid://73158219798258", [64] = "rbxassetid://84574601542163" },
		RosetteGold = { [32] = "rbxassetid://135357551294580", [64] = "rbxassetid://70556801378650" },
		RosetteGreen = { [32] = "rbxassetid://84526875510471", [64] = "rbxassetid://82742036413616" },
		Shears = { [32] = "rbxassetid://101248515980521", [64] = "rbxassetid://102272530113267" },
		Shield = { [32] = "rbxassetid://113930316328398", [64] = "rbxassetid://107127291489306" },
		ShieldFill = { [32] = "rbxassetid://83790867124696", [64] = "rbxassetid://130992065791874" },
		ShieldInk = { [32] = "rbxassetid://95768693383717", [64] = "rbxassetid://135854949441064" },
		Sparkle = { [32] = "rbxassetid://89479670827057", [64] = "rbxassetid://101435523116047" },
		SparkleFill = { [32] = "rbxassetid://88625348507864", [64] = "rbxassetid://129985363820817" },
		SparkleInk = { [32] = "rbxassetid://80358267075755", [64] = "rbxassetid://73122612426795" },
		Star = { [32] = "rbxassetid://85383638239127", [64] = "rbxassetid://87853978359140" },
		StarFill = { [32] = "rbxassetid://85155632025121", [64] = "rbxassetid://140407948305591" },
		StarInk = { [32] = "rbxassetid://85956664848437", [64] = "rbxassetid://74832745205597" },
		Tag = { [32] = "rbxassetid://128039691057129", [64] = "rbxassetid://121333175275940" },
		Wolf = { [32] = "rbxassetid://132527896295085", [64] = "rbxassetid://129199817523938" },
		WolfFill = { [32] = "rbxassetid://78269914458631", [64] = "rbxassetid://109628613402520" },
		WolfInk = { [32] = "rbxassetid://117384496298950", [64] = "rbxassetid://71070529414106" },
		Wool = { [32] = "rbxassetid://99071883019705", [64] = "rbxassetid://101070775925036" },
		WoolFill = { [32] = "rbxassetid://136171037118755", [64] = "rbxassetid://82071539664128" },
		WoolInk = { [32] = "rbxassetid://83195252046602", [64] = "rbxassetid://93793835722049" },
		Yarn = { [32] = "rbxassetid://92066374453665", [64] = "rbxassetid://77058830302727" },
		TokenAntennae = { [64] = "rbxassetid://82989790552484", [128] = "rbxassetid://121582110479755" },
		TokenFace = { [64] = "rbxassetid://79211831714442", [128] = "rbxassetid://80459457085229" },
		TokenFeatures = { [64] = "rbxassetid://75264964882719", [128] = "rbxassetid://131416277790428" },
		TokenFeaturesDark = { [64] = "rbxassetid://84256467358348", [128] = "rbxassetid://109133976263362" },
		TokenHorns = { [64] = "rbxassetid://136325361173102", [128] = "rbxassetid://77434498186151" },
		TokenLegs = { [64] = "rbxassetid://129548125159144", [128] = "rbxassetid://80564054207275" },
		TokenShine = { [64] = "rbxassetid://103093765750306", [128] = "rbxassetid://121390218800710" },
		TokenSpots = { [64] = "rbxassetid://106430301812948", [128] = "rbxassetid://116873316566249" },
		TokenTuft = { [64] = "rbxassetid://96688993020052", [128] = "rbxassetid://101111607225149" },
		TokenWool = { [64] = "rbxassetid://137106063601117", [128] = "rbxassetid://117829361452032" },
		MenuSheepdex = { [64] = "rbxassetid://92615100892694", [128] = "rbxassetid://98223697982290" },
		MenuStore = { [64] = "rbxassetid://87422661843300", [128] = "rbxassetid://80442653198441" },
		MenuSettings = { [64] = "rbxassetid://76848100273662", [128] = "rbxassetid://90112159978361" },
		MenuGuard = { [64] = "rbxassetid://131927398982049", [128] = "rbxassetid://97577982557422" },
		MenuGift = { [64] = "rbxassetid://100707177390081", [128] = "rbxassetid://101240927723015" },
		MenuClover = { [64] = "rbxassetid://139755815065724", [128] = "rbxassetid://92076048801330" },
		HudCash = { [64] = "rbxassetid://117782895812392", [128] = "rbxassetid://107519691624858" },
		HudFire = { [64] = "rbxassetid://73196007364050", [128] = "rbxassetid://73997376206068" },
		HudBoost = { [64] = "rbxassetid://118019768629118", [128] = "rbxassetid://100460917644595" },
		HudClock = { [64] = "rbxassetid://91780290550268", [128] = "rbxassetid://70867464651989" },
		HudClover = { [64] = "rbxassetid://123263845002389", [128] = "rbxassetid://110479207785035" },
		HudCloud = { [64] = "rbxassetid://91721349892776", [128] = "rbxassetid://126606582174942" },
		HudRebirth = { [64] = "rbxassetid://91325357842597", [128] = "rbxassetid://140557635239283" },
		HudTrophy = { [64] = "rbxassetid://95420214977122", [128] = "rbxassetid://94851727140891" },
		HudAlert = { [64] = "rbxassetid://120384219717100", [128] = "rbxassetid://88141080468118" },
		HudDaily = { [64] = "rbxassetid://100492887401375", [128] = "rbxassetid://100330758183713" },
		HudCrown = { [64] = "rbxassetid://70881977478097", [128] = "rbxassetid://100103917334139" },
		HudUpgrade = { [64] = "rbxassetid://129079502301626", [128] = "rbxassetid://80362475823286" },
		HudShoe = { [64] = "rbxassetid://86142016100021", [128] = "rbxassetid://138884847358739" },
		HudWarning = { [64] = "rbxassetid://133818832916616", [128] = "rbxassetid://132431273945364" },
		HudDog = { [64] = "rbxassetid://124860465665342", [128] = "rbxassetid://87451805635726" },
		HudPaw = { [64] = "rbxassetid://87357528265338", [128] = "rbxassetid://120537429573505" },
		HudHouse = { [64] = "rbxassetid://122344558981615", [128] = "rbxassetid://123502095235615" },
		HudCheck = { [64] = "rbxassetid://113675041381025", [128] = "rbxassetid://112900935815883" },
		HudLock = { [64] = "rbxassetid://79827019605555", [128] = "rbxassetid://96039067522826" },
		HudUnlock = { [64] = "rbxassetid://109568780876365", [128] = "rbxassetid://135321038223421" },
		MenuShears = { [64] = "rbxassetid://70393574138903", [128] = "rbxassetid://123803608892151" },
	} :: { [string]: { [number]: string } },
}

return deepFreeze(Theme)
