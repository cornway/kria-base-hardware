

`include "mcore_defs.svh"


module draw_bmap_row #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter PIXEL_WIDTH = 32'd16,
    parameter PIPE_LEN = 32'd4
) (
    input wire aclk,
    input wire aresetn,

    input wire req,

    input mcore_t mcore,

    input int32_t xcur_in,
    input int32_t ycur_in,
    input int32_t cnt_in,

    input wire pdec_transparent_in,

    output logic pix_req,
    input logic pix_busy,
    input logic pix_resp,
    input pixel_t pixel,

    mem_if.slave memory,

    output logic busy,

    output logic [31:0] debug_port
);


uint32_t xp_next, xp_reg;
uint32_t yp_next, yp_reg;
uint32_t cnt_next, cnt_reg;
uint16_t hdx, hdy;

fb_if framebuffer_if();

assign hdx = `HDX1616(mcore) >> 16;
assign hdy = `HDY1616(mcore) >> 16;

typedef enum logic [4:0] { br_state_idle, br_state_setup, br_state_read_req, br_state_read_resp, br_state_write } br_state_e;

br_state_e br_state, br_state_next;

always_comb begin
    pix_req = '0;
    framebuffer_if.req = '0;
    framebuffer_if.x = '0;
    framebuffer_if.y = '0;
    framebuffer_if.pixel = '0;

    xp_next = xp_reg;
    yp_next = yp_reg;
    cnt_next = cnt_reg;
    br_state_next = br_state;

    case (br_state)
        br_state_idle: begin
            if (req) begin
                xp_next = xcur_in >> 16;
                yp_next = ycur_in >> 16;
                cnt_next = '0;

                if (cnt_in)
                    br_state_next = br_state_read_req;
                else
                    br_state_next = br_state_setup;
            end
        end
        br_state_setup: begin
            if (cnt_reg < (cnt_in - 1'b1)) begin
                cnt_next = cnt_reg + 1'b1;
                xp_next = xp_reg + hdx;
                yp_next = yp_reg + hdy;
                br_state_next = br_state_read_req;
            end else begin
                br_state_next = br_state_idle;
            end
        end
        br_state_read_req: begin
            if (!pix_busy) begin
                pix_req = '1;
                br_state_next = br_state_read_resp;
            end
        end
        br_state_read_resp: begin
            if (pix_resp) begin
                br_state_next = br_state_write;
            end
        end
        br_state_write: begin
            if (pdec_transparent_in) begin
                br_state_next = br_state_setup;
            end else begin
                if (!framebuffer_if.busy) begin
                    framebuffer_if.x = xp_reg;
                    framebuffer_if.y = yp_reg;
                    framebuffer_if.req = '1;
                    framebuffer_if.pixel = pixel;

                    br_state_next = br_state_setup;
                end
            end
        end
    endcase
end

always_ff @(posedge aclk, negedge aresetn) begin
    if (!aresetn) begin
        xp_reg <= '0;
        yp_reg <= '0;
        cnt_reg <= '0;
        br_state <= br_state_idle;
    end else begin
        xp_reg <= xp_next;
        yp_reg <= yp_next;
        cnt_reg <= cnt_next;
        br_state <= br_state_next;
    end
end

assign busy  = br_state != br_state_idle;

frame_buffer_wrapper #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIPE_LEN(PIPE_LEN)
) frame_buffer_wrapper_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .memory(memory),
    .mcore(mcore),
    .framebuffer_if(framebuffer_if)
);

assign debug_port[3:0] = br_state == br_state_idle ? 4'ha :
                        br_state == br_state_setup ? 4'hb :
                        br_state == br_state_read_req ? 4'hc :
                        br_state == br_state_read_resp ? 4'hd :
                        br_state == br_state_write ? 4'hd : 4'h0;

assign debug_port[6:4] = '0;
assign debug_port[7] = framebuffer_if.busy;

`ifndef SYNTHESIS

always_ff @(posedge aclk) begin
    case (br_state)
        br_state_idle: begin
            if (req) begin
                $display("[BMAP DRAW ROW] === br_state_idle: req = %x", req);
                $display("[BMAP DRAW ROW] xp_next = %x, yp_next = %x", xp_next, yp_next);
                $display("[BMAP DRAW ROW]wmod=%x, HDX1616=%x, HDY1616=%x", mcore.wmod, `HDX1616(mcore), `HDY1616(mcore));
            end
        end
        br_state_setup: begin
            $display("[BMAP DRAW ROW] === br_state_setup:");
            $display("[BMAP DRAW ROW]xp_next=%x, yp_next=%x, cnt_nex=%x", xp_next, yp_next, cnt_next);
        end
        br_state_write: begin
            if (!framebuffer_if.busy) begin
                $display("[BMAP DRAW ROW] === br_state_write:");
                $display("[BMAP DRAW ROW] xp_reg = %x, yp_reg = %x", xp_reg, yp_reg);
            end else begin
                $display("[BMAP DRAW ROW] wait framebuffer ready");
            end
        end
    endcase
end

`endif

endmodule
