--!strict

local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Looks = require(ServerScriptService.Services.SheepService.Looks)
local Run = require(script.Parent.Run)

local function part(name: string, material: Enum.Material, parent: Instance, tint: string?): Part
	local block = Instance.new("Part")
	block.Name = name
	block.Material = material
	if tint then
		block:SetAttribute("Tint", tint)
	end
	block.Parent = parent
	return block
end

return function(t: Run.Suite)
	t.Test("every wool material's stud variant is in the place, on the material the wool becomes", function()
		for _, look in GameConfig.Sheep.Studs do
			local variant = MaterialService:FindFirstChild(look.Variant)
			-- Missing: run studio/SheepStuds.luau in Edit (tools/assemble.luau does it for built places).
			t.Expect(if variant and variant:IsA("MaterialVariant") then variant.Name else nil).ToBe(look.Variant)
			if variant and variant:IsA("MaterialVariant") then
				t.Expect(variant.BaseMaterial).ToBe(look.Material)
			end
		end
	end)

	t.Test("Studs covers the fleece by its material and leaves the rest of the sheep alone", function()
		local model = Instance.new("Model")
		local wool = Instance.new("Folder")
		wool.Name = "Wool"
		wool.Parent = model
		local puff = part("Wool1", Enum.Material.SmoothPlastic, wool)
		local glowing = part("Stripe", Enum.Material.Neon, puff)
		local metal = part("Wool2", Enum.Material.Metal, wool)
		local glass = part("Wool3", Enum.Material.Glass, wool)
		local granite = part("Wool4", Enum.Material.Granite, wool)
		local tail = part("Tail", Enum.Material.SmoothPlastic, model)
		local head = part("Head", Enum.Material.SmoothPlastic, model)
		local addons = Instance.new("Folder")
		addons.Name = "Addons"
		addons.Parent = model
		local woolly = part("Tuft", Enum.Material.Fabric, addons, "Wool")
		local horn = part("Horn", Enum.Material.SmoothPlastic, addons, "Horn")

		Looks.Studs(model)

		t.Expect(puff.Material).ToBe(Enum.Material.Plastic)
		t.Expect(puff.MaterialVariant).ToBe("SheepStuds")
		t.Expect(glowing.Material).ToBe(Enum.Material.Plastic)
		t.Expect(glowing.MaterialVariant).ToBe("SheepStudsGlow")
		t.Expect(metal.Material).ToBe(Enum.Material.Metal)
		t.Expect(metal.MaterialVariant).ToBe("SheepStudsMetal")
		t.Expect(glass.Material).ToBe(Enum.Material.Plastic)
		t.Expect(glass.MaterialVariant).ToBe("SheepStuds")
		t.Expect(math.abs(glass.Transparency - 0.25) < 1e-3).ToBe(true)
		t.Expect(granite.Material).ToBe(Enum.Material.Granite)
		t.Expect(granite.MaterialVariant).ToBe("")
		t.Expect(tail.MaterialVariant).ToBe("SheepStuds")
		t.Expect(woolly.MaterialVariant).ToBe("SheepStudsFabric")
		t.Expect(head.Material).ToBe(Enum.Material.SmoothPlastic)
		t.Expect(head.MaterialVariant).ToBe("")
		t.Expect(horn.MaterialVariant).ToBe("")
		model:Destroy()
	end)
end
