--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local LambLook = require(ReplicatedStorage.Utils.LambLook)
local Theme = require(ReplicatedStorage.Config.Theme)

-- Shear a Sheep's sheep token (UIKit.Token) in a family's colours: its wool, face and legs, horns for the horned ones,
-- gold wool and sparkles for a Royal fleece, blue sparkles for a Rare one, a dark "?" while undiscovered. A lamb's
-- token is the lamb's white with its spots' colour, whatever it'll grow into.
local SheepIcon = {}

local UNKNOWN = Color3.fromRGB(70, 78, 98)
local GOLD = Color3.fromRGB(255, 196, 40)

type Colors = {
	Wool: Color3,
	Face: Color3,
	Legs: Color3,
	Spots: Color3?,
	Horns: Color3?,
}

local function layer(token: Instance, name: string): ImageLabel?
	local found = token:FindFirstChild(name)
	return if found and found:IsA("ImageLabel") then found else nil
end

local function isDark(color: Color3): boolean
	return color.R * 0.299 + color.G * 0.587 + color.B * 0.114 < 0.45
end

local function paintLayers(token: Instance, colors: Colors, fleece: number, unknown: boolean)
	local function paint(name: string, color: Color3?, visible: boolean?)
		local image = layer(token, name)
		if image then
			image.Visible = visible ~= false
			image.ImageColor3 = color or Color3.new(1, 1, 1)
		end
	end
	paint("Legs", colors.Legs)
	paint("Wool", colors.Wool)
	paint("Tuft", colors.Wool)
	paint("Shine", nil, not unknown)
	paint("Spots", colors.Spots, colors.Spots ~= nil and not unknown)
	paint("Horns", colors.Horns, colors.Horns ~= nil and not unknown)
	paint("Antennae", colors.Face, false)
	paint("Face", colors.Face)
	local features = layer(token, "Features")
	if features then
		features.Image = if isDark(colors.Face) then Theme.Icons.TokenFeaturesDark else Theme.Icons.TokenFeatures
		features.Visible = not unknown
	end
	local mystery = token:FindFirstChild("Mystery")
	if mystery and mystery:IsA("GuiObject") then
		mystery.Visible = unknown
	end
	for _, name in { "Sparkle1", "Sparkle2" } do
		local sparkle = token:FindFirstChild(name)
		if sparkle and sparkle:IsA("GuiObject") then
			sparkle.Visible = fleece >= 2 and not unknown
			local fill = sparkle:FindFirstChild("Fill")
			if fill and fill:IsA("ImageLabel") then
				fill.ImageColor3 = if fleece >= 3 then GOLD else Color3.fromRGB(150, 210, 255)
			end
		end
	end
end

function SheepIcon.Paint(token: Instance, family: string, rarity: number?, unknown: boolean?)
	local breed = GameConfig.Breeds[family]
	if not breed then
		return
	end
	local fleece = rarity or 1
	local mutation = if fleece >= 3
		then GameConfig.Mutations.Gold
		elseif breed.Mutation then GameConfig.Mutations[breed.Mutation]
		else nil
	local hidden = unknown == true
	paintLayers(token, {
		Wool = if hidden then UNKNOWN elseif mutation then mutation.Color else breed.WoolColor,
		Face = if hidden then UNKNOWN else breed.FaceColor,
		Legs = if hidden then UNKNOWN else breed.LegColor,
		Spots = if mutation == nil then breed.WoolSpotColor else nil,
		Horns = if breed.HornStyle then breed.HornColor else nil,
	}, fleece, hidden)
end

-- A lamb's token: the lamb's white, its spots in its marks' colour (`look`; plain without), and its fleece's sparkle.
function SheepIcon.PaintLamb(token: Instance, look: LambLook.Look?, rarity: number?)
	local lamb = GameConfig.LambBreed
	paintLayers(token, {
		Wool = lamb.WoolColor,
		Face = lamb.FaceColor,
		Legs = lamb.LegColor,
		Spots = if look then look.Color else nil,
	}, rarity or 1, false)
end

-- The card colour for a fleece rarity (Theme.Fleece.Rarity's names).
function SheepIcon.RarityLook(rarity: number): string
	return if rarity >= 3 then "Legendary" elseif rarity == 2 then "Rare" else "Common"
end

-- The card colour for a family: its rarity in its god's herd (Common to Mythic, Theme.Fleece.Rarity's names). A lamb,
-- whose family is a secret, is Common's.
function SheepIcon.FamilyLook(family: string?): string
	return Economy.FamilyRarities[if family then Economy.FamilyRarity(family) else 1].Name
end

return table.freeze(SheepIcon)
