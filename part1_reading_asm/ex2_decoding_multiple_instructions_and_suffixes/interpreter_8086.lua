_8086 = {}

--[[
TASKS

- when encountering a new instruction, ask _8086 how many bits to use (CMD_SIZE)
- march through the data until you reach the end

--]]

function _8086:parse_to_asm(file_url, file_name)

    -- load file and get number of commands
    local file_handle = assert(io.open(file_url, 'rb'), "Failed to open file: " .. file_url)
    local file_data = file_handle:read("*all")
    print("PARSE ASM FILE: '" .. file_name .. "' ...")

    -- move through the buffer and identify new commands in chunks
    _8086.buffer_current_byte = 1
    _8086.cmd_counter = 1
    local cmd_config = _8086:get_cmd_config(string.byte(file_data))
    
    -- ID cmd and check how many bytes this op will need


    -- loop on through the buffer here


    -- local cmd_list = {}
    -- for i = 1, cmd_count do
    --     local index = (i * 2) - 1
    --     local cmd_byte_1 = _8086:to_binary(string.byte(file_data, index, index))
    --     local op_code_length = _8086:get_op_code_size(cmd_byte_1)
    --     local cmd_config = _8086:get_op_code_config(cmd_byte_1)
    --     print("CMD_" .. i .. ": " .. op_code_length)
    --     local cmd = {
    --         -- isolate the a//b bytes for this instruction and hand them to the interpreter
    --         table.insert(cmd_list, _8086:parse(
    --             _8086:to_binary(string.byte(file_data, index, index)),
    --             _8086:to_binary(string.byte(file_data, index + 1, index + 1))
    --         ))
    --     }
    -- end
    -- local asm_string = "bits 16\n\n"
    -- for i = 1, #cmd_list do
    --     asm_string = asm_string .. cmd_list[i] .. "\n"
    -- end
    -- _8086:write_asm(asm_string, file_name)
end

function _8086:parse(byte_a, byte_b)
    -- local cmd = {
    --     -- A
    --     op_code = string.sub(byte_a, 1, 6),
    --     d = string.sub(byte_a, 7, 7),
    --     w = string.sub(byte_a, 8, 8),

    --     -- B
    --     mod = string.sub(byte_b, 1, 2),
    --     reg = string.sub(byte_b, 3, 5),
    --     r_m = string.sub(byte_b, 6, 8)
    -- }

    -- -- Parse the 3 separate parts and concat them into an asm instruction line
    -- local str_op_code = "" .. _8086:get_op_code_config(cmd.op_code).asm_cmd
    -- local str_op_a = _8086.MOD_LOOKUP[cmd.mod][cmd.r_m][cmd.w + 1]
    -- local str_op_b = _8086.MOD_LOOKUP[cmd.mod][cmd.reg][cmd.w + 1]
    -- return str_op_code .. " " .. str_op_a .. ", " .. str_op_b
end

function _8086:get_op_code_config(input)
    assert(_8086.OP_CODE[input] ~= nil, "\n\n(!) No parser found for instruction: " .. input .. " (!)\n\n")
    local op_config = _8086:get_op_config_from_prefix(input)
    return _8086.OP_CODE[input]
end

function _8086:write_asm(file_name, asm_string)
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

function _8086:to_binary(number)
    local remainder = ""
    while number > 0 do
        remainder = tostring(number % 2) .. remainder
        number = math.floor(number / 2)
    end
    return remainder
end

-- Identify what type of command we are parsing. Return an OP_CONFIG if a match is found
function _8086:get_cmd_config(input)
    local i2b = _8086:to_binary(input) -- input to binary

    for key, value in pairs(_8086.OP_CODE) do
        local test_chunk = string.sub(i2b, 1, #key)
        if (test_chunk == key) then
            print("CMD[" .. _8086.cmd_counter .. "] --> " .. test_chunk .. " = " .. value.id)
            return value
        end
    end

    -- Fail gracefully
    assert(false, "no OP_CODE found with sig matching: " .. i2b)
    return nil
end

function _8086:parse_mov_REG_2_REG(input)
    print("PARSING REG_2_REG")
end
-- function _8086:get_cmd_bytes_required(intpu)

--//////////////////////////////////////////////
-- DEFINITIONS
--//////////////////////////////////////////////
_8086.OP_CODE = {
    ["100010"] =    { asm_type = "mov", parser = _8086.parse_mov_REG_2_REG, id = "MOV REG_2_REG"},
    ["1100011"] =   { asm_type = "mov", id = "MOV IMM_2_RM"},
    ["1011"] =      { asm_type = "mov", id = "MOV IMM 2 REG"},
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
