use clap::{command, Arg};
use mlua::prelude::*;
use std::fs;
use bfdsl::{ir::*, codegen};


const MIDDLECLASS_LUA: &str = include_str!("../lib/middleclass/middleclass.lua");
const MAIN_LUA:        &str = include_str!("lua/main.lua");


macro_rules! include_lua {
    ( $lua:expr, $($name:literal),* ) => {
        $(
            $lua.load(include_str!(concat!("lua/", $name))).set_name($name).exec().unwrap();
        )*
    }
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


    let bf = codegen::generate_brainfuck(ir, blocks);
    fs::write(&format!("{}.bf", file_name), bf).unwrap();
}