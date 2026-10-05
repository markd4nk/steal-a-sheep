--!strict

export type Expectation = {
	ToBe: (expected: any) -> (),
	ToEqual: (expected: any) -> (),
	ToThrow: () -> (),
}

export type Suite = {
	Test: (name: string, body: () -> ()) -> (),
	Expect: (value: any) -> Expectation,
}

type Case = {
	Name: string,
	Body: () -> (),
}

local function show(value: any): string
	return if type(value) == "string" then string.format("%q", value) else tostring(value)
end

local function deepEqual(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for key, value in a do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

local function expect(value: any): Expectation
	return {
		ToBe = function(expected: any)
			if value ~= expected then
				error(`expected {show(expected)}, got {show(value)}`, 2)
			end
		end,
		ToEqual = function(expected: any)
			if not deepEqual(value, expected) then
				error(`expected a value deeply equal to {show(expected)}, got {show(value)}`, 2)
			end
		end,
		ToThrow = function()
			assert(type(value) == "function", "ToThrow needs a function")
			if pcall(value) then
				error("expected the function to throw", 2)
			end
		end,
	}
end

-- Runs every ModuleScript named *.spec under root (default: this folder). Returns (allPassed, report).
return function(root: Instance?): (boolean, string)
	local lines: { string } = {}
	local passed, failed = 0, 0
	for _, module in (root or script.Parent):GetDescendants() do
		if not module:IsA("ModuleScript") or not string.match(module.Name, "%.spec$") then
			continue
		end
		local cases: { Case } = {}
		local loaded, loadError = pcall(function()
			local suite = require(module) :: any
			suite({
				Test = function(name: string, body: () -> ())
					table.insert(cases, { Name = name, Body = body })
				end,
				Expect = expect,
			})
		end)
		if not loaded then
			failed += 1
			table.insert(lines, `FAIL {module.Name}: {loadError}`)
			continue
		end
		for _, case in cases do
			local ok, message = pcall(case.Body :: any)
			if ok then
				passed += 1
			else
				failed += 1
				table.insert(lines, `FAIL {module.Name} > {case.Name}: {message}`)
			end
		end
	end
	table.insert(lines, `{passed} passed, {failed} failed`)
	local report = table.concat(lines, "\n")
	print(report)
	return failed == 0, report
end
