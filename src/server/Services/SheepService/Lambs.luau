--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local LambLook = require(ReplicatedStorage.Utils.LambLook)
local Looks = require(script.Parent.Looks)

-- The plain lambs every lamb is marked on (Utils/LambLook): Shear a Sheep's rig in the lamb's look
-- (GameConfig.LambBreed) with its fleece taken off, the head sat back against the bare body on a round neck, and the
-- horns, for the families that grow them, shrunk to buds. SheepService makes one without horns and one per horn style.
local Lambs = {}

local Settings = GameConfig.Sheep.Lamb

-- With no fleece over them, the head moves this far back and down onto the body, and the tail this far forward.
local HEAD_SHIFT = Vector3.new(0, -0.06, 0.18)
local TAIL_SHIFT = Vector3.new(0, 0, -0.06)
-- The neck that fills the gap under the head: its box and where it sits, at the rig's size.
local NECK_SIZE = Vector3.new(0.78, 0.72, 0.8)
local NECK_AT = CFrame.new(0, 1.52, -0.62) * CFrame.Angles(math.rad(-30), 0, 0)

-- Each side's horn pieces shrink by `factor` towards the piece nearest the head, so the buds stay on it.
local function budHorns(model: Model, factor: number)
	local head = model:FindFirstChild("Head")
	local addons = model:FindFirstChild("Addons")
	if not head or not head:IsA("BasePart") or not addons then
		return
	end
	for _, side in { -1, 1 } do
		local parts: { BasePart } = {}
		for _, descendant in addons:GetDescendants() do
			local tint = descendant:GetAttribute("Tint")
			if descendant:IsA("BasePart") and (tint == "Horn" or tint == "HornBand") then
				local across = head.CFrame:PointToObjectSpace(descendant.Position).X
				if (across >= 0) == (side > 0) then
					table.insert(parts, descendant)
				end
			end
		end
		local anchor: Vector3? = nil
		local nearest = math.huge
		for _, part in parts do
			local gap = (part.Position - head.Position).Magnitude
			if gap < nearest then
				nearest = gap
				anchor = part.Position
			end
		end
		if not anchor then
			continue
		end
		for _, part in parts do
			local at = anchor + (part.Position - anchor) * factor
			part.Size *= factor
			part.CFrame = CFrame.new(at) * part.CFrame.Rotation
			local weld = part:FindFirstChildOfClass("Weld")
			if weld and weld.Part0 then
				weld.C0 = weld.Part0.CFrame:ToObjectSpace(part.CFrame)
				weld.C1 = CFrame.identity
			end
		end
	end
end

local function shiftJoint(model: Model, pieceName: string, by: Vector3)
	local piece = model:FindFirstChild(pieceName)
	local joint = piece and piece:FindFirstChild(pieceName)
	if joint and joint:IsA("Motor6D") then
		joint.C0 += by
	end
end

-- The plain lamb with `horns` (or none), at the rig's size standing at the origin, named LambLook.TemplateName.
function Lambs.Template(kit: Looks.Kit, rig: Model, horns: GameConfig.HornStyle?): Model
	local model = rig:Clone()
	model:PivotTo(CFrame.identity)
	local breed = table.clone(GameConfig.LambBreed)
	breed.Scale = 1
	breed.HornStyle = horns
	Looks.Dress(kit, model, breed)
	local wool = model:FindFirstChild("Wool")
	if wool then
		wool:Destroy()
	end
	budHorns(model, Settings.HornBud)
	shiftJoint(model, "Head", HEAD_SHIFT)
	shiftJoint(model, "Tail", TAIL_SHIFT)
	local body = model:FindFirstChild("Body")
	if body and body:IsA("BasePart") then
		local neck = Instance.new("Part")
		neck.Name = "Neck"
		neck.Size = NECK_SIZE
		neck.CFrame = NECK_AT
		neck.Color = breed.SkinColor
		neck.Material = breed.SkinMaterial
		local round = Instance.new("SpecialMesh")
		round.MeshType = Enum.MeshType.Sphere
		round.Parent = neck
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = neck
		weld.Parent = neck
		neck.Parent = model
	end
	model.Name = LambLook.TemplateName(horns)
	return model
end

return table.freeze(Lambs)
