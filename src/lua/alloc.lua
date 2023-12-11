Block = class "Block"

function Block:initialize(id, size)
    self.id = id
    self.size = size
    self.uses = {}
end

function Block:ref(i)
    return Ref(self, i)
end

function Block:__tostring()
    return "Block(" .. tostring(self.id) .. ", " .. tostring(self.size) .. ")"
end




Ref = class "Ref"

function Ref:initialize(blk, offset)
    offset = offset or 0
    assert_is_int(offset)
    self.block = blk
    self.offset = offset
    assert(offset >= 0)
    assert(offset < blk.size)
end

function Ref:ref(i)
    return Ref(self.block, self.offset + i)
end

function Ref:__tostring()
    return "Ref(" .. tostring(self.block.id) ..  ", " .. tostring(self.offset) ..  ")"
end




Allocator = class "Allocator"

function Allocator:initialize()
    self.blocks = {}
    self.free_blocks = {}
    self.active_blocks = {}
end

local function get_blocks(blklist, size)
    if blklist[size] then return blklist[size] end
    local blocks = {}
    blklist[size] = blocks
    return blocks
end

local function find_block(blklist, blk) -- TODO: don't use linear search
    for i, v in ipairs(blklist) do
        if v == blk then return i end
    end
    return -1
end

function Allocator:alloc(n)
    local free = get_blocks(self.free_blocks, n)

    local block
    if #free > 0 then
        block = table.remove(free)
    else
        local id = #self.blocks
        block = Block(id, n)
        table.insert(self.blocks, block)
    end

    local active = get_blocks(self.active_blocks, n)
    table.insert(active, block)

    return block
end

function Allocator:free(blk)
    local active = get_blocks(self.active_blocks, blk.size)
    local index = find_block(active, blk)

    assert(index ~= -1) -- TODO

    assert(table.remove(active, index) == blk)

    local free = get_blocks(self.free_blocks, blk.size)
    table.insert(free, blk)
end

function Allocator:allocated(blk)
    if blk:isInstanceOf(Ref) then blk = blk.block end
    local active = get_blocks(self.active_blocks, blk.size)
    local index = find_block(active, blk)
    return index ~= -1
end