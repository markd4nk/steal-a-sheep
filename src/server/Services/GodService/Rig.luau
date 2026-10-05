--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Olympus = require(ReplicatedStorage.Config.Olympus)

-- One primitive god: a blocky robed figure on Motor6D joints (clients swing the limbs, GodAnimController), its colours,
-- hair, sash, a nameplate, and its signature accessory. Built standing on the origin facing -Z, then scaled.
local Rig = {}

Rig.Scale = 1.6
Rig.Hip = 3 * Rig.Scale -- studs from the feet to the root's centre

local rgb = Color3.fromRGB
local rad = math.rad

local HAIR: { [string]: Color3 } = {
	Demeter = rgb(196, 140, 60),
	Dionysus = rgb(70, 40, 30),
	Artemis = rgb(60, 50, 50),
	Hephaestus = rgb(40, 30, 30),
	Ares = rgb(30, 26, 26),
	Aphrodite = rgb(255, 214, 120),
	Apollo = rgb(255, 220, 110),
	Athena = rgb(90, 60, 40),
	Poseidon = rgb(220, 226, 236),
	Hermes = rgb(150, 100, 50),
	Hera = rgb(80, 40, 30),
	Aeolus = rgb(200, 220, 235),
	Iris = rgb(255, 190, 120),
	Pan = rgb(110, 74, 44),
	Hebe = rgb(240, 200, 120),
	Eros = rgb(250, 210, 110),
	Tyche = rgb(60, 40, 30),
	Asclepius = rgb(210, 210, 214),
	Eris = rgb(30, 20, 30),
	Hecate = rgb(30, 26, 40),
	Hypnos = rgb(90, 70, 120),
	Morpheus = rgb(40, 40, 70),
	Phobos = rgb(30, 26, 26),
	Deimos = rgb(70, 30, 24),
	Thanatos = rgb(20, 20, 24),
	Nemesis = rgb(40, 60, 64),
	Themis = rgb(90, 64, 40),
	Nike = rgb(250, 220, 130),
	Hestia = rgb(120, 50, 30),
	Zeus = rgb(244, 244, 248),
}
local BEARDS = {
	Hephaestus = true,
	Poseidon = true,
	Zeus = true,
	Dionysus = true,
	Aeolus = true,
	Pan = true,
	Asclepius = true,
}

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	shape: Enum.PartType?
): Part
	local block = Instance.new("Part")
	block.Name = name
	block.Shape = shape or Enum.PartType.Block
	block.Size = size
	block.CFrame = cframe
	block.Color = color
	block.Material = Enum.Material.SmoothPlastic
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.CanCollide = false
	block.CanTouch = false
	block.CanQuery = false
	block.Massless = true
	block.Anchored = false
	block.Parent = parent
	return block
end

local function weld(host: BasePart, block: BasePart)
	local joint = Instance.new("Weld")
	joint.Part0 = host
	joint.Part1 = block
	joint.C0 = host.CFrame:ToObjectSpace(block.CFrame)
	joint.Parent = block
end

local function motor(name: string, host: BasePart, limb: BasePart, pivot: Vector3)
	local joint = Instance.new("Motor6D")
	joint.Name = name
	joint.Part0 = host
	joint.Part1 = limb
	joint.C0 = host.CFrame:ToObjectSpace(CFrame.new(pivot))
	joint.C1 = limb.CFrame:ToObjectSpace(CFrame.new(pivot))
	joint.Parent = host
end

local function extra(
	host: BasePart,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	shape: Enum.PartType?,
	neon: boolean?
)
	local block = part(host.Parent :: Instance, name, size, cframe, color, shape)
	if neon then
		block.Material = Enum.Material.Neon
	end
	weld(host, block)
	return block
end

local function ring(
	host: BasePart,
	name: string,
	center: Vector3,
	radius: number,
	count: number,
	size: Vector3,
	color: Color3,
	shape: Enum.PartType?
)
	for index = 1, count do
		local angle = index / count * 2 * math.pi
		local at = CFrame.new(center + Vector3.new(math.sin(angle) * radius, 0, math.cos(angle) * radius))
			* CFrame.Angles(0, angle, 0)
		extra(host, `{name}{index}`, size, at, color, shape)
	end
end

-- A pair of wings off the torso's back.
local function wings(torso: BasePart, size: Vector3, color: Color3)
	for _, side in { -1, 1 } do
		extra(
			torso,
			"Wing",
			size,
			CFrame.new(side * (0.6 + size.Y * 0.2), 3.6 + size.Y * 0.2, 0.75)
				* CFrame.Angles(rad(-20), 0, rad(side * -35)),
			color,
			nil,
			true
		)
	end
end

local function sign(kind: string, head: BasePart, rightArm: BasePart, leftArm: BasePart, tier: Olympus.Tier)
	local accent = tier.Accent
	local top = Vector3.new(0, 5.55, 0)
	local torso = (head.Parent :: Instance):FindFirstChild("Torso") :: BasePart
	if kind == "WheatCrown" then
		ring(head, "Wheat", top, 0.75, 9, Vector3.new(0.2, 0.7, 0.2), accent, Enum.PartType.Cylinder)
	elseif kind == "VineCrown" then
		ring(
			head,
			"Vine",
			top - Vector3.new(0, 0.1, 0),
			0.75,
			8,
			Vector3.new(0.4, 0.4, 0.4),
			accent,
			Enum.PartType.Ball
		)
		for index = 1, 3 do
			extra(
				head,
				`Grape{index}`,
				Vector3.new(0.35, 0.35, 0.35),
				CFrame.new(0.8 + index * 0.05, 5.1 - index * 0.3, 0.2),
				rgb(110, 40, 150),
				Enum.PartType.Ball
			)
		end
	elseif kind == "Crescent" then
		for index = -2, 2 do
			local angle = rad(index * 28)
			local at = CFrame.new(math.sin(angle) * 0.9, 6.1 + math.cos(angle) * 0.5 - 0.5, 0)
				* CFrame.Angles(0, 0, -angle)
			extra(head, `Moon{index + 3}`, Vector3.new(0.35, 0.35, 0.25), at, rgb(220, 236, 255), nil, true)
		end
	elseif kind == "Hammer" then
		local hand = rightArm.CFrame * CFrame.new(0, -1.1, -0.4)
		extra(rightArm, "Handle", Vector3.new(0.3, 2.4, 0.3), hand * CFrame.Angles(rad(90), 0, 0), rgb(110, 76, 50))
		extra(rightArm, "HammerHead", Vector3.new(1.1, 0.7, 0.7), hand * CFrame.new(0, 0, -1.2), rgb(70, 70, 76))
	elseif kind == "Plume" then
		extra(head, "Helmet", Vector3.new(1.65, 1.1, 1.65), CFrame.new(0, 5.2, 0), accent, Enum.PartType.Ball)
		extra(head, "Plume", Vector3.new(0.3, 0.8, 1.7), CFrame.new(0, 6, 0.1), rgb(220, 30, 30))
	elseif kind == "Rose" then
		extra(head, "Rose", Vector3.new(0.55, 0.55, 0.55), CFrame.new(0.65, 5.25, -0.3), accent, Enum.PartType.Ball)
		extra(
			head,
			"Rose2",
			Vector3.new(0.4, 0.4, 0.4),
			CFrame.new(-0.6, 5.3, -0.25),
			rgb(255, 120, 170),
			Enum.PartType.Ball
		)
	elseif kind == "SunHalo" then
		extra(
			head,
			"Halo",
			Vector3.new(0.2, 3.2, 3.2),
			CFrame.new(0, 4.9, 0.9) * CFrame.Angles(0, rad(90), 0),
			accent,
			Enum.PartType.Cylinder,
			true
		)
	elseif kind == "Shield" then
		extra(
			leftArm,
			"Shield",
			Vector3.new(0.25, 2.4, 2.4),
			leftArm.CFrame * CFrame.new(-0.55, 0, 0),
			accent,
			Enum.PartType.Cylinder
		)
		extra(head, "Helm", Vector3.new(1.55, 0.8, 1.55), CFrame.new(0, 5.3, 0), rgb(200, 200, 210), Enum.PartType.Ball)
	elseif kind == "Trident" then
		local hand = rightArm.CFrame * CFrame.new(0, -1, -0.3)
		extra(rightArm, "Shaft", Vector3.new(0.25, 5.5, 0.25), hand * CFrame.new(0, 1.2, 0), rgb(255, 200, 60))
		for index = -1, 1 do
			extra(
				rightArm,
				`Prong{index + 2}`,
				Vector3.new(0.2, 0.9, 0.2),
				hand * CFrame.new(index * 0.35, 4.3, 0),
				rgb(255, 214, 90)
			)
		end
		extra(rightArm, "Bar", Vector3.new(0.95, 0.2, 0.2), hand * CFrame.new(0, 3.9, 0), rgb(255, 214, 90))
	elseif kind == "WingedCap" then
		extra(head, "Cap", Vector3.new(1.6, 0.8, 1.6), CFrame.new(0, 5.35, 0), accent, Enum.PartType.Ball)
		for _, side in { -1, 1 } do
			extra(
				head,
				"Wing",
				Vector3.new(0.15, 0.9, 1.3),
				CFrame.new(side * 0.85, 5.6, 0.2) * CFrame.Angles(rad(-25), 0, rad(side * 25)),
				rgb(255, 255, 255),
				nil,
				true
			)
		end
	elseif kind == "Crown" then
		ring(head, "Crown", top, 0.7, 6, Vector3.new(0.3, 0.6, 0.3), accent)
		extra(
			head,
			"Gem",
			Vector3.new(0.35, 0.35, 0.35),
			CFrame.new(0, 5.6, -0.75),
			rgb(150, 60, 200),
			Enum.PartType.Ball,
			true
		)
	elseif kind == "Bolt" then
		local hand = rightArm.CFrame * CFrame.new(0, -1.1, 0)
		extra(
			rightArm,
			"Bolt1",
			Vector3.new(0.35, 1.3, 0.25),
			hand * CFrame.new(0, -0.5, -0.2) * CFrame.Angles(0, 0, rad(25)),
			accent,
			nil,
			true
		)
		extra(
			rightArm,
			"Bolt2",
			Vector3.new(0.35, 1.3, 0.25),
			hand * CFrame.new(0.2, -1.5, -0.2) * CFrame.Angles(0, 0, rad(-25)),
			accent,
			nil,
			true
		)
		extra(
			rightArm,
			"Bolt3",
			Vector3.new(0.35, 1.1, 0.25),
			hand * CFrame.new(0, -2.4, -0.2) * CFrame.Angles(0, 0, rad(25)),
			accent,
			nil,
			true
		)
	elseif kind == "WindSwirl" then
		-- Aeolus: gusts circling his head, and the bag of winds.
		for index = 1, 8 do
			local angle = index / 8 * 2 * math.pi
			local at = CFrame.new(math.sin(angle) * 1.1, 4.5 + index * 0.13, math.cos(angle) * 1.1)
				* CFrame.Angles(0, angle, 0)
			extra(head, `Gust{index}`, Vector3.new(0.55, 0.14, 0.14), at, accent, nil, true)
		end
		local sack = rightArm.CFrame * CFrame.new(0, -1.4, 0)
		extra(rightArm, "Sack", Vector3.new(1, 1, 1), sack, rgb(196, 170, 120), Enum.PartType.Ball)
	elseif kind == "RainbowHalo" then
		local bands = {
			rgb(240, 80, 80),
			rgb(250, 170, 60),
			rgb(250, 230, 80),
			rgb(90, 200, 110),
			rgb(80, 150, 240),
			rgb(170, 100, 230),
		}
		for index, color in bands do
			local size = 3.9 - index * 0.4
			extra(
				head,
				`Band{index}`,
				Vector3.new(0.2, size, size),
				CFrame.new(0, 4.9, 1.1 - index * 0.03) * CFrame.Angles(0, rad(90), 0),
				color,
				Enum.PartType.Cylinder
			)
		end
	elseif kind == "Horns" then
		-- Pan: goat horns and his pipes.
		local horn = rgb(214, 190, 150)
		for _, side in { -1, 1 } do
			local base = CFrame.new(side * 0.55, 5.6, 0.1) * CFrame.Angles(rad(-20), 0, rad(side * -25))
			local tip = CFrame.new(side * 0.85, 6.1, 0.35) * CFrame.Angles(rad(-50), 0, rad(side * -45))
			extra(head, "Horn", Vector3.new(0.3, 0.7, 0.3), base, horn)
			extra(head, "HornTip", Vector3.new(0.22, 0.6, 0.22), tip, horn)
		end
		local hand = rightArm.CFrame * CFrame.new(0, -1.1, -0.45)
		for index = 0, 4 do
			local length = 1.1 - index * 0.15
			local at = hand * CFrame.new(-0.4 + index * 0.2, -length / 2 + 0.4, 0)
			extra(rightArm, `Pipe{index + 1}`, Vector3.new(0.18, length, 0.18), at, rgb(206, 176, 112))
		end
	elseif kind == "Cup" then
		local hand = rightArm.CFrame * CFrame.new(0, -1.1, -0.4)
		extra(rightArm, "Stem", Vector3.new(0.2, 0.5, 0.2), hand, accent)
		extra(rightArm, "Bowl", Vector3.new(0.7, 0.5, 0.7), hand * CFrame.new(0, -0.45, 0), accent)
		extra(
			rightArm,
			"Nectar",
			Vector3.new(0.55, 0.1, 0.55),
			hand * CFrame.new(0, -0.72, 0),
			rgb(255, 170, 200),
			nil,
			true
		)
	elseif kind == "Bow" then
		-- Eros: a bow and small wings.
		local hand = leftArm.CFrame * CFrame.new(0, -1, -0.3)
		local wood = rgb(150, 100, 60)
		extra(leftArm, "BowMid", Vector3.new(0.2, 1, 0.2), hand, wood)
		extra(
			leftArm,
			"BowTop",
			Vector3.new(0.2, 0.9, 0.2),
			hand * CFrame.new(0, 0.85, -0.25) * CFrame.Angles(rad(-30), 0, 0),
			wood
		)
		extra(
			leftArm,
			"BowBottom",
			Vector3.new(0.2, 0.9, 0.2),
			hand * CFrame.new(0, -0.85, -0.25) * CFrame.Angles(rad(30), 0, 0),
			wood
		)
		extra(leftArm, "String", Vector3.new(0.05, 2.5, 0.05), hand * CFrame.new(0, 0, -0.45), rgb(255, 255, 255))
		wings(torso, Vector3.new(0.15, 1.4, 0.9), rgb(255, 210, 225))
	elseif kind == "CoinCrown" then
		ring(head, "Coin", top, 0.75, 8, Vector3.new(0.12, 0.55, 0.55), accent, Enum.PartType.Cylinder)
	elseif kind == "Staff" then
		-- Asclepius: the staff with a serpent round it.
		local hand = rightArm.CFrame * CFrame.new(0, -1, -0.3)
		extra(rightArm, "Staff", Vector3.new(0.25, 5.5, 0.25), hand * CFrame.new(0, 1.2, 0), rgb(130, 96, 60))
		for index = 1, 7 do
			local angle = index * 1.1
			local at = hand * CFrame.new(math.cos(angle) * 0.25, -0.8 + index * 0.55, math.sin(angle) * 0.25)
			extra(rightArm, `Coil{index}`, Vector3.new(0.3, 0.3, 0.3), at, accent, Enum.PartType.Ball)
		end
	elseif kind == "Apple" then
		local hand = rightArm.CFrame * CFrame.new(0, -1.4, -0.3)
		extra(rightArm, "Apple", Vector3.new(0.8, 0.8, 0.8), hand, accent, Enum.PartType.Ball)
		extra(rightArm, "AppleLeaf", Vector3.new(0.3, 0.08, 0.2), hand * CFrame.new(0.1, 0.45, 0), rgb(90, 170, 70))
	elseif kind == "Torch" then
		-- Hecate carries two.
		for _, arm in { rightArm, leftArm } do
			local hand = arm.CFrame * CFrame.new(0, -1.1, -0.4)
			extra(arm, "TorchStick", Vector3.new(0.2, 0.2, 1.6), hand * CFrame.new(0, 0, -0.5), rgb(90, 66, 50))
			extra(arm, "TorchFlame", Vector3.new(0.45, 0.6, 0.45), hand * CFrame.new(0, 0.2, -1.4), accent, nil, true)
		end
	elseif kind == "NightCap" then
		extra(head, "Cap", Vector3.new(1.55, 0.5, 1.55), CFrame.new(0, 5.45, 0.05), accent)
		extra(
			head,
			"Cap2",
			Vector3.new(1.1, 0.5, 1.1),
			CFrame.new(0.1, 5.85, 0.25) * CFrame.Angles(rad(15), 0, 0),
			accent
		)
		extra(
			head,
			"Cap3",
			Vector3.new(0.7, 0.5, 0.7),
			CFrame.new(0.2, 6.15, 0.55) * CFrame.Angles(rad(35), 0, 0),
			accent
		)
		extra(
			head,
			"Pompom",
			Vector3.new(0.4, 0.4, 0.4),
			CFrame.new(0.25, 6.2, 0.95),
			rgb(255, 255, 255),
			Enum.PartType.Ball
		)
	elseif kind == "Stars" then
		for index = 1, 6 do
			local angle = index / 6 * 2 * math.pi
			local at = CFrame.new(math.sin(angle) * 1.1, 6 + math.sin(angle * 2) * 0.2, math.cos(angle) * 1.1)
			extra(head, `Star{index}`, Vector3.new(0.32, 0.32, 0.32), at, accent, Enum.PartType.Ball, true)
		end
	elseif kind == "FearMask" then
		extra(head, "Mask", Vector3.new(1.45, 0.9, 0.2), CFrame.new(0, 4.85, -0.68), rgb(40, 36, 40))
		for _, side in { -1, 1 } do
			extra(head, "Eye", Vector3.new(0.25, 0.15, 0.1), CFrame.new(side * 0.3, 4.95, -0.8), accent, nil, true)
		end
		ring(head, "Spike", top, 0.65, 6, Vector3.new(0.2, 0.7, 0.2), rgb(60, 50, 56))
	elseif kind == "Scythe" then
		local hand = rightArm.CFrame * CFrame.new(0, -1, -0.3)
		extra(rightArm, "Snath", Vector3.new(0.25, 6, 0.25), hand * CFrame.new(0, 1.4, 0), rgb(60, 50, 46))
		extra(
			rightArm,
			"Blade",
			Vector3.new(0.12, 0.45, 2.2),
			hand * CFrame.new(0, 4.2, -1) * CFrame.Angles(rad(-15), 0, 0),
			accent
		)
		extra(head, "Hood", Vector3.new(1.65, 1.6, 1.45), CFrame.new(0, 4.95, 0.15), rgb(24, 24, 28))
	elseif kind == "Sword" then
		local hand = rightArm.CFrame * CFrame.new(0, -1.1, -0.3)
		extra(rightArm, "Hilt", Vector3.new(0.25, 0.6, 0.25), hand, rgb(70, 50, 40))
		extra(rightArm, "Guard", Vector3.new(0.9, 0.18, 0.25), hand * CFrame.new(0, -0.35, 0), rgb(220, 190, 90))
		extra(rightArm, "Blade", Vector3.new(0.3, 2.4, 0.12), hand * CFrame.new(0, -1.6, 0), accent)
	elseif kind == "Scales" then
		-- Themis: the scales of justice, and blind.
		local hand = leftArm.CFrame * CFrame.new(0, -1.1, -0.4)
		extra(leftArm, "Rod", Vector3.new(0.15, 1.2, 0.15), hand * CFrame.new(0, -0.6, 0), accent)
		extra(leftArm, "Beam", Vector3.new(1.8, 0.12, 0.12), hand * CFrame.new(0, -1.2, 0), accent)
		for _, side in { -1, 1 } do
			extra(leftArm, "Pan", Vector3.new(0.6, 0.1, 0.6), hand * CFrame.new(side * 0.85, -1.8, 0), accent)
		end
		extra(head, "Blindfold", Vector3.new(1.48, 0.3, 1.48), CFrame.new(0, 4.95, 0), rgb(240, 240, 246))
	elseif kind == "BackWings" then
		-- Nike: great wings and a laurel wreath.
		wings(torso, Vector3.new(0.2, 2.6, 1.4), rgb(255, 255, 255))
		ring(head, "Laurel", top, 0.75, 8, Vector3.new(0.35, 0.2, 0.35), rgb(90, 160, 80), Enum.PartType.Ball)
	elseif kind == "HandFlame" then
		local hand = rightArm.CFrame * CFrame.new(0, -1.3, -0.5)
		extra(rightArm, "Flame", Vector3.new(0.6, 0.8, 0.6), hand, accent, nil, true)
		extra(
			rightArm,
			"FlameCore",
			Vector3.new(0.35, 0.6, 0.35),
			hand * CFrame.new(0, 0.2, 0),
			rgb(255, 220, 110),
			nil,
			true
		)
	end
end

local function nameplate(head: BasePart, tier: Olympus.Tier)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Nameplate"
	billboard.Size = UDim2.fromOffset(220, 64)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.2, 0)
	billboard.MaxDistance = 160
	billboard.LightInfluence = 0
	billboard.Parent = head
	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = billboard
	local function line(name: string, text: string, height: number, color: Color3)
		local words = Instance.new("TextLabel")
		words.Name = name
		words.BackgroundTransparency = 1
		words.Size = UDim2.new(1, 0, 0, height)
		words.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
		words.TextScaled = true
		words.TextColor3 = color
		words.Text = text
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2.5
		stroke.Parent = words
		words.Parent = billboard
	end
	line("Mood", "", 22, Color3.fromRGB(255, 90, 80))
	line("GodName", tier.God, 26, Color3.new(1, 1, 1))
	line("Area", tier.Area, 16, Color3.fromRGB(255, 226, 120))
end

function Rig.Build(tier: Olympus.Tier): Model
	local model = Instance.new("Model")
	model.Name = tier.God
	local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), tier.Robe)
	root.Transparency = 1
	root.Massless = false
	model.PrimaryPart = root
	local torso = part(model, "Torso", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), tier.Robe)
	motor("RootJoint", root, torso, Vector3.new(0, 3, 0))
	extra(torso, "Sash", Vector3.new(0.4, 2.3, 1.08), CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, rad(35)), tier.Accent)
	extra(torso, "Robe", Vector3.new(2.3, 1.5, 1.25), CFrame.new(0, 1.65, 0), tier.Robe)
	local darker = tier.Robe:Lerp(Color3.new(0, 0, 0), 0.25)
	for _, side in { -1, 1 } do
		local leg = part(
			model,
			if side < 0 then "LeftLeg" else "RightLeg",
			Vector3.new(0.9, 2, 0.9),
			CFrame.new(side * 0.5, 1, 0),
			darker
		)
		motor(if side < 0 then "LeftHip" else "RightHip", torso, leg, Vector3.new(side * 0.5, 2, 0))
		local arm = part(
			model,
			if side < 0 then "LeftArm" else "RightArm",
			Vector3.new(0.8, 2, 0.8),
			CFrame.new(side * 1.4, 3, 0),
			tier.Skin
		)
		motor(if side < 0 then "LeftShoulder" else "RightShoulder", torso, arm, Vector3.new(side * 1.4, 3.9, 0))
	end
	local head = part(model, "Head", Vector3.new(1.4, 1.4, 1.4), CFrame.new(0, 4.75, 0), tier.Skin)
	motor("Neck", torso, head, Vector3.new(0, 4, 0))
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	local hair = HAIR[tier.God] or rgb(60, 40, 30)
	extra(head, "Hair", Vector3.new(1.5, 0.45, 1.5), CFrame.new(0, 5.4, 0.05), hair)
	extra(head, "HairBack", Vector3.new(1.5, 1.1, 0.35), CFrame.new(0, 4.85, 0.65), hair)
	if BEARDS[tier.God] then
		extra(head, "Beard", Vector3.new(1.2, 0.9, 0.35), CFrame.new(0, 4.15, -0.62), hair)
	end
	sign(
		tier.Sign,
		head,
		model:FindFirstChild("RightArm") :: BasePart,
		model:FindFirstChild("LeftArm") :: BasePart,
		tier
	)
	nameplate(head, tier)
	model:ScaleTo(Rig.Scale)
	return model
end

return table.freeze(Rig)
