--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Theme = require(ReplicatedStorage.Config.Theme)
local Animate = require(script.Parent.Motion)

type Kind = Theme.ButtonKind

local Motion = Theme.Motion
local Color = Theme.Color

-- Every UIKit button's behaviour and state: the squish when pressed, the hover on PC, and which of the eight kinds it
-- shows (UI_SPEC 1.4). Screens never write a button's colours or text directly; they ask for a kind here.
local Buttons = {}

type State = {
	Kind: Kind,
	Hovered: boolean,
	Loading: boolean,
	DotsThread: thread?,
}

local states: { [GuiButton]: State } = setmetatable({}, { __mode = "k" }) :: any
local bound: { [GuiButton]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local shakes: { [GuiButton]: number } = setmetatable({}, { __mode = "k" }) :: any
local shaded: { [GuiButton]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function face(button: GuiButton): Frame?
	local found = button:FindFirstChild("Face")
	return if found and found:IsA("Frame") then found else nil
end

local function shadow(frame: Instance, name: string): UIShadow?
	local found = frame:FindFirstChild(name)
	return if found and found:IsA("UIShadow") then found else nil
end

local function stateOf(button: GuiButton): State
	local state = states[button]
	if not state then
		local kind = button:GetAttribute("Kind")
		state = {
			Kind = if type(kind) == "string" and Theme.Button[kind :: Kind] then kind :: Kind else "Action",
			Hovered = false,
			Loading = false,
			DotsThread = nil,
		}
		states[button] = state
	end
	return state
end

local function brighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

-- Paints the face, lip, outline and labels for the button's kind, brighter while hovered.
local function paint(button: GuiButton)
	local frame = face(button)
	if not frame then
		return
	end
	local state = stateOf(button)
	local look = Theme.Button[state.Kind]
	local faceColor = if state.Hovered then brighten(look.Face, Motion.HoverBrighten) else look.Face
	frame.BackgroundColor3 = faceColor
	local lip = shadow(frame, "Lip")
	local lipRing = shadow(frame, "LipRing")
	local ring = shadow(frame, "Ring")
	local flat = look.Lip == nil
	if lip then
		lip.Color = look.Lip or look.Face
		lip.Enabled = not flat
	end
	if lipRing then
		lipRing.Color = look.Outline
		lipRing.Enabled = not flat
	end
	if ring then
		ring.Color = look.Outline
	end
	local shine = frame:FindFirstChild("Shine")
	if shine and shine:IsA("GuiObject") then
		shine.Visible = not flat
	end
	-- Flat kinds (locked, disabled) and the snow Soft button have no studs. The image is set here too, so faces built
	-- before the studs were uploaded pick them up.
	local studs = frame:FindFirstChild("Studs")
	if studs and studs:IsA("ImageLabel") then
		studs.Image = Theme.Studs.Image
		studs.Visible = not flat and state.Kind ~= "Soft" and Theme.Studs.Image ~= ""
	end
	for _, name in { "Label", "ValueLabel", "SubLabel" } do
		local label = frame:FindFirstChild(name, true)
		if label and label:IsA("TextLabel") then
			label.TextColor3 = look.Label
			local stroke = label:FindFirstChild("TextStroke")
			if stroke and stroke:IsA("UIStroke") then
				stroke.Color = look.LabelStroke or look.Label
				stroke.Enabled = look.LabelStroke ~= nil and name ~= "SubLabel"
			end
		end
	end
	local icon = frame:FindFirstChild("Icon", true)
	if icon and icon:IsA("ImageLabel") and icon:GetAttribute("Tinted") == true then
		icon.ImageColor3 = look.Label
	end
	local dots = frame:FindFirstChild("Dots")
	if dots then
		for _, dot in dots:GetChildren() do
			if dot:IsA("Frame") then
				dot.BackgroundColor3 = if look.LabelStroke then Color.Snow else look.Label
			end
		end
	end
end

local function textLabel(button: GuiButton, name: string): TextLabel?
	local found = button:FindFirstChild(name, true)
	return if found and found:IsA("TextLabel") then found else nil
end

-- The dots bob one after another while a request is out. One worker a button: a repaint that turns them off and on
-- again before it next wakes (Set, then Loading) keeps it going in step, rather than starting another beside it.
local function runDots(button: GuiButton, state: State)
	local running = state.DotsThread
	if running and coroutine.status(running) ~= "dead" then
		return
	end
	local frame = face(button)
	local dots = frame and frame:FindFirstChild("Dots")
	if not dots then
		return
	end
	state.DotsThread = task.spawn(function()
		local step = 0
		while state.Loading and button.Parent do
			step = step % 3 + 1
			for index = 1, 3 do
				local dot = dots:FindFirstChild(`Dot{index}`)
				if dot and dot:IsA("Frame") then
					dot.Position = UDim2.fromOffset(0, if index == step then -4 else 0)
				end
			end
			task.wait(Motion.Dots)
		end
	end)
end

-- Shows a kind, with the words and an optional line under them ("Need $3.1K more"). Hides the dots.
function Buttons.Set(button: GuiButton, kind: Kind, text: string, subText: string?)
	local state = stateOf(button)
	state.Kind = kind
	button:SetAttribute("Kind", kind)
	local label = textLabel(button, "Label")
	if label then
		label.Text = text
	end
	local sub = textLabel(button, "SubLabel")
	if sub then
		sub.Text = subText or ""
		sub.Visible = subText ~= nil and subText ~= ""
	end
	Buttons.Loading(button, false)
	paint(button)
end

-- The button's kind right now.
function Buttons.Kind(button: GuiButton): Kind
	return stateOf(button).Kind
end

-- Keeps the colour, hides the words, shows three dots; the screen ignores taps until the server answers.
function Buttons.Loading(button: GuiButton, isLoading: boolean)
	local state = stateOf(button)
	local frame = face(button)
	if not frame or state.Loading == isLoading then
		return
	end
	state.Loading = isLoading
	local content = frame:FindFirstChild("Content")
	local value = frame:FindFirstChild("Value")
	local dots = frame:FindFirstChild("Dots")
	if content and content:IsA("GuiObject") then
		content.Visible = not isLoading
	end
	if value and value:IsA("GuiObject") and isLoading then
		value.Visible = false
	end
	if dots and dots:IsA("GuiObject") then
		dots.Visible = isLoading
	end
	if isLoading then
		runDots(button, state)
	end
end

-- A price on the right of the button, after its bill (nil hides it); the words move to the left while it shows.
function Buttons.SetValue(button: GuiButton, text: string?, icon: string?)
	local frame = face(button)
	if not frame then
		return
	end
	local value = frame:FindFirstChild("Value")
	local content = frame:FindFirstChild("Content")
	if value and value:IsA("GuiObject") then
		value.Visible = text ~= nil
		local label = value:FindFirstChild("ValueLabel")
		if label and label:IsA("TextLabel") then
			label.Text = text or ""
		end
		local glyph = value:FindFirstChild("ValueIcon")
		if glyph and glyph:IsA("ImageLabel") then
			glyph.Image = icon or Theme.Icons.Cash
		end
	end
	local layout = content and content:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.HorizontalAlignment = if text then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Center
	end
	local padding = content and content:FindFirstChildOfClass("UIPadding")
	if padding then
		padding.PaddingLeft = UDim.new(0, if text then 18 else 12)
	end
end

-- An icon before the words (a padlock, the Robux glyph), or none. `tinted` paints it the label's colour.
function Buttons.SetIcon(button: GuiButton, image: string?, tinted: boolean?)
	local frame = face(button)
	local icon = frame and frame:FindFirstChild("Icon", true)
	if icon and icon:IsA("ImageLabel") then
		icon.Visible = image ~= nil
		icon.Image = image or ""
		icon:SetAttribute("Tinted", tinted == true)
		if tinted then
			icon.ImageColor3 = Theme.Button[stateOf(button).Kind].Label
		else
			icon.ImageColor3 = Color3.new(1, 1, 1)
		end
	end
end

-- Can't afford, tapped: still pressable, so it shakes and flashes red 300 (the Denied blip is the caller's).
function Buttons.Shake(button: GuiButton)
	local frame = face(button)
	if not frame then
		return
	end
	local base = frame:GetAttribute("BaseX")
	if type(base) ~= "number" then
		base = frame.Position.X.Offset
		frame:SetAttribute("BaseX", base)
	end
	local baseX = base :: number
	-- The tap that shakes it has just been released, so it shakes at rest height: tweening from wherever the squish's
	-- spring-back had got to would cancel that spring and leave the face pressed down.
	local restY = frame:GetAttribute("BaseY")
	local baseY = if type(restY) == "number" then restY else frame.Position.Y.Offset
	local token = (shakes[button] or 0) + 1
	shakes[button] = token
	local steps = Motion.Shake
	local stepTime = Motion.ShakeSeconds / (#steps - 1)
	task.spawn(function()
		local look = Theme.Button[stateOf(button).Kind]
		frame.BackgroundColor3 = Color.Red300
		TweenService:Create(frame, TweenInfo.new(Motion.ShakeSeconds, Enum.EasingStyle.Quad), {
			BackgroundColor3 = look.Face,
		}):Play()
		for index = 2, #steps do
			-- Reduce Motion: the red flash alone.
			if shakes[button] ~= token or PlayerSettings.ReduceMotion() then
				break
			end
			local position = frame.Position
			TweenService:Create(
				frame,
				TweenInfo.new(stepTime, Enum.EasingStyle.Sine),
				{ Position = UDim2.new(position.X.Scale, baseX + steps[index], position.Y.Scale, baseY) }
			):Play()
			task.wait(stepTime)
		end
		if shakes[button] == token then
			shakes[button] = nil
			local position = frame.Position
			frame.Position = UDim2.new(position.X.Scale, baseX, position.Y.Scale, baseY)
			-- Its kind may have changed while it flashed (cash came in): end on today's look, not the one it started on.
			paint(button)
		end
	end)
end

-- A tab on or off (Ranch Studs): the page showing is a blue studded button, the others grey; the words stay snow.
function Buttons.SetTab(tab: GuiButton, isOn: boolean)
	-- Prize Fleece's tabs (UIKit.Tabs): the page showing has its face in the menu's colour and white words; the others
	-- are muted words in the well.
	if tab:GetAttribute("Fleece") == true then
		local fleeceFace = tab:FindFirstChild("Face")
		if fleeceFace and fleeceFace:IsA("GuiObject") then
			fleeceFace.Visible = isOn
		end
		local fleeceLabel = tab:FindFirstChild("Label", true)
		if fleeceLabel and fleeceLabel:IsA("TextLabel") then
			fleeceLabel.TextColor3 = if isOn then Color.Snow else Theme.Fleece.Muted
			local stroke = fleeceLabel:FindFirstChild("TextStroke")
			if stroke and stroke:IsA("UIStroke") then
				stroke.Enabled = isOn
			end
		end
		local fleeceIcon = tab:FindFirstChild("Icon", true)
		if fleeceIcon and fleeceIcon:IsA("ImageLabel") then
			fleeceIcon.ImageTransparency = if isOn then 0 else 0.4
		end
		return
	end
	local look = Theme.Tab
	local frame = tab:FindFirstChild("Face")
	if frame and frame:IsA("Frame") then
		frame.BackgroundTransparency = 0
		frame.BackgroundColor3 = if isOn then look.On else look.Off
		local lip = shadow(frame, "Lip")
		if lip then
			lip.Color = if isOn then look.OnLip else look.OffLip
		end
	end
	local studs = tab:FindFirstChild("Studs")
	if studs and studs:IsA("ImageLabel") then
		studs.Image = Theme.Studs.Image
		studs.Visible = Theme.Studs.Image ~= ""
	end
	local label = tab:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		label.TextColor3 = Color.Snow
	end
	local icon = tab:FindFirstChild("Icon", true)
	if icon and icon:IsA("ImageLabel") then
		icon.ImageTransparency = if isOn then 0 else 0.15
		icon.ImageColor3 = Color3.new(1, 1, 1)
	end
end

-- Kinds that can't do anything right now: they don't move when pressed.
local STILL: { [string]: boolean } = { Locked = true, Disabled = true, NightDisabled = true, Owned = true }

local function pressable(button: GuiButton): boolean
	return not STILL[stateOf(button).Kind] and not stateOf(button).Loading
end

-- Whether the button's kind can't do anything right now (Locked, Disabled and the night panel's two).
function Buttons.IsStill(button: GuiButton): boolean
	return STILL[stateOf(button).Kind] == true
end

-- Squishes to 0.94 and drops onto its lip while held; springs back on release.
local function press(button: GuiButton, down: boolean)
	local frame = face(button)
	local squish = button:FindFirstChild("Squish")
	if not frame or not squish or not squish:IsA("UIScale") or (down and not pressable(button)) then
		return
	end
	local lipSize = frame:GetAttribute("Lip")
	local lip = if type(lipSize) == "number" then lipSize else Theme.Lip.Button
	local baseY = frame:GetAttribute("BaseY")
	if type(baseY) ~= "number" then
		baseY = frame.Position.Y.Offset
		frame:SetAttribute("BaseY", baseY)
	end
	local drop = if down then math.min(Motion.SquishDrop, lip - 1) else 0
	local info = if down then Motion.SquishDown else Motion.SquishUp
	local position = frame.Position
	TweenService:Create(squish, info, { Scale = if down then Motion.Squish else 1 }):Play()
	TweenService:Create(frame, info, {
		Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, (baseY :: number) + drop),
	}):Play()
	for _, name in { "Lip", "LipRing" } do
		local instance = shadow(frame, name)
		if instance then
			TweenService:Create(instance, info, { Offset = UDim2.fromOffset(0, lip - drop) }):Play()
		end
	end
end

-- Rows, cells and tabs (buttons without a kind, with looks of their own) darken while held, so a tap reads as taken,
-- without touching the colours the screen gives them. Scaling them instead would shrink them into a corner and jog the
-- rest of their list. Safe to call twice.
function Buttons.Shade(button: GuiButton): { RBXScriptConnection }
	if shaded[button] then
		return {}
	end
	shaded[button] = true
	local hold: (down: boolean) -> ()
	if button:FindFirstChildWhichIsA("UIGridStyleLayout") then
		-- Its children are laid out (a shop row), so a layer over it would join the row: its own background is
		-- tinted instead, which a gradient does without changing its colour.
		local tint = Instance.new("UIGradient")
		tint.Name = "PressTint"
		tint.Color = ColorSequence.new(Color3.new(1, 1, 1):Lerp(Color.Ink, 1 - Motion.PressShade))
		tint.Enabled = false
		tint.Parent = button
		hold = function(down: boolean)
			tint.Enabled = down
		end
	else
		local shade = Instance.new("Frame")
		shade.Name = "PressShade"
		shade.BackgroundColor3 = Color.Ink
		shade.BackgroundTransparency = 1
		shade.BorderSizePixel = 0
		shade.Size = UDim2.fromScale(1, 1)
		shade.ZIndex = 50
		local frame = face(button)
		local round = button:FindFirstChildOfClass("UICorner") or (frame and frame:FindFirstChildOfClass("UICorner"))
		if round then
			round:Clone().Parent = shade
		end
		shade.Parent = button
		hold = function(down: boolean)
			-- A clear button (a tab not picked, on the dark tab bar) lightens instead: ink wouldn't show there.
			local clear = button.BackgroundTransparency >= 1 and (frame == nil or frame.BackgroundTransparency >= 1)
			if down then
				shade.BackgroundColor3 = if clear then Color.Snow else Color.Ink
			end
			TweenService
				:Create(shade, if down then Motion.SquishDown else Motion.SquishUp, {
					BackgroundTransparency = if not down
						then 1
						elseif clear then Motion.PressLight
						else Motion.PressShade,
				})
				:Play()
		end
	end
	-- A finger that presses a row and then drags its list may never lift over the row, so the shade also goes when
	-- the list scrolls or any touch or click ends.
	local held = false
	local scrollWatch: RBXScriptConnection? = nil
	local function release()
		if scrollWatch then
			scrollWatch:Disconnect()
			scrollWatch = nil
		end
		if held then
			held = false
			hold(false)
		end
	end
	local connections = {
		button.MouseButton1Down:Connect(function()
			held = true
			hold(true)
			-- Looked up now: rows are shaded before they join their list.
			local scroller = button:FindFirstAncestorWhichIsA("ScrollingFrame")
			if scroller and not scrollWatch then
				scrollWatch = scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(release)
			end
		end),
		button.MouseButton1Up:Connect(release),
		button.MouseLeave:Connect(release),
		UserInputService.InputEnded:Connect(function(input: InputObject)
			local kind = input.UserInputType
			if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 then
				release()
			end
		end),
	}
	return connections
end

-- A picture button (UIKit.PictureButton) has no face colour to brighten or lip to drop onto: it grows a little under
-- the mouse and squishes while held.
local function bindPicture(button: GuiButton): { RBXScriptConnection }
	local squish = button:FindFirstChild("Squish")
	if not squish or not squish:IsA("UIScale") then
		return {}
	end
	local held = false
	local hovered = false
	local function settle()
		local scale = if held then Motion.Squish elseif hovered then Motion.PictureHover else 1
		TweenService:Create(squish, if held then Motion.SquishDown else Motion.SquishUp, { Scale = scale }):Play()
	end
	return {
		button.MouseButton1Down:Connect(function()
			held = true
			settle()
		end),
		button.MouseButton1Up:Connect(function()
			held = false
			settle()
		end),
		-- A touch fires this just after MouseButton1Down, in the same frame: it mustn't undo the squish.
		button.MouseEnter:Connect(function()
			hovered = UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
			settle()
		end),
		button.MouseLeave:Connect(function()
			held = false
			hovered = false
			settle()
		end),
	}
end

-- Wires the squish and the PC hover on one button with a Face. Safe to call twice.
function Buttons.Bind(button: GuiButton): { RBXScriptConnection }
	if bound[button] then
		return {}
	end
	if button:GetAttribute("Picture") == true then
		bound[button] = true
		return bindPicture(button)
	end
	-- Only UIKit's buttons (they carry a Kind): tabs and rows have their own looks.
	if not face(button) or button:GetAttribute("Kind") == nil then
		return {}
	end
	bound[button] = true
	return {
		button.MouseButton1Down:Connect(function()
			-- A still button tapped turns side to side, so the tap is seen to land but go nowhere; the screen says why.
			local frame = face(button)
			if frame and STILL[stateOf(button).Kind] then
				Animate.Wobble(frame)
			end
			press(button, true)
		end),
		button.MouseButton1Up:Connect(function()
			press(button, false)
		end),
		button.MouseLeave:Connect(function()
			press(button, false)
			local state = stateOf(button)
			if state.Hovered then
				state.Hovered = false
				paint(button)
			end
		end),
		button.MouseEnter:Connect(function()
			if UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse and pressable(button) then
				stateOf(button).Hovered = true
				paint(button)
			end
		end),
	}
end

-- Binds every button of a screen, rows cloned in later included; the returned watcher is for the caller to
-- disconnect.
function Buttons.Watch(gui: ScreenGui): RBXScriptConnection
	local function watch(instance: Instance)
		if instance:IsA("GuiButton") then
			Buttons.Bind(instance)
		end
	end
	for _, descendant in gui:GetDescendants() do
		watch(descendant)
	end
	return gui.DescendantAdded:Connect(watch)
end

return table.freeze(Buttons)
