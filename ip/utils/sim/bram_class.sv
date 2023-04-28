
`timescale 1ns/1ps

package bram_pkg;

class BramDrv #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter BRAM_READ_LATENCY = 32'd1,
    parameter TT = 8ns,
    parameter TA = 2ns
);

virtual bram_if_dv #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) bram;

function new (virtual bram_if_dv #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) bram );
    this.bram  = bram;
endfunction


task cycle_start;
    #TT;
endtask

task cycle_end;
    @(posedge bram.aclk);
endtask

task cycle_wait(input integer cnt);
    repeat(cnt) @(posedge bram.aclk);
endtask

task setup();
    bram.addra = '0;
    bram.dina = '0;
    bram.wea = '0;
    bram.ena = '0;
endtask

task wait_ready();
    wait(bram.aresetn);
endtask


task write (input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
    bram.wea <= #TA '1;
    bram.ena <= #TA '1;
    bram.dina <= #TA data;
    bram.addra <= #TA addr;
    cycle_start();
    cycle_end();
    bram.wea <= #TA '0;
    bram.ena <= #TA '0;
    bram.dina <= #TA '0;
    bram.addra <= #TA '0;
endtask


task read (input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data);
    bram.wea <= #TA '0;
    bram.ena <= #TA '1;
    bram.addra <= #TA addr;
    cycle_start();
    cycle_wait(BRAM_READ_LATENCY);
    cycle_start();
    data = bram.douta;
    cycle_end();
    bram.ena <= #TA '0;
    bram.addra <= #TA '0;

endtask

endclass

endpackage