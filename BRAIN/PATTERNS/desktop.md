# Desktop tools (outside the game window)

The Roblox Studio MCP works inside Studio: it runs Luau, starts solo playtests, screenshots the viewport and sends
input to the game. It can't reach Studio's own menus and dialogs, or anything outside Studio. Machines set up with
README step 8 also have the `windows-computer-use` MCP server, which sees and controls the Windows desktop.

**You may use it whenever it's the best way to get the game's work done. Don't ask first**: announce the takeover
(Rules) and go ahead. The only limits are the actions under Rules that need the user's say-so, whatever tool does
them. Jobs only these tools can do (step by step in `desktop-recipes.md`):

| Job | Why nothing else can |
| --- | --- |
| Save the place (**File > Save to Roblox**) | There's no save tool, and `SavePlaceAsync` fails from Edit |
| Publish Animation Editor animations | No API uploads animations (`AssetService:CreateAssetAsync` takes models, plugins, meshes and images) |
| Start and end a Server & Clients test, add clients | `start_stop_play` only runs solo playtests |
| Click **Buy** in a Studio test purchase | The purchase dialog doesn't show in `screen_capture` |
| **File > Import** (FBX from Blender and the like; called Import 3D before) | There's no import tool |
| See Studio while other windows cover it | `screen_capture` comes back as a dark 3D view |
| Creator Hub in the user's browser: developer products, passes, the place's settings, thumbnails | It needs the user's signed-in browser; no MCP reaches it |

