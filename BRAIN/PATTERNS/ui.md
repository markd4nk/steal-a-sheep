# UI

`UIController` (`src/client/Controllers/UIController`) owns every screen. It starts with none.

## Build UI in Studio, drive it from code

Author ScreenGuis in **StarterGui** (in Studio, not in code). Code finds them and makes them work. Only build UI
with `Instance.new` or a UI library if the user asks for that.

- With the Roblox Studio MCP connected: inspect the tree (`search_game_tree`, `inspect_instance`), create and edit
  elements (`execute_luau` in Edit mode), then `screen_capture` during a playtest to check the result.
- Without it: don't fall back to building UI in code. Tell the user the Studio MCP isn't connected
  (https://create.roblox.com/docs/studio/mcp), write the screen module, and list the elements the ScreenGui needs.
- StarterGui lives in the place file, not on disk; Rojo doesn't sync it. Remind the user to save the place.
- UI in the world that shows everyone the same thing (a leaderboard's SurfaceGui) can be written by the server
  directly (`leaderboards.md`). UIController is for per-player screens.
- Set `ResetOnSpawn = false` on each ScreenGui **in StarterGui**. UIController sets it on the PlayerGui copy at
  runtime, which keeps that copy alive. But if the StarterGui original is still `true`, every respawn clones a
  duplicate ScreenGui on top.
- Name elements for what they are (`CashLabel`, `CloseButton`). Code finds them by name.
- Lay out with `UIListLayout`, `UIPadding`, `UIScale` and `Scale` sizes, not fixed pixel offsets, so it works on
  phones. Check with Studio's Device Simulator.
- A `UIListLayout` draws its children unrotated: `Rotation` on a list item does nothing, with no warning. Put
  anything that turns (an arrow's pointer) inside a plain frame, and make that frame the list item.
- A `BillboardGui`'s buttons ignore clicks and taps unless `BillboardGui.Active` is `true`.
- A `UIStroke` on text (`ApplyStrokeMode.Contextual`) is drawn entirely outside the letters, so an outline that
  suits big text fills the gaps inside small text and the word smears. Keep it near 12% of `TextSize` (about 1.5 at
  13), and keep words on a small chip at 13 or more: at 11, even a thin outline read blurry on a phone.
- The Device Simulator draws a phone smaller than its size and stretches it to fit the window (a Galaxy A06,
  800 x 360, drew at 705 x 338), so small text looks softer there than on the phone. Compare text side by side in
  the same view before calling it fixed.
- A ScreenGui with `ScreenInsets.DeviceSafeInsets` (and `ClipToDeviceSafeArea`) can't reach a phone's real
  corners: on a Galaxy A06 the safe area stopped 47 points short on the camera side and 21 at the bottom. UI that
  must sit in the corner needs its own ScreenGui with `ScreenInsets.None` and `ClipToDeviceSafeArea = false`; keep
  about 8 points in for rounded corners.
- A ScrollingFrame's `CanvasPosition` moves its content by the same number of drawn (`AbsolutePosition`) pixels,
  `UIScale` included. To scroll a child to the top: `CanvasPosition.Y + (child.AbsolutePosition.Y -
  frame.AbsolutePosition.Y)`, clamped to `AbsoluteCanvasSize.Y - AbsoluteWindowSize.Y`, once any pop-in tween has
  finished (the drawn size changes during it).

## Adding a screen

1. Create a ScreenGui in StarterGui named after the screen, e.g. `Shop`.
2. Create `src/client/Controllers/UIController/Screens/Shop.luau` from the template below.
3. Add `Shop = require(script.Screens.Shop)` to `screenModules` in `UIController/init.luau`.

## Screen contract (`UIController/Types.luau`)

- The module returns `{ new = function(context, gui): Screen }`.
- A `Screen` has `Modal`, `StartsOpen`, `Open`, `Close`, `Destroy`. Non-modal screens (HUD, notifications) can
  be open together. Opening a modal (shop, settings) closes the other modals.
- `context.Controllers` is the controller registry; `context.Open(name)` / `context.Close(name)` switch screens.
  Screens never require each other.
- Screens may request changes through `Remotes` and display replicated values (attributes). They never decide
  outcomes.
- A screen owns its connections through a `Trove` and cleans up in `Destroy`.
- Look up elements with `FindFirstChild` and check `IsA` before use, so a renamed element warns instead of
  erroring.
- Other systems use `registry.UIController:Open(name)`, `:Close(name)`, `:IsOpen(name)`. Screens mount after
  the player's first spawn, usually after every controller's `Start`. `Open` on a screen that isn't mounted yet
  is remembered and applied when it mounts; `IsOpen` returns `false` until then.
- If the ScreenGui isn't found within 15 seconds, UIController warns with the expected path and skips only that
  screen.
- Studio-only tools (the debug panel) may make their own ScreenGui in code: the module's optional `Build(playerGui)`
  returns it, and UIController uses that instead of waiting for one from StarterGui (RobloxPack since 2026-10-05).
  Every screen players see is still built in Studio.

```lua
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local Hud = {}

function Hud.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local player = Players.LocalPlayer
	local trove = Trove.new()
	local label = gui:FindFirstChild("CashLabel", true)

	local function refresh()
		if label and label:IsA("TextLabel") then
			local cash = player:GetAttribute("Cash")
			label.Text = if type(cash) == "number" then tostring(cash) else "..."
		end
	end

	trove:Connect(player:GetAttributeChangedSignal("Cash"), refresh)
	refresh()

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Hud
```

## Buttons that call the server

Debounce on the client (disable the button until the request returns) so normal use never hits the server's
rate limit. Show a generic "try again" message when `Invoke` returns `false`.

## Deprecated UI APIs

`GuiObject:TweenPosition/TweenSize` → `TweenService`. `Draggable` → `UIDragDetector`. `FontSize` → `TextSize`.
`TextColor` → `TextColor3`. See `BRAIN/DEPRECATIONS.md`.

Reference: https://create.roblox.com/docs/ui
