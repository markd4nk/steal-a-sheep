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
	require(Controllers.GodController),
	require(Controllers.ChaseController),
	require(Controllers.ShrineController),
	require(Controllers.PromptController),
	require(Controllers.ComponentController),
	-- Studio-only camera rig for filming trailers (BRAIN/PATTERNS/trailers.md); does nothing in live games.
	require(Controllers.TrailerController),
}

return registry
