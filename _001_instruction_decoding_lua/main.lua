#!/usr/bin/env lua

require "interpreter_8086"
_8086:parse_to_asm("asm/listing_0037_single_register_mov", "_0037_single")
_8086:parse_to_asm("asm/listing_0038_many_register_mov", "_0038_multiple")
