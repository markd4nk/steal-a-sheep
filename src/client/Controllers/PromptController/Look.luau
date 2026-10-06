--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Scale = require(script.Parent.Parent.UIController.Scale)

type Trove = typeof(Trove.new())

-- Every ProximityPrompt in the game's own look (they're all Style Custom, so Roblox draws none): the action on a
-- studded button like the menus', and how to do it on this device. On a computer the key sits beside it in a key cap,
-- and clicking the button works too; on a phone the button is what you tap, bigger, with no key; on a gamepad the
-- controller's button sits beside it. A prompt's object text (a price, a lamb's name) is a small line above. A prompt
-- that must be held fills its button while it's held.
local Look = {}

-- The button's colour, from the prompt's PromptKind attribute (a Theme.Button kind): Buy (green) unless it says.
local DEFAULT_KIND = "Buy"
local KEY_SIZE = 40
local GAP = 8
local SIDE_PADDING = 18 -- each side of the button's words
local MIN_WIDTH = 96
local OBJECT_SIZE = Theme.TextSize.Body
local COMPUTER_SIZE = 1.15 -- drawn this much bigger on a computer, as the HUD is
local POP = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local PRESS = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function onComputer(): boolean
	return not UserInputService.TouchEnabled and not GuiService:IsTenFootInterface()
end

local function textWidth(text: string, size: number): number
	return TextService:GetTextSize(text, size, Enum.Font.FredokaOne, Vector2.new(2000, 200)).X
end

-- The key cap: white with an ink outline and lip, the key's letter or the controller button's picture on it.
local function keyCap(parent: Instance, prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): Frame
	local cap = UIKit.Frame(parent, "Key", UDim2.fromOffset(KEY_SIZE, KEY_SIZE), Theme.Color.Snow)
	cap.LayoutOrder = 1
	UIKit.Corner(cap, Theme.Radius.Button)
	UIKit.Surface(cap, Theme.Color.Line, Theme.Lip.Small, Theme.Color.Line)
	local picture = if inputType == Enum.ProximityPromptInputType.Gamepad
		then UserInputService:GetImageForKeyCode(prompt.GamepadKeyCode)
		else ""
	if picture ~= "" then
		local icon = UIKit.Icon(cap, "Glyph", picture, KEY_SIZE - 8)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
	else
		local key = if inputType == Enum.ProximityPromptInputType.Gamepad
			then string.gsub(prompt.GamepadKeyCode.Name, "^Button", "")
			else UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
		if key == "" then
			key = prompt.KeyboardKeyCode.Name
		end
		UIKit.Text(cap, "KeyLabel", string.upper(key), 22, Theme.Color.Line, UDim2.fromScale(1, 1))
	end
	return cap
end

-- Draws `prompt` (shown for `inputType`) into `container`: its billboard, and a trove that takes it all away.
function Look.Show(
	prompt: ProximityPrompt,
	inputType: Enum.ProximityPromptInputType,
	container: Instance
): (Trove, BillboardGui)
	local trove = Trove.new()
	local touch = inputType == Enum.ProximityPromptInputType.Touch
	local kindAttribute = prompt:GetAttribute("PromptKind")
	local kind = if type(kindAttribute) == "string" and Theme.Button[kindAttribute :: any]
		then kindAttribute
		else DEFAULT_KIND
	local height = if touch then Theme.ButtonHeight.Hero else Theme.ButtonHeight.Standard
	local labelSize = if touch then Theme.TextSize.Title else Theme.TextSize.Label
	local action = prompt.ActionText
	local object = prompt.ObjectText
	local buttonWidth = math.max(MIN_WIDTH, math.ceil(textWidth(action, labelSize)) + SIDE_PADDING * 2)
	local hitHeight = math.max(height + Theme.Lip.Button, Theme.MinTouch)
	local rowWidth = buttonWidth + (if touch then 0 else KEY_SIZE + GAP)
	local objectHeight = if object ~= "" then OBJECT_SIZE + 8 else 0
	local scale = Scale.Current() * (if onComputer() then COMPUTER_SIZE else 1)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PromptUI"
	billboard.ResetOnSpawn = false
	billboard.AlwaysOnTop = true
	billboard.Active = true
	billboard.LightInfluence = 0
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboard.Size = UDim2.fromOffset(
		(math.max(rowWidth, textWidth(object, OBJECT_SIZE) + 12)) * scale,
		(objectHeight + hitHeight) * scale
	)
	-- PromptLift (studs) raises it off its part: the Put down prompt sits over the lamb on the player's head, not on it.
	local lift = prompt:GetAttribute("PromptLift")
	if type(lift) == "number" then
		billboard.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)
	end
	local adornee = prompt.Parent
	billboard.Adornee = if adornee
			and (adornee:IsA("BasePart") or adornee:IsA("Attachment") or adornee:IsA("Model"))
		then adornee :: any
		else nil
	trove:Add(billboard)

	-- Sizes are points: Root is drawn at the UI's scale, and Holder pops in from its middle.
	local root = UIKit.Frame(billboard, "Root", UDim2.fromScale(1 / scale, 1 / scale))
	local size = Instance.new("UIScale")
	size.Name = "Scale"
	size.Scale = scale
	size.Parent = root
	local holder = UIKit.Frame(root, "Holder", UDim2.fromScale(1, 1))
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	local pop = Instance.new("UIScale")
	pop.Name = "Pop"
	pop.Scale = 0.7
	pop.Parent = holder
	local column = UIKit.List(holder, false, 0, Enum.HorizontalAlignment.Center)
	column.VerticalAlignment = Enum.VerticalAlignment.Bottom

	if object ~= "" then
		UIKit.Text(holder, "ObjectLabel", object, OBJECT_SIZE, Theme.Color.Snow, UDim2.new(1, 0, 0, objectHeight), {
			Stroke = Theme.Color.Line,
			Order = 1,
		})
	end
	local row = UIKit.Frame(holder, "Row", UDim2.fromOffset(rowWidth, hitHeight))
	row.LayoutOrder = 2
	local line = UIKit.List(row, true, GAP, Enum.HorizontalAlignment.Center)
	line.VerticalAlignment = Enum.VerticalAlignment.Center
	if not touch then
		keyCap(row, prompt, inputType)
	end
	local button = UIKit.Button(row, "ActionButton", kind :: any, buttonWidth, height, action)
	button.LayoutOrder = 2
	local face = button:FindFirstChild("Face") :: Frame
	local squish = button:FindFirstChild("Squish") :: UIScale

	-- Holding: the face fills from the left over HoldDuration.
	local fill = UIKit.Frame(face, "HoldFill", UDim2.fromScale(0, 1), Theme.Color.Snow)
	fill.BackgroundTransparency = 0.55
	fill.ZIndex = 1
	UIKit.Corner(fill, Theme.Radius.Button)
	local function holdTween(on: boolean)
		local goal = if on then UDim2.fromScale(1, 1) else UDim2.fromScale(0, 1)
		local info = if on
			then TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear)
			else TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(fill, info, { Size = goal }):Play()
	end
	if prompt.HoldDuration > 0 then
		trove:Connect(prompt.PromptButtonHoldBegan, function()
			holdTween(true)
		end)
		trove:Connect(prompt.PromptButtonHoldEnded, function()
			holdTween(false)
		end)
	end
	trove:Connect(prompt.Triggered, function()
		TweenService:Create(squish, PRESS, { Scale = 0.88 }):Play()
		task.delay(PRESS.Time, function()
			TweenService:Create(squish, RELEASE, { Scale = 1 }):Play()
		end)
	end)

	-- A click or a tap on the button is the same as the key.
	if prompt.ClickablePrompt or touch then
		local held = false
		trove:Connect(button.InputBegan, function(input: InputObject)
			local kindOfInput = input.UserInputType
			if
				(kindOfInput == Enum.UserInputType.Touch or kindOfInput == Enum.UserInputType.MouseButton1)
				and input.UserInputState ~= Enum.UserInputState.Change
			then
				held = true
				prompt:InputHoldBegin()
			end
		end)
		trove:Connect(button.InputEnded, function(input: InputObject)
			local kindOfInput = input.UserInputType
			if held and (kindOfInput == Enum.UserInputType.Touch or kindOfInput == Enum.UserInputType.MouseButton1) then
				held = false
				prompt:InputHoldEnd()
			end
		end)
		trove:Add(function()
			if held then
				held = false
				prompt:InputHoldEnd()
			end
		end)
	end

	billboard.Parent = container
	TweenService:Create(pop, POP, { Scale = 1 }):Play()
	return trove, billboard
end

-- Prompts on the same spot (the walker sign's cash and Robux upgrades) stand side by side, in the order given.
function Look.Arrange(billboards: { BillboardGui })
	local count = #billboards
	for index, billboard in billboards do
		billboard.SizeOffset = Vector2.new((index - (count + 1) / 2) * 1.08, 0)
	end
end

-- Where the prompts' billboards live: this player's PlayerGui, so they're theirs alone.
function Look.Container(): Instance
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

return table.freeze(Look)
