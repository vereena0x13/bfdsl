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


    let lua = Lua::new();
    let globals = lua.globals();

    lua.load(code).exec().unwrap();
}