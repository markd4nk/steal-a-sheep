--!strict

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Remotes = require(ReplicatedStorage.Remotes)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Buttons = require(script.Parent.Parent.Buttons)
local Panel = require(script.Parent.Parent.Panel)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The player's own settings (DESIGN/ui/mockups/settings.html, A): Music and Sound effects in four steps each (- and +,
-- the steps lit up to the level, the button greyed at either end) and Reduce motion, opened from a gear in Roblox's top
-- bar beside its own buttons (SettingsGear, TopbarSafeInsets). The server saves each change (SetSetting) and mirrors it
-- as an attribute; the menu shows what it asked for at once and the saved value once it arrives. Gamepad: B closes.
local Settings = {}

local Color = Theme.Color
local WIDTH = 480
local PANEL_HEIGHT = 300
local ROW_HEIGHT = 58
local PIPS_WIDTH = 112
local PIP_GAP = 3
local GEAR_GUI = "SettingsGear"
local GEAR_GAP = 12 -- points between Roblox's buttons and the gear
local BACK_ACTION = "SettingsBack"

type Trove = typeof(Trove.new())
type VolumeRow = { Setting: PlayerSettings.Name, Minus: TextButton, Plus: TextButton, Pips: { Frame } }
type ToggleRow = { Setting: PlayerSettings.Name, Button: TextButton }

local VOLUMES: { { Row: string, Title: string, Setting: PlayerSettings.Name } } = {
	{ Row = "MusicRow", Title = "Music", Setting = "MusicVolume" },
	{ Row = "SoundsRow", Title = "Sound effects", Setting = "SfxVolume" },
}
local TOGGLES: { { Row: string, Title: string, Setting: PlayerSettings.Name } } = {
	{ Row = "MotionRow", Title = "Reduce motion", Setting = "ReduceMotion" },
}

-- A row: the setting's name on the left, its Controls on the right.
local function row(page: Instance, name: string, title: string, order: number): Frame
	local tile = UIKit.Tile(page, name, UDim2.new(1, 0, 0, ROW_HEIGHT))
	tile.LayoutOrder = order
	UIKit.Padding(tile, 16, 10, 0, 0)
	local controls = UIKit.Frame(tile, "Controls", UDim2.new(0, 230, 1, 0))
	controls.AnchorPoint = Vector2.new(1, 0)
	controls.Position = UDim2.fromScale(1, 0)
	UIKit.List(controls, true, 8, Enum.HorizontalAlignment.Right).VerticalAlignment = Enum.VerticalAlignment.Center
	UIKit.Text(tile, "TitleLabel", title, 24, Color.Snow, UDim2.new(1, -240, 1, 0), {
		Stroke = Color.Line,
		AlignX = Enum.TextXAlignment.Left,
		Fit = true,
	})
	return controls
end

-- The volume's steps: a dark well with one pip a step (Pip1 the quietest).
local function pips(parent: Instance): Frame
	local steps = PlayerSettings.Steps()
	local well = UIKit.Frame(parent, "Pips", UDim2.fromOffset(PIPS_WIDTH, 22), Color.Blue950)
	well.BackgroundTransparency = 0
	well.LayoutOrder = 2
	UIKit.Corner(well, 9)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Color.Line
	edge.Thickness = Theme.Line.Normal
	edge.Parent = well
	UIKit.Padding(well, PIP_GAP, PIP_GAP, PIP_GAP, PIP_GAP)
	UIKit.List(well, true, PIP_GAP)
	local width = (PIPS_WIDTH - PIP_GAP * (steps + 1)) / steps
	for step = 1, steps do
		local pip = UIKit.Frame(well, `Pip{step}`, UDim2.new(0, width, 1, 0), Color.Green500)
		pip.BackgroundTransparency = 0
		pip.LayoutOrder = step
		UIKit.Corner(pip, 4)
	end
	return well
end

