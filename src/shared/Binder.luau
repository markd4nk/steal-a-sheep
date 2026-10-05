--!strict

local CollectionService = game:GetService("CollectionService")

export type Object = {
	Destroy: (self: any) -> (),
}

export type Component = {
	Tag: string,
	Ancestors: { Instance }?,
	new: (instance: Instance, registry: { [string]: any }) -> Object?,
}

export type Binder = {
	Destroy: (self: Binder) -> (),
}

local Binder = {}

function Binder.new(tag: string, construct: (instance: Instance) -> Object?, ancestors: { Instance }?): Binder
	local allowed: { Instance } = ancestors or { workspace }
	local objects: { [Instance]: Object } = {}
	local watchers: { [Instance]: RBXScriptConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local destroyed = false

	local function isAllowed(instance: Instance): boolean
		for _, ancestor in allowed do
			if instance:IsDescendantOf(ancestor) then
				return true
			end
		end
		return false
	end

	local function unbind(instance: Instance)
		local object = objects[instance]
		if not object then
			return
		end
		objects[instance] = nil
		local ok, message = pcall(object.Destroy :: any, object)
		if not ok then
			warn(`[{tag}] Destroy failed for {instance:GetFullName()}: {message}`)
		end
	end

	local function bind(instance: Instance)
		if destroyed or objects[instance] then
			return
		end
		local ok, result = pcall(construct, instance)
		if not ok then
			warn(`[{tag}] Construct failed for {instance:GetFullName()}: {result}`)
			return
		end
		if not result then
			return
		end
		if destroyed or not watchers[instance] or objects[instance] or not isAllowed(instance) then
			-- construct yielded (against the rule) and the instance was untracked or rebound meanwhile
			pcall(result.Destroy :: any, result)
			return
		end
		objects[instance] = result
	end

	local function refresh(instance: Instance)
		if isAllowed(instance) then
			bind(instance)
		else
			unbind(instance)
		end
	end

	local function track(instance: Instance)
		if destroyed or watchers[instance] then
			return
		end
		watchers[instance] = instance.AncestryChanged:Connect(function()
			refresh(instance)
		end)
		refresh(instance)
	end

	local function untrack(instance: Instance)
		local watcher = watchers[instance]
		if watcher then
			watcher:Disconnect()
			watchers[instance] = nil
		end
		unbind(instance)
	end

	table.insert(connections, CollectionService:GetInstanceAddedSignal(tag):Connect(track))
	table.insert(connections, CollectionService:GetInstanceRemovedSignal(tag):Connect(untrack))
	for _, instance in CollectionService:GetTagged(tag) do
		track(instance)
	end

	local function destroy(_self: Binder)
		if destroyed then
			return
		end
		destroyed = true
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		for instance in watchers do
			untrack(instance)
		end
	end

	return { Destroy = destroy }
end

return Binder
