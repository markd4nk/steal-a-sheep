--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChaseFeel = require(ReplicatedStorage.Utils.ChaseFeel)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Run = require(script.Parent.Run)
local Sounds = require(ReplicatedStorage.Config.Sounds)

local Chase = GameConfig.Chase

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return function(t: Run.Suite)
	t.Test("the level is 1 at NearStuds and closer, 0 at FarStuds and further, rising as the god closes", function()
		t.Expect(ChaseFeel.Level(0)).ToBe(1)
		t.Expect(ChaseFeel.Level(Chase.NearStuds)).ToBe(1)
		t.Expect(ChaseFeel.Level(Chase.FarStuds)).ToBe(0)
		t.Expect(ChaseFeel.Level(Chase.FarStuds * 3)).ToBe(0)
		local last = -1
		for distance = Chase.FarStuds, Chase.NearStuds, -4 do
			local level = ChaseFeel.Level(distance)
			t.Expect(level >= last).ToBe(true)
			last = level
		end
	end)

	t.Test("the heartbeat runs HeartbeatBpm, quicker and louder as the level rises", function()
		t.Expect(near(ChaseFeel.BeatSeconds(0), 60 / Chase.HeartbeatBpm[1])).ToBe(true)
		t.Expect(near(ChaseFeel.BeatSeconds(1), 60 / Chase.HeartbeatBpm[2])).ToBe(true)
		local slowSpeed, quiet = ChaseFeel.Beat(0)
		local fastSpeed, loud = ChaseFeel.Beat(1)
		t.Expect(slowSpeed).ToBe(1)
		t.Expect(near(quiet, Chase.HeartbeatQuiet)).ToBe(true)
		t.Expect(fastSpeed > slowSpeed).ToBe(true)
		t.Expect(loud).ToBe(1)
		-- At the fastest, beats overlap their tails: the pool's voices cover it, so none is cut off.
		local beat = Sounds.Effects.Heartbeat
		local voices = beat.Voices or 1
		t.Expect((beat.Length or 0) / fastSpeed < voices * ChaseFeel.BeatSeconds(1)).ToBe(true)
	end)

	t.Test("the drums are out below DrumsFrom and all in from DrumsFull", function()
		t.Expect(ChaseFeel.Drums(0)).ToBe(0)
		t.Expect(ChaseFeel.Drums(Chase.DrumsFrom)).ToBe(0)
		t.Expect(ChaseFeel.Drums(Chase.DrumsFull)).ToBe(1)
		t.Expect(ChaseFeel.Drums(1)).ToBe(1)
	end)

	t.Test("the red edges throb on a heartbeat and settle back between beats", function()
		for _, level in { 0, 0.5, 1 } do
			local settled = ChaseFeel.Edges(level, 10)
			local throb = ChaseFeel.Edges(level, 0)
			t.Expect(throb > settled).ToBe(true)
			t.Expect(throb <= 1).ToBe(true)
		end
		t.Expect(ChaseFeel.Edges(1, 10) > ChaseFeel.Edges(0, 10)).ToBe(true)
	end)

	t.Test("every god's line is a sound, and both voices have lines for every moment", function()
		for _, voice in { "God", "Goddess" } do
			local cast = Sounds.Voices[voice]
			t.Expect(cast ~= nil).ToBe(true)
			for _, moment in { "Roar", "Yell", "Snarl", "Laugh", "Frustrated" } do
				local lines = cast[moment]
				t.Expect(lines ~= nil and #lines > 0).ToBe(true)
				for _, name in lines do
					t.Expect(Sounds.Effects[name] ~= nil).ToBe(true)
				end
			end
		end
	end)

	t.Test("a faster god steps more often, within the run clip's speed limits", function()
		local runStuds = 21
		t.Expect(near(ChaseFeel.StepSeconds(runStuds, runStuds), Chase.StepSeconds)).ToBe(true)
		t.Expect(ChaseFeel.StepSeconds(40, runStuds) < ChaseFeel.StepSeconds(20, runStuds)).ToBe(true)
		t.Expect(near(ChaseFeel.StepSeconds(1000, runStuds), Chase.StepSeconds / 2.4)).ToBe(true)
	end)
end
