`timescale 1ns/1ps

module xaxi_from_mem_wrapper #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter AXI_ADDR_WIDTH = 32'd32,
    parameter AXI_DATA_WIDTH = 32'd32
) (
    input wire aclk,
    input wire aresetn,

    input wire [AXI_ADDR_WIDTH-1:0] ps_mem_offset,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM req" *)
    input wire mem_req,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM addr" *)
    input wire [ADDR_WIDTH-1:0] mem_addr,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM we" *)
    input wire mem_we,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM wdata" *)
    input wire [DATA_WIDTH-1:0] mem_wdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM be" *)
    input wire [DATA_WIDTH/8-1:0] mem_be,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM gnt" *)
    output wire mem_gnt,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM rsp_valid" *)
    output wire mem_rsp_valid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM rsp_rdata" *)
    output wire [DATA_WIDTH-1:0] mem_rsp_rdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM rsp_error" *)
    output wire mem_rsp_error,

    //Req channel
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWADDR" *)
    output wire [AXI_ADDR_WIDTH-1:0] m00_axi_aw_addr,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWPROT" *)
    output wire [2:0] m00_axi_aw_prot,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWVALID" *)
    output wire m00_axi_aw_valid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WDATA" *)
    output wire [AXI_DATA_WIDTH-1:0] m00_axi_w_data,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WSTRB" *)
    output wire [AXI_DATA_WIDTH/8-1:0] m00_axi_w_strb,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WVALID" *)
    output wire m00_axi_w_valid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BREADY" *)
    output wire m00_axi_b_ready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARADDR" *)
    output wire [AXI_ADDR_WIDTH-1:0] m00_axi_ar_addr,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARPROT" *)
    output wire [2:0] m00_axi_ar_prot,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARVALID" *)
    output wire m00_axi_ar_valid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RREADY" *)
    output wire m00_axi_r_ready,

    //Resp channel
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWREADY" *)
    input wire m00_axi_aw_ready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WREADY" *)
    input wire m00_axi_w_ready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BRESP" *)
    input wire [1:0] m00_axi_b_resp,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BVALID" *)
    input wire m00_axi_b_valid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARREADY" *)
    input wire m00_axi_ar_ready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RDATA" *)
    input wire [AXI_DATA_WIDTH-1:0] m00_axi_r_data,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RRESP" *)
    input wire [1:0] m00_axi_r_resp,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RVALID" *)
    input wire m00_axi_r_valid


);

xaxi_from_mem #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
            .AXI_DATA_WIDTH(AXI_DATA_WIDTH))
            xaxi_from_mem_inst (

    .aclk(aclk),
    .aresetn(aresetn),

    .mem_req(mem_req),
    .mem_addr(mem_addr),
    .mem_we(mem_we),
    .mem_wdata(mem_wdata),
    .mem_be(mem_be),
    .mem_gnt(mem_gnt),
    .mem_rsp_valid(mem_rsp_valid),
    .mem_rsp_rdata(mem_rsp_rdata),
    .mem_rsp_error(mem_rsp_error),

    .m_axi_aw_addr(m00_axi_aw_addr | ps_mem_offset),
    .m_axi_aw_prot(m00_axi_aw_prot),
    .m_axi_aw_valid(m00_axi_aw_valid),
    .m_axi_w_data(m00_axi_w_data),
    .m_axi_w_strb(m00_axi_w_strb),
    .m_axi_w_valid(m00_axi_w_valid),
    .m_axi_b_ready(m00_axi_b_ready),
    .m_axi_ar_addr(m00_axi_ar_addr | ps_mem_offset),
    .m_axi_ar_prot(m00_axi_ar_prot),
    .m_axi_ar_valid(m00_axi_ar_valid),
    .m_axi_r_ready(m00_axi_r_ready),

    .m_axi_aw_ready(m00_axi_aw_ready),
    .m_axi_w_ready(m00_axi_w_ready),
    .m_axi_b_resp(m00_axi_b_resp),
    .m_axi_b_valid(m00_axi_b_valid),
    .m_axi_ar_ready(m00_axi_ar_ready),
    .m_axi_r_data(m00_axi_r_data),
    .m_axi_r_resp(m00_axi_r_resp),
    .m_axi_r_valid(m00_axi_r_valid)

            );

endmodule