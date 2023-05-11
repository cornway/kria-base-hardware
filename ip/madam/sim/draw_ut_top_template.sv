

`include "../synth/mcore_defs.svh"

import xmem_pkg::*;
import bram_pkg::*;
import mcore_pkg::*;

module UT_TOP_MODULE_NAME;

localparam DATA_WIDTH = 32'd32;
localparam ADDR_WIDTH = 32'd32;
localparam PIXEL_WIDTH = 32'd16;
localparam RD_LATENCY = 32'd2;
localparam WR_LATENCY = 32'd1;
localparam MEMORY_DEPTH = 32'h300000;
localparam BRAM_READ_LATENCY = 32'd2;
localparam TA = 2ns;
localparam TT = 8ns;

logic aclk;
logic aresetn;
event xmem_drv_done_event;
longint unsigned clock_count = 0;

`include "xmem_assign.svh"
`include "bram_assign.svh"

typedef McoreRegs #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) McoreRegs_t;

`include "CEL_SETUP_SVH"
//`include "CEL_CHECK_SVH"

typedef Xmemory #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .RD_LATENCY(RD_LATENCY),
    .WR_LATENCY(WR_LATENCY),
    .MEMORY_DEPTH(MEMORY_DEPTH),
    .TT(TT),
    .TA(TA)
) Xmemory_t;

typedef BramDrv #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .BRAM_READ_LATENCY(BRAM_READ_LATENCY),
    .TT(TT),
    .TA(TA)
) BramDrv_t;

mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem_if();

mem_if_dv #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem_if_dv(.aclk(aclk), .aresetn(aresetn));

mem_if_dv #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem_if_dv_1(.aclk(aclk), .aresetn(aresetn));


bram_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xbram_if();

bram_if_dv #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xbram_if_dv(.aclk(aclk), .aresetn(aresetn));

`XMEM_ASSIGN(xmem_if_dv, xmem_if);
`BRAM_ASSIGN(xbram_if, xbram_if_dv);

Xmemory_t xmemory;
Xmemory_t xmemory_exp;

BramDrv_t bramDrv;

integer error_count;
//Memory monitor
initial begin
    xmemory = new(xmem_if_dv);
    xmemory.setup();
    xmemory.set_memory("MEM_CAP_BEFORE");

    xmemory.wait_ready();
    fork
        forever begin
            xmemory.monitor();
        end
        begin
            @(xmem_drv_done_event);
            xmemory_exp = new(xmem_if_dv_1);
            xmemory_exp.setup();
            xmemory_exp.set_memory("MEM_CAP_AFTER");
            error_count = xmemory_exp.cmp_mem(xmemory);
            if (error_count)
                $fatal(1, "Memory Check Faield !!! errors=%d", error_count);
            else
                $display("Memory Check Succeeded");
        end
    join
end

initial begin
    fork
        begin
            aclk = '0;
            aresetn = '0;
        end
        begin
            repeat(16) @(posedge aclk);
            aresetn = '1;
        end
    join
end

always begin
    #10ns aclk <= ~aclk;
end

always @(posedge aclk) begin
    clock_count++;
end

mcore_top_wrapper #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH))
mcore_top_wrapper_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .clka(aclk),
    .rsta(~aresetn),
    .addra(xbram_if.addra),
    .dina(xbram_if.dina),
    .douta(xbram_if.douta),
    .ena(xbram_if.ena),
    .wea(xbram_if.wea),

    .mem_req(xmem_if.req),
    .mem_addr(xmem_if.addr),
    .mem_we(xmem_if.we),
    .mem_wdata(xmem_if.wdata),
    .mem_be(xmem_if.be),
    .mem_gnt(xmem_if.gnt),
    .mem_rsp_valid(xmem_if.rsp_valid),
    .mem_rsp_rdata(xmem_if.rsp_rdata),
    .mem_rsp_error(xmem_if.rsp_error)
);

McoreRegs_t mcoreClass;

initial begin
    bramDrv = new(xbram_if_dv);
    mcoreClass = new(bramDrv);

    $dumpfile("dump.vcd");
    $dumpvars();

    bramDrv.setup();
    bramDrv.wait_ready();

    setup_cel_core(mcoreClass);

    //trigger
    mcoreClass.set_utils_reg(TRIGGER_REG_NUM, '0);

    mcoreClass.poll_reg(mcoreClass.get_utils_reg_addr(32'h50), '0);
    $display("Clocks taken : %d", clock_count);
    -> xmem_drv_done_event;
    repeat(20) @(posedge aclk);
    $finish();
end

endmodule