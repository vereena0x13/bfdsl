Loop = class "Loop"

function Loop:initialize(start, prev)
    self.offset = 0
    self.start = start
    self.prev = prev
end



CodeGen = class "CodeGen"

function CodeGen:initialize()
    self.allocator = Allocator()
    self.buffer = {}
    self.loop = nil
    self.current_block = nil
    self.pointer_offset = 0
end


local function check_current_block(self)
    if not self.current_block then
        error("no block selected; call `to(blk)` first")
    end
end


function CodeGen:adjust(n)
    assert_is_int(n)
    check_current_block(self)
    table.insert(self.buffer, Insn(OpCode.ADJUST, n))
end

function CodeGen:inc(n) self:adjust(math.abs(n or 1)) end
function CodeGen:dec(n) self:adjust(-math.abs(n or 1)) end


function CodeGen:select(n)
    assert_is_int(n)
    check_current_block(self)
    if self.loop then self.loop.offset = self.loop.offset + n end
    table.insert(self.buffer, Insn(OpCode.SELECT, n))
end

function CodeGen:right(n) self:select(math.abs(n or 1)) end
function CodeGen:left(n) self:select(-math.abs(n or 1)) end


function CodeGen:read(n)
    check_current_block(self)
    table.insert(self.buffer, Insn(OpCode.READ, n or 1))
end

function CodeGen:write(n)
    check_current_block(self)
    table.insert(self.buffer, Insn(OpCode.WRITE, n or 1))
end


function CodeGen:open()
    check_current_block(self)

    local info = debug.getinfo(3)
    self.loop = Loop(info.short_src .. ":" .. info.currentline, self.loop)

    table.insert(self.buffer, Insn(OpCode.OPEN))
end

function CodeGen:close()
    check_current_block(self) -- ??

    if self.loop.offset ~= 0 then
        -- TODO: allow_unbalanced
        local info = debug.getinfo(3)
        error("unbalanced loop: " .. self.loop.start .. " to " .. info.short_src .. ":" .. info.currentline)
    end
    self.loop = self.loop.prev

    table.insert(self.buffer, Insn(OpCode.CLOSE))
end


function CodeGen:set(x)
    assert_is_int(x)
    check_current_block(self)
    table.insert(self.buffer, Insn(OpCode.SET, x))
end

function CodeGen:clear()
    self:set(0)
end



function CodeGen:alloc(n)
    n = n or 1
    local xs = {}
    for i = 1, n do
        xs[#xs+1] = self.allocator:alloc(1)
    end
    return unpack(xs)
end

function CodeGen:free(...)
    for _, blk in ipairs({...}) do
        self.allocator:free(blk)
    end
end

function CodeGen:allocated(...)
    return self.allocator:is_allocated(...)
end


function CodeGen:to(blk)
    assert(self.allocator:is_allocated(blk))
    
    self.current_block = blk
    self.pointer_offset = 0
    
    table.insert(self.buffer, Insn(OpCode.TO, blk.id))
end