--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Run = require(script.Parent.Run)
local Score = require(ServerScriptService.Services.LeaderboardService.Score)

return function(t: Run.Suite)
	t.Test("whole numbers come back exact up to a trillion", function()
		for _, value in { 0, 1, 2, 7, 10, 99, 100, 101, 999, 12345, 4_687_500, 2 ^ 31, 999_999_999_999 } do
			t.Expect(Score.Decode(Score.Encode(value))).ToBe(value)
		end
	end)

	t.Test("late-game numbers fit below 2^53 and keep twelve digits", function()
		for _, value in { 5e14, 3.6e19, 1e30, 1e300, math.huge } do
			local stored = Score.Encode(value)
			t.Expect(stored < 2 ^ 53 and stored % 1 == 0).ToBe(true)
			local back = Score.Decode(stored)
			t.Expect(math.abs(back - math.min(value, 1e300)) <= math.min(value, 1e300) * 1e-12).ToBe(true)
		end
	end)

	t.Test("keeps the order, and nothing below 0", function()
		local last = -1
		for _, value in { 0, 1, 2, 10, 11, 1000, 1001, 1e6, 1e12, 1e12 + 1, 1e15, 1e18 } do
			local stored = Score.Encode(value)
			t.Expect(stored > last).ToBe(true)
			last = stored
		end
		t.Expect(Score.Encode(-5)).ToBe(0)
		t.Expect(Score.Encode(0 / 0)).ToBe(0)
		t.Expect(Score.Decode(-5)).ToBe(0)
	end)

	t.Test("Top keeps each player's best, highest first, ties by UserId", function()
		local stored = { { UserId = 1, Value = 50 }, { UserId = 2, Value = 30 }, { UserId = 3, Value = 30 } }
		local live = { { UserId = 2, Value = 70 }, { UserId = 1, Value = 10 }, { UserId = 4, Value = 30 } }
		t.Expect(Score.Top(stored, live, 10)).ToEqual({
			{ UserId = 2, Value = 70 },
			{ UserId = 1, Value = 50 },
			{ UserId = 3, Value = 30 },
			{ UserId = 4, Value = 30 },
		})
	end)

	t.Test("Top cuts to the row count and leaves out players at 0", function()
		local live = { { UserId = 1, Value = 0 }, { UserId = 2, Value = 5 }, { UserId = 3, Value = 9 } }
		t.Expect(Score.Top({}, live, 1)).ToEqual({ { UserId = 3, Value = 9 } })
		t.Expect(#Score.Top({}, { { UserId = 1, Value = 0 } }, 10)).ToBe(0)
	end)
end
