--!strict

export type Registry = { [string]: any }

export type System = {
	Name: string,
	Init: ((self: any, registry: Registry) -> ())?,
	Start: ((self: any) -> ())?,
	Destroy: ((self: any) -> ())?,
}

export type Lifecycle = {
	Start: (self: Lifecycle) -> (),
	Destroy: (self: Lifecycle) -> (),
}

local Lifecycle = {}

local function runHook(system: System, phase: string, hook: (...any) -> (), ...: any)
	local thread = coroutine.create(hook)
	local ok, message = coroutine.resume(thread, system, ...)
	if not ok then
		error(`[{system.Name}.{phase}] {debug.traceback(thread, tostring(message))}`, 0)
	end
	if coroutine.status(thread) ~= "dead" then
		coroutine.close(thread)
		error(`[{system.Name}.{phase}] yielded. Hooks must return immediately; move waiting work into task.spawn.`, 0)
	end
end

function Lifecycle.new(systems: { System }): Lifecycle
	local registry: Registry = {}
	for _, system in systems do
		assert(type(system.Name) == "string" and system.Name ~= "", "Every system needs a Name")
		assert(registry[system.Name] == nil, `Duplicate system name: {system.Name}`)
		registry[system.Name] = system
	end
	table.freeze(registry)

	local state = "Created"
	local initialized: { System } = {}

	local function destroy(_self: Lifecycle)
		if state == "Destroyed" then
			return
		end
		state = "Destroyed"
		for index = #initialized, 1, -1 do
			local system = initialized[index]
			local hook = system.Destroy
			if hook then
				local ok, message = xpcall(hook :: any, debug.traceback, system)
				if not ok then
					warn(`[{system.Name}.Destroy] {message}`)
				end
			end
		end
		table.clear(initialized)
	end

	local lifecycle: Lifecycle

	local function start(_self: Lifecycle)
		assert(state == "Created", `Cannot start a lifecycle that is {state}`)
		state = "Starting"
		local ok, message = pcall(function()
			for _, system in systems do
				table.insert(initialized, system)
				local hook = system.Init
				if hook then
					runHook(system, "Init", hook, registry)
				end
			end
			for _, system in systems do
				local hook = system.Start
				if hook then
					runHook(system, "Start", hook)
				end
			end
		end)
		if not ok then
			destroy(lifecycle)
			error(message, 0)
		end
		state = "Started"
	end

	lifecycle = { Start = start, Destroy = destroy }
	return lifecycle
end

return Lifecycle
