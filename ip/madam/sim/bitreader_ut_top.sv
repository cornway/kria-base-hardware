
`timescale 1ns/1ps

`include "../synth/mcore_defs.svh"

module bitreader_ut_top;

localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 32;
localparam TA = 2ns;
localparam TT = 8ns;

logic aclk;
logic aresetn;
logic [ADDR_WIDTH-1:0] addra;
logic [DATA_WIDTH-1:0] dina;
logic [DATA_WIDTH-1:0] douta;
logic ena;
logic [DATA_WIDTH/8-1:0] wea;

logic [DATA_WIDTH-1:0] m_axi_wdata;
logic m_axi_wdata_valid;

initial begin
    aclk <= '0;
    aresetn <= '0;
    addra <= '0;
    dina <= '0;
    ena <= '0;
    wea <= '0;
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

task _write (input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
    wea <= #TA '1;
    ena <= #TA '1;
    dina <= #TA data;
    addra <= #TA addr;
    cycle_start();
    cycle_end();
    wea <= #TA '0;
    ena <= #TA '0;
    dina <= #TA '0;
    addra <= #TA '0;

    repeat(6) @(posedge aclk);

endtask

task _read (input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data);
    wea <= #TA '0;
    ena <= #TA '1;
    addra <= #TA addr;
    cycle_start();
    cycle_end();
    cycle_start();
    data = douta;
    cycle_end();
    ena <= #TA '0;
    addra <= #TA '0;

endtask

task _wait_ready ();
    automatic logic [DATA_WIDTH-1:0] read_data = 0;

    _read(M_UTIL_ADDR + 32'h8, read_data);
    while (read_data) begin
        _read(M_UTIL_ADDR + 32'h8, read_data);
    end
endtask

task _attach_buffer (input logic [ADDR_WIDTH-1:0] addr);
    _write(M_UTIL_ADDR + 32'h4, addr);
    _wait_ready();
endtask

task _skip (input logic [7:0] bitrate);
    _write(M_UTIL_ADDR + 32'h8, {8'h0, bitrate, bitrate, 8'h1});
    _wait_ready();
endtask

task _read_data (input logic [7:0] bitrate, output logic [DATA_WIDTH-1:0] data);
    _write(M_UTIL_ADDR + 32'h8, {8'h0, bitrate, bitrate, 8'h2});
    _wait_ready();
    _read(M_UTIL_ADDR + 32'hc, data);
    $display("********* _read_data = %x", data);
endtask

logic [DATA_WIDTH-1:0] read_data;

initial begin
    read_data = '0;
    wait(aresetn);

    // _attach_buffer(32'h271bd0);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _skip(8'd60);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);
    // _skip(8'd12);
    // _read_data(8'h6, read_data);
    // _read_data(8'h6, read_data);

    _attach_buffer(32'ha8f78);
    _read_data(8'h8, read_data);
    _read_data(8'h8, read_data);
    _read_data(8'h6, read_data);
    _read_data(8'h8, read_data);
    _read_data(8'h6, read_data);
    _read_data(8'h8, read_data);
    _read_data(8'h6, read_data);
    _read_data(8'h6, read_data);
    _read_data(8'h6, read_data);
    _read_data(8'h6, read_data);
    _read_data(8'h6, read_data);
    _read_data(8'h6, read_data);
    _read_data(8'h6, read_data);
    _read_data(8'h6, read_data);
    _read_data(8'h8, read_data);

    #100;
    @(posedge aclk)
    $finish();
end

always begin
    @(posedge aclk iff m_axi_wdata_valid)
    $display("m_axi_wdata = %x", m_axi_wdata);
end

initial begin
    #20000
    $finish();
end

mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) ps_mem();

logic [ADDR_WIDTH-1:0] m00_axi_ar_addr;
logic [DATA_WIDTH-1:0] m00_axi_r_data_reg, m00_axi_r_data_next;

xaxi_from_mem_wrapper #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .AXI_ADDR_WIDTH(ADDR_WIDTH),
            .AXI_DATA_WIDTH(DATA_WIDTH))
xaxi_from_mem_wrapper_inst (
    .aclk(aclk),
    .aresetn(aresetn),

    .mem_req(ps_mem.req),
    .mem_addr(ps_mem.addr),
    .mem_we(ps_mem.we),
    .mem_wdata(ps_mem.wdata),
    .mem_be(ps_mem.be),
    .mem_gnt(ps_mem.gnt),
    .mem_rsp_valid(ps_mem.rsp_valid),
    .mem_rsp_rdata(ps_mem.rsp_rdata),
    .mem_rsp_error(ps_mem.rsp_error),

    .m00_axi_aw_addr(),
    .m00_axi_aw_prot(),
    .m00_axi_aw_valid(),
    .m00_axi_w_data(m_axi_wdata),
    .m00_axi_w_strb(),
    .m00_axi_w_valid(m_axi_wdata_valid),
    .m00_axi_b_ready(),
    .m00_axi_ar_addr(m00_axi_ar_addr),
    .m00_axi_ar_prot(),
    .m00_axi_ar_valid(),
    .m00_axi_r_ready(),

    .m00_axi_aw_ready('1),
    .m00_axi_w_ready('1),
    .m00_axi_b_resp('0),
    .m00_axi_b_valid('1),
    .m00_axi_ar_ready('1),
    .m00_axi_r_data(m00_axi_r_data_reg),
    .m00_axi_r_resp('0),
    .m00_axi_r_valid('1)
);

always_ff @(posedge aclk) begin
    if (!aresetn)
        m00_axi_r_data_reg <= '0;
    else
        m00_axi_r_data_reg <= m00_axi_r_data_next;
end

always_comb begin
    unique case (m00_axi_ar_addr)
        32'h271bd0: m00_axi_r_data_next = 32'hd72b2ed6;
        32'h271bd4: m00_axi_r_data_next = 32'hcd72f74d;
        32'h271bd8: m00_axi_r_data_next = 32'h6ed65cb5;
        32'h271bdc: m00_axi_r_data_next = 32'hd6ba27de;
        32'h271be0: m00_axi_r_data_next = 32'hdd7debba;
        32'h271be4: m00_axi_r_data_next = 32'hb5ef9cb3;
        32'h271be8: m00_axi_r_data_next = 32'hd2ab31d6;
        32'h271bec: m00_axi_r_data_next = 32'hff75c65e;
        32'h271bf0: m00_axi_r_data_next = 32'h2fbf2d65;
        32'h271bf4: m00_axi_r_data_next = 32'h96ba35aa;
        32'h271bf8: m00_axi_r_data_next = 32'hbb75b2ab;
        32'h271bfc: m00_axi_r_data_next = 32'hf5968eb5;


        32'ha8f78: m00_axi_r_data_next = 32'h2409f96;
        32'ha8f7c: m00_axi_r_data_next = 32'ha47aebaa;
        32'ha8f80: m00_axi_r_data_next = 32'hb9e387d8;
        32'ha8f84: m00_axi_r_data_next = 32'h70000000;


        default: begin
            m00_axi_r_data_next = m00_axi_r_data_reg;
        end
    endcase
end

mcore_top_wrapper #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .AXI_ADDR_WIDTH(ADDR_WIDTH),
            .AXI_DATA_WIDTH(DATA_WIDTH))
    mcore_top_wrapper_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .clka(aclk),
        .rsta(~aresetn),
        .addra(addra),
        .dina(dina),
        .douta(douta),
        .ena(ena),
        .wea(wea),

        .mem_req(ps_mem.req),
        .mem_addr(ps_mem.addr),
        .mem_we(ps_mem.we),
        .mem_wdata(ps_mem.wdata),
        .mem_be(ps_mem.be),
        .mem_gnt(ps_mem.gnt),
        .mem_rsp_valid(ps_mem.rsp_valid),
        .mem_rsp_rdata(ps_mem.rsp_rdata),
        .mem_rsp_error(ps_mem.rsp_error)
    );

endmodule