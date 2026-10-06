--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Show = require(script.Show)

-- The Merge Shrine on this device (ShrineService runs it): the sheep picked in the Merge menu standing on the pedestals,
-- the camera on the shrine while the menu is open, the merge itself when the server says it went through
-- (Remotes.ShrineShow, Show), and the lamb waiting on the altar with a Pick up prompt. All of it is this player's own:
-- nobody else sees their picks, their merge or their lamb until they carry it away.
local ShrineController = { Name = "ShrineController" }

export type Pick = { Family: string, Scale: number }
export type Shot = "Menu" | "Show"

local SHOT_SECONDS = 0.5
local LANDED_SECONDS = 1.4 -- the camera stays on the landed lamb this long before going back to the player
local FOV = 55
-- Where the camera stands and looks, in the shrine's space (its front is -Z): for the menu the shrine sits left of the
-- middle, clear of the panel on the right; for the merge it's in the middle.
local SHOTS: { [Shot]: { From: Vector3, To: Vector3 } } = {
	Menu = { From = Vector3.new(4, 12.5, -32), To = Vector3.new(-5, 9.5, -2) },
	Show = { From = Vector3.new(9, 13.5, -34), To = Vector3.new(0, 10, -2) },
}
-- The sound at each beat of the merge (Show).
local BEATS: { [string]: string } = {
	Merge = "LabZap",
	Rise = "LabRiser",
	Pop = "RevealSparkle",
	Land = "PenDrop",
}
local SPARKLES = {
	Color3.fromRGB(255, 230, 140),
	Color3.fromRGB(140, 200, 255),
	Color3.fromRGB(255, 205, 70),
}

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local player = Players.LocalPlayer
local shrine: Model? = nil
local folder: Folder? = nil
local previews: { Model } = {}
local lamb: Model? = nil
local showing = false
local framed: Shot? = nil
local restoreFov: number? = nil

-- A family's plain look (SheepService's preview models) at `scale` times its rig, standing at `at`.
local function sheepModel(family: string, scale: number, at: CFrame): Model?
	local looks = ReplicatedStorage:FindFirstChild("SheepLooks")
	local source = looks and looks:FindFirstChild(family)
	if not source or not source:IsA("Model") then
		return nil
	end
	local model = source:Clone()
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	model:ScaleTo(math.max(scale, 0.05))
	model:PivotTo(at)
	return model
end

-- The top of pedestal `index` (1 left, 2 the back, 3 right, seen from the front), a sheep on it facing the front.
local function pedestalSpot(index: number): CFrame?
	local pedestal = shrine and shrine:FindFirstChild(`Pedestal{index}`)
	if not pedestal or not pedestal:IsA("BasePart") then
		return nil
	end
	local top = (pedestal.CFrame * CFrame.new(0, pedestal.Size.Y / 2, 0)).Position
	return CFrame.new(top) * GameConfig.Shrine.At.Rotation * CFrame.Angles(0, math.rad(180), 0)
end

local function clearPreviews()
	for _, model in previews do
		model:Destroy()
	end
	table.clear(previews)
end

local function clearLamb()
	if lamb then
		lamb:Destroy()
		lamb = nil
	end
end

local function shotFrame(shot: Shot): CFrame
	local at = GameConfig.Shrine.At
	local spec = SHOTS[shot]
	return CFrame.lookAt(at:PointToWorldSpace(spec.From), at:PointToWorldSpace(spec.To))
end

-- The HUD and the shrine's own Merge prompt hide while the camera is on the shrine: the shrine is the scene.
local function setHud(visible: boolean)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild("Hud")
	if hud and hud:IsA("ScreenGui") then
		hud.Enabled = visible
	end
	local stations = workspace:FindFirstChild("Stations")
	local station = stations and stations:FindFirstChild("MergeStation")
	local prompt = station and station:FindFirstChildWhichIsA("ProximityPrompt")
	if prompt then
		prompt.Enabled = visible
	end
end

-- The camera on the shrine (a shot), or back on the player (nil).
local function frame(shot: Shot?)
	local camera = workspace.CurrentCamera
	if shot then
		setHud(false)
		if not framed then
			restoreFov = camera.FieldOfView
		end
		framed = shot
		camera.CameraType = Enum.CameraType.Scriptable
		TweenService:Create(camera, TweenInfo.new(SHOT_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = shotFrame(shot),
			FieldOfView = FOV,
		}):Play()
		return
	end
	if not framed then
		return
	end
	framed = nil
	setHud(true)
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = restoreFov or 70
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

