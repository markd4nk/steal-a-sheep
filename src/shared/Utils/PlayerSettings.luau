--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)

export type Name = "MusicVolume" | "SfxVolume" | "ReduceMotion" | "LowGraphics"
export type Values = {
	MusicVolume: number,
	SfxVolume: number,
	ReduceMotion: boolean,
	LowGraphics: boolean,
}

-- The player's own settings (the Settings menu): music and effects volume, Reduce Motion and Low Graphics (kept
-- from Shear a Sheep; nothing in this game reads it yet, so the menu leaves it out). Saved as `Settings` and
-- mirrored on the player as `Setting<Name>` attributes; everything that honours one reads it here. Volumes are 0 to 1
-- in GameConfig.Settings.VolumeStep steps; the other two are on or off. The client sends toggles as 1 and 0.
local PlayerSettings = {}

local NAMES: { Name } = { "MusicVolume", "SfxVolume", "ReduceMotion", "LowGraphics" }
PlayerSettings.Names = table.freeze(NAMES)

-- The names as plain strings, for the remote's guard.
function PlayerSettings.NameList(): { string }
	local list: { string } = {}
	for _, name in NAMES do
		table.insert(list, name)
	end
	return list
end

local TOGGLES: { [string]: boolean } = { ReduceMotion = true, LowGraphics = true }

function PlayerSettings.IsToggle(name: string): boolean
	return TOGGLES[name] == true
end

function PlayerSettings.Attribute(name: string): string
	return `Setting{name}`
end

-- How many steps a volume has above silent (4 at a quarter a step).
function PlayerSettings.Steps(): number
	return math.round(1 / GameConfig.Settings.VolumeStep)
end

function PlayerSettings.Defaults(): Values
	local defaults = GameConfig.Settings.Defaults
	return {
		MusicVolume = defaults.MusicVolume,
		SfxVolume = defaults.SfxVolume,
		ReduceMotion = defaults.ReduceMotion,
		LowGraphics = defaults.LowGraphics,
	}
end

-- A value the client sent, made safe to save: a volume rounded to a step and kept within 0 to 1, a toggle from 1/0.
function PlayerSettings.Clean(name: Name, value: number): number | boolean
	if TOGGLES[name] then
		return value >= 0.5
	end
	local step = GameConfig.Settings.VolumeStep
	return math.clamp(math.round(value / step) * step, 0, 1)
end

-- Whether a saved Settings table has the right shape (fields may be missing; Reconcile fills them).
function PlayerSettings.IsValid(settings: any): boolean
	if type(settings) ~= "table" then
		return false
	end
	for key, value in settings do
		if type(key) ~= "string" then
			return false
		end
		if TOGGLES[key] then
			if type(value) ~= "boolean" then
				return false
			end
		elseif key == "MusicVolume" or key == "SfxVolume" then
			if type(value) ~= "number" or value ~= value or value < 0 or value > 1 then
				return false
			end
		end
	end
	return true
end

-- A volume setting on `player` (the default until their data loads).
function PlayerSettings.Volume(player: Player, name: Name): number
	local value = player:GetAttribute(PlayerSettings.Attribute(name))
	if type(value) == "number" then
		return value
	end
	return (PlayerSettings.Defaults() :: any)[name]
end

-- A toggle on `player` (the default until their data loads).
function PlayerSettings.IsOn(player: Player, name: Name): boolean
	local value = player:GetAttribute(PlayerSettings.Attribute(name))
	if type(value) == "boolean" then
		return value
	end
	return (PlayerSettings.Defaults() :: any)[name] == true
end

-- Shortcuts for the local player, for effects deciding whether to play (clients only).
function PlayerSettings.ReduceMotion(): boolean
	local player = game:GetService("Players").LocalPlayer
	return player ~= nil and PlayerSettings.IsOn(player, "ReduceMotion")
end

function PlayerSettings.LowGraphics(): boolean
	local player = game:GetService("Players").LocalPlayer
	return player ~= nil and PlayerSettings.IsOn(player, "LowGraphics")
end

return table.freeze(PlayerSettings)
