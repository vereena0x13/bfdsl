use clap::{command, Arg};
use mlua::prelude::*;
use std::fs;
use bfdsl::ir;


const MIDDLECLASS_LUA: &str = include_str!("../lib/middleclass/middleclass.lua");
const UTIL_LUA:        &str = include_str!("lua/util.lua");
const IR_LUA:          &str = include_str!("lua/ir.lua");
const CODEGEN_LUA:     &str = include_str!("lua/codegen.lua");
const MAIN_LUA:        &str = include_str!("lua/main.lua");


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


    lua.load(UTIL_LUA).set_name("util.lua").exec().unwrap();
    lua.load(IR_LUA).set_name("ir.lua").exec().unwrap();
    lua.load(CODEGEN_LUA).set_name("codegen.lua").exec().unwrap();


    let base_path = path.parent().unwrap().to_str().unwrap();
    let file_name = path.file_name().unwrap().to_str().unwrap();
    let lua_ir = lua.load(MAIN_LUA).call::<_, LuaTable>((base_path, file_name)).unwrap();
    let ir = ir::from_lua(lua_ir);
    
    print!("{}", ir::to_string(ir));
}