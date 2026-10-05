--!strict

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)

type Trove = typeof(Trove.new())

-- One UIScale for the whole UI (UI_SPEC 3.3): sizes are points, and a phone held sideways (390 pt short side) is 1.
-- Each ScreenGui's content sits in a Root frame with a UIScale named Scale; Root is 1/scale of the screen so, scaled,
-- it covers it exactly. Menus are sized from the safe area, and the HUD's top row sits in Roblox's top bar row.
local Scale = {
	Changed = Signal.new() :: Signal.Signal<number>,
}

local current = 1
local watching: RBXScriptConnection? = nil

local function compute(): number
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(844, 390)
	local short = math.min(viewport.X, viewport.Y)
	local config = Theme.Scale
	local value = math.clamp(1 + (short - config.Base) * config.PerPoint, config.Min, config.Max)
	if GuiService:IsTenFootInterface() then
		value *= config.TV
	end
	return value
end

local function refresh()
	local value = compute()
	if math.abs(value - current) > 1e-4 then
		current = value
		Scale.Changed:Fire(value)
	end
end

local function watch()
	if watching then
		return
	end
	current = compute()
	local camera = workspace.CurrentCamera
	if camera then
		watching = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
	end
end

-- The scale right now.
function Scale.Current(): number
	watch()
	return current
end

-- A computer: no touch screen, and not a console on a TV.
local function onComputer(): boolean
	return not UserInputService.TouchEnabled and not GuiService:IsTenFootInterface()
end

-- The scale `instance`'s screen is drawn at: the one scale, times what its screen asked for on a computer (Bind).
-- Points in a screen's Root are pixels divided by this.
function Scale.Of(instance: Instance): number
	watch()
	local gui = if instance:IsA("ScreenGui") then instance else instance:FindFirstAncestorWhichIsA("ScreenGui")
	local root = if gui then gui:FindFirstChild("Root") else nil
	local uiScale = if root then root:FindFirstChild("Scale") else nil
	return if uiScale and uiScale:IsA("UIScale") and uiScale.Scale > 0 then uiScale.Scale else current
end

