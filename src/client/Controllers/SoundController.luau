--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local ChaseFeel = require(ReplicatedStorage.Utils.ChaseFeel)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Sounds = require(ReplicatedStorage.Config.Sounds)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Shear a Sheep's sounds (Config/Sounds, Roblox-licensed audio) played the same way, trimmed to what this game
-- needs: pooled 2D effects for what the player does, 3D ones at a spot or from a thing (a god) for what happens around
-- them, the calm music in turn, the chase music while a god is after the player, and the meadow ambience. Each group
-- plays at its mix volume times the player's own setting (the Settings menu): music and the ambience follow Music,
-- every effect Sound effects.
local SoundController = { Name = "SoundController" }

type Pool = { Sounds: { Sound }, Next: number }

local FOLDER_NAME = "GameSounds"
local FADE = TweenInfo.new(Sounds.Music.FadeSeconds, Enum.EasingStyle.Sine)
local DANGER_IN = TweenInfo.new(Sounds.Music.DangerInSeconds, Enum.EasingStyle.Sine)

local trove = Trove.new()
local groups: { [string]: SoundGroup } = {}
local pools: { [string]: Pool } = {}
-- Pools that play from a part (PlayOn), by part and then by effect name; they go with the part.
local emitters: { [Instance]: { [string]: Pool } } = setmetatable({}, { __mode = "k" }) :: any
local lastAt: { [string]: number } = {}
-- Each play's number, so a cut-off timer (an effect's Length) stops only the play it was set for.
local plays: { [Sound]: number } = setmetatable({}, { __mode = "k" }) :: any
local random = Random.new()
local calm: { Sound } = {}
local calmIndex = 1
local inDanger = false
-- The chase music: its two mixes, how far up the chase has faded them (0 to 1) and where that's heading, how fast,
-- and how far in the drums are.
local danger: Sound? = nil
local drums: Sound? = nil
local dangerGain = 0
local dangerTarget = 0
local dangerRate = 1
local drumShare = 0

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

-- Starts `sound` as `settings` says, stopping it after Length seconds of the file when there is one.
local function start(sound: Sound, settings: Sounds.Effect, speed: number?, volume: number?)
	local playback = speedOf(settings, speed)
	sound.PlaybackSpeed = playback
	sound.Volume = settings.Volume * (volume or 1)
	sound.TimePosition = settings.Start or 0
	sound:Play()
	local count = (plays[sound] or 0) + 1
	plays[sound] = count
	local length = settings.Length
	if length then
		task.delay(length / playback, function()
			if plays[sound] == count then
				sound:Stop()
			end
		end)
	end
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

local function fadeTo(sound: Sound, volume: number, info: TweenInfo?)
	TweenService:Create(sound, info or FADE, { Volume = volume }):Play()
end

local function playCalm()
	if #calm == 0 then
		return
	end
	local track = calm[calmIndex]
	track.Volume = Sounds.Music.Calm[calmIndex].Volume
	track:Play()
end

-- Every frame while the chase music is up: its fade, the drums' share, and the jump back from the loop's end, keeping
-- the two mixes together.
local function stepDanger(dt: number)
	local under, full = danger, drums
	if not under or not full then
		return
	end
	if dangerGain ~= dangerTarget then
		local move = dt * dangerRate
		dangerGain = if dangerGain < dangerTarget
			then math.min(dangerTarget, dangerGain + move)
			else math.max(dangerTarget, dangerGain - move)
		if dangerGain <= 0 then
			under:Stop()
			full:Stop()
		end
	end
	if dangerGain <= 0 then
		return
	end
	local duck = 1 - GameConfig.Chase.UnderscoreDuck * drumShare
	under.Volume = Sounds.Music.Danger.Volume * dangerGain * duck
	full.Volume = Sounds.Music.DangerDrums.Volume * dangerGain * drumShare
	local loop = Sounds.Music.DangerLoop
	if under.TimePosition >= loop.End then
		under.TimePosition = loop.Start
		full.TimePosition = loop.Start
	elseif math.abs(full.TimePosition - under.TimePosition) > 0.08 then
		full.TimePosition = under.TimePosition
	end
end

