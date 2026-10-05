# Several sessions at once

The user often runs several agent sessions on one computer, each in its own git worktree (T3 Code makes one per
thread), sometimes under two Claude accounts. The main checkout, Studio (one place, one Rojo port, the Studio MCP) and
the mouse and keyboard are shared. Most of the costly accidents in this pack's first game came from that sharing: a
map deleted by keys meant for another window, scripts reverted by a Rojo sync from an older branch, answers quoted
from a stale worktree.

## Your worktree

- At the start of a task, check you aren't behind: `git log --oneline HEAD..main`. New worktrees have started about
  20 commits behind, and an agent quoted an old price from one. If it's behind and your tree is clean,
  `git merge --ff-only main`.
- Merge main into your branch early and often, to settle conflicts while they're small; that's always safe. Merging
  your branch into main changes what everyone else builds on: do it once your work is checked, and before anyone
  syncs scripts into the shared place (below).
- T3 Code renames a worktree's branch (`t3code/<hash>` becomes a descriptive name) after it starts, so read
  `git branch --show-current` before merging.
- When the user says something is "still" wrong, the fix may sit on a branch nobody merged. Check
  `git branch --no-merged main` and `git log main..<branch>` on likely ones first, and say which branch held it.

## Who else is working

- `ListAgents` (Claude Code) lists only the sessions of your own account and config folder: sessions of the other
  account can't be listed or messaged. Also look for transcripts written in the last few minutes,
  `find ~/.claude*/projects -name "*.jsonl" -mmin -10` (any but yours is a live peer), and read
  `~/.claude*/sessions/*.json` (each session's folder, and whether it's busy).
- Hand over across accounts through the repo (`DESIGN/CURRENT_STATE.md`, a handoff doc, git) or through the user,
  not "message me when you're done".
- For a long run with several sessions (overnight), one lock file and one log outside the repo worked: a
  `STUDIO_LOCK.txt` that says HELD (by which session) or FREE, and a `LOG.md` with a line per handover. Each session
  reads both before touching Studio or the desktop. Hand the lock straight to the next session, leaving staged work
  (imported meshes) in place.

## Studio is shared

One session at a time uses Studio: playtests, build scripts, Rojo syncs, saving. The others write code and run
`check.ps1` in their worktrees, and test once Studio is free. Say when you take Studio, and send "Studio free" (or
write it in the lock file) when you're done.

- **Every Studio edit lasts.** With Team Create on, the place keeps edits without a Save: reopening it brought back a
  branch's scripts, rebuilt menus and a debug flag with no Save in between (seen 2026-10-03), and the next Save or
  Publish ships them. Clean up in the same turn: delete `TEMP_` instances and test scripts, turn debug attributes
  off, and after testing a branch put main's scripts back (Rojo from the main checkout) and rerun main's `studio/`
  build scripts for anything you rebuilt.
- **Whose scripts are in Studio?** A peer may hand Studio over holding their unmerged branch's scripts, and a Rojo sync
  from your branch silently puts main's older copies of their files back. Check `git branch --no-merged main` and ask.
  If their branch doesn't touch your files, set your one changed script's `Source` from `execute_luau` in Edit
  (compare its length with the file on disk) instead of syncing, or wait for their merge. For several scripts,
  `python scripts/stage_branch.py --base <commit>` (RobloxPack) writes snippets that check the place still holds
  `<commit>`'s scripts, swap yours in for a playtest, then put everything back and verify it.
- **Merge before others sync.** Scripts that are in the place but not in main disappear at the next session's Rojo
  sync.
- **One Studio window.** Each Studio takes about 3 GB, jumps to the front and catches stray clicks. Ask the user before
  opening a second one on a local copy of the place.
- **Timings need the same conditions.** Another session focusing its Studio window throttles yours to about 15 fps
  mid-run. Measure main and your branch back to back, note each run's mean frame time, and trust counts over
  milliseconds (`testing-studio.md`, Performance).
- Sharing the mouse and keyboard: `desktop.md`, Other sessions.

## Tools on Windows

- Python's `open(path, "w")` writes CRLF on Windows. Write bytes, or pass `newline=""` (`check.ps1` warns about
  CRLF where git expects LF).
- Long-running background commands (`rojo serve`, Blender's GUI for its MCP) need a long timeout (Claude Code:
  `timeout: 7200000`); the default 30 minutes stops them mid-task.

## After a crash

- Files being written at that moment can be left as NUL bytes: the shared `.git/config`, a worktree's index, a file
  mid-edit (seen 2026-10-02). If git errors oddly or a file diffs as binary, scan for NUL bytes first. `git read-tree
  HEAD` in that worktree rebuilds a zeroed index and keeps the working files; restore an edited file from git.
  `check.ps1` fails on NUL bytes in tracked text files.
- Studio may reopen an auto-recovered copy, whose tab title ends in `@ <date time>`. Don't save it over the real
  place: reopen the place from Roblox by running Studio's exe (its path from
  `Get-CimInstance Win32_Process -Filter "name='RobloxStudioBeta.exe'"`) with
  `-task EditPlace -placeId <placeId> -universeId <universeId>`. Roblox allows one session per place, so the other
  window drops to the start page, and the Studio MCP's id changes (`list_roblox_studios` again). Unsaved Team Create
  edits come back with it (above).
