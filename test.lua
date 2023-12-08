function move(dst, src)
	assert(allocated(src))
	assert(allocated(dst))

	to(dst)
	clear()
	to(src)
	open()
		dec()
		to(dst)
		inc()
		to(src)
	close()
	to(dst)
end

function copy(dst, src)
	assert(allocated(src))
	assert(allocated(dst))

	local tmp = alloc()

	to(dst)
	clear()
	to(src)
	open()
		dec()
		to(dst)
		inc()
		to(tmp)
		inc()
		to(src)
	close()

	move(src, tmp) 
	free(tmp)
	to(dst)
end

function swap(a, b)
	assert(allocated(a))
	assert(allocated(b))

	local tmp = alloc()

	move(tmp, a) 
	move(a, b) 
	move(b, tmp) 

	free(tmp)
end

function if_then(cond, t)
	assert(allocated(cond))
	assert(type(t) == "function")

	to(cond)
	open()
		t()
		to(cond)
		clear()
	close()
end

function if_then_else(cond, t, f)
	assert(allocated(cond))
	assert(type(t) == "function")
	assert(type(f) == "function")

	local tmp = alloc()

	to(tmp)
    set(1)

	to(cond)
	open()
		t()
		to(tmp)
		dec()
		to(cond)
		clear()
	close()
	to(tmp)
	open()
		f()
		to(tmp)
		dec()
	close()
end


function truthy(r, a)
	assert(allocated(r))
	assert(allocated(a))

	to(r)
	clear()
	if_then(a, function()
		to(r)
		inc()
	end)
	to(r)
end

function bor(r, a, b)
	assert(allocated(r))
	assert(allocated(a))
	assert(allocated(b))

	to(r)
	clear()
	if_then(a, function()
		to(b)
		inc()
	end)
	truthy(r, b)
end

function band(r, a, b)
	assert(allocated(r))
	assert(allocated(a))
	assert(allocated(b))

	to(r)
	clear()
	to(a)
	if_then(a, function()
		if_then(b, function()
			to(r)
			inc()
		end)
	end)
	to(r)
end

function bnot(r, a)
	assert(allocated(r))
	assert(allocated(a))

	to(r)
    set(1)
	if_then(a, function()
		to(r)
		dec()		
	end)
	to(r)
end

function eq(r, a, b)
	assert(allocated(r))
	assert(allocated(a))
	assert(allocated(b))

	local c, tmp1, tmp2 = alloc(3)

	local function cond()
		copy(tmp1, a) 
		copy(tmp2, b) 
		band(c, tmp1, tmp2)
	end

	cond()
	open()
		to(a)
		dec()
		to(b)
		dec()
		cond()
	close()

	to(a)
	open()
		to(b)
        clear()
		inc()
		to(a)
		clear()
	close()

	truthy(tmp1, b)
	bnot(r, tmp1)

	free(c, tmp1, tmp2)
end

function ne(r, a, b)
	eq(r, a, b)
	copy(a, r) 
	bnot(r, a)	
end

function lt(r, a, b)
	assert(allocated(r))
	assert(allocated(a))
	assert(allocated(b))

	local c, tmp1, tmp2 = alloc(3)

	local function cond()
		copy(tmp1, a) 
		copy(tmp2, b) 
		band(c, tmp1, tmp2)
	end

	cond()
	open()
		to(a)
		dec()
		to(b)
		dec()
		cond()
	close()

	truthy(r, b)

	free(c, tmp1, tmp2)
end

function gt(r, a, b)
	assert(allocated(r))
	assert(allocated(a))
	assert(allocated(b))

	local c, tmp1, tmp2 = alloc(3)

	local function cond()
		copy(tmp1, a) 
		copy(tmp2, b) 
		band(c, tmp1, tmp2)
	end

	cond()
	open()
		to(a)
		dec()
		to(b)
		dec()
		cond()
	close()

	truthy(r, a)

	free(c, tmp1, tmp2)
end

function lte(r, a, b)
	assert(allocated(r))
	assert(allocated(a))
	assert(allocated(b))

	local ta, tb = alloc(2)
	local g, e = alloc(2)

	copy(ta, a) 
	copy(tb, b) 
	lt(g, ta, tb)

	copy(ta, a) 
	copy(tb, b) 
	eq(e, ta, tb)

	bor(r, g, e)

	free(ta, tb, g, e)
end

function gte(r, a, b)
	assert(allocated(r))
	assert(allocated(a))
	assert(allocated(b))

	local ta, tb = alloc(2)
	local g, e = alloc(2)

	copy(ta, a) 
	copy(tb, b) 
	gt(g, ta, tb)

	copy(ta, a)  
	copy(tb, b)  
	eq(e, ta, tb)

	bor(r, g, e)

	free(ta, tb, g, e)
end

