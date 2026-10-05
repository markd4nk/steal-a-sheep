# Characters, tools and input

## Moving characters within the place

- The server moves a character with `character:PivotTo(cframe)`, aimed a few studs above the floor so it lands
  on it. Never take a position from the client. `TeleportService` is only for other places and servers
  (`DEPRECATIONS.md`, Teleports).
- Respawns use `SpawnLocation`s. The Baseplate template has one at the origin; move or delete it when the design
  says where players spawn.
- Per-life state (in a round, holding a boost) ends on `Humanoid.Died` **and** `Player.CharacterRemoving`, which
  also covers respawns without dying. Each life is a new character: redo per-character connections on
  `CharacterAdded`.

## Tools

- A `Tool` gives click, tap and gamepad activation with no input code, so prefer one for anything the player
  uses in their hands.
- Keep the template in `ServerStorage`. The server clones it into `player.Backpack` and can equip it with
  `Humanoid:EquipTool(tool)`. Set `CanBeDropped = false` unless dropping is a feature.
- Take a tool away by destroying it. Look in both the Backpack and the character, since an equipped tool is
  parented to the character. The Backpack empties on respawn, so give tools again on `CharacterAdded` if they
  should last.
- Activation is client input. The tools guide says tool events fire only on the client (older class-reference
  samples use them in server Scripts); either way, treat it as a request. A controller connects
  `Tool.Activated` while the tool is in the character (watch the character's `ChildAdded`) and fires a
  no-argument Net remote. The server decides everything else.
- Free swing animation: parent a `StringValue` named `toolanim` with Value `"Slash"` (or `"Lunge"`) to the
  equipped tool. The default `Animate` script plays it and removes the value; the local character's animations
  replicate.

## Posing arms from code

For a hold the default animations don't have (lifting something overhead, holding a prop out), pose the joints on
every client, so nothing replicates:

- Set the joints' `Transform` after the Animator writes it (`RunService.PreSimulation`) and put the old value back
  after the frame's physics (`PostSimulation`), so walking keeps its legs and the next frame starts clean. R15
  characters with the Avatar Joint Upgrade have an `AnimationConstraint` where the `Motor6D` was; both have
  `Transform`, between the same two frames (the constraint's attachments stand in for `C0` and `C1`).
- Aim each arm part by the direction it should point, not by angles from rest. Rest poses differ: blocky arms hang
  down, but some skinned avatars rest in a T-pose, so an identity `Transform` holds their arms out sideways and the
  same angles that swing a blocky arm forward swing theirs to the side (seen 2026-10-03). Measure where each joint
  sits at rest (shoulder, elbow, wrist, from `C0` and `C1`), turn the upper arm's rest direction onto the target with
  the smallest rotation about the shoulder, then the forearm's in the upper arm's own space.
- A prop held for show, with nothing to click, is better as a client-side copy welded to the hand than as a `Tool`:
  nothing to equip, no backpack. Set the copy's `Archivable = false`, or a script that clones the character (a
  cutscene's double) clones a frozen copy along with it, and copy the hand's `LocalTransparencyModifier` onto it each
  frame, so first person and scripts that hide the character hide the prop too.

## Melee hits

The client only says "I swung". The server works out the rest from its own positions:

- The tool is equipped and the player is alive.
- The cooldown has passed, with ~0.05 s of tolerance for network jitter.
- The target is within range of the player's root part (design range + ~1.5 studs of tolerance).
- The target is in front: the flat look vector dotted with the flat direction to the target is at least ~0.25.

Rate-limit the remote a little above the honest maximum (4/s for a 0.5 s cooldown). Keep target selection a
pure function of positions so it can be unit-tested.

## Input on every device

- Tools and GUI buttons work with mouse, touch and gamepad without extra code. For other actions,
  `ContextActionService:BindAction(name, handler, true, ...)` binds keys and gamepad buttons, and the `true`
  adds an on-screen touch button.
- The Studio MCP can click but can't emulate touch or gamepad. `testing-studio.md` has what to do
  instead.

References: https://create.roblox.com/docs/players/tools ·
https://create.roblox.com/docs/reference/engine/classes/Tool ·
https://create.roblox.com/docs/reference/engine/classes/ContextActionService
