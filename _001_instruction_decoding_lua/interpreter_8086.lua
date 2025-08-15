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

    -- Parse the 3 separate parts and concat them into an asm instruction line
    local str_op_code = "" .. _8086.OP_CODE[cmd.op_code]
    local str_op_a = _8086.MOD_LOOKUP[cmd.mod][cmd.r_m][cmd.w + 1]
    local str_op_b = _8086.MOD_LOOKUP[cmd.mod][cmd.reg][cmd.w + 1]
    return str_op_code .. " " .. str_op_a .. ", " .. str_op_b
end

function _8086:get_op_code(input)
    return _8086.OP_CODE[input]
end

function _8086:parse_to_asm(file_url, file_name)
    local file_handle = assert(io.open(file_url, 'rb'))
    local file_data = file_handle:read("*all")
    local cmd_count = math.floor(#file_data / 2)
    local cmd_list = {}
    for i = 1, cmd_count do
        local index = (i * 2) - 1
        local cmd = {
            -- isolate the a//b bytes for this instruction and hand them to the interpreter
            table.insert(cmd_list, _8086:parse(
                to_binary(string.byte(file_data, index, index)),
                to_binary(string.byte(file_data, index + 1, index + 1))
            ))
        }
    end
    local asm_string = "bits 16\n\n"
    for i = 1, #cmd_list do
        -- print("(" .. i .. ") --> " .. cmd_list[i])
        asm_string = asm_string .. cmd_list[i] .. "\n"
    end
    
    -- "open a new file ion write mode (w)"
    local file_url = "output/" .. file_name .. ".asm"
    local new_file = io.open(file_url, "w")
    if (new_file) then
        new_file:write(asm_string)
        new_file:close();
    end

    print("COMPILED ASM TO: " .. file_url)
    print("data: " .. asm_string)
end

--//////////////////////////////////////////////
-- DEFINITIONS
--//////////////////////////////////////////////
_8086.OP_CODE = {
    ["100010"] = "mov",
    ["101011"] = "shite",
    ["0110"] = "arse",
}
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
