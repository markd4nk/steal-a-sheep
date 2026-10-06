--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Theme = require(ReplicatedStorage.Config.Theme)

local Motion = Theme.Motion

-- The UI's motion (UI_SPEC 1.8): it only confirms, points or celebrates, and never makes the player wait. A menu takes
-- taps the moment it starts to open.
local Animate = {}

type Shake = {
	Token: number,
	BaseX: number, -- the X offset it rests at, from before the first of overlapping shakes
}

local pulses: { [UIStroke]: { Tween } } = setmetatable({}, { __mode = "k" }) :: any
local counters: { [TextLabel]: number } = setmetatable({}, { __mode = "k" }) :: any
local countTweens: { [TextLabel]: Tween } = setmetatable({}, { __mode = "k" }) :: any
local shakes: { [GuiObject]: Shake } = setmetatable({}, { __mode = "k" }) :: any
local celebrations: { [GuiObject]: number } = setmetatable({}, { __mode = "k" }) :: any
local slideRests: { [GuiObject]: UDim2 } = setmetatable({}, { __mode = "k" }) :: any
local slides: { [GuiObject]: Tween } = setmetatable({}, { __mode = "k" }) :: any
local flashRests: { [GuiObject]: Color3 } = setmetatable({}, { __mode = "k" }) :: any
local flashes: { [GuiObject]: Tween } = setmetatable({}, { __mode = "k" }) :: any
local textRests: { [TextLabel]: Color3 } = setmetatable({}, { __mode = "k" }) :: any
local textFlashes: { [TextLabel]: Tween } = setmetatable({}, { __mode = "k" }) :: any
local SLIDE_DISTANCE = 28 -- points a page slides in from

type Wobble = {
	Token: number,
	Rest: number, -- the rotation it rests at (the cash bill sits tilted)
}

local wobbles: { [GuiObject]: Wobble } = setmetatable({}, { __mode = "k" }) :: any

local function scaleOf(target: Instance, name: string): UIScale?
	local found = target:FindFirstChild(name)
	return if found and found:IsA("UIScale") then found else nil
end

-- The pulsing ring the tutorial and hints put on what they point at: a UIStroke named Glow directly under `parent`,
-- or under its Face (UIKit.Glow), with its outer GlowRing.
function Animate.FindGlow(parent: Instance): UIStroke?
	local found = parent:FindFirstChild("Glow")
	if not found then
		local face = parent:FindFirstChild("Face")
		found = face and face:FindFirstChild("Glow")
	end
	return if found and found:IsA("UIStroke") then found else nil
end

-- Breathes the ring (and its GlowRing) from solid to half, over and over, until switched off.
function Animate.SetGlow(stroke: UIStroke?, on: boolean)
	if not stroke then
		return
	end
	local rings = { stroke }
	local outer = stroke.Parent and stroke.Parent:FindFirstChild("GlowRing")
	if outer and outer:IsA("UIStroke") then
		table.insert(rings, outer)
	end
	local running = pulses[stroke]
	if on and not running then
		local tweens: { Tween } = {}
		for _, ring in rings do
			ring.Enabled = true
			ring.Transparency = 0
			local tween = TweenService:Create(ring, Motion.Glow, { Transparency = Motion.GlowDim })
			tween:Play()
			table.insert(tweens, tween)
		end
		pulses[stroke] = tweens
	elseif not on and running then
		for _, tween in running do
			tween:Cancel()
		end
		pulses[stroke] = nil
		for _, ring in rings do
			ring.Enabled = false
		end
	end
end

-- How big a menu or card is drawn once open: 1, or less where it doesn't fit. A Prize Fleece window says (its Fit,
-- UIController/Scale); a pop-up card with a header (AutoFit, UIKit.PopCard) shrinks to fit the screen's height.
local FIT_MARGIN = 12 -- pixels kept free above and below a pop-up card that had to shrink
local function fitInto(height: number, holder: GuiObject): number
	return math.clamp((holder.AbsoluteSize.Y - 2 * FIT_MARGIN) / height, 0.5, 1)
end

-- A pop-up card that fits itself: its height at full size and what holds it, or nil.
local function autoFit(target: GuiObject, pop: UIScale): (number?, GuiObject?)
	local holder = target.Parent
	if target:GetAttribute("AutoFit") ~= true or not holder or not holder:IsA("GuiObject") or pop.Scale <= 0 then
		return nil, nil
	end
	local height = target.AbsoluteSize.Y / pop.Scale
	return if height > 0 then height else nil, holder
