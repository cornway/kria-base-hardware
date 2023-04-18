

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

endmodule