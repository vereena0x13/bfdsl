CodeGen = class "CodeGen"

function CodeGen:initialize()
    self.allocator = Allocator()
    self.insns = {}
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
    table.insert(self.current_block.uses, #self.insns)
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
    table.insert(self.current_block.uses, #self.insns)
end

function CodeGen:write(n)
    n = n or 1
    assert_is_int(n)
    check_current_block(self)
    table.insert(self.insns, Insn(OpCode.WRITE, n or 1))
    table.insert(self.current_block.uses, #self.insns)
end


function CodeGen:open()
    check_current_block(self)
    table.insert(self.insns, Insn(OpCode.OPEN))
    table.insert(self.current_block.uses, #self.insns)
end

function CodeGen:close()
    check_current_block(self)
    table.insert(self.insns, Insn(OpCode.CLOSE))
    table.insert(self.current_block.uses, #self.insns)
end


function CodeGen:set(x)
    check_current_block(self)
    assert_is_int(x)
    table.insert(self.insns, Insn(OpCode.SET, x))
    table.insert(self.current_block.uses, #self.insns)
end

function CodeGen:clear()
    self:set(0)
end


function CodeGen:alloc(n)
    n = n or 1
    local xs = {}
    for i = 1, n do
        local x = self.allocator:alloc(1)
        self:to(x) self:set(0)
        xs[#xs+1] = x
    end
    return unpack(xs)
end

function CodeGen:alloc_block(...)
    local xs = {}
    for _, v in ipairs({...}) do
        local x = self.allocator:alloc(v)
        for i = 0, v - 1 do
            self:to(x:ref(i)) self:set(0)
        end
        xs[#xs+1] = x
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

    local blk
    if x:isInstanceOf(Ref) then
        blk = x.block
    elseif x:isInstanceOf(Block) then
        blk = x
    else
        error("expected Block or Ref, got " .. tostring(x))
    end

    self.current_block = blk
    self.pointer_offset = 0
    
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