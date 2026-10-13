# BRAIN proposals

Lessons proposed for the shared files (`BRAIN/`, `AGENTS.md`, the shared scripts), waiting for the user. Each has an
id, where it would go, the text as it would read there, and how and when it was seen. The user approves by id; the
agent then applies the text, adds a line to `BRAIN/CHANGELOG.md`, moves the id to *Done* with the date, and runs
`./scripts/brain-sync.ps1 -ToPack`.

## Waiting

- **S49** (`BRAIN/PATTERNS/testing-studio.md`, replacing "`screen_capture` leaves out BillboardGuis"): "`screen_capture`
  leaves out BillboardGuis with `AlwaysOnTop` on; the others show, in Workspace or in PlayerGui with an `Adornee`. To
  see an AlwaysOnTop one, turn it off for the capture from a Client `execute_luau`, or use the desktop tools'
  `screenshot` of the Studio window (`desktop.md`)." Seen 2026-10-06 in a Steal a Sheep playtest: the stair walker's
  "+N/s" over the player's head (PlayerGui, AlwaysOnTop) was enabled, sized and adorned but missing from two captures,
  moved into the Head and still missing, then showed at once with AlwaysOnTop off; the walker's own "LV 1" billboard
  (not AlwaysOnTop) shows in every capture.
- **S52** (`BRAIN/PATTERNS/trailers.md`, Studio's window): "A Studio window in the background still counts 60
  `RenderStepped` a second, but its picture changes only every 4th frame (15 fps): don't judge the throttle by
  `RenderStepped`. To film without taking the user's screen, run a scripted shot on its own clock at a quarter of real
  speed (Roblox's tracks too, with `AdjustSpeed`), record it with OBS behind the user's windows, and keep each
  picture once with ffmpeg (`mpdecimate=hi=200:lo=64:frac=0.02,setpts=N/(60*TB)`): 60 distinct frames a second.
  Anything on Roblox's own clock (grazing animals, sways) plays four times too fast, so take it out of the shot."
  Seen 2026-10-06 filming Steal a Sheep's slide animation mock-ups: a real-time take had 15 distinct frames a second.
- **S53** (`BRAIN/GOTCHAS.md`): "Decorative parts are often `CanQuery = false` (a commissioned map's tree leaves
  were), so raycasts and `GetPartBoundsInRadius` pass through them: a camera that pulls in when a ray hits scenery
  still ends up inside a tree's crown. Find what's in the way by testing points against every part's box, and choose
  camera sides that avoid it." Seen 2026-10-06, same mock-ups.

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
- **S24** (`BRAIN/PATTERNS/desktop.md` or `ui.md`, mock-ups): "Uploaded images can't be downloaded by asset id without a
  login (the thumbnails API returns its placeholder for Image assets, assetdelivery returns 403). Every image any
  Studio on the computer has shown is still on disk: `%LOCALAPPDATA%\Roblox\rbx-storage\<xx>\<file>`, each an `RBXH`
  header followed by the PNG (cut from the `\x89PNG` signature). The files aren't named by asset id: extract them all,
  make a numbered contact sheet and pick by eye. With a project's game art this way, a mock-up can be drawn as HTML
  and rendered with headless Chrome (`chrome --headless=new --screenshot`) when every Studio is busy with other
  sessions." Seen 2026-10-05 mocking up Steal a Sheep's Robux store while three sessions held the open Studios.

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
- **S22** (`BRAIN/PATTERNS/ui.md`): "A ScrollingFrame with `ScrollBarThickness = 0` still draws a 1-pixel line where
  its bar would be; set `ScrollBarImageTransparency = 1` as well to hide the bar." Seen 2026-10-05 on Steal a Sheep's
  store, whose tabs stand outside the window instead of a bar.
- **S23** (`BRAIN/PATTERNS/testing-studio.md`): "`user_mouse_input`'s `instance_path` can't reach an instance whose name
  has a dot in it ('Instance not found'): the dot splits the path. Name UI elements without dots (or tap by x/y)."
  Seen 2026-10-05 clicking the store's `Sheep.GoldenFleece` card.
- **S25** (`BRAIN/GOTCHAS.md`): "Neon brightens a part's colour towards white: a pale Neon colour (140, 255, 170) reads
  as white, most of all in a ViewportFrame. Give Neon a saturated colour, (255, 90, 0) or (0, 220, 190), to keep its
  hue." Seen 2026-10-05 rendering Steal a Sheep's sheep designs: four glowing Mythics came out white.
- **S26** (`BRAIN/PATTERNS/testing-studio.md`): "To call the running game's client code from a playtest (open a menu,
  press what the mouse would) without the mouse, add a TEMP_ LocalScript to StarterPlayerScripts in Edit that requires
  the controller and acts when an attribute on the LocalPlayer changes, then set the attribute from a Client
  `execute_luau`: the LocalScript shares the game's module copies, `execute_luau` doesn't (S7). Delete it after." Seen
  2026-10-05 in Steal a Sheep: desktop clicks meant for my Studio landed in another session's, which had taken the
  foreground between my screenshot and my click.
