local x = alloc(1)
local y = alloc(1)

to(x)
set(21)
open()
    dec()
    to(y)
    inc(2)
    to(x)
close()

to(y)
inc(23)

write()