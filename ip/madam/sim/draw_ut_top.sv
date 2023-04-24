

`include "../synth/mcore_defs.svh"

import xmem_pkg::*;

module draw_ut_top;

localparam DATA_WIDTH = 32'd32;
localparam ADDR_WIDTH = 32'd32;
localparam PIXEL_WIDTH = 32'd16;
localparam RD_LATENCY = 32'd2;
localparam WR_LATENCY = 32'd1;
localparam MEMORY_DEPTH = 32'h100000;
localparam PIPE_LEN = 32'd4;
localparam TA = 2ns;
localparam TT = 8ns;


logic aclk;
logic aresetn;
event xmem_drv_done_event;

`include "xmem_assign.svh"

typedef Xmemory #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .RD_LATENCY(RD_LATENCY),
    .WR_LATENCY(WR_LATENCY),
    .MEMORY_DEPTH(MEMORY_DEPTH),
    .TT(TT),
    .TA(TA)
) Xmemory_t;

mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem_if();

mem_if_dv #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem_if_dv(.aclk(aclk), .aresetn(aresetn));

`XMEM_ASSIGN(xmem_if_dv, xmem_if);

Xmemory_t xmemory;


initial begin
    xmemory = new(xmem_if_dv);
    xmemory.setup();
    xmemory.wait_ready();
    fork
        forever begin
            xmemory.monitor();
        end
        begin
            @(xmem_drv_done_event);
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

int32_t xcur, ycur, cnt;
pixel_t pixel;
logic req, busy;
mcore_t mcore;

draw_bmap_row #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIPE_LEN(PIPE_LEN)
) draw_bmap_row_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .req(req),
    .mcore(mcore),
    .xcur_in(xcur),
    .ycur_in(ycur),
    .cnt_in(cnt),
    .pdec_transparent_in('0),
    .pix_req(),
    .pix_resp('1),
    .pixel(pixel),
    .memory(xmem_if),

    .busy(busy)
);

initial begin
    xcur = '0;
    ycur = '0;
    cnt = '0;
    pixel = '0;
    req = '0;
    mcore.wmod = 32'h500;
    `HDX1616(mcore) = 1'b1 << 16;
    `HDY1616(mcore) = 1'b1  << 16;

    wait(aresetn);

    xcur = 32'd10;
    ycur = 32'd10;
    cnt = 32'd10;
    pixel = 16'h7fff;
    req = '1;
    wait(busy);
    req = '0;

    @(negedge busy);
    -> xmem_drv_done_event;
    repeat(2) @(posedge aclk);
    $finish();
end

endmodule