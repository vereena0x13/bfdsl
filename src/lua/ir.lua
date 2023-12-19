OpCode = {
    ADJUST  = 0,
    SELECT  = 1,
    READ    = 2,
    WRITE   = 3,
    OPEN    = 4,
    CLOSE   = 5,
    SET     = 6,
    TO      = 7,
    COMMENT = 8,
}



Insn = class "Insn"

function Insn:initialize(opcode, operand)
    self.opcode = opcode
    self.operand = operand
    self.level = 0
end