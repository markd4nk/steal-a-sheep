--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Binder = require(ReplicatedStorage.Binder)

-- Example client component: tag an anchored part "Spinner" and optionally set a SpinSpeed attribute
-- (degrees per second). Client-side, so it is presentation only; other players see their own copy spin.
local Spinner: Binder.Component = {
	Tag = "Spinner",
	new = function(instance: Instance, _registry: { [string]: any }): Binder.Object?
		if not instance:IsA("BasePart") then
			warn(`[Spinner] {instance:GetFullName()} is not a BasePart`)
			return nil
		end
		local part = instance :: BasePart
		local connection = RunService.PreRender:Connect(function(deltaTime: number)
			local speed = part:GetAttribute("SpinSpeed")
			local degreesPerSecond = if type(speed) == "number" then speed else 90
			part.CFrame *= CFrame.Angles(0, math.rad(degreesPerSecond * deltaTime), 0)
		end)
		return {
			Destroy = function()
				connection:Disconnect()
			end,
		}
	end,
}

return Spinner
