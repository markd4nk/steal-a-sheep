# UI mock-ups

HTML mock-ups of this game's menus, drawn in Shear a Sheep's "Prize Fleece" look (the system `Theme.Fleece` and
`UIKit` build in the game), so a new screen can be shown and agreed before it's built. Nothing here is synced by Rojo or
read by the game. Use them when Studio is busy or a look needs several variants side by side; a `TEMP_` screen in
Studio is the closer check once one is picked.

| Path | What it is |
| --- | --- |
| `mockups/*.html` | The pages: `sell-stall` (the Sell Stall's menu, 2026-10-05; built as A, and in the game the pen's sheep don't show) |
| `kit.js` | The pieces: the sheep token as `SheepIcon` paints it, cards, buttons, panels, phone and PC frames with the HUD |
| `fleece.css` | Every token and component, copied from Shear a Sheep's `DESIGN/ui/fleece/fleece.css` (its `SPEC.md` has the rules) |
| `data.json` | Each family's token colours and a sample flock, written by `export-data.luau` from the game's own `GameConfig`, `Olympus` and `Economy` |
| `assets/` | The stud tile (Shear a Sheep's `art/ui/make_studs.py`) and the world behind the frames (a playtest screenshot) |
| `render.mjs` | Renders each page to `renders/<page>.png` and each frame to `renders/<page>/<id>.png` (gitignored) |

```
lune run DESIGN/ui/export-data.luau      after changing a family, a formula or the sample flock
node DESIGN/ui/render.mjs sell            pages whose name starts with "sell"
node DESIGN/ui/render.mjs --serve         http://127.0.0.1:8741/DESIGN/ui/mockups/sell-stall.html in a browser
```

It needs Chrome or Edge and a Roblox install (its Fredoka One and Builder Sans), and reads gvesster's icon pack from
`~/Downloads/Free Icon Pack v3.1 (Basic)/Free Icon Pack v3.1 (Basic)` (or `ICON_PACK`): the pack's licence lets the game
use its pictures, not pass them on, so they stay out of git.
