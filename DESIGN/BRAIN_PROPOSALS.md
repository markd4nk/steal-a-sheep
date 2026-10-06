# BRAIN proposals

Lessons proposed for the shared files (`BRAIN/`, `AGENTS.md`, the shared scripts), waiting for the user. Each has an
id, where it would go, the text as it would read there, and how and when it was seen. The user approves by id; the
agent then applies the text, adds a line to `BRAIN/CHANGELOG.md`, moves the id to *Done* with the date, and runs
`./scripts/brain-sync.ps1 -ToPack`.

## Waiting

- **S11** (`BRAIN/GOTCHAS.md`): "Roblox's moderation removes AI-generated limb meshes as if they broke the rules:
  `generate_mesh` split two characters into head, torso, arms and legs, and within the hour two of the bare-skin limbs
  (a leg, an arm: smooth skin-coloured tubes with rounded ends) were removed, with a notice to the account. Don't
  split generated characters into bare limbs; generate them clothed, or whole. The public asset details
  (`economy.roblox.com/v2/assets/<id>/details`) and Studio's cache still showed the removed meshes as fine, so only the
  notice tells you." Seen 2026-10-05 making Steal a Sheep's Zeus mock-ups.
- **S9** (`BRAIN/PATTERNS/testing-studio.md`): "`generate_mesh` reads `partNames` as one comma-separated string: a JSON
  list passed through it keeps its brackets and quotes in the part names (`[\"head\"_geom`). Pass `head, torso, left
  arm`. The result is a Model named after the prompt, one Model per part holding a MeshPart `<part>_geom`, dropped
  far from the map at the camera's focus; the mesh is published to the creator (`publishedAssetId` in the job result),
  so `insert_asset` brings it back later. Run it with `async` and collect with `wait_job_finished`: two in parallel
  took about four minutes." Seen 2026-10-05 making Steal a Sheep's Zeus mock-ups.
- **S10** (`BRAIN/PATTERNS/testing-studio.md`): "`screen_capture` calls sent in parallel to one Studio time out (two of
  three did); send them one at a time." Seen 2026-10-05.
- **S1** (`BRAIN/PATTERNS/characters.md`): "PlayerScripts may have no `PlayerModule`: in Studio 2026-10 the default
  control scripts weren't there, so `require(PlayerModule):GetControls():GetMoveVector()` is gone. Read the player's
  input as `Humanoid.MoveDirection` in a RenderStep bound after `Enum.RenderPriority.Character` (it still holds what
  Roblox's controls asked for this frame), then call `Humanoid:Move` in the same step to override the frame's
  movement." Seen 2026-10-05 building Steal a Sheep's slide: the slide never started until it read MoveDirection.
- **S2** (`BRAIN/PATTERNS/testing-studio.md`): "The Studio MCP server can be driven from a script (StudioMCP.exe in the
  Studio version folder speaks JSON-RPC over stdio: `initialize`, then `tools/call`), which lets a session without the
  MCP configured test in Studio. Always pick the Studio by name from `list_roblox_studios` and refuse any other: several
  Studios can be open. `screen_capture` with `camera_position` leaves Freecam on, which then swallows mouse clicks:
  restart the playtest after it. A minimized Studio window captures UI but no ViewportFrame contents." Seen 2026-10-05.
- **S3** (`BRAIN/GOTCHAS.md`): "Lune 0.10.5 panics ('Cannot clone an instance that does not exist') serializing clones
  of a place's instances with `roblox.serializeModel`; serialize the originals instead (trimmed in memory)." Seen
  2026-10-05 extracting Shear a Sheep's sheep rig.

- **S4** (`BRAIN/PATTERNS/characters.md`): "A Humanoid moves its WalkSpeed along the slope it stands on, so it covers
  WalkSpeed x cos(grade) across the ground (60 on 52 degrees: 37 studs/s of x). Anything a script moves beside it (NPCs
  stepped by AlignPosition or CFrame) must measure its steps along the slope too, or on steep ground it outruns
  players." Seen 2026-10-05 in Steal a Sheep: gods chasing at 0.88 of a slider's speed caught every thief on 52 degrees.
