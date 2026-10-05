# NPCs (enemies, followers, wanderers)

One server service owns all NPCs of a kind and moves them from one loop. It's a service even without client
requests (`systems.md`).

## Setup

- Keep a template rig in `ServerStorage`. In an Edit-mode `execute_luau`,
  `Players:CreateHumanoidModelFromDescriptionAsync(HumanoidDescription.new(), Enum.HumanoidRigType.R15)` gives a
  full R15 rig. Delete its `Animate` LocalScript: LocalScripts don't run in NPCs.
- An avatar NPC's face: the newer heads (the default one too) are animated (`FaceControls` on the head) and ignore
  `HumanoidDescription.Face`. Their expression comes from a mood animation that `Animate` plays, so an NPC shows a
  neutral face. A mood's catalog id (`HumanoidDescription.MoodAnimation`) isn't a clip an `Animator` can load
  ("AnimationClip loaded is not valid"): in Edit, `InsertService:LoadAsset(id)` and use its
  `R15Anim.mood.Animation1` id. To hold an expression with no animation at all (and in Edit), set the head's
  `FaceControls` properties (`LeftLipCornerPuller`, `RightLipCornerPuller`, `JawDrop`...). In Edit the rig's
  accessories sit where they were authored until their welds settle: put each `Handle` on its matching body
  `Attachment` (`attachment.WorldCFrame * handleAttachment.CFrame:Inverse()`).
  https://create.roblox.com/docs/reference/engine/classes/FaceControls
- For a non-human NPC (a pet), a Humanoid model with an invisible `HumanoidRootPart`, massless cosmetic parts
  welded to it and `RequiresNeck = false` works with `MoveTo` and pathfinding. A legless Humanoid can only
  step onto ledges lower than its `HipHeight`, so keep it above the steps in your map (a 1-stud spawn pad
  needs more than 1).
- Clone it, parent it into a workspace folder, then call `root:SetNetworkOwner(nil)`. It only works once the
  model is in the workspace. The server then simulates the NPC and no client can move it.
- Put NPC parts in a collision group that doesn't collide with itself (`GOTCHAS.md`, collision groups).
  Without one, a crowd climbs over itself and onto the player. Register groups in Studio's Collision Groups
  editor at edit time, since runtime registration costs time per part in the world. If code must, register
  once in `Start` behind `IsCollisionGroupRegistered`.

## Movement

- Tick every NPC from one loop (0.1-0.2 s), not a thread per NPC.
- Create one path per NPC with `PathfindingService:CreatePath({ AgentRadius = ..., AgentHeight = ...,
  AgentCanJump = ... })`. `Path:ComputeAsync` yields, so run it in `task.spawn` with an "is computing" flag;
  never call it from a lifecycle hook or the tick itself.
- To chase a moving target:
  - When a shapecast (`workspace:Blockcast`) towards the target is clear, `Humanoid:MoveTo(target)` directly.
    Shapecasts ignore parts they start inside, so an NPC already pressed against a ledge or wall sees a clear
    line and pushes into it forever. Cast a box a little narrower than the NPC.
  - Otherwise follow waypoints from `Path:GetWaypoints()`, moving on to the next one within ~2 studs.
  - Recompute about every second, or sooner when the target has moved a few studs.
- Stop just short of the target (~2.5 studs) by calling `MoveTo` on the NPC's own position.
- Add a stuck check: under ~0.5 studs of progress in 1 s → switch to a path; still stuck after a few seconds →
  teleport next to the target (followers) or give up (enemies).
- An NPC that only follows set points (a patrol, a route to a gate) doesn't need a Humanoid or pathfinding. Leave
  its root unanchored, weld or motor every other part to it (massless, `CanCollide`, `CanTouch` and `CanQuery` off),
  and drive it with an `AlignPosition` and an `AlignOrientation` in `OneAttachment` mode: set `Position` to the next
  point, `MaxVelocity` to its speed, and move on when it's within about a stud (flat distance). After
  `root:SetNetworkOwner(nil)` the server simulates it and every client sees it glide; call it again after welding
  something new on. It held exact speeds in server logs, never tripped or stuck, and 100 of them kept the server at
  60 physics fps.

## Followers (pets, companions)

- Aim for a spot behind the owner: their root position minus their flat look vector × the follow distance.
- Within an arrive radius, stop once (`MoveTo` its own position, then set a flag so you don't reissue it every
  tick).
- Past ~60 studs (respawns, teleports), `PivotTo` it next to the owner instead of walking.
- Put followers and characters in collision groups that don't collide, so owners don't trip over their pet.
  Characters need their group set on `CharacterAdded` and `DescendantAdded`. Setting
  `RaycastParams.CollisionGroup` to the followers' group makes the clear-line cast skip both groups with no
  filter list to maintain.
- The official pathfinding sample reads the deprecated `Velocity`; `check.ps1` rejects a copy. Use
  `AssemblyLinearVelocity`.

## Damage, death and cleanup

- Deal contact damage from the tick with an overlap query (`workspace:GetPartBoundsInBox` around the NPC's
  bounds, grown by about a stud), scaled by the tick length. `Touched` is unreliable for continuous contact.
- The server damages the NPC's `Humanoid`. On death, fire a `Signal` on the service (e.g.
  `ZombieKilled(killer)`) so other systems react without the NPC service knowing about them.
- Destroy NPCs when their round or area ends, and in the service's `Destroy`.

## Animation

Play NPC animations on the server through the Humanoid's `Animator` (`Animator:LoadAnimation`); they replicate
to clients. For custom rigs, Animation Editor drafts, and many cosmetic animals animated on each client instead, see
`animations.md`.

References: https://create.roblox.com/docs/characters/pathfinding ·
https://create.roblox.com/docs/scripting/security/network-ownership
