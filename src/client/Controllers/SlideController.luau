--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BodyClips = require(ReplicatedStorage.Utils.BodyClips)
local CarryPose = require(ReplicatedStorage.Utils.CarryPose)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- How sliding players look on this device: surfing down side on, knees bent, looking downhill, carving and leaning
-- into turns (Utils/BodyClips' Surf, the user's pick over Roblox's sit, 2026-10-06). Posed on every device over the
-- Animator, like a carried lamb's raised arms, so nothing replicates: the local player's slide shows the moment
-- MovementController starts it, anyone else's when the server's Sliding attribute says so. A carrier keeps
-- CarryController's arms (it poses first, so this leaves them alone). R6 characters keep the sit MovementController
-- plays. Only sliders near the camera are posed.
local SlideController = { Name = "SlideController" }

type Slider = {
	Rig: BodyClips.Rig?,
	For: Model?, -- the character Rig was measured from (nil Rig: one BodyClips can't pose, such as R6)
	Since: number, -- os.clock() this slide began, so the carve starts from its beginning
	Sliding: boolean,
	Weight: number, -- how far the surf is blended over the Animator's
}

local RANGE = 200
local BLEND_IN = 10
local BLEND_OUT = 7

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local sliders: { [Player]: Slider } = {}
local touched: { CarryPose.Joint } = {}
local befores: { CFrame } = {}

local function isSliding(player: Player): boolean
	if player == Players.LocalPlayer then
		local movement = registry.MovementController
		return movement ~= nil and movement:IsSliding()
	end
	return player:GetAttribute("Sliding") == true
end

local function pose(dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local slider = sliders[player]
		local sliding = isSliding(player)
		if not slider then
			if not sliding then
				continue
			end
			slider = { Rig = nil, For = nil, Since = now, Sliding = false, Weight = 0 }
			sliders[player] = slider
		end
		if sliding and not slider.Sliding then
			slider.Since = now
		end
		slider.Sliding = sliding
		local character = player.Character
		local rig = slider.Rig
		if character and (slider.For ~= character or (rig and not BodyClips.Intact(rig))) then
			rig = BodyClips.Measure(character)
			slider.Rig = rig
			slider.For = character
		end
		slider.Weight += ((if sliding then 1 else 0) - slider.Weight) * math.clamp(
			dt * (if sliding then BLEND_IN else BLEND_OUT),
			0,
			1
		)
		if not sliding and slider.Weight < 0.01 then
			sliders[player] = nil
			continue
		end
		if not rig or (rig.Root.Position - eye).Magnitude > RANGE then
			continue
		end
		local frame = BodyClips.Sample("Surf", now - slider.Since, rig.Body)
		frame.Root = BodyClips.Ground(rig, "Surf", dt) * (frame.Root or CFrame.identity)
		local skip = if player:GetAttribute("Carrying") == true then BodyClips.HoldJoints else nil
		BodyClips.Apply(rig, frame, slider.Weight, skip, touched, befores)
	end
end

function SlideController.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function SlideController.Start(_self: any)
	-- Connected after CarryController's (the registry starts it first): the carry's arms are on already.
	trove:Connect(RunService.PreSimulation, pose)
	trove:Connect(RunService.PostSimulation, function()
		BodyClips.Restore(touched, befores)
	end)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		sliders[player] = nil
	end)
end

function SlideController.Destroy(_self: any)
	trove:Clean()
	BodyClips.Restore(touched, befores)
	table.clear(sliders)
end

return SlideController
