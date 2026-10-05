--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

-- The one toast spot under the HUD's pictures on the left, shared by a Sheepdex find (DexCard) and a badge
-- (BadgeCard) so two never land on each other (a first Rare sheep is both): a card takes the spot before it shows and
-- frees it once it's gone; one that finds it taken waits for Freed.
local ToastSlot = {}

ToastSlot.Freed = Signal.new() :: Signal.Signal<>

local holder: string? = nil

function ToastSlot.Take(name: string): boolean
	if holder ~= nil and holder ~= name then
		return false
	end
	holder = name
	return true
end

function ToastSlot.Free(name: string)
	if holder == name then
		holder = nil
		ToastSlot.Freed:Fire()
	end
end

return ToastSlot
