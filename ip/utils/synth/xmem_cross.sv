

module xmem_cross_or #(
    parameter ADDR_WIDTH = 32'd32,
    parameter DATA_WIDTH = 32'd32,
    parameter NUM_MASTERS = 2
) (
    input wire aclk,
    input wire aresetn,

    mem_if m_if[NUM_MASTERS],

    mem_if s_if
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