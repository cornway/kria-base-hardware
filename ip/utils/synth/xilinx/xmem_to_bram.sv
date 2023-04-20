
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

mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) s_if();

mem_if #(
    .DATA_WIDTH(XDATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) m_if();

typedef logic [$clog2(BRAM_READ_LATENCY)-1:0] latency_t;

latency_t rd_ready_wait_reg, rd_ready_wait_next;

typedef enum logic [2:0] {
    m_state_idle,
    m_state_read
} mstate_e;

mstate_e mstate, mstate_next;

always_comb begin
    rd_ready_wait_next = rd_ready_wait_reg;
    mstate_next = mstate;

    case (mstate)
        m_state_idle: begin
            if (s_if.req) begin
                if (!s_if.we) begin
                    rd_ready_wait_next = latency_t'(BRAM_READ_LATENCY) - 1'b1;
                    mstate_next = m_state_read;
                end
            end
        end

        m_state_read: begin
            if (rd_ready_wait_reg) begin
                rd_ready_wait_next = rd_ready_wait_reg - 1'b1;
            end else begin
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
    end else begin
        mstate <= mstate_next;
        rd_ready_wait_reg <= rd_ready_wait_next;
    end
end

assign debug_out[2:0] = mstate;
assign debug_out[4:3] = rd_ready_wait_reg;
assign debug_out[7:5] = '0;


assign bram_addra = s_if.addr;
assign bram_dina = s_if.wdata;
assign bram_wea = s_if.we ? s_if.be : '0;
assign s_if.rsp_rdata = bram_douta;
assign s_if.rsp_error  = '0;

assign s_if.gnt = m_if.req;

assign m_if.req = xmem_req;
assign m_if.addr = xmem_addr;
assign m_if.be = xmem_be;
assign m_if.we = xmem_we;
assign m_if.wdata = xmem_wdata;

assign xmem_gnt = m_if.gnt;
assign xmem_rsp_valid = m_if.rsp_valid;
assign xmem_rsp_rdata = m_if.rsp_rdata;
assign xmem_rsp_error = m_if.rsp_error;

always_comb begin
    bram_ena = '0;
    s_if.rsp_valid = '0;

    case (mstate)
        m_state_idle: begin
            if (s_if.req) begin
                bram_ena = '1;
                if (xmem_we) begin
                    s_if.rsp_valid = '1;
                end
            end
        end

        m_state_read: begin
            if (!rd_ready_wait_reg) begin
                s_if.rsp_valid = '1;
            end
        end
    endcase
end

xmem_wconvert #(
    .DATA_WIDTH_IN(XDATA_WIDTH),
    .DATA_WIDTH_OUT(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem_wconvert_inst (

    .s_if(s_if.slave),
    .m_if(m_if.master)
);



endmodule