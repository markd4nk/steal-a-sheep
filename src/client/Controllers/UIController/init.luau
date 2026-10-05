--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Format = require(ReplicatedStorage.Utils.Format)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Buttons = require(script.Buttons)
local Panel = require(script.Panel)
local Scale = require(script.Scale)
local Types = require(script.Types)

-- Every screen, built at runtime from Shear a Sheep's UI kit (Utils/UIKit, Config/Theme) so the look is the same:
-- the Ranch Studs HUD and the Prize Fleece menus. One modal menu at a time; a menu opened while another is open
-- swaps with it. Notices go to the open menu's bottom edge, or under the HUD's top row.
local screenModules: { [string]: Types.ScreenModule } = {
	Hud = require(script.Screens.Hud),
	Flock = require(script.Screens.Flock),
	Shop = require(script.Screens.Shop),
	Sheepdex = require(script.Screens.Sheepdex),
	Merge = require(script.Screens.Merge),
	Popup = require(script.Screens.Popup),
}
if RunService:IsStudio() then
	screenModules.DebugPanel = require(script.Screens.DebugPanel)
end

local UIController = { Name = "UIController" }

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local screens: { [string]: Types.Screen } = {}
local openScreens: { [string]: boolean } = {}
local pending: { [string]: { [string]: any } | boolean } = {}
local destroyed = false

local function close(name: string)
	pending[name] = nil
	local screen = screens[name]
	if screen and openScreens[name] then
		openScreens[name] = nil
		screen:Close()
	end
end

local function open(name: string, options: { [string]: any }?)
	local screen = screens[name]
	if not screen then
		if screenModules[name] then
			pending[name] = options or true
		else
			warn(`[UIController] No screen named {name}`)
		end
		return
	end
	if screen.Modal then
		local swapping = false
		for other in openScreens do
			if other ~= name and screens[other].Modal then
				swapping = true
				Panel.SetSwapping(true)
				close(other)
			end
		end
		if swapping then
			task.defer(Panel.SetSwapping, false)
		end
		local sound = registry.SoundController
		if sound and not openScreens[name] then
			sound:Play("MenuOpen")
		end
	end
	openScreens[name] = true
	screen:Open(options)
end

local function notify(message: string, kind: string)
	for name in openScreens do
		local screen = screens[name]
		local show = screen.Notify
		if screen.Modal and show then
			show(screen, message, kind)
			return
		end
	end
	local hud = screens.Hud
	local show = hud and hud.Notify
	if hud and show then
		show(hud, message, kind)
	end
end

local function mount(name: string, module: Types.ScreenModule)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local build = module.Build
	if not build then
		return
	end
	local ok, gui = pcall(build, playerGui)
	if not ok or not gui then
		warn(`[UIController] Screen {name} failed to make its ScreenGui: {gui}`)
		return
	end
	if destroyed then
		gui:Destroy()
		return
	end
	gui.ResetOnSpawn = false
	if gui:FindFirstChild("Root") and name ~= "DebugPanel" then
		Scale.Bind(gui, trove, if name == "Hud" then 1.2 else nil)
	end
	trove:Add(Buttons.Watch(gui))
	-- Every menu's header chip shows the player's coins.
	local cashLabel = gui:FindFirstChild("CashLabel", true)
	if cashLabel and cashLabel:IsA("TextLabel") then
		local player = Players.LocalPlayer
		local function showCoins()
			local coins = player:GetAttribute("Coins")
			cashLabel.Text = if type(coins) == "number" then Format.Short(coins) else "..."
		end
		trove:Connect(player:GetAttributeChangedSignal("Coins"), showCoins)
		showCoins()
	end
	local context: Types.Context = {
		Controllers = registry,
		Open = open,
		Close = close,
		Notify = notify,
	}
	local built, screen = pcall(module.new, context, gui)
	if not built then
		warn(`[UIController] Screen {name} failed to build: {screen}`)
		return
	end
	screens[name] = screen
	local requested = pending[name]
	pending[name] = nil
	if screen.StartsOpen or requested then
		open(name, if type(requested) == "table" then requested else nil)
	else
		screen:Close()
	end
end

function UIController.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function UIController.Start(_self: any)
	-- The HUD first, so the menus' notices have somewhere to go.
	local order = { "Hud", "Popup", "Flock", "Shop", "Sheepdex", "Merge", "DebugPanel" }
	task.spawn(function()
		for _, name in order do
			local module = screenModules[name]
			if module and not destroyed then
				mount(name, module)
			end
		end
	end)
end

function UIController.Destroy(_self: any)
	destroyed = true
	for name, screen in screens do
		local ok, message = pcall(screen.Destroy :: any, screen)
		if not ok then
			warn(`[UIController] Screen {name} failed to destroy: {message}`)
		end
	end
	table.clear(screens)
	table.clear(openScreens)
	trove:Clean()
end

function UIController.Open(_self: any, name: string, options: { [string]: any }?)
	open(name, options)
end

function UIController.Close(_self: any, name: string)
	close(name)
end

function UIController.IsOpen(_self: any, name: string): boolean
	return openScreens[name] == true
end

function UIController.IsModalOpen(_self: any): boolean
	for name in openScreens do
		if screens[name] and screens[name].Modal then
			return true
		end
	end
	return false
end

function UIController.Notify(_self: any, message: string, kind: string)
	notify(message, kind)
end

-- A big moment in the middle of the screen (the Popup screen's celebration): a merge, a lamb grown up.
function UIController.Celebrate(_self: any, title: string, line: string)
	local popup = screens.Popup :: any
	if popup and popup.Celebrate then
		popup:Celebrate(title, line)
	end
end

-- The HUD's screen, for controllers that show things on it (the chase banner, the home arrow).
function UIController.Screen(_self: any, name: string): Types.Screen?
	return screens[name]
end

return UIController