- **S27** (`BRAIN/PATTERNS/publishing.md`, a new "A game's first publish" section): "A place opened from a local file
  publishes as a new experience: File > Publish to Roblox opens **Publish Experience** (Name, Description, Creator,
  Devices, Team Create and Data Sharing, both on by default); **Create** takes about 5 s, and the window reopens as
  the Team Create cloud place, titled with the experience's name, under a new Studio MCP id. New experiences start
  Private: `https://develop.roblox.com/v1/universes/<id>` shows `privacyType` with no sign-in, while
  `games.roblox.com/v1/games` returns placeholders for a private game. Turning Team Create on can log HTTP 429
  'Commit Failure: Publish Assets' for the scripts' version history; the place was fine (every script matched after),
  so compare the scripts again rather than republishing. Max players isn't in Studio's Experience Settings: Creator
  Hub > Places > the place > Access (it starts at 50). Studio Access to API Services is under Experience Settings >
  Security. The Limited audience (Playtesters, Friends) needs a content maturity label first: until the
  questionnaire is done, Save Changes stays greyed out." Seen 2026-10-05 publishing Steal a Sheep.
- **S28** (`BRAIN/PATTERNS/animations.md`, a new "Skinned meshes from Blender" part): "A Blender rig exported as FBX
  (forward -Z, up Y, primary bone axis Y, no leaf bones) comes in through File > Import at its Blender size, one
  Blender unit to one stud, facing -Z: a direction (x, y, z) in Blender's rig is (-x, z, y) in the model. The Bones
  sit under the MeshPart (unanchored), with an `AnimationController` and an `InitialPoses` folder beside it. A Bone's
  own axes aren't Blender's (its X and Z come in flipped), so pose from the model's axes, not the bone's:
  `bone.Transform = CFrame.new(rc:VectorToObjectSpace(offset)) * (rc:Inverse() * q * rc)`, `rc` being the bone's rest
  rotation relative to the MeshPart and `q` the rotation in the model's axes, carried by the parent bone." Seen
  2026-10-05 in Steal a Sheep: Zeus's walk pose from Blender matched in Studio, foot for foot.
- **S29** (`BRAIN/PATTERNS/desktop-recipes.md`, Import 3D): "Run end to end: `ctrl+m` in the Studio window opens
  'Open 3D File (FBX, OBJ, GLB, GLTF)'; `window click_element` 'File name:' (role Edit, `window=` the dialog's hwnd),
  `ctrl+a`, type the path, Enter; the 'Import Preview' window's defaults (Upload to Roblox, Add to Workspace, pivot at
  the scene origin) were right for a rigged character with an embedded texture; Import. The mesh and texture upload at
  once (`MeshId`, `TextureID`)." Seen 2026-10-05 in Steal a Sheep.
