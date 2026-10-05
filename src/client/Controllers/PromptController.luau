--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The world's prompts on this device: a station's (Opens: Shop, Sell, Merge) opens its screen, another player's
-- tutorial lamb can't be stolen here (the server refuses it too), and no lamb offers itself while the player carries
-- one.
local PromptController = { Name = "PromptController" }

local OPENS: { [string]: { Screen: string, Options: { [string]: any }? } } = {
	Shop = { Screen = "Shop" },
	Sell = { Screen = "Flock", Options = { Sell = true } },
	Merge = { Screen = "Merge" },
}

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local player = Players.LocalPlayer

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
end

function PromptController.Destroy(_self: any)
	trove:Clean()
end

return PromptController