-- `how`: "Cut" stops the chase music dead, "Quick" fades it fast, anything else fades it gently.
local function setDanger(on: boolean, how: string?)
	if on == inDanger then
		return
	end
	inDanger = on
	local current = calm[calmIndex]
	if on then
		if current then
			fadeTo(current, 0, DANGER_IN)
		end
		local under, full = danger, drums
		if under and full then
			drumShare = 0
			under.TimePosition = 0
			full.TimePosition = 0
			full.Volume = 0
			under:Play()
			full:Play()
		end
		dangerTarget = 1
		dangerRate = 1 / 0.6
	else
		dangerTarget = 0
		dangerRate = if how == "Cut"
			then math.huge
			elseif how == "Quick" then 1 / Sounds.Music.QuickSeconds
			else 1 / Sounds.Music.FadeSeconds
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
	danger = make(Sounds.Music.Danger.Name, Sounds.Music.Danger.Id, 0, "Music", created)
	drums = make(Sounds.Music.DangerDrums.Name, Sounds.Music.DangerDrums.Id, 0, "Music", created)
	trove:Connect(RunService.Heartbeat, stepDanger)
	local ambience = make("Ambience", Sounds.Ambience.Id, Sounds.Ambience.Volume, "Ambience", created)
	ambience.Looped = true
	ambience:Play()
	playCalm()
	-- A lamb lifted onto the head boinks, except a stolen one: its alarm is the chase's (ChaseController).
	trove:Connect(player:GetAttributeChangedSignal("Carrying"), function()
		if player:GetAttribute("Carrying") == true and player:GetAttribute("CarryStolen") ~= true then
			SoundController:Play("Pickup")
		end
	end)
end

function SoundController.Destroy(_self: any)
	trove:Clean()
	table.clear(pools)
	table.clear(calm)
end

-- A 2D effect by its Config/Sounds name, optionally at another speed and a share of its volume.
function SoundController.Play(_self: any, name: string, speed: number?, volume: number?)
	local settings = Sounds.Effects[name]
	local pool = pools[name]
	if not settings or not pool or not ready(name, settings) then
		return
	end
	local sound = pool.Sounds[pool.Next]
	pool.Next = pool.Next % #pool.Sounds + 1
	start(sound, settings, speed, volume)
end

local function aim(sound: Sound, settings: Sounds.Effect)
	sound.RollOffMinDistance = settings.Near or 10
	sound.RollOffMaxDistance = settings.Range or Sounds.DefaultRange
end

-- A 3D effect at a part or attachment, heard within its Range.
function SoundController.PlayAt(_self: any, name: string, where: Instance, speed: number?)
	local settings = Sounds.Effects[name]
	if not settings or not ready(`{name}@`, settings) then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = settings.Id
	sound.SoundGroup = groups[settings.Group or "Effects"]
	aim(sound, settings)
	sound.Parent = where
	start(sound, settings, speed)
	task.delay(8, function()
		sound:Destroy()
	end)
end

-- A 3D effect from a part that plays it again and again (a god's steps and voice): its copies stay on the part and
-- go with it.
function SoundController.PlayOn(_self: any, name: string, part: BasePart, speed: number?, volume: number?)
	local settings = Sounds.Effects[name]
	if not settings then
		return
	end
	local byName = emitters[part]
	if not byName then
		byName = {}
		emitters[part] = byName
	end
	local pool = byName[name]
	if not pool then
		local copies: { Sound } = {}
		for index = 1, settings.Voices or 1 do
			local sound = make(`{name}{index}`, settings.Id, settings.Volume, settings.Group or "Effects", part)
			aim(sound, settings)
			table.insert(copies, sound)
		end
		pool = { Sounds = copies, Next = 1 }
		byName[name] = pool
	end
	local sound = pool.Sounds[pool.Next]
	pool.Next = pool.Next % #pool.Sounds + 1
	start(sound, settings, speed, volume)
end

-- The chase music: on while a god is after the player. Off, `how` is "Cut" (caught), "Quick" (got away) or nil.
function SoundController.SetDanger(_self: any, on: boolean, how: string?)
	setDanger(on, how)
end

-- How scary the chase is now (ChaseFeel's level): it brings in the chase music's drums.
function SoundController.SetDangerLevel(_self: any, level: number)
	drumShare = ChaseFeel.Drums(level)
end

return SoundController
