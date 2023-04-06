

interface ram_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
);
    logic clk;
    logic ena;
    logic enb;
    logic wea;
    logic web;

    logic [ADDR_WIDTH-1:0] addra;
    logic [ADDR_WIDTH-1:0] addrb;

    logic [DATA_WIDTH-1:0] dia;
    logic [DATA_WIDTH-1:0] doa;
    logic [DATA_WIDTH-1:0] dib;
    logic [DATA_WIDTH-1:0] dob;

    modport slave (
        input clk, ena, enb, wea, web, addra, addrb, dia, dib,
        output doa, dob
    );

    modport master (
        output clk, ena, enb, wea, web, addra, addrb, dia, dib,
        input doa, dob
    );

endinterface //ram_if

module ram_wrapper #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64,
    parameter RAM_STYLE = "mixed",
    parameter RAM_SIZE = 1024,
    parameter READ_LATENCY = 2
) (
    ram_if ramif
);

localparam DATA_WIDTH_BYTES = DATA_WIDTH/8;

(* ram_style = RAM_STYLE *) reg [DATA_WIDTH-1:0] ram [ RAM_SIZE / DATA_WIDTH_BYTES ];

reg [DATA_WIDTH-1:0] dob_reg[READ_LATENCY];
reg [DATA_WIDTH-1:0] doa_reg[READ_LATENCY];

wire [ADDR_WIDTH-$clog2(DATA_WIDTH_BYTES)-1:0] addra_w;
wire [ADDR_WIDTH-$clog2(DATA_WIDTH_BYTES)-1:0] addrb_w;

assign addra_w = ramif.addra >> $clog2(DATA_WIDTH_BYTES);
assign addrb_w = ramif.addrb >> $clog2(DATA_WIDTH_BYTES);

integer i;

always_ff @(posedge ramif.clk) begin
    if (ramif.ena) begin
        if (ramif.wea) begin
            ram[addra_w] <= ramif.dia;
        end
    end else if (ramif.enb) begin
        if (ramif.web) begin
            ram[addrb_w] <= ramif.dib;
        end
    end
end

always_ff @(posedge ramif.clk) begin
    if (ramif.ena) begin
        doa_reg[0] <= ram[addra_w];
    end
    if (ramif.enb) begin
        dob_reg[0] <= ram[addrb_w];
    end
end

always_ff @(posedge ramif.clk) begin

    for (i = 1; i < READ_LATENCY; i++) begin
        doa_reg[i] <= doa_reg[i-1];
    end

    for (i = 1; i < READ_LATENCY; i++) begin
        dob_reg[i] <= dob_reg[i-1];
    end
end

assign ramif.dob = dob_reg[READ_LATENCY-1];
assign ramif.doa = doa_reg[READ_LATENCY-1];

endmodule


module ram_infra #(
    parameter RAM_SIZE = 1024 * 512,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
) (
    input wire clka,
    input wire rsta,
    input wire [ADDR_WIDTH-1:0] addra,
    input wire [DATA_WIDTH-1:0] dina,
    output wire [DATA_WIDTH-1:0] douta,
    input wire ena,
    input wire [DATA_WIDTH/8-1:0] wea,

    input wire clkb,
    input wire rstb,
    input wire [ADDR_WIDTH-1:0] addrb,
    input wire [DATA_WIDTH-1:0] dinb,
    output wire [DATA_WIDTH-1:0] doutb,
    input wire enb,
    input wire [DATA_WIDTH/8-1:0] web

);

//localparam ADDR_WIDTH = $clog2(RAM_SIZE);

ram_if #(.ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)) ramif[2]();

wire ram_select_a, ram_select_b;

assign ram_select_a = addra & RAM_SIZE ? '1 : '0;
assign ram_select_b = addrb & RAM_SIZE ? '1 : '0;

genvar j;
generate
    for (j = 0; j < 2; j++) begin

        assign ramif[j].wea = j == ram_select_a ? |wea : '0;
        assign ramif[j].web = j == ram_select_b ? |web : '0;

        assign ramif[j].ena = j == ram_select_a ? ena : '0;
        assign ramif[j].enb = j == ram_select_b ? enb : '0;

        assign ramif[j].dia = dina;
        assign ramif[j].dib = dinb;

        assign ramif[j].clk = clka;

        assign ramif[j].addra = addra & (~RAM_SIZE);
        assign ramif[j].addrb = addrb & (~RAM_SIZE);
    end
endgenerate

assign douta = ram_select_a ? ramif[1].doa : ramif[0].doa;
assign doutb = ram_select_b ? ramif[1].dob : ramif[0].dob;

ram_wrapper #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .RAM_STYLE("block"),
    .RAM_SIZE(RAM_SIZE),
    .READ_LATENCY(2)
) ram_wrapper_0 (
    .ramif(ramif[0].master)
);

ram_wrapper #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .RAM_STYLE("mixed"),
    .RAM_SIZE(RAM_SIZE),
    .READ_LATENCY(2)
) ram_wrapper_1 (
    .ramif(ramif[1].master)
);


endmodule