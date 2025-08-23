_8086 = {}

--[[
TASKS

- when encountering a new instruction, ask _8086 how many bits to use (CMD_SIZE)
- march through the data until you reach the end

--]]

function _8086:parse_to_asm(file_url, file_name)
    -- load file and get number of commands
    local file_handle = assert(io.open(file_url, 'rb'), "Failed to open file: " .. file_url)
    _8086.file_data = file_handle:read("*all")
    print("\n\n----> PARSE ASM FILE: '" .. file_name .. "' ...")

    -- move through the buffer and identify new commands in chunks
    _8086.CMD_LIST = {}
    _8086.byte_index = 1
    _8086.cmd_counter = 1

    ----------------------------------------------------- PARSING LOOP
    while (_8086.byte_index <= #_8086.file_data) do
        -- init and setup the basic OP type
        _8086:init_cmd(string.byte(_8086.file_data, _8086.byte_index, _8086.byte_index))
        local str_result = _8086.CMD_STATE.type
        _8086.op_a = _8086.CMD_STATE:operand_a()
        _8086.op_b = _8086.CMD_STATE:operand_b()
        str_result = str_result .. " " .. _8086.op_a .. ", " .. _8086.op_b
        print("CMD[" .. _8086.cmd_counter .. "] --> " .. str_result)
        table.insert(_8086.CMD_LIST, str_result)

        -- march on --
        _8086.byte_index = _8086.byte_index + _8086:cur_cmd_req_bytes()
        _8086.cmd_counter = _8086.cmd_counter + 1
    end
    print("PARSE COMPLETE: " .. (_8086.cmd_counter - 1) .. " command lines")


    -- Build the master string and WRITE it to ASM
    local asm_string = "bits 16\n\n"
    for i = 1, #_8086.CMD_LIST do
        asm_string = asm_string .. _8086.CMD_LIST[i] .. "\n"
    end
    _8086:write_asm(asm_string, file_name)
end

--/////////////////////////////////////
-- BINARY HELPERS
--/////////////////////////////////////

function _8086:to_binary(number)
    local remainder = ""
    while number > 0 do
        remainder = tostring(number % 2) .. remainder
        number = math.floor(number / 2)
    end
    return remainder
end

function _8086:byte_as_binary(index)
    -- Safety checks
    assert(_8086.file_data ~= nil, "FILE DATA NIL")
    assert(index ~= nil, "INDEX IS NIL")
    assert(index <= #_8086.file_data,
        "INDEX " .. tostring(index) .. " OUT OF BOUNDS (file length: " .. #_8086.file_data .. ")")

    local byte_value = string.byte(_8086.file_data, index)
    return _8086:to_binary(byte_value)
end

function _8086:bytes_as_binary(index, length)
    local result = ""

    for i = 1, length do
        result = result .. _8086:byte_as_binary(index + (i - 1))
    end
    return result
end

function _8086:write_asm(file_name, asm_string)
    -- "open a new file ion write mode (w)"
    local file_url = "output/" .. file_name .. ".asm"
    local new_file = io.open(file_url, "w")
    if (new_file) then
        new_file:write(asm_string)
        new_file:close();
    end
end

-- Identify what type of command we are parsing. Return an OP_CONFIG if a match is found
function _8086:init_cmd(input)
    -- input to binary
    local i2b = _8086:to_binary(input)

    for key, value in pairs(_8086.OP_CODES) do
        local test_chunk = string.sub(i2b, 1, #key)
        if (test_chunk == key) then
            _8086.CMD_STATE = value
            _8086:allocate_cmd_binary()
            print("\nCMD[" .. _8086.cmd_counter .. "] " .. value.id .. "  " .. key)
            print(_8086.CMD_BINARY)
            -- _8086:log_all_fields()
            return
        end
    end
    -- Fail gracefully
    assert(false, "no OP_CODE found with sig matching: " .. i2b)
    return nil
end

function _8086:allocate_cmd_binary()
    _8086.CMD_BINARY = _8086:bytes_as_binary(_8086.byte_index, _8086.CMD_STATE.min_bytes)
    _8086.CMD_BINARY = _8086:bytes_as_binary(_8086.byte_index, _8086:cur_cmd_req_bytes())
end

function _8086:get_file_bytes_as_binary(index, length)
    local str = ""
    for i = index, length do
        str = str .. _8086:to_binary(string.byte(_8086.file_data, index, index))
    end
    return str
end

function _8086:log_all_fields()
    for key, value in pairs(_8086.CMD_STATE.fields) do
        print("  - " .. key .. ": " .. _8086:field(key))
    end
end

function _8086:field(key)
    local field_lookup = _8086.CMD_STATE.fields[key]
    assert(field_lookup ~= nil, "Unable to find field: [" .. key .. "] in cmd_state (" .. _8086.CMD_STATE.id .. ")")
    -- get mod binary
    local start_index = field_lookup[1]
    local end_index = start_index + (field_lookup[2] - 1)
    local result = string.sub(_8086.CMD_BINARY, start_index, end_index)
    -- use them to find out how many bytes are required in MOD_LOOKUP
    -- tweak if needed (special 16bit flag)
    return result
end

function _8086:data_read(id)

end

function _8086:cur_cmd_req_bytes()
    local total_bytes = _8086.CMD_STATE.min_bytes
    total_bytes = total_bytes + _8086:mod_bytes_required()
    total_bytes = total_bytes + _8086:imm_data_bytes_required()
    return total_bytes
end

function _8086:mod_bytes_required()
    if (_8086.CMD_STATE.has_mod) then
        local mod = _8086:field("mod")
        local extra_bytes = _8086.MOD_LOOKUP[mod].extra_bytes
        -- special exception, if MOD is 00, check R_M == 110 (for 16bit)
        if (mod == "00") then
            local r_m = _8086:field("r_m")
            if (r_m == "110") then
                extra_bytes = 2
            end
        end
        return extra_bytes
    else
        return 0
    end
end

function _8086:imm_data_bytes_required()
    if (_8086.CMD_STATE.has_immediate_data) then
        local w = _8086:field("w")
        if w=="0" then
            return 1
        else
            return 2
        end
    else
        return 0
    end
end

--//////////////////////////////////////////////
-- DEFINITIONS
--//////////////////////////////////////////////

-- REGISTER to REGISTER
function _8086:REG_2_REG_operand_a()
    return _8086.MOD_LOOKUP[_8086:field("mod")][_8086:field("r_m")][_8086:field("w") + 1]
end

function _8086:REG_2_REG_operand_b()
    return _8086.MOD_LOOKUP[_8086:field("mod")][_8086:field("reg")][_8086:field("w") + 1]
end

-- IMMEDIATE to REGISTER / MEMORY
function _8086:IMM_2_RM_operand_a()
    assert(false, "IMM_2_RM (a) not implemented yet")
    return ""
end

function _8086:IMM_2_RM_operand_b()
    assert(false, "IMM_2_RM (b) not implemented yet")
    return ""
end

-- IMMEDIATE to REGISTER
function _8086:IMM_2_REG_operand_a()
    return _8086.REG_LOOKUP[_8086:field("reg")][_8086:field("w") + 1]
end

function _8086:IMM_2_REG_operand_b()
    local data = nil
    local bytes_required = _8086:imm_data_bytes_required()
    if bytes_required == 1 then
        data =  _8086:field("data_8-bit")
    else
        data = _8086:field("data_16-bit")
    end
    return tonumber(data,2)
end

-- FIELD data is stored as a START_INDEX, LENGTH
-- e.g. 100010.w is located at 8, length of 1
_8086.OP_CODES = {
    ["100010"] = {
        type = "mov",
        min_bytes = 2,
        has_mod = true,
        has_immediate_data = false,
        id = "MOV REG_2_REG",
        fields = {
            ["d"] = { 7, 1 },
            ["w"] = { 8, 1 },
            ["mod"] = { 9, 2 },
            ["reg"] = { 11, 3 },
            ["r_m"] = { 14, 3 },
        },
        operand_a = _8086.REG_2_REG_operand_a,
        operand_b = _8086.REG_2_REG_operand_b,
    },
    ["1100011"] = {
        type = "mov",
        min_bytes = 2,
        has_mod = true,
        has_immediate_data = true,
        id = "MOV IMM_2_RM",
        fields = {
            ["w"] = { 8, 1 },
            ["mod"] = { 9, 2 },
            ["r_m"] = { 14, 3 },
        },
        operand_a = _8086.IMM_2_RM_operand_a,
        operand_b = _8086.IMM_2_RM_operand_b,
    },
    ["1011"] = {
        type = "mov",
        min_bytes = 1,
        has_mod = false,
        has_immediate_data = true,
        id = "MOV IMM_2_REG",
        fields = {
            ["w"] = { 5, 1 },
            ["reg"] = { 6, 3 },
            ["data_8-bit"] = { 9, 8 },
            ["data_16-bit"] = { 9, 16 },
        },
        operand_a = _8086.IMM_2_REG_operand_a,
        operand_b = _8086.IMM_2_REG_operand_b,
    },
}
_8086.REG_ENCODING_MOD_00 = {
    extra_bytes = 0, -- unless R_M is 110 (TODO)
    -- ["000"] = "(bx) + (si)",
    -- ["001"] = "(bx) + (di)",
    -- ["010"] = "(bp) + (si)",
    -- ["011"] = "(bp) + (di)",
    -- ["100"] = "(si)",
    -- ["101"] = "(di)",
    -- ["110"] = "direct address",
    -- ["111"] = "(bx)",
}
_8086.REG_ENCODING_MOD_01 = {
    extra_bytes = 1, -- 8bit follows
}
_8086.REG_ENCODING_MOD_10 = {
    extra_bytes = 2, -- 16bit follows
}
_8086.REG_ENCODING_MOD_11 = {
    extra_bytes = 0, -- 16bit follows
    ["000"] = { "al", "ax" },
    ["001"] = { "cl", "cx" },
    ["010"] = { "dl", "dx" },
    ["011"] = { "bl", "bx" },
    ["100"] = { "ah", "sp" },
    ["101"] = { "ch", "bp" },
    ["110"] = { "dh", "si" },
    ["111"] = { "bh", "di" },
}
_8086.MOD_LOOKUP = {
    ["00"] = _8086.REG_ENCODING_MOD_00,
    ["01"] = _8086.REG_ENCODING_MOD_01,
    ["10"] = _8086.REG_ENCODING_MOD_10,
    ["11"] = _8086.REG_ENCODING_MOD_11,
}
_8086.REG_LOOKUP = {
    ["000"] = { "al", "ax" },
    ["001"] = { "cl", "cx" },
    ["010"] = { "dl", "dx" },
    ["011"] = { "bl", "bx" },
    ["100"] = { "ah", "sp" },
    ["101"] = { "ch", "bp" },
    ["110"] = { "dh", "si" },
    ["111"] = { "bh", "di" },
}