-- The lamb waits on the altar until its owner picks it up (the server then puts it over their head) or it goes home.
local function waitOnAltar(model: Model)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShrinePrompt"
	prompt.ActionText = "Pick up"
	prompt.ObjectText = (string.gsub(model.Name, "Sheep$", "Lamb"))
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = GameConfig.Shrine.CollectDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = root
	prompt.Triggered:Connect(function()
		Remotes.ShrineCollect:Fire()
	end)
end

local function play(show: { [string]: any })
	local holder = folder
	local home = shrine
	if showing or not holder or not home then
		return
	end
	local family = show.Family
	local rarity = show.Rarity
	local scale = show.Scale
	if type(family) ~= "string" or type(rarity) ~= "number" or type(scale) ~= "number" then
		return
	end
	showing = true
	clearLamb()
	-- The three on their pedestals: the menu's picks if they're still standing, otherwise made again.
	local sheep: { Model } = {}
	if #previews == 3 then
		sheep = table.clone(previews)
		table.clear(previews)
	else
		clearPreviews()
		local inputs = if type(show.Inputs) == "table" then show.Inputs else {}
		for index, input in inputs do
			local spot = pedestalSpot(index)
			local model = if spot
					and type(input.Family) == "string"
					and type(input.Scale) == "number"
				then sheepModel(input.Family, input.Scale, spot)
				else nil
			if model then
				model.Parent = holder
				table.insert(sheep, model)
			end
		end
	end
	local start = Show.AltarSpot(home) or CFrame.new()
	local model = sheepModel(family, scale, start)
	if not model then
		for _, other in sheep do
			other:Destroy()
		end
		showing = false
		return
	end
	local tier = Economy.Tier(family)
	model.Name = tier.FamilyName
	lamb = model
	frame("Show")
	Show.Play({
		Shrine = home,
		Sheep = sheep,
		Lamb = model,
		LambScale = scale,
		Sparkle = SPARKLES[rarity] or SPARKLES[1],
		Beat = function(name: string)
			local sound = registry.SoundController
			local cue = BEATS[name]
			if sound and cue then
				sound:Play(cue)
			end
		end,
	}, holder)
	showing = false
	if lamb ~= model then
		-- The lamb left the altar during the show (it can't be picked up before it lands, but it can go home).
		model:Destroy()
		frame(nil)
		return
	end
	local ui = registry.UIController
	if ui then
		local title = if rarity >= 3 then "ROYAL!" elseif rarity == 2 then "RARE!" else "NEW LAMB!"
		ui:Celebrate(title, "Pick it up and take it home")
	end
	task.delay(LANDED_SECONDS, function()
		if not showing and framed == "Show" then
			frame(nil)
		end
	end)
	waitOnAltar(model)
end

function ShrineController.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function ShrineController.Start(_self: any)
	local holder = Instance.new("Folder")
	holder.Name = "ShrineLocal"
	holder.Parent = workspace
	folder = holder
	trove:Add(holder)
	task.spawn(function()
		local found = workspace:WaitForChild("MergeShrine", 60)
		if found and found:IsA("Model") then
			shrine = found
		end
	end)
	trove:Add(Remotes.ShrineShow:Connect(function(show: { [string]: any }?)
		if show then
			task.spawn(play, show)
		else
			clearLamb()
		end
	end))
end

function ShrineController.Destroy(_self: any)
	frame(nil)
	clearPreviews()
	clearLamb()
	trove:Clean()
end

-- The menu's picks on the pedestals, in order (an empty list clears them). Ignored while a merge plays.
function ShrineController.Preview(_self: any, picks: { Pick })
	local holder = folder
	if showing or not holder then
		return
	end
	clearPreviews()
	for index, pick in picks do
		local spot = pedestalSpot(index)
		local model = if spot then sheepModel(pick.Family, pick.Scale, spot) else nil
		if model then
			model.Parent = holder
			table.insert(previews, model)
		end
	end
end

-- The camera on the shrine for the menu (true) or back on the player (false). A merge keeps it on the shrine.
function ShrineController.Frame(_self: any, on: boolean)
	if showing then
		return
	end
	frame(if on then "Menu" else nil)
end

function ShrineController.IsShowing(_self: any): boolean
	return showing
end

return ShrineController
