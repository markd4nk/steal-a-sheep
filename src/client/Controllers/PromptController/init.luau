--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local PenArea = require(ReplicatedStorage.Utils.PenArea)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Look = require(script.Look)

-- The world's prompts on this device, drawn in the game's own look (Look): a station's (Opens: Shop, Sell, Merge)
-- opens its screen, another player's tutorial lamb can't be stolen here (the server refuses it too), and no lamb offers
-- itself while the player carries one. Inside their own fence with a lamb, the lamb on their head offers Put down: a
-- prompt only this device has, which asks the server (Remotes.PutDown) to deliver it there. Only the owner sees their
-- stair walker sign's upgrade prompts.
local PromptController = { Name = "PromptController" }

local OPENS: { [string]: { Screen: string, Options: { [string]: any }? } } = {
	Shop = { Screen = "Shop" },
	Sell = { Screen = "SellStall" },
	Merge = { Screen = "Merge" },
}
local PUT_DOWN_CHECK = 0.1

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local player = Players.LocalPlayer
local putDownPrompt: ProximityPrompt? = nil
-- The prompts showing now, each with what draws it.
type Drawn = { Trove: typeof(Trove.new()), Billboard: BillboardGui }
local shown: { [ProximityPrompt]: Drawn } = {}

-- Roblox draws no prompt of its own: each is the game's (the server makes them Custom too; this catches any it missed).
local function customise(descendant: Instance)
	if descendant:IsA("ProximityPrompt") and descendant.Style ~= Enum.ProximityPromptStyle.Custom then
		descendant.Style = Enum.ProximityPromptStyle.Custom
	end
end

-- Side by side when several show on one spot, in their keys' order (E before R).
local function arrange(spot: Instance?)
	if not spot then
		return
	end
	local together: { ProximityPrompt } = {}
	for prompt in shown do
		if prompt.Parent == spot then
			table.insert(together, prompt)
		end
	end
	table.sort(together, function(a: ProximityPrompt, b: ProximityPrompt)
		return a.KeyboardKeyCode.Value < b.KeyboardKeyCode.Value
	end)
	local billboards: { BillboardGui } = {}
	for _, prompt in together do
		table.insert(billboards, shown[prompt].Billboard)
	end
	Look.Arrange(billboards)
end

local function hide(prompt: ProximityPrompt)
	local drawn = shown[prompt]
	if drawn then
		shown[prompt] = nil
		drawn.Trove:Destroy()
		arrange(prompt.Parent)
	end
end

