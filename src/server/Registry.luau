--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lifecycle = require(ReplicatedStorage.Lifecycle)

local Services = script.Parent.Services

-- Order matters: Init and Start run top to bottom, Destroy bottom to top. List dependencies first.
local registry: { Lifecycle.System } = {
	require(Services.DataService),
	require(Services.PurchaseService),
	require(Services.SheepService),
	require(Services.PlotService),
	require(Services.FlockService),
	require(Services.GodService),
	require(Services.WildService),
	require(Services.MountainService),
	require(Services.TrainingService),
	require(Services.ShopService),
	require(Services.GiftService),
	require(Services.LeaderboardService),
	require(Services.DebugService),
	require(Services.ComponentService),
}

return registry
