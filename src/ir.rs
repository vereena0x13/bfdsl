use std::fmt;

use mlua::prelude::LuaTable;



#[derive(Debug, Clone, PartialEq)]
pub struct Insn {
    pub variant: InsnVariant,
    pub level: u32,
}



#[derive(Debug, Clone, PartialEq)]
pub enum InsnVariant {
    Adjust(i32),
    Select(i32),
    Read(u32),
    Write(u32),
    Open,
    Close,
    Set(u32),
    To(u32),
}

impl fmt::Display for InsnVariant {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            InsnVariant::Adjust(n) => write!(f, "adjust {}", n),
            InsnVariant::Select(n) => write!(f, "select {}", n),
            InsnVariant::Read(n)   => write!(f, "read {}", n),
            InsnVariant::Write(n)  => write!(f, "write {}", n),
            InsnVariant::Open      => write!(f, "open"),
            InsnVariant::Close     => write!(f, "close"),
            InsnVariant::Set(n)    => write!(f, "set {}", n),
            InsnVariant::To(blkid) => write!(f, "to <{}>", blkid),
        }
    }    
}

pub fn insns_from_lua(lua_ir: LuaTable) -> Vec<Insn> {
    let mut result = Vec::new();

    for lua_insn in lua_ir.sequence_values::<LuaTable>() {
        let lua_insn = lua_insn.unwrap();
        let opcode = lua_insn.get::<_, u32>("opcode").unwrap();
        let level = lua_insn.get::<_, u32>("level").unwrap();
        
        let insn_variant = match opcode {
            0 => InsnVariant::Adjust(lua_insn.get::<_, i32>("operand").unwrap()),
            1 => InsnVariant::Select(lua_insn.get::<_, i32>("operand").unwrap()),
            2 => InsnVariant::Read(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            3 => InsnVariant::Write(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            4 => InsnVariant::Open,
            5 => InsnVariant::Close,
            6 => InsnVariant::Set(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            7 => InsnVariant::To(lua_insn.get::<_, i32>("operand").unwrap() as u32),
            _ => panic!()
        };

        result.push(Insn { variant: insn_variant, level });
    }

    result
}


#[derive(Debug, Clone, PartialEq)]
pub struct Block {
    pub id: u32,
    pub size: u32,
    pub uses: Vec<u32>,
}

impl fmt::Display for Block {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "Block({}, {})", self.id, self.size)
    }    
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



#[derive(Debug, Clone, PartialEq)]
pub struct Comment {
    pub insn_index: u32,
    pub comment: String,
}

pub fn comments_from_lua(lua_comments: LuaTable) -> Vec<Comment> {
    let mut result = Vec::new();

    for lua_comment in lua_comments.sequence_values::<LuaTable>() {
        let lua_comment = lua_comment.unwrap();
        let index = lua_comment.get::<_, u32>(1).unwrap();
        let comment = lua_comment.get::<_, String>(2).unwrap();
        result.push(Comment { insn_index: index, comment });
    }

    result
}



#[derive(Debug, Clone, PartialEq)]
pub struct IR {
    pub insns: Vec<Insn>,
    pub blocks: Vec<Block>,
    pub comments: Vec<Comment>,
}

pub fn ir_from_lua(lua_ir: LuaTable) -> IR {
    let lua_insns = lua_ir.get::<_, LuaTable>("insns").unwrap();
    let lua_blocks = lua_ir.get::<_, LuaTable>("blocks").unwrap();
    let lua_comments = lua_ir.get::<_, LuaTable>("comments").unwrap();
    IR {
        insns: insns_from_lua(lua_insns),
        blocks: blocks_from_lua(lua_blocks),
        comments: comments_from_lua(lua_comments)
    }
}


pub fn ir_to_string(ir: &IR) -> String {
    let mut result = String::new();

    result.push_str("blocks:\n");
    for block in &ir.blocks {
        result.push_str(format!("{}\n", block).as_str());
    }

    result.push_str("\ninsns:\n");

    let mut level = 0;
    let mut comment_index = 0;
    for (i, insn) in ir.insns.iter().enumerate() {
        if let InsnVariant::Close = insn.variant { level -= 1 }
        result.push_str("    ".repeat(level).as_str());
        if let InsnVariant::Open = insn.variant { level += 1 }

        if ir.comments.len() > 0 && comment_index < ir.comments.len() {
            let comment = &ir.comments[comment_index];
            if i == comment.insn_index as usize {
                comment_index += 1;
                result.push('/');
                result.push('/');
                result.push(' ');
                result.push_str(comment.comment.as_str());
                result.push('\n');

                result.push_str("    ".repeat(if let InsnVariant::Open = insn.variant { level - 1 } else { level }).as_str());
            }
        }

        result.push_str(insn.variant.to_string().as_str());
        result.push('\n');
    }

    result
}