function Settings.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Settings", "Day", "Settings", nil, false, nil, {
		Accent = "Settings",
		Badge = Theme.Icons.MenuSettings,
		Size = "Medium",
		Width = WIDTH,
	})
	window:SetAttribute("PanelHeight", PANEL_HEIGHT)
	-- The settings are about the player, not their balance: no cash chip in this header.
	local cash = window:FindFirstChild("CashChip", true)
	if cash and cash:IsA("GuiObject") then
		cash.Visible = false
	end
	local page = window:FindFirstChild("Pages") :: Frame
	UIKit.List(page, false, 10)
	for index, spec in VOLUMES do
		local controls = row(page, spec.Row, spec.Title, index)
		UIKit.Button(controls, "MinusButton", "Soft", 44, Theme.ButtonHeight.Row, "-").LayoutOrder = 1
		pips(controls)
		UIKit.Button(controls, "PlusButton", "Soft", 44, Theme.ButtonHeight.Row, "+").LayoutOrder = 3
	end
	for index, spec in TOGGLES do
		local controls = row(page, spec.Row, spec.Title, #VOLUMES + index)
		UIKit.Button(controls, "ToggleButton", "Danger", 120, Theme.ButtonHeight.Row, "Off").LayoutOrder = 1
	end
	UIKit.LightText(window)
	gui.Parent = playerGui
	return gui
end

-- The gear in Roblox's top bar, round and dark like Roblox's own buttons beside it (not a UIKit button, so
-- Buttons.Watch leaves its look alone).
local function gear(playerGui: Instance, trove: Trove): TextButton
	local gui = Instance.new("ScreenGui")
	gui.Name = GEAR_GUI
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
	gui.DisplayOrder = 5
	local button = Instance.new("TextButton")
	button.Name = "GearButton"
	button.Text = ""
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.Position = UDim2.new(0, GEAR_GAP, 0.5, 0)
	button.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
	button.BackgroundTransparency = 0.38
	UIKit.Corner(button)
	local picture = UIKit.Icon(button, "Picture", Theme.Icons.MenuSettings, 34)
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromScale(0.5, 0.5)
	picture.Size = UDim2.fromScale(0.78, 0.78)
	button.Parent = gui
	-- As tall as Roblox's buttons: the bar's height less their margin, 32 to 44 points.
	local function fit()
		local side = math.clamp(gui.AbsoluteSize.Y - 14, 32, 44)
		button.Size = UDim2.fromOffset(side, side)
	end
	trove:Connect(gui:GetPropertyChangedSignal("AbsoluteSize"), fit)
	fit()
	gui.Parent = playerGui
	trove:Add(gui)
	return button
end

function Settings.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local player = Players.LocalPlayer
	local trove = Trove.new()
	local panel = Panel.Bind(gui, trove)
	local window = panel.Window
	local pending: { [string]: number | boolean } = {} -- asked for, not yet mirrored back

	local volumes: { VolumeRow } = {}
	for _, spec in VOLUMES do
		local rowFrame = window:FindFirstChild(spec.Row, true) :: Frame
		local well = rowFrame:FindFirstChild("Pips", true) :: Frame
		local lit: { Frame } = {}
		for step = 1, PlayerSettings.Steps() do
			table.insert(lit, well:FindFirstChild(`Pip{step}`) :: Frame)
		end
		table.insert(volumes, {
			Setting = spec.Setting,
			Minus = rowFrame:FindFirstChild("MinusButton", true) :: TextButton,
			Plus = rowFrame:FindFirstChild("PlusButton", true) :: TextButton,
			Pips = lit,
		})
	end
	local toggles: { ToggleRow } = {}
	for _, spec in TOGGLES do
		local rowFrame = window:FindFirstChild(spec.Row, true) :: Frame
		table.insert(toggles, {
			Setting = spec.Setting,
			Button = rowFrame:FindFirstChild("ToggleButton", true) :: TextButton,
		})
	end

	local function volumeOf(setting: PlayerSettings.Name): number
		local asked = pending[setting]
		return if type(asked) == "number" then asked else PlayerSettings.Volume(player, setting)
	end
	local function isOn(setting: PlayerSettings.Name): boolean
		local asked = pending[setting]
		return if type(asked) == "boolean" then asked else PlayerSettings.IsOn(player, setting)
	end

	local function refresh()
		local step = GameConfig.Settings.VolumeStep
		for _, entry in volumes do
			local value = volumeOf(entry.Setting)
			local level = math.round(value / step)
			for index, pip in entry.Pips do
				pip.BackgroundColor3 = if index <= level then Color.Green500 else Color.Line
				pip.BackgroundTransparency = if index <= level then 0 else 0.6
			end
			Buttons.Set(entry.Minus, if value <= 0 then "Disabled" else "Soft", "-")
			Buttons.Set(entry.Plus, if value >= 1 then "Disabled" else "Soft", "+")
		end
		for _, entry in toggles do
			local on = isOn(entry.Setting)
			Buttons.Set(entry.Button, if on then "Buy" else "Danger", if on then "On" else "Off")
		end
	end

	local function nudge(entry: VolumeRow, direction: number)
		local value = volumeOf(entry.Setting)
		local nextValue = PlayerSettings.Clean(entry.Setting, value + direction * GameConfig.Settings.VolumeStep)
		if nextValue == value then
			return
		end
		pending[entry.Setting] = nextValue
		Remotes.SetSetting:Fire(entry.Setting, nextValue :: number)
		refresh()
	end

	for _, entry in volumes do
		trove:Connect(entry.Minus.Activated, function()
			nudge(entry, -1)
		end)
		trove:Connect(entry.Plus.Activated, function()
			nudge(entry, 1)
		end)
	end
	for _, entry in toggles do
		trove:Connect(entry.Button.Activated, function()
			local on = not isOn(entry.Setting)
			pending[entry.Setting] = on
			Remotes.SetSetting:Fire(entry.Setting, if on then 1 else 0)
			refresh()
		end)
	end
	for _, name in PlayerSettings.Names do
		trove:Connect(player:GetAttributeChangedSignal(PlayerSettings.Attribute(name)), function()
			pending[name] = nil
			if gui.Enabled then
				refresh()
			end
		end)
	end

	local gearButton = gear(player:WaitForChild("PlayerGui"), trove)
	trove:Connect(gearButton.Activated, function()
		if context.Controllers.UIController:IsOpen(gui.Name) then
			context.Close(gui.Name)
		else
			context.Open(gui.Name)
		end
	end)
	if panel.CloseButton then
		trove:Connect(panel.CloseButton.Activated, function()
			context.Close(gui.Name)
		end)
	end

	local function unbind()
		ContextActionService:UnbindAction(BACK_ACTION)
	end

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			refresh()
			panel.Show()
			ContextActionService:BindActionAtPriority(
				BACK_ACTION,
				function(_action: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
					if state == Enum.UserInputState.Begin then
						context.Close(gui.Name)
					end
					return Enum.ContextActionResult.Sink
				end,
				false,
				Enum.ContextActionPriority.High.Value,
				Enum.KeyCode.ButtonB
			)
			if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
				GuiService.SelectedObject = volumes[1].Plus
			end
		end,
		Close = function(_self: Types.Screen)
			unbind()
			local selected = GuiService.SelectedObject
			if selected and selected:IsDescendantOf(gui) then
				GuiService.SelectedObject = nil
			end
			panel.Hide(function() end)
		end,
		Destroy = function(_self: Types.Screen)
			unbind()
			trove:Clean()
			gui:Destroy()
		end,
		Notify = function(_self: Types.Screen, message: string, kind: string)
			panel.Status(message, Style.NoticeKindOf(kind))
		end,
	}
end

return Settings
