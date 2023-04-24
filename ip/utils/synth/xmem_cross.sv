

module xmem_cross_or #(
    parameter ADDR_WIDTH = 32'd32,
    parameter DATA_WIDTH = 32'd32,
    parameter NUM_MASTERS = 2
) (
    input wire aclk,
    input wire aresetn,

    mem_if.master m_if[NUM_MASTERS],

    mem_if.slave s_if
);

logic [NUM_MASTERS-1:0] req;
logic [ADDR_WIDTH-1:0] addr [NUM_MASTERS];
logic [DATA_WIDTH-1:0] wdata [NUM_MASTERS];
logic [NUM_MASTERS-1:0] we;
logic [DATA_WIDTH/8-1:0] be [NUM_MASTERS];

genvar i, j;
generate
    assign addr[0]  = m_if[0].addr;
    assign wdata[0] = m_if[0].wdata;
    assign be[0]    = m_if[0].be;
    assign req[0]   = m_if[0].req;
    assign we[0]    = m_if[0].we;

    for (i = 1; i < NUM_MASTERS; i++) begin
        assign addr[i]  = m_if[i].addr  | addr[i-1];
        assign wdata[i] = m_if[i].wdata | wdata[i-1];
        assign be[i]    = m_if[i].be    | be[i-1];

        assign req[i] = m_if[i].req;
        assign we[i] = m_if[i].we;
    end


    assign s_if.req = |req;
    assign s_if.wdata = wdata[NUM_MASTERS-1];
    assign s_if.addr = addr[NUM_MASTERS-1];
    assign s_if.be = be[NUM_MASTERS-1];
    assign s_if.we = |we;

    for (i = 0; i < NUM_MASTERS; i++) begin
        assign m_if[i].gnt = s_if.gnt;
        assign m_if[i].rsp_valid = s_if.rsp_valid;
        assign m_if[i].rsp_rdata = s_if.rsp_rdata;
        assign m_if[i].rsp_error = s_if.rsp_error;
    end
endgenerate

endmodule


module xmem_cross_rr #(
    parameter NUM_MASTERS = 2
) (
    input logic aclk,
    input logic aresetn,

    mem_if.master m_if[NUM_MASTERS],
    mem_if.slave s_if
);

logic [NUM_MASTERS-1:0] req;
logic [NUM_MASTERS-1:0] rel;
logic [$clog2(NUM_MASTERS)-1:0] select;
logic select_valid;

genvar i;
generate
for (i = 0; i < NUM_MASTERS; i++) begin
    assign req[i] = m_if[i].req;
    assign rel[i] = m_if[i].rsp_valid;
end
endgenerate

arbiter_RR #(
    .NUM_MASTERS(NUM_MASTERS)
) arbiter_RR_inst (
    .aclk(aclk),
    .aresetn(aresetn),

    .req_in(req),
    .gnt_out(),
    .release_in(rel),
    .select(select),
    .select_valid(select_valid)
);

xmem_master_mux #(
    .NUM_MASTERS(NUM_MASTERS)
) xmem_master_mux_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .select(select),

    .m_if(m_if),
    .s_if(s_if),
    .select_valid(select_valid)
);

endmodule