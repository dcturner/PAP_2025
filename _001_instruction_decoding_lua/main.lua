#!/usr/bin/env lua
require "interpreter_8086"

function to_binary(number)
  local remainder = ""
  while number > 0 do
    remainder = tostring(number % 2) .. remainder
    number = math.floor(number / 2)
  end
  return remainder
  -- print(remainder)
end

function parse_command(cmd)
  print("parse... a: " .. cmd.a .. ", b: " .. cmd.b)
  return _8086:parse(cmd.a, cmd.b)
end

--//////////////////////////////////////////////
-- DEFINITIONS
--//////////////////////////////////////////////

-- Machine Instruction Format
MIF_STRUCTURE = { 6, 1, 1, 2, 3, 3 }
MIF_FIELDS = { "op_code", "d", "w", "mod", "reg", "r_m" }

--//////////////////////////////////////////////
-- START
--//////////////////////////////////////////////

-- LOAD FILE
-- FILE_NAME = "asm/listing_0037_single_register_mov"
FILE_NAME = "asm/listing_0038_many_register_mov"
FILE_HANDLE = assert(io.open(FILE_NAME, 'rb'))
DATA_TXT = FILE_HANDLE:read("*all")

-- How many commands? (2 chars per cmd)
CMD_COUNT = math.floor(#DATA_TXT / 2)

-- Add each 2byte command into a command list
CMD_LIST = {}
OUTPUT = {}
for i = 1, CMD_COUNT do
  local index = (i * 2) - 1
  local cmd = {
    -- isolate the a//b bytes for this instruction and hand them to the interpreter
    table.insert(CMD_LIST, _8086:parse(
      to_binary(string.byte(DATA_TXT, index, index)),
      to_binary(string.byte(DATA_TXT, index + 1, index + 1))
    ))
  }
  for i = 1, #CMD_LIST do
    print("(" .. i .. ") --> " .. CMD_LIST[i])
  end
end
