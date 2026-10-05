--!strict

-- [developerProductId] = grant. A grant changes only the player's saved data through registry.DataService,
-- must not yield, and returns true once the reward is applied. See BRAIN/PATTERNS/purchases.md.
export type Grant = (player: Player, registry: { [string]: any }) -> boolean

local Products: { [number]: Grant } = {}

return Products
