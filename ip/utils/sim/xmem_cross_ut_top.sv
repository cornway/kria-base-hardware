

`timescale 1ns/1ps

import xmem_pkg::*;

module xmem_cross_ut_top;

localparam DATA_WIDTH = 32'd32;
localparam ADDR_WIDTH = 32'd32;
localparam RD_LATENCY = 32'd2;
localparam WR_LATENCY = 32'd1;
localparam TT = 8ns;
localparam TA = 2ns;
localparam NUM_MASTERS = 3;
localparam MEMORY_DEPTH = 8;

event xmem_drv_done_event;

typedef XmemDriver #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .TT(TT),
    .TA(TA)
) XmemDriver_t;

typedef Xmemory #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .RD_LATENCY(RD_LATENCY),
    .WR_LATENCY(WR_LATENCY),
    .MEMORY_DEPTH(MEMORY_DEPTH),
    .TT(TT),
    .TA(TA)
) Xmemory_t;

XmemDriver_t xmatser_1;
XmemDriver_t xmatser_2;
XmemDriver_t xmatser_3;

Xmemory_t xmemory;

`include "xmem_assign.svh"


mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) master_1(),
master_2(),
master_3(),
slave_1();

mem_if_dv #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) master_dv_1(.aclk(aclk), .aresetn(aresetn)),
master_dv_2(.aclk(aclk), .aresetn(aresetn)),
master_dv_3(.aclk(aclk), .aresetn(aresetn)),
slave_dv_1(.aclk(aclk), .aresetn(aresetn));

logic aclk;
logic aresetn;

xmem_cross_rr #(
    .NUM_MASTERS(NUM_MASTERS)
) xmem_cross_rr_inst (
    .aclk(aclk),
    .aresetn(aresetn),

    .m_if('{
        master_1.master,
        master_2.master,
        master_3.master
    }),
    .s_if (slave_1.slave)
);

`XMEM_ASSIGN(master_1, master_dv_1);
`XMEM_ASSIGN(master_2, master_dv_2);
`XMEM_ASSIGN(master_3, master_dv_3);
`XMEM_ASSIGN(slave_dv_1, slave_1);

logic [DATA_WIDTH-1:0] read_data;
initial begin
    xmatser_1 = new(master_dv_1);
    xmatser_2 = new(master_dv_2);
    xmatser_3 = new(master_dv_3);

    fork
        begin
            xmatser_1.setup();
            xmatser_1.wait_ready();
            xmatser_1.write(32'h0, 32'hbada55e5);
            xmatser_1.read(32'h4, read_data);
            $display("read_data=%x", read_data);
        end
        begin
            xmatser_2.setup();
            xmatser_2.wait_ready();
            xmatser_2.write(32'h4, 32'h12345678);
            xmatser_2.read(32'h0, read_data);
            $display("read_data=%x", read_data);
        end
        begin
            xmatser_3.setup();
            xmatser_3.wait_ready();
            xmatser_3.write(32'h8, 32'hcafecafe);
            xmatser_3.write(32'h4, 32'hcafecafe);
            xmatser_3.read(32'h8, read_data);
            $display("read_data=%x", read_data);
        end
    join

    -> xmem_drv_done_event;

    repeat(2) @(posedge aclk);
    $finish();
end

initial begin
    xmemory = new(slave_dv_1);
    xmemory.setup();
    xmemory.wait_ready();
    fork
        forever begin
            xmemory.monitor();
        end
        begin
            @(xmem_drv_done_event);
            xmemory.print_mem();
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


endmodule