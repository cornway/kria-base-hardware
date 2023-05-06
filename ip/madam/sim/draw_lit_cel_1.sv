

`include "../synth/mcore_defs.svh"

import xmem_pkg::*;
import bram_pkg::*;
import mcore_pkg::*;

module draw_lit_cel_1_top;

localparam DATA_WIDTH = 32'd32;
localparam ADDR_WIDTH = 32'd32;
localparam PIXEL_WIDTH = 32'd16;
localparam RD_LATENCY = 32'd2;
localparam WR_LATENCY = 32'd1;
localparam MEMORY_DEPTH = 32'h300000;
localparam BRAM_READ_LATENCY = 32'd2;
localparam TA = 2ns;
localparam TT = 8ns;

logic [15:0] PLUT[32] = '{
    16'h10c5,
    16'h0,
    16'h10c4,
    16'h882,
    16'hca4,
    16'h460,
    16'h420,
    16'h20,
    16'h862,
    16'h421,
    16'h861,
    16'h441,
    16'h41,
    16'h8a2,
    16'h881,
    16'h440,
    16'h8a1,
    16'h8c1,
    16'hcc1,
    16'hcc2,
    16'h480,
    16'hcc3,
    16'h8a0,
    16'h10c3,
    16'h14e5,
    16'h10e4,
    16'hffff,
    16'hffff,
    16'hffff,
    16'hffff,
    16'hffff,
    16'hffff
};

logic aclk;
logic aresetn;
event xmem_drv_done_event;
longint unsigned clock_count = 0;

`include "xmem_assign.svh"
`include "bram_assign.svh"

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
    xmemory.set_memory("/tmp/test_data/draw_literal_1_before.bin");
    xmemory.wait_ready();
    fork
        forever begin
            xmemory.monitor();
        end
        begin
            @(xmem_drv_done_event);
            xmemory_exp = new(xmem_if_dv_1);
            xmemory_exp.setup();
            xmemory_exp.set_memory("/tmp/test_data/draw_literal_1_after.bin");
            error_count = xmemory_exp.cmp_mem(xmemory);
            if (error_count)
                $fatal("Memory Check Faield !!! errors=%d", error_count);
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

typedef McoreRegs #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) McoreRegs_t;

McoreRegs_t mcoreClass;

initial begin
    bramDrv = new(xbram_if_dv);
    mcoreClass = new(bramDrv);

    bramDrv.setup();
    bramDrv.wait_ready();

    /*Cel setup begin*/
    mcoreClass.set_cel_int_var(HDDX1616_ID , 32'h0);
    mcoreClass.set_cel_int_var(HDDY1616_ID , 32'h0);
    mcoreClass.set_cel_int_var(HDX1616_ID , 32'h10000);
    mcoreClass.set_cel_int_var(HDY1616_ID , 32'h0);
    mcoreClass.set_cel_int_var(VDX1616_ID , 32'h0);
    mcoreClass.set_cel_int_var(VDY1616_ID , 32'h10000);
    mcoreClass.set_cel_int_var(XPOS1616_ID , 32'h1349000);
    mcoreClass.set_cel_int_var(YPOS1616_ID , 32'h6a0000);
    mcoreClass.set_cel_int_var(HDX1616_2_ID , 32'h0);
    mcoreClass.set_cel_int_var(HDY1616_2_ID , 32'h0);
    mcoreClass.set_cel_int_var(TEXTURE_WI_START_ID , 32'h0);
    mcoreClass.set_cel_int_var(TEXTURE_HI_START_ID , 32'h0);
    mcoreClass.set_cel_int_var(TEXEL_INCX_ID , 32'h1);
    mcoreClass.set_cel_int_var(TEXEL_INCY_ID , 32'h1);
    mcoreClass.set_cel_int_var(TEXTURE_WI_LIM_ID , 32'h56);
    mcoreClass.set_cel_int_var(TEXTURE_HI_LIM_ID , 32'hb0);
    mcoreClass.set_cel_int_var(TEXEL_FUN_NUMBER_ID , 32'h1);
    mcoreClass.set_cel_int_var(SPRWI_ID , 32'h2);
    mcoreClass.set_cel_int_var(SPRHI_ID , 32'h16);
    mcoreClass.set_cel_int_var(BITCALC_ID , 32'h180);
    mcoreClass.set_cel_uint_var(BITADDR_ID , 32'h0);
    mcoreClass.set_cel_uint_var(BITBUFLEN_ID , 32'h0);
    mcoreClass.set_cel_uint_var(BITBUF_ID , 32'h0);
    mcoreClass.set_cel_uint_var(CCBFLAGS_ID , 32'h3fbec000);
    mcoreClass.set_cel_uint_var(PIXC_ID , 32'h1f811f00);
    mcoreClass.set_cel_uint_var(PRE0_ID , 32'h544);
    mcoreClass.set_cel_uint_var(PRE1_ID , 32'h1001);
    mcoreClass.set_cel_uint_var(TARGETPROJ_ID , 32'h0);
    mcoreClass.set_cel_uint_var(SRCDATA_ID , 32'h0);
    mcoreClass.set_cel_uint_var(PLUTF_ID , 32'h0);
    mcoreClass.set_cel_uint_var(PDATF_ID , 32'h0);
    mcoreClass.set_cel_uint_var(NCCBF_ID , 32'h0);
    mcoreClass.set_cel_uint_var(PXOR1_ID , 32'hffffffff);
    mcoreClass.set_cel_uint_var(PXOR2_ID , 32'h0);
    mcoreClass.set_mregs(CLIPXY_ID , 32'hef013f);
    mcoreClass.set_mregs(FBTARGET_ID , 32'h201000);
    mcoreClass.set_mregs(PDATA_ID , 32'h283b08);
    mcoreClass.set_wmod(  32'h500);
    /*Setup PDEC begin*/
    mcoreClass.set_utils_reg(32'h20 , 32'h0);
    mcoreClass.set_utils_reg(32'h21 , 32'hf);
    mcoreClass.set_utils_reg(32'h22 , 32'h1);
    /*Setup PDEC end*/
    /*Cel setup end*/

    //PLUT
    mcoreClass.load_plut(PLUT);

    //offset, trigger
    mcoreClass.set_utils_reg(32'h61 , 32'h0);


    mcoreClass.poll_reg(mcoreClass.get_utils_reg_addr(32'h60), '0);

    $display("Clocks taken : %d", clock_count);
    -> xmem_drv_done_event;
    repeat(20) @(posedge aclk);
    $finish();
end

endmodule