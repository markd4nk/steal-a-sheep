# Steal a Sheep trailer: shot list (2026-10-05, first cut)

About 35 s, 16:9 for the game page and a 9:16 cut. Real gameplay only, the game's own audio (its calm and chase
music are instrumental APM tracks, licensed for the experience; no voice-over, no lyrics). Captions describe gameplay
only: no prices, "free" or "best". Filmed in a Studio copy of main with `TrailerController` (Studio only; in the client
Registry on this branch), recorded with OBS (`trailer/obs.py`, `TRAILER_DIR=%USERPROFILE%\Videos\StealASheepTrailer`),
cut with `trailer/edit.py` from `trailer/stealasheep.cut.json`.

Staging: `ServerStorage.DebugBlankProfile` on (filming never touches a save), Play, then from Client calls
`Remotes.Debug:Invoke(...)`: `UnlockAll`, `GiveSheep` x12 and `GrowAll` (a full pen), `AddClimb` to tune how fast the
slide is against the god's speed, `SetSpeed` for the walk-ins, `Steal` (tier) for each theft. HUD off for every shot
(the rig's default); `ProximityPromptService` off.

| # | Shot | Seconds | Staging | Camera |
| --- | --- | --- | --- | --- |
| 1 | **Steal** (the hook) | 3 | `Steal 30`: the thief lands at Zeus's pasture and lifts a lamb overhead | Fixed, low and close in front of the thief, Zeus out of focus behind |
| 2 | **Alert** | 2 | Zeus's "!!" and point, during the head start | Close on Zeus's face and raised bolt, a slow push in |
| 3 | **Chase** | 5 | Walk downhill: the slide starts; Zeus runs after | Follow from in front and above, looking back up the slope at thief and god |
| 4 | **Slide wide** | 3 | The same slide, further down | High side glide down the colourful stretches |
| 5 | **Home** | 3 | Placed at the plot's gate carrying a lamb, walk in, `PutDown` | Fixed at the pen, the lamb hops down |
| 6 | **Pens** | 3 | A full pen roaming (12 grown sheep) | Slow glide along the pen fence |
| 7 | **Climb** | 5 | Nothing staged | Fast glide up the corridor from the meadow past the stages to High Olympus |
| 8 | **Caught** | 3 | `Steal` from a lower tier with little climbing: the god catches and punches the thief down the mountain | Fixed wide on the catch, the thief flying |
| 9 | **Gods** | 4 | The 30 avatar gods posed on risers at the summit (client copies, as the thumbnail) | Slow glide along the rows, Zeus centred at the end |
| 10 | **Title** | 3 | - | `edit.py`'s title card over the last frames: "Steal a Sheep" |

Page captions (gameplay only): 1 "Steal sheep from the gods", 3 "Slide home before they catch you", 6 "Fill your
pens", 7 "Climb to Zeus", 9 "30 gods to rob". Social captions: shorter and louder ("STEAL FROM ZEUS", "RUN!").
