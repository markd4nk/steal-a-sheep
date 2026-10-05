--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Wander = require(ReplicatedStorage.Utils.Wander)
local Run = require(script.Parent.Run)

local Motion = GameConfig.SheepMotion

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

return function(t: Run.Suite)
	t.Test("a stroll goes StrollMinDistance to StrollMaxDistance any way, at the same height", function()
		local from = CFrame.new(40, 0.4, -12)
		for angle = 0, 0.875, 0.125 do
			for _, distance in { 0, 0.5, 0.999 } do
				local spot = Wander.Stroll(from, angle, distance)
				local gone = flat(spot.Position, from.Position)
				t.Expect(gone >= Motion.StrollMinDistance - 1e-6).ToBe(true)
				t.Expect(gone <= Motion.StrollMaxDistance + 1e-6).ToBe(true)
				t.Expect(math.abs(spot.Y - from.Y) < 1e-6).ToBe(true)
			end
		end
	end)

	t.Test("a stroll ends facing the way the sheep walked", function()
		local spot = Wander.Stroll(CFrame.new(0, 0, 0), 0, 0.5) -- angle 0: towards +X
		t.Expect(spot.LookVector:Dot(Vector3.xAxis) > 0.99).ToBe(true)
	end)

	t.Test("a turn on the spot stays put and takes TurnAroundSeconds", function()
		local from = CFrame.new(3, 0.4, 3) * CFrame.Angles(0, 1, 0)
		local to = Wander.TurnAround(from, 0.5)
		t.Expect(flat(to.Position, from.Position) < 1e-6).ToBe(true)
		local walk = Wander.Plan(from, to, 10)
		t.Expect(walk.Duration).ToBe(0)
		t.Expect(Wander.Ends(walk)).ToBe(10 + Motion.TurnAroundSeconds)
		local pose, done = Wander.PoseAt(walk, Wander.Ends(walk))
		t.Expect(done).ToBe(true)
		t.Expect(pose.LookVector:Dot(to.LookVector) > 0.999).ToBe(true)
	end)

	t.Test("a stroll turns first, then walks at WanderSpeed with an eased start and end", function()
		local from = CFrame.new(0, 0.4, 0)
		local to = CFrame.new(10, 0.4, 0)
		local walk = Wander.Plan(from, to, 100)
		t.Expect(walk.Turn).ToBe(Motion.WanderTurnSeconds)
		t.Expect(math.abs(walk.Duration - (10 / Motion.WanderSpeed + Motion.EaseSeconds)) < 1e-6).ToBe(true)
		local turning = Wander.PoseAt(walk, 100 + walk.Turn / 2)
		t.Expect(flat(turning.Position, from.Position) < 1e-6).ToBe(true)
		-- Steadily on, never back, and at walking pace in the middle.
		local last = -1
		for step = 0, 40 do
			local now = 100 + walk.Turn + walk.Duration * step / 40
			local pose = Wander.PoseAt(walk, now)
			t.Expect(pose.X >= last - 1e-6).ToBe(true)
			last = pose.X
		end
		local middle = 100 + walk.Turn + walk.Duration / 2
		local pace = (Wander.PoseAt(walk, middle + 0.1).X - Wander.PoseAt(walk, middle).X) / 0.1
		t.Expect(math.abs(pace - Motion.WanderSpeed) < 1e-3).ToBe(true)
		local slow = (Wander.PoseAt(walk, 100 + walk.Turn + 0.05).X - from.X) / 0.05
		t.Expect(slow < Motion.WanderSpeed / 2).ToBe(true)
	end)

	t.Test("a stroll ends on its spot, and anywhere it's asked about after", function()
		local from = CFrame.new(0, 0.4, 0)
		local to = CFrame.new(-3, 0.4, 4)
		local walk = Wander.Plan(from, to, 0)
		local pose, done = Wander.PoseAt(walk, Wander.Ends(walk))
		t.Expect(done).ToBe(true)
		t.Expect(flat(pose.Position, to.Position) < 1e-6).ToBe(true)
		local later, stillDone = Wander.PoseAt(walk, Wander.Ends(walk) + 30)
		t.Expect(stillDone).ToBe(true)
		t.Expect(flat(later.Position, to.Position) < 1e-6).ToBe(true)
		local before, notDone = Wander.PoseAt(walk, -5)
		t.Expect(notDone).ToBe(false)
		t.Expect(flat(before.Position, from.Position) < 1e-6).ToBe(true)
	end)

	t.Test("a short stroll still eases without overshooting", function()
		local from = CFrame.new(0, 0, 0)
		local to = CFrame.new(0.3, 0, 0)
		local walk = Wander.Plan(from, to, 0)
		t.Expect(walk.Ease <= walk.Duration / 2 + 1e-6).ToBe(true)
		for step = 0, 20 do
			local pose = Wander.PoseAt(walk, walk.Turn + walk.Duration * step / 20)
			t.Expect(pose.X >= -1e-6 and pose.X <= 0.3 + 1e-6).ToBe(true)
		end
	end)
end
