# Rigs and animations

For animals, creatures and props that move by Animation Editor animations. Player characters use Roblox's own rig
(`characters.md`); what NPCs do is in `npcs.md`.

## The rig

- One `Motor6D` per moving piece. Parent it inside the piece it moves and name it after that piece, as the 3D
  Importer does with a rigged mesh. Pose names are part names: the Animator applies a pose to the Motor6D joining
  that part to the part of its parent pose.
- Give every joint axes that line up with the model (C0 and C1 without rotation), so one rule covers every key:
  around X tips forward or back, Y turns, Z rolls. Write down which sign lifts a head or swings a leg forward.
- Make the PrimaryPart a small invisible `Root`, the only anchored part, with everything else unanchored, massless
  and `CanCollide` off. Set its `PivotOffset` so the model's pivot is on the ground between the feet: `PivotTo` a
  spawn spot then puts the feet on the floor. Root never animates; bobbing and hops go on the body's joint.
- Things that only follow (eyes, fur, wool, add-ons) are welded, not jointed, and stay out of animations.
- Add an `AnimationController` with an `Animator` for rigs without a Humanoid. An anchored Root animates fine.
- Keep piece sizes, joint pivots and attachment points in one layout module that the Studio build script reads. A
  later swap from blocks to meshes then keeps every joint where the animations expect it.
- The Animation Editor only opens rigs in the Workspace. Keep the rig there in Edit and have its service move it to
  `ServerStorage` when a game starts, so there is one rig to animate and to clone.

## Making drafts by script

A script can make first drafts as `KeyframeSequence`s for someone to polish in the editor.

- A keyframe holds a pose for each joint keyed at that time, nested by the joint tree from Root. A parent pose with
  `Weight = 0` counts as not keyed: the joint keeps moving between its real keys (verified: a head keyed 0 and 40
  degrees read 20 halfway, through a weight-0 pose). Before its first key a joint sits at rest and then jumps, so
  key every moving joint at 0 and at the end.
- `EasingStyle` and `EasingDirection` on a pose say how it moves on to the next key. Use `CubicV2`, which behaves
  like standard easing (`Out` starts fast); `Cubic` is deprecated because its directions come out reversed between
  the editor and the game. `Bounce` with `Out` bounces at the end: a landing.
- Set `Loop` and `Priority` on the sequence. Markers are `KeyframeMarker`s added with `Keyframe:AddMarker`, read with
  `AnimationTrack:GetMarkerReachedSignal(name)`.
- A script that remakes drafts must not overwrite them by default: after polishing, the editor's copy is the truth.

## Playing them

- Few NPCs whose poses matter to everyone (an attack wind-up): play on the server through the Animator; tracks
  replicate (`npcs.md`).
- Many cosmetic animals: play on each client. Animations a client plays on a model it doesn't own don't replicate,
  so the server only sends state and positions (attributes), and each device animates what it can see:
  - Animate only the nearest N within a range of the camera (a player can't see more than a pen or two); stop every
    track (`Stop(0)`) past it, with a few studs of slack so the edge doesn't flicker. Re-pick every ~0.2 s.
  - Start looping tracks at a random point once they've loaded (`TimePosition = random * Length` when `Length > 0`),
    so a herd doesn't move in step.
  - A client can move an anchored rig it doesn't own, locally, with `workspace:BulkMoveTo` on the Root; it stays
    there until the server next changes that part's `CFrame`.
- A higher-priority track overrides only the joints it keys; the rest fall through to lower tracks (an Idle keeps
  breathing under a Graze that only moves the head).
- With deferred signals (the default), marker and `AnimationPlayed` handlers run after the current code yields: in a
  test, `task.wait()` before reading what they counted.
- `Model:ScaleTo` scales the rig, its joints, its `PivotOffset` and how far animations move it (a 0.6-stud hop
  measured 0.48 on a model scaled to 0.8), so one set of animations fits every size.
- Put published ids in Config (with the desktop tools an agent can publish the drafts: `desktop-recipes.md`,
  Publish animations). Until then, Studio playtests can play the drafts: drafts in `ServerStorage` never reach
  clients, so in Studio the server copies them into a `ReplicatedStorage` folder and each client calls
  `KeyframeSequenceProvider:RegisterKeyframeSequence` for a temporary id. Those ids only work in Studio.
- Since July 2025, playtesting an animation in a game gives that game permission to use it, even when another
  account or group owns it. If one still fails live, add it under the game's Configure > Permissions.

## Checking them without playing

- `Animator:StepAnimations(0)` works in Edit: load a track, `Play(0)`, `AdjustSpeed(0)`, set `TimePosition`, step,
  then read each Motor6D's `Transform` or take a screenshot of the pose. Wait for `track.Length > 0` first.
- Use a fresh copy of the rig for each animation: a stopped track keeps its weight while no time passes, so it
  blends into the next one's readings.
- To screenshot poses in Edit without the HUD, set `StarterGui.ShowDevelopmentGui = false`, and back afterwards.
- In Shear a Sheep, 300 animals of 22-30 parts, 60 of them animating, cost about 0.7 ms of render CPU and held
  60 fps on PC and in the Device Simulator (2026-09-28).

References: https://create.roblox.com/docs/animation/editor ·
https://create.roblox.com/docs/reference/engine/classes/KeyframeSequenceProvider ·
https://create.roblox.com/docs/reference/engine/classes/Pose ·
https://create.roblox.com/docs/reference/engine/classes/AnimationTrack ·
https://devforum.roblox.com/t/animation-does-not-replicate-when-played-on-client/750912 ·
https://devforum.roblox.com/t/improving-animation-asset-permissions/3852101
