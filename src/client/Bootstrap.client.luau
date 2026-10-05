--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Net = require(ReplicatedStorage.Net)

-- StarterPlayerScripts' children are copied into PlayerScripts one at a time, and this script can start before its
-- siblings arrive: in a fresh place the Registry found no Controllers folder (2026-10-05).
for _, child in StarterPlayer.StarterPlayerScripts:GetChildren() do
	if not script.Parent:WaitForChild(child.Name, 10) then
		warn(`[Bootstrap] PlayerScripts.{child.Name} never arrived`)
	end
end

-- PlayerScripts run after initial replication, but the remotes folder is created by the server at runtime.
ReplicatedStorage:WaitForChild(Net.FolderName)
require(ReplicatedStorage.Remotes)

local runtime = Lifecycle.new(require(script.Parent.Registry))

script.Destroying:Connect(function()
	runtime:Destroy()
end)

runtime:Start()
script:SetAttribute("Ready", true)
print(`[{GameConfig.Name}] Client ready`)