end

local function fitOf(target: GuiObject, pop: UIScale): number
	local fit = target:GetAttribute("Fit")
	if type(fit) == "number" then
		return fit
	end
	local height, holder = autoFit(target, pop)
	return if height and holder then fitInto(height, holder) else 1
end

-- A menu or card opens: from 0.85 to its size with a little overshoot, the backdrop fading in under it.
function Animate.PopIn(target: GuiObject, backdrop: GuiObject?, backdropTransparency: number?)
	local pop = scaleOf(target, "Pop")
	if pop then
		local height, holder = autoFit(target, pop)
		local fit = fitOf(target, pop)
		pop.Scale = Motion.PopInFrom * fit
		local tween = TweenService:Create(pop, Motion.PopIn, { Scale = fit })
		tween:Play()
		-- A screen just switched on still has the room it was laid out with while off (on a phone, 579 px tall for
		-- 280), so a card that fits itself is fitted again once the room is known: the Daily Gift's first opening ran
		-- off the bottom of a phone (2026-10-03).
		-- A Prize Fleece window's Fit can change while it pops in, as the screen just switched on gets its real size
		-- (UIController/Scale sets it a frame later on a phone): the pop then heads for the new one, or it ends up drawn
		-- at full size, past the screen's bottom (the store and the Free Gift on a Galaxy A06, 2026-10-05).
		if type(target:GetAttribute("Fit")) == "number" then
			local refitted = target:GetAttributeChangedSignal("Fit"):Connect(function()
				local refit = fitOf(target, pop)
				if math.abs(refit - fit) > 0.01 then
					fit = refit
					tween:Cancel()
					pop.Scale = Motion.PopInFrom * refit
					tween = TweenService:Create(pop, Motion.PopIn, { Scale = refit })
					tween:Play()
				end
			end)
			task.delay(Motion.PopIn.Time, function()
				refitted:Disconnect()
			end)
		end
		if height and holder and target:GetAttribute("Fit") == nil then
			local roomed = holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				local refit = fitInto(height, holder)
				if math.abs(refit - fit) > 0.01 then
					-- A frame in at most: it pops in again from the right size, so it still reads as one pop.
					fit = refit
					tween:Cancel()
					pop.Scale = Motion.PopInFrom * refit
					tween = TweenService:Create(pop, Motion.PopIn, { Scale = refit })
					tween:Play()
				end
			end)
			task.delay(Motion.PopIn.Time, function()
				roomed:Disconnect()
			end)
		end
	end
	if backdrop then
		backdrop.BackgroundTransparency = 1
		TweenService:Create(backdrop, Motion.BackdropIn, {
			BackgroundTransparency = backdropTransparency or Motion.Backdrop,
		}):Play()
	end
end

-- It closes: a quick shrink to 0.92 while the backdrop fades, then `done`.
function Animate.PopOut(target: GuiObject, backdrop: GuiObject?, done: () -> ())
	local pop = scaleOf(target, "Pop")
	if pop then
		TweenService:Create(pop, Motion.PopOut, { Scale = Motion.PopOutTo * pop.Scale }):Play()
	end
	if backdrop then
		TweenService:Create(backdrop, Motion.PopOut, { BackgroundTransparency = 1 }):Play()
	end
	task.delay(Motion.PopOut.Time, done)
end

-- A quick punch: 1.12 (or `amount`) back to 1 (the cash pill on a gain). Still with Reduce Motion on.
function Animate.Punch(scale: UIScale, amount: number?)
	if PlayerSettings.ReduceMotion() then
		scale.Scale = 1
		return
	end
	scale.Scale = amount or Motion.Punch
	TweenService:Create(scale, Motion.TickUp, { Scale = 1 }):Play()
end

-- Slides a page in from the side it comes from (-1 from the left, 1 from the right; 0 just shows it) to where it rests,
-- as a tab or page changes. Reduce Motion shows it in place.
function Animate.SlideIn(target: GuiObject, direction: number)
	local rest = slideRests[target] or target.Position
	slideRests[target] = rest
	local running = slides[target]
	if running then
		running:Cancel()
		slides[target] = nil
	end
	if direction == 0 or PlayerSettings.ReduceMotion() then
		target.Position = rest
		return
	end
	target.Position = rest + UDim2.fromOffset(direction * SLIDE_DISTANCE, 0)
	local tween = TweenService:Create(target, Motion.Slide, { Position = rest })
	slides[target] = tween
	tween:Play()
