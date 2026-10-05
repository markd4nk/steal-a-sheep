--!strict

-- A click on every button of a screen, rows cloned in later included, so no screen wires its own.
local Clicks = {}

-- A button's click dies with the button; only the watcher for new ones is returned, for the caller to disconnect.
function Clicks.Bind(gui: ScreenGui, click: () -> ()): RBXScriptConnection
	local function watch(instance: Instance)
		if instance:IsA("GuiButton") then
			instance.Activated:Connect(click)
		end
	end
	for _, descendant in gui:GetDescendants() do
		watch(descendant)
	end
	return gui.DescendantAdded:Connect(watch)
end

return table.freeze(Clicks)