- **S5** (`BRAIN/PATTERNS/characters.md`): "A Humanoid driven fast down a steep slope leaves the floor: sliding at 60
  studs/s down 45-52 degrees it was in the air a third of the time. Each frame after your Move, cap its vertical
  velocity at minus (horizontal speed x slope) unless it's Jumping: it then stays on the floor." Seen 2026-10-05.
- **S6** (`BRAIN/GOTCHAS.md`): "Lune can't read derived properties: `part.Position` errors ('missing default value'),
  use `part.CFrame.Position`; reading `Texture.Texture` fails too (clone an existing Texture rather than make one); a
  Part made in Lune has Studs surfaces, not Studio's Smooth. Clones of a place's instances save fine with
  `serializePlace`." Seen 2026-10-05 building High Olympus in Lune.
- **S7** (`BRAIN/PATTERNS/testing-studio.md`): "`require` of a game ModuleScript from `execute_luau` runs a separate
  copy in the command's context: a service required there never ran Start and holds none of the game's state (a
  `Build` returned nil). To look at what the game made, read or clone its instances, or go through its remotes." Seen
  2026-10-05.
- **S8** (`BRAIN/PATTERNS/sessions.md`, Tools on Windows): "Claude Code's Bash tool fails a heredoc whose body has
  backticks ('unexpected EOF while looking for matching'), even with a quoted delimiter: write such files with the
  Write or Edit tools." Seen twice on 2026-10-05.
- **S9** (`BRAIN/PATTERNS/sessions.md`): "After `git merge`, list what's still conflicted with
  `git diff --name-only --diff-filter=U` before you commit: a merge's output piped through `tail` hides some of its
  CONFLICT lines, and `check.ps1` doesn't look for conflict markers in Markdown, so they get committed." Seen
  2026-10-05 in Steal a Sheep: DECISIONS.md and CURRENT_STATE.md went in with markers after only HISTORY.md was fixed.
  (Could also become a `check.ps1` test: fail on lines starting `<<<<<<<` or `>>>>>>>` in tracked text files.)
- **S10** (`BRAIN/PATTERNS/characters.md`): "Humanoids hold up at high WalkSpeed: 245 studs/s up a 7-12 degree ramp and
  slides of 200-260 down 12-29 degrees stayed on the floor (0 samples below it, 2 of 179 in the air), but anything they
  clip at 150+ stops them dead. Give a fast movement a short rise (here: reach the target in about 2 s) rather than a
  fixed acceleration, or high targets take ten seconds to reach." Seen 2026-10-05 playtesting Steal a Sheep's Climbing.
- **S11** (`BRAIN/PATTERNS/sessions.md`, Studio is shared): "Every Studio window of one Roblox version reads the same
  `content` folder, so a `GetObjects("rbxasset://...")` sync file there is shared between sessions: give yours a name of
  its own (`content/<game>/<task>-sync.rbxm`), or another session's code can end up in your place." Seen 2026-10-05,
  Steal a Sheep: three sessions each had their own Studio open on a place copy, one already using `sync.rbxm`.
- **S12** (`BRAIN/PATTERNS/testing-studio.md`, screenshots and the camera): "A camera set from `execute_luau` on the
  client is put back by Roblox's camera scripts the next frame, and `screen_capture`'s `camera_position` only lasts
  for that capture. To hold a shot (a recording), bind a RenderStep at `Enum.RenderPriority.Last` that sets a
  Scriptable camera every frame; unbind it and set `CameraType` back to Custom after." Seen 2026-10-05 filming
  grazing sheep.
- **S13** (`BRAIN/PATTERNS/leaderboards.md`, Store): "An OrderedDataStore holds whole numbers below 2^63, and an
  exponential economy's numbers head past that (Steal a Sheep: a full pen at the top earns about 5e14 cash a second,
  and its Climbing stat passes 1e15; Luau is exact only to 2^53 anyway). Store `math.floor(math.log10(1 + value) * 1e13)`
  instead: the order holds, it stays under 2^53 up to 1e300, and `math.floor(10 ^ (stored / 1e13) - 1 + 0.5)` gives
  whole numbers back exactly below about 2e12 and to twelve digits above." Seen 2026-10-05 building Steal a Sheep's
  boards.
