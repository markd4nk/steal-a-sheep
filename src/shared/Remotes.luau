--!strict

-- The one module allowed to create instances at require time. Define every remote here with
-- Net.ToServer / Net.ToClient / Net.Request before the server bootstrap calls Net.Publish().
-- See BRAIN/PATTERNS/networking.md.
local Net = require(script.Parent.Net)
local Guard = Net.Guard

local FLOCK_ACTIONS = { "Equip", "Unequip", "Lock", "Unlock", "Sell", "EquipBest" }
local BUY_ITEMS = { "Walker", "PenSlot", "Trail" }
local SHEEP_ID = Guard.String(16)

local Remotes = {
	-- Studio-only test tools (DebugService and the debug panel): a command's name and an optional number. Live
	-- servers refuse every command.
	Debug = Net.Request(
		"Debug",
		{ Guard.String(40), Guard.Optional(Guard.Number(-1e15, 1e15)) },
		{ Count = 20, Window = 1 }
	) :: Net.Request<(string, number?), (boolean, string?)>,

	-- The player's flock and progress (FlockService.Snapshot): the whole table each time something in it changes.
	State = Net.ToClient("State") :: Net.ToClient<{ [string]: any }>,
	-- The same snapshot on request, for a client that has just started.
	GetState = Net.Request("GetState", {}, { Count = 4, Window = 2 }) :: Net.Request<(), ({ [string]: any })>,

	-- A notice under the HUD's top row: words, "Good" | "Bad" | "Rare", and a sound cue's name (Config/Sounds).
	Notify = Net.ToClient("Notify") :: Net.ToClient<(string, string, string?)>,
	-- A god set off after this player (their name), or nil when the chase ended.
	Chase = Net.ToClient("Chase") :: Net.ToClient<(string?, number?)>,
	-- A lamb grew up: its name and size ("Giant").
	Reveal = Net.ToClient("Reveal") :: Net.ToClient<(string, string)>,
	-- Coins earned while away and how many lambs grew up meanwhile.
	Offline = Net.ToClient("Offline") :: Net.ToClient<(number, number)>,
	-- A slider knocked this player back, down the slope (the direction), or this player's slide hit someone.
	Knockback = Net.ToClient("Knockback") :: Net.ToClient<Vector3>,
	SlideHit = Net.ToClient("SlideHit") :: Net.ToClient<number>,

	-- The player's own flock: equip, unequip, lock, unlock or sell one sheep, or Equip Best (no id).
	FlockAction = Net.Request(
		"FlockAction",
		{ Guard.OneOf(FLOCK_ACTIONS), Guard.Optional(SHEEP_ID) },
		{ Count = 12, Window = 1 }
	) :: Net.Request<(string, string?), (boolean, string?)>,
	-- Three sheep into one at the Merge Shrine: (ok, message, the new sheep's id).
	Merge = Net.Request("Merge", { Guard.Array(SHEEP_ID, 3) }, { Count = 4, Window = 1 }) :: Net.Request<({ string }), (boolean, string?, string?)>,
	-- The shop: the next stair walker, room for one more sheep in the pen, or a trail by id (bought, or equipped if
	-- owned).
	Buy = Net.Request("Buy", { Guard.OneOf(BUY_ITEMS), Guard.Optional(Guard.String(16)) }, { Count = 8, Window = 1 }) :: Net.Request<(string, string?), (boolean, string?)>,
	-- Give up a run: the carried sheep goes back to its pasture.
	ReturnSheep = Net.ToServer("ReturnSheep", {}, { Count = 2, Window = 1 }) :: Net.ToServer<()>,
	-- Off the stair walker (the player jumped while on it).
	LeaveWalker = Net.ToServer("LeaveWalker", {}, { Count = 4, Window = 1 }) :: Net.ToServer<()>,
	-- Put the carried lamb down here, in the player's own pen: that delivers it (the server checks where they stand).
	PutDown = Net.ToServer("PutDown", {}, { Count = 4, Window = 1 }) :: Net.ToServer<()>,
	-- The client's slide state (MovementController): the server checks hits only for sliders it has heard from.
	Slide = Net.ToServer("Slide", { Guard.Boolean() }, { Count = 20, Window = 1 }) :: Net.ToServer<boolean>,
}

return Remotes
