--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(ReplicatedStorage.Net.Guard)
local Run = require(script.Parent.Run)

return function(t: Run.Suite)
	t.Test("Number rejects NaN, infinity and out-of-range values", function()
		local guard = Guard.Number(0, 10)
		t.Expect(guard(5)).ToBe(true)
		t.Expect(guard(0 / 0)).ToBe(false)
		t.Expect(guard(math.huge)).ToBe(false)
		t.Expect(guard(11)).ToBe(false)
		t.Expect(guard("5")).ToBe(false)
	end)

	t.Test("Integer rejects fractions", function()
		local guard = Guard.Integer(1, 3)
		t.Expect(guard(2)).ToBe(true)
		t.Expect(guard(2.5)).ToBe(false)
	end)

	t.Test("String enforces byte length and valid UTF-8", function()
		local guard = Guard.String(4)
		t.Expect(guard("abcd")).ToBe(true)
		t.Expect(guard("abcde")).ToBe(false)
		t.Expect(guard("\255")).ToBe(false)
	end)

	t.Test("OneOf accepts only listed strings", function()
		local guard = Guard.OneOf({ "Sword", "Bow" })
		t.Expect(guard("Bow")).ToBe(true)
		t.Expect(guard("Gun")).ToBe(false)
	end)

	t.Test("Optional allows nil", function()
		local guard = Guard.Optional(Guard.Boolean())
		t.Expect(guard(nil)).ToBe(true)
		t.Expect(guard(false)).ToBe(true)
		t.Expect(guard(1)).ToBe(false)
	end)

	t.Test("Array rejects holes, extra keys and oversized arrays", function()
		local guard = Guard.Array(Guard.Integer(0, 9), 3)
		t.Expect(guard({ 1, 2, 3 })).ToBe(true)
		t.Expect(guard({ 1, 2, 3, 4 })).ToBe(false)
		local extraKey: { [any]: any } = { 1, 2 }
		extraKey.x = 3
		local mixed: { any } = { 1 }
		table.insert(mixed, "2")
		t.Expect(guard(extraKey)).ToBe(false)
		t.Expect(guard(mixed)).ToBe(false)
	end)

	t.Test("Vector3 rejects NaN and distant positions", function()
		local guard = Guard.Vector3(100)
		t.Expect(guard(Vector3.new(1, 2, 3))).ToBe(true)
		t.Expect(guard(Vector3.new(0 / 0, 0, 0))).ToBe(false)
		t.Expect(guard(Vector3.new(1000, 0, 0))).ToBe(false)
	end)
end