- **S14** (`BRAIN/PATTERNS/ui.md`): "A map's board panel can be modelled lying on its side (its RightVector pointing
  down), and a SurfaceGui on it then reads sideways; SurfaceGuis have no rotation. Put the GUI on an invisible
  upright part just in front of the panel's face instead (`CFrame.lookAt(centre, centre + normal)`, sized from the
  panel's extents along world up and across)." Seen 2026-10-05 on Steal a Sheep's commissioned map.
- **S15** (`BRAIN/PATTERNS/desktop.md`): "The desktop tools' `record` saves its mp4 under the session's working
  directory (`windows-computer-use/` in the repo): move it out before committing. With a window target its `region`
  crop was ignored; crop afterwards with ffmpeg (`-vf crop=w:h:x:y`)." Seen 2026-10-05.
- **S16** (`BRAIN/PATTERNS/animations.md`): "A Motor6D `Transform` set from a script moves its parts only at the next
  simulation step: in a test, wait a frame (`task.wait()`) before reading the moved parts' positions." Seen 2026-10-05
  measuring a grazing pose.
- **S17** (`BRAIN/PATTERNS/components.md`): "A tagged model the server makes while players are in the game can reach
  a client in pieces: `CollectionService`'s added signal (and a Binder's) fires for the model before all its
  descendants have arrived. Code that collects a model's parts, joints or decals when its tag appears must also take
  them from `DescendantAdded`, or it keeps a partial set for good." Seen 2026-10-05, Steal a Sheep: lambs put down in
  the pen walked about stiff and never changed face in two takes of five; models made before the player joined were
  never affected.
- **S18** (`BRAIN/PATTERNS/testing-studio.md`): "A picture uploaded through `upload_image` reports
  `AssetFetchStatus.Failure` until Roblox's review clears it (minutes), and a Studio that fetched it before then may go
  on reporting Failure from `PreloadAsync` after it's cleared: check in a freshly opened Studio. In game code, swap in a
  new picture only once it has arrived, or a Decal shows nothing meanwhile." Seen 2026-10-05.

- **S11** (`BRAIN/PATTERNS/characters.md`, Posing from code): "To make a player's feet land on moving things (stair
  machines, treadmills, pedals), anchor the root and solve the legs yourself: after the Animator (`PreSimulation`), a
  two-bone IK in the leg's plane sets hip and knee `Transform` (about the joint's X) from the thigh and shin vectors
  read off the joints' C0/C1 or attachments, and the ankle gets minus their sum so the foot stays level. Place the
  root from each avatar's own leg length rather than one height: the same code then fits skinned and blocky avatars
  of different sizes. A baked animation can't, its feet float or sink on other avatars." Seen 2026-10-05 in Steal a
  Sheep's stair walker test.
- **S12** (`BRAIN/PATTERNS/testing-studio.md`, Screenshots): "To show the user a motion without taking over the
  desktop, drive it from a phase you set from `execute_luau`, `screen_capture` each phase from the same camera, and
  join the frames into a GIF (Pillow)." Seen 2026-10-05.
- **S13** (`BRAIN/GOTCHAS.md`): "A `WedgePart`'s slope rises towards its +Z: low edge at -Z, full height at +Z. Turn
  it 180 degrees about Y for a ramp that rises the way a model faces (-Z)." Measured with raycasts 2026-10-05.
- **S14** (`BRAIN/PATTERNS/desktop.md`, after the `record` notes): "`record` writes its mp4 into a
  `windows-computer-use/` folder in the session's working directory, which is the repo: move the file out (to the
  attachments folder) and delete the folder before committing. To film the game view without taking over the screen,
  pin the camera from a Client `execute_luau` (a RenderStepped that sets `CameraType` Scriptable and the CFrame), turn
  off the core UI, define a viewport over the 3D view, and record that with `foreground: false`." Seen 2026-10-05.
- **S15** (`BRAIN/GOTCHAS.md`): "A statement put in front of a line that starts with `(` joins it: `a:Call(x)` then
  `(thing :: Model):PivotTo(cf)` on the next line is read as `a:Call(x)(thing):PivotTo(cf)`, and the formatter puts it on
  one line. Through an untyped registry (`registry.X`) the type checker can't see the bad call, so it only fails when it
  runs. Start such a line with a local (`local character = thing :: Model`) instead." Seen 2026-10-05 in Steal a Sheep:
  a merge added a call before the stair walker's exit `PivotTo`, so jumping off would have errored.
