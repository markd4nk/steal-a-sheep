--!strict

-- The one module allowed to create instances at require time. Define every remote here with
-- Net.ToServer / Net.ToClient / Net.Request before the server bootstrap calls Net.Publish().
-- See BRAIN/PATTERNS/networking.md.
local GameConfig = require(script.Parent.Config.GameConfig)
local Net = require(script.Parent.Net)
local PlayerSettings = require(script.Parent.Utils.PlayerSettings)
local Guard = Net.Guard

local FLOCK_ACTIONS = { "Equip", "Unequip", "Lock", "Unlock", "EquipBest" }
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
	-- A god set off after this player (its name and tier), or nil when the chase ended: then how, "Caught" or "Escaped"
	-- (across the safety line), or nil (home, gave up, fell).
	Chase = Net.ToClient("Chase") :: Net.ToClient<(string?, number?, string?)>,
	-- A lamb grew up: its name and size ("Giant").
	Reveal = Net.ToClient("Reveal") :: Net.ToClient<(string, string)>,
	-- Coins earned while away and how many lambs grew up meanwhile.
	Offline = Net.ToClient("Offline") :: Net.ToClient<(number, number)>,
	-- A slider knocked this player back, down the slope (the direction), or this player's slide hit someone.
	Knockback = Net.ToClient("Knockback") :: Net.ToClient<Vector3>,
	SlideHit = Net.ToClient("SlideHit") :: Net.ToClient<number>,
	-- A god caught this player and punched them down the mountain: where they land, and how long the flight takes.
	Punch = Net.ToClient("Punch") :: Net.ToClient<(Vector3, number)>,

	-- The player's own flock: equip, unequip, lock or unlock one sheep, or Equip Best (no id).
	FlockAction = Net.Request(
		"FlockAction",
		{ Guard.OneOf(FLOCK_ACTIONS), Guard.Optional(SHEEP_ID) },
		{ Count = 12, Window = 1 }
	) :: Net.Request<(string, string?), (boolean, string?)>,
	-- Three grown sheep of one family into one fresh lamb at the Merge Shrine (ShrineService): (ok, message).
	Merge = Net.Request("Merge", { Guard.Array(SHEEP_ID, 3) }, { Count = 4, Window = 1 }) :: Net.Request<({ string }), (boolean, string?)>,
	-- The player's merge went through: what their shrine shows (the three going in, the lamb coming out, ShrineController),
	-- or nil once the lamb has left the altar (picked up, or gone to the pen by itself).
	ShrineShow = Net.ToClient("ShrineShow") :: Net.ToClient<({ [string]: any }?)>,
	-- Pick up your merged lamb from the shrine's altar.
	ShrineCollect = Net.ToServer("ShrineCollect", {}, { Count = 3, Window = 1 }) :: Net.ToServer<()>,
	-- The Sell Stall: these stored sheep sold together (ok, message).
	Sell = Net.Request("Sell", { Guard.Array(SHEEP_ID, GameConfig.Theft.InventoryLimit) }, { Count = 4, Window = 1 }) :: Net.Request<({ string }), (boolean, string?)>,
	-- The shop: the next stair walker, room for one more sheep in the pen, or a trail by id (bought, or equipped if
	-- owned).
	Buy = Net.Request("Buy", { Guard.OneOf(BUY_ITEMS), Guard.Optional(Guard.String(16)) }, { Count = 8, Window = 1 }) :: Net.Request<(string, string?), (boolean, string?)>,
	-- The Robux store: an item by its Config/Store key ("Cash.1", "Sheep.Kronos", "DoubleMoney"), or "Speed" or
	-- "Walker" for that ladder's next step. The server opens Roblox's dialog: (ok, a message to show).
	RequestPurchase = Net.Request("RequestPurchase", { Guard.String(32) }, { Count = 4, Window = 2 }) :: Net.Request<(string), (boolean, string?)>,
	-- The free gift, once per player: (ok, message, coins given, Climbing given).
	ClaimGift = Net.Request("ClaimGift", {}, { Count = 2, Window = 2 }) :: Net.Request<(), (boolean, string?, number?, number?)>,
	-- A Sheepdex entry's reward (SheepdexService), by family id.
	ClaimDex = Net.Request("ClaimDex", { Guard.String(32) }, { Count = 6, Window = 1 }) :: Net.Request<(string), (boolean, string?)>,
	-- Today's daily gift (DailyService): (ok, message, what was given: Day, Kind, Amount, or a sheep's Name and Family).
	ClaimDaily = Net.Request("ClaimDaily", {}, { Count = 2, Window = 2 }) :: Net.Request<(), (boolean, string?, { [string]: any }?)>,
	-- Give up a run: the carried sheep goes back to its pasture.
	ReturnSheep = Net.ToServer("ReturnSheep", {}, { Count = 2, Window = 1 }) :: Net.ToServer<()>,
	-- Off the stair walker (the player jumped while on it).
	LeaveWalker = Net.ToServer("LeaveWalker", {}, { Count = 4, Window = 1 }) :: Net.ToServer<()>,
	-- Put the carried lamb down here, in the player's own pen: that delivers it (the server checks where they stand).
	PutDown = Net.ToServer("PutDown", {}, { Count = 4, Window = 1 }) :: Net.ToServer<()>,
	-- The client's slide state (MovementController): the server checks hits only for sliders it has heard from.
	Slide = Net.ToServer("Slide", { Guard.Boolean() }, { Count = 20, Window = 1 }) :: Net.ToServer<boolean>,
	-- The Settings menu changing one of the player's own settings: its name and the new value (a volume 0 to 1, or 1
	-- and 0 for a toggle). The server cleans it up, saves it and mirrors it as Setting<Name> (SettingsService).
	SetSetting = Net.ToServer(
		"SetSetting",
		{ Guard.OneOf(PlayerSettings.NameList()), Guard.Number(0, 1) },
		{ Count = 12, Window = 2 }
	) :: Net.ToServer<PlayerSettings.Name, number>,
}

return Remotes
