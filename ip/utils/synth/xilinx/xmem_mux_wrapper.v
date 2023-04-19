

module xmem_mux_wrapper #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter ADDR_OFFSET = 32'h100000
) (
    input wire alck,
    input wire aresetn,


    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 M00_MEM req" *)
    input wire m00_mem_req,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 M00_MEM addr" *)
    input wire [ADDR_WIDTH-1:0] m00_mem_addr,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 M00_MEM we" *)
    input wire m00_mem_we,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 M00_MEM wdata" *)
    input wire [DATA_WIDTH-1:0] m00_mem_wdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 M00_MEM be" *)
    input wire [DATA_WIDTH/8-1:0] m00_mem_be,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 M00_MEM gnt" *)
    output wire m00_mem_gnt,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 M00_MEM rsp_valid" *)
    output wire m00_mem_rsp_valid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 M00_MEM rsp_rdata" *)
    output wire [DATA_WIDTH-1:0] m00_mem_rsp_rdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 M00_MEM rsp_error" *)
    output wire m00_mem_rsp_error,


    //Slave 00
    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S00_MEM req" *)
    output wire s00_mem_req,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S00_MEM addr" *)
    output wire [ADDR_WIDTH-1:0] s00_mem_addr,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S00_MEM we" *)
    output wire s00_mem_we,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S00_MEM wdata" *)
    output wire [DATA_WIDTH-1:0] s00_mem_wdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S00_MEM be" *)
    output wire [DATA_WIDTH/8-1:0] s00_mem_be,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S00_MEM gnt" *)
    input wire s00_mem_gnt,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S00_MEM rsp_valid" *)
    input wire s00_mem_rsp_valid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S00_MEM rsp_rdata" *)
    input wire [DATA_WIDTH-1:0] s00_mem_rsp_rdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S00_MEM rsp_error" *)
    input wire s00_mem_rsp_error,



    //Slave 01
    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S01_MEM req" *)
    output wire s01_mem_req,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S01_MEM addr" *)
    output wire [ADDR_WIDTH-1:0] s01_mem_addr,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S01_MEM we" *)
    output wire s01_mem_we,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S01_MEM wdata" *)
    output wire [DATA_WIDTH-1:0] s01_mem_wdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S01_MEM be" *)
    output wire [DATA_WIDTH/8-1:0] s01_mem_be,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S01_MEM gnt" *)
    input wire s01_mem_gnt,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S01_MEM rsp_valid" *)
    input wire s01_mem_rsp_valid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S01_MEM rsp_rdata" *)
    input wire [DATA_WIDTH-1:0] s01_mem_rsp_rdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 S01_MEM rsp_error" *)
    input wire s01_mem_rsp_error,

    output wire debug

);

xmem_mux #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem_mux_inst (

    .aclk(aclk),
    .aresetn(aresetn),

    .m00_mem_req(m00_mem_req),
    .m00_mem_addr(m00_mem_addr >= ADDR_OFFSET ? m00_mem_addr - ADDR_OFFSET : m00_mem_addr),
    .m00_mem_we(m00_mem_we),
    .m00_mem_wdata(m00_mem_wdata),
    .m00_mem_be(m00_mem_be),
    .m00_mem_gnt(m00_mem_gnt),
    .m00_mem_rsp_valid(m00_mem_rsp_valid),
    .m00_mem_rsp_rdata(m00_mem_rsp_rdata),
    .m00_mem_rsp_error(m00_mem_rsp_error),


    .s00_mem_req(s00_mem_req),
    .s00_mem_addr(s00_mem_addr),
    .s00_mem_we(s00_mem_we),
    .s00_mem_wdata(s00_mem_wdata),
    .s00_mem_be(s00_mem_be),
    .s00_mem_gnt(s00_mem_gnt),
    .s00_mem_rsp_valid(s00_mem_rsp_valid),
    .s00_mem_rsp_rdata(s00_mem_rsp_rdata),
    .s00_mem_rsp_error(s00_mem_rsp_error),


    .s01_mem_req(s01_mem_req),
    .s01_mem_addr(s01_mem_addr),
    .s01_mem_we(s01_mem_we),
    .s01_mem_wdata(s01_mem_wdata),
    .s01_mem_be(s01_mem_be),
    .s01_mem_gnt(s01_mem_gnt),
    .s01_mem_rsp_valid(s01_mem_rsp_valid),
    .s01_mem_rsp_rdata(s01_mem_rsp_rdata),
    .s01_mem_rsp_error(s00_mem_rsp_error),

    .slave_select(m00_mem_addr >= ADDR_OFFSET)
);

assign debug = m00_mem_addr >= ADDR_OFFSET;

endmodule