Everything inside the running game (walking, the game's own buttons, reading state, screenshots of play) stays on
the Studio MCP (`testing.md`): it's faster and doesn't take the user's mouse.

## Is it connected?

Its tools are `screenshot`, `act`, `window`, `record`, `play` and `system`. Don't use `process`: start and stop
programs with Bash. If the tools are missing, don't imitate them: ask the user to do the step, and say in your report that they did it.

## Rules

These tools move the real mouse and press real keys, and the user (or another agent session) is often working on the
same computer.

- Any window the game's work needs is fair game: Studio and its dialogs, Creator Hub in the browser, Blender holding
  the game's art, a file dialog. Never an unrelated app, and never the user's other browser tabs.
- Screenshot the window you're working in (`window:<hwnd>`), never `desktop`, `display:N` or `foreground`: other apps on screen
  can show the user's private information.
- Never read or write the clipboard: no `system` `get_clipboard` or `set_clipboard`, and no `act` `paste`, which
  replaces what the user copied. Type text with `act` `type`.
- Free to do: **Save to Roblox**; publishing Animation Editor animations the game needs (they go to the game owner's
  account, and live games play nothing else); clicking **Buy** in a Studio test purchase (it doesn't charge);
  Creator Hub texts, icons and place settings.
- Ask first, as for any tool: **Publish to Roblox** (players get the new version, along with any other session's
  unfinished Studio-side work); **Buy** anywhere else (a published game or roblox.com spends real Robux); Creator Hub
  prices, new paid products, and taking off sale something the game still sells (AGENTS.md: anything involving
  Robux). A user's "do the store edits" in the task counts as asking.
- Close only dialogs you opened. Never close a Studio window: unsaved Studio-side work goes with it.
- Before anything that moves the mouse or presses keys, say in one line what it does and how long it takes
  ("Taking the mouse for about 5 s to save the place"), then go ahead in the same turn: don't wait for a reply.
  Keep each `act` call short (Other sessions, below) so the user gets the mouse back quickly. One `act` at a time:
  never send two in parallel.
- Give the user their window back. Before you take over, `window` `list` with `limit: 1` and `details: true` returns
  just the foreground window and its `hwnd`; `window` `focus` that `hwnd` when you're done.
- Windows Security prompts ("allow ... on public and private networks?") take the foreground and swallow clicks,
  and `window list` doesn't show them. One came from `python -m http.server` (bound to `127.0.0.1`, none appears),
  another from T3 Code's `cloudflared` tunnel. If input stops reaching its window, screenshot a screen region;
  answer **Cancel** (allowing changes the user's firewall) and tell the user.
- `screenshot` with `save: true` writes a `windows-computer-use/` folder into the session's working folder: move
  what you need and delete it, so nobody commits it.

## Other sessions

Several agent sessions can share one mouse and keyboard, and Studio jumps to the front when another session uses it.
Keys go to whatever window is in front when they're sent, not to the one the `act` call focused at the start. On
2026-10-01 a click, `ctrl+a` and `Delete` meant for a Creator Hub text box landed in Studio's 3D view and deleted the
whole map.

- If other sessions may be using this computer (Claude Code: `ListAgents`), tell them before a takeover and wait for
  "desktop free" while one of theirs runs.
- Never send `Delete` or `Backspace` to clear a field. Select it (`ctrl+a`) and type over it, so a stray key can't
  delete anything.
- Keep a batch to one item's worth (about 30 s). Each `act` result ends with the window the input went to ("focused &
  sent input to '...'"): if it isn't the one you meant, stop and check what your keys did there before anything else.
- In Studio, `ChangeHistoryService:GetCanUndo()` from `execute_luau` in Edit names the last waypoint
  (`DeleteSelectedAction` is a `Delete` key), and `:Undo()` takes it back. Undo one step at a time until the damage is
  gone, tell any session using Studio, and don't save the place until it's checked.

## Finding Studio

`window` `list` with query `RobloxStudioBeta` (Studio's process) and `details: true` (for each `hwnd`) lists every
Studio window: the game's, whose title has the place's name, and one for each window of a Server & Clients test.
Use the game's `hwnd` in every later call (`window:<hwnd>` as a target, `window=<hwnd>` for `click_element`, `focus`
for `act`), so nothing lands in another game's Studio or in a browser tab that mentions Roblox Studio. Check it's
the place the Studio MCP is connected to (`list_roblox_studios`).

## Seeing

- `window` `get_text` and `window` `ui_tree` (start with a small `depth`) read a window's controls and text with no
  image. In Studio they reach little: the menu bar's items (File, Edit, Test...) and the title bar. The ribbon,
  the dock panels (Explorer, plugin widgets such as Rojo's and the Animation Editor) and the items inside a menu
  have no names there, so find those with a screenshot.
- `screenshot` with `target: "window:<hwnd>"` captures a window without bringing it forward, and sets the
  coordinate frame for `act`. With `capture_mode: "printwindow"` a Studio window that isn't in front (on another
  monitor) comes back with its 3D view. If a capture is black, the default mode brings Studio to the front and
  captures again. While the user is working, pass `capture_mode: "printwindow"` (in the pinned version, any value
  except `auto` or `bitblt` skips that step) and report the black capture instead.
- Menus that drop down (the File menu, a plugin's ⋯ menu, their submenus) and Studio's dialogs are windows of
  their own, missing from a capture of the main window. After opening one, `window` `list` Studio's windows again:
  a menu shows up titled `RobloxStudio`, a dialog under its own title (`Asset Configuration`). Screenshot that
  `hwnd`.
- Studio's log says what a click did when nothing shows on screen: the newest
  `%LOCALAPPDATA%\Roblox\logs\*_Studio_*_last.log` (read it with Bash).
- `record` and `play` bring the window to the front. Announce them like any other takeover. `record` with
  `foreground: false` films a window where it is instead (seen with Studio's 3D view behind other windows, at 15 fps),
  so no takeover is needed. Ask for no more frames than it can capture (15 fps did, 20-30 didn't): short of that, the
  mp4 keeps the asked-for rate and plays faster than real time, which misleads anyone judging timing.

## Clicking and typing

1. Try `window` `click_element` first (`query` = the control's name, `window=<hwnd>`). It presses the control
   through UI Automation, with no mouse and without bringing Studio forward. When a control can't be pressed that
   way it falls back to a real click; the result says which (`invoked` or `clicked`).
2. Otherwise `screenshot` the Studio window, then send one `act` call with `focus` set to the `hwnd`. Coordinates
   are in that screenshot's image space; pass its `capture_id`, since a newer screenshot invalidates them (a
   screenshot of a menu's window too). To click a spot you've found before without a new screenshot, pass
   `coordinate_space: "screen"` with its screen position: each `act` result prints the screen point it clicked, and
   `ui_tree` gives screen rects. A repeated sequence (open a menu, pick an item, fill a dialog) can then go in one
   `act`, as long as each window opens where it did before.
3. A `screenshot` with both `region` and `define_viewport` makes that crop the frame for later calls until `system`
   `clear_viewport` (`text` = its name). Crop with `region` alone.
4. Keys go to the foreground window, so any `act` that types or presses keys needs `focus`.
5. Check every step through the Studio MCP (`get_studio_state`, `list_roblox_studios`, `execute_luau`) or a fresh
   screenshot. Don't assume a click landed.
6. `act` coordinates are in the last screenshot's image space, even when that screenshot was of another window (a
   dialog) or a region, and even with `focus` naming a different window: a click meant for Studio's File menu after
   a dialog's screenshot hit the 3D view. Screenshot the window right before clicking it, and `system
   clear_viewport` before clicking outside a defined viewport.

## Not known yet

- Whether a Studio window covered by other windows captures with its 3D view or black.
- Whether a test purchase dialog belongs to the Studio window or is a window of its own (menus and the Asset
  Configuration dialog are their own windows).
