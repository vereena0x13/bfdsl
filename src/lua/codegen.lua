CodeGen = class "CodeGen"

function CodeGen:initialize()
    self.allocator = Allocator()
    self.insns = {}
    self.comments = {}
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

    table.insert(self.insns, Insn(OpCode.ADJUST, n))
end

function CodeGen:inc(n) self:adjust(math.abs(n or 1)) end
function CodeGen:dec(n) self:adjust(-math.abs(n or 1)) end


function CodeGen:select(n)
    assert_is_int(n)
    check_current_block(self)

    self.pointer_offset = self.pointer_offset + n
    if self.pointer_offset < 0 or self.pointer_offset >= self.current_block.size then
        error("pointer (" .. tostring(self.pointer_offset) .. ") is out of bounds of the current block (" .. tostring(self.current_block) .. ")")
    end

    table.insert(self.insns, Insn(OpCode.SELECT, n))
end

function CodeGen:right(n) self:select(math.abs(n or 1)) end
function CodeGen:left(n) self:select(-math.abs(n or 1)) end


function CodeGen:read(n)
    n = n or 1
    assert_is_int(n)
    check_current_block(self)
    table.insert(self.insns, Insn(OpCode.READ, n or 1))
end

function CodeGen:write(n)
    n = n or 1
    assert_is_int(n)
    check_current_block(self)
    table.insert(self.insns, Insn(OpCode.WRITE, n or 1))
end


function CodeGen:open()
    check_current_block(self)
    table.insert(self.insns, Insn(OpCode.OPEN))
end

function CodeGen:close()
    check_current_block(self)
    table.insert(self.insns, Insn(OpCode.CLOSE))
end


function CodeGen:set(x)
    assert_is_int(x)
    table.insert(self.insns, Insn(OpCode.SET, x))
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
    return self.allocator:allocated(...)
end


function CodeGen:to(x)
    assert(self.allocator:allocated(x))

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
    
    table.insert(self.insns, Insn(OpCode.TO, blk.id))

    if x:isInstanceOf(Ref) then
        self:select(x.offset)
    end
end

function CodeGen:at(blk)
    assert(self.allocator:allocated(blk))
    assert(blk:isInstanceOf(Block))
    self.current_block = blk
    self.pointer_offset = 0
end

function CodeGen:comment(s)
    table.insert(self.comments, { #self.insns, s })
end