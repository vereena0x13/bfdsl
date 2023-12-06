CodeGen = class "CodeGen"

function CodeGen:initialize()
    self.buffer = {}
end

function CodeGen:adjust(n)
    if type(n) ~= "number" then error("expected number, got " .. type(n)) end
    table.insert(self.buffer, Insn(OpCode.ADJUST, n))
end

function CodeGen:select(n)
    if type(n) ~= "number" then error("expected number, got " .. type(n)) end
    table.insert(self.buffer, Insn(OpCode.SELECT, n))
end

function CodeGen:inc(n) self:adjust(math.abs(n or 1)) end
function CodeGen:dec(n) self:adjust(-math.abs(n or 1)) end

function CodeGen:right(n) self:select(math.abs(n or 1)) end
function CodeGen:left(n) self:select(-math.abs(n or 1)) end

function CodeGen:read(n) table.insert(self.buffer, Insn(OpCode.READ, n or 1)) end
function CodeGen:write(n) table.insert(self.buffer, Insn(OpCode.WRITE, n or 1)) end

function CodeGen:open()
    table.insert(self.buffer, Insn(OpCode.OPEN))
end

function CodeGen:close()
    table.insert(self.buffer, Insn(OpCode.CLOSE))
end

function CodeGen:set(x)
    if type(x) ~= "number" then error("expected number, got " .. type(x)) end
    table.insert(self.buffer, Insn(OpCode.SET, x))
end

function CodeGen:clear()
    self:set(0)
end