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