

`timescale 1ns/1ps

package mcore_pkg;

import bramif_pkg::*;

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

typedef BramIf #(
    .data_t(logic[DATA_WIDTH-1:0]),
    .addr_t(logic[ADDR_WIDTH-1:0])
) BramIf_t;

typedef logic [DATA_WIDTH-1:0] data_t;
typedef logic [ADDR_WIDTH-1:0] addr_t;

protected BramIf_t bram;

function new(BramIf_t bram);
    this.bram = bram;
endfunction

//LOCAL
local function logic [ADDR_WIDTH-1:0] get_mregs_addr(integer mreg_id);
    return M_REGS_ADDR + (mreg_id * DATA_WIDTH/8);
endfunction

local function logic [ADDR_WIDTH-1:0] get_wmod_addr();
    return M_RMOD_WMOD_FSM_ADDR + 32'h4;
endfunction

local function logic [ADDR_WIDTH-1:0] get_cel_uint_addr(integer id);
    return M_CEL_VARS_ADDR + (((id | CEL_VARS_SUB_SIZE) * DATA_WIDTH/8));
endfunction

local function logic [ADDR_WIDTH-1:0] get_cel_int_addr(integer id);
    return M_CEL_VARS_ADDR + ((id * DATA_WIDTH/8));
endfunction

local function logic [ADDR_WIDTH-1:0] get_plut_addr();
    return M_PLUT_ADDR;
endfunction


//PUBLIC
function logic [ADDR_WIDTH-1:0] get_utils_reg_addr(integer id);
    return M_UTIL_ADDR + ((id * DATA_WIDTH/8));
endfunction

task automatic set_wmod(input data_t data);
    this.bram.write(get_wmod_addr(), data);
endtask

task automatic set_cel_int_var(input addr_t addr, input data_t data);
    this.bram.write(get_cel_int_addr(addr), data);
endtask

task automatic get_cel_int_var(input addr_t addr, output data_t data);
    this.bram.read(get_cel_int_addr(addr), data);
endtask

task automatic set_cel_uint_var(input addr_t addr, input data_t data);
    this.bram.write(get_cel_uint_addr(addr), data);
endtask

task automatic get_cel_uint_var(input addr_t addr, output data_t data);
    this.bram.read(get_cel_uint_addr(addr), data);
endtask

task automatic set_utils_reg(input addr_t addr, input data_t data);
    this.bram.write(get_utils_reg_addr(addr), data);
endtask

task automatic set_mregs(input addr_t addr, input data_t data);
    this.bram.write(get_mregs_addr(addr), data);
endtask

task automatic get_mregs(input addr_t addr, output data_t data);
    this.bram.read(get_mregs_addr(addr), data);
endtask

task automatic poll_reg(logic[ADDR_WIDTH-1:0] addr, logic[DATA_WIDTH-1:0] exp);
    automatic logic [DATA_WIDTH-1:0] read_data;

    this.bram.read(addr, read_data);
    while (read_data != exp) begin
        this.bram.read(addr,read_data);
    end
endtask

task automatic load_plut(input logic [15:0] PLUT[32]);
    automatic integer i;
    automatic logic [ADDR_WIDTH-1:0] addr;

    addr = get_plut_addr();
    for (i = 0; i < 32; i++) begin
        this.bram.write(addr, PLUT[i]);
        addr += DATA_WIDTH/8;
    end
endtask

endclass

endpackage