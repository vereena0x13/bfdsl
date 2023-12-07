use clap::{command, Arg};
use mlua::prelude::*;
use std::fs;
use bfdsl::ir::*;


const MIDDLECLASS_LUA: &str = include_str!("../lib/middleclass/middleclass.lua");
const MAIN_LUA:        &str = include_str!("lua/main.lua");


macro_rules! include_lua {
    ( $lua:expr, $($name:literal),* ) => {
        $(
            $lua.load(include_str!(concat!("lua/", $name))).set_name($name).exec().unwrap();
        )*
    }
}


fn layout_blocks(blocks: Vec<Block>) -> Vec<u32> {
    let mut result = Vec::new();
    let mut index = 0;
    for block in blocks {
        result.push(index);
        index += block.size;
    }
    result
}

fn generate_brainfuck(ir: Vec<Insn>, blocks: Vec<Block>) -> String {
    let mut result = String::new();

    let block_locations = layout_blocks(blocks);
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


fn main() {
    let matches = command!()
        .arg(Arg::new("file").required(true))
        .get_matches();


    let file = matches.get_one::<String>("file").unwrap();
    let path = fs::canonicalize(file).unwrap();


    let lua = unsafe { Lua::unsafe_new_with(LuaStdLib::ALL, LuaOptions::new()) };
    let globals = lua.globals();

    
    let middleclass = lua.load(MIDDLECLASS_LUA).eval::<LuaTable>().unwrap();
    globals.set("class", middleclass).unwrap();


    include_lua!(
        lua,
        "util.lua",
        "ir.lua",
        "alloc.lua",
        "codegen.lua"
    );


    let base_path = path.parent().unwrap().to_str().unwrap();
    let file_name = path.file_name().unwrap().to_str().unwrap();
    let (lua_ir, lua_blocks) = lua.load(MAIN_LUA).call::<_, (LuaTable, LuaTable)>((base_path, file_name)).unwrap();
    let ir = insns_from_lua(lua_ir);
    let blocks = blocks_from_lua(lua_blocks);

    //println!("{}", insns_to_string(&ir));
    //println!("{:?}", blocks);


    let bf = generate_brainfuck(ir, blocks);
    fs::write(&format!("{}.bf", file_name), bf).unwrap();
}