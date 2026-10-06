--!strict

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Model = require(script.Model)

-- The Merge Shrine (DESIGN/DECISIONS.md): the Laurel Ring in the hub, where three grown sheep of one family and a fee
-- become one fresh lamb (FlockService.ShrineMerge). Its owner's client plays the merge and lands the lamb on the altar
-- (ShrineController); they pick it up there (Remotes.ShrineCollect) and carry it home like a stolen lamb, with no god
-- after it (WildService.CarryLamb). Nobody else sees or takes it. Left on the altar for LambWaitSeconds, or when its
-- owner leaves, it goes to their pen by itself. The lamb is in their flock from the moment of the merge, so nothing
-- that happens on the way home can lose it.
local ShrineService = { Name = "ShrineService" }

type Waiting = {
	Id: string,
	Family: string,
	Rarity: number,
	Weight: number,
	Scale: number,
	ReadyAt: number, -- when it has landed on the owner's altar
	GoesAt: number, -- when it goes to the pen by itself
}

local CHECK_SECONDS = 0.5
local LAND_SLACK = 0.5 -- the client's show may land a little before the server's clock says so
local POLICY_TRIES = 3
local POLICY_RETRY_SECONDS = 5

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local random = Random.new()
local waiting: { [Player]: Waiting } = {}
local shrine: Model? = nil
-- A merge's fee is cash, which the store sells for Robux, so the lamb it rolls is a paid random item: players whose
-- region restricts those can't merge. Unknown until Roblox answers, and closed while unknown.
local mayMerge: { [Player]: boolean } = {}

local function fetchPolicy(player: Player)
	for try = 1, POLICY_TRIES do
		local ok, policy = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)
		if ok and typeof(policy) == "table" then
			if player.Parent then
				mayMerge[player] = policy.ArePaidRandomItemsRestricted ~= true
			end
			return
		end
		if try < POLICY_TRIES then
			task.wait(POLICY_RETRY_SECONDS)
		end
	end
	warn(`ShrineService: no paid random item policy for {player.Name}; the shrine stays closed to them`)
end

local function notify(player: Player, message: string, kind: string, sound: string?)
	Remotes.Notify:Fire(player, message, kind, sound)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function altarTop(): CFrame?
	local altar = shrine and shrine:FindFirstChild("Altar")
	if not altar or not altar:IsA("BasePart") then
		return nil
	end
	return altar.CFrame * CFrame.new(0, altar.Size.Y / 2, 0)
end

-- The lamb leaves the altar for its owner's pen without being carried.
local function sendHome(player: Player, reason: string?)
	local lamb = waiting[player]
	if not lamb then
		return
	end
	waiting[player] = nil
	registry.FlockService:ShrineArrive(player, lamb.Id, reason)
	Remotes.ShrineShow:Fire(player, nil)
end

local function merge(player: Player, ids: { string }): (boolean, string?)
	local root = rootOf(player)
	if not root or (root.Position - GameConfig.Shrine.At.Position).Magnitude > GameConfig.Shrine.MenuDistance + 8 then
		return false, "Come closer to the shrine"
	end
	if waiting[player] then
		return false, "Pick up your lamb first"
	end
	if not mayMerge[player] then
		return false, "Merging isn't available in your region"
	end
	-- How the three looked, for the show: they're gone from the flock once the merge goes through.
	local data = registry.DataService:GetData(player)
	local inputs: { { [string]: any } } = {}
	for _, id in ids do
		local sheep = data and data.Sheep[id]
		if sheep then
			table.insert(inputs, {
				Family = sheep.Family,
				Rarity = sheep.Rarity,
				Scale = Economy.Scale(sheep, GameConfig.SheepSize),
			})
		end
	end
	local ok, message, lamb = registry.FlockService:ShrineMerge(player, ids, random)
	if not ok or not lamb then
		return false, message
	end
	local scale = Economy.Scale(lamb, GameConfig.SheepSize)
	local now = os.clock()
	waiting[player] = {
		Id = lamb.Id,
		Family = lamb.Family,
		Rarity = lamb.Rarity,
		Weight = lamb.Weight,
		Scale = scale,
		ReadyAt = now + GameConfig.Shrine.MergeSeconds,
		GoesAt = now + GameConfig.Shrine.MergeSeconds + GameConfig.Shrine.LambWaitSeconds,
	}
	-- The lamb lands on the altar as a lamb, marked like any other (SheepService.LambLook).
	Remotes.ShrineShow:Fire(player, {
		Inputs = inputs,
		Family = lamb.Family,
		Rarity = lamb.Rarity,
		Scale = scale,
		Weight = lamb.Weight,
		Look = registry.SheepService:LambLook(lamb.Family),
	})
	return true, nil
end

local function collect(player: Player)
	local lamb = waiting[player]
	local root = rootOf(player)
	local top = altarTop()
	if not lamb or not root or not top or os.clock() < lamb.ReadyAt - LAND_SLACK then
		return
	end
	if (root.Position - top.Position).Magnitude > GameConfig.Shrine.CollectDistance + 4 then
		notify(player, "Get closer to the altar", "Bad", "Denied")
		return
	end
	if player:GetAttribute("Carrying") == true then
		notify(player, "Take your sheep home first", "Bad", "Denied")
		return
	end
	local model = registry.SheepService:BuildLamb(lamb.Family, lamb.Rarity, lamb.Weight, lamb.Scale)
	if not model then
		return
	end
	model.Name = "ShrineLamb"
	model:PivotTo(top)
	if not registry.WildService:CarryLamb(player, model, lamb.Id, lamb.Family, lamb.Weight) then
		model:Destroy()
		return
	end
	waiting[player] = nil
	Remotes.ShrineShow:Fire(player, nil)
end

function ShrineService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function ShrineService.Start(_self: any)
	local model = Model.Build(GameConfig.Shrine.At)
	model.Parent = workspace
	shrine = model
	trove:Add(model)

	Remotes.Merge:Handle(merge)
	trove:Add(Remotes.ShrineCollect:Connect(collect))
	trove:Connect(Players.PlayerAdded, function(player: Player)
		task.spawn(fetchPolicy, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(fetchPolicy, player)
	end
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		sendHome(player, nil)
		mayMerge[player] = nil
	end)
	local since = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		since += dt
		if since < CHECK_SECONDS then
			return
		end
		since = 0
		local now = os.clock()
		for player, lamb in waiting do
			if now >= lamb.GoesAt then
				sendHome(player, "Your new lamb went to your pen")
			end
		end
	end)
end

function ShrineService.Destroy(_self: any)
	trove:Clean()
	shrine = nil
end

return ShrineService
