--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BreedBuilds = require(ReplicatedStorage.Config.BreedBuilds)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Mutations = require(ReplicatedStorage.Utils.Mutations)
local SheepRigLayout = require(ReplicatedStorage.Config.SheepRigLayout)

-- Dresses a sheep cloned from the rig for its breed: body colours, wool style and size, horns, accessory, special
-- effects, then its scale. Wool colours and materials come last and again whenever a mutation lands (Paint).
-- Add-ons are the placeholder models in ServerStorage.Assets.SheepAddons (studio/BuildSheep.luau), placed on a Farm
-- Sheep at the origin and welded on relative to the joint of the piece they sit on, so they stay put when the mesh
-- build swaps a piece's block for a mesh.
export type Kit = {
	Addons: Instance?,
	-- Each rig piece's joint frame and block at rest, in model space (SheepRigLayout).
	Pivots: { [string]: CFrame },
	Rests: { [string]: CFrame },
}

local Settings = GameConfig.Sheep

local FACE_PIECES = { "Head", "EarL", "EarR" }
local LEG_PIECES = { "LegFL", "LegFR", "LegBL", "LegBR" }
local SKIN_PIECES = { "Body" }
-- The tail is woolly: in the skin colour it poked out of a full fleece like a bald spot.
local WOOL_PIECES = { "Tail" }

local Looks = {}

function Looks.new(addons: Instance?): Kit
	local pivots: { [string]: CFrame } = {}
	local rests: { [string]: CFrame } = {}
	for _, piece in SheepRigLayout.Pieces do
		pivots[piece.Name] = piece.Pivot
		rests[piece.Name] = piece.CFrame
	end
	return { Addons = addons, Pivots = pivots, Rests = rests }
end

local function paintPieces(model: Model, names: { string }, color: Color3)
	for _, name in names do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end
end

-- The weld offset from `piece` to a block at `cframe` in model space. It goes through the piece's own joint, so it
-- holds whatever shape the piece's block or mesh has.
local function offsetFrom(kit: Kit, piece: BasePart, cframe: CFrame): CFrame
	local pivot = kit.Pivots[piece.Name]
	local joint = piece:FindFirstChild(piece.Name)
	if pivot and joint and joint:IsA("JointInstance") then
		return joint.C1 * pivot:ToObjectSpace(cframe)
	end
	return (kit.Rests[piece.Name] or CFrame.identity):ToObjectSpace(cframe)
end

-- A puff and every block hanging off it (a ringlet's lower balls).
local function blocksOf(puff: BasePart): { BasePart }
	local blocks = { puff }
	for _, descendant in puff:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(blocks, descendant)
		end
	end
	return blocks
end

local function weldTo(kit: Kit, model: Model, part: BasePart, template: BasePart): boolean
	local pieceName = template:GetAttribute("Piece")
	local piece = if type(pieceName) == "string" then model:FindFirstChild(pieceName) else nil
	if not piece or not piece:IsA("BasePart") then
		return false
	end
	local joint = Instance.new("Weld")
	joint.Name = "Weld"
	joint.Part0 = piece
	joint.Part1 = part
	joint.C0 = offsetFrom(kit, piece, template.CFrame)
	joint.Parent = part
	part.CFrame = piece.CFrame * joint.C0
	return true
end

-- A horn's stripes: darker on a light horn, lighter on a dark one (art/sheep/mock_fluffy.py's bands).
local function hornBand(color: Color3): Color3
	local r, g, b = color.R * 255, color.G * 255, color.B * 255
	if r + g + b > 380 then
		return Color3.fromRGB(r * 0.8, g * 0.8, b * 0.8)
	end
	return Color3.fromRGB(math.min(255, r * 1.5 + 20), math.min(255, g * 1.5 + 20), math.min(255, b * 1.5 + 20))
end

-- A part's colour from its Tint; "Own" (a breed build's lava, lightning, ice) and untinted parts keep their template's.
local function tint(part: BasePart, breed: GameConfig.Breed)
	local tag = part:GetAttribute("Tint")
	if tag == "Horn" then
		part.Color = breed.HornColor
	elseif tag == "HornBand" then
		part.Color = hornBand(breed.HornColor)
	elseif tag == "Face" then
		part.Color = breed.FaceColor
	elseif tag == "Wool" then
		part.Color = breed.WoolColor
	elseif tag == "Spot" then
		part.Color = breed.WoolSpotColor or breed.WoolColor
	end
end

