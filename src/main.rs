use clap::{command, Arg};
use mlua::prelude::*;
use std::{fs, process};

fn main() {
    let matches = command!()
        .arg(Arg::new("file").required(true))
        .get_matches();


    let file = matches.get_one::<String>("file").unwrap();
    let code = match fs::read_to_string(file) {
        Ok(code) => code,
        Err(_) => {
            println!("Unable to read file `{file}`");
            process::exit(1)
        }
    };


    let lua = unsafe { Lua::unsafe_new_with(LuaStdLib::ALL, LuaOptions::new()) }; // NOTE: unsafe :( but we use the debug module, so alas.
    let globals = lua.globals();

    
    let middleclass = lua.load(include_str!("../lib/middleclass/middleclass.lua")).eval::<LuaTable>().unwrap();
    globals.set("class", middleclass).unwrap();


    lua.load(include_str!("../lib/init.lua")).exec().unwrap();

    lua.load(code).exec().unwrap();
}