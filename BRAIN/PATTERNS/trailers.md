# Trailers and gameplay videos

Film the real game in a Studio playtest and cut it with ffmpeg. Don't generate footage with AI video models: Roblox
rejects game-page videos whose visuals aren't the actual game, and they can't keep a game's models consistent anyway.
RobloxPack ships the kit (since 2026-10-05): the camera rig below as `TrailerController` (off until a game adds it
to the client Registry), and `trailer/` with `obs.py`, `edit.py`, an example cut list and a README. It came from Shear
a Sheep's 28 s trailer in two formats, filmed and cut with no human steps.

## Where it goes decides the rules

- **Game page video** (Creator Hub > the experience > Thumbnails). Real in-game visuals only; no voice-over,
  narration or music with lyrics; captions may only describe gameplay ("Collect rare breeds", never "Best game" or
  "Play now"); 3 uploads a month, rejected ones included; not shown on Xbox, PlayStation or VR.
  https://create.roblox.com/docs/production/publishing/thumbnails
- **TikTok, Shorts, ads.** Creator Store music (APM and the like) is licensed for use inside experiences, so don't
  carry the game's music off Roblox: set the game's music volume to 0 before filming and lay a track you're licensed
  to use over the cut (the Pixabay Content License allows commercial use with no credit). Hype captions are fine here.
- Shoot once and make both: 16:9 (1920x1080) for the page, 9:16 (1080x1920) for social. In the 9:16 crop, put the
  subject in the middle and captions in the upper third, clear of TikTok's buttons along the bottom and right.

## Shape

- 25-35 s. The first 3 s show the core verb paying off. A shape that worked for a tycoon: verb, reward, collection,
  rare or upgraded item, threat (the music drops out), rescue, a wide payoff of the base, title.
- Cut on the beat. Shot lengths are whole beats (60 / BPM seconds), and the music runs unedited from one offset:
  measure a track's loudness every 50 ms with ffmpeg (or numpy on its PCM) to find a built-in dropout, then choose the
  offset that lands the dropout on the threat. An agent can't hear whether a music edit falls on the beat, so don't
  splice the track.

## The camera rig

Put a Studio-only controller in the game (`Start` returns at once unless `RunService:IsStudio()`) and drive it from
MCP `execute_luau` calls through a `BindableFunction` it creates in `ReplicatedStorage`. It can't be a script you
paste into `execute_luau`: those calls get their own module cache, and Studio's Assistant resets `CameraType` when it
changes during a call (`testing-studio.md`). The controller sets `Scriptable` in a `task.delay(0.1)` after the call
returns and binds its step at `Enum.RenderPriority.Camera.Value + 1`.

Shots that covered a whole trailer:

| Shot | How |
| --- | --- |
| Glide | Catmull-Rom spline through key positions and look points, resampled by length so the speed stays even, smootherstep easing |
| Follow | Offset from a moving target in its heading's axes (or the base's, or the world's), smoothed with `1 - exp(-dt / lag)` |
| Orbit | Round an instance between two angles; pick the angles in code so the camera stays inside fences |
| Fixed watch | One position, looking at a moving target |

Add a field-of-view lerp, a `DepthOfFieldEffect` focused on the look point, and a little `math.noise` drift. Give
positions in the player's base (plot) space, so the same shot works on any plot.

- **Clear the line of sight.** Each frame, set `LocalTransparencyModifier = 1` on tagged crowd models (animals, NPCs)
  that are in view and nearer than the subject by more than a couple of studs. Without it, about half the frames of
  close-ups in a crowd were another animal's back.
- **Hide the HUD** through the game's own cutscene path if it has one, and also: dev panels,
  `ProximityPromptService.Enabled`, `UserInputService.MouseIconEnabled` and
  `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)`. Keep CoreGui off even in shots that show the HUD: the
  player list covers its corner.
- **Roblox's menu buttons can't be hidden.** The logo, menu and voice buttons stay in a playtest's top-left corner
  whatever you set (`SetCore("TopbarEnabled", false)` returns fine and changes nothing). Crop them out: the 16:9 cut
  taken from the right edge of a 1914x960 viewport drops them with no scaling.
- **Stage through the game's Studio-only debug remote**, from a fixed-seed script: grant items, land, upgrades and
  helpers; spawn the threat on demand; force a random result for the next roll (a server attribute) so the take lands
  the rare outcome. Use a blank, never-saved profile so filming touches no save.
- **Switch shots on the actor's own state attributes** (crouched, charging, carrying, hidden), not on timers.
- **Walk the character** with `Humanoid:MoveTo` from the client for verb shots; slow its `WalkSpeed` for the take.
- Things that spoiled takes: a first-time cutscene starting mid-take (blank profiles replay onboarding, and debug
  playtime can make the first threat due); the character's own area effect changing the scene around it (stand it
  outside the crowd for a "full" look); a shot's last frame carrying into the next take's first second (trim it).

