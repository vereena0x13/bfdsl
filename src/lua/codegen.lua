CodeGen = class "CodeGen"

function CodeGen:initialize()
    self.allocator = Allocator()
    self.buffer = {}
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

    self:comment("adjust " .. tostring(n))
    table.insert(self.buffer, Insn(OpCode.ADJUST, n))
end

function CodeGen:inc(n) self:adjust(math.abs(n or 1)) end
function CodeGen:dec(n) self:adjust(-math.abs(n or 1)) end


function CodeGen:select(n)
    assert_is_int(n)
    check_current_block(self)

    self.pointer_offset = self.pointer_offset + n
    if self.pointer_offset < 0 or self.pointer_offset >= self.current_block.size then
        error("out of bounds of current block (" .. tostring(self.current_block) .. ")")
    end

    self:comment("select " .. tostring(n))
    table.insert(self.buffer, Insn(OpCode.SELECT, n))
end

function CodeGen:right(n) self:select(math.abs(n or 1)) end
function CodeGen:left(n) self:select(-math.abs(n or 1)) end


function CodeGen:read(n)
    assert_is_int(n)
    check_current_block(self)
    table.insert(self.buffer, Insn(OpCode.READ, n or 1))
end

function CodeGen:write(n)
    assert_is_int(n)
    check_current_block(self)
    table.insert(self.buffer, Insn(OpCode.WRITE, n or 1))
end


function CodeGen:open()
    check_current_block(self)
    self:comment "open"
    table.insert(self.buffer, Insn(OpCode.OPEN))
end

function CodeGen:close()
    check_current_block(self)
    self:comment "close"
    table.insert(self.buffer, Insn(OpCode.CLOSE))
end


function CodeGen:set(x)
    assert_is_int(x)
    self:comment("set " .. tostring(x))
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

function CodeGen:alloc_block(...)
    local xs = {}
    for _, v in ipairs({...}) do
        xs[#xs+1] = self.allocator:alloc(v)
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


function CodeGen:to(x)
    assert(self.allocator:is_allocated(x))
    self:comment("to " .. tostring(x))

    local blk, offset
    if x:isInstanceOf(Ref) then
        blk = x.block
        offset = x.offset
    elseif x:isInstanceOf(Block) then
        blk = x
        offset = 0
    else
        error()
    end

    self.current_block = blk
    self.pointer_offset = offset
    
    table.insert(self.buffer, Insn(OpCode.TO, blk.id))

    if x:isInstanceOf(Ref) then
        self:select(x.offset)
    end
end

function CodeGen:at(x)
    assert(self.allocator:is_allocated(x))
    self:comment("at " .. tostring(x))

    local blk, offset = x, 0
    if blk:isInstanceOf(Ref) then
        blk = blk.block
        offset = x.offset
    end

    self.current_block = blk
    self.pointer_offset = offset
end


function CodeGen:comment(s)
    table.insert(self.buffer, Insn(OpCode.COMMENT, s))
end