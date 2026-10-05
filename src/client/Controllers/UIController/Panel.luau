--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Motion = require(script.Parent.Motion)
local Scale = require(script.Parent.Scale)
local Style = require(script.Parent.Style)

type Trove = typeof(Trove.new())

export type Panel = {
	Window: Frame,
	Header: Frame?,
	Tabs: Frame?,
	CloseButton: TextButton?,
	CashLabel: TextLabel?,
	-- A notice sliding up over the panel's bottom edge for 2.5 s: "Good", "Rare", or a problem ("Bad" or "Raid": it
	-- shakes, and stands just inside the edge).
	Status: (text: string, kind: Style.NoticeKind) -> (),
	-- The menu opens (pops in over its backdrop) or closes (pops out, then `done`).
	Show: () -> (),
	Hide: (done: () -> ()) -> (),
	-- LB/RB on the tabs and B on the close button while a gamepad plays.
	RefreshKeys: () -> (),
}

-- What every menu's panel (UIKit.MenuGui) does the same way: its size from the safe area, popping in and out, the
-- status notice at its bottom edge, and the gamepad's key hints.
local Panel = {}

-- True while UIController swaps one menu for another: the backdrops hand over at once, so the world doesn't flash
-- through between them.
local swapping = false

-- A problem's words have no pill to hang over the bottom edge, which on a phone is close to the screen's: they stand
-- this far inside the window instead, their foot on the line.
local PROBLEM_LIFT = 14

function Panel.SetSwapping(isSwapping: boolean)
	swapping = isSwapping
end

function Panel.Bind(gui: ScreenGui, trove: Trove): Panel
	local root = gui:FindFirstChild("Root")
	local found = root and root:FindFirstChild("Window")
	assert(found and found:IsA("Frame"), `{gui.Name} has no Root.Window`)
	local window = found :: Frame
	local backdrop = gui:FindFirstChild("Backdrop") :: GuiObject?
	local header = window:FindFirstChild("Header") :: Frame?
	-- Prize Fleece keeps the tabs in their own bar under the header (the Sheep Shop's in it), and the cash in a chip on it.
	local tabs = window:FindFirstChild("Tabs", true) :: Frame?
	local closeButton = if header then header:FindFirstChild("CloseButton", true) :: TextButton? else nil
	local cashLabel = if header then header:FindFirstChild("CashLabel", true) :: TextLabel? else nil
	local statusLabel = window:FindFirstChild("StatusLabel") :: TextLabel?
	local rest = if statusLabel then statusLabel.Position else UDim2.new()
	local restAnchor = if statusLabel then statusLabel.AnchorPoint else Vector2.new(0.5, 0.5)
	local problemRest = UDim2.new(rest.X.Scale, rest.X.Offset, 1, -PROBLEM_LIFT)
	-- Where a problem stands: just inside the bottom edge, or, when the menu asks with its window's ProblemTop (points
	-- under the header, the wolf den's: Mark 2026-10-03), at the top. ProblemShowing is set while one shows, so the
	-- menu can clear room for it.
	local function problemAt(): (UDim2, Vector2)
		local top = window:GetAttribute("ProblemTop")
		local pagesTop = window:GetAttribute("PagesTop")
		if type(top) == "number" and type(pagesTop) == "number" then
			return UDim2.new(rest.X.Scale, rest.X.Offset, 0, pagesTop + top), Vector2.new(0.5, 0)
		end
		return problemRest, Vector2.new(0.5, 1)
	end
	local statusToken = 0
	local hideToken = 0
	local statusQueue: { { Text: string, Kind: Style.NoticeKind } } = {}
	local statusShowing = false
	if statusLabel then
		statusLabel.Visible = false
	end
	Scale.Menu(gui, window, trove)

	local function display(text: string, kind: Style.NoticeKind)
		local label = statusLabel
		if not label then
			return
		end
		statusShowing = true
		statusToken += 1
		local token = statusToken
		label.Text = text
		Style.PaintNotice(label, kind)
		local problem = Style.IsProblem(kind)
		local at, anchor = rest, restAnchor
		if problem then
			at, anchor = problemAt()
		end
		label.AnchorPoint = anchor
		window:SetAttribute("ProblemShowing", if problem then true else nil)
		Motion.NoticeIn(label, at)
		if problem then
			task.delay(Theme.Motion.NoticeIn.Time, function()
				if statusToken == token then
					Motion.Shake(label)
				end
			end)
		end
		task.delay(GameConfig.Ui.NoticeSeconds, function()
			if statusToken ~= token then
				return
			end
			local nextStatus = table.remove(statusQueue, 1)
			if nextStatus then
				display(nextStatus.Text, nextStatus.Kind)
				return
			end
			Motion.NoticeOut(label, at, function()
				if statusToken == token then
					statusShowing = false
					label.Visible = false
					window:SetAttribute("ProblemShowing", nil)
				end
			end)
		end)
	end

	-- A problem answers what the player just did, so it shows at once; good and rare news wait their turn (a
	-- mutation's gold "turned Gold!" and then "New in your Sheepdex!" both get seen).
	local function status(text: string, kind: Style.NoticeKind)
		if statusShowing and not Style.IsProblem(kind) then
			table.insert(statusQueue, { Text = text, Kind = kind })
			while #statusQueue > GameConfig.Ui.NoticeQueue do
				table.remove(statusQueue, 1)
			end
			return
		end
		display(text, kind)
	end

	local function refreshKeys()
		local gamepad = UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
		if tabs then
			for _, descendant in tabs:GetDescendants() do
				if descendant.Name == "KeyChip" and descendant:IsA("GuiObject") then
					descendant.Visible = gamepad
				end
			end
		end
		if closeButton then
			local key = closeButton:FindFirstChild("KeyLabel", true)
			local icon = closeButton:FindFirstChild("Icon", true)
			if key and key:IsA("GuiObject") then
				key.Visible = gamepad
			end
			if icon and icon:IsA("GuiObject") then
				icon.Visible = not gamepad
			end
		end
	end
	trove:Connect(UserInputService:GetPropertyChangedSignal("PreferredInput"), refreshKeys)
	refreshKeys()

	return {
		Window = window,
		Header = header,
		Tabs = tabs,
		CloseButton = closeButton,
		CashLabel = cashLabel,
		Status = status,
		Show = function()
			hideToken += 1
			gui.Enabled = true
			refreshKeys()
			if swapping and backdrop then
				Motion.PopIn(window, nil)
				backdrop.BackgroundTransparency = Theme.Motion.Backdrop
			else
				Motion.PopIn(window, backdrop)
			end
		end,
		Hide = function(done: () -> ())
			hideToken += 1
			local token = hideToken
			table.clear(statusQueue)
			if swapping and backdrop then
				backdrop.BackgroundTransparency = 1
			end
			Motion.PopOut(window, if swapping then nil else backdrop, function()
				if hideToken == token then
					gui.Enabled = false
					done()
				end
			end)
		end,
		RefreshKeys = refreshKeys,
	}
end

return table.freeze(Panel)
