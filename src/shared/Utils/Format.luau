--!strict

-- Thousand, million, billion, trillion, quadrillion, quintillion, sextillion. Each unit is written out rather than
-- worked out as 1000 ^ n so it's exactly its power of ten, which the digit maths in Short relies on.
local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx" }
local UNITS = { 1e3, 1e6, 1e9, 1e12, 1e15, 1e18, 1e21 }

local Format = {}

-- 12345 -> "12,345". "%.0f", not "%d": "%d" goes through a 64-bit integer, which overflows past about 9.2e18.
function Format.Number(value: number): string
	local sign = if value < 0 then "-" else ""
	local digits = string.format("%.0f", math.floor(math.abs(value)))
	local groups: { string } = {}
	local head = #digits % 3
	if head > 0 then
		table.insert(groups, string.sub(digits, 1, head))
	end
	for index = head + 1, #digits, 3 do
		table.insert(groups, string.sub(digits, index, index + 2))
	end
	return sign .. table.concat(groups, ",")
end

-- 950 -> "950", 1500 -> "1.5K", 12345 -> "12.3K", 4900000 -> "4.9M", then B, T, Qa, Qi and Sx; past 999Sx it counts
-- on in Sx ("1,234Sx"). Keeps three digits and rounds down, so a balance never reads higher than it is. Integer maths
-- throughout, dividing only by exact powers of ten, so 2900 can't come out as "2.89K" (nor 9.2e18 as "9.19Qi").
function Format.Short(value: number): string
	local sign = if value < 0 then "-" else ""
	local whole = math.floor(math.abs(value))
	if whole < 1000 then
		return sign .. string.format("%d", whole)
	end
	local index = 1
	while index < #UNITS and whole >= UNITS[index + 1] do
		index += 1
	end
	local unit = UNITS[index]
	if whole >= 1000 * unit then
		return sign .. Format.Number(whole // unit) .. SUFFIXES[index]
	end
	local decimals = if whole < 10 * unit then 2 elseif whole < 100 * unit then 1 else 0
	local scale = 10 ^ decimals
	local kept = whole // (unit // scale)
	local text = string.format("%d", kept // scale)
	if decimals > 0 then
		local fraction = string.gsub(string.format(`%0{decimals}d`, kept % scale), "0+$", "")
		if fraction ~= "" then
			text ..= "." .. fraction
		end
	end
	return sign .. text .. SUFFIXES[index]
end

-- 1500 -> "$1.5K"
function Format.Cash(value: number): string
	return "$" .. Format.Short(value)
end

-- An income or a Climbing: tenths under 100 (12.5 -> "12.5", 3 -> "3"), then like Short.
function Format.Rate(value: number): string
	if value < 100 then
		local tenths = math.floor(value * 10 + 1e-6)
		return if tenths % 10 == 0 then `{tenths // 10}` else string.format("%.1f", tenths / 10)
	end
	return Format.Short(value)
end

-- 133 -> "2:13", and from an hour on 5025 -> "1:23:45". Rounds up, so a countdown never reads 0:00 while any time is
-- left.
function Format.Duration(seconds: number): string
	local whole = math.max(0, math.ceil(seconds - 1e-6))
	if whole >= 3600 then
		return string.format("%d:%02d:%02d", whole // 3600, whole // 60 % 60, whole % 60)
	end
	return string.format("%d:%02d", whole // 60, whole % 60)
end

-- A multiplier: 1.5 -> "x1.5", 2 -> "x2", 139.5 -> "x139". Tenths, rounded down, and from 100 on like Short.
function Format.Multiplier(value: number): string
	if value >= 100 then
		return "x" .. Format.Short(value)
	end
	local tenths = math.floor(value * 10 + 1e-6)
	return if tenths % 10 == 0 then `x{tenths // 10}` else string.format("x%.1f", tenths / 10)
end

-- "Racka" -> "a Racka", "Argali" -> "an Argali"
function Format.Indefinite(noun: string): string
	return if string.find(noun, "^[AEIOUaeiou]") then `an {noun}` else `a {noun}`
end

return table.freeze(Format)
