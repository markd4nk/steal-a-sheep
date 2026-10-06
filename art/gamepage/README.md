# Game page art (icon and thumbnails)

Mock-ups for the user to pick from: rendered in a Studio copy of the place, composed with Python (Pillow).
Nothing here uploads anything.

- `tiles.py`: renders bigger than Studio's viewport. `plan` splits one virtual camera (position, target, vertical
  FOV, output size) into overlapping tiles, each the same camera turned a little in its own frame, and prints each
  tile's CFrame and FOV for `execute_luau`. Capture each tile with `screen_capture` (no camera arguments; pin the
  camera every frame with `BindToRenderStep`, or the game's camera script takes it back), then `stitch` maps them
  back onto the virtual image exactly (a pure rotation, no parallax) and reports any uncovered pixels.
- `compose.py`: the title ("STEAL A / SHEEP" in FredokaOne from Studio's own fonts, gold or white with the game's
  thick black edge, a soft shine and shadow), captions, a light vignette, final sizes and contact sheets.
- Scenes (2026-10-05): copies of the avatar gods and of the player's character, posed on the client with
  Roblox's run, idle and sit clips frozen at a chosen point and joint `Transform`s held in `PreSimulation` (the copy's
  BallSocketConstraints off so arms go straight up); live gods, wild and pen sheep, billboards and menus hidden on that
  device with `LocalTransparencyModifier`; still sheep from `ReplicatedStorage.SheepLooks`. The thief wears Roblox's
  "Shocked" head (131227297250373).

Outputs: `C:/Users/<name>/.t3/userdata/attachments/gamepage_*.png` (icons 512 x 512, thumbnails 1920 x 1080, contact
sheets). Working files go in `work/`, which git ignores.
