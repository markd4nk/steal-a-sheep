--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Net = require(ReplicatedStorage.Net)

require(ReplicatedStorage.Remotes)
Net.Publish()

local runtime = Lifecycle.new(require(script.Parent.Registry))

game:BindToClose(function()
	runtime:Destroy()
end)

runtime:Start()
script:SetAttribute("Ready", true)
print(`[{GameConfig.Name}] Server ready`)
