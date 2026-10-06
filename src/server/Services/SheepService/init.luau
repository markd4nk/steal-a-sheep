--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CarryPose = require(ReplicatedStorage.Utils.CarryPose)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Extras = require(script.Extras)
local Looks = require(script.Looks)

-- Makes sheep models: Shear a Sheep's rig (ServerStorage.Assets.SheepRig, its meshes and add-ons in
-- ServerStorage.Assets.SheepAddons) dressed as a family's breed by Looks, with the family's primitive extra, its fleece
-- rarity's paint and sparkle, at a size. Also lifts them onto a carrier's head and puts them down. Every sheep is
-- tagged "Sheep" for the clients' idle animation and never collides with anything.
local SheepService = { Name = "SheepService" }

local SHEEP_TAG = "Sheep"
local CARRY_WELD = "CarryWeld"
local LOOKS_FOLDER = "SheepLooks"

local template: Model? = nil
local kit: Looks.Kit? = nil

local function settle(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end
	local root = model.PrimaryPart
	if root then
		root.Anchored = true
	end
end

local function sparkle(model: Model, color: Color3, rate: number)
	local body = model:FindFirstChild("Body")
	local fx = body and body:FindFirstChild("FX")
	local parent: Instance? = fx or body
	if not parent then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Fleece"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(0.6, 1)
	emitter.Speed = NumberRange.new(1, 2.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = parent
end

function SheepService.Init(_self: any, _systems: Lifecycle.Registry) end

function SheepService.Start(_self: any)
	local assets = ServerStorage:FindFirstChild("Assets")
	local rig = assets and assets:FindFirstChild("SheepRig")
	if not rig or not rig:IsA("Model") or not rig.PrimaryPart then
		warn("[SheepService] ServerStorage.Assets.SheepRig is missing: rebuild the place with tools/assemble.luau")
		return
	end
	rig:PivotTo(CFrame.identity)
	template = rig
	kit = Looks.new(assets and assets:FindFirstChild("SheepAddons"))
	-- One plain adult of each family for the clients (menus' 3D previews).
	local folder = Instance.new("Folder")
	folder.Name = LOOKS_FOLDER
	for family in GameConfig.Breeds do
		local model = SheepService:Build(family, 1, 1)
		if model then
			model.Name = family
			CollectionService:RemoveTag(model, SHEEP_TAG)
			model.Parent = folder
		end
	end
	folder.Parent = ReplicatedStorage
end

function SheepService.Destroy(_self: any) end

function SheepService.IsReady(_self: any): boolean
	return template ~= nil
end

-- A sheep of `family` in fleece `rarity` (1 Plain, 2 Shiny, 3 Royal) at `scale` times its rig's size, at the origin.
function SheepService.Build(_self: any, family: string, rarity: number, scale: number): Model?
	local base = GameConfig.Breeds[family]
	if not template or not kit or not base then
		return nil
	end
	local model = template:Clone()
	model.Name = family
	-- Dressed at the rig's own size, so the extras are placed in its space; scaled once at the end.
	local breed = table.clone(base)
	breed.Scale = 1
	Looks.Dress(kit, model, breed)
	local paint = if rarity >= 3 then "Gold" else base.Mutation
	Looks.Paint(model, breed, paint)
	if base.Extra then
		Extras.Add(model, base.Extra)
	end
	if base.Extras then
		for _, extra in base.Extras do
			Extras.Add(model, extra.Kind, extra.Color)
		end
	end
	if rarity == 2 then
		sparkle(model, Color3.fromRGB(140, 200, 255), 4)
	elseif rarity >= 3 then
		sparkle(model, Color3.fromRGB(255, 214, 90), 8)
	end
	settle(model)
	if math.abs(scale - 1) > 1e-3 then
		model:ScaleTo(scale)
	end
	model:SetAttribute("Family", family)
	model:SetAttribute("Rarity", rarity)
	CollectionService:AddTag(model, SHEEP_TAG)
	return model
end

-- Welds the sheep over `character`'s head in their raised hands (CarryPose), as Shear a Sheep carries.
function SheepService.Carry(_self: any, model: Model, character: Model): boolean
	local root = model.PrimaryPart
	local characterRoot = character:FindFirstChild("HumanoidRootPart")
	local family = model:GetAttribute("Family")
	local base = if type(family) == "string" then GameConfig.Breeds[family] else nil
	if not root or not characterRoot or not characterRoot:IsA("BasePart") or not base then
		return false
	end
	local breed = table.clone(base)
	breed.Scale = model:GetScale() * GameConfig.SheepSize
	local holder, at = CarryPose.HoldSpot(character, characterRoot, breed)
	local old = root:FindFirstChild(CARRY_WELD)
	if old then
		old:Destroy()
	end
	root.Anchored = false
	root.Massless = true
	local joint = Instance.new("Weld")
	joint.Name = CARRY_WELD
	joint.Part0 = holder
	joint.Part1 = root
	joint.C0 = at * root.PivotOffset:Inverse()
	joint.Parent = root
	model:PivotTo(holder.CFrame * at)
	model:SetAttribute("State", "Carried")
	return true
end

-- Takes it off whoever held it and stands it at `at` (its feet's centre).
function SheepService.Place(_self: any, model: Model, at: CFrame)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local joint = root:FindFirstChild(CARRY_WELD)
	if joint then
		joint:Destroy()
	end
	root.Anchored = true
	model:PivotTo(at)
	model:SetAttribute("State", nil)
end

return SheepService
