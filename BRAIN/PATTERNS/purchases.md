# Purchases

`PurchaseService` owns `MarketplaceService.ProcessReceipt`. Roblox allows only one handler; nothing else may set
it.

## Developer products (consumables: cash packs, boosts)

Add a grant to `src/server/Services/PurchaseService/Products.luau`:

```lua
local Products: { [number]: Grant } = {
	[1234567890] = function(player, registry)
		return registry.DataService:AdjustCash(player, 500)
	end,
}
```

- A grant changes **only the player's saved data**, through `registry.DataService`. It returns `true` once the
  reward is applied, and `false` if Roblox should retry later.
- A grant must not yield, prompt, or wait on the player.
- How it's crash-safe: the receipt id is written into the same profile as the reward. `ProcessReceipt` returns
  `PurchaseGranted` only after a save that contains the receipt has finished. A crash before that means Roblox
  retries, the receipt id is found, and the reward is not granted twice. If a receipt arrives while the player's
  data is still loading, `ProcessReceipt` waits up to 60 seconds for it, because Roblox only re-sends
  unprocessed receipts on the next purchase or rejoin. If the player leaves first, it stays pending until they
  rejoin.
- Rewards outside the profile (server-wide effects, other players' data) aren't protected this way. Ask the user
  before adding one.
- Never grant from `PromptProductPurchaseFinished` or from a client request. Official docs: use
  `ProcessReceipt` only.
- Prompt from the client: `MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)`.
- Products can also be bought from the game's Store page while the player is offline. The receipt is processed
  the next time they join, which this design handles.

## Passes (permanent: VIP, 2x cash)

- Check on the server with `registry.PurchaseService:OwnsPass(player, passId)`. It yields on the first check,
  then caches, and updates from `PromptGamePassPurchaseFinished`. Call it from `task.spawn` or a handler, never a
  lifecycle hook.
- Passes aren't receipts. Don't put them in `Products`.
- A system that grants a pass perk checks `OwnsPass` when the player loads (in `task.spawn`) and connects to
  `PurchaseService.PassPurchased`, so a purchase applies without a rejoin. Mirror ownership as a player
  attribute for the UI.
- Prompt from the client with `MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, passId)`.
- In Studio, `OwnsPass` ignores the passes the testing account owns (it created them, so every solo test would
  otherwise play as an owner of all of them). `PurchaseService:SetIgnorePasses(player, false)` (the debug panel's
  "Ignore owned passes") asks Roblox again; a pass bought or granted in the session counts.

## Paid random items (loot boxes, gacha, paid spins): policy, not optional

Anything random bought with Robux, or with currency bought with Robux (including keys, re-rolls, "luck" boosts):

- Show the odds of every outcome as percentages that sum to 100%, **before** purchase.
- Server-side, check `PolicyService:GetPolicyInfoForPlayerAsync(player).ArePaidRandomItemsRestricted`. When it is
  `true`, that player must not use paid random items. Offer the alternative the policy page lists (for example,
  direct purchase).
- Also respect `IsPaidItemTradingAllowed` if paid items can be traded.

Ask the user before building any paid random mechanic.

## Testing

Test that a grant happens exactly once, and that leaving mid-purchase leaves it pending until rejoin. In Studio,
`PurchaseService:Grant(player, productId)` runs a product's grant with no dialog or receipt, and `GrantPass(player,
passId)` makes a pass count as bought in this session (the debug panel has both). `PurchaseService.Granted` fires with
`(player, productId, fromReceipt)`, false for those debug grants, so analytics can skip them. For
developer products bought outside the game (the Store tab), use the Creator Hub test mode described on the
developer products page before enabling it. How to run a test purchase in Studio: `testing-studio.md`, Purchases
and saving.

Create products in Creator Hub under the experience's **Monetization > Developer Products**. Saving one can ask
you to accept Managed Pricing terms. That feature is optional, and turning it off skips the terms.

References:
https://create.roblox.com/docs/production/monetization/developer-products ·
https://create.roblox.com/docs/production/monetization/passes ·
https://create.roblox.com/docs/production/monetization/paid-random-items