- **S19** (`BRAIN/PATTERNS/purchases.md`, or a new "Free rewards" note): "A reward for favoriting: open Roblox's own
  prompt with `AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)` on the client
  and wait for `PromptSetFavoriteCompleted` = `Success`; the server can't see favorites, so it takes the claim on trust
  and allows one per player. No API shows whether a player liked (voted on) the game, and Roblox's Community Rules
  forbid prizes 'in exchange for a thumb up on your game': ask for likes without tying the reward to them. In an
  unpublished place PlaceId is 0 and there's nothing to favorite." Seen 2026-10-05 building Steal a Sheep's free gift
  (docs and DevForum; the live prompt itself not yet tried).
- **S20** (`BRAIN/PATTERNS/sessions.md`, Worktrees): "To put uncommitted work on top of a newer main, a temporary WIP
  commit and `git rebase main` work, but undo the commit with `git reset --soft HEAD~1`, never `git reset --soft
  main`: another session can move main while you resolve the rebase, and resetting to the new main makes your tree
  look like it reverts their commit." Seen 2026-10-05 in Steal a Sheep: main gained a merge mid-rebase, and status
  showed the StairMaster's files as deleted until the reset was redone onto the commit the rebase used.
- **S21** (`BRAIN/PATTERNS/sessions.md`, Tools on Windows): "Python's `open(path, 'w')` on Windows writes CRLF line
  endings, so a script that edits a Luau or Markdown file turns every line CRLF. Open files for writing with
  `newline='\n'`, or strip `\r` afterwards." Seen 2026-10-05 in Steal a Sheep: four edited services came back all
  CRLF.
- **S22** (`BRAIN/PATTERNS/animations.md`, a new "Skinned meshes from Blender" part): "A Blender rig exported as FBX
  (forward -Z, up Y, primary bone axis Y, no leaf bones) comes in through File > Import at its Blender size, one
  Blender unit to one stud, facing -Z: a direction (x, y, z) in Blender's rig is (-x, z, y) in the model. The Bones
  sit under the MeshPart (unanchored), with an `AnimationController` and an `InitialPoses` folder beside it. A Bone's
  own axes aren't Blender's (its X and Z come in flipped), so pose from the model's axes, not the bone's:
  `bone.Transform = CFrame.new(rc:VectorToObjectSpace(offset)) * (rc:Inverse() * q * rc)`, `rc` being the bone's rest
  rotation relative to the MeshPart and `q` the rotation in the model's axes, carried by the parent bone." Seen
  2026-10-05 in Steal a Sheep: Zeus's walk pose from Blender matched in Studio, foot for foot.
- **S23** (`BRAIN/PATTERNS/desktop-recipes.md`, Import 3D): "Run end to end: `ctrl+m` in the Studio window opens
  'Open 3D File (FBX, OBJ, GLB, GLTF)'; `window click_element` 'File name:' (role Edit, `window=` the dialog's hwnd),
  `ctrl+a`, type the path, Enter; the 'Import Preview' window's defaults (Upload to Roblox, Add to Workspace, pivot at
  the scene origin) were right for a rigged character with an embedded texture; Import. The mesh and texture upload at
  once (`MeshId`, `TextureID`)." Seen 2026-10-05 in Steal a Sheep.

- **S24** (`BRAIN/PATTERNS/npcs.md`, a new "NPCs as Roblox avatars" part): "`Players:CreateHumanoidModelFromDescription`
  builds an NPC from any catalog items, owned or not, in Edit and on the server. Its HeightScale, WidthScale,
  DepthScale and HeadScale go past the avatar editor's limits (1.65, head 2.1 worked). Avatars made this way have
  AnimationConstraint joints, not Motor6Ds, and a dynamic head (FaceControls, no face Decal): give it a look with
  `desc.Head` = a catalog dynamic head (angry ones exist), not a decal. In Edit, a joint's `Transform` doesn't move
  anything, and moving an anchored limb makes Studio rebuild the body around it: pose in a playtest. There a
  `Transform` set on the server doesn't replicate, so set it on each client too (`RunService.PreSimulation`, after the
  Animator), or play an animation, whose tracks do replicate. Roblox's default R15 walk (507777826) plays on them."
  Seen 2026-10-05 in Steal a Sheep, dressing Zeus from the catalog.

## Done

- None yet.
