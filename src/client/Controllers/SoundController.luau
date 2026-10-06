--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Sounds = require(ReplicatedStorage.Config.Sounds)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Shear a Sheep's sounds (Config/Sounds, Roblox-licensed audio) played the same way, trimmed to what this game
-- needs: pooled 2D effects for what the player does, 3D ones at a spot for what happens around them, the calm music in
-- turn, its danger track while a god chases the player, and the meadow ambience. Each group plays at its mix volume
-- times the player's own setting (the Settings menu): music and the ambience follow Music, every effect Sound effects.
local SoundController = { Name = "SoundController" }

type Pool = { Sounds: { Sound }, Next: number }

local FOLDER_NAME = "GameSounds"
local FADE = TweenInfo.new(Sounds.Music.FadeSeconds, Enum.EasingStyle.Sine)

local trove = Trove.new()
local groups: { [string]: SoundGroup } = {}
local pools: { [string]: Pool } = {}
local lastAt: { [string]: number } = {}
local random = Random.new()
local calm: { Sound } = {}
local calmIndex = 1
local danger: Sound? = nil
local inDanger = false

local function make(name: string, id: string, volume: number, group: string, parent: Instance): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = volume
	sound.SoundGroup = groups[group]
	sound.Parent = parent
	return sound
end

local function ready(name: string, settings: Sounds.Effect): boolean
	local now = os.clock()
	local previous = lastAt[name]
	if previous and now - previous < (settings.Gap or 0) then
		return false
	end
	lastAt[name] = now
	return true
end

local function speedOf(settings: Sounds.Effect, speed: number?): number
	local jitter = settings.Jitter or 0
	return (speed or settings.Speed or 1) * (1 + random:NextNumber(-jitter, jitter))
end

local function groupVolume(name: string): number
	local setting: PlayerSettings.Name = if name == "Effects" then "SfxVolume" else "MusicVolume"
	return (Sounds.Groups[name] or 1) * PlayerSettings.Volume(Players.LocalPlayer, setting)
end

local function applyVolumes()
	for name, group in groups do
		group.Volume = groupVolume(name)
	end
end

local function fadeTo(sound: Sound, volume: number)
	TweenService:Create(sound, FADE, { Volume = volume }):Play()
end

local function playCalm()
	if #calm == 0 then
		return
	end
	local track = calm[calmIndex]
	track.Volume = Sounds.Music.Calm[calmIndex].Volume
	track:Play()
end

local function setDanger(on: boolean)
	if on == inDanger then
		return
	end
	inDanger = on
	local track = danger
	local current = calm[calmIndex]
	if on then
		if current then
			fadeTo(current, 0)
		end
		if track then
			track.Volume = 0
			track:Play()
			fadeTo(track, Sounds.Music.Danger.Volume)
		end
	else
		if track then
			fadeTo(track, 0)
		end
		task.delay(Sounds.Music.CalmDelay, function()
			if not inDanger and current then
				fadeTo(current, Sounds.Music.Calm[calmIndex].Volume)
				if not current.IsPlaying then
					current:Play()
				end
			end
		end)
	end
end

function SoundController.Init(_self: any, _systems: Lifecycle.Registry) end

function SoundController.Start(_self: any)
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = SoundService
	trove:Add(created)
	for name in Sounds.Groups do
		local group = Instance.new("SoundGroup")
		group.Name = name
		group.Volume = groupVolume(name)
		group.Parent = created
		groups[name] = group
	end
	local player = Players.LocalPlayer
	for _, setting in { "MusicVolume", "SfxVolume" } do
		trove:Connect(player:GetAttributeChangedSignal(PlayerSettings.Attribute(setting)), applyVolumes)
	end
	for name, settings in Sounds.Effects do
		local copies: { Sound } = {}
		for index = 1, settings.Voices or 1 do
			table.insert(
				copies,
				make(`{name}{index}`, settings.Id, settings.Volume, settings.Group or "Effects", created)
			)
		end
		pools[name] = { Sounds = copies, Next = 1 }
	end
	for index, track in Sounds.Music.Calm do
		local sound = make(track.Name, track.Id, track.Volume, "Music", created)
		table.insert(calm, sound)
		trove:Connect(sound.Ended, function()
			if index == calmIndex and not inDanger then
				calmIndex = calmIndex % #calm + 1
				playCalm()
			end
		end)
	end
	danger = make("Danger", Sounds.Music.Danger.Id, 0, "Music", created)
	if danger then
		danger.Looped = true
	end
	local ambience = make("Ambience", Sounds.Ambience.Id, Sounds.Ambience.Volume, "Ambience", created)
	ambience.Looped = true
	ambience:Play()
	playCalm()
	trove:Connect(player:GetAttributeChangedSignal("Carrying"), function()
		local carrying = player:GetAttribute("Carrying") == true
		if carrying then
			SoundController:Play("Pickup")
		end
	end)
end

function SoundController.Destroy(_self: any)
	trove:Clean()
	table.clear(pools)
	table.clear(calm)
end

-- A 2D effect by its Config/Sounds name.
function SoundController.Play(_self: any, name: string, speed: number?)
	local settings = Sounds.Effects[name]
	local pool = pools[name]
	if not settings or not pool or not ready(name, settings) then
		return
	end
	local sound = pool.Sounds[pool.Next]
	pool.Next = pool.Next % #pool.Sounds + 1
	sound.PlaybackSpeed = speedOf(settings, speed)
	sound.TimePosition = settings.Start or 0
	sound:Play()
end

-- A 3D effect at a part or attachment, heard within its Range.
function SoundController.PlayAt(_self: any, name: string, where: Instance, speed: number?)
	local settings = Sounds.Effects[name]
	if not settings or not ready(`{name}@`, settings) then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = settings.Id
	sound.Volume = settings.Volume
	sound.SoundGroup = groups[settings.Group or "Effects"]
	sound.PlaybackSpeed = speedOf(settings, speed)
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = settings.Range or Sounds.DefaultRange
	sound.TimePosition = settings.Start or 0
	sound.Parent = where
	sound:Play()
	task.delay(8, function()
		sound:Destroy()
	end)
end

-- The god chase's music: on while a god is after the player.
function SoundController.SetDanger(_self: any, on: boolean)
	setDanger(on)
end

return SoundController
