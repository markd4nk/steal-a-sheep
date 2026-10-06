--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Each player's own settings (music and effects volume, Reduce Motion): saved in `Settings`, mirrored as
-- `Setting<Name>` attributes for their client, changed through SetSetting (Shear a Sheep's SettingsService). They only
-- ever affect the player who sets them, so the client's word is fine once it's cleaned up.
local SettingsService = { Name = "SettingsService" }

local registry: Lifecycle.Registry = {}
local trove = Trove.new()

-- The save's settings, made if it has none (Reconcile adds them on load; a wiped save may not have them yet).
local function settingsOf(data: any): { [string]: any }
	if type(data.Settings) ~= "table" then
		data.Settings = PlayerSettings.Defaults()
	end
	return data.Settings
end

local function mirror(player: Player, settings: { [string]: any })
	for _, name in PlayerSettings.Names do
		player:SetAttribute(PlayerSettings.Attribute(name), settings[name])
	end
end

local function set(player: Player, name: PlayerSettings.Name, value: number)
	local data = registry.DataService:GetData(player)
	if not data then
		return
	end
	local settings = settingsOf(data)
	local clean = PlayerSettings.Clean(name, value)
	if settings[name] == clean then
		return
	end
	settings[name] = clean
	player:SetAttribute(PlayerSettings.Attribute(name), clean)
end

function SettingsService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function SettingsService.Start(_self: any)
	trove:Add(Remotes.SetSetting:Connect(set))
	trove:Add(registry.DataService:ObserveLoaded(function(player: Player, data: any)
		mirror(player, settingsOf(data))
	end))
end

function SettingsService.Destroy(_self: any)
	trove:Clean()
end

return SettingsService