local function findAddon(kit: Kit, name: string): Instance?
	local addon = if kit.Addons then kit.Addons:FindFirstChild(name) else nil
	if not addon then
		warn(`[SheepService] ServerStorage.Assets.SheepAddons.{name} is missing: run studio/BuildSheep.luau in Edit`)
	end
	return addon
end

-- Welds a copy of every block of an add-on onto the sheep.
local function attach(kit: Kit, model: Model, breed: GameConfig.Breed, name: string)
	local addon = findAddon(kit, name)
	if not addon then
		return
	end
	local folder = model:FindFirstChild("Addons")
	if not folder then
		local created = Instance.new("Folder")
		created.Name = "Addons"
		created.Parent = model
		folder = created
	end
	for _, descendant in addon:GetDescendants() do
		if descendant:IsA("BasePart") then
			local part = descendant:Clone()
			if weldTo(kit, model, part, descendant) then
				tint(part, breed)
				part.Parent = folder
			else
				part:Destroy()
			end
		end
	end
	local spec = SheepRigLayout.Addons[name]
	local hides: { string } = if spec and spec.Hides then spec.Hides else {}
	for _, pieceName in hides do
		local piece = model:FindFirstChild(pieceName)
		if piece and piece:IsA("BasePart") then
			piece.Transparency = 1
			piece.CanQuery = false
			-- A hidden head's face pictures go too (a Decal shows on an invisible part).
			for _, child in piece:GetChildren() do
				if child:IsA("Decal") then
					child.Transparency = 1
				end
			end
		end
	end
end

-- Swaps the rig's round puffs for a wool style's pieces, which keep the puffs' names so shearing still finds them.
local function restyle(kit: Kit, model: Model, style: string)
	local addon = findAddon(kit, style)
	local woolFolder = model:FindFirstChild("Wool")
	if not addon or not woolFolder then
		return
	end
	for _, name in SheepRigLayout.WoolOrder do
		local replacement = addon:FindFirstChild(name)
		local old = woolFolder:FindFirstChild(name)
		if not replacement or not replacement:IsA("BasePart") or not old then
			continue
		end
		local puff = replacement:Clone()
		if weldTo(kit, model, puff, replacement) then
			old:Destroy()
			puff.Parent = woolFolder
		else
			puff:Destroy()
		end
	end
end

