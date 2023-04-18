
`timescale 1ns/1ps

module xmem_bram_ut_top;

localparam ADDR_WIDTH = 32'd32;
localparam DATA_WIDTH = 32'd128;
localparam XADDR_WIDTH = 32'd32;
localparam XDATA_WIDTH = 32'd32;
localparam BRAM_READ_LATENCY = 2;

localparam TA = 2ns;
localparam TT = 8ns;


logic aclk;
logic aresetn;

//BRAM interface
logic [ADDR_WIDTH-1:0] bram_addra;
logic [DATA_WIDTH-1:0] bram_dina;
logic [DATA_WIDTH-1:0] bram_douta;
logic bram_ena;
logic [DATA_WIDTH/8-1:0] bram_wea;

//Memory interface
logic                     xmem_req;
logic [XADDR_WIDTH-1:0]    xmem_addr;
logic                     xmem_we;
logic [XDATA_WIDTH-1:0]    xmem_wdata;
logic [XDATA_WIDTH/8-1:0]  xmem_be;

logic                      xmem_gnt;
logic                      xmem_rsp_valid;
logic [XDATA_WIDTH-1:0]     xmem_rsp_rdata;
logic                      xmem_rsp_error;


xmem_to_bram #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .XADDR_WIDTH(XADDR_WIDTH),
    .XDATA_WIDTH(XDATA_WIDTH),
    .BRAM_READ_LATENCY(BRAM_READ_LATENCY)
) xmem_to_bram_inst (
    .*
);

logic [XDATA_WIDTH-1:0] read_data;
initial begin
    wait(aresetn);

    _write(32'h0, 32'h01234567);
    _write(32'h4, 32'h89abcdef);
    _write(32'h8, 32'hfedcba98);
    _write(32'hc, 32'h76543210);

    _read(32'h0, read_data);
    _read(32'h4, read_data);
    _read(32'h8, read_data);
    _read(32'hc, read_data);

    repeat(2) @(posedge aclk);
    $finish();
end

initial begin
    fork
        begin
            aclk = '0;
            aresetn = '0;
            xmem_req = '0;
            xmem_addr = '0;
            xmem_we = '0;
            xmem_wdata = '0;
            xmem_be = '0;
        end
        begin
            repeat(16) @(posedge aclk);
            aresetn = '1;
        end
    join
end

always begin
    #10 aclk <= ~aclk;
end

task cycle_start;
    #TT;
endtask

task cycle_end;
    @(posedge aclk);
endtask

task _write (input logic [XADDR_WIDTH-1:0] addr, input logic [XDATA_WIDTH-1:0] data);
    xmem_req <= #TA '1;
    xmem_we <= #TA '1;
    xmem_be <= #TA '1;
    xmem_wdata <= #TA data;
    xmem_addr <= #TA addr;

    @(posedge aclk iff xmem_rsp_valid);

    xmem_req <= #TA '0;
    xmem_we <= #TA '0;
    xmem_be <= #TA '0;
    xmem_wdata <= #TA '0;
    xmem_addr <= #TA '0;

    @(posedge aclk);

endtask

task _read (input logic [XADDR_WIDTH-1:0] addr, output logic [XDATA_WIDTH-1:0] data);
    xmem_req <= #TA '1;
    xmem_addr <= #TA addr;
    cycle_start();
    cycle_end();

    @(posedge aclk iff xmem_rsp_valid);

    data = xmem_rsp_rdata;
    $display("_read: addr=%x data=%x", addr, data);

    xmem_req <= #TA '0;
    xmem_we <= #TA '0;
    xmem_be <= #TA '0;
    xmem_wdata <= #TA '0;
    xmem_addr <= #TA '0;

    @(posedge aclk);
endtask

logic [DATA_WIDTH-1:0] ram[15];

always_comb begin
    if (bram_ena) begin
        bram_douta = ram[bram_addra];
    end
end

genvar i;

generate

for (i = 0; i < DATA_WIDTH/8; i++) begin

    always_ff @(posedge aclk) begin
        if (bram_ena && bram_wea) begin
            if (bram_wea[i]) begin
                ram[bram_addra][ 8*(i+1) - 1 : i*8 ] <= bram_dina [ 8*(i+1) - 1 : i*8 ];
            end
        end

    end
end

endgenerate

endmodule