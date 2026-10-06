--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BodyClips = require(ReplicatedStorage.Utils.BodyClips)
local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Run = require(script.Parent.Run)

-- A god's measurements (Pan, 2026-10-06): the Root joint 3.62 studs up, a chest 0.83 deep, arms hanging down.
local GOD: BodyClips.Body = {
	Joint = 3.62,
	Belly = 0.88,
	Arms = {
		Left = { Turn = CFrame.identity, Down = Vector3.new(0, -1, 0) },
		Right = { Turn = CFrame.identity, Down = Vector3.new(0, -1, 0) },
	},
}

-- A skinned avatar resting in a T-pose: its arms point out sideways.
local TPOSE: BodyClips.Body = {
	Joint = 2.4,
	Belly = 0.6,
	Arms = {
		Left = { Turn = CFrame.identity, Down = Vector3.new(-1, 0, 0) },
		Right = { Turn = CFrame.identity, Down = Vector3.new(1, 0, 0) },
	},
}

local function finite(frame: CFrame): boolean
	for _, value in { frame:GetComponents() } do
		if value ~= value or math.abs(value) == math.huge then
			return false
		end
	end
	return true
end

local function same(a: BodyClips.Pose, b: BodyClips.Pose): boolean
	for joint, frame in a do
		local other = b[joint] or CFrame.identity
		if (frame.Position - other.Position).Magnitude > 1e-4 or frame.LookVector:Dot(other.LookVector) < 0.9999 then
			return false
		end
		if frame.UpVector:Dot(other.UpVector) < 0.9999 then
			return false
		end
	end
	for joint, frame in b do
		if
			not a[joint] and (frame.Position.Magnitude > 1e-4 or frame.LookVector:Dot(Vector3.new(0, 0, -1)) < 0.9999)
		then
			return false
		end
	end
	return true
end

return function(t: Run.Suite)
	t.Test("every clip gives a real transform for each joint it poses", function()
		local ok = true
		for _, clip in { "Lunge", "Belly", "GetUp", "Surf" } do
			for step = 0, 40 do
				for _, frame in BodyClips.Sample(clip, step * 0.05, GOD) do
					ok = ok and finite(frame)
				end
			end
		end
		t.Expect(ok).ToBe(true)
	end)

	t.Test("the lunge lands in the belly glide, and getting up starts from it and ends standing", function()
		local glide = BodyClips.Sample("Belly", 0, GOD)
		t.Expect(same(BodyClips.Sample("Lunge", BodyClips.LungeSeconds, GOD), glide)).ToBe(true)
		t.Expect(same(BodyClips.Sample("GetUp", 0, GOD), glide)).ToBe(true)
		t.Expect(same(BodyClips.Sample("GetUp", BodyClips.GetUpSeconds, GOD), {})).ToBe(true)
		t.Expect(same(BodyClips.Sample("Lunge", 0, GOD), {})).ToBe(true)
	end)

	t.Test("on its belly the chest's front rests on the floor", function()
		local root = BodyClips.Sample("Belly", 0, GOD).Root :: CFrame
		-- Lying flat, the chest's front faces down, Belly from the joint's axis.
		local chest = root * Vector3.new(0, 0, -GOD.Belly + 0.05)
		t.Expect(math.abs(GOD.Joint + chest.Y - 0.05) < 1e-6).ToBe(true)
		t.Expect(root.UpVector:Dot(Vector3.new(0, 0, -1)) > 0.99).ToBe(true)
	end)

	t.Test("the surf loops smoothly and keeps the arms out for balance on any rest pose", function()
		t.Expect(same(BodyClips.Sample("Surf", 0, GOD), BodyClips.Sample("Surf", 1.8, GOD))).ToBe(true)
		for _, body in { GOD, TPOSE } do
			local pose = BodyClips.Sample("Surf", 0, body)
			local left = (pose.LeftShoulder :: CFrame) * body.Arms.Left.Down
			local right = (pose.RightShoulder :: CFrame) * body.Arms.Right.Down
			t.Expect(left.X < -0.8 and right.X > 0.8).ToBe(true)
		end
	end)

	t.Test("the dive carries a god faster, and only the dive", function()
		local lunge = GameConfig.Theft.Lunge
		t.Expect(Economy.LungeShare(0)).ToBe(1)
		t.Expect(Economy.LungeShare(lunge.DiveFrom)).ToBe(lunge.DiveSpeed)
		t.Expect(Economy.LungeShare((lunge.DiveFrom + lunge.DiveTo) / 2)).ToBe(lunge.DiveSpeed)
		t.Expect(Economy.LungeShare(lunge.DiveTo)).ToBe(1)
		t.Expect(Economy.LungeShare(60)).ToBe(1)
		t.Expect(lunge.DiveTo <= lunge.Seconds).ToBe(true)
	end)
end
