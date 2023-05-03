

`timescale 1ns/1ps

package mcore_pkg;

//`include "../synth/mcore_defs.svh"

localparam M_REGS_ADDR = 32'h0;
localparam M_PLUT_ADDR = 32'h4000;
localparam M_PBUSQ_ADDR = 32'h8000;
localparam M_RMOD_WMOD_FSM_ADDR = 32'hC000;
localparam M_UTIL_ADDR = 32'h10000;
localparam M_CEL_VARS_ADDR = 32'h14000;
localparam CEL_VARS_SUB_SIZE = 32'h80;

class McoreRegs #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32
);

function new();
endfunction

function logic [ADDR_WIDTH-1:0] get_mregs_addr(integer mreg_id);
    return M_REGS_ADDR + (mreg_id * DATA_WIDTH/8);
endfunction

function logic [ADDR_WIDTH-1:0] get_wmod_addr();
    return M_RMOD_WMOD_FSM_ADDR + 32'h4;
endfunction

function logic [ADDR_WIDTH-1:0] get_cel_uint_addr(integer id);
    return M_CEL_VARS_ADDR + (((id | CEL_VARS_SUB_SIZE) * DATA_WIDTH/8));
endfunction

function logic [ADDR_WIDTH-1:0] get_cel_int_addr(integer id);
    return M_CEL_VARS_ADDR + ((id * DATA_WIDTH/8));
endfunction

function logic [ADDR_WIDTH-1:0] get_utils_reg_addr(integer id);
    return M_UTIL_ADDR + ((id * DATA_WIDTH/8));
endfunction

function logic [ADDR_WIDTH-1:0] get_plut_addr();
    return M_PLUT_ADDR;
endfunction

endclass

endpackage