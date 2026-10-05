--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)

type Sheep = Economy.Sheep

-- The sheep standing on a plot's pen pads: one model per equipped sheep, rebuilt when it grows a size, with a small
-- label over it (its income, and a lamb's growth). Plain functions over FlockService's per-player models.
local Pens = {}

export type Shown = {
	Model: Model,
	Scale: number,
	Adult: boolean,
	Label: TextLabel,
}

-- Lambs grow from their weight's size to this share of a Standard adult before their size shows.
local LAMB_GROWN_SHARE = 0.85

function Pens.Scale(sheep: Sheep): number
	if Economy.IsAdult(sheep) then
		return Economy.Scale(sheep, GameConfig.SheepSize)
	end
	local start = Economy.LambScale(sheep.Weight)
	local share = math.clamp(sheep.Grown / Economy.GrowthSeconds(sheep), 0, 1)
	return GameConfig.SheepSize * (start + (LAMB_GROWN_SHARE - start) * share)
end

local function makeLabel(model: Model): TextLabel
	local root = model.PrimaryPart
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PenLabel"
	billboard.Size = UDim2.fromOffset(120, 34)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	billboard.MaxDistance = 70
	billboard.LightInfluence = 0
	billboard.Parent = root or model
	local words = Instance.new("TextLabel")
	words.BackgroundTransparency = 1
	words.Size = UDim2.fromScale(1, 1)
	words.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	words.TextScaled = true
	words.TextColor3 = Color3.fromRGB(190, 255, 90)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Parent = words
	words.Parent = billboard
	return words
end

function Pens.LabelText(sheep: Sheep): string
	local rate = `+{Format.Rate(Economy.Income(sheep))}/s`
	if Economy.IsAdult(sheep) then
		return rate
	end
	local share = math.clamp(sheep.Grown / Economy.GrowthSeconds(sheep), 0, 1)
	return `{rate}  {math.floor(share * 100)}%`
end

-- Puts a freshly built model on its pad. `build` makes the model (SheepService.Build).
function Pens.Show(
	sheep: Sheep,
	at: CFrame,
	ownerId: number,
	folder: Instance,
	build: (string, number, number) -> Model?
): Shown?
	local scale = Pens.Scale(sheep)
	local model = build(sheep.Family, sheep.Rarity, scale)
	if not model then
		return nil
	end
	model.Name = `Pen_{ownerId}_{sheep.Id}`
	model:SetAttribute("OwnerId", ownerId)
	model:SetAttribute("SheepId", sheep.Id)
	model:PivotTo(at)
	local label = makeLabel(model)
	label.Text = Pens.LabelText(sheep)
	model.Parent = folder
	return { Model = model, Scale = scale, Adult = Economy.IsAdult(sheep), Label = label }
end

-- Grows a lamb's model a little, or swaps nothing; returns false when it needs rebuilding (it just grew up).
function Pens.Update(shown: Shown, sheep: Sheep): boolean
	if Economy.IsAdult(sheep) ~= shown.Adult then
		return false
	end
	local scale = Pens.Scale(sheep)
	if math.abs(scale - shown.Scale) > 0.02 then
		local pivot = shown.Model:GetPivot()
		shown.Model:ScaleTo(scale)
		shown.Model:PivotTo(pivot)
		shown.Scale = scale
	end
	shown.Label.Text = Pens.LabelText(sheep)
	return true
end

return table.freeze(Pens)
