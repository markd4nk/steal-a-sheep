--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local PenArea = require(ReplicatedStorage.Utils.PenArea)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The world's prompts on this device: a station's (Opens: Shop, Sell, Merge) opens its screen, another player's
-- tutorial lamb can't be stolen here (the server refuses it too), and no lamb offers itself while the player carries
-- one. Inside their own fence with a lamb, the lamb on their head offers Put down: a prompt only this device has, which
-- asks the server (Remotes.PutDown) to deliver it there.
local PromptController = { Name = "PromptController" }

local OPENS: { [string]: { Screen: string, Options: { [string]: any }? } } = {
	Shop = { Screen = "Shop" },
	Sell = { Screen = "Flock", Options = { Sell = true } },
	Merge = { Screen = "Merge" },
}
local PUT_DOWN_CHECK = 0.1

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local player = Players.LocalPlayer
local putDownPrompt: ProximityPrompt? = nil

local function refreshPrompt(prompt: ProximityPrompt)
	if prompt.Name ~= "StealPrompt" then
		return
	end
	local owner = prompt:GetAttribute("OwnerId")
	local mine = owner == nil or owner == player.UserId
	local carrying = player:GetAttribute("Carrying") == true
	prompt.Enabled = mine and not carrying
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
	local tier = player:GetAttribute("CarryTier")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PutDownPrompt"
	prompt.ActionText = "Put down"
	prompt.ObjectText = if type(tier) == "number" and Olympus.Tiers[tier]
		then (string.gsub(Olympus.Tiers[tier].FamilyName, "Sheep$", "Lamb"))
		else ""
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
end

return PromptController
