# Desktop tools: recipes

Step-by-step jobs for the desktop tools. Read `desktop.md` first: its Rules, Finding Studio, Seeing and Clicking
and typing apply to every step here. Save the place and Publish animations have been run end to end; the rest are
starting points. When one works, or needs changing, tell the user and propose the change to this file
(`DESIGN/BRAIN_PROPOSALS.md`).

## Save the place

1. Only in Edit (`get_studio_state`): never during a playtest or while one is stopping. Check it's the real place
   (`list_roblox_studios` shows its place id), not an auto-recovery copy.
2. **File > Save to Roblox**. `click_element` "File" reports `invoked`, but the menu's items aren't in UI
   Automation, so use real clicks: click **File** at its screen rect from `ui_tree` (`coordinate_space: "screen"`),
   screenshot the menu's own window (Seeing), then click **Save to Roblox**. It's three rows above **Publish to
   Roblox**; don't slip.
3. No dialog opens. Confirm it in Studio's log (Seeing): `Saved new changes in "<place>" to Roblox.` Record it in
   `DESIGN/STUDIO_CONTENT.md` (saved, or still unsaved).

## Publish animations

For rigs whose Animation Editor drafts are in `ServerStorage.RBX_ANIMSAVES` (`animations.md`).

1. When the game needs them: live games play only published animations. It uploads assets to the owner's account,
   so list what you published in your report. Publish as the experience's owner (`game.CreatorType`, `game.CreatorId`
   from `execute_luau`); the dialog's Creator is **Me** for a user-owned game.
2. Avatar tab > **Clip Editor** opens the Animation Editor, which clears the selection. Then select the rig with
   `game:GetService("Selection"):Set({ rig })` from `execute_luau`: the editor takes it and loads one of its drafts.
3. The **⋯** button beside the animation's name > **Load** (click it; hovering doesn't open the submenu) > the draft.
   The submenu lists the drafts in a different order each time, so screenshot it before picking.
4. **⋯ > Publish to Roblox** opens the **Asset Configuration** window. Its Title starts as the loaded draft's name,
   so check it's the one you meant, then replace it (click the field, `ctrl+a`, type). Leave **Delete Local
   Instances** off to keep the draft for polishing. **Save**: after a few seconds of "Uploading" it says
   "Successfully submitted!" with the ID. Read the ID from a screenshot (the copy button would use the clipboard),
   then **Close**.
5. Check every ID with `execute_luau` in Edit before using it: `MarketplaceService:GetProductInfoAsync(id,
   Enum.InfoType.Asset)` gives the name, `AssetTypeId` 24 (Animation) and the creator, and
   `KeyframeSequenceProvider:GetKeyframeSequenceAsync("rbxassetid://" .. id)` should match the draft (keyframe and
   pose counts, last keyframe's time, `Loop`, `Priority`).
6. Republishing a polished draft under the same ID: **Overwrite an existing asset...** in that dialog.
7. Close the editor (its panel's ×) before playtesting or saving: while it's open it poses the rig and keeps a
   `workspace.RBX_MICROBONE_NODES` folder, and closing it removes both.

## Server & Clients test

1. From Edit: **Test > Start Test Session > Server and Clients** (F7). The client count beside the person icon in
   the top bar can be 0, which opens only a server window: set it with its arrows, then press Play. **Test > Add
   Clients** adds more. The mode and count stay set for the next session, so mention them when handing over.
2. A Studio window opens for the server and for each client; the Studio MCP lists them as extra studios
   (`testing-studio.md`, Studio windows).
3. End it with the red stop button left of the client count (or **Test > End Session**); `start_stop_play`
   doesn't. Send nothing else until `get_studio_state` shows Edit.

## Test purchase

1. Prompt from a client `execute_luau` (`testing-studio.md`, Purchases and saving).
2. Find the dialog in the Studio window that prompted (a client's window in a Server & Clients test). Try
   `click_element` "Buy", else screenshot and click it.
3. Check the grant on the server as `testing-studio.md` says.

## Import 3D

1. Only in Edit. **File > Import** (Ctrl+M; it was Import 3D) opens a Windows file dialog ("Open 3D File"): type
   the file's full path into File name and press Enter.
2. The Import Preview window opens. Set its options to what the game's docs say (for example its art folder's README)
   and leave the rest at their defaults: Anchored is under File General; Scale Unit and Merge Meshes under File
   Geometry (scroll the options down). There's no Use Imported Pivot box any more: each object's origin becomes its
   part's pivot anyway. Import.
3. Check the result with `execute_luau`: names, sizes, positions and pivots (`GOTCHAS.md`, imported pivots), and
   that nothing extra landed in the Workspace.

The first import leaves an **Import Queue** panel docked at the bottom. While it's open, File > Import shows a tick and
only toggles the panel: add the next file with the panel's folder button (its top left), which opens the same file
dialog. Close the panel when done.

Imported meshes are uploaded straight away: each MeshPart's `MeshId` is an `rbxassetid://` id, and identical meshes
share one. Save those ids in the repo. From then on `AssetService:CreateMeshPartAsync(Content.fromUri(id))` in
`execute_luau` (Edit) recreates any of them at its own size, so a lost or rebuilt set comes back without the import
dialog or the desktop tools. Place each one by its saved centre and set its `PivotOffset`.

Do the steps after an import one small `execute_luau` at a time (move the models, set properties, share meshes).
Studio has crashed doing them all in one call straight after an import (seen 2026-10-03, no log line); after a
reopen the same steps went through one by one. A `CollisionFidelity` change reads back as the old value for a moment.

## Creator Hub in Chrome

Run end to end on 2026-10-01: 29 developer products, 3 passes and the place's settings.

1. Find the Chrome window (`window` `list`, query `chrome`) and pass its `hwnd` as `focus` with
   `key_method: "scancode"`. The default (`auto`) uses window messages for browsers, which typed each letter twice and
   ignored `ctrl+a` and `ctrl+l`.
2. Open a page by URL: `ctrl+l`, `wait` 0.5 s (without it the first letter is lost and Chrome searches Google), type
   the URL, `Return`, `wait` about 5 s.
   - Developer product: `https://create.roblox.com/dashboard/creations/experiences/<universeId>/developer-products/<productId>/configure`
   - Pass: `.../experiences/<universeId>/passes/<passId>/configure`
   - The place's server size: `.../experiences/<universeId>/places/<placeId>/access` (Maximum Visitor Count)
3. Change a text: click the field, `ctrl+a`, type over it. **Save Changes** sits at the bottom: scroll down first. The
   "Item for sale" switch moves when the page hasn't loaded its regional prices yet, so screenshot before clicking
   it. Turning a product off keeps its price for later.
4. Every product page is laid out alike, so after the first one the same steps can run on the rest with
   `coordinate_space: "screen"` and the screen points the first `act` printed, still one or two items per batch.
5. Check each change without screenshots, through Roblox's public APIs (fetch them before you start too, to compare):
   `https://apis.roblox.com/developer-products/v1/developer-products/<id>/details` and
   `https://apis.roblox.com/game-passes/v1/game-passes/<id>/product-info` (Name, Description, IsForSale,
   PriceInRobux). Roblox's text filter can turn a whole description into `#####`: "One Jacob, straight into your
   pen..." and "One Racka, ..." were read as names, and "One Jacob sheep, ..." passed.

- Work in a new tab: the user's open tabs can be private.
- A product's or badge's new icon (**Change**, then the file dialog) shows at once but reverts on reload unless you
  scroll down and click **Save Changes**. Check it through the product API's `IconImageAssetId`.
- Custom analytics events are under the experience's Analytics > Explore (`analytics/custom-events` is a 404).
  Open one by URL: `.../analytics/explore?metric=CustomEventsV2&filter_CustomEventName=<Event>&filter_AggregationType=Count&breakdown=CustomField1`.
  Days are UTC, and the newest one is partial.

## The live game from this computer

Only with the user's OK: joining on their account kicks their other session.

- The live Roblox client ignores a bare click: move the mouse onto the button, nudge it a few pixels, wait 0.3 s,
  then press and release. `type` drops letters in its text boxes: one character per `type`, 40 ms apart.
- The owner's F9 console has a Server command line. Real players share that server, so act only on the user's own
  player.
- The client's log, `%LOCALAPPDATA%\Roblox\logs\*_Player_*_last.log`, has the game's prints and failed asset loads.
