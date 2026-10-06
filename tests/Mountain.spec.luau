--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Mountain = require(ReplicatedStorage.Utils.Mountain)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Run = require(script.Parent.Run)

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

-- The middle of a tier's stretch of ramp.
local function on(tier: number): number
	local row = Olympus.Tiers[tier]
	return (row.XStart + row.XEnd) / 2
end

return function(t: Run.Suite)
	t.Test("slide base: the escape speed, never under walking speed", function()
		local tier10 = Olympus.Tiers[10]
		t.Expect(near(Mountain.SlideBase(tier10.Reach, 10, 1), Economy.GodSpeed(10))).ToBe(true)
		t.Expect(Mountain.SlideBase(0, 30, 1)).ToBe(GameConfig.Movement.WalkSpeed)
	end)

	t.Test("momentum: more for every tier passed, never past the top speed, none below the safety line", function()
		local per = GameConfig.Movement.MomentumPerTier
		local top = GameConfig.Movement.MomentumTop
		t.Expect(Mountain.Momentum(20, 10, on(10))).ToBe(1)
		t.Expect(near(Mountain.Momentum(20, 10, on(8)), 1 + per * 2)).ToBe(true)
		-- Climbing back up past where it began gives nothing extra.
		t.Expect(Mountain.Momentum(20, 10, on(12))).ToBe(1)
		-- From Zeus to tier 1 a slow slide is lifted to the top speed and no further.
		t.Expect(near(20 * Mountain.Momentum(20, 30, on(1)), top)).ToBe(true)
		-- A slide already faster than the top speed keeps its own.
		t.Expect(Mountain.Momentum(top * 1.5, 30, on(1))).ToBe(1)
		t.Expect(Mountain.Momentum(20, 30, Olympus.SafeLineX - 1)).ToBe(1)
	end)
end
