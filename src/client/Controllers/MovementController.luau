--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Mountain = require(ReplicatedStorage.Utils.Mountain)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- How the local character moves. Walking: 18 studs a second, times a carried lamb's burden share; going up the ramp,
-- no faster up the slope than the player's Climbing allows there (Mountain.ClimbSpeedAt; the server checks). Sliding:
-- moving downhill on the ramp starts a slide by itself; it speeds up to the escape speed set when it starts
-- (Economy.EscapeSpeed: Climbing against the lamb's tier and weight) and keeps it all the way down, like momentum;
-- it steers within a cone either side of straight downhill with the ordinary movement controls,
-- brakes when pulled back, and runs out to a stop past the safety line. A slider's hit costs it speed; a hit player is
-- moved back down the slope and stunned for a moment. Also: their stair walker steps while they train.
local MovementController = { Name = "MovementController" }

local SLIDE_RENDER = "SlideControl"
local SIT_R15 = "rbxassetid://2506281703"
local SIT_R6 = "rbxassetid://178130996"
local STEP_CYCLE = 0.55 -- seconds a stair walker step takes to come down one step

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local player = Players.LocalPlayer

local sliding = false
local slideSpeed = 0
local slideTarget = 0
local heading = Mountain.Downhill
local knockUntil = 0
local stunUntil = 0
local knockDirection = Vector3.zero
local stuckFor = 0
local sitTrack: AnimationTrack? = nil
local walkTrack: AnimationTrack? = nil

local function character(): (Model?, Humanoid?, BasePart?)
	local model = player.Character
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if model and humanoid and root and root:IsA("BasePart") and humanoid.Health > 0 then
		return model, humanoid, root
	end
	return nil, nil, nil
end

local function climbing(): number
	local climb = player:GetAttribute("ClimbPower")
	return if type(climb) == "number" then climb else 0
end

-- The carried lamb's tier and burden, or nil when empty-handed.
local function carried(): (number?, number?)
	if player:GetAttribute("Carrying") ~= true then
		return nil, nil
	end
	local tier = player:GetAttribute("CarryTier")
	local burden = player:GetAttribute("CarryBurden")
	if type(tier) ~= "number" or type(burden) ~= "number" then
		return nil, nil
	end
	return tier, burden
end

-- The share of walking speed a carried lamb leaves the player (Economy.CarryShare), 1 when empty-handed.
local function carryShare(): number
	local tier, burden = carried()
	return if tier and burden then Economy.CarryShare(burden, climbing(), tier) else 1
end

-- The speed a slide starting at `x` keeps all the way down.
local function escapeSpeed(x: number): number
	local tier, burden = carried()
	if tier and burden then
		return Economy.EscapeSpeed(climbing(), tier, Economy.Burdens[burden].Weight)
	end
	return Economy.EscapeSpeed(climbing(), math.max(Mountain.TierAt(x), 1), Economy.EmptyWeight)
end

-- Walking speed, held down when the move heads up the ramp so its uphill part never beats the climb speed there.
-- Moving across the slope stays at full speed.
local function walkSpeed(position: Vector3, input: Vector3, walk: number, share: number): number
	if input.X <= 0 or position.X < Olympus.SafeLineX then
		return walk
	end
	local climb = Mountain.ClimbSpeedAt(position.X, climbing()) * share
	return math.min(walk, climb / input.X)
end

-- What the player is asking for, in world space: the Humanoid's MoveDirection as Roblox's own controls set it this
-- frame. This runs after them and before this controller's own Move (which then wins for the frame).
-- Studio playtests only: the DebugSpeed attribute (DebugService) multiplies the character's speed.
local function speedBoost(): number
	if not RunService:IsStudio() then
		return 1
	end
	local boost = player:GetAttribute("DebugSpeed")
	return if type(boost) == "number" and boost > 0 then boost else 1
end

local function moveInput(humanoid: Humanoid): Vector3
	local direction = humanoid.MoveDirection
	return Vector3.new(direction.X, 0, direction.Z)
end

local function loadTrack(humanoid: Humanoid, id: string): AnimationTrack?
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	return if ok then track else nil
end

local function setSliding(on: boolean, humanoid: Humanoid?)
	if sliding == on then
		return
	end
	sliding = on
	Remotes.Slide:Fire(on)
	if on then
		if humanoid and not sitTrack then
			local id = if humanoid.RigType == Enum.HumanoidRigType.R15 then SIT_R15 else SIT_R6
			sitTrack = loadTrack(humanoid, id)
			if sitTrack then
				sitTrack.Priority = Enum.AnimationPriority.Action
				sitTrack.Looped = true
			end
		end
		if sitTrack then
			sitTrack:Play(0.15)
		end
		local sound = registry.SoundController
		if sound then
			sound:Play("IntroWhip")
		end
	elseif sitTrack then
		sitTrack:Stop(0.2)
	end
end

local function step(dt: number)
	local _, humanoid, root = character()
	if not humanoid or not root then
		return
	end
	local now = os.clock()
	local share = carryShare()
	local walk = GameConfig.Movement.WalkSpeed * share
	local boost = speedBoost()
	local settings = GameConfig.Movement

	-- Knocked back: moved down the slope, then held still until the stun ends.
	if now < stunUntil then
		setSliding(false, humanoid)
		if now < knockUntil then
			humanoid.WalkSpeed = GameConfig.SlideHit.KnockStuds / GameConfig.SlideHit.KnockSeconds
			humanoid:Move(knockDirection, false)
		else
			humanoid.WalkSpeed = 0
			humanoid:Move(Vector3.zero, false)
		end
		return
	end

	local position = root.Position
	-- In unboosted studs a second, so a Studio speed boost changes nothing but the result.
	local velocity = root.AssemblyLinearVelocity / boost
	local onRamp = Mountain.IsOnRamp(position)
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local input = moveInput(humanoid)

	if not sliding then
		humanoid.WalkSpeed = walkSpeed(position, input, walk, share) * boost
		local downhill = -velocity.X
		local flat = Vector2.new(velocity.X, velocity.Z).Magnitude
		if
			onRamp
			and grounded
			and position.X > Olympus.SafeLineX + 2
			and downhill > settings.SlideMinStart
			and downhill > flat * 0.6
			and input.X < 0
		then
			slideSpeed = math.max(flat, walk)
			slideTarget = escapeSpeed(position.X)
			heading = Vector3.new(
				-1,
				0,
				math.clamp(velocity.Z / math.max(flat, 1), -settings.SlideHeading, settings.SlideHeading)
			).Unit
			setSliding(true, humanoid)
		else
			return
		end
	end

	-- Sliding.
	local pastLine = position.X < Olympus.SafeLineX
	if not onRamp and not pastLine and grounded then
		setSliding(false, humanoid)
		humanoid.WalkSpeed = walk * boost
		return
	end
	local target = if pastLine then 0 else slideTarget
	local braking = input.X > 0.35
	if braking or pastLine then
		-- Past the safety line the slide runs out more gently than a pulled-back brake.
		local brake = if braking then settings.SlideBrake else settings.SlideBrake * 0.4
		slideSpeed = math.max(0, slideSpeed - brake * dt)
	elseif grounded then
		if slideSpeed < target then
			slideSpeed = math.min(target, slideSpeed + settings.SlideAccel * dt)
		else
			slideSpeed = math.max(target, slideSpeed - settings.SlideAccel * 0.5 * dt)
		end
	end
	-- Scenery hit: the slide carries on from the speed the character really has, and ends if it stays stuck.
	local actual = Vector2.new(velocity.X, velocity.Z).Magnitude
	if grounded and actual < slideSpeed * 0.6 then
		slideSpeed = math.max(actual + 4, settings.SlideStopSpeed)
	end
	stuckFor = if actual < settings.SlideStopSpeed then stuckFor + dt else 0
	if stuckFor > 0.5 then
		stuckFor = 0
		setSliding(false, humanoid)
		humanoid.WalkSpeed = walk * boost
		return
	end
	-- Steering: the stick's sideways share turns the heading, never past the cone either side of downhill.
	local wanted = math.clamp(input.Z, -1, 1) * settings.SlideHeading
	local current = heading.Z / math.max(math.abs(heading.X), 1e-3)
	local turned = current + (wanted - current) * math.clamp(settings.SlideTurnRate * dt, 0, 1)
	heading = Vector3.new(-1, 0, turned).Unit
	if slideSpeed < settings.SlideStopSpeed then
		setSliding(false, humanoid)
		humanoid.WalkSpeed = walk * boost
		return
	end
	humanoid.WalkSpeed = slideSpeed * boost
	humanoid:Move(heading, false)
	-- On High Olympus's steep stretches a fast slide outruns its own fall and hops along the floor (in the air a
	-- third of the way down, measured at 52 degrees): it drops at least as fast as the ramp does, unless it jumped.
	if onRamp and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
		local follow = -Vector2.new(velocity.X, velocity.Z).Magnitude * Mountain.RampSlope(position.X) * boost
		if velocity.Y * boost > follow then
			root.AssemblyLinearVelocity = Vector3.new(velocity.X * boost, follow, velocity.Z * boost)
		end
	end
end

-- The player's own stair walker steps down while they train, and they walk on the spot.
local function animateWalker(humanoid: Humanoid?)
	local training = player:GetAttribute("Training") == true
	if training and humanoid then
		if not walkTrack then
			local model = player.Character
			local animate = model and model:FindFirstChild("Animate")
			local walkValue = animate and animate:FindFirstChild("walk")
			local walkAnimation = walkValue and walkValue:FindFirstChildOfClass("Animation")
			if walkAnimation then
				walkTrack = loadTrack(humanoid, walkAnimation.AnimationId)
				if walkTrack then
					walkTrack.Priority = Enum.AnimationPriority.Action
					walkTrack.Looped = true
				end
			end
		end
		if walkTrack and not walkTrack.IsPlaying then
			walkTrack:Play(0.2)
		end
	elseif walkTrack and walkTrack.IsPlaying then
		walkTrack:Stop(0.2)
	end
	local index = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = if plots and type(index) == "number" then plots:FindFirstChild(`Plot{index}`) else nil
	local walker = plot and plot:FindFirstChild("StairWalker")
	if not walker then
		return
	end
	local share = if training then (os.clock() % STEP_CYCLE) / STEP_CYCLE else 0
	for _, child in walker:GetChildren() do
		local number = tonumber(string.match(child.Name, "^Step(%d)$"))
		if number and child:IsA("BasePart") then
			local rest = child:GetAttribute("Rest")
			if typeof(rest) ~= "CFrame" then
				child:SetAttribute("Rest", child.CFrame)
				rest = child.CFrame
			end
			-- Each step moves down and back one step's height and depth, so the stair seems to roll.
			child.CFrame = (rest :: CFrame) * CFrame.new(0, -0.6 * share, -0.9 * share)
		end
	end
