
`timescale 1ns/1ps

`include "pdec_defs.svh"

module pdec_ut_top;

logic [15:0] PLUT[32] = '{
    16'h7fff,
    16'h421,
    16'h842,
    16'hc63,
    16'h1084,
    16'h14a5,
    16'h18c6,
    16'h1ce7,
    16'h2108,
    16'h2529,
    16'h294a,
    16'h2d6b,
    16'h318c,
    16'h35ad,
    16'h39ce,
    16'h3def,
    16'h4210,
    16'h4631,
    16'h4a52,
    16'h4e73,
    16'h5294,
    16'h56b5,
    16'h5ad6,
    16'h5ef7,
    16'h6318,
    16'h6739,
    16'h10,
    16'h0,
    16'h7d50,
    16'h0,
    16'h7fff,
    16'h0
};

logic [31:0] PRE0 = 32'h804;
pdec _pdec = '{default: '0, plutaCCBbits: '0, pixelBitsMask: 16'hf, tmask: '1};

logic [15:0] pixel;

logic transparent;
logic [15:0] amv;
logic [15:0] pres;

logic aclk;
logic aresetn;

pdec #(

) pdec_inst(
    .aclk(aclk),
    .aresetn(aresetn),

    .pixel_in(pixel),
    .pdec_in(_pdec),
    .PRE0(PRE0),
    .PLUT(PLUT),

    .transparent(transparent),
    .amv_out(amv),
    .pres_out(pres),

    .ap_busy(),
    .ap_data_ready()
);

initial begin
    wait(aresetn);

    _apply(16'h27);
    _apply(16'h2a);
    _apply(16'h2b);
    _apply(16'h2b);
    _apply(16'h2a);

    _apply(16'h2b);
    _apply(16'h27);
    _apply(16'h23);
    _apply(16'h21);
    _apply(16'h3d);

    PRE0 = 32'h80003bd6;

    _apply(16'h400);
    #20;
    $finish();
end

task _apply(input logic [15:0] _pixel);
    pixel <= _pixel;
    repeat(2) @(posedge aclk);
    $display("amv = %x, pres = %x, transp = %x", amv, pres, transparent);
endtask

initial begin
    fork
        begin
            aclk = '0;
            aresetn = '0;
            pixel = '0;
        end
        begin
            repeat(16) @(posedge aclk);
            aresetn = '1;
        end
    join
end

always begin
    #10 aclk = ~aclk;
end

endmodule