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
    adjust = function(...) return gen:adjust(...) end,
    inc    = function(...) return gen:inc(...) end,
    dec    = function(...) return gen:dec(...) end,
    select = function(...) return gen:select(...) end,
    right  = function(...) return gen:right(...) end,
    left   = function(...) return gen:left(...) end,
    read   = function(...) return gen:read(...) end,
    write  = function(...) return gen:write(...) end,
    open   = function(...) return gen:open(...) end,
    close  = function(...) return gen:close(...) end,
    set    = function(...) return gen:set(...) end,
    clear  = function(...) return gen:clear(...) end,
	alloc  = function(...) return gen:alloc(...) end,
	free   = function(...) return gen:free(...) end,
	to     = function(...) return gen:to(...) end,
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


setfenv(func, fenv)


local status, ret, err = xpcall(func, debug.traceback)
-- TODO: handle this properly
if not status then
    print(ret)
end


return gen.buffer