end

function MovementController.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function MovementController.Start(_self: any)
	RunService:BindToRenderStep(SLIDE_RENDER, Enum.RenderPriority.Character.Value + 5, step)
	trove:Add(function()
		RunService:UnbindFromRenderStep(SLIDE_RENDER)
	end)
	trove:Connect(RunService.Heartbeat, function()
		local _, humanoid = character()
		animateWalker(humanoid)
	end)
	trove:Add(Remotes.SlideHit:Connect(function(loss: number)
		slideSpeed *= 1 - math.clamp(loss, 0, 1)
		local sound = registry.SoundController
		if sound then
			sound:Play("Scuffle")
		end
	end))
	trove:Add(Remotes.Knockback:Connect(function(direction: Vector3)
		local now = os.clock()
		knockDirection = Vector3.new(direction.X, 0, direction.Z).Unit
		knockUntil = now + GameConfig.SlideHit.KnockSeconds
		stunUntil = now + GameConfig.SlideHit.StunSeconds
		local sound = registry.SoundController
		if sound then
			sound:Play("Yelp")
		end
	end))
	trove:Connect(player.CharacterAdded, function()
		sitTrack = nil
		walkTrack = nil
		sliding = false
		Remotes.Slide:Fire(false)
	end)
end

function MovementController.Destroy(_self: any)
	trove:Clean()
end

function MovementController.IsSliding(_self: any): boolean
	return sliding
end

return MovementController