end

-- Pops something in from small (the cash pill on the first shear, the lab's pen counter back from under the result's
-- word). Reduce Motion leaves it at full size.
function Animate.Appear(scale: UIScale)
	if PlayerSettings.ReduceMotion() then
		scale.Scale = 1
		return
	end
	scale.Scale = Motion.CashAppearFrom
	TweenService:Create(scale, Motion.CashAppear, { Scale = 1 }):Play()
end

-- A piece pops in from small (0.4 to 1, a little overshoot) on the UIScale it has for that (Pop, or a button's
-- Squish), or one made for it. Reduce Motion leaves it at full size.
function Animate.Pop(target: GuiObject)
	if PlayerSettings.ReduceMotion() then
		return
	end
	local scale = scaleOf(target, "Pop") or scaleOf(target, "Squish")
	if not scale then
		local made = Instance.new("UIScale")
		made.Name = "Pop"
		made.Parent = target
		scale = made
	end
	local found = scale :: UIScale
	found.Scale = Motion.RevealFrom
	TweenService:Create(found, Motion.Reveal, { Scale = 1 }):Play()
end

-- Shows or hides a HUD piece (a tile, a chip, the leaderboard's card, the carry hint): one that appears pops in, so the eye
-- catches what's new; one that goes leaves at once.
function Animate.Reveal(target: GuiObject, shown: boolean)
	if target.Visible == shown then
		return
	end
	target.Visible = shown
	if shown then
		Animate.Pop(target)
	end
end

-- Counts a number up over 0.35 s (cash going up); spending snaps down in 0.2 s. `format` writes each step.
function Animate.Count(label: TextLabel, from: number, to: number, format: (number) -> string)
	local token = (counters[label] or 0) + 1
	counters[label] = token
	local running = countTweens[label]
	if running then
		running:Cancel()
	end
	local info = if to >= from then Motion.TickUp else Motion.TickDown
	local value = Instance.new("NumberValue")
	value.Value = from
	local tween = TweenService:Create(value, info, { Value = to })
	countTweens[label] = tween
	value.Changed:Connect(function(current: number)
		if counters[label] == token then
			label.Text = format(if current == to then to else math.floor(current))
		end
	end)
	tween.Completed:Connect(function()
		if counters[label] == token then
			label.Text = format(to)
			countTweens[label] = nil
		end
		value:Destroy()
	end)
	tween:Play()
end

-- Flashes a piece's background to `color` and fades it back (the cash chip when a price is out of reach). For pieces
-- whose own colour doesn't change: the colour it fades back to is the one it had the first time.
function Animate.Flash(target: GuiObject, color: Color3)
	local rest = flashRests[target] or target.BackgroundColor3
	flashRests[target] = rest
	local running = flashes[target]
	if running then
		running:Cancel()
	end
	target.BackgroundColor3 = color
	local tween = TweenService:Create(target, Motion.FlashFade, { BackgroundColor3 = rest })
	flashes[target] = tween
	tween:Play()
end

-- The same for a label's words (the menu's cash ticking red as it's spent).
function Animate.FlashText(label: TextLabel, color: Color3)
	local rest = textRests[label] or label.TextColor3
	textRests[label] = rest
	local running = textFlashes[label]
	if running then
		running:Cancel()
	end
	label.TextColor3 = color
	local tween = TweenService:Create(label, Motion.FlashFade, { TextColor3 = rest })
	textFlashes[label] = tween
	tween:Play()
end

-- Turns a piece side to side and back to how it rests (a still button tapped, the cash bill when there isn't
-- enough). A wobble during another carries on from the same rest. Reduce Motion: no wobble.
function Animate.Wobble(target: GuiObject)
	if PlayerSettings.ReduceMotion() then
		return
	end
	local running = wobbles[target]
	local rest = if running then running.Rest else target.Rotation
	local token = (if running then running.Token else 0) + 1
	wobbles[target] = { Token = token, Rest = rest }
	local steps = Motion.Wobble
	local stepTime = Motion.WobbleSeconds / (#steps - 1)
	task.spawn(function()
		for index = 2, #steps do
			local current = wobbles[target]
			if not current or current.Token ~= token then
				return
			end
			TweenService:Create(target, TweenInfo.new(stepTime, Enum.EasingStyle.Sine), {
				Rotation = rest + steps[index],
			}):Play()
			task.wait(stepTime)
		end
		local current = wobbles[target]
		if current and current.Token == token then
			wobbles[target] = nil
			target.Rotation = rest
		end
	end)
end

-- Stops a count and writes `text` at once.
function Animate.Set(label: TextLabel, text: string)
	counters[label] = (counters[label] or 0) + 1
	label.Text = text
end

-- Ends a shake at once, back at its resting X.
local function stopShake(target: GuiObject)
	local running = shakes[target]
	if running then
		shakes[target] = nil
		local position = target.Position
		target.Position = UDim2.new(position.X.Scale, running.BaseX, position.Y.Scale, position.Y.Offset)
	end
end

-- Shakes a piece side to side (a problem notice as it lands): 0, -8, +7, -5, +3, 0 over 0.32 s. A shake that starts
-- during another carries on from the same resting X, so overlapping shakes never leave it off centre.
function Animate.Shake(target: GuiObject)
	-- Reduce Motion: the notice's red and its blip say it without the movement.
	if PlayerSettings.ReduceMotion() then
		return
	end
	local running = shakes[target]
	local baseX = if running then running.BaseX else target.Position.X.Offset
	local token = (if running then running.Token else 0) + 1
	shakes[target] = { Token = token, BaseX = baseX }
	local steps = Motion.Shake
	local stepTime = Motion.ShakeSeconds / (#steps - 1)
	task.spawn(function()
		for index = 2, #steps do
			local current = shakes[target]
			if not current or current.Token ~= token then
				return
			end
			local position = target.Position
			TweenService:Create(target, TweenInfo.new(stepTime, Enum.EasingStyle.Sine), {
				Position = UDim2.new(position.X.Scale, baseX + steps[index], position.Y.Scale, position.Y.Offset),
			}):Play()
			task.wait(stepTime)
		end
		local current = shakes[target]
		if current and current.Token == token then
			stopShake(target)
		end
	end)
end

-- A notice arrives: slides 10 pt down into place and fades in. `rest` is where it sits.
function Animate.NoticeIn(target: GuiObject, rest: UDim2)
	stopShake(target)
	target.Position = rest - UDim2.fromOffset(0, Motion.NoticeDrop)
	target.Visible = true
	TweenService:Create(target, Motion.NoticeIn, { Position = rest }):Play()
end

-- It leaves upwards, then `done`.
function Animate.NoticeOut(target: GuiObject, rest: UDim2, done: () -> ())
	stopShake(target)
	TweenService:Create(target, Motion.NoticeOut, { Position = rest - UDim2.fromOffset(0, Motion.NoticeDrop) }):Play()
	task.delay(Motion.NoticeOut.Time, done)
end

-- "2 sheep!", a rare result: 0.2 to 1.15 to 1 with the burst, holds (3 s unless `hold` says), fades. `target` holds a
-- UIScale named Pop; `labels` fade out at the end.
function Animate.Celebrate(target: GuiObject, labels: { TextLabel }, burst: ImageLabel?, hold: number?)
	local seconds = hold or Motion.CelebrateHold
	local pop = scaleOf(target, "Pop")
	local token = (celebrations[target] or 0) + 1
	celebrations[target] = token
	target.Visible = true
	for _, label in labels do
		label.TextTransparency = 0
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 0
		end
	end
	if pop then
		pop.Scale = Motion.CelebrateFrom
		TweenService:Create(pop, Motion.Celebrate, { Scale = 1 }):Play()
	end
	if burst then
		burst.ImageTransparency = 0.45
		burst.Rotation = 0
		TweenService:Create(burst, TweenInfo.new(seconds + 0.4, Enum.EasingStyle.Sine), { Rotation = 40 }):Play()
	end
	task.delay(seconds, function()
		-- A newer celebration on the same piece owns its fade.
		if celebrations[target] ~= token then
			return
		end
		for _, label in labels do
			TweenService:Create(label, Motion.CelebrateFade, { TextTransparency = 1 }):Play()
			local stroke = label:FindFirstChildOfClass("UIStroke")
			if stroke then
				TweenService:Create(stroke, Motion.CelebrateFade, { Transparency = 1 }):Play()
			end
		end
		if burst then
			TweenService:Create(burst, Motion.CelebrateFade, { ImageTransparency = 1 }):Play()
		end
		task.delay(Motion.CelebrateFade.Time, function()
			if celebrations[target] == token then
				target.Visible = false
			end
		end)
	end)
end

return table.freeze(Animate)
