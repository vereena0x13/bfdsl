Loop = class "Loop"

function Loop:initialize(start, prev)
    self.left = 0
    self.right = 0
    self.start = start
    self.prev = prev
end


CodeGen = class "CodeGen"

function CodeGen:initialize()
    self.buffer = {}
    self.loop = nil
    self.pointer = 0
end


function CodeGen:adjust(n)
    if type(n) ~= "number" then error("expected number, got " .. type(n)) end
    if n ~= math.floor(n) then error("expected integer, got " .. type(n)) end
    
    table.insert(self.buffer, Insn(OpCode.ADJUST, n))
end

function CodeGen:inc(n) self:adjust(math.abs(n or 1)) end
function CodeGen:dec(n) self:adjust(-math.abs(n or 1)) end


function CodeGen:select(n)
    if type(n) ~= "number" then error("expected integer, got " .. type(n)) end
    if n ~= math.floor(n) then error("expected integer, got " .. type(n)) end
    
    self.pointer = self.pointer + n
    if self.loop then
        local dir = n > 0 and "right" or "left"
        self.loop[dir] = self.loop[dir] + math.abs(n)
    end

    table.insert(self.buffer, Insn(OpCode.SELECT, n))
end

function CodeGen:right(n) self:select(math.abs(n or 1)) end
function CodeGen:left(n) self:select(-math.abs(n or 1)) end


function CodeGen:read(n) table.insert(self.buffer, Insn(OpCode.READ, n or 1)) end
function CodeGen:write(n) table.insert(self.buffer, Insn(OpCode.WRITE, n or 1)) end


function CodeGen:open()
    local info = debug.getinfo(3)
    self.loop = Loop(info.short_src .. ":" .. info.currentline, self.loop)

    table.insert(self.buffer, Insn(OpCode.OPEN))
end

function CodeGen:close()
    if self.loop.left ~= self.loop.right then
        -- TODO: allowUnbalanced ??
        local info = debug.getinfo(3)
        error("unbalanced loop: " .. self.loop.start .. " to " .. info.short_src .. ":" .. info.currentline)
    end
    self.loop = self.loop.prev

    table.insert(self.buffer, Insn(OpCode.CLOSE))
end


function CodeGen:set(x)
    if type(x) ~= "number" then error("expected number, got " .. type(x)) end
    table.insert(self.buffer, Insn(OpCode.SET, x))
end

function CodeGen:clear()
    self:set(0)
end