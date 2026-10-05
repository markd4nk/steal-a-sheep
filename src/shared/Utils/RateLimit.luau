--!strict

export type RateLimit = {
	Allow: (self: RateLimit, key: any) -> boolean,
	Remove: (self: RateLimit, key: any) -> (),
}

type Bucket = {
	Tokens: number,
	UpdatedAt: number,
}

local RateLimit = {}

function RateLimit.new(count: number, window: number, clock: (() -> number)?): RateLimit
	assert(count >= 1 and count % 1 == 0, "RateLimit count must be a positive integer")
	assert(window > 0 and window < math.huge, "RateLimit window must be a positive number of seconds")
	local now = clock or os.clock
	local refillPerSecond = count / window
	-- Weak keys so a Player who leaves is forgotten without a PlayerRemoving hook.
	local buckets: { [any]: Bucket } = setmetatable({}, { __mode = "k" }) :: any

	local function allow(_self: RateLimit, key: any): boolean
		local time = now()
		local bucket = buckets[key]
		if not bucket then
			bucket = { Tokens = count, UpdatedAt = time }
			buckets[key] = bucket
		end
		bucket.Tokens = math.min(count, bucket.Tokens + (time - bucket.UpdatedAt) * refillPerSecond)
		bucket.UpdatedAt = time
		if bucket.Tokens < 1 then
			return false
		end
		bucket.Tokens -= 1
		return true
	end

	local function remove(_self: RateLimit, key: any)
		buckets[key] = nil
	end

	return { Allow = allow, Remove = remove }
end

return RateLimit
