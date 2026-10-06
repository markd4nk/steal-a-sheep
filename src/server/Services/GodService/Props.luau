--!strict

-- The symbols the gods hold, built from blocks like the rest of the game's props (the user's rule: symbols as glowing
-- block props). Each is a list of blocks in the right fist's frame, at the gods' size: U across, V out of the fist
-- (down while the arm hangs, up when Zeus raises his), Z forwards. Long things held at the side (staffs, a trident)
-- run up past the fist, a little in front of the arm, so they stand upright. Welded to the hand, so they follow the
-- animations on every device.
local Props = {}

type Block = {
	U: number,
	V: number,
	Z: number?,
	Size: Vector3,
	Turn: number?, -- degrees, in the U-V plane
	Color: Color3,
	Glow: boolean?,
	Ball: boolean?,
}

local rgb = Color3.fromRGB
local V3 = Vector3.new
local GOLD = rgb(246, 192, 48)
local WOOD = rgb(120, 84, 52)
local SILVER = rgb(214, 220, 232)
local IRON = rgb(66, 62, 70)

local function upright(z: number, blocks: { Block }): { Block }
	for _, block in blocks do
		block.Z = block.Z or z
	end
	return blocks
end

local function staff(color: Color3, from: number, to: number, width: number?): Block
	local w = width or 0.26
	return { U = 0, V = (from + to) / 2, Size = V3(w, to - from, w), Color = color }
end

local function bolt(): { Block }
	local points = { Vector2.new(0.6, 2.3), Vector2.new(-0.35, 0.25), Vector2.new(0.5, 0.25), Vector2.new(-0.55, -2.3) }
	local widths = { 0.62, 0.55, 0.5 }
	local blocks: { Block } = {}
	for index = 1, 3 do
		local a, b = points[index], points[index + 1]
		local mid, d = (a + b) / 2, b - a
		table.insert(blocks, {
			U = mid.X,
			V = 1.2 + mid.Y,
			Size = V3(widths[index], d.Magnitude + widths[index] * 0.5, 0.45),
			Turn = -math.deg(math.atan2(d.X, d.Y)),
			Color = rgb(255, 226, 70),
			Glow = true,
		})
	end
	return blocks
end

local function bow(color: Color3): { Block }
	local blocks: { Block } = {}
	local radius = 2.6
	local previous: Vector2? = nil
	for step = -2, 2 do
		local angle = math.rad(step * 30)
		local at = Vector2.new(radius * math.cos(angle) - radius, radius * math.sin(angle))
		if previous then
			local mid, d = (previous + at) / 2, at - previous
			table.insert(blocks, {
				U = mid.X,
				V = mid.Y,
				Size = V3(0.26, d.Magnitude + 0.2, 0.26),
				Turn = -math.deg(math.atan2(d.X, d.Y)),
				Color = color,
			})
		end
		previous = at
	end
	local tip = radius * math.cos(math.rad(60)) - radius
	table.insert(blocks, {
		U = tip,
		V = 0,
		Size = V3(0.06, 2 * radius * math.sin(math.rad(60)), 0.06),
		Color = rgb(255, 255, 255),
		Glow = true,
	})
	return upright(0.5, blocks)
end

