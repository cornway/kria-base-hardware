

module xmem_wconvert #(
    parameter DATA_WIDTH_IN = 32'd32,
    parameter DATA_WIDTH_OUT = 32'd32,
    parameter ADDR_WIDTH = 32'd32
) (
    mem_if.slave s_if,
    mem_if.master m_if
);

localparam ADDR_OUT_MASK = (1 << $clog2(DATA_WIDTH_OUT/8)) - 1;
localparam DATA_IN_MASK = (1 << DATA_WIDTH_IN) - 1;

wire [ $clog2(DATA_WIDTH_OUT/8) - $clog2(DATA_WIDTH_IN/8) - 1 : 0 ] lsb_msb_sel;

assign lsb_msb_sel = m_if.addr[$clog2(DATA_WIDTH_OUT/8) -1 : $clog2(DATA_WIDTH_IN/8)];

generate
    if (DATA_WIDTH_OUT / DATA_WIDTH_IN > 1) begin

        assign s_if.wdata          = m_if.wdata << (lsb_msb_sel * DATA_WIDTH_IN);
        assign m_if.rsp_rdata      = (s_if.rsp_rdata >> (lsb_msb_sel * DATA_WIDTH_IN)) & DATA_IN_MASK;
        assign s_if.be             = m_if.be << (lsb_msb_sel * (DATA_WIDTH_IN/8));

    end else if (DATA_WIDTH_OUT / DATA_WIDTH_IN == 1) begin

        assign s_if.wdata           = m_if.wdata;
        assign m_if.rsp_rdata       = s_if.rsp_rdata;
        assign s_if.be              = m_if.be;

    end else begin
        $fatal("Down conversion is not supported yet");
    end
endgenerate

assign s_if.req = m_if.req;
assign s_if.addr = m_if.addr & (~ADDR_OUT_MASK);
assign s_if.we = m_if.we;

assign m_if.gnt = s_if.gnt;
assign m_if.rsp_valid = s_if.rsp_valid;
assign m_if.rsp_error = s_if.rsp_error;

endmodule

