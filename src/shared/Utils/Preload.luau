--!strict

local ContentProvider = game:GetService("ContentProvider")

-- Fetches sounds' audio and pictures ahead of use and asks again later for any that didn't arrive, waiting longer each
-- time. While Roblox's asset servers throttle a client (HTTP 429, about 141 "Failed to load sound" a day in the live
-- error report of 2026-10-03), something asked for again at once only fails again, so callers use only what has
-- arrived. An iPhone never showed the store's packs or the kennel's dogs, fetched once when the menu opened (2026-10-04).
local Preload = {}

local RETRY_SECONDS = { 15, 45, 120, 300 } -- the waits before each new try at what failed; then it's left

-- The asset number in a content id ("rbxassetid://123", or a URL ending in it), so the callback's id matches the
-- item's however either is written.
local function assetKey(id: string): string
	return string.match(id, "(%d+)$") or id
end

-- Yields until every item has arrived or the last try is used up, calling `loaded` with each item as it arrives. Items
-- sharing an id (`idOf`) are fetched once; `fetch` is what PreloadAsync is given for an item.
local function fetchAll<T>(items: { T }, idOf: (T) -> string, fetch: (T) -> any, loaded: (item: T) -> ())
	local waiting = items
	for try = 1, #RETRY_SECONDS + 1 do
		if try > 1 then
			task.wait(RETRY_SECONDS[try - 1])
		end
		local byKey: { [string]: { T } } = {}
		local requests = {}
		for _, item in waiting do
			local key = assetKey(idOf(item))
			local list = byKey[key]
			if list then
				table.insert(list, item)
			else
				byKey[key] = { item }
			end
			table.insert(requests, fetch(item))
		end
		local failed: { T } = {}
		-- If the call itself errors, the items it never named count as arrived below, so one bad call can't leave a
		-- whole group of them unused all session.
		pcall(
			ContentProvider.PreloadAsync,
			ContentProvider,
			requests,
			function(id: string, status: Enum.AssetFetchStatus)
				local key = assetKey(id)
				local list = byKey[key]
				if not list then
					return
				end
				byKey[key] = nil
				for _, item in list do
					if status == Enum.AssetFetchStatus.Success then
						loaded(item)
					else
						table.insert(failed, item)
					end
				end
			end
		)
		-- An item the callback never named counts as arrived, rather than unused for good.
		for _, list in byKey do
			for _, item in list do
				loaded(item)
			end
		end
		if #failed == 0 then
			return
		end
		waiting = failed
	end
end

-- Sounds' audio: `loaded` gets each sound as its audio arrives.
function Preload.Sounds(sounds: { Sound }, loaded: (sound: Sound) -> ())
	fetchAll(sounds, function(sound: Sound): string
		return sound.SoundId
	end, function(sound: Sound): any
		return sound
	end, loaded)
end

-- Pictures by content id: `loaded` gets each id as its picture arrives.
function Preload.Images(ids: { string }, loaded: (id: string) -> ())
	fetchAll(ids, function(id: string): string
		return id
	end, function(id: string): any
		return id
	end, loaded)
end

return table.freeze(Preload)
