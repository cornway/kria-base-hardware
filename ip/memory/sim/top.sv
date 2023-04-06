
`timescale 1ns/1ps

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 32;

module sim_memory_wrapper_top;

logic clka, clkb;
logic rsta, rstb;
logic [ADDR_WIDTH-1:0] addra, addrb;
logic [DATA_WIDTH-1:0] dina, douta, dinb, doutb;
logic ena, enb;
logic [DATA_WIDTH/8-1:0] wea, web;

assign clkb = clka;

initial begin
    clka = '0;
    rsta = '1;
    rstb = '1;
    addra = '0;
    addrb = '0;
    dina = '0;
    dinb = '0;
    wea = '0;
    web = '0;
    ena = '0;
    enb = '0;
end

always begin
    #5 clka <= ~clka;
end

task memwrite (input logic[ADDR_WIDTH-1: 0] addr, input logic[DATA_WIDTH-1:0] data);
    addra = addr;
    dina = data;
    ena = '1;
    wea = '1;
    repeat(1) @(posedge clka);
    #1
    ena = '0;
    wea = '0;
    dina = '0;
endtask

task memread (input logic[ADDR_WIDTH-1: 0] addr);
    addra = addr;
    ena = '1;
    repeat(2) @(posedge clka);
    $display("addra = %x douta = %x", addr, douta);
    ena = '0;
endtask


initial begin
    #20
    @(posedge clka)

    memwrite(32'h0000_0000, 32'hcafecafe);
    memwrite(32'h0000_0024, 32'h12345678);

    //Read
    @(posedge clka);
    memread(32'h0000_0000);
    memread(32'h0000_0024);

    @(posedge clka);
    $finish();
end

ram_infra #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .RAM_SIZE(32'h20)
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