local function show(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	hide(prompt)
	local trove, billboard = Look.Show(prompt, inputType, Look.Container())
	local drawn = { Trove = trove, Billboard = billboard }
	shown[prompt] = drawn
	arrange(prompt.Parent)
	-- Its words can change while it shows (the walker sign's price after an upgrade): drawn again.
	local function redraw()
		if shown[prompt] == drawn then
			show(prompt, inputType)
		end
	end
	trove:Connect(prompt:GetPropertyChangedSignal("ActionText"), redraw)
	trove:Connect(prompt:GetPropertyChangedSignal("ObjectText"), redraw)
	trove:Connect(prompt.Destroying, function()
		hide(prompt)
	end)
end

local function refreshPrompt(prompt: ProximityPrompt)
	if prompt.Name ~= "StealPrompt" then
		return
	end
	local owner = prompt:GetAttribute("OwnerId")
	local mine = owner == nil or owner == player.UserId
	local carrying = player:GetAttribute("Carrying") == true
	prompt.Enabled = mine and not carrying
end

-- The walker sign's prompts carry their owner's id: hidden from everyone else. The server turns them on and off for
-- the owner; this device only ever turns them off.
local OWNED = { CoinPrompt = true, RobuxPrompt = true }

local function refreshOwned(prompt: ProximityPrompt)
	if prompt:GetAttribute("OwnerId") ~= player.UserId and prompt.Enabled then
		prompt.Enabled = false
	end
end

local function watchOwned(prompt: ProximityPrompt)
	refreshOwned(prompt)
	trove:Connect(prompt:GetPropertyChangedSignal("Enabled"), function()
		task.defer(refreshOwned, prompt)
	end)
	trove:Connect(prompt:GetAttributeChangedSignal("OwnerId"), function()
		task.defer(refreshOwned, prompt)
	end)
end

local function refreshAll()
	local wild = workspace:FindFirstChild("WildSheep")
	if not wild then
		return
	end
	for _, descendant in wild:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			refreshPrompt(descendant)
		end
	end
end

-- The lamb on this player's head: its root, welded to their character.
local function carriedLamb(character: Model): BasePart?
	local carried = workspace:FindFirstChild("CarriedSheep")
	if not carried then
		return nil
	end
	for _, model in carried:GetChildren() do
		local root = if model:IsA("Model") then model.PrimaryPart else nil
		local weld = root and root:FindFirstChild("CarryWeld")
		local holder = if weld and weld:IsA("Weld") then weld.Part0 else nil
		if root and holder and holder:IsDescendantOf(character) then
			return root
		end
	end
	return nil
end

local function ownPen(): BasePart?
	local index = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = if plots and type(index) == "number" then plots:FindFirstChild(`Plot{index}`) else nil
	local pen = plot and plot:FindFirstChild("Pen")
	return if pen and pen:IsA("BasePart") then pen else nil
end

local function dropPutDown()
	if putDownPrompt then
		putDownPrompt:Destroy()
		putDownPrompt = nil
	end
end

-- Offers Put down while this player carries a lamb inside their own fence.
local function refreshPutDown()
	local character = player.Character
	local pen = ownPen()
	local lamb = if character and player:GetAttribute("Carrying") == true then carriedLamb(character) else nil
	if not character or not pen or not lamb or not PenArea.Contains(pen, character:GetPivot().Position, 0) then
		dropPutDown()
		return
	end
	if putDownPrompt and putDownPrompt.Parent == lamb then
		return
	end
	dropPutDown()
	-- The verb only.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PutDownPrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom
	local scale = player:GetAttribute("CarriedScale")
	prompt:SetAttribute("PromptLift", 1 + 2 * (if type(scale) == "number" then scale else 1))
	prompt.ActionText = "Put down"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = GameConfig.Theft.PutDownReach
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt.Triggered:Connect(function()
		Remotes.PutDown:Fire()
	end)
	prompt.Parent = lamb
	putDownPrompt = prompt
end

function PromptController.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function PromptController.Start(_self: any)
	trove:Connect(workspace.DescendantAdded, customise)
	for _, descendant in workspace:GetDescendants() do
		customise(descendant)
	end
	trove:Connect(ProximityPromptService.PromptShown, show)
	trove:Connect(ProximityPromptService.PromptHidden, hide)
	trove:Connect(ProximityPromptService.PromptTriggered, function(prompt: ProximityPrompt)
		local opens = prompt:GetAttribute("Opens")
		local spec = if type(opens) == "string" then OPENS[opens] else nil
		if spec then
			registry.UIController:Open(spec.Screen, spec.Options)
		end
	end)
	task.spawn(function()
		local wild = workspace:WaitForChild("WildSheep", 60)
		if not wild then
			return
		end
		trove:Connect(wild.DescendantAdded, function(descendant: Instance)
			if descendant:IsA("ProximityPrompt") then
				refreshPrompt(descendant)
				-- The server turns a lamb's prompt back on when it returns; this device decides again.
				trove:Connect(descendant:GetPropertyChangedSignal("Enabled"), function()
					task.defer(refreshPrompt, descendant)
				end)
			end
		end)
		for _, descendant in wild:GetDescendants() do
			if descendant:IsA("ProximityPrompt") then
				refreshPrompt(descendant)
			end
		end
	end)
	trove:Connect(player:GetAttributeChangedSignal("Carrying"), refreshAll)
	task.spawn(function()
		local plots = workspace:WaitForChild("Plots", 60)
		if not plots then
			return
		end
		trove:Connect(plots.DescendantAdded, function(descendant: Instance)
			if descendant:IsA("ProximityPrompt") and OWNED[descendant.Name] then
				watchOwned(descendant)
			end
		end)
		for _, descendant in plots:GetDescendants() do
			if descendant:IsA("ProximityPrompt") and OWNED[descendant.Name] then
				watchOwned(descendant)
			end
		end
	end)
	local sinceCheck = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		sinceCheck += dt
		if sinceCheck >= PUT_DOWN_CHECK then
			sinceCheck = 0
			refreshPutDown()
		end
	end)
end

function PromptController.Destroy(_self: any)
	trove:Clean()
	dropPutDown()
	for prompt in shown do
		hide(prompt)
	end
end

return PromptController