function add(r, a)
	assert(allocated(r))
	assert(allocated(a))

	local tmp = alloc()

	copy(tmp, a) 
	open()
		to(r)
		inc()
		to(tmp)
		dec()
	close()
	to(r)
end

function sub(r, a)
	assert(allocated(r))
	assert(allocated(a))

	local tmp = alloc()

	copy(tmp, a) 
	open()
		to(r)
		dec()
		to(tmp)
		dec()
	close()
	to(r)
end

function mul(r, a, b)
	local tmp1, tmp2 = alloc(2)

	copy(tmp1, a) 
	to(a)
	clear()
	to(tmp1)
	open()
		copy(tmp2, b) 
		open()
			to(a)
			inc()
			to(tmp2)
			dec()
		close()
		to(tmp1)
		dec()
	close()
	move(r, a) 

	free(tmp1, tmp2)
end

function divmod(quotient, remainder, a, b)
	assert(allocated(quotient))
	assert(allocated(remainder))
	assert(allocated(a))
	assert(allocated(b))

	local tmp1, tmp2, tmp3 = alloc(3)

	local function cond()
		copy(tmp1, a) 
		copy(tmp2, b) 
		gte(tmp3, tmp1, tmp2)
	end

	to(quotient)
	clear()
	to(remainder)
	clear()

	cond()
	open()
		copy(tmp1, b) 
		open()
			dec()
			to(a)
			dec()
			to(tmp1)
		close()

		to(quotient)
		inc()

		cond()
	close()

	to(a)
	open()
		dec()
		to(remainder)
		inc()
		to(a)
	close()

	free(tmp1, tmp2, tmp3)

	to(quotient)
end

function printCell(a)
	assert(allocated(a))

	local tmp1, tmp2, tmp3, divisor, digit, remainder, tmp5, tmp6 = alloc(8)

	to(tmp1)
	inc(10)
	open()
		dec()
		to(divisor)
		inc(10)
		to(tmp1)
	close()

	copy(tmp2, a) 
	divmod(digit, remainder, tmp2, divisor)
	copy(tmp3, digit) 
	open()
		to(tmp5)
		inc()
		to(tmp3)
		inc(48)
		write()		
		clear()
	close()

	to(divisor)
	clear()
	inc(10)
	copy(tmp2, remainder) 
	divmod(digit, remainder, tmp2, divisor)
	copy(tmp3, digit) 
	bor(tmp6, tmp3, tmp5)
	open()
		copy(tmp3, digit) 
		inc(48)
		write()
		clear()
		to(tmp6)
		clear()
	close()

	to(remainder)
	inc(48)
	write()

	to(divisor)
	write()

	free(tmp1, tmp2, tmp3, divisor, digit, remainder, tmp5, tmp6)

	to(a)
end



local emit = (function()
    local LUT = {
        ["+"] = inc,
        ["-"] = dec,
        [">"] = right,
        ["<"] = left,
        [","] = read,
        ["."] = write,
        ["["] = open,
        ["]"] = close
    }
    return function(s)
        for i = 1, #s do
            local fn = LUT[s:sub(i, i)]
            if fn then fn() end
        end
    end
end)()


Array = class "Array"

function Array:initialize(size)
    -- temp
    -- index
    -- data
    -- index_copy
    self.pointer = alloc_block(size + 4)
end

function Array:set(idx, val)
    assert(allocated(idx))
    assert(allocated(val))

    local index = Ref(self.pointer, 1)
    local data = Ref(self.pointer, 2)
    
    copy(index, idx)
    copy(data, val)

    to(index)
    open()
        dec()
        emit(">>")
        inc()
        emit(">")
        open()
            dec()
            emit("<<<<")
            inc()
            emit(">>>>")
        close()
        emit("<[->+<]")
        emit("<[->+<]")
        emit("<[->+<]")
        emit(">")
    close()
    
    emit(">>>[-]<<")
    emit("[->>+<<]>")

    open()
        dec()
        emit("[-<+>]")
        emit("<<<<[->>>>+<<<<]")
        emit(">>>")
    close()
    emit("<<<")

    at(self.pointer)
end

function Array:get(idx, val)
    assert(allocated(idx))
    assert(allocated(val))

    local index = Ref(self.pointer, 1)
    local data = Ref(self.pointer, 2)
    
    copy(index, idx)

    to(index)
    open()
        dec()
        emit(">>")
        inc()
        emit(">")
        open()
            dec()
            emit("<<<<")
            inc()
            emit(">>>>")
        close()
        emit("<[->+<]")
        emit("<<[->+<]")
        emit(">")
    close()
    
    emit(">>>[-<<+<<+>>>>]")
    emit("<<<<[->>>>+<<<<]")
    emit(">>>")

    open()
        dec()
        emit("<[-<+>]>")
        emit("[-<+>]")
        emit("<<<<[->>>>+<<<<]")
        emit(">>>")
    close()
    emit("<<<")

    at(self.pointer)

    move(val, data)
