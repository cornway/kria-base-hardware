

`include "mcore_defs.svh"

module frame_buffer #(
    parameter  DATA_WIDTH= 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter PIXEL_WIDTH = 32'd16
) (
    input wire aclk,
    input wire aresetn,

    mem_if.slave memory,
    input mcore_t mcore,

    input pixel_t pixel,
    input uint16_t x,
    input uint16_t y,
    input wire req,

    output logic resp,
    output logic busy
);

mem_if #(
    .DATA_WIDTH(PIXEL_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) pix_if();

typedef enum logic [3:0] { fb_state_idle,
                            fb_state_calc_addr_1,
                            fb_state_calc_addr_2,
                            fb_state_mem_write } fb_state_e;

fb_state_e fb_state, fb_state_next;
uint33_t addr_reg, addr_next;
logic resp_next;

uint32_t yw_reg, yw_next;
uint8_t y1_next, y1_reg;
uint16_t x_next, x_reg;
uint32_t offset_next, offset_reg;

always_comb begin
    pix_if.req = '0;
    pix_if.addr = '0;
    pix_if.wdata = '0;
    pix_if.be = '0;
    pix_if.we = '0;

    resp_next = '0;

    yw_next = yw_reg;
    y1_next = y1_reg;
    x_next = x_reg;
    offset_next = offset_reg;

    fb_state_next = fb_state;
    addr_next = addr_reg;

    case (fb_state)
        fb_state_idle: begin
            if (req) begin
                yw_next = (y >> 1) * mcore.wmod;
                y1_next = (y & 1) << 1;
                x_next = x << 2;
                fb_state_next = fb_state_calc_addr_1;
            end
        end
        fb_state_calc_addr_1: begin
            offset_next = yw_reg + y1_reg + x_reg;
            fb_state_next = fb_state_calc_addr_2;
        end
        fb_state_calc_addr_2: begin
            addr_next = mcore.regs[MREGS_FBTARGET_ID] + (offset_reg ^ 2);
            fb_state_next = fb_state_mem_write;
        end
        fb_state_mem_write: begin
            pix_if.req = '1;
            pix_if.we = '1;
            pix_if.be = '1;
            pix_if.addr = addr_reg;
            pix_if.wdata = pixel;
            if (pix_if.gnt) begin
                resp_next = '1;
                fb_state_next = fb_state_idle;
            end
        end
    endcase
end

always_ff @(posedge aclk, negedge aresetn) begin
    if (!aresetn) begin
        fb_state <= fb_state_idle;
        addr_reg <= '0;
        yw_reg <= '0;
        y1_reg <= '0;
        x_reg <= '0;
        offset_reg <= '0;
    end else begin
        addr_reg <= addr_next;
        yw_reg <= yw_next;
        y1_reg <= y1_next;
        x_reg <= x_next;
        offset_reg <= offset_next;
        fb_state <= fb_state_next;
    end
end

assign addr_dbg = addr_reg;
assign busy = fb_state != fb_state_idle;
assign resp = resp_next;

xmem_wconvert #(
    .DATA_WIDTH_IN(PIXEL_WIDTH),
    .DATA_WIDTH_OUT(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem_wconvert_inst (
    .s_if(memory),
    .m_if(pix_if.master)
);

endmodule