--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RateLimit = require(ReplicatedStorage.Utils.RateLimit)
local Run = require(script.Parent.Run)

return function(t: Run.Suite)
	t.Test("allows a burst of Count, then refills over Window", function()
		local now = 0
		local limiter = RateLimit.new(2, 1, function()
			return now
		end)
		t.Expect(limiter:Allow("a")).ToBe(true)
		t.Expect(limiter:Allow("a")).ToBe(true)
		t.Expect(limiter:Allow("a")).ToBe(false)
		now = 0.5
		t.Expect(limiter:Allow("a")).ToBe(true)
		t.Expect(limiter:Allow("a")).ToBe(false)
	end)

	t.Test("tracks keys separately", function()
		local limiter = RateLimit.new(1, 60, function()
			return 0
		end)
		t.Expect(limiter:Allow("a")).ToBe(true)
		t.Expect(limiter:Allow("b")).ToBe(true)
		t.Expect(limiter:Allow("a")).ToBe(false)
	end)

	t.Test("rejects invalid settings", function()
		t.Expect(function()
			RateLimit.new(0, 1)
		end).ToThrow()
		t.Expect(function()
			RateLimit.new(1.5, 1)
		end).ToThrow()
	end)
end
