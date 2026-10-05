--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Binder = require(ReplicatedStorage.Binder)
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local Components = script.Parent.Parent.Components

local components: { Binder.Component } = {
	require(Components.Spinner),
}

local ComponentController = { Name = "ComponentController" }

local registry: Lifecycle.Registry = {}
local binders: { Binder.Binder } = {}

function ComponentController.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function ComponentController.Start(_self: any)
	for _, component in components do
		table.insert(
			binders,
			Binder.new(component.Tag, function(instance)
				return component.new(instance, registry)
			end, component.Ancestors)
		)
	end
end

function ComponentController.Destroy(_self: any)
	for _, binder in binders do
		binder:Destroy()
	end
	table.clear(binders)
end

return ComponentController
