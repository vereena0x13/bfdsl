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
    Set(u32),
    To(u32),
    Comment(String)
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
            Insn::Set(n)    => write!(f, "set {}", n),
            Insn::To(blkid) => write!(f, "to <{}>", blkid),
            Insn::Comment(s) => write!(f, "{}", s),
        }
    }    
}

pub fn insns_from_lua(lua_ir: LuaTable) -> Vec<Insn> {
    let mut result = Vec::new();

    for lua_insn in lua_ir.sequence_values::<LuaTable>() {
        let lua_insn = lua_insn.unwrap();
        let opcode = lua_insn.get::<_, u32>("opcode").unwrap();
        
        let insn = match opcode {
            0 => Insn::Adjust(lua_insn.get::<_, i32>("operand").unwrap()),
            1 => Insn::Select(lua_insn.get::<_, i32>("operand").unwrap()),
            2 => Insn::Read(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            3 => Insn::Write(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            4 => Insn::Open,
            5 => Insn::Close,
            6 => Insn::Set(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            7 => Insn::To(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            8 => Insn::Comment(lua_insn.get::<_, String>("operand").unwrap()),
            _ => panic!()
        };

        result.push(insn);
    }

    result
}

pub fn insns_to_string(ir: &Vec<Insn>) -> String {
    let mut result = String::new();
    let mut level = 0;
    for insn in ir {
        if let Insn::Close = insn { level -= 1 }
        result.push_str("    ".repeat(level).as_str());
        if let Insn::Open = insn { level += 1 }
        result.push_str(insn.to_string().as_str());
        result.push('\n');
    }
    result
}



#[derive(Debug, Clone, PartialEq)]
pub struct Block {
    pub id: u32,
    pub size: u32,
    pub uses: Vec<u32>,
}

pub fn blocks_from_lua(lua_blocks: LuaTable) -> Vec<Block> {
    let mut result = Vec::new();

    for lua_block in lua_blocks.sequence_values::<LuaTable>() {
        let lua_block = lua_block.unwrap();
        let id = lua_block.get::<_, u32>("id").unwrap();
        let size = lua_block.get::<_, u32>("size").unwrap();
        let uses = Vec::<u32>::new(); // TODO
        result.push(Block { id, size, uses });
    }

    result
}