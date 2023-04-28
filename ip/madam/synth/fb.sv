

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

    fb_if.master framebuffer_if
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
pixel_t pixel_next, pixel_reg;

always_comb begin
    pix_if.req = '0;
    pix_if.addr = '0;
    pix_if.wdata = '0;
    pix_if.be = '0;
    pix_if.we = '0;
    pixel_next = pixel_reg;

    resp_next = '0;

    yw_next = yw_reg;
    y1_next = y1_reg;
    x_next = x_reg;
    offset_next = offset_reg;

    fb_state_next = fb_state;
    addr_next = addr_reg;

    case (fb_state)
        fb_state_idle: begin
            if (framebuffer_if.req) begin
                yw_next = (framebuffer_if.y >> 1) * mcore.wmod;
                y1_next = (framebuffer_if.y & 1) << 1;
                x_next = framebuffer_if.x << 2;
                pixel_next = framebuffer_if.pixel;
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
            pix_if.wdata = pixel_reg;
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
        pixel_reg <= '0;
    end else begin
        addr_reg <= addr_next;
        yw_reg <= yw_next;
        y1_reg <= y1_next;
        x_reg <= x_next;
        offset_reg <= offset_next;
        pixel_reg <= pixel_next;
        fb_state <= fb_state_next;
    end
end

assign framebuffer_if.busy = fb_state != fb_state_idle;
assign framebuffer_if.resp = resp_next;

xmem_wconvert #(
    .DATA_WIDTH_IN(PIXEL_WIDTH),
    .DATA_WIDTH_OUT(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) xmem_wconvert_inst (
    .s_if(memory),
    .m_if(pix_if.master)
);

endmodule

module frame_buffer_piped #(
    parameter  DATA_WIDTH= 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter PIXEL_WIDTH = 32'd16,
    parameter PIPE_LEN = 32'd4
) (
    input wire aclk,
    input wire aresetn,

    mem_if.slave memory,
    input mcore_t mcore,

    fb_if.master framebuffer_if
);

typedef logic [$clog2(PIPE_LEN)-1:0] pipe_t;

logic [PIPE_LEN-1:0] busy;
pipe_t fb_select;

fb_if fb_if_int[PIPE_LEN]();

mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) mem_if_int[PIPE_LEN]();

genvar i;
generate

for (i = 0; i < PIPE_LEN; i++) begin
    frame_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .PIXEL_WIDTH(PIXEL_WIDTH)
    ) frame_buffer_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .mcore(mcore),
        .memory(mem_if_int[i]),
        .framebuffer_if(fb_if_int[i])
    );

    assign busy[i] = fb_if_int[i].busy;

    assign fb_if_int[i].pixel = framebuffer_if.pixel;
    assign fb_if_int[i].x = framebuffer_if.x;
    assign fb_if_int[i].y = framebuffer_if.y;
    assign fb_if_int[i].req = fb_select == i ? framebuffer_if.req : '0;
end

endgenerate

assign framebuffer_if.resp = ! (&busy);
assign framebuffer_if.busy = &busy;

always_ff @(posedge aclk, negedge aresetn) begin
    if (!aresetn) begin
        fb_select <= '0;
    end else begin
        fb_select <= _get_first_ready();
    end
end

function pipe_t _get_first_ready;
    automatic integer i = 0;
    for (i = 0; i < PIPE_LEN; i++) begin
        if (!busy[i]) begin
            return i;
        end
    end
    /*Failure case, must not happen*/
    return pipe_t'('0);

endfunction

xmem_cross_rr #(
    .NUM_MASTERS(PIPE_LEN)
) xmem_cross_rr_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .m_if(mem_if_int),
    .s_if(memory)
);

endmodule