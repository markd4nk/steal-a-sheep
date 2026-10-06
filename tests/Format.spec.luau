--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Utils.Format)
local Run = require(script.Parent.Run)

return function(t: Run.Suite)
	t.Test("Short keeps three digits and rounds down", function()
		t.Expect(Format.Short(950)).ToBe("950")
		t.Expect(Format.Short(1500)).ToBe("1.5K")
		t.Expect(Format.Short(2900)).ToBe("2.9K")
		t.Expect(Format.Short(12345)).ToBe("12.3K")
		t.Expect(Format.Short(2.57e12)).ToBe("2.57T")
	end)

	t.Test("maxDecimals keeps fewer digits after the point", function()
		t.Expect(Format.Short(2.57e12, 1)).ToBe("2.5T")
		t.Expect(Format.Short(2.04e12, 1)).ToBe("2T")
		t.Expect(Format.Short(12345, 1)).ToBe("12.3K")
		t.Expect(Format.Rate(2.57e12, 1)).ToBe("2.5T")
		t.Expect(Format.Rate(1)).ToBe("1")
		t.Expect(Format.Rate(1.25, 1)).ToBe("1.2")
	end)
end
