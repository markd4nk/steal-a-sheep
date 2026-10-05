--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ServerScriptService.Data.PlayerData)
local Run = require(script.Parent.Run)

local function sheep(id: string): { [string]: any }
	return {
		Id = id,
		Family = "Meadow",
		Rarity = 1,
		Burden = 2,
		Size = 3,
		Grown = 10.5,
		Rank = 0,
		Locked = false,
		Slot = 2,
		Pinned = false,
	}
end

return function(t: Run.Suite)
	t.Test("accepts the template and data with missing fields", function()
		t.Expect((PlayerData.Validate(table.clone(PlayerData.Template)))).ToBe(true)
		t.Expect((PlayerData.Validate({}))).ToBe(true)
	end)

	t.Test("accepts fractional coins and Climb Power, and a well-formed flock", function()
		t.Expect((PlayerData.Validate({ Coins = 12.5, ClimbPower = 3.25 }))).ToBe(true)
		t.Expect((PlayerData.Validate({ Sheep = { ["1"] = sheep("1") } }))).ToBe(true)
	end)

	t.Test("rejects corrupt values instead of repairing them", function()
		t.Expect((PlayerData.Validate({ Coins = -1 }))).ToBe(false)
		t.Expect((PlayerData.Validate({ Coins = 0 / 0 }))).ToBe(false)
		t.Expect((PlayerData.Validate({ Coins = "100" }))).ToBe(false)
		t.Expect((PlayerData.Validate({ WalkerLevel = 1.5 }))).ToBe(false)
		t.Expect((PlayerData.Validate({ Receipts = { abc = "yesterday" } }))).ToBe(false)
		t.Expect((PlayerData.Validate("not a table"))).ToBe(false)
	end)

	t.Test("rejects a sheep with an impossible roll or a mismatched id", function()
		local bad = sheep("1")
		bad.Rarity = 4
		t.Expect((PlayerData.Validate({ Sheep = { ["1"] = bad } }))).ToBe(false)
		t.Expect((PlayerData.Validate({ Sheep = { ["2"] = sheep("1") } }))).ToBe(false)
	end)

	t.Test("accepts a sheep's home spot, and rejects one that isn't a number", function()
		local placed = sheep("1")
		placed.HomeX = -12.5
		placed.HomeZ = 30
		t.Expect((PlayerData.Validate({ Sheep = { ["1"] = placed } }))).ToBe(true)
		placed.HomeZ = "here"
		t.Expect((PlayerData.Validate({ Sheep = { ["1"] = placed } }))).ToBe(false)
		placed.HomeZ = 0 / 0
		t.Expect((PlayerData.Validate({ Sheep = { ["1"] = placed } }))).ToBe(false)
	end)

	t.Test("rejects data from a newer schema", function()
		t.Expect((PlayerData.Validate({ SchemaVersion = PlayerData.SchemaVersion + 1 }))).ToBe(false)
	end)

	t.Test("Migrate stamps the current schema version", function()
		local data: any = { Coins = 5 }
		PlayerData.Migrate(data)
		t.Expect(data.SchemaVersion).ToBe(PlayerData.SchemaVersion)
	end)
end
