--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Theme = require(ReplicatedStorage.Config.Theme)

-- Shear a Sheep's sheep token (UIKit.Token) in a family's colours: its wool, face and legs, horns for the horned ones,
-- gold wool and sparkles for a Royal fleece, blue sparkles for a Rare one, a dark "?" while undiscovered.
local SheepIcon = {}

local UNKNOWN = Color3.fromRGB(70, 78, 98)
local GOLD = Color3.fromRGB(255, 196, 40)

local function layer(token: Instance, name: string): ImageLabel?
	local found = token:FindFirstChild(name)
	return if found and found:IsA("ImageLabel") then found else nil
end

local function isDark(color: Color3): boolean
	return color.R * 0.299 + color.G * 0.587 + color.B * 0.114 < 0.45
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
	local wool = if unknown then UNKNOWN elseif mutation then mutation.Color else breed.WoolColor
	local face = if unknown then UNKNOWN else breed.FaceColor
	local legs = if unknown then UNKNOWN else breed.LegColor
	local function paint(name: string, color: Color3?, visible: boolean?)
		local image = layer(token, name)
		if image then
			image.Visible = visible ~= false
			image.ImageColor3 = color or Color3.new(1, 1, 1)
		end
	end
	paint("Legs", legs)
	paint("Wool", wool)
	paint("Tuft", wool)
	paint("Shine", nil, not unknown)
	paint("Spots", breed.WoolSpotColor, breed.WoolSpotColor ~= nil and mutation == nil and not unknown)
	paint("Horns", breed.HornColor, breed.HornStyle ~= nil and not unknown)
	paint("Antennae", face, false)
	paint("Face", face)
	local features = layer(token, "Features")
	if features then
		features.Image = if isDark(face) then Theme.Icons.TokenFeaturesDark else Theme.Icons.TokenFeatures
		features.Visible = not unknown
	end
	local mystery = token:FindFirstChild("Mystery")
	if mystery and mystery:IsA("GuiObject") then
		mystery.Visible = unknown == true
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

-- The card colour for a fleece rarity (Theme.Fleece.Rarity's names).
function SheepIcon.RarityLook(rarity: number): string
	return if rarity >= 3 then "Legendary" elseif rarity == 2 then "Rare" else "Common"
end

return table.freeze(SheepIcon)
