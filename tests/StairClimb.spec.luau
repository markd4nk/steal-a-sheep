--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local StairClimb = require(ReplicatedStorage.Utils.StairClimb)
local Run = require(script.Parent.Run)

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return function(t: Run.Suite)
	t.Test("steps run faster at every level and with a trail", function()
		local config = GameConfig.StairWalker
		t.Expect(near(StairClimb.StepSeconds(Economy.WalkerRate(0)), config.SlowestStep)).ToBe(true)
		t.Expect(near(StairClimb.StepSeconds(0), config.SlowestStep)).ToBe(true)
		for level = 1, Economy.MaxWalker do
			t.Expect(
				StairClimb.StepSeconds(Economy.WalkerRate(level))
					< StairClimb.StepSeconds(Economy.WalkerRate(level - 1))
			)
				.ToBe(true)
		end
		local top = Economy.WalkerRate(Economy.MaxWalker)
		t.Expect(
			StairClimb.StepSeconds(Economy.TrainingRate(Economy.MaxWalker, "Sunlight")) < StairClimb.StepSeconds(top)
		)
			.ToBe(true)
		t.Expect(near(StairClimb.StepSeconds(top * 1000), config.FastestStep)).ToBe(true)
		-- Three upgrades in, at least half a step a second faster than the free machine: a change you can see.
		t.Expect(StairClimb.StepSeconds(Economy.WalkerRate(3)) < 1 / (1 / config.SlowestStep + 0.5)).ToBe(true)
	end)

	t.Test("a step comes down one rise and back one run each cycle", function()
		local a, b = StairClimb.Tread(1), StairClimb.Tread(0)
		t.Expect(near(a.Y - b.Y, StairClimb.Rise)).ToBe(true)
		t.Expect(near(b.Z - a.Z, StairClimb.Run)).ToBe(true)
		for index = 1, StairClimb.Steps do
			for _, cycle in { 0, 0.25, 0.5, 3.75, 120.1 } do
				local u = StairClimb.StepAt(index, cycle)
				t.Expect(u >= StairClimb.Lowest and u < StairClimb.Lowest + StairClimb.Steps).ToBe(true)
			end
			-- A quarter of a cycle later, every step is a quarter step lower (or has wrapped round inside).
			local now, later = StairClimb.StepAt(index, 0.5), StairClimb.StepAt(index, 0.75)
			t.Expect(near(now - later, 0.25) or near(now - later + StairClimb.Steps, 0.25)).ToBe(true)
		end
	end)

	t.Test("about five steps show at any moment", function()
		for _, cycle in { 0, 0.3, 0.6, 0.9 } do
			local shown = 0
			for index = 1, StairClimb.Steps do
				if StairClimb.Shown(StairClimb.StepAt(index, cycle)) then
					shown += 1
				end
			end
			t.Expect(shown >= 5 and shown <= 6).ToBe(true)
		end
	end)
end
