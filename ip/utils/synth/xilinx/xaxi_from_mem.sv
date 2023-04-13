`timescale 1ns/1ps

`include "typedef.svh"

module xaxi_from_mem #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,

    AXI_ADDR_WIDTH = 32'd32,
    AXI_DATA_WIDTH = 32'd32,
    AXI_ID_WIDTH = 1,
    AXI_USER_WIDTH = 1
) (

    input wire aclk,
    input wire aresetn,

    //Memory interface
    input wire mem_req,
    input wire [ADDR_WIDTH-1:0] mem_addr,
    input wire mem_we,
    input wire [DATA_WIDTH-1:0] mem_wdata,
    input wire [DATA_WIDTH/8-1:0] mem_be,

    output wire mem_gnt,
    output wire mem_rsp_valid,
    output wire [DATA_WIDTH-1:0] mem_rsp_rdata,
    output wire mem_rsp_error,

    //Req channel
    output wire [AXI_ADDR_WIDTH-1:0] m_axi_aw_addr,
    output wire [2:0] m_axi_aw_prot,
    output wire m_axi_aw_valid,
    output wire [AXI_DATA_WIDTH-1:0] m_axi_w_data,
    output wire [AXI_DATA_WIDTH/8-1:0] m_axi_w_strb,
    output wire m_axi_w_valid,
    output wire m_axi_b_ready,
    output wire [AXI_ADDR_WIDTH-1:0] m_axi_ar_addr,
    output wire [2:0] m_axi_ar_prot,
    output wire m_axi_ar_valid,
    output wire m_axi_r_ready,

    //Resp channel
    input wire m_axi_aw_ready,
    input wire m_axi_w_ready,
    input wire [1:0] m_axi_b_resp,
    input wire m_axi_b_valid,
    input wire m_axi_ar_ready,
    input wire [AXI_DATA_WIDTH-1:0] m_axi_r_data,
    input wire [1:0] m_axi_r_resp,
    input wire m_axi_r_valid
);

`AXI_LITE_TYPEDEF_ALL(axi_lite, logic [AXI_ADDR_WIDTH-1:0], logic [AXI_DATA_WIDTH-1:0], logic [AXI_DATA_WIDTH/8-1:0])
axi_lite_req_t axi_lite_req;
axi_lite_resp_t axi_lite_rsp;

  axi_lite_from_mem #(
    .MemAddrWidth    ( ADDR_WIDTH        ),
    .AxiAddrWidth    ( AXI_ADDR_WIDTH    ),
    .DataWidth       ( DATA_WIDTH        ),
    .MaxRequests     ( 32'd2             ),
    .AxiProt         ( 32'b010           ),
    .axi_req_t       ( axi_lite_req_t    ),
    .axi_rsp_t       ( axi_lite_resp_t   )
  ) i_axi_lite_from_mem (
    .clk_i          (aclk),
    .rst_ni         (aresetn),
    .mem_req_i      (mem_req),
    .mem_addr_i     (mem_addr),
    .mem_we_i       (mem_we),
    .mem_wdata_i    (mem_wdata),
    .mem_be_i       (mem_be),
    .mem_gnt_o      (mem_gnt),
    .mem_rsp_valid_o(mem_rsp_valid),
    .mem_rsp_rdata_o(mem_rsp_rdata),
    .mem_rsp_error_o(mem_rsp_error),
    .axi_req_o       ( axi_lite_req    ),
    .axi_rsp_i       ( axi_lite_rsp    )
  );



    //Req channel
    assign m_axi_aw_addr = axi_lite_req.aw.addr;
    assign m_axi_aw_prot = axi_lite_req.aw.prot;
    assign m_axi_aw_valid = axi_lite_req.aw_valid;
    assign m_axi_w_data = axi_lite_req.w.data;
    assign m_axi_w_strb = axi_lite_req.w.strb;
    assign m_axi_w_valid = axi_lite_req.w_valid;
    assign m_axi_b_ready = axi_lite_req.b_ready;
    assign m_axi_ar_addr = axi_lite_req.ar.addr;
    assign m_axi_ar_prot = axi_lite_req.ar.prot;
    assign m_axi_ar_valid = axi_lite_req.ar_valid;
    assign m_axi_r_ready = axi_lite_req.r_ready;

    //Resp channel
    assign axi_lite_rsp.aw_ready = m_axi_aw_ready;
    assign axi_lite_rsp.w_ready = m_axi_w_ready;
    assign axi_lite_rsp.b.resp = m_axi_b_resp;
    assign axi_lite_rsp.b_valid = m_axi_b_valid;
    assign axi_lite_rsp.ar_ready = m_axi_ar_ready;
    assign axi_lite_rsp.r.data = m_axi_r_data;
    assign axi_lite_rsp.r.resp = m_axi_r_resp;
    assign axi_lite_rsp.r_valid = m_axi_r_valid;


endmodule