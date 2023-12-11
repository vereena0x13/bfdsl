use crate::{alloc, ir::*};

pub fn generate_brainfuck(ir: Vec<Insn>, blocks: Vec<Block>) -> String {
    let mut result = String::new();

    let block_locations = alloc::layout_blocks(blocks);
    let mut pointer: i32 = 0;

    for insn in ir {
        match insn {
            Insn::Adjust(n) => {
                if n > 0 {
                    result.push_str("+".repeat(n as usize).as_str());
                } else {
                    result.push_str("-".repeat(n.abs() as usize).as_str());
                }
            },
            Insn::Select(n) => {
                pointer += n;
                if n > 0 {
                    result.push_str(">".repeat(n as usize).as_str());
                } else {
                    result.push_str("<".repeat(n.abs() as usize).as_str());
                }
            },
            Insn::Read(n) => result.push_str(",".repeat(n as usize).as_str()),
            Insn::Write(n) => result.push_str(".".repeat(n as usize).as_str()),
            Insn::Open => result.push('['),
            Insn::Close => result.push(']'),
            Insn::Set(x) => {
                result.push_str("[-]");
                if x != 0 { result.push_str("+".repeat(x as usize).as_str()) }
            },
            Insn::To(blkid) => {
                let blk_loc = block_locations[blkid as usize];
                if blk_loc as i32 > pointer {
                    let delta = blk_loc as i32 - pointer;
                    result.push_str(">".repeat(delta as usize).as_str());
                    pointer += delta;
                } else if (blk_loc as i32) < pointer {
                    let delta = pointer - blk_loc as i32;
                    result.push_str("<".repeat(delta as usize).as_str());
                    pointer -= delta;
                }
            },
        }
    }

    result
}