--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Binder = require(ReplicatedStorage.Binder)
local Lifecycle = require(ReplicatedStorage.Lifecycle)

-- Add server components here, e.g. require(script.Parent.Parent.Components.Door).
local components: { Binder.Component } = {}

local ComponentService = { Name = "ComponentService" }

local registry: Lifecycle.Registry = {}
local binders: { Binder.Binder } = {}

function ComponentService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function ComponentService.Start(_self: any)
	for _, component in components do
		table.insert(
			binders,
			Binder.new(component.Tag, function(instance)
				return component.new(instance, registry)
			end, component.Ancestors)
		)
	end
end

function ComponentService.Destroy(_self: any)
	for _, binder in binders do
		binder:Destroy()
	end
	table.clear(binders)
end

return ComponentService
