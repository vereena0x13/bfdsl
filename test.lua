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


