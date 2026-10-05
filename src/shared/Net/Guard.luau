--!strict

export type Guard = (value: any) -> boolean

local Guard = {}

local function isFinite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

function Guard.Boolean(): Guard
	return function(value)
		return type(value) == "boolean"
	end
end

function Guard.Number(min: number, max: number): Guard
	return function(value)
		return type(value) == "number" and isFinite(value) and value >= min and value <= max
	end
end

function Guard.Integer(min: number, max: number): Guard
	return function(value)
		return type(value) == "number" and isFinite(value) and value % 1 == 0 and value >= min and value <= max
	end
end

function Guard.String(maxBytes: number): Guard
	return function(value)
		return type(value) == "string" and #value <= maxBytes and utf8.len(value) ~= nil
	end
end

function Guard.OneOf(options: { string }): Guard
	local allowed: { [string]: boolean } = {}
	for _, option in options do
		allowed[option] = true
	end
	return function(value)
		return type(value) == "string" and allowed[value] == true
	end
end

function Guard.Instance(className: string): Guard
	return function(value)
		return typeof(value) == "Instance" and value:IsA(className)
	end
end

function Guard.Vector3(maxMagnitude: number): Guard
	return function(value)
		return typeof(value) == "Vector3"
			and isFinite(value.X)
			and isFinite(value.Y)
			and isFinite(value.Z)
			and value.Magnitude <= maxMagnitude
	end
end

function Guard.CFrame(maxDistance: number): Guard
	return function(value)
		if typeof(value) ~= "CFrame" then
			return false
		end
		for _, component in { value:GetComponents() } do
			if not isFinite(component) then
				return false
			end
		end
		return value.Position.Magnitude <= maxDistance
	end
end

function Guard.Optional(guard: Guard): Guard
	return function(value)
		return value == nil or guard(value)
	end
end

function Guard.Array(guard: Guard, maxLength: number): Guard
	return function(value)
		if type(value) ~= "table" then
			return false
		end
		local length = #value
		if length > maxLength then
			return false
		end
		local count = 0
		for key, item in value do
			count += 1
			if count > length or type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > length then
				return false
			end
			if not guard(item) then
				return false
			end
		end
		return count == length
	end
end

return table.freeze(Guard)
