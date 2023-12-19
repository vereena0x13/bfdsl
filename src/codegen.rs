use crate::{alloc, ir::*};

pub fn generate_brainfuck(ir: &IR) -> String {
    let mut result = String::new();

    let block_locations = alloc::layout_blocks(&ir.blocks);
    let mut pointer: i32 = 0;

    for insn in &ir.insns {
        match &insn.variant {
            InsnVariant::Adjust(n) => {
                if *n > 0 {
                    result.push_str("+".repeat(*n as usize).as_str());
                } else {
                    result.push_str("-".repeat(n.abs() as usize).as_str());
                }
            },
            InsnVariant::Select(n) => {
                pointer += n;
                if *n > 0 {
                    result.push_str(">".repeat(*n as usize).as_str());
                } else {
                    result.push_str("<".repeat(n.abs() as usize).as_str());
                }
            },
            InsnVariant::Read(n) => result.push_str(",".repeat(*n as usize).as_str()),
            InsnVariant::Write(n) => result.push_str(".".repeat(*n as usize).as_str()),
            InsnVariant::Open => result.push('['),
            InsnVariant::Close => result.push(']'),
            InsnVariant::Set(x) => {
                result.push_str("[-]");
                if *x != 0 { result.push_str("+".repeat(*x as usize).as_str()) }
            },
            InsnVariant::To(blkid) => {
                let blk_loc = block_locations[*blkid as usize];
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