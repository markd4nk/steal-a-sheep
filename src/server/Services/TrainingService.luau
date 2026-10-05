--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Remotes = require(ReplicatedStorage.Remotes)
local StairClimb = require(ReplicatedStorage.Utils.StairClimb)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The stair walker: walking into your own machine's entry snaps you onto its steps, like a treadmill (root anchored
-- where your legs reach the steps); jumping steps you off. While on it you train Climbing at its level's rate times
-- your trail's multiplier, and your flock keeps earning. Not while carrying a lamb. Clients run the steps and the climb
-- (WalkerController); the server only places the player and keeps the OnWalker attribute (their plot's index).
local TrainingService = { Name = "TrainingService" }

type Session = { Plot: any, At: CFrame }

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local sessions: { [Player]: Session } = {}
-- False after stepping off, until the player has left the entry: walking away doesn't snap them straight back on.
local armed: { [Player]: boolean } = {}
local told: { [Player]: boolean } = {}

local function rootOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return root, humanoid
	end
	return nil, nil
end

local function stepOff(player: Player, putDown: boolean)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	armed[player] = false
	player:SetAttribute("OnWalker", nil)
	session.Plot.Pieces.Walker.Model:SetAttribute("Climber", nil)
	local root = rootOf(player)
	if root then
		root.Anchored = false
		if putDown then
			(player.Character :: Model):PivotTo(StairClimb.ExitAt(session.Plot.Pieces.Walker.Model:GetPivot()))
		end
	end
end

local function stepOn(player: Player)
	local plot = registry.PlotService:GetPlot(player)
	local root = rootOf(player)
	local character = player.Character
	if not plot or not root or not character then
		return
	end
	local rig = StairClimb.Rig(character)
	local offset = if rig then rig.Offset else StairClimb.Tread(0.5) + Vector3.new(0, 3, 0.2)
	local at = plot.Pieces.Walker.Model:GetPivot() * CFrame.new(offset)
	root.Anchored = true
	root.CFrame = at
	sessions[player] = { Plot = plot, At = at }
	player:SetAttribute("OnWalker", plot.Index)
	plot.Pieces.Walker.Model:SetAttribute("Climber", player.UserId)
	if not told[player] then
		told[player] = true
		Remotes.Notify:Fire(player, "Jump to get off", "Good")
	end
end

-- Every frame: snap owners who walk into their machine's entry onto it, and step off anyone who can't stay on.
local function watch()
	for _, player in Players:GetPlayers() do
		local carrying = registry.WildService:IsCarrying(player)
		local session = sessions[player]
		if session then
			local root = rootOf(player)
			if not root or carrying or (root.Position - session.At.Position).Magnitude > 2 then
				stepOff(player, false)
			end
		elseif registry.PlotService:AtWalker(player) then
			if armed[player] ~= false and not carrying and registry.DataService:GetData(player) then
				stepOn(player)
			end
		else
			armed[player] = true
		end
	end
end

local function tick(dt: number)
	for _, player in Players:GetPlayers() do
		local data = registry.DataService:GetData(player)
		if not data then
			continue
		end
		local training = sessions[player] ~= nil and not registry.WildService:IsCarrying(player)
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
		watch()
		elapsed += dt
		if elapsed >= GameConfig.Training.TickSeconds then
			local step = elapsed
			elapsed = 0
			tick(step)
		end
	end)
	trove:Add(Remotes.LeaveWalker:Connect(function(player: Player)
		stepOff(player, true)
	end))
	local function follow(player: Player)
		trove:Connect(player.CharacterRemoving, function()
			stepOff(player, false)
		end)
	end
	for _, player in Players:GetPlayers() do
		follow(player)
	end
	trove:Connect(Players.PlayerAdded, follow)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		stepOff(player, false)
		armed[player] = nil
		told[player] = nil
	end)
end

function TrainingService.Destroy(_self: any)
	trove:Clean()
end

return TrainingService
