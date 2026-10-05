# Components (behaviour on tagged instances)

Use a component when **many instances** share behaviour: doors, pickups, kill bricks, spinners. Tag them in
Studio (Tag Editor, or the `Tags` section in Properties). Use a system instead for game-wide state.

`src/shared/Binder.luau` does the tracking. It creates an object for each tagged instance under an allowed
ancestor (default `workspace`), and destroys it when the tag is removed, the instance leaves the DataModel
(including streaming out), or the instance moves outside the allowed ancestors.

## Adding one

1. Create `src/server/Components/Name.luau` (authoritative) or `src/client/Components/Name.luau` (presentation).
2. Add its `require` to `components` in `ComponentService` (server) or `ComponentController` (client).
3. Tag instances in Studio and save the place.

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Binder = require(ReplicatedStorage.Binder)
local Trove = require(ReplicatedStorage.Packages.Trove)

local KillBrick: Binder.Component = {
	Tag = "KillBrick",
	new = function(instance: Instance, _registry: { [string]: any }): Binder.Object?
		if not instance:IsA("BasePart") then
			warn(`[KillBrick] {instance:GetFullName()} is not a BasePart`)
			return nil
		end
		local trove = Trove.new()
		trove:Connect((instance :: BasePart).Touched, function(hit: BasePart)
			local character = hit.Parent
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end)
		return {
			Destroy = function()
				trove:Destroy()
			end,
		}
	end,
}

return KillBrick
```

## Rules

- `new` must not yield. Return `nil` to skip an instance, after a `warn` saying why.
- The returned object must have `Destroy`, and it must disconnect everything `new` connected.
- Settings that vary per instance (this door is slower) are attributes on the instance (`SpinSpeed`, `Damage`),
  read with a default when missing or the wrong type. Values every instance shares go in `src/shared/Config`.
- Server components decide outcomes (damage, rewards). Client components only present (spin, glow, sounds).
  A client component never grants anything.
- `Touched` fires many times per contact and for every body part. Debounce per character when granting.
- Reach systems through the registry argument: `registry.DataService:AdjustCash(player, 5)`.
- Set `Ancestors` on the component table to track tags outside `workspace`, e.g. `Ancestors = { workspace,
  game:GetService("Players") }` for character parts.

`src/client/Components/Spinner.luau` is a working example: tag an anchored part `Spinner` and optionally set a
`SpinSpeed` attribute (degrees per second).
