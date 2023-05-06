`timescale 1ns/1ps


`include "../synth/mcore_defs.svh"

module fb_ut_top;

localparam DATA_WIDTH = 32'd32;
localparam ADDR_WIDTH = 32'd32;
localparam PIXEL_WIDTH = 32'd16;
localparam TA = 2ns;
localparam TT = 8ns;

logic aclk;
logic aresetn;

mcore_t mcore;

mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) fb_mem();

uint16_t fb_pixel;
logic [ADDR_WIDTH-1:0] fb_addr;
uint16_t fb_x, fb_y;
logic fb_req, fb_resp, fb_busy;

frame_buffer #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .PIXEL_WIDTH(PIXEL_WIDTH)
) frame_buffer_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .memory(fb_mem.slave),
    .mcore(mcore),
    .pixel(fb_pixel),
    .x(fb_x),
    .y(fb_y),
    .req(fb_req),
    .resp(fb_resp),
    .busy(fb_busy),
    .ext_offset('0),
    .dbg_flags(7'h2)
);


task _write_pix (input logic [15:0] x, input logic [15:0] y, input logic [PIXEL_WIDTH-1:0] pix);

    fb_pixel <= #TA pix;
    fb_x <= #TA x;
    fb_y <= #TA y;
    fb_req <= #TA '1;
    cycle_start();
    cycle_end();

    @(posedge aclk iff fb_resp);

    fb_pixel <= #TA '0;
    fb_x <= #TA '0;
    fb_y <= #TA '0;
    fb_addr <= #TA '0;
    fb_req <= #TA '0;

endtask

always begin
    @(posedge aclk iff fb_mem.req);
    $display("Data being written : addr = %x be= %x pix = %x", fb_mem.addr, fb_mem.be, fb_mem.wdata);
    wait(!fb_mem.req);
end

always begin
    @(posedge aclk iff fb_mem.req);
    repeat(2) @(posedge aclk);

    fb_mem.gnt <= '1;
    fb_mem.rsp_valid <= '1;

    @(posedge aclk);
    fb_mem.gnt <= '0;
    fb_mem.rsp_valid <= '0;

end

logic[ADDR_WIDTH-1:0] addr_offset = 32'h200000;

initial begin
    wait(aresetn);

    _write_pix(16'hec, 16'h82, 16'ha108);

    @(posedge aclk);
    $finish();
end

initial begin
    fork
        begin
            aclk = '0;
            aresetn = '0;
            mcore.wmod = 32'h500;
            mcore.regs[FBTARGET_ID] = 32'h200000;
            fb_pixel = '0;
            fb_x  = '0;
            fb_y  = '0;
            fb_addr  = '0;
            fb_req  = '0;
            fb_mem.gnt = '0;
            fb_mem.rsp_valid = '0;
        end
        begin
            repeat(16) @(posedge aclk);
            aresetn = '1;
        end
    join
end

task cycle_start;
    #TT;
endtask

task cycle_end;
    @(posedge aclk);
endtask

always begin
    #10 aclk <= ~aclk;
end

endmodule