local KINDS: { [string]: () -> { Block } } = {
	Bolt = bolt,
	Trident = function()
		local aqua = rgb(120, 230, 255)
		return upright(0.7, {
			staff(rgb(40, 150, 170), -4.6, 2.6),
			{ U = 0, V = -4.6, Size = V3(1.6, 0.26, 0.3), Color = GOLD },
			{ U = 0, V = -5.5, Size = V3(0.3, 1.6, 0.3), Color = aqua, Glow = true },
			{ U = -0.7, V = -5.2, Size = V3(0.26, 1.0, 0.26), Color = aqua, Glow = true },
			{ U = 0.7, V = -5.2, Size = V3(0.26, 1.0, 0.26), Color = aqua, Glow = true },
		})
	end,
	Serpent = function()
		local blocks = { staff(WOOD, -4.2, 2.4) }
		for index = 0, 3 do
			local side = if index % 2 == 0 then 1 else -1
			table.insert(blocks, {
				U = side * 0.16,
				V = -1.2 - index * 0.8,
				Size = V3(0.22, 0.95, 0.3),
				Turn = side * 35,
				Color = rgb(90, 200, 110),
				Glow = true,
			})
		end
		table.insert(
			blocks,
			{ U = 0, V = -4.3, Size = V3(0.36, 0.36, 0.36), Color = rgb(90, 200, 110), Glow = true, Ball = true }
		)
		return upright(0.7, blocks)
	end,
	Caduceus = function()
		return upright(0.7, {
			staff(GOLD, -3.9, 2.2, 0.22),
			{ U = 0, V = -4.15, Size = V3(0.45, 0.45, 0.45), Color = GOLD, Ball = true },
			{ U = -0.45, V = -3.9, Size = V3(0.8, 0.28, 0.12), Turn = -25, Color = rgb(255, 255, 255), Glow = true },
			{ U = 0.45, V = -3.9, Size = V3(0.8, 0.28, 0.12), Turn = 25, Color = rgb(255, 255, 255), Glow = true },
		})
	end,
	PinkBow = function()
		return bow(rgb(255, 150, 196))
	end,
	SilverBow = function()
		return bow(SILVER)
	end,
	Hammer = function()
		return {
			{ U = 0, V = 0.8, Size = V3(0.3, 2.6, 0.3), Color = WOOD },
			{ U = 0, V = 2.3, Size = V3(1.4, 0.8, 0.8), Color = IRON },
			{ U = 0, V = 2.3, Size = V3(1.45, 0.2, 0.85), Color = rgb(255, 128, 40), Glow = true },
		}
	end,
	Torch = function()
		return upright(0.6, {
			staff(WOOD, -2.3, 0.4, 0.3),
			{ U = 0, V = -2.7, Size = V3(0.7, 1.0, 0.7), Color = rgb(255, 120, 30), Glow = true },
			{ U = 0, V = -2.85, Size = V3(0.4, 0.6, 0.4), Color = rgb(255, 220, 90), Glow = true },
		})
	end,
	Scythe = function()
		local blade = rgb(200, 220, 255)
		return upright(0.7, {
			staff(IRON, -4.8, 2.4, 0.25),
			{ U = 0.6, V = -4.7, Size = V3(1.2, 0.26, 0.15), Turn = 10, Color = blade, Glow = true },
			{ U = 1.5, V = -4.45, Size = V3(0.9, 0.22, 0.15), Turn = 30, Color = blade, Glow = true },
			{ U = 2.1, V = -4.0, Size = V3(0.6, 0.2, 0.15), Turn = 55, Color = blade, Glow = true },
		})
	end,
	Sword = function()
		return {
			{ U = 0, V = 0.2, Size = V3(0.25, 0.7, 0.25), Color = rgb(70, 50, 40) },
			{ U = 0, V = 0.6, Size = V3(1.0, 0.18, 0.3), Color = GOLD },
			{ U = 0, V = 2.0, Size = V3(0.32, 2.6, 0.12), Color = rgb(200, 220, 255), Glow = true },
		}
	end,
	Cup = function()
		return upright(0.5, {
			{ U = 0, V = -0.2, Size = V3(0.5, 0.12, 0.5), Color = GOLD },
			{ U = 0, V = -0.45, Size = V3(0.15, 0.4, 0.15), Color = GOLD },
			{ U = 0, V = -0.85, Size = V3(0.7, 0.5, 0.7), Color = GOLD },
			{ U = 0, V = -1.08, Size = V3(0.6, 0.08, 0.6), Color = rgb(255, 214, 120), Glow = true },
		})
	end,
	Apple = function()
		return upright(0.35, {
			{ U = 0, V = 0.45, Size = V3(0.75, 0.75, 0.75), Color = rgb(255, 210, 60), Glow = true, Ball = true },
			{ U = 0.15, V = 0.02, Size = V3(0.3, 0.1, 0.18), Turn = 20, Color = rgb(96, 170, 70) },
		})
	end,
	Scales = function()
		return {
			{ U = 0, V = 0.7, Size = V3(0.12, 1.2, 0.12), Color = GOLD },
			{ U = 0, V = 1.3, Size = V3(2.0, 0.12, 0.12), Color = GOLD },
			{ U = -0.95, V = 1.6, Size = V3(0.05, 0.6, 0.05), Color = GOLD },
			{ U = 0.95, V = 1.6, Size = V3(0.05, 0.6, 0.05), Color = GOLD },
			{ U = -0.95, V = 1.92, Size = V3(0.7, 0.1, 0.7), Color = GOLD, Glow = true },
			{ U = 0.95, V = 1.92, Size = V3(0.7, 0.1, 0.7), Color = GOLD, Glow = true },
		}
	end,
	Sceptre = function()
		return upright(0.6, {
			staff(GOLD, -4.0, 2.0, 0.22),
			{ U = 0, V = -4.6, Size = V3(1.0, 1.0, 0.22), Turn = 45, Color = rgb(36, 190, 176), Glow = true },
			{ U = 0, V = -4.6, Size = V3(0.62, 0.62, 0.3), Turn = 45, Color = rgb(40, 92, 220), Glow = true },
			{ U = 0, V = -4.6, Size = V3(0.28, 0.28, 0.38), Turn = 45, Color = GOLD, Glow = true },
		})
	end,
	Flame = function()
		return upright(0.6, {
			{ U = 0, V = -0.5, Size = V3(0.8, 1.1, 0.8), Color = rgb(255, 120, 30), Glow = true },
			{ U = 0, V = -0.7, Size = V3(0.45, 0.7, 0.45), Color = rgb(255, 220, 90), Glow = true },
		})
	end,
	Wheat = function()
		local blocks: { Block } = {}
		for index = -2, 2 do
			table.insert(
				blocks,
				{ U = index * 0.12, V = -1.3, Size = V3(0.08, 2.4, 0.08), Turn = index * 6, Color = rgb(200, 170, 70) }
			)
			table.insert(blocks, {
				U = index * 0.24,
				V = -2.6,
				Size = V3(0.18, 0.55, 0.18),
				Turn = index * 6,
				Color = rgb(255, 214, 90),
				Glow = true,
			})
		end
		return upright(0.5, blocks)
	end,
	Lyre = function()
		local blocks: { Block } = {
			{ U = 0, V = -0.6, Size = V3(1.0, 0.25, 0.25), Color = GOLD },
			{ U = -0.45, V = -1.4, Size = V3(0.2, 1.6, 0.2), Turn = -12, Color = GOLD },
			{ U = 0.45, V = -1.4, Size = V3(0.2, 1.6, 0.2), Turn = 12, Color = GOLD },
			{ U = 0, V = -2.15, Size = V3(1.3, 0.18, 0.18), Color = GOLD },
		}
		for index = -1, 1 do
			table.insert(
				blocks,
				{ U = index * 0.2, V = -1.35, Size = V3(0.05, 1.4, 0.05), Color = rgb(255, 255, 255), Glow = true }
			)
		end
		return upright(0.6, blocks)
	end,
	Spear = function()
		return upright(0.7, {
			staff(WOOD, -4.9, 2.6, 0.25),
			{ U = 0, V = -5.4, Size = V3(0.45, 1.0, 0.15), Color = rgb(255, 200, 120), Glow = true },
		})
	end,
	DarkSpear = function()
		return upright(0.7, {
			staff(IRON, -4.9, 2.6, 0.25),
			{ U = 0, V = -5.4, Size = V3(0.45, 1.0, 0.15), Color = rgb(220, 50, 50), Glow = true },
		})
	end,
	Thyrsus = function()
		local blocks = { staff(rgb(96, 140, 60), -4.2, 2.2, 0.24) }
		for index, at in
			{ Vector2.new(0, -4.5), Vector2.new(-0.22, -4.3), Vector2.new(0.22, -4.3), Vector2.new(0, -4.15) }
		do
			table.insert(blocks, {
				U = at.X,
				V = at.Y,
				Size = V3(0.36, 0.36, 0.36),
				Color = rgb(150, 70, 200),
				Glow = index == 1,
				Ball = true,
			})
		end
		return upright(0.7, blocks)
	end,
	Pipes = function()
		local blocks: { Block } = {}
		for index = 0, 4 do
			local length = 1.6 - index * 0.22
			table.insert(blocks, {
				U = -0.5 + index * 0.25,
				V = -0.2 + length / 2,
				Size = V3(0.2, length, 0.2),
				Color = rgb(196, 160, 100),
			})
		end
		table.insert(blocks, { U = 0, V = 0.3, Size = V3(1.35, 0.15, 0.25), Color = rgb(96, 160, 70) })
		return upright(0.35, blocks)
	end,
	Cornucopia = function()
		local blocks: { Block } = {}
		for index = 0, 3 do
			local size = 0.3 + index * 0.18
			table.insert(blocks, {
				U = -0.3 + index * 0.25,
				V = -0.2 - index * 0.35,
				Size = V3(size, 0.5, size),
				Turn = -25 + index * 10,
				Color = GOLD,
			})
		end
		for index = 0, 2 do
			table.insert(blocks, {
				U = 0.5 + index * 0.15,
				V = -1.6 - index * 0.12,
				Size = V3(0.3, 0.3, 0.3),
				Color = rgb(255, 226, 90),
				Glow = true,
				Ball = true,
			})
		end
		return upright(0.45, blocks)
	end,
	Rainbow = function()
		local blocks = { staff(rgb(250, 250, 255), -2.4, 0.6, 0.18) }
		local colors = {
			rgb(255, 70, 70),
			rgb(255, 160, 50),
			rgb(255, 230, 70),
			rgb(90, 220, 110),
			rgb(80, 150, 255),
			rgb(170, 100, 240),
		}
		for index, color in colors do
			local angle = math.rad(-90 + (index - 0.5) * 30)
			table.insert(blocks, {
				U = math.cos(angle) * 0.75,
				V = -3.0 + math.sin(angle) * 0.75,
				Size = V3(0.3, 0.45, 0.2),
				Turn = math.deg(angle),
				Color = color,
				Glow = true,
			})
		end
		return upright(0.6, blocks)
	end,
	Wreath = function()
		local blocks: { Block } = {}
		for index = 0, 9 do
			local angle = math.rad(index * 36)
			table.insert(blocks, {
				U = math.cos(angle) * 0.6,
				V = -1.0 + math.sin(angle) * 0.6,
				Size = V3(0.32, 0.18, 0.18),
				Turn = math.deg(angle) + 90,
				Color = if index % 2 == 0 then rgb(96, 170, 70) else GOLD,
				Glow = index % 2 == 1,
			})
		end
		return upright(0.5, blocks)
	end,
	Wind = function()
		local blocks: { Block } = {}
		for index = 0, 6 do
			local angle = math.rad(index * 50)
			local radius = 0.3 + index * 0.12
			table.insert(blocks, {
				U = math.cos(angle) * radius,
				V = -1.2 + math.sin(angle) * radius,
				Size = V3(0.5, 0.14, 0.14),
				Turn = math.deg(angle) + 90,
				Color = rgb(230, 250, 255),
				Glow = true,
			})
		end
		return upright(0.5, blocks)
	end,
	Poppy = function()
		return upright(0.5, {
			{ U = 0, V = -0.8, Size = V3(0.1, 1.6, 0.1), Color = rgb(70, 140, 60) },
			{ U = 0, V = -1.7, Size = V3(0.6, 0.25, 0.6), Color = rgb(230, 50, 50), Glow = true },
			{ U = 0, V = -1.8, Size = V3(0.2, 0.12, 0.2), Color = rgb(30, 20, 30) },
		})
	end,
	StarWand = function()
		local pink = rgb(255, 170, 220)
		return upright(0.6, {
			staff(SILVER, -2.4, 0.6, 0.15),
			{ U = 0, V = -2.75, Size = V3(0.95, 0.25, 0.15), Color = pink, Glow = true },
			{ U = 0, V = -2.75, Size = V3(0.95, 0.25, 0.15), Turn = 60, Color = pink, Glow = true },
			{ U = 0, V = -2.75, Size = V3(0.95, 0.25, 0.15), Turn = 120, Color = pink, Glow = true },
		})
	end,
	Rose = function()
		return upright(0.5, {
			{ U = 0, V = -0.7, Size = V3(0.1, 1.4, 0.1), Color = rgb(70, 140, 60) },
			{ U = 0.15, V = -0.8, Size = V3(0.3, 0.1, 0.16), Turn = 30, Color = rgb(70, 140, 60) },
			{ U = 0, V = -1.55, Size = V3(0.5, 0.5, 0.5), Color = rgb(230, 40, 90), Glow = true, Ball = true },
		})
	end,
}

Props.Kinds = KINDS

-- Builds `kind` into the model's right fist (a no-op for an unknown kind).
function Props.Hold(model: Model, kind: string)
	local make = KINDS[kind]
	local hand = model:FindFirstChild("RightHand")
	if not make or not hand or not hand:IsA("BasePart") then
		return
	end
	local frame = hand.CFrame * CFrame.Angles(math.pi, 0, 0)
	local folder = Instance.new("Model")
	folder.Name = "Symbol"
	for index, block in make() do
		local part = Instance.new("Part")
		part.Name = `{kind}{index}`
		part.Shape = if block.Ball then Enum.PartType.Ball else Enum.PartType.Block
		part.Size = block.Size
		part.CFrame = frame
			* CFrame.new(block.U, block.V, block.Z or 0)
			* CFrame.Angles(0, 0, math.rad(block.Turn or 0))
		part.Color = block.Color
		part.Material = if block.Glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.CastShadow = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = part
		weld.Parent = part
		part.Parent = folder
	end
	folder.Parent = model
end

return table.freeze(Props)
