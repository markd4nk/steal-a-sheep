--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)

-- The fleece paints Looks.Paint lays over a sheep's wool (a trimmed copy of Shear a Sheep's Utils/Mutations).
local Mutations = {}

function Mutations.Get(id: string?): GameConfig.Mutation?
	return if id then GameConfig.Mutations[id] else nil
end

function Mutations.PuffColor(mutation: GameConfig.Mutation, order: number, count: number): Color3
	if mutation.Rainbow then
		return Color3.fromHSV(((order - 1) / math.max(count, 1)) % 1, 0.72, 1)
	end
	return mutation.Color
end

return table.freeze(Mutations)
