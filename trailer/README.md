# Trailer kit

Film the real game in a Studio playtest and cut it with ffmpeg, with no human steps. How and why:
`BRAIN/PATTERNS/trailers.md`. This kit came from Shear a Sheep's first trailer (2026-10-01): a 28 s cut in two formats.

## Pieces

| Piece | What it does |
| --- | --- |
| `src/client/Controllers/TrailerController` | A Studio-only camera rig: glides along smooth paths, follow shots, orbits, depth of field, a crowd faded out of the way, the HUD hidden, the character walked or placed. Off until you add it to `src/client/Registry.luau`. Driven through `ReplicatedStorage.TrailerRig` (a local BindableFunction) from MCP `execute_luau` calls in the Client. |
| `trailer/obs.py` | Drives OBS 31 over its websocket: scene setup, the crop to the game's viewport, timed takes. |
| `trailer/cut.example.json` | The shape of a cut list: clips, in and out points, captions per variant, music, a title card. |
| `trailer/edit.py` | Cuts a cut list into `out/<name>_<variant>.mp4`: 16:9 for the game page, 9:16 for TikTok and Shorts. |

Footage lives outside the repo and outside OneDrive, in `%USERPROFILE%\Videos\<game name>Trailer\` (`TRAILER_DIR`
overrides it): `raw/` (takes), `work/` (contact sheets, segments), `music/` and `out/`.

## A shot

From a Client `execute_luau` during Play (positions in world space unless the shot has a `Space`, such as the
player's base, so one shot works on any base):

```lua
local rig = game:GetService("ReplicatedStorage").TrailerRig
-- A glide past the base, then a follow shot pulling back from the player.
rig:Invoke("Play", { Seconds = 5, Keys = { { Pos = Vector3.new(0, 20, 60), Look = Vector3.new(0, 0, 0) }, { Pos = Vector3.new(40, 12, 30), Look = Vector3.new(0, 2, 0) } } })
rig:Invoke("Play", { Seconds = 6, Follow = "Character", Offset = Vector3.new(0, 4, 12), OffsetTo = Vector3.new(0, 9, 22), Dof = {} })
rig:Invoke("Walk", { Vector3.new(10, 0, 0), Vector3.new(10, 0, 10) }, nil, 10)
rig:Invoke("Stop")
```

Other shot fields: `Orbit`, `LookAt`, `Fov`/`FovTo`, `Roll`, `Shake`, `Hud` (keep the game's screens up),
`HideCharacter`, `Clear` (tags of a crowd to fade from the line of sight). The header of
`TrailerController/init.luau` lists them all.

## Shooting

1. Studio: `ServerStorage.DebugBlankProfile` on (filming never touches a save), Play. Stage the scene through the
   debug remote (`DebugService`): cash, items, the moment you want.
2. Studio's window: maximised, side panels and the command bar closed, View > Full Screen, the ribbon collapsed. Keep
   Studio focused: unfocused it drops to about 15 fps.
3. `python trailer/obs.py setup`, then `python trailer/obs.py frame L T R B W H` to crop to the viewport (check with
   `obs.py still`). Roblox's menu buttons stay in the viewport's top-left corner whatever the game does: crop them out.
4. For each shot, start `python trailer/obs.py take NAME SECONDS` in the background, then send the shot. MCP calls take
   1-5 s to land, so give shots a `Delay` and pad the take. `python trailer/edit.py sheet raw/NAME.mkv` makes a contact
   sheet to pick in and out points from.
5. Copy `cut.example.json` to `cut.json`, fill in the clips, and run `python trailer/edit.py trailer/cut.json`.

Needs `pip install obsws-python` and ffmpeg (`winget install Gyan.FFmpeg`; found on PATH or in WinGet's folder).
