--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

-- Studio-only test tools: a DEBUG button on the left edge opens buttons for DebugService's commands. UIController
-- mounts it only in Studio. Unlike the game's screens it makes its own ScreenGui in code, so a new game has it on its
-- first Play with nothing to build; players never see it. Add a row to BUTTONS for each command a game adds.
type Button = {
	Text: string,
	Command: string,
	Value: number?,
	UsesId: boolean?, -- sends the number typed in the id box
	Confirm: boolean?, -- needs a second click
	Toggle: string?, -- a player attribute that says it's on; the click sends 0 to turn it off, 1 to turn it on
}

local BUTTONS: { Button } = {
	{ Text = "Coins +1,000", Command = "AddCash", Value = 1000 },
	{ Text = "Coins +100,000", Command = "AddCash", Value = 100000 },
	{ Text = "Climb Power +100", Command = "AddClimb", Value = 100 },
	{ Text = "Climb Power +10,000", Command = "AddClimb", Value = 10000 },
	{ Text = "Steal from tier (id)", Command = "Steal", UsesId = true },
	{ Text = "Give a sheep of tier (id)", Command = "GiveSheep", UsesId = true },
	{ Text = "Grow every lamb", Command = "GrowAll" },
	{ Text = "Unlock every tier", Command = "UnlockAll" },
	{ Text = "Reset free gift", Command = "ResetGift" },
	{ Text = "Speed x5", Command = "SetSpeed", Value = 5 },
	{ Text = "Speed normal", Command = "SetSpeed", Value = 1 },
	{ Text = "Wipe save", Command = "WipeSave", Confirm = true },
	{ Text = "Ignore owned passes", Command = "SetIgnorePasses", Toggle = "DebugIgnorePasses" },
	{ Text = "Grant product (id)", Command = "GrantProduct", UsesId = true },
	{ Text = "Grant pass (id)", Command = "GrantPass", UsesId = true },
}

local WIDTH = 240
local ROW = 30
local GAP = 6
local TOGGLE_WIDTH = 64
local DARK = Color3.fromRGB(32, 32, 38)
local MID = Color3.fromRGB(58, 58, 68)
local LIGHT = Color3.fromRGB(235, 235, 240)
local GOLD = Color3.fromRGB(255, 200, 60)

local DebugPanel = {}

local function round(parent: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = parent
end

local function newButton(name: string, text: string, order: number, parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.Name = name -- the command, so tests can click it by path (PlayerGui.DebugPanel.Panel.AddCash)
	button.LayoutOrder = order
	button.Size = UDim2.new(1, 0, 0, ROW)
	button.BackgroundColor3 = MID
	button.TextColor3 = LIGHT
	button.TextSize = 14
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = parent
	round(button)
	return button
end

function DebugPanel.Build(playerGui: Instance): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "DebugPanel"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	return gui
end

function DebugPanel.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local player = Players.LocalPlayer
	local trove = Trove.new()

	local toggle = Instance.new("TextButton")
	toggle.Name = "Toggle"
	toggle.AnchorPoint = Vector2.new(0, 0.5)
	toggle.Position = UDim2.new(0, GAP, 0.5, 0)
	toggle.Size = UDim2.fromOffset(TOGGLE_WIDTH, ROW)
	toggle.BackgroundColor3 = DARK
	toggle.TextColor3 = GOLD
	toggle.TextSize = 14
	toggle.Text = "DEBUG"
	toggle.Parent = gui
	round(toggle)

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, GAP * 2 + TOGGLE_WIDTH, 0.5, 0)
	panel.Size = UDim2.fromOffset(WIDTH, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = DARK
	panel.Visible = false
	panel.Parent = gui
	round(panel)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, GAP)
	padding.PaddingBottom = UDim.new(0, GAP)
	padding.PaddingLeft = UDim.new(0, GAP)
	padding.PaddingRight = UDim.new(0, GAP)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, GAP)
	layout.Parent = panel

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.LayoutOrder = 0
	status.Size = UDim2.new(1, 0, 0, 0)
	status.AutomaticSize = Enum.AutomaticSize.Y
	status.BackgroundTransparency = 1
	status.TextColor3 = GOLD
	status.TextSize = 13
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = panel

	local idBox = Instance.new("TextBox")
	idBox.Name = "Id"
	idBox.LayoutOrder = 1
	idBox.Size = UDim2.new(1, 0, 0, ROW)
	idBox.BackgroundColor3 = LIGHT
	idBox.TextColor3 = DARK
	idBox.TextSize = 14
	idBox.PlaceholderText = "Product or pass id"
	idBox.Text = ""
	idBox.ClearTextOnFocus = false
	idBox.Parent = panel
	round(idBox)

	local function setStatus(text: string?)
		local blank = if player:GetAttribute("DebugBlankProfile") == true then "Blank save: nothing is saved" else nil
		local lines = {}
		for _, line in { blank, text } do
			if line then
				table.insert(lines, line)
			end
		end
		status.Text = table.concat(lines, "\n")
		status.Visible = #lines > 0
	end

	local rows: { [TextButton]: Button } = {}
	local armed: TextButton? = nil
	local busy = false

	local function label(button: TextButton, spec: Button)
		if armed == button then
			button.Text = `Click again: {string.lower(spec.Text)}`
		elseif spec.Toggle then
			button.Text = `{spec.Text}: {if player:GetAttribute(spec.Toggle) == true then "on" else "off"}`
		else
			button.Text = spec.Text
		end
	end

	local function relabel()
		for button, spec in rows do
			label(button, spec)
		end
	end

	local function run(button: TextButton, spec: Button)
		if busy then
			return
		end
		if spec.Confirm and armed ~= button then
			armed = button
			relabel()
			return
		end
		armed = nil
		local value = spec.Value
		if spec.UsesId then
			value = tonumber(idBox.Text)
			if not value then
				relabel()
				setStatus("Type an id in the box first.")
				return
			end
		elseif spec.Toggle then
			value = if player:GetAttribute(spec.Toggle) == true then 0 else 1
		end
		busy = true
		setStatus(`{spec.Command}...`)
		local callOk, ok, reason = Remotes.Debug:Invoke(spec.Command, value)
		busy = false
		relabel()
		if not callOk then
			setStatus(`{spec.Command}: no answer (rate limit, or the server errored)`)
		elseif ok then
			setStatus(`{spec.Command}: done`)
		else
			setStatus(`{spec.Command}: {reason or "refused"}`)
		end
	end

	for index, spec in BUTTONS do
		local button = newButton(spec.Command, spec.Text, index + 1, panel)
		rows[button] = spec
		label(button, spec)
		trove:Connect(button.Activated, function()
			run(button, spec)
		end)
		if spec.Toggle then
			trove:Connect(player:GetAttributeChangedSignal(spec.Toggle), relabel)
		end
	end

	trove:Connect(toggle.Activated, function()
		panel.Visible = not panel.Visible
		armed = nil
		relabel()
	end)
	trove:Connect(player:GetAttributeChangedSignal("DebugBlankProfile"), function()
		setStatus(nil)
	end)
	setStatus(nil)

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
			gui:Destroy()
		end,
	}
end

return DebugPanel
