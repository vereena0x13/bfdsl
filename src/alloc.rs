use crate::ir::*;

pub fn layout_blocks(blocks: &Vec<Block>) -> Vec<u32> {
    let mut result = Vec::new();
    let mut index = 0;
    for block in blocks {
        result.push(index);
        index += block.size;
    }
    result
}