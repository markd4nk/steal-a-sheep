--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lifecycle = require(ReplicatedStorage.Lifecycle)

local Controllers = script.Parent.Controllers

-- Order matters: Init and Start run top to bottom, Destroy bottom to top. List dependencies first.
local registry: { Lifecycle.System } = {
	require(Controllers.StateController),
	require(Controllers.SoundController),
	require(Controllers.UIController),
	require(Controllers.CarryController),
	require(Controllers.MovementController),
	require(Controllers.WalkerController),
	require(Controllers.AnimController),
	require(Controllers.PromptController),
	require(Controllers.ComponentController),
}

return registry
