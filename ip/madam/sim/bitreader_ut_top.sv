`include "bitreader_types.svh"

`timescale 1ns/1ps

module bitreader_ut_top;

localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;
localparam TA = 2ns;
localparam TT = 8ns;

logic aclk;
logic aresetn;


logic [ADDR_WIDTH-1:0] attach_addr;
logic [DATA_WIDTH-1:0] bitrate;
logic [DATA_WIDTH-1:0] bitskip;
logic [DATA_WIDTH-1:0] data_out;
bitreader_op_e bitreader_op;
logic req, busy;

mem_if ps_memory();

initial begin
    aclk <= '0;
    aresetn <= '0;
    attach_addr <= '0;
    bitrate <= '0;
    bitskip <= '0;
    req = '0;
    bitreader_op <= BR_ATTACH;
end

initial begin
    repeat(16) @(posedge aclk);
    aresetn <= '1;
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

task setup_op (input bitreader_op_e op,
                input logic [ADDR_WIDTH-1:0] addr,
                input logic [DATA_WIDTH-1:0] _bitrate,
                input logic [DATA_WIDTH-1:0] _bitskip);

    bitreader_op <= #TA op;
    attach_addr <= #TA addr;
    bitrate <= #TA _bitrate;
    bitskip <= #TA _bitskip;
    req <= #TA '1;
    cycle_start();
    cycle_end();

    @(negedge busy);

    if (op == BR_READ) begin
        $display("Data Read : %x", data_out);
    end

endtask

// task _read (input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data);
//     wea <= #TA '0;
//     ena <= #TA '1;
//     addra <= #TA addr;
//     cycle_start();
//     data = douta;
//     cycle_end();
//     ena <= #TA '0;
//     addra <= #TA '0;

// endtask

logic [DATA_WIDTH-1:0] read_data;

initial begin
    read_data = '0;
    wait(aresetn)

    setup_op(BR_ATTACH, 32'h271bd0, 32'h0, 32'h0);
    setup_op(BR_SKIP, '0, '0, '0);
    setup_op(BR_READ, '0, 32'd6, '0);
    setup_op(BR_READ, '0, 32'd6, '0);
    setup_op(BR_SKIP, '0, '0, 32'd18);
    setup_op(BR_READ, '0, 32'd6, '0);
    setup_op(BR_READ, '0, 32'd6, '0);
    setup_op(BR_READ, '0, 32'd6, '0);
    setup_op(BR_READ, '0, 32'd6, '0);
    setup_op(BR_READ, '0, 32'd6, '0);
    setup_op(BR_READ, '0, 32'd6, '0);
    setup_op(BR_READ, '0, 32'd6, '0);
    setup_op(BR_READ, '0, 32'd6, '0);
    setup_op(BR_READ, '0, 32'd6, '0);

    #10
    $finish();
end

initial begin
    #2000
    $finish();
end

bitreader #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH))
            bitreader_top_inst (
                .aclk(aclk),
                .aresetn(aresetn),
                .memory(ps_memory.slave),
                .addr_in(attach_addr),
                .bitrate_in(bitrate),
                .bitskip_in(bitskip),
                .req(req),
                .op(bitreader_op),
                .ap_busy(busy),
                .data_out(data_out)
            );

always_comb begin
    unique case (ps_memory.addr)
        32'h0:      ps_memory.rsp_rdata = '0;
        32'h271bd0: ps_memory.rsp_rdata = 32'hd72b2ed6;
        32'h271bd4: ps_memory.rsp_rdata = 32'hcd72f74d;
        32'h271bd8: ps_memory.rsp_rdata = 32'h6ed65cb5;
        32'h271bdc: ps_memory.rsp_rdata = 32'hd6ba27de;
        32'h271be0: ps_memory.rsp_rdata = 32'hdd7debba;
        32'h271be4: ps_memory.rsp_rdata = 32'hb5ef9cb3;
        32'h271be8: ps_memory.rsp_rdata = 32'hd2ab31d6;
        32'h271bec: ps_memory.rsp_rdata = 32'hff75c65e;
        32'h271bf0: ps_memory.rsp_rdata = 32'h2fbf2d65;
        32'h271bf4: ps_memory.rsp_rdata = 32'h96ba35aa;
        32'h271bf8: ps_memory.rsp_rdata = 32'hbb75b2ab;
        32'h271bfc: ps_memory.rsp_rdata = 32'hf5968eb5;


        default: $fatal("address %x is not valid !", ps_memory.addr);
    endcase
end

assign ps_memory.gnt = '1;
assign ps_memory.rsp_valid = '1;
assign ps_memory.rsp_error = '0;

endmodule