local args = { ... }
local base_path = args[1]
local main_file = args[2]

local SEPARATOR = package.config:sub(1,1)


local func, err = loadfile(base_path .. SEPARATOR .. main_file)
if not func then
    print(err)
    return {} -- TODO
end


local gen = CodeGen()


local fenv = {
    string = _G.string,
	math = _G.math,
	table = _G.table,
    xpcall = _G.xpcall,
	tostring = _G.tostring,
	print = _G.print,
	unpack = _G.unpack,
	next = _G.next,
	assert = _G.assert,
	tonumber = _G.tonumber,
	pcall = _G.pcall,
	type = _G.type,
	select = _G.select,
	pairs = _G.pairs,
	ipairs = _G.ipairs,
	error = _G.error,
}
fenv._G = fenv


local included = {}
fenv.include = function(file)
    local path = base_path .. SEPARATOR .. file

	if included[path] then
		return
	end
	included[path] = true

	local func, err = loadfile(path)

	if not func then
		error(err)
	end

	setfenv(func, fenv)
	local status, ret, err = xpcall(func, debug.traceback)
	if not status or err then
		error(ret)
	end
end


local codegen_fns = { "adjust", "inc", "dec", "select", "right", "left", "read", "write", "open", "close", "set", "clear", "alloc", "free", "to" }
for _, fn in ipairs(codegen_fns) do
	fenv[fn] = function(...) return gen[fn](gen, ...) end
end

setfenv(func, fenv)


local status, ret, err = xpcall(func, debug.traceback)
-- TODO: handle this properly
if not status then
    print(ret)
end


return gen.buffer