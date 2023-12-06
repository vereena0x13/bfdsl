local args = { ... }
local base_path = args[1]
local main_file = args[2]

local SEPARATOR = package.config:sub(1,1)


local gen = CodeGen()


gen:set(21)
gen:open()
    gen:right()
    gen:inc(2)
    gen:left()
    gen:dec()
gen:close()
gen:right()
gen:write()


-- local code = loadfile(base_path .. SEPARATOR .. main_file)
-- code()


return gen.buffer