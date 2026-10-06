--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Herds = require(ReplicatedStorage.Config.Herds)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Run = require(script.Parent.Run)

return function(t: Run.Suite)
	t.Test("every god has six families, Common to Mythic, each a look of its own", function()
		local seen: { [string]: boolean } = {}
		local gods = 0
		for god, herd in Herds.ByGod do
			gods += 1
			t.Expect(#herd).ToBe(#Herds.Rarities)
			for _, family in herd do
				t.Expect(GameConfig.Breeds[family] ~= nil).ToBe(true)
				t.Expect(seen[family]).ToBe(nil)
				seen[family] = true
			end
			t.Expect(type(god)).ToBe("string")
		end
		t.Expect(gods).ToBe(Olympus.Count)
	end)

	t.Test("each herd's Common is its god's own family", function()
		for _, tier in Olympus.Tiers do
			local herd = Herds.ByGod[tier.God]
			t.Expect(herd ~= nil).ToBe(true)
			if herd then
				t.Expect(herd[1]).ToBe(tier.Family)
			end
		end
	end)

	t.Test("every rarer look has a display name ending in Sheep", function()
		for id, look in Herds.Looks do
			t.Expect(GameConfig.Breeds[id].DisplayName).ToBe(look.Name)
			t.Expect(string.sub(look.Name, -6)).ToBe(" Sheep")
		end
	end)
end
