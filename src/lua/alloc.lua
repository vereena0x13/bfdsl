Block = class "Block"

function Block:initialize(size)
    self.size = size
    self.uses = {}
    self.active_index = -1
end

function Block:__tostring()
    return "Block(" .. tostring(self.size) .. ")"
end



Allocator = class "Allocator"

function Allocator:initialize()
    self.free_blocks = {}
    self.active_blocks = {}
end

local function get_blocks(blklist, size)
    if blklist[size] then return blklist[size] end
    local blocks = {}
    blklist[size] = blocks
    return blocks
end

local function corrupt_block_error(blk, active)
    error("corrupt block: " .. tostring(blk.active_index) .. "; " .. tostring(blk) .. " != " .. tostring(active[blk.active_index]))
end

function Allocator:alloc(n)
    local free = get_blocks(self.free_blocks, n)

    local block
    if #free > 0 then
        block = table.remove(free)
    else
        block = Block(n)
    end

    local active = get_blocks(self.active_blocks, n)
    table.insert(active, block)
    block.active_index = #active

    return block
end

function Allocator:free(blk)
    local active = get_blocks(self.active_blocks, blk.size)
    
    if active[blk.active_index] ~= blk then
        corrupt_block_error(blk, active)
    end

    assert(table.remove(active, blk.active_index) == blk)

    local free = get_blocks(self.free_blocks, blk.size)
    table.insert(free, blk)

    blk.active_index = -1
end

function Allocator:is_allocated(blk)
    if blk.active_index == -1 then return false end

    local active = get_blocks(self.active_blocks, blk.size)
    if active[blk.active_index] ~= blk then
        corrupt_block_error(blk, active)
    end

    return true
end