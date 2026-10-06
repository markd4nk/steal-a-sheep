--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Roster = require(ServerScriptService.Services.FlockService.Roster)
local Run = require(script.Parent.Run)

local function make(id: string, size: number, slot: number, pinned: boolean?): Economy.Sheep
	local sheep: Economy.Sheep = {
		Id = id,
		Family = Olympus.Tiers[1].Family,
		Rarity = 1,
		Weight = 1,
		Size = size,
		Grown = 0,
		Rank = 0,
		Locked = false,
		Slot = slot,
		Pinned = pinned == true,
	}
	sheep.Grown = Economy.GrowthSeconds(sheep)
	return sheep
end

return function(t: Run.Suite)
	t.Test("FreeSlot finds the lowest empty slot, nil when full", function()
		local flock = { ["1"] = make("1", 1, 1), ["2"] = make("2", 1, 3) }
		t.Expect(Roster.FreeSlot(flock, 3)).ToBe(2)
		flock["3"] = make("3", 1, 2)
		t.Expect(Roster.FreeSlot(flock, 3)).ToBe(nil)
	end)

	t.Test("Equip Best fills the slots with the top earners and keeps pinned ones", function()
		local flock = {
			["1"] = make("1", 1, 1, true), -- pinned, small
			["2"] = make("2", 1, 2),
			["3"] = make("3", 3, 0), -- a Giant in storage
			["4"] = make("4", 2, 0),
		}
		Roster.EquipBest(flock, 3)
		t.Expect(flock["1"].Slot).ToBe(1)
		t.Expect(flock["3"].Slot > 0).ToBe(true)
		t.Expect(flock["4"].Slot > 0).ToBe(true)
		t.Expect(flock["2"].Slot).ToBe(0)
		t.Expect(Roster.Income(flock, 3)).ToBe(2 + 5 + 3)
	end)

	t.Test("Equip Best keeps a growing lamb in by its likely worth, not its family", function()
		local lamb = make("1", 1, 0)
		lamb.Grown = 0
		lamb.Family = Olympus.Tiers[3].Family
		local flock = { ["1"] = lamb, ["2"] = make("2", 1, 1), ["3"] = make("3", 1, 0) }
		Roster.EquipBest(flock, 2)
		-- Tier 3's lamb is worth more than tier 1's grown sheep, though it earns nothing yet.
		t.Expect(flock["1"].Slot > 0).ToBe(true)
		t.Expect(Roster.Income(flock, 2)).ToBe(2)
	end)

	t.Test("Normalize stores sheep past the pen's size and splits shared slots", function()
		local flock = { ["1"] = make("1", 1, 5), ["2"] = make("2", 1, 2), ["3"] = make("3", 1, 2) }
		Roster.Normalize(flock, 3)
		t.Expect(flock["1"].Slot).ToBe(0)
		t.Expect(flock["2"].Slot).ToBe(2)
		t.Expect(flock["3"].Slot).ToBe(0)
	end)

	t.Test("CanSell takes stored, unlocked sheep only, each once, never the whole flock", function()
		local flock = { ["1"] = make("1", 1, 1), ["2"] = make("2", 1, 0), ["3"] = make("3", 2, 0) }
		t.Expect((Roster.CanSell(flock, { "2", "3" }, 3))).ToBe(true)
		t.Expect((Roster.CanSell(flock, {}, 3))).ToBe(false)
		t.Expect((Roster.CanSell(flock, { "1" }, 3))).ToBe(false) -- earning in the pen
		t.Expect((Roster.CanSell(flock, { "2", "2" }, 3))).ToBe(false)
		t.Expect((Roster.CanSell(flock, { "9" }, 3))).ToBe(false)
		flock["3"].Locked = true
		t.Expect((Roster.CanSell(flock, { "3" }, 3))).ToBe(false)
		-- Past the pen's size counts as stored; selling every sheep is refused.
		local stored = { ["1"] = make("1", 1, 5), ["2"] = make("2", 1, 0) }
		t.Expect((Roster.CanSell(stored, { "1" }, 3))).ToBe(true)
		t.Expect((Roster.CanSell(stored, { "1", "2" }, 3))).ToBe(false)
	end)
end
