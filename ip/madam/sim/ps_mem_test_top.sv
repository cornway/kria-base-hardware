
`timescale 1ns/1ps

`include "../synth/mcore_defs.svh"

module ps_mem_test_top;

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

endtask

task _read (input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data);
    wea <= #TA '0;
    ena <= #TA '1;
    addra <= #TA addr;
    cycle_start();
    data = douta;
    cycle_end();
    ena <= #TA '0;
    addra <= #TA '0;

endtask

logic [DATA_WIDTH-1:0] read_data;

initial begin
    read_data = '0;
    wait(aresetn)

    _write(M_REGS_ADDR + 32'h0, 32'h00550055);
    _write(M_REGS_ADDR + 32'h10, 32'h00aa00aa);
    _write(M_REGS_ADDR + 32'h18, 32'h00110011);

    _write(M_REGS_ADDR + 32'h100, 32'h12345678);

    _write(M_CEL_VARS_ADDR + 32'h0, 32'h12345678);
    _read(M_CEL_VARS_ADDR + 32'h0, read_data);
    $display("read_data = %x", read_data);

    _write(M_CEL_VARS_ADDR + 32'h40, 32'hcafecafe);
    _read(M_CEL_VARS_ADDR + 32'h40, read_data);
    $display("read_data = %x", read_data);

    _write(M_CEL_VARS_ADDR + 32'h80, 32'hdeaddead);
    _read(M_CEL_VARS_ADDR + 32'h80, read_data);
    $display("read_data = %x", read_data);

    _write(M_CEL_VARS_ADDR + 32'hc0, 32'hbeefbeef);
    _read(M_CEL_VARS_ADDR + 32'hc0, read_data);
    $display("read_data = %x", read_data);

    _write(M_UTIL_ADDR + 32'h0, 32'h7000_0000);
    _write(M_UTIL_ADDR + 32'h8, 32'h0000_0008);
    _write(M_UTIL_ADDR + 32'hc, 32'hcafe_0000);
    _write(M_UTIL_ADDR + 32'h4, 32'h0000_0001);
    @(posedge aclk)

    while (read_data[0] == '0) begin
        _read(M_UTIL_ADDR + 32'h0000_0004, read_data);
    end
    read_data = 0;

    _write(M_UTIL_ADDR + 32'hc, 32'hbeef_0000);
    _write(M_UTIL_ADDR + 32'h4, 32'h0000_0001);
    @(posedge aclk)

    while (read_data[0] == '0) begin
        _read(M_UTIL_ADDR + 32'h0000_0004, read_data);
    end

    @(posedge aclk)
    $finish();
end

always begin
    @(posedge aclk iff m_axi_wdata_valid)
    $display("m_axi_wdata = %x", m_axi_wdata);
end

initial begin
    #2000
    $finish();
end

mcore_top #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .AXI_ADDR_WIDTH(ADDR_WIDTH),
            .AXI_DATA_WIDTH(DATA_WIDTH))
            mcore_top_inst (
                .aclk(aclk),
                .aresetn(aresetn),
                .mr_clka(aclk),
                .mr_rsta(~aresetn),
                .mr_addra(addra),
                .mr_dina(dina),
                .mr_douta(douta),
                .mr_ena(ena),
                .mr_wea(wea),


    .m_axi_aw_addr(),
    .m_axi_aw_prot(),
    .m_axi_aw_valid(),
    .m_axi_w_data(m_axi_wdata),
    .m_axi_w_strb(),
    .m_axi_w_valid(m_axi_wdata_valid),
    .m_axi_b_ready(),
    .m_axi_ar_addr(),
    .m_axi_ar_prot(),
    .m_axi_ar_valid(),
    .m_axi_r_ready(),

    .m_axi_aw_ready('1),
    .m_axi_w_ready('1),
    .m_axi_b_resp('0),
    .m_axi_b_valid('1),
    .m_axi_ar_ready('1),
    .m_axi_r_data('0),
    .m_axi_r_resp('0),
    .m_axi_r_valid('1),

    .debug()

            );

endmodule