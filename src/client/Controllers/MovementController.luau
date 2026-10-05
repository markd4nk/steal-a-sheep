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

-- How the local character moves. Walking: the design's 18 studs a second, times a carried lamb's burden share. Sliding:
-- moving downhill on the ramp starts a slide by itself; it speeds up to the stretch's slide speed (the burden slows it
-- and its acceleration), steers within a cone either side of straight downhill with the ordinary movement controls,
-- brakes when pulled back, and runs out to a stop past the safety line. A slider's hit costs it speed; a hit player is
-- moved back down the slope and stunned for a moment. Also: the climb gates a player has opened stop colliding on
-- their own device, and their stair walker steps while they train.
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

-- The burden share a carried lamb leaves the player (Economy.CarryMultiplier), 1 when empty-handed.
local function carryShare(): number
	if player:GetAttribute("Carrying") ~= true then
		return 1
	end
	local burden = player:GetAttribute("CarryBurden")
	local tier = player:GetAttribute("CarryTier")
	local climb = player:GetAttribute("ClimbPower")
	if type(burden) ~= "number" or type(tier) ~= "number" then
		return 1
	end
	return Economy.CarryMultiplier(burden, if type(climb) == "number" then climb else 0, tier)
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
		humanoid.WalkSpeed = walk * boost
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
	local target = if pastLine then 0 else Mountain.SlideSpeedAt(position.X) * share
	local braking = input.X > 0.35
	if braking or pastLine then
		-- Past the safety line the slide runs out more gently than a pulled-back brake.
		local brake = if braking then settings.SlideBrake else settings.SlideBrake * 0.4
		slideSpeed = math.max(0, slideSpeed - brake * dt)
	elseif grounded then
		if slideSpeed < target then
			slideSpeed = math.min(target, slideSpeed + settings.SlideAccel * share * dt)
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
end

-- Gates this player has opened stop colliding here (MountainService builds them; the server still checks).
local function refreshGates()
	local folder = workspace:FindFirstChild("ClimbGates")
	local unlocked = player:GetAttribute("Unlocked")
	local open = if type(unlocked) == "number" then unlocked else 1
	if not folder then
		return
	end
	for _, gate in folder:GetChildren() do
		local tier = gate:GetAttribute("Tier")
		local wall = gate:FindFirstChild("Wall")
		local sign = gate:FindFirstChild("Sign")
		if type(tier) == "number" and wall and wall:IsA("BasePart") then
			local passable = tier <= open
			wall.CanCollide = not passable
			wall.Transparency = if passable then 1 else 0.2
			local gui = sign and sign:FindFirstChildOfClass("SurfaceGui")
			if gui then
				gui.Enabled = not passable
			end
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
	trove:Connect(player:GetAttributeChangedSignal("Unlocked"), refreshGates)
	task.spawn(function()
		local folder = workspace:WaitForChild("ClimbGates", 60)
		if folder then
			trove:Connect(folder.ChildAdded, refreshGates)
			refreshGates()
		end
	end)
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
