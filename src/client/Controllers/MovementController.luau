--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Mountain = require(ReplicatedStorage.Utils.Mountain)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- How the local character moves. Walking: as fast as the player's Climbing allows here, for the lamb's hidden weight
-- (Mountain.SpeedAt; the server checks the uphill part): slower than normal only up a slope too steep for them,
-- faster the more they've outgrown it. Sliding:
-- moving downhill on the ramp starts a slide by itself; it speeds up to the escape speed set when it starts
-- (Mountain.SlideBase: Climbing against the lamb's tier and weight), then gains momentum for every tier it passes
-- (Mountain.Momentum, from the lamb's tier, or where it began empty-handed); a bump costs speed, won back almost at
-- once, and never trips the character over. It steers within a cone either side of straight downhill with the ordinary movement controls, brakes when
-- pulled back, and stops dead at the safety line: the plots are walked. A slider's hit costs it speed; a hit player is
-- moved back down the slope and stunned for a moment; a god's punch flies them down the mountain (Remotes.Punch).
-- The stair walker is WalkerController's.
local MovementController = { Name = "MovementController" }

local SLIDE_RENDER = "SlideControl"
-- R15 characters surf down instead, posed on every device (SlideController).
local SIT_R6 = "rbxassetid://178130996"
local PUNCH_ARC = 0.12 -- a punch's arc peaks this share of its length above the straight line (20 to 120 studs)

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local player = Players.LocalPlayer

local sliding = false
local slideSpeed = 0
local slideTarget = 0
local slideFrom = 1 -- the tier its momentum counts from
local recovering = false -- knocked under its speed by a bump: it gets back up quickly
local recoverUntil = 0 -- os.clock() until which a new slide recovers quickly too (it ended stuck)
local heading = Mountain.Downhill
local knockUntil = 0
local stunUntil = 0
-- A god's punch in flight: from where to where, when it started and how long it takes.
type Flight = { From: Vector3, To: Vector3, Start: number, Seconds: number }
local flight: Flight? = nil
local knockDirection = Vector3.zero
local stuckFor = 0
local sitTrack: AnimationTrack? = nil

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

-- The carried lamb's tier and hidden weight, or nil when empty-handed.
local function carried(): (number?, number?)
	if player:GetAttribute("Carrying") ~= true then
		return nil, nil
	end
	local tier = player:GetAttribute("CarryTier")
	local weight = player:GetAttribute("CarryWeight")
	if type(tier) ~= "number" or type(weight) ~= "number" then
		return nil, nil
	end
	return tier, weight
end

-- The speed a slide starting at `x` builds its momentum on (Mountain.SlideBase), and the tier the momentum counts from.
local function slideStart(x: number): (number, number)
	local tier, weight = carried()
	if tier and weight then
		return Mountain.SlideBase(climbing(), tier, weight), tier
	end
	local here = math.max(Mountain.TierAt(x), 1)
	return Mountain.SlideBase(climbing(), here, 1), here
end

-- Walking speed here (Mountain.SpeedAt, for the carried weight). Faster than normal it's the same every way; slower,
-- only the move's uphill part is held down to it, so a player on a slope too steep for them can still cross it or
-- come back down at normal speed.
local function walkSpeed(position: Vector3, input: Vector3): number
	local _, weight = carried()
	local speed = Mountain.SpeedAt(position.X, climbing(), weight or 1)
	local normal = GameConfig.Movement.WalkSpeed
	if speed >= normal then
		return speed
	end
	if input.X <= 0 then
		return normal
	end
	return math.min(normal, speed / input.X)
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

-- A slide that hits something at speed would otherwise trip the character onto the floor for a second or two.
local function keepOnFeet(model: Model)
	local humanoid = model:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	end
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
		if humanoid and not sitTrack and humanoid.RigType == Enum.HumanoidRigType.R6 then
			sitTrack = loadTrack(humanoid, SIT_R6)
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
	local walk = GameConfig.Movement.WalkSpeed
	local boost = speedBoost()
	local settings = GameConfig.Movement

	-- Punched by a god: tumbling along a high arc down the mountain, then held still for a moment on landing.
	local punched = flight
	if punched then
		setSliding(false, humanoid)
		humanoid:Move(Vector3.zero, false)
		local t = (now - punched.Start) / punched.Seconds
		if t >= 1 then
			flight = nil
			humanoid.PlatformStand = false
			root.CFrame = CFrame.lookAlong(punched.To, Mountain.Downhill)
			root.AssemblyLinearVelocity = Vector3.zero
			stunUntil = now + GameConfig.Theft.PunchStun
			knockUntil = 0
			local sound = registry.SoundController
			if sound then
				sound:Play("Land")
			end
			return
		end
		humanoid.PlatformStand = true
		local span = (punched.To - punched.From).Magnitude
		local height = math.clamp(span * PUNCH_ARC, 20, 120) * 4 * t * (1 - t)
		local at = punched.From:Lerp(punched.To, t) + Vector3.new(0, height, 0)
		root.CFrame = CFrame.lookAlong(at, Mountain.Downhill) * CFrame.Angles(-t * math.pi * 4, 0, 0)
		root.AssemblyLinearVelocity = Vector3.zero
		return
	end

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
		humanoid.WalkSpeed = walkSpeed(position, input) * boost
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
			slideTarget, slideFrom = slideStart(position.X)
			recovering = now < recoverUntil
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

	-- Sliding. The safety line stops it dead, so nobody is carried on into the plots: from there they walk.
	if position.X < Olympus.SafeLineX then
		setSliding(false, humanoid)
		humanoid.WalkSpeed = walkSpeed(position, input) * boost
		root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
		return
	end
	if not onRamp and grounded then
		setSliding(false, humanoid)
		humanoid.WalkSpeed = walk * boost
		return
	end
	local target = slideTarget * Mountain.Momentum(slideTarget, slideFrom, position.X)
	if input.X > 0.35 then
		slideSpeed = math.max(0, slideSpeed - settings.SlideBrake * dt)
	elseif grounded then
		if slideSpeed < target then
			local rise = if recovering then settings.SlideRecoverSeconds else settings.SlideRiseSeconds
			slideSpeed = math.min(target, slideSpeed + math.max(settings.SlideAccel, target / rise) * dt)
			recovering = recovering and slideSpeed < target
		else
			slideSpeed = math.max(target, slideSpeed - settings.SlideAccel * 0.5 * dt)
		end
	end
	-- Scenery hit: the slide carries on from the speed the character really has, once a bump: still against it, it
	-- pushes back up to speed, so steering slides the character off fast. It ends if it stays stuck.
	local actual = Vector2.new(velocity.X, velocity.Z).Magnitude
	if grounded and actual < slideSpeed * 0.6 and not recovering then
		slideSpeed = math.max(actual + 4, settings.SlideStopSpeed)
		recovering = true
	end
	stuckFor = if actual < settings.SlideStopSpeed then stuckFor + dt else 0
	if stuckFor > 0.5 then
		stuckFor = 0
		recoverUntil = now + settings.SlideRiseSeconds
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

function MovementController.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function MovementController.Start(_self: any)
	RunService:BindToRenderStep(SLIDE_RENDER, Enum.RenderPriority.Character.Value + 5, step)
	trove:Add(function()
		RunService:UnbindFromRenderStep(SLIDE_RENDER)
	end)
	trove:Add(Remotes.SlideHit:Connect(function(loss: number)
		slideSpeed *= 1 - math.clamp(loss, 0, 1)
		local sound = registry.SoundController
		if sound then
			sound:Play("Scuffle")
		end
	end))
	trove:Add(Remotes.Punch:Connect(function(landing: Vector3, seconds: number)
		local _, _, root = character()
		if not root then
			return
		end
		flight = { From = root.Position, To = landing, Start = os.clock(), Seconds = math.max(seconds, 0.3) }
		-- The punch itself sounds from the god (GodController); this is the thief flying off.
		local sound = registry.SoundController
		if sound then
			sound:Play("Fly")
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
	if player.Character then
		task.spawn(keepOnFeet, player.Character)
	end
	trove:Connect(player.CharacterAdded, function(model: Model)
		task.spawn(keepOnFeet, model)
		flight = nil
		sitTrack = nil
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
