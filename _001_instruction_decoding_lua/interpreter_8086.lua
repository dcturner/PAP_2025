_8086 = {}

function _8086:parse(byte_a, byte_b)
    local cmd = {
        -- A
        op_code = string.sub(byte_a, 1, 6),
        d = string.sub(byte_a, 7, 7),
        w = string.sub(byte_a, 8, 8),

        -- B
        mod = string.sub(byte_b, 1, 2),
        reg = string.sub(byte_b, 3, 5),
        r_m = string.sub(byte_b, 6, 8)
    }

    -- 100010   OP_CODE
    -- 0        D
    -- 1        W
    -- 11       MOD
    -- 011      REG
    -- 001      R_M

    print("PARSING... a: " .. byte_a .. ", b: " .. byte_b)
    local str_op_code = "" .. _8086:opcode(cmd.op_code) .. " "
    local str_op_a = _8086.MOD_LOOKUP[cmd.mod][cmd.r_m][cmd.w + 1]
    local str_op_b = _8086.MOD_LOOKUP[cmd.mod][cmd.reg][cmd.w + 1]
    return str_op_code .. str_op_a .. ", " .. str_op_b
end

_8086.OP_CODE = {
    ["100010"] = "mov",
    ["101011"] = "shite",
    ["0110"] = "arse",
}
function _8086:opcode(input)
    return _8086.OP_CODE[input]
end

_8086.REG_ENCODING_MOD_11 = {
    ["000"] = { "al", "ax" },
    ["001"] = { "cl", "cx" },
    ["010"] = { "dl", "dx" },
    ["011"] = { "bl", "bx" },
    ["100"] = { "ah", "sp" },
    ["101"] = { "ch", "bp" },
    ["110"] = { "dh", "si" },
    ["111"] = { "bh", "di" },
}
_8086.REG_ENCODING_MOD_00 = {
    ["000"] = "(bx) + (si)",
    ["001"] = "(bx) + (di)",
    ["010"] = "(bp) + (si)",
    ["011"] = "(bp) + (di)",
    ["100"] = "(si)",
    ["101"] = "(di)",
    ["110"] = "direct address",
    ["111"] = "(bx)",
}
_8086.MOD_LOOKUP = {
    ["00"] = _8086.REG_ENCODING_MOD_00,
    ["11"] = _8086.REG_ENCODING_MOD_11,
}
