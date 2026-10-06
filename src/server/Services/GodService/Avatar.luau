--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Olympus = require(ReplicatedStorage.Config.Olympus)
local Looks = require(script.Parent.Looks)
local Props = require(script.Parent.Props)
local Rig = require(script.Parent.Rig)

-- A god as a Roblox avatar (the user's pick, 2026-10-05): the classic angry face, catalog hair, crowns and robes
-- (Looks), a big head for the cute Roblox look, scaled up to tower over the players, and its symbol in its fist
-- (Props). Roblox fetches the catalog items when the god is made, so Build yields; a god whose items won't load comes
-- back nil and GodService builds its block figure (Rig) instead.
local Avatar = {}

Avatar.Scale = 1.65 -- 9.6 studs tall, as the block figures were
Avatar.HeadScale = 1.3 -- times the body's scale

local RIGID: { [string]: Enum.AccessoryType } = {
	Hair = Enum.AccessoryType.Hair,
	Hat = Enum.AccessoryType.Hat,
	Face = Enum.AccessoryType.Face,
	Neck = Enum.AccessoryType.Neck,
	Shoulder = Enum.AccessoryType.Shoulder,
	Front = Enum.AccessoryType.Front,
	Back = Enum.AccessoryType.Back,
	Waist = Enum.AccessoryType.Waist,
}
local LAYERED: { [string]: Enum.AccessoryType } = {
	TShirt = Enum.AccessoryType.TShirt,
	Shirt = Enum.AccessoryType.Shirt,
	Pants = Enum.AccessoryType.Pants,
	Jacket = Enum.AccessoryType.Jacket,
	Sweater = Enum.AccessoryType.Sweater,
	Shorts = Enum.AccessoryType.Shorts,
	DressSkirt = Enum.AccessoryType.DressSkirt,
	LeftShoe = Enum.AccessoryType.LeftShoe,
	RightShoe = Enum.AccessoryType.RightShoe,
}

local function description(tier: Olympus.Tier, look: Looks.Look): HumanoidDescription
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = tier.Skin
	desc.TorsoColor = look.Torso or tier.Skin
	desc.LeftArmColor = tier.Skin
	desc.RightArmColor = tier.Skin
	desc.LeftLegColor = look.Legs or tier.Skin
	desc.RightLegColor = look.Legs or tier.Skin
	desc.Head = look.Head
	local list = {}
	for order, item in look.Accessories do
		local rigid = RIGID[item.Type]
		local layered = LAYERED[item.Type]
		if rigid then
			table.insert(list, { AssetId = item.Id, AccessoryType = rigid, IsLayered = false })
		elseif layered then
			table.insert(list, { AssetId = item.Id, AccessoryType = layered, IsLayered = true, Order = order })
		end
	end
	desc:SetAccessories(list, true)
	desc.Shirt = look.Shirt or 0
	desc.Pants = look.Pants or 0
	desc.HeightScale = Avatar.Scale
	desc.WidthScale = Avatar.Scale
	desc.DepthScale = Avatar.Scale
	desc.HeadScale = Avatar.Scale * Avatar.HeadScale
	return desc
end

-- The god's model and how high its root's centre stands above its feet, or nil when Roblox couldn't make it.
function Avatar.Build(tier: Olympus.Tier): (Model?, number)
	local look = Looks[tier.God]
	if not look then
		return nil, 0
	end
	local ok, result =
		pcall(Players.CreateHumanoidModelFromDescription, Players, description(tier, look), Enum.HumanoidRigType.R15)
	if not ok or typeof(result) ~= "Instance" or not result:IsA("Model") then
		warn(`[GodService] {tier.God}'s avatar didn't load ({result}); using the block figure`)
		return nil, 0
	end
	local model = result
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model.PrimaryPart
	local head = model:FindFirstChild("Head")
	if not humanoid or not root or not head or not head:IsA("BasePart") then
		model:Destroy()
		return nil, 0
	end
	model.Name = tier.God
	-- GodService moves it by its root's constraints: the Humanoid only carries the animations, with no state machine
	-- of its own, no name and no health bar.
	humanoid.EvaluateStateMachine = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = humanoid
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = part ~= root
		end
	end
	Rig.Nameplate(head, tier)
	if look.Prop then
		Props.Hold(model, look.Prop)
	end
	model:SetAttribute("Raise", look.Raise == true)
	return model, humanoid.HipHeight + root.Size.Y / 2
end

return table.freeze(Avatar)