-- Grows the wool for the breed: every block of a puff by WoolSize, and each puff pushed out sideways and up from the
-- piece it sits on. Its front stays where it was, so bigger wool grows back, up and out instead of over the face.
-- The model still stands at the origin facing -Z.
local function sizeWool(model: Model, woolSize: number)
	local woolFolder = model:FindFirstChild("Wool")
	if not woolFolder or woolSize == 1 then
		return
	end
	local spread = 1 + (woolSize - 1) * Settings.WoolSpread
	for _, puff in woolFolder:GetChildren() do
		local weld = puff:FindFirstChild("Weld")
		local host = if weld and weld:IsA("Weld") then weld.Part0 else nil
		if not puff:IsA("BasePart") or not weld or not weld:IsA("Weld") or not host then
			continue
		end
		local rest = puff.CFrame
		local grown = puff.Size * woolSize
		local out = (rest.Position - host.Position) * spread
		local centre = host.Position + Vector3.new(out.X, out.Y, rest.Z - host.Position.Z + (grown.Z - puff.Size.Z) / 2)
		puff.Size = grown
		weld.C0 = host.CFrame:ToObjectSpace(CFrame.new(centre) * rest.Rotation)
		weld.C1 = CFrame.identity
		-- Blocks hanging off the puff (a placeholder ringlet's balls) grow with it.
		for _, part in blocksOf(puff) do
			local joint = part:FindFirstChild("Weld")
			if part ~= puff and joint and joint:IsA("Weld") then
				part.Size *= woolSize
				joint.C0 = CFrame.new(joint.C0.Position * woolSize) * joint.C0.Rotation
			end
		end
	end
end

-- Moves each ear to where `placeName` hangs it (SheepRigLayout.EarPlaces), from the Level its mesh was built in, by
-- turning the ear's joint: its animations still bend it, from there.
local function placeEars(model: Model, placeName: string)
	local head = model:FindFirstChild("Head")
	local from, to = SheepRigLayout.EarPlaces.Level, SheepRigLayout.EarPlaces[placeName]
	if not head or not head:IsA("BasePart") or not to then
		return
	end
	local rad = math.rad
	for _, side in { { Name = "EarL", Sign = -1 }, { Name = "EarR", Sign = 1 } } do
		local ear = model:FindFirstChild(side.Name)
		local joint = if ear then ear:FindFirstChild(side.Name) else nil
		if not joint or not joint:IsA("Motor6D") then
			continue
		end
		local sign = side.Sign
		local root = SheepRigLayout.EarRoot * Vector3.new(sign, 1, 1)
		local turnFrom = CFrame.Angles(0, rad(-from.Sweep * sign), rad(-from.Droop * sign))
		local turnTo = CFrame.Angles(0, rad(-to.Sweep * sign), rad(-to.Droop * sign))
		local rootTo = root + Vector3.new(0, to.Lift, to.Back)
		local frame = model:GetPivot() * CFrame.new(rootTo) * turnTo * turnFrom:Inverse()
		joint.C0 = (head :: BasePart).CFrame:ToObjectSpace(frame)
	end
end

-- Re-poses the rig pieces a breed's build moves (Build.Rig, model space at scale 1: the Wolf in Sheep's Clothing's
-- small head on top of its wolf's, the Humanoid's arms and legs, the Long Sheep's back legs), before its wool and
-- extras are welded on: each piece to its centre and size, its joint to its pivot, so animations bend it from there.
-- Returns the kit the welds go through, with the moved pivots and rests.
local function poseRig(kit: Kit, model: Model, rig: { [string]: BreedBuilds.RigPlace }): Kit
	local pivots = table.clone(kit.Pivots)
	local rests = table.clone(kit.Rests)
	for pieceName, place in rig do
		local part = model:FindFirstChild(pieceName)
		local joint = if part then part:FindFirstChild(pieceName) else nil
		if not part or not part:IsA("BasePart") or not joint or not joint:IsA("Motor6D") or not joint.Part0 then
			continue
		end
		local rest = rests[pieceName] or CFrame.identity
		local center = place.Center or rest.Position
		local pivot = place.Pivot or (pivots[pieceName] or rest).Position
		if place.Size then
			part.Size = place.Size
		end
		local parentRest = rests[(joint.Part0 :: BasePart).Name] or CFrame.identity
		joint.C0 = parentRest:Inverse() * CFrame.new(pivot)
		joint.C1 = CFrame.new(pivot - center)
		pivots[pieceName] = CFrame.new(pivot)
		rests[pieceName] = CFrame.new(center)
	end
	return { Addons = kit.Addons, Pivots = pivots, Rests = rests }
end

-- Floats the whole sheep `lift` studs over where it stands (a breed build's Lift, at scale 1): the Body joint carries
-- every piece, legs included, so the feet leave the ground and animations still bend each joint from there.
local function liftBody(model: Model, lift: number)
	local body = model:FindFirstChild("Body")
	local joint = if body then body:FindFirstChild("Body") else nil
	if lift ~= 0 and joint and joint:IsA("Motor6D") then
		joint.C0 += Vector3.new(0, lift, 0)
	end
end

local function light(parent: Instance, color: Color3, brightness: number, range: number)
	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Brightness = brightness
	glow.Range = range
	glow.Shadows = false
	glow.Parent = parent
end

local function particles(parent: Instance, color: Color3, rate: number, size: number, speed: number, life: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Effect"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(life * 0.7, life)
	emitter.Speed = NumberRange.new(speed * 0.6, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = parent
end

-- Lights and particles on the FX attachment, plus any blocks the effect has (Lava's glowing stripes).
local function addEffect(kit: Kit, model: Model, breed: GameConfig.Breed, effect: string)
	local body = model:FindFirstChild("Body")
	local fx = body and body:FindFirstChild("FX")
	if not fx then
		return
	end
	if effect == "LavaGlow" then
		attach(kit, model, breed, "LavaGlow")
		light(fx, Color3.fromRGB(255, 130, 40), 2, 9)
	elseif effect == "LavaLight" then
		light(fx, Color3.fromRGB(255, 130, 40), 2, 9)
	elseif effect == "StormSparks" then
		particles(fx, Color3.fromRGB(255, 232, 90), 6, 0.45, 5, 0.5)
	elseif effect == "Stars" then
		particles(fx, Color3.fromRGB(255, 250, 220), 4, 0.35, 1.5, 1.6)
	elseif effect == "Sparkles" then
		particles(fx, Color3.fromRGB(255, 190, 235), 5, 0.4, 2, 1.2)
	elseif effect == "MoonGlow" then
		light(fx, Color3.fromRGB(235, 240, 255), 0.8, 8)
	elseif effect == "Spores" then
		particles(fx, Color3.fromRGB(214, 236, 120), 3, 0.22, 0.6, 2.4)
	elseif effect == "Wisps" then
		particles(fx, Color3.fromRGB(255, 196, 228), 3, 0.45, 0.8, 1.6)
	end
end

-- Everything about a breed's look except the wool's colour: call Paint afterwards.
function Looks.Dress(kit: Kit, model: Model, breed: GameConfig.Breed)
	paintPieces(model, SKIN_PIECES, breed.SkinColor)
	for _, name in SKIN_PIECES do
		local skin = model:FindFirstChild(name)
		if skin and skin:IsA("BasePart") then
			skin.Material = breed.SkinMaterial
			skin.Reflectance = 0
		end
	end
	paintPieces(model, WOOL_PIECES, breed.WoolColor)
	paintPieces(model, FACE_PIECES, breed.FaceColor)
	paintPieces(model, LEG_PIECES, breed.LegColor)
	-- Its own face picture; each device swaps it for expressions (SheepController/Faces).
	local head = model:FindFirstChild("Head")
	local face = if head then head:FindFirstChild("Face") else nil
	if face and face:IsA("Decal") then
		face.Texture = Settings.Faces[breed.Face] or Settings.Faces.Idle
		local overlayName = breed.FaceOverlay
		if overlayName and Settings.Faces[overlayName] then
			-- Laid over whatever face it makes (an eyepatch, stitches), so expression swaps never touch it.
			local overlay = face:Clone()
			overlay.Name = "FaceOverlay"
			overlay.Texture = Settings.Faces[overlayName]
			overlay.ZIndex = face.ZIndex + 1
			overlay.Parent = head
		end
	end
	for _, detail in SheepRigLayout.Details do
		local color = if detail.Tint == "EarInner" and breed.EarInnerColor
			then breed.EarInnerColor
			else Settings.DetailColors[detail.Tint]
		paintPieces(model, { detail.Name }, color)
	end
	local build = if breed.Build then BreedBuilds.Builds[breed.Build] else nil
	if build and build.Rig then
		kit = poseRig(kit, model, build.Rig)
	end
	if build then
		restyle(kit, model, `{breed.Build}Wool`)
	elseif breed.WoolStyle ~= "Puffs" then
		restyle(kit, model, breed.WoolStyle)
	end
	sizeWool(model, breed.WoolSize)
	if breed.HornStyle then
		attach(kit, model, breed, breed.HornStyle)
		placeEars(model, "Back")
	end
	if breed.Accessory then
		attach(kit, model, breed, breed.Accessory)
	end
	if build then
		attach(kit, model, breed, `{breed.Build}Extras`)
		liftBody(model, build.Lift)
		if build.EarPlace ~= "Level" and not breed.HornStyle then
			placeEars(model, build.EarPlace)
		end
	end
	if breed.SpecialFX then
		addEffect(kit, model, breed, breed.SpecialFX)
	end
	if breed.Scale ~= 1 then
		model:ScaleTo(breed.Scale)
	end
end

-- How far a breed's body floats over where it stands at `scale` (its own by default): its build's Lift, 0 for most.
function Looks.Lift(breed: GameConfig.Breed, scale: number?): number
	local build = if breed.Build then BreedBuilds.Builds[breed.Build] else nil
	return if build then build.Lift * (scale or breed.Scale) else 0
end

-- Colours the wool for the breed, or for its mutation, which replaces the breed's wool colour and material (spots
-- included, and a build's own colours, materials and patterns) but keeps its wool style, horns and effects.
function Looks.Paint(model: Model, breed: GameConfig.Breed, mutationId: string?)
	local woolFolder = model:FindFirstChild("Wool")
	if not woolFolder then
		return
	end
	local mutation = Mutations.Get(mutationId)
	local count = #SheepRigLayout.WoolOrder
	for order, name in SheepRigLayout.WoolOrder do
		local puff = woolFolder:FindFirstChild(name)
		if not puff or not puff:IsA("BasePart") then
			continue
		end
		local color = breed.WoolColor
		local material = breed.WoolMaterial
		if mutation then
			color = Mutations.PuffColor(mutation, order, count)
			material = mutation.Material
		end
		-- A Spotted style's patches take the breed's second colour, unless a mutation repaints them with the rest.
		local spot = if mutation then color else breed.WoolSpotColor or color
		for _, part in blocksOf(puff) do
			local tag = part:GetAttribute("Tint")
			if tag == "Own" and not mutation then
				continue
			end
			part.Color = if tag == "Spot" then spot else color
			part.Material = material
			if mutation and part:IsA("MeshPart") then
				part.TextureID = ""
			end
		end
	end
end

return table.freeze(Looks)