## Studio's window

- **Maximise the viewport after Play starts** (Play lays the window out again): close Explorer and Properties, turn
  off Window > Script > Command Bar, View > Full Screen, and double-click the Home tab to collapse the ribbon.
  `Alt+F11` and `Ctrl+F1` sent from the desktop tools did nothing; the menus work. On a 1920x1080 screen this leaves a
  1914x960 viewport. Put all of it back afterwards, Window menu first, then Full Screen off, then the ribbon.
- In full screen the menu bar sits about 22 px higher, so menu coordinates from a windowed screenshot hit the wrong
  item: open the menu and screenshot it before clicking.
- Keep Studio focused and don't click inside the viewport while recording (unfocused, it drops to about 15 fps).

## Recording with OBS

- Install with `winget install OBSProject.OBSStudio`. Before the first launch, write the profile
  (`%APPDATA%\obs-studio\basic\profiles\<name>\basic.ini`: Simple output, `RecQuality=HQ`, `RecFormat2=mkv`,
  `RecEncoder=nvenc`, `FilePath` with forward slashes) and `plugin_config\obs-websocket\config.json`
  (`server_enabled`, a password). Launch `obs64.exe` from its `bin\64bit` folder with `--disable-shutdown-check
  --disable-updater --minimize-to-tray`. Check `basic.ini` after the first run: it can rewrite the encoder and mangle
  the path, and then every recording stops with "bad output path".
- Drive it with `obsws-python`: a `window_capture` of `RobloxStudioBeta.exe` (method 2, `client_area`, cursor off,
  priority 2 to match the exe), a `wasapi_process_output_capture` for Studio's sound only (mute Desktop Audio and the
  mic), the scene item cropped to the viewport, and the canvas set to the crop's size so nothing is scaled. Use even
  sizes a multiple of 4 wide: OBS rounded 1914 down to 1912. `GetSourceScreenshot` of the source ignores the crop;
  screenshot the scene to check framing.
- **NVENC needs a recent NVIDIA driver.** OBS 32 and ffmpeg 9 want NVENC API 13 (the OBS log says "NVENC not
  supported" / `outdated_driver`). With an older driver, install OBS 31.1.2 (API 12.2) rather than updating the
  user's driver. Without NVENC, x264 competes with Studio for the CPU.
- **Takes:** run a script that starts recording, sleeps N seconds, stops and renames the file as a background
  command, then send the shot. MCP calls take 1-5 s to land, so give each shot a 0.5-1 s `Delay` and pad the take.
  The desktop tools' `record` is for judging motion (10 fps), not for footage.
- Keep footage outside the repo and outside OneDrive: a shoot is gigabytes of takes.
- A plain `taskkill` makes OBS show an "OBS has crashed!" dialog on the way out; close it and force-quit.

## Reviewing without watching

- Make a contact sheet of every take (`fps=2,scale=320:-2,drawtext` of the timestamp, `tile=6xN`), then a 4 fps sheet
  of the window you'll use, and pick in and out points to the frame from those.
- Measure loudness with `ebur128`: the game's music bed between events against the effects, and the finished cut.
- Say plainly that the cut was judged from frames and loudness, not watched with sound: pacing and the music need the
  user's eyes and ears, and a round of notes.

## Editing with ffmpeg

- Cut every clip from its original take once per format (never crop one format out of the other): trim, crop to the
  aspect (each clip can move its 9:16 crop across the frame), `scale=...:flags=lanczos,setsar=1`, `fps`, captions with
  `drawtext`, stereo 48 kHz audio, an intermediate MKV with PCM audio.
- Captions in the game's display font: copy it from `%LOCALAPPDATA%\Roblox\Versions\<version>\content\fonts\` next to
  the work files and pass the text with `textfile=`, so nothing needs escaping. Wrap the fade expression in
  `clip(...,0,1)` so a caption can carry across a cut already faded in. Shrink long lines to fit a 9:16 frame's width.
- Join with `concat` (hard cuts) and `xfade`/`acrossfade`. Normalise every input with
  `fps=60,settb=1/60,setsar=1,setpts=PTS-STARTPTS`, and reset `settb` after each `concat`: it hands on a microsecond
  timebase, and `xfade` refuses inputs whose timebases differ.
- Mix the game's audio per clip (up for the verb and the threat, down for calm shots) under the music, then
  `loudnorm=I=-14:TP=-1.5`. Encode `libx264 -crf 17 -preset slow`, AAC 192k, `-movflags +faststart`.
- Slow motion: `minterpolate` (mode `mci`) for speeds under 1, with the sound pitched down by `asetrate`.
