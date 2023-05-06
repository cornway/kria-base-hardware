
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

typedef Xmemory #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .RD_LATENCY(RD_LATENCY),
    .WR_LATENCY(WR_LATENCY),
    .MEMORY_DEPTH(MEMORY_DEPTH),
    .TT(TT),
    .TA(TA)
) Xmemory_t;

typedef logic [DATA_WIDTH-1:0] data_t;

localparam MEMORY_DEPTH_WORDS = (MEMORY_DEPTH*8) / DATA_WIDTH;

local logic [DATA_WIDTH-1:0] ram [MEMORY_DEPTH_WORDS];

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

function automatic set_memory(input string fpath);
    automatic int fd = $fopen(fpath, "rb");
    automatic integer i;

    $display("MEMORY_DEPTH_WORDS = %x", MEMORY_DEPTH_WORDS);
    if (!fd) begin
        $fatal("Couldnt open file \'%s\'", fpath);
    end

    $fread(ram, fd);
    $fclose(fd);

    for (i = 0; i < MEMORY_DEPTH_WORDS; i++) begin
        ram [i] = { <<8{ram[i]} };
    end
endfunction;

function automatic dump_memory(input string fpath);
    automatic int fd = $fopen(fpath, "wb");
    if (!fd) begin
        $fatal("Couldnt open file \'%s\'", fpath);
    end

    $fwrite(fd, "%u", ram);
    $fclose(fd);
endfunction

local task cycle_start;
    @(posedge xmem.aclk iff xmem.req);
endtask

local task cycle_end;
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
    ram = '{default: '0};
endtask

local function automatic logic [DATA_WIDTH-1:0] _get_data_mask(input logic [DATA_WIDTH/8-1:0] be);
    logic [DATA_WIDTH-1:0] mask = '0;
    for (integer i  = 0; i < DATA_WIDTH/8; i++) begin
        mask = mask | ({8{be[i]}} << (i * 8));
    end
    return mask;
endfunction

task automatic monitor ();

    automatic logic [ADDR_WIDTH-1:0] addr_w;
    automatic logic [DATA_WIDTH-1:0] wdata_mask;

    cycle_start();


    addr_w = xmem.addr / (DATA_WIDTH/8);
    if (addr_w >= MEMORY_DEPTH) begin
        $fatal(0, "xmem.addr exceeds memory capacity!");
    end

    xmem.rsp_rdata = ram [addr_w];

    $display("----------------------- Xmemory.monitor: addr = %x (words: %x), xmem.we=%x xmem.wdata=%x xmem.be=%x, xmem.rsp_rdata = %x",
                xmem.addr, addr_w, xmem.we, xmem.wdata, xmem.be, xmem.rsp_rdata);

    if (xmem.we) begin
        wdata_mask = _get_data_mask(xmem.be);
        ram [addr_w] = (xmem.wdata & wdata_mask) | (ram [addr_w] & ~wdata_mask);
        $display("ram [addr_w] = %x", ram [addr_w]);
    end

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

function integer cmp_mem(ref Xmemory_t xmem);
    integer i;
    integer err_count = 0;

    if (MEMORY_DEPTH_WORDS != xmem.MEMORY_DEPTH_WORDS)
        $fatal("Xmemory.cmp: memories size are different");

    for (i = 0; i < MEMORY_DEPTH_WORDS; i++) begin
        if (ram[i] != xmem.ram[i]) begin
            $display("Xmemory.mem_cmp: Memory content is different: addr=%x (words: %x) ram(%x) != xmem.ram[%x]",
                i*(DATA_WIDTH/8), i, ram[i], xmem.ram[i]);
                err_count++;
        end
    end
    return err_count;
endfunction

endclass

endpackage