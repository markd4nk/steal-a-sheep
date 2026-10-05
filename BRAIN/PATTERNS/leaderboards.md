# Global leaderboards

A top-N board across every server uses an `OrderedDataStore`: a separate store holding one number per player.
The number itself lives in player data (e.g. a saved `CashEarned`), and the board mirrors it.

## Store

- `DataStoreService:GetOrderedDataStore(name)`. In Studio add a `_Studio` suffix, as `DataService` does, so
  playtests never touch the live board.
- Getting the store throws where DataStores are unavailable (unpublished place, or Studio API access off).
  `pcall` it in `Start` and show "Leaderboard unavailable" instead of failing startup.
- Key: `tostring(player.UserId)`. Value: a whole number.

## Writing

- Write from the refresh loop, only for players whose value changed since the last write, and once more when
  they leave (`DataService.PlayerReleasing`, inside `task.spawn` because that handler mustn't yield). This is
  the exception to "never save on a timer": it's a different store with its own budget.
- Use `UpdateAsync` returning `math.max(old or 0, new)`, so a late write from an older session can't lower a
  score. The type definitions say the transform returns `number`, so returning `nil` to cancel won't
  type-check; `math.max` never needs to.
- Budget per server per minute: `GetSortedAsync` 5 + 2 × players; ordered writes 30 + 5 × players. One read
  and one write per changed player every 60 s fits easily.

## Reading and showing

- `store:GetSortedAsync(false, 10):GetCurrentPage()` gives `{ key, value }` entries, highest first.
- Names: `Players:GetNameFromUserIdAsync(userId)` in a `pcall`, cached per id. Studio test players have
  negative ids with no account, so fall back to `Player1`-style names.
- A board that shows everyone the same thing can be driven by the server: a SurfaceGui built in Studio with
  rows named `Row1`…`RowN`, whose text the server sets. It replicates, and streams in showing the current text.
  Per-player screens still belong to `UIController`.
- What counts is a design call; list it under *To review* in `DESIGN/DECISIONS.md`. Currency bought with Robux is
  usually left out so the top spot can't be bought.

References: https://create.roblox.com/docs/reference/engine/classes/OrderedDataStore ·
https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits
