use std::fmt;

use mlua::prelude::LuaTable;

#[derive(Debug, Clone, PartialEq)]
pub enum Insn {
    Adjust(i32),
    Select(i32),
    Read(u32),
    Write(u32),
    Open,
    Close,
    Set(u32)
}

impl fmt::Display for Insn {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Insn::Adjust(n) => write!(f, "adjust {}", n),
            Insn::Select(n) => write!(f, "select {}", n),
            Insn::Read(n)   => write!(f, "read {}", n),
            Insn::Write(n)  => write!(f, "write {}", n),
            Insn::Open      => write!(f, "open"),
            Insn::Close     => write!(f, "close"),
            Insn::Set(n)    => write!(f, "set {}", n)
        }
    }    
}

pub fn from_lua(lua_ir: LuaTable) -> Vec<Insn> {
    let mut result = Vec::new();

    for i in 1..(lua_ir.len().unwrap() + 1) {
        let lua_insn = lua_ir.get::<_, LuaTable>(i).unwrap();
        let opcode = lua_insn.get::<_, u32>("opcode").unwrap();
        
        let insn = match opcode {
            0 => Insn::Adjust(lua_insn.get::<_, i32>("operand").unwrap()),
            1 => Insn::Select(lua_insn.get::<_, i32>("operand").unwrap()),
            2 => Insn::Read(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            3 => Insn::Write(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            4 => Insn::Open,
            5 => Insn::Close,
            6 => Insn::Set(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            _ => panic!()
        };

        result.push(insn);
    }

    result
}

// TODO: clean this up
pub fn print(ir: Vec<Insn>) {
    let mut level = 0;
    for insn in ir {
        match insn {
            Insn::Open => {
                print!("{}", "    ".repeat(level));
                println!("{}", insn);
                level += 1;
            },
            Insn::Close => {
                level -= 1;
                print!("{}", "    ".repeat(level));
                println!("{}", insn);
            },
            _ => {
                print!("{}", "    ".repeat(level));
                println!("{}", insn);
            }
        }
    }
}