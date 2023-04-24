
`timescale 1ns/1ps

package xmem_pkg;

class XmemDriver #(
    parameter TT = 8ns,
    parameter TA = 2ns,
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32
);

virtual mem_if_dv #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem;

function new (virtual mem_if_dv #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) xmem );
    this.xmem  = xmem;
endfunction

task cycle_start;
    #TT;
endtask

task cycle_wr_end;
    @(posedge xmem.aclk iff xmem.rsp_valid);
endtask

task cycle_rd_end;
    wait(xmem.rsp_valid);
endtask

task cycle_gnt_wait;
    wait(xmem.gnt);
endtask

task wait_ready();
    wait (xmem.aresetn);
endtask

task setup();
    xmem.req = '0;
    xmem.we = '0;
    xmem.be = '0;
    xmem.addr = '0;
    xmem.wdata = '0;
endtask

task automatic write (input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
    xmem.req <= #TA '1;
    xmem.we <= #TA '1;
    xmem.be <= #TA '1;
    xmem.addr <= #TA addr;
    xmem.wdata <= #TA data;
    cycle_gnt_wait();
    cycle_start();
    cycle_wr_end();
    xmem.req <= #TA '0;
    xmem.we <= #TA '0;
    xmem.be <= #TA '0;
    xmem.addr <= #TA '0;
    xmem.wdata <= #TA '0;
    //@(posedge xmem.aclk);
endtask

task automatic read (input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data);
    xmem.req <= #TA '1;
    xmem.we <= #TA '0;
    xmem.be <= #TA '0;
    xmem.addr <= #TA addr;
    xmem.wdata <= #TA '0;
    cycle_gnt_wait();
    cycle_start();
    cycle_rd_end();
    data = xmem.rsp_rdata;
    xmem.req <= #TA '0;
    xmem.addr <= #TA '0;
endtask

endclass

class Xmemory #(
    parameter TT = 8ns,
    parameter TA = 2ns,
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter RD_LATENCY = 32'd2,
    parameter WR_LATENCY = 32'd0,
    parameter MEMORY_DEPTH = 32'd15
);

logic [DATA_WIDTH-1:0] ram [MEMORY_DEPTH];

virtual mem_if_dv #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem;

function new (virtual mem_if_dv #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) xmem );
    this.xmem  = xmem;
endfunction

task cycle_start;
    @(posedge xmem.aclk iff xmem.req);
endtask

task cycle_end;
    @(posedge xmem.aclk);
endtask

task wait_ready();
    wait (xmem.aresetn);
endtask

task setup();
    xmem.rsp_valid = '0;
    xmem.rsp_error = '0;
    xmem.rsp_rdata = '0;
    xmem.gnt = '0;
endtask

task automatic monitor ();

    automatic logic [ADDR_WIDTH-1:0] addr_w;


    cycle_start();

    addr_w = xmem.addr / (DATA_WIDTH/8);
    if (addr_w >= MEMORY_DEPTH) begin
        $fatal(0, "xmem.addr exceeds memory capacity!");
    end

    $display("Xmemory addr_w = %x, xmem.we=%x xmem.wdata=%x", addr_w, xmem.we, xmem.wdata);

    xmem.rsp_rdata = ram [addr_w];
    if (xmem.we)
        ram [addr_w] = xmem.wdata;


    xmem.gnt <= #TA '1;

    if (xmem.we) begin
        repeat(WR_LATENCY) @(posedge xmem.aclk);
    end else begin
        repeat(RD_LATENCY) @(posedge xmem.aclk);
    end

    xmem.rsp_valid <= #TA '1;
    xmem.rsp_error <= #TA '0;

    cycle_end();

    xmem.rsp_valid <= #TA '0;
    xmem.rsp_error <= #TA '0;
    xmem.rsp_rdata <= #TA '0;
    xmem.gnt <= #TA '0;
endtask

function print_mem();
    $display("=== Memory content ===");
    foreach (ram[i])
        $display("ram[%d] = %x", i, ram[i]);
    $display("=== Memory content ===");
endfunction

endclass

endpackage