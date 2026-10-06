--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Run = require(script.Parent.Run)

return function(t: Run.Suite)
	t.Test("volumes go in four steps, kept within 0 and 1; toggles come from 1 and 0", function()
		t.Expect(PlayerSettings.Steps()).ToBe(4)
		t.Expect(PlayerSettings.Clean("MusicVolume", 0.43)).ToBe(0.5)
		t.Expect(PlayerSettings.Clean("MusicVolume", 0.1)).ToBe(0)
		t.Expect(PlayerSettings.Clean("SfxVolume", 0.9)).ToBe(1)
		t.Expect(PlayerSettings.Clean("SfxVolume", 1)).ToBe(1)
		t.Expect(PlayerSettings.Clean("SfxVolume", 0)).ToBe(0)
		t.Expect(PlayerSettings.Clean("ReduceMotion", 1)).ToBe(true)
		t.Expect(PlayerSettings.Clean("ReduceMotion", 0)).ToBe(false)
	end)

	t.Test("each setting has its own attribute and a default", function()
		local defaults = PlayerSettings.Defaults() :: any
		local seen: { [string]: boolean } = {}
		for _, name in PlayerSettings.Names do
			local attribute = PlayerSettings.Attribute(name)
			t.Expect(seen[attribute]).ToBe(nil)
			seen[attribute] = true
			t.Expect(defaults[name] ~= nil).ToBe(true)
			t.Expect(PlayerSettings.IsToggle(name)).ToBe(type(defaults[name]) == "boolean")
		end
		t.Expect(defaults.MusicVolume).ToBe(1)
		t.Expect(defaults.SfxVolume).ToBe(1)
		t.Expect(defaults.ReduceMotion).ToBe(false)
	end)

	t.Test("a saved Settings table must have the right types", function()
		t.Expect(PlayerSettings.IsValid(PlayerSettings.Defaults())).ToBe(true)
		t.Expect(PlayerSettings.IsValid({})).ToBe(true)
		t.Expect(PlayerSettings.IsValid({ SfxVolume = -0.25 })).ToBe(false)
		t.Expect(PlayerSettings.IsValid({ MusicVolume = 0 / 0 })).ToBe(false)
		t.Expect(PlayerSettings.IsValid({ ReduceMotion = "yes" })).ToBe(false)
		t.Expect(PlayerSettings.IsValid({ [1] = true })).ToBe(false)
	end)
end
