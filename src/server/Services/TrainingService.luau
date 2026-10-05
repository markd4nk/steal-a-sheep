--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The stair walker: standing on your own plot's machine trains Climbing at its level's rate times your trail's
-- multiplier, while your flock keeps earning. Nothing while carrying a lamb or off the machine. The server checks the
-- player's spot every tick; the client only plays the stepping.
local TrainingService = { Name = "TrainingService" }

local registry: Lifecycle.Registry = {}
local trove = Trove.new()

local function tick(dt: number)
	for _, player in Players:GetPlayers() do
		local data = registry.DataService:GetData(player)
		if not data then
			continue
		end
		local training = registry.PlotService:IsOnWalker(player) and not registry.WildService:IsCarrying(player)
		if player:GetAttribute("Training") ~= training then
			player:SetAttribute("Training", training)
		end
		if not training then
			continue
		end
		local before = Economy.ClimbTier(data.ClimbPower)
		data.ClimbPower += Economy.TrainingRate(data.WalkerLevel, data.Trail) * dt
		player:SetAttribute("ClimbPower", data.ClimbPower)
		local stepped = data.Tutorial == 1
		if stepped then
			data.Tutorial = 2
			player:SetAttribute("Tutorial", 2)
		end
		if stepped or Economy.ClimbTier(data.ClimbPower) ~= before then
			registry.FlockService:Push(player)
		end
	end
end

function TrainingService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function TrainingService.Start(_self: any)
	local elapsed = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		elapsed += dt
		if elapsed >= GameConfig.Training.TickSeconds then
			local step = elapsed
			elapsed = 0
			tick(step)
		end
	end)
end

function TrainingService.Destroy(_self: any)
	trove:Clean()
end

return TrainingService
