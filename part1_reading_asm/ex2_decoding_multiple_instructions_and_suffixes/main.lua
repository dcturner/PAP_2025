#!/usr/bin/env lua

require "interpreter_8086"
local test = 0
_8086:parse_to_asm("asm/listing_0037_single_register_mov", "_0037")
_8086:parse_to_asm("asm/listing_0038_many_register_mov", "_0038")
_8086:parse_to_asm("asm/listing_0039_more_movs", "_0039_more")
-- _8086:parse_to_asm("asm/listing_0038_many_register_mov", "_0038_multiple")