- **S30** (`BRAIN/PATTERNS/npcs.md`, a new "NPCs as Roblox avatars" part): "`Players:CreateHumanoidModelFromDescription`
  builds an NPC from any catalog items, owned or not, in Edit and on the server. Its HeightScale, WidthScale,
  DepthScale and HeadScale go past the avatar editor's limits (1.65, head 2.1 worked). Avatars made this way have
  AnimationConstraint joints, not Motor6Ds, and a dynamic head (FaceControls, no face Decal): give it a look with
  `desc.Head` = a catalog dynamic head (angry ones exist), not a decal. In Edit, a joint's `Transform` doesn't move
  anything, and moving an anchored limb makes Studio rebuild the body around it: pose in a playtest. There a
  `Transform` set on the server doesn't replicate, so set it on each client too (`RunService.PreSimulation`, after the
  Animator), or play an animation, whose tracks do replicate. Roblox's default R15 walk (507777826) plays on them.
  A copy shown in a ViewportFrame (in a WorldModel) loses its layered clothing if its AnimationConstraints are
  removed: anchor the parts and keep the joints." Seen 2026-10-05 in Steal a Sheep, dressing the gods from the
  catalog (the Sheepdex's god pictures lost their dresses).
- **S31** (`BRAIN/PATTERNS/desktop-recipes.md`, Creator Hub in Chrome): "Many developer products or passes at once:
  in the Creator Hub tab, open DevTools (`ctrl+shift+j`), click the console's prompt and `type` one line of JavaScript
  that `fetch`es the Open Cloud endpoints with the page's sign-in (`credentials: 'include'`): `POST
  https://apis.roblox.com/developer-products/v2/universes/<id>/developer-products` and `.../game-passes/v1/universes/
  <id>/game-passes`, multipart `name`, `description`, `price`, `isForSale`; retry once with the `x-csrf-token` header
  the first 403 returns. List what exists first (`GET .../developer-products/creator`, `.../game-passes/creator`) and
  skip those names, so a rerun is safe. Write the ids into a fixed `<textarea>` on the page and screenshot it, then
  check every id through the public details APIs (desktop-recipes step 5). 49 products and 2 passes took about 25 s."
  Seen 2026-10-05 in Steal a Sheep.
- **S32** (`BRAIN/PATTERNS/publishing.md`, Maturity questionnaire): "Picking the last answer of a topic moves straight
  on to the next topic, so a Continue click sent in the same batch lands on the next page and can tick an answer
  there (it ticked Romance 'Yes'). Click one answer per screenshot. The topics (2026-10): Violence, Blood, Fear, Crude
  Humor, Gambling-Related Content, Strong Language, Romance, Alcohol, Social Hangout, Free-form User Creation,
  Sensitive Issues, Cross-Experience Content, AI Interaction, Paid Random Items (and whether the game respects
  `ArePaidRandomItemsRestricted`), Paid Item Trading, Media Sharing, Continuous Media Feed; then Preview rating, then
  Submit and publish." Seen 2026-10-05 in Steal a Sheep.
- **S33** (`BRAIN/GOTCHAS.md`): "A MaterialVariant on a MeshPart follows the mesh's UVs but keeps its `StudsPerTile`
  size in studs: a part twice as big shows twice as many tiles, and the pattern bends and breaks where UV islands meet.
  A tile made for flat blocks (studs, bricks) reads better at half its size or less on small round meshes. A `Texture`
  on a MeshPart is projected flat from each face instead: an even grid, but only its picture, with no normal map, so
  bevels go flat. Glass and Neon parts draw no variant at all; for a glowing look, give a Plastic variant an
  `EmissiveMaskContent` (its own colour map works). A variant's BaseMaterial and maps are PluginSecurity: make variants
  in Studio, not from game scripts. Variants show in ViewportFrames too, and a MeshPart's own TextureID picture still
  shows with a variant on it." Seen 2026-10-05 putting the map's Studs material on Steal a Sheep's wool.
- **S34** (`BRAIN/PATTERNS/testing-studio.md`): "`_G` lasts between `execute_luau` calls in one Studio: define a
  long mock-up or test helper once (`_G.TEMP_Mockup = function(look) ... end`), rerun it with one-line calls, and set
  it to nil when done. The command's thread lacks the RobloxScript capability: reading `Lighting.Technology` or
  `MaterialService.Use2022Materials` errors." Seen 2026-10-05 in Edit, rendering four looks of the same scene.
- **S35** (`BRAIN/PATTERNS/testing-studio.md`, running `studio/` build scripts): "A `studio/` script that only uses
  `game:GetService`, `Enum` and datatypes can also build a place file in Lune, so the cloud place (execute_luau) and
  local builds share one source: `luau.load(fs.readFile(path), { environment = { game = place, Enum = roblox.Enum,
  Color3 = roblox.Color3 } })()`, where `place` is from `roblox.deserializePlace`. Lune 0.10.5 sets PluginSecurity
  properties (a MaterialVariant's BaseMaterial, `EmissiveMaskContent` from another `...Content`) but can't read the
  older `ContentId` ones (`ColorMap`): read the `...Content` twin." Seen 2026-10-05, Steal a Sheep's stud materials.
- **S36** (`BRAIN/PATTERNS/testing-studio.md`, a new "Checking that assets load" part): "To check a game's assets
  load, don't preload bare ids: `ContentProvider:PreloadAsync({ "rbxassetid://..." })` reports Failure for meshes and
  most images that load fine. Preload instances (a Decal per image, a Sound per sound, then `IsLoaded` and
  `TimeLength > 0`), build meshes with `AssetService:CreateMeshPartAsync` on the server, and load animations through
  an Animator (`Length > 0`). The public thumbnails and economy APIs aren't enough on their own: they said Completed
  for meshes moderation had removed." Seen 2026-10-05 in Steal a Sheep's asset audit (1,286 ids, all loading).
- **S37** (`BRAIN/PATTERNS/trailers.md`, staging and cutting; the `edit.py` part also for RobloxPack's `trailer/`):
  "To walk or steer the player's own character during a take, call `Humanoid:Move` in `BindToRenderStep` at
  `Enum.RenderPriority.Input.Value + 1`. From `RenderStepped` it comes too late: Roblox's controls have already reset
  MoveDirection when the game's own movement code reads it. Check every caption against its frame, since a game's
  stage signs and nameplates often fill the lower third; move that clip's caption up with `y`. The OBS 'Trailer'
  profile is shared by every game on the PC: if a shoot changes its recording path or canvas, put them back after.
  `edit.py` takes a cut list `fps` (60 fps takes halve cleanly to 30), and the title card keeps the last clip's sound,
  fading, instead of cutting to silence." Seen 2026-10-05 filming Steal a Sheep's trailer: the
  slide wouldn't start under a RenderStepped steer, and stage signs collided with "Climb to Zeus".

- **S40** (`BRAIN/PATTERNS/testing-studio.md`, Purchases and saving): "A local copy of the place can act as the
  published one: in Edit, `game:SetPlaceId(<placeId>)` and `game:SetUniverseId(<universeId>)` (Plugin security, fine
  from `execute_luau`) make its playtests use the universe's Studio DataStores ('data will be saved') and show
  Roblox's test purchase dialog for the universe's products, without touching the cloud place. Its
  `list_roblox_studios` name then reads like the cloud place's: address it by id. Server & Clients test players
  (`Player1` -1, `Player2` -2) save under their own keys, away from the owner's Studio save. Put both ids back to 0
  before leaving it." Seen 2026-10-05 in Steal a Sheep, testing saves across sessions and real receipts overnight.
- **S41** (`BRAIN/PATTERNS/ui.md`): "On a computer or a tablet Roblox opens its player list (the leaderstats) at the
  top right by default, about 315 px wide: a HUD's top-right counters end up under it. Keep them left of it there (not
  on a phone, a touch screen whose short side is under about 500 px, nor on a console, where it starts closed)." Seen
  2026-10-05 in Steal a Sheep: Climbing and cash were hidden at every PC and iPad join.
- **S42** (`BRAIN/PATTERNS/ui.md`): "A menu that opens by itself must wait for everything that wants the player's tap,
  not only other menus: a welcome-back card isn't modal, and a daily menu opened under it. Check a 'busy' state that
  includes such cards, and leave a few seconds after it clears." Seen 2026-10-05 in Steal a Sheep.
- **S43** (`BRAIN/PATTERNS/testing-studio.md`, Studio windows): "Server & Clients from the desktop: Test menu > Start
  Test Session > Server and Clients starts at once with the toolbar's client count, which may be 0 (a server only,
  and Add Clients stays greyed). End Session in the same menu, set the count with the arrows beside the person icon,
  then the blue Play. Clients run in the Device Simulator when Test > Device Simulator is ticked." Seen 2026-10-05.
- **S44** (`BRAIN/PATTERNS/ui.md`): "Game-drawn ProximityPrompt UIs (Style Custom, a BillboardGui per prompt in
  PlayerGui) are invisible to `screen_capture` like every billboard: check them with the desktop tools' region
  screenshot, and trigger them with `InputHoldBegin`/`InputHoldEnd` as their button does. Prompts sharing a part need
  laying out side by side (`SizeOffset`); Roblox's own UI stacked them, a custom one overlaps them." Seen 2026-10-05
  in Steal a Sheep.
- **S45** (`BRAIN/PATTERNS/desktop.md`, Other sessions): "`window` close goes by `query`, not `hwnd` (`hwnd` alone
  fails with 'no window matching None'), and closes the first window whose title contains it. After Don't Save a
  Studio stays open on its Start page, titled just 'Roblox Studio', which every Studio window's title contains: closing
  it with that query shut the user's cloud place Studio instead. List the windows first and give a query only one
  title holds. A Team Create place closed by mistake loses nothing (its edits are on Roblox's server), but its MCP
  connection goes until it's reopened: `RobloxStudioBeta.exe -task EditPlace -placeId <id> -universeId <id>`." Seen
  2026-10-06 in Steal a Sheep, closing an overnight test copy.
- **S46** (`BRAIN/PATTERNS/testing-studio.md`, running `studio/` build scripts): "A build script that runs both in
  Lune and in Studio can build different things if it takes 'the first child that matches': Studio's `GetChildren`
  order for a loaded place isn't the file's order, which Lune keeps. Pick by a stable rule (the closest match, then
  name or position) when both must agree, and compare a Studio rebuild with a Lune build by sums of instance counts,
  name lengths, and part positions and sizes rounded to 0.01, which don't depend on order." Seen 2026-10-06 in Steal
  a Sheep: High Olympus rebuilt in the cloud place matched a Lune build everywhere but its clouds, about 5% bigger
  (another of stage 7's ten-part cloud models).
- **S47** (`BRAIN/PATTERNS/publishing.md`, What's live): "In Team Create the server autosaves edits as a new version
  within about a minute, with no Save: **Save to Roblox** then still logs 'Saved new changes' but adds no Version
  History row, and **Publish to Roblox** publishes that autosaved version, so Version History and Server management
  show the autosave's time, not the publish's. Check that every edit came before that time." Seen 2026-10-06 in Steal
  a Sheep: version 8 was autosaved at 08:42 and published at 08:51.
- **S48** (`BRAIN/GOTCHAS.md`, Assets): "APM's alternate mixes of one track (the plain title, '(80%)', '(40%)', 'B')
  are separate assets that start together: 'Run For Your Life' full and '(80%)' (no drums) line up to about 10 ms.
  Play two as layers and crossfade them for intensity (drums in as danger grows). Their lengths differ by a second, so
  don't use `Looped`: jump both `TimePosition`s from a loop end back to a loop start you've measured (a bar multiple
  where the audio matches), and resync the second to the first when they drift. Find them by searching the track's
  name." Seen 2026-10-06 in Steal a Sheep's chase music (cross-correlated offline, playing in sync in a playtest).
- **S50** (`BRAIN/GOTCHAS.md`): "A part with `CanQuery` off still blocks characters and PathfindingService if it's
  `CanCollide`, but raycasts, `Blockcast` and `GetPartBoundsInBox` don't see it. Imported maps often switch
  `CanQuery` off on fences, hay and props, so 'is the way clear?' checks with rays pass straight through a fence the
  player can't. To find a walkable way, ask PathfindingService rather than testing with rays first." Seen 2026-10-06
  porting Shear a Sheep's guide trail to Steal a Sheep. 305 of the plots' collidable fence parts had `CanQuery` off;
  `ComputeAsync` still routed out through the gate (30-300 ms for about 250 studs, in Edit as well).
- **S51** (`BRAIN/PATTERNS/ui.md`): "A menu that remakes its cards on every state push swallows taps once the state
  pushes every second (a countdown, something growing): a tap that starts on one card and ends on its replacement never
  fires `Activated`. Remake the cards only when the list itself changes (a key of the ids in order and the fields the
  cards are made from) and update the numbers in place; redraw a ViewportFrame only when what it shows changes." Seen
  2026-10-06 in Steal a Sheep: with a lamb growing, the Flock menu's cards couldn't be picked until it kept them.
- **S54** (`BRAIN/PATTERNS/testing-studio.md`, Screenshots and the camera): "In a playtest, a Scriptable camera held
  far from the character (about 3,000 studs away, the character still at the spawn) drew only the sky and the
  BillboardGuis, even with StreamingEnabled off; changing a part near the shot on the client sometimes brought the
  view back. Pivot the character (anchored) near the shot first: with it there and the normal camera the same spot
  drew properly. An Edit-mode `screen_capture` of the spot was always fine." Seen 2026-10-06 filming Steal a Sheep's
  High Olympus (main's version too, so not caused by that change).
- **S55** (`BRAIN/PATTERNS/desktop.md`, Recording): "`record` of a window that isn't in front can return identical
  frames ('frames look identical'): Studio stops drawing a covered window. Record with `foreground=true` (it needs no
  input, so announce it as a short takeover); one background recording of the same window did move, so don't trust a
  background one." Seen 2026-10-06 filming Steal a Sheep's moving scenery with other sessions' Studios open.
- **S56** (`BRAIN/PATTERNS/testing-studio.md`, Phones, replacing "its setters fail during a playtest"): "In a solo
  playtest, `SetDeviceAsync` and `SetOrientationAsync` work from a **Client** `execute_luau` (Server calls fail), and
  the UI lays itself out again for the new screen, so one playtest can sweep every phone: switch, wait about a second,
  read `AbsolutePosition`s (plus `GuiService:GetGuiInset()` for screen pixels), capture. Reapply any test-only
  change your own layout code resets when the viewport changes." Seen 2026-10-06 in Steal a Sheep: 16 phones
  sideways, 4 upright and 2 tablets measured in one playtest.
- **S57** (`BRAIN/PATTERNS/ui.md`): "On a touch screen Roblox's default dynamic thumbstick takes any touch that starts
  in `TouchGui.TouchControlFrame.DynamicThumbstickFrame`: the left 40% of the screen (plus 100 px) and the bottom two
  thirds below the top bar. A HUD button there takes the touch first, so a thumb meant for the stick opens a menu
  instead. On phones keep buttons out of it (a row under the top bar, or the right side), and check against that
  frame's `AbsolutePosition` in a Client call." Seen 2026-10-06 in Steal a Sheep: the menu pictures' lower row sat in
  it on every phone preset (on a Galaxy A06 the zone started 151 of 338 px down).

## Done

- None yet.