end





local function dbg(c)
    local t = alloc()
    for i = 1, c:len() do
        to(t) 
        set(string.byte(c:sub(i, i)))
        write()
    end
    free(t)
end


local sp = alloc()
-- local spmax = alloc()
local stack = Array(4)

local function push(x)
	if type(x) == "number" then
		local t = alloc()
		to(t) set(x)
		push(t)
		free(t)
		return
	end

	stack:set(sp, x)
	to(sp)
	inc()

	if spmax then
		local t1, t2, t3 = alloc(3)
		copy(t2, sp)
		copy(t3, spmax)
		gt(t1, t2, t3)
		if_then(t1, function()
			copy(spmax, sp)
		end)
	end

	free(t1, t2, t3)
end

local function pop()
	to(sp) dec()
	local r = alloc()
	stack:get(sp, r)
	to(r)
	return r
end

local function pop2()
	to(sp) dec()
	local t1, r = alloc(2)
	copy(t1, sp)
	stack:get(t1, r)
	free(t1)
	to(r)
	return r
end



-- TODO: move nip (and ip ig?) into gen
-- by making the `a` functions return what
-- to set the nip to.
--              vereena0x13, 12-05-23
local ip, nip = alloc(2)
to(ip) set(1)

-- NOTE TODO: Switch this to binary search?
-- Actually, I just realized that using
-- if_then to implement this rather than
-- if_then_else is actually much less efficient
-- (er, it'll be slower) -- obvious in hindsight.
-- By not using if_then_else, we guarantee that
-- in each iteration of the main loop, we will
-- always compare `ip` to each code fragment index
-- _even after we've already found the correct
-- fragment for this loop iteration_.
-- But anyway; longer-term it would probably make
-- sense to switch to a binary search tree of
-- if_then_else, etc.
-- Unless someone knows a better way that can
-- be implemented in _brainfuck_ (aka. hell).
--              vereena0x13, 6-05-21
local function gen(a)
    local t1, t2, ip2, sr, t3 = alloc(5)
    to(ip)
    open()
        to(sr) set(1)
        for i = 1, #a do
            copy(t3, sr)
            if_then(t3, function()
                to(t1) set(i)
                copy(ip2, ip)
                eq(t2, t1, ip2)
                if_then(t2, function()
                    to(sr) set(0)
                    a[i]()
                end)
            end)
        end
        move(ip, nip)
    close()
    free(t1, t2, ip2, sr, t3)
end

gen({
    function() -- 1
        dbg("IP: 1\n")
        push(2) -- IP: 2
        push(4) -- x
        to(nip) set(3) -- fib(x)
    end,
    function() -- 2
        dbg("IP: 2\n")
        local t = pop()
        dbg("x: ")
        printCell(t)
        to(nip) set(0)
        free(t)
    end,
    function() -- 3
        dbg("IP: 3\n")
        local x = pop()
        local rip = pop()
        local t1, t2 = alloc(2)

        copy(t1, x)
        bnot(t2, t1)
        if_then_else(t2, function()
            -- x == 0; return 0
            push(0)
            move(nip, rip)
        end, function()
            copy(t1, x)
            dec()
            bnot(t2, t1)
            if_then_else(t2, function()
                -- x == 1; return 1
                push(1)
                move(nip, rip)
            end, function()
                -- n > 1; return fib(x - 1) + fib(x - 2)
                push(rip)

                copy(t1, x)
                dec()
                push(t1)

                copy(t1, x)
                dec(2)
                push(t1)

                to(nip) set(4) -- IP: 4
            end)
        end)

        free(x, rip, t1, t2)
    end,
    function() -- 4
        dbg("IP: 4\n")
        local x = pop()
        push(5) -- IP: 5
        push(x)
        to(nip) set(3) -- IP: 3 (fib(x2))
        free(x)
    end,
    function() -- 5
        dbg("IP: 5\n")
        local r = pop()
        local x = pop()
        push(r)
        push(6) -- IP: 6
        push(x)
        to(nip) set(3) -- IP: 3 (fib(x1))
        free(r, x)
    end,
    function() -- 6
        dbg("IP: 6\n")
        local x1 = pop()
        local x2 = pop()
        local rip = pop()

        add(x1, x2)
        push(x1)

        move(nip, rip)

        free(x1, x2, rip)
    end
})


if spmax then
	dbg("\nspmax: ")
	printCell(spmax)
	dbg("\n")
end





--[[
push(1)
push(2)

local t = alloc()
to(t) set(3)
push(t)


local t1 = pop2()
--printCell(t1)

local t2 = pop2()
--printCell(t2)

local t3 = pop2()
--printCell(t3)

free(t, t1, t2, t3)
]]