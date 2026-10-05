--!strict

local StarterPlayer = game:GetService("StarterPlayer")

local Path = require(StarterPlayer.StarterPlayerScripts.Controllers.TrailerController.Path)
local Run = require(script.Parent.Run)

local function close(a: Vector3, b: Vector3): boolean
	return (a - b).Magnitude < 1e-4
end

return function(t: Run.Suite)
	t.Test("every easing starts at 0 and ends at 1", function()
		for _, ease in { "Linear", "In", "Out", "InOut" } do
			t.Expect(Path.Ease(0, ease)).ToBe(0)
			t.Expect(Path.Ease(1, ease)).ToBe(1)
		end
	end)

	t.Test("a path runs from its first key to its last", function()
		local built = Path.Build({ Vector3.new(0, 0, 0), Vector3.new(10, 0, 0), Vector3.new(10, 0, 10) })
		t.Expect(close(Path.At(built, 0), Vector3.new(0, 0, 0))).ToBe(true)
		t.Expect(close(Path.At(built, 1), Vector3.new(10, 0, 10))).ToBe(true)
	end)

	t.Test("the camera travels at an even speed, however the keys are spaced", function()
		local built = Path.Build({ Vector3.new(0, 0, 0), Vector3.new(10, 0, 0), Vector3.new(30, 0, 0) })
		t.Expect(math.abs(Path.At(built, 0.5).X - 15) < 0.01).ToBe(true)
	end)
end
