
module xmem_to_bram_wrapper #(
    parameter XDATA_WIDTH = 32'd32,
    parameter XADDR_WIDTH = 32'd32,

    parameter DATA_WIDTH = 32'd128,
    parameter ADDR_WIDTH = 32'd32,
    parameter BRAM_READ_LATENCY = 8
) (
    input wire aclk,
    input wire aresetn,

    //bram
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM CLK" *)
    output wire clka,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM RST" *)
    output wire rsta,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM ADDR" *)
    output wire [ADDR_WIDTH-1:0] addra,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM DIN" *)
    output wire [DATA_WIDTH-1:0] dina,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM DOUT" *)
    input wire [DATA_WIDTH-1:0] douta,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM EN" *)
    output wire ena,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM WE" *)
    output wire [DATA_WIDTH/8-1:0] wea,

    //xmem
    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM req" *)
    input wire xmem_req,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM addr" *)
    input wire [ADDR_WIDTH-1:0] xmem_addr,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM we" *)
    input wire xmem_we,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM wdata" *)
    input wire [XDATA_WIDTH-1:0] xmem_wdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM be" *)
    input wire [XDATA_WIDTH/8-1:0] xmem_be,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM gnt" *)
    output wire xmem_gnt,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM rsp_valid" *)
    output wire xmem_rsp_valid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM rsp_rdata" *)
    output wire [XDATA_WIDTH-1:0] xmem_rsp_rdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM rsp_error" *)
    output wire xmem_rsp_error,

    output wire [7:0] debug_out

);

assign clka = aclk;
assign rsta = ~aresetn;

xmem_to_bram #(
    .XDATA_WIDTH(XDATA_WIDTH),
    .XADDR_WIDTH(XADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .BRAM_READ_LATENCY(BRAM_READ_LATENCY)
) xmem_to_bram_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .bram_addra(addra),
    .bram_dina(dina),
    .bram_douta(douta),
    .bram_ena(ena),
    .bram_wea(wea),

    .xmem_req(xmem_req),
    .xmem_addr(xmem_addr),
    .xmem_we(xmem_we),
    .xmem_wdata(xmem_wdata),
    .xmem_be(xmem_be),
    .xmem_gnt(xmem_gnt),
    .xmem_rsp_valid(xmem_rsp_valid),
    .xmem_rsp_rdata(xmem_rsp_rdata),
    .xmem_rsp_error(xmem_rsp_error),
    .debug_out(debug_out)
);

endmodule