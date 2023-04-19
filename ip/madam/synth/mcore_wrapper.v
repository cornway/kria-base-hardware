`timescale 1ns/1ps

module mcore_top_wrapper #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32
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

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM req" *)
    output wire mem_req,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM addr" *)
    output wire [ADDR_WIDTH-1:0] mem_addr,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM we" *)
    output wire mem_we,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM wdata" *)
    output wire [DATA_WIDTH-1:0] mem_wdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM be" *)
    output wire [DATA_WIDTH/8-1:0] mem_be,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM gnt" *)
    input wire mem_gnt,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM rsp_valid" *)
    input wire mem_rsp_valid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM rsp_rdata" *)
    input wire [DATA_WIDTH-1:0] mem_rsp_rdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:xmem:1.0 MEM rsp_error" *)
    input wire mem_rsp_error,

    output wire [ADDR_WIDTH-1:0] ps_mem_offset_out,

    output wire [63:0] debug_port

);

mcore_top #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH))
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

                .mem_req(mem_req),
                .mem_addr(mem_addr),
                .mem_we(mem_we),
                .mem_wdata(mem_wdata),
                .mem_be(mem_be),
                .mem_gnt(mem_gnt),
                .mem_rsp_valid(mem_rsp_valid),
                .mem_rsp_rdata(mem_rsp_rdata),
                .mem_rsp_error(mem_rsp_error),

                .ps_mem_offset_out(ps_mem_offset_out),

                .debug_port(debug_port)
            );

endmodule