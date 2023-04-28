

module xmem_mux #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32
) (
    input wire aclk,
    input wire aresetn,

    //Master
    input wire                          m00_mem_req,
    input wire [ADDR_WIDTH-1:0]         m00_mem_addr,
    input wire                          m00_mem_we,
    input wire [DATA_WIDTH-1:0]         m00_mem_wdata,
    input wire [DATA_WIDTH/8-1:0]       m00_mem_be,

    output wire                         m00_mem_gnt,
    output wire                         m00_mem_rsp_valid,
    output wire [DATA_WIDTH-1:0]        m00_mem_rsp_rdata,
    output wire                         m00_mem_rsp_error,

    //Slave #0
    output wire                         s00_mem_req,
    output wire [ADDR_WIDTH-1:0]        s00_mem_addr,
    output wire                         s00_mem_we,
    output wire [DATA_WIDTH-1:0]        s00_mem_wdata,
    output wire [DATA_WIDTH/8-1:0]      s00_mem_be,

    input wire                          s00_mem_gnt,
    input wire                          s00_mem_rsp_valid,
    input wire [DATA_WIDTH-1:0]         s00_mem_rsp_rdata,
    input wire                          s00_mem_rsp_error,


    //Slave #1
    input wire                          s01_mem_req,
    input wire [ADDR_WIDTH-1:0]         s01_mem_addr,
    input wire                          s01_mem_we,
    input wire [DATA_WIDTH-1:0]         s01_mem_wdata,
    input wire [DATA_WIDTH/8-1:0]       s01_mem_be,

    input wire                          s01_mem_gnt,
    input wire                          s01_mem_rsp_valid,
    input wire [DATA_WIDTH-1:0]         s01_mem_rsp_rdata,
    input wire                          s01_mem_rsp_error,

    input wire slave_select
);

`define _M_ASSIGN(_sig) \
assign m00_mem_``_sig = slave_select ? s01_mem_``_sig : s00_mem_``_sig;

`define _S_ASSIGN(_sig) \
assign s00_mem_``_sig = slave_select ? '0 : m00_mem_``_sig; \
assign s01_mem_``_sig = slave_select ? m00_mem_``_sig : '0;

`_M_ASSIGN(gnt);
`_M_ASSIGN(rsp_valid);
`_M_ASSIGN(rsp_rdata);
`_M_ASSIGN(rsp_error);

`_S_ASSIGN(req);
`_S_ASSIGN(addr);
`_S_ASSIGN(we);
`_S_ASSIGN(wdata);
`_S_ASSIGN(be);

`undef _M_ASSIGN
`undef _S_ASSIGN

endmodule


module xmem_master_mux #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter NUM_MASTERS = 2
) (
    input wire aclk,
    input wire aresetn,

    /* Which master has access to the bus */
    input wire [$clog2(NUM_MASTERS)-1:0] select,

    /* Indicates if select is valid, otherwise no one has access to thee bus */
    input wire select_valid,

    mem_if.master m_if[NUM_MASTERS],

    mem_if.slave s_if
);

logic req[NUM_MASTERS];
logic [ADDR_WIDTH-1:0] addr[NUM_MASTERS];
logic we [NUM_MASTERS];
logic [DATA_WIDTH/8-1:0] be [NUM_MASTERS];
logic [DATA_WIDTH-1:0] wdata [NUM_MASTERS];

/* Note: select_valid is not used here, in order to let ongoing operations complete (receive response from the bus)
*/
`define _M_ASSIGN(_sig) \
assign m_if[i].``_sig = i == select ? s_if.``_sig : '0;

`define _I_ASSIGN(_sig) \
assign ``_sig[i] = m_if[i].``_sig;

`define _S_ASSIGN(_sig) \
assign s_if.``_sig = select_valid ? ``_sig[select] : '0;


genvar i;

generate

for (i = 0; i < NUM_MASTERS; i++) begin
    `_M_ASSIGN(gnt);
    `_M_ASSIGN(rsp_valid);
    `_M_ASSIGN(rsp_rdata);
    `_M_ASSIGN(rsp_error);

    `_I_ASSIGN(req);
    `_I_ASSIGN(addr);
    `_I_ASSIGN(we);
    `_I_ASSIGN(be);
    `_I_ASSIGN(wdata);

    `_S_ASSIGN(req);
    `_S_ASSIGN(addr);
    `_S_ASSIGN(we);
    `_S_ASSIGN(be);
    `_S_ASSIGN(wdata);
end

endgenerate

`undef _M_ASSIGN
`undef _S_ASSIGN

endmodule