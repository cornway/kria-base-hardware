

module mcore_top_wrapper #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter AXI_ADDR_WIDTH = 32'd32,
    parameter AXI_DATA_WIDTH = 32'd32
) (

    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME MREGS, MEM_ECC NONE, MASTER_TYPE BRAM_CTRL, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1" *)

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 MREGS CLK" *)
    input wire clka,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 MREGS RST" *)
    input wire rsta,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 MREGS ADDR" *)
    input wire [ADDR_WIDTH-1:0] addra,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 MREGS DIN" *)
    input wire [DATA_WIDTH-1:0] dina,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 MREGS DOUT" *)
    output wire [DATA_WIDTH-1:0] douta,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 MREGS EN" *)
    input wire ena,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 MREGS WE" *)
    input wire [DATA_WIDTH/8-1:0] wea,

    input wire aclk,
    input wire aresetn,

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
    input wire m00_axi_r_valid,


    output wire [31:0] debug

);

mcore_top #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
            .AXI_DATA_WIDTH(AXI_DATA_WIDTH))
            mcore_top_inst (
                .aclk(aclk),
                .aresetn(aresetn),
                .mr_clka(clka),
                .mr_rsta(rsta),
                .mr_addra(addra),
                .mr_dina(dina),
                .mr_douta(douta),
                .mr_ena(ena),
                .mr_wea(wea),


    .m_axi_aw_addr(m00_axi_aw_addr),
    .m_axi_aw_prot(m00_axi_aw_prot),
    .m_axi_aw_valid(m00_axi_aw_valid),
    .m_axi_w_data(m00_axi_w_data),
    .m_axi_w_strb(m00_axi_w_strb),
    .m_axi_w_valid(m00_axi_w_valid),
    .m_axi_b_ready(m00_axi_b_ready),
    .m_axi_ar_addr(m00_axi_ar_addr),
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
    .m_axi_r_valid(m00_axi_r_valid),

    .debug(debug)

            );

endmodule