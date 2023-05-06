

`include "../synth/mcore_defs.svh"

import xmem_pkg::*;
import bram_pkg::*;
import mcore_pkg::*;

module draw_mcore_ut_top;

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
    16'h0,
    16'h7fff,
    16'h77fe,
    16'h6b9b,
    16'h5f39,
    16'h7fff,
    16'h67bc,
    16'h4f59,
    16'h3af6,
    16'h63fc,
    16'h5398,
    16'h4314,
    16'h3af6,
    16'h4bfd,
    16'h3b55,
    16'h2a8f,
    16'h2e91,
    16'h2270,
    16'h1a0d,
    16'h15ee,
    16'h11ca,
    16'h3f58,
    16'h32b3,
    16'h25ed,
    16'h1928,
    16'h2a8f,
    16'h222d,
    16'h1dcb,
    16'h1989,
    16'h222d,
    16'h1548,
    16'h883
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
BramDrv_t bramDrv;

//Memory monitor
initial begin
    xmemory = new(xmem_if_dv);
    xmemory.setup();
    xmemory.set_memory("/tmp/test_data/draw_literal_0_before.bin");
    xmemory.dump_memory("/tmp/test_data/draw_literal_0_before.bin.sim");
    xmemory.wait_ready();
    fork
        forever begin
            xmemory.monitor();
        end
        begin
            @(xmem_drv_done_event);
            xmemory.dump_memory("/tmp/test_data/draw_literal_0.bin.sim");
            //xmemory.print_mem();
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

McoreRegs_t mcoreRegs;


task automatic poll_done(ref BramDrv_t bramDrv);
    automatic logic [DATA_WIDTH-1:0] read_data;
    bramDrv.read(mcoreRegs.get_utils_reg_addr(32'h50), read_data);
    while (read_data[0]) begin
        bramDrv.read(mcoreRegs.get_utils_reg_addr(32'h50),read_data);
    end
endtask

task automatic load_plut(ref BramDrv_t bramDrv, ref McoreRegs_t regs, input logic [15:0] PLUT[32]);
    automatic integer i;
    automatic logic [ADDR_WIDTH-1:0] addr;

    addr = regs.get_plut_addr();
    for (i = 0; i < 32; i++) begin
        bramDrv.write(addr, PLUT[i]);
        addr += DATA_WIDTH/8;
    end
endtask

initial begin
    mcoreRegs = new();
    bramDrv = new(xbram_if_dv);

    bramDrv.setup();
    bramDrv.wait_ready();


    //Draw bitmap row
    bramDrv.write(mcoreRegs.get_wmod_addr(), 32'h500);
    bramDrv.write(mcoreRegs.get_cel_int_addr(HDX1616_ID), 1'b1 << 16);
    bramDrv.write(mcoreRegs.get_cel_int_addr(HDY1616_ID), '0);

    //Draw literal core
    bramDrv.write(mcoreRegs.get_cel_int_addr(XPOS1616_ID), 32'h10000);
    bramDrv.write(mcoreRegs.get_cel_int_addr(YPOS1616_ID), 32'h30000);

    bramDrv.write(mcoreRegs.get_cel_uint_addr(PRE0_ID), 32'h7c4);
    bramDrv.write(mcoreRegs.get_cel_int_addr(SPRWI_ID), 32'ha0);
    bramDrv.write(mcoreRegs.get_cel_int_addr(BITCALC_ID), '0);
    bramDrv.write(mcoreRegs.get_cel_int_addr(VDX1616_ID), '0);
    bramDrv.write(mcoreRegs.get_cel_int_addr(VDY1616_ID), 32'h10000);
    bramDrv.write(mcoreRegs.get_cel_int_addr(TEXTURE_HI_LIM_ID), 32'h20);
    bramDrv.write(mcoreRegs.get_mregs_addr(PDATA_ID), 32'h271bd0);

    bramDrv.write(mcoreRegs.get_cel_int_addr(TEXTURE_WI_LIM_ID), 32'h13f);
    bramDrv.write(mcoreRegs.get_cel_int_addr(TEXTURE_HI_START_ID), 32'h0);
    bramDrv.write(mcoreRegs.get_cel_int_addr(TEXTURE_WI_START_ID), '0);

    //PDEC
    bramDrv.write(mcoreRegs.get_utils_reg_addr(32'h20), 32'h0);
    bramDrv.write(mcoreRegs.get_utils_reg_addr(32'h21), 32'hf);
    bramDrv.write(mcoreRegs.get_utils_reg_addr(32'h22), 32'h1);

    //PLUT
    load_plut(bramDrv, mcoreRegs, PLUT);

    //offset, trigger
    bramDrv.write(mcoreRegs.get_utils_reg_addr(32'h51), 32'h1c);


    poll_done(bramDrv);
    $display("Clocks taken : %d", clock_count);
    -> xmem_drv_done_event;
    repeat(20) @(posedge aclk);
    $finish();
end

endmodule