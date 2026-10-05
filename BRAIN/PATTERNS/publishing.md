# Publishing and what's live

**File > Publish to Roblox** puts everything in the place in front of players: every session's Studio-side work and
whatever scripts are in Studio, not only your task's. Ask the user first, every time (`desktop.md`, Rules).

## What's live

- Studio's logs say what went live: `%LOCALAPPDATA%\Roblox\logs\*_Studio_*_last.log`, one per Studio process, written
  while it runs. Search them for `Saved new changes`, `Published new changes`, `No changes to the place` and
  `Add publish notes to v`; that last line names the version that went live. Git notes can miss a publish: one went
  live without anyone writing it down (2026-10-03).
- A publish with nothing changed since the last save still reports success, but adds no Version History row: it
  publishes the latest version again. Version History's time is when a version was saved, not when it was published.
- Creator Hub > the place > Version History > **Show published only** lists what went live.
- Several Studio processes can be open at once. To match the Studio MCP's Studio to its log, find a playtest's
  server-ready print in it.

## Releasing

1. Make the place match one commit of main: its scripts (Rojo from the main checkout, or each script's text checked
   against the commit), and the Studio-side content from that commit's `studio/` build scripts, rerun for anything
   that changed since the last release. No `TEMP_` instances, no debug flags left on (`sessions.md`).
2. Playtest that state: both bootstraps `Ready`, the unit tests, the console clean of our warnings, and a
   multi-player test if the release touches other players (`testing.md`).
3. **Save to Roblox**, then **Publish to Roblox** (`desktop-recipes.md`), with the user's OK.
4. After a data schema change, restart outdated servers: Creator Hub > the experience > Server Management > Restart
   Servers > "Restart only servers with outdated versions" (`data.md`). Do the same when old servers can't work with
   the new version (changed remotes, products they don't know).
5. Only then change prices in Creator Hub or put new products on sale, so nobody buys what the live servers can't
   grant.
6. Record the version, its commit and what went out in `DESIGN/CURRENT_STATE.md` (Live).

Tell the user every change that went out, not only your task's: find the last live version (above), list the feature
commits since it (`git log --no-merges <last-live-commit>..HEAD`, docs left out) and the Studio-side saves, in plain
words, and say which may have been live already.

## Creator Hub limits

- **Badges**: each experience gets 5 free badge creations a day, resetting at 00:00 GMT; each one past that costs 100
  Robux, so ask the user. A game's badge ids: `https://badges.roblox.com/v1/universes/<universeId>/badges?limit=100`.
  A badge whose `statistics.awardedCount` is 0 has never been awarded by a live server: its id isn't in a published
  version yet. Rarity is a daily figure, so it reads 0% until the day after the first awards.
- **Maturity questionnaire** (Creator Hub > Configure > Questionnaire): once completed it can't be edited, only
  restarted, which asks every question again. When something new needs declaring (paid random items, new content),
  restart and give the same answers except the new one, so keep the answers in the game's `DESIGN/`. Check the
  preview's label before **Submit and publish**, then reload to confirm it.

## A private test experience for phones

To try a branch on a real phone without publishing it to players, use a second, private experience owned by the user.
It has its own saves, and Robux prompts fail there (products and passes belong to the live universe). To publish a
branch to it without touching the shared place: **File > Download a Copy** of the live place, open that file in a
second Studio (ask the user first: `sessions.md`), serve the branch with Rojo into that window only, run the build
scripts, then **File > Publish to Roblox As > Update existing experience** and pick the test experience, never the
live one. Close the second Studio afterwards.