-- Fits a screen's Root to the scale, now and whenever the screen changes size. `computer` draws it that much bigger
-- on a computer (the HUD's buttons looked small on a 1080p screen at the one scale).
function Scale.Bind(gui: ScreenGui, trove: Trove, computer: number?): GuiObject?
	watch()
	local found = gui:FindFirstChild("Root")
	local uiScale = found and found:FindFirstChild("Scale")
	if not found or not found:IsA("GuiObject") or not uiScale or not uiScale:IsA("UIScale") then
		warn(`[UIController] {gui.Name} has no Root frame with a UIScale named Scale`)
		return nil
	end
	local root = found :: GuiObject
	local scaler = uiScale :: UIScale
	local function drawn(): number
		return if computer and onComputer() then current * computer else current
	end
	-- Text that shrinks to fit is capped in screen pixels, which a UIScale doesn't touch: scale the caps too.
	local function fitText(instance: Instance)
		if instance:IsA("UITextSizeConstraint") then
			local most = instance:GetAttribute("MaxPoints")
			local least = instance:GetAttribute("MinPoints")
			if type(most) == "number" then
				instance.MaxTextSize = math.max(1, math.floor(most * drawn() + 0.5))
			end
			if type(least) == "number" then
				instance.MinTextSize = math.max(1, math.floor(least * drawn() + 0.5))
			end
		end
	end
	local function apply()
		local scale = drawn()
		scaler.Scale = scale
		root.Size = UDim2.fromScale(1 / scale, 1 / scale)
		for _, descendant in gui:GetDescendants() do
			fitText(descendant)
		end
	end
	-- Roblox doesn't measure auto-sized text again when a UIScale changes, so after a change (the window resized)
	-- labels keep their old widths and clip. Switching their AutomaticSize off for a frame measures them afresh.
	local function remeasure()
		local sized: { [GuiObject]: Enum.AutomaticSize } = {}
		for _, descendant in gui:GetDescendants() do
			if descendant:IsA("GuiObject") and descendant.AutomaticSize ~= Enum.AutomaticSize.None then
				sized[descendant] = descendant.AutomaticSize
				descendant.AutomaticSize = Enum.AutomaticSize.None
			end
		end
		RunService.Heartbeat:Wait()
		for object, mode in sized do
			if object.Parent then
				object.AutomaticSize = mode
			end
		end
	end
	trove:Connect(gui.DescendantAdded, fitText)
	trove:Add(Scale.Changed:Connect(function()
		apply()
		task.spawn(remeasure)
	end))
	apply()
	return root
end

-- A menu's window. A Prize Fleece panel (PanelWidth and PanelHeight attributes, UIKit.Panel) is its own size, up to
-- the safe area's height minus a margin and its width minus 24, and on a screen too short for it (a phone held
-- sideways) its picture tucks into the header so it stays clear of Roblox's buttons. An older window: the safe area's
-- height minus a margin, up to 404 pt, and 2.35 times as wide, up to 760 pt. A `MaxWidth` attribute narrows either.
-- The ScreenGui keeps to the safe area (CoreUISafeInsets), so its size is the safe area.
function Scale.Menu(gui: ScreenGui, window: GuiObject, trove: Trove)
	local menu = Theme.Menu
	local fleece = Theme.Fleece
	local badge = window:FindFirstChild("Badge")
	local header = window:FindFirstChild("Header")
	local headerPadding = if header then header:FindFirstChildOfClass("UIPadding") else nil
	local function apply()
		local safe = gui.AbsoluteSize / current
		local maxWidth = window:GetAttribute("MaxWidth")
		local widest = if type(maxWidth) == "number" then maxWidth else math.huge
		local panelWidth = window:GetAttribute("PanelWidth")
		local panelHeight = window:GetAttribute("PanelHeight")
		if type(panelWidth) == "number" and type(panelHeight) == "number" then
			local room = safe.Y - menu.Margin - fleece.Lip
			local fit = 1
			local height = math.min(room, panelHeight)
			if height < fleece.CompactHeight then
				height = math.min(fleece.CompactHeight, panelHeight)
				fit = math.max(room, 1) / height
			end
			local width = math.min(panelWidth, widest, (safe.X - menu.SideMargin) / fit)
			window.Size = UDim2.fromOffset(math.floor(width), math.floor(height))
			-- Motion.PopIn and PopOut scale the window by its Fit; one already open takes the new one now.
			local before = window:GetAttribute("Fit")
			window:SetAttribute("Fit", fit)
			local pop = window:FindFirstChild("Pop")
			if pop and pop:IsA("UIScale") and type(before) == "number" and math.abs(pop.Scale - before) < 1e-3 then
				pop.Scale = fit
			end
			local compact = safe.Y < panelHeight + fleece.Badge * 0.5
			if badge and badge:IsA("GuiObject") then
				local side = if compact then fleece.BadgeCompact else fleece.Badge
				badge.Size = UDim2.fromOffset(side, side)
				badge.Position = if compact
					then UDim2.fromOffset(side / 2 - 6, side / 2 - 6)
					else UDim2.fromOffset(side / 2 - 16, side / 2 - 22)
			end
			if headerPadding and badge and badge:IsA("GuiObject") and badge.Visible then
				headerPadding.PaddingLeft = UDim.new(0, if compact then 70 else 80)
			end
			return
		end
		local height = math.min(safe.Y - menu.Margin, menu.MaxHeight)
		local width = math.min(height * menu.Aspect, widest, safe.X - menu.SideMargin)
		window.Size = UDim2.fromOffset(math.floor(width), math.floor(height))
	end
	trove:Connect(gui:GetPropertyChangedSignal("AbsoluteSize"), apply)
	trove:Add(Scale.Changed:Connect(apply))
	apply()
end

-- The HUD's top row in the row of Roblox's own top bar: as wide as the screen and vertically centred in the row. Its
-- pieces are anchored in it: the sheep chip in the middle and the cash and gear at the right edge, clear of Roblox's
-- buttons at the left. Returns where the rest of the HUD may start, in points from the top of `root`, and where the
-- row ends, in pixels from the top of the screen, through `onBelow`.
function Scale.TopBar(gui: ScreenGui, root: GuiObject, topBar: GuiObject, trove: Trove, onBelow: (number, number) -> ())
	local function apply()
		local inset = GuiService.TopbarInset
		-- AbsolutePosition counts from below the GUI inset; TopbarInset counts from the top of the screen.
		local origin = gui.AbsolutePosition + GuiService:GetGuiInset()
		local centreY = (inset.Min.Y + inset.Max.Y) / 2 - origin.Y
		local rowBottom = inset.Max.Y - origin.Y
		local scale = Scale.Of(root)
		local height = topBar.AbsoluteSize.Y / scale
		-- Drawn bigger (a computer), the row is taller than Roblox's and hangs from the top of the screen, so it keeps
		-- room above for the cash's bill, which stands out of the row.
		local margin = if scale > current + 1e-3 then 9 else 4
		local middle = math.max(centreY / scale, height / 2 + margin)
		topBar.AnchorPoint = Vector2.new(0, 0.5)
		topBar.Position = UDim2.fromOffset(0, middle)
		onBelow(math.max(rowBottom / scale, middle + height / 2) + 8, origin.Y + (middle + height / 2) * scale)
	end
	trove:Connect(GuiService:GetPropertyChangedSignal("TopbarInset"), apply)
	trove:Connect(topBar:GetPropertyChangedSignal("AbsoluteSize"), apply)
	trove:Connect(root:GetPropertyChangedSignal("AbsoluteSize"), apply)
	trove:Add(Scale.Changed:Connect(apply))
	apply()
end

return table.freeze(Scale)
