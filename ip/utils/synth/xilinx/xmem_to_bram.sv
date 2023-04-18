
`timescale 1ns/1ps

module xmem_to_bram #(
    parameter XDATA_WIDTH = 32'd32,
    parameter XADDR_WIDTH = 32'd32,

    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter BRAM_READ_LATENCY = 2
) (
    input wire aclk,
    input wire aresetn,

    //BRAM interface
    output logic [ADDR_WIDTH-1:0] bram_addra,
    output logic [DATA_WIDTH-1:0] bram_dina,
    input logic [DATA_WIDTH-1:0] bram_douta,
    output logic bram_ena,
    output logic [DATA_WIDTH/8-1:0] bram_wea,

    //Memory interface
    input logic                     xmem_req,
    input logic [XADDR_WIDTH-1:0]    xmem_addr,
    input logic                     xmem_we,
    input logic [XDATA_WIDTH-1:0]    xmem_wdata,
    input logic [XDATA_WIDTH/8-1:0]  xmem_be,

    output logic                      xmem_gnt,
    output logic                      xmem_rsp_valid,
    output logic [XDATA_WIDTH-1:0]     xmem_rsp_rdata,
    output logic                      xmem_rsp_error,

    output wire [7:0]                   debug_out
);

localparam BRAM_ADDR_MASK = (1 << $clog2(DATA_WIDTH/8)) - 1;
localparam XDATA_MASK = (1 << XDATA_WIDTH) - 1;

logic [$clog2(BRAM_READ_LATENCY)-1:0] rd_ready_wait_reg, rd_ready_wait_next;
logic [DATA_WIDTH-1:0] bram_douta_reg[BRAM_READ_LATENCY];

typedef enum logic [2:0] {
    m_state_idle,
    m_state_read
} mstate_e;

mstate_e mstate, mstate_next;

assign xmem_gnt = xmem_req;
assign bram_addra = xmem_addr & ~BRAM_ADDR_MASK;

wire [ $clog2(DATA_WIDTH/8) - $clog2(XDATA_WIDTH/8) - 1 : 0 ] xmem_lsb_msb_sel;

assign xmem_lsb_msb_sel = xmem_addr[$clog2(DATA_WIDTH/8) -1 : $clog2(XDATA_WIDTH/8)];

generate
    if (DATA_WIDTH / XDATA_WIDTH > 1) begin

        assign bram_dina            = xmem_wdata << (xmem_lsb_msb_sel * XDATA_WIDTH);
        assign xmem_rsp_rdata       = (bram_douta_reg[BRAM_READ_LATENCY-1] >> (xmem_lsb_msb_sel * XDATA_WIDTH)) & XDATA_MASK;
        assign bram_wea             = xmem_we ? (xmem_be << (xmem_lsb_msb_sel * (XDATA_WIDTH/8))) : '0;

    end else begin

        assign bram_dina        = xmem_wdata;
        assign xmem_rsp_rdata   = bram_douta;
        assign bram_wea         = xmem_we ? xmem_be : '0;

    end
endgenerate

always_comb begin
    rd_ready_wait_next = rd_ready_wait_reg;
    mstate_next = mstate;

    xmem_rsp_valid = '0;
    xmem_rsp_error = '0;

    bram_ena = '0;

    case (mstate)
        m_state_idle: begin
            if (xmem_req) begin
                bram_ena = '1;
                if (!xmem_we) begin
                    rd_ready_wait_next = '1;
                    mstate_next = m_state_read;
                end else begin
                    xmem_rsp_valid = '1;
                end
            end
        end

        m_state_read: begin
            bram_ena = '1;
            if (rd_ready_wait_reg) begin
                rd_ready_wait_next = rd_ready_wait_reg - 1'b1;
            end else begin
                xmem_rsp_valid = '1;
                mstate_next = m_state_idle;
            end
        end
    endcase
end

integer i;
always_ff @(posedge aclk, negedge aresetn) begin
    if (!aresetn) begin
        mstate <= m_state_idle;
        rd_ready_wait_reg <= '0;
        for (i = 0; i < BRAM_READ_LATENCY; i++) begin
            bram_douta_reg[i] <= '0;
        end
    end else begin
        mstate <= mstate_next;
        rd_ready_wait_reg <= rd_ready_wait_next;

        bram_douta_reg[0] <= bram_douta;
        for (i = 1; i < BRAM_READ_LATENCY; i++) begin
            bram_douta_reg[i] <= bram_douta_reg[i-1];
        end
    end
end

assign debug_out[2:0] = mstate;
assign debug_out[4:3] = rd_ready_wait_reg;
assign debug_out[7:5] = '0;

endmodule