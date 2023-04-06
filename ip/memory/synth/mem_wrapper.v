

module memory_wrapper #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (

    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME PORTA, MEM_ECC NONE, MASTER_TYPE BRAM_CTRL, READ_WRITE_MODE READ_WRITE, READ_LATENCY 2" *)

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTA CLK" *)
    input wire clka,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTA RST" *)
    input wire rsta,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTA ADDR" *)
    input wire [ADDR_WIDTH-1:0] addra,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTA DIN" *)
    input wire [DATA_WIDTH-1:0] dina,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTA DOUT" *)
    output wire [DATA_WIDTH-1:0] douta,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTA EN" *)
    input wire ena,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTA WE" *)
    input wire [DATA_WIDTH/8-1:0] wea,


    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME PORTB, MEM_ECC NONE, MASTER_TYPE BRAM_CTRL, READ_WRITE_MODE READ_WRITE, READ_LATENCY 2" *)

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTB CLK" *)
    input wire clkb,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTB RST" *)
    input wire rstb,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTB ADDR" *)
    input wire [ADDR_WIDTH-1:0] addrb,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTB DIN" *)
    input wire [DATA_WIDTH-1:0] dinb,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTB DOUT" *)
    output wire [DATA_WIDTH-1:0] doutb,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTB EN" *)
    input wire enb,

    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 PORTB WE" *)
    input wire [DATA_WIDTH/8-1:0] web


);

ram_infra #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) ram_infra_inst (
    .clka(clka),
    .rsta(rsta),
    .addra(addra),
    .dina(dina),
    .douta(douta),
    .ena(ena),
    .wea(wea),

    .clkb(clkb),
    .rstb(rstb),
    .addrb(addrb),
    .dinb(dinb),
    .doutb(doutb),
    .enb(enb),
    .web(web)
);


endmodule