

`include "mcore_defs.svh"

module draw_scaled #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter PIXEL_WIDTH = 32'd16,
    parameter PIPE_LEN = 32'd4
) (
    input wire aclk,
    input wire aresetn,
    input mcore_t mcore,
    mem_if.slave memory,

    input int32_t xcur_in,
    input int32_t ycur_in,

    input int32_t deltax_in,
    input int32_t deltay_in,

    input pixel_t pixel,

    input wire req,
    output logic busy,
    output logic ret_valid,
    output logic ret_code
);

fb_if framebuffer_if();

int32_t x_reg, y_reg;
int32_t x_next, y_next;

int32_t deltax_next, deltax_reg;
int32_t deltay_next, deltay_reg;

assign busy = do_state != do_wait_req;

typedef enum logic[7:0] { do_wait_req, do_pretest, do_check_y, do_check_x, do_post_x, do_test_clip, do_write_pixel, do_done } do_state_e;

do_state_e do_state, do_state_next;

always_comb begin
    x_next = x_reg;
    y_next = y_reg;

    ret_valid = '0;
    ret_code = '0;

    framebuffer_if.x = '0;
    framebuffer_if.y = '0;
    framebuffer_if.req = '0;
    framebuffer_if.pixel = '0;

    deltax_next = deltax_reg;
    deltay_next = deltay_reg;

    do_state_next = do_state;

    case (do_state)
        do_wait_req: begin
            if (req) begin
                do_state_next = do_pretest;
            end
        end
        do_pretest: begin
            y_next = ycur_in;
            x_next = xcur_in;

            deltax_next = deltax_in;
            deltay_next = deltay_in;

            if ((`HDX1616(mcore) < 0) && (deltax_in < 0) && (xcur_in < 0)) begin
                ret_valid = '1;
                ret_code = '1;
                do_state_next = do_wait_req;
            end else if ((`HDY1616(mcore) < 0) && (deltay_in < 0) && (ycur_in < 0)) begin
                ret_valid = '1;
                ret_code = '1;
                do_state_next = do_wait_req;
            end else if ((`HDX1616(mcore) > 0) && (deltax_in) > (`CLIPXVAL(mcore)) && (xcur_in) > (`CLIPXVAL(mcore))) begin
                ret_valid = '1;
                ret_code = '1;
                do_state_next = do_wait_req;
            end else if ((`HDY1616(mcore) > 0) && ((deltay_in)) > (`CLIPYVAL(mcore)) && (ycur_in) > (`CLIPYVAL(mcore))) begin
                ret_valid = '1;
                ret_code = '1;
                do_state_next = do_wait_req;
            end else if (xcur_in == deltax_in) begin
                ret_valid = '1;
                ret_code = '0;
                do_state_next = do_wait_req;
            end else begin
                do_state_next = do_check_y;
            end
        end

        do_check_y: begin
            if (y_reg == deltay_in) begin
                do_state_next = do_done;
            end else begin
                do_state_next = do_check_x;
            end
        end

        do_check_x: begin
            if (x_reg == deltax_in) begin
                y_next = y_reg + `TEXEL_INCY(mcore);
                do_state_next = do_check_y;
            end else begin
                do_state_next = do_test_clip;
            end
        end

        do_post_x: begin
            x_next = x_reg + `TEXEL_INCX(mcore);
            do_state_next = do_check_x;
        end

        do_test_clip: begin
            //#define TESTCLIP(cx, cy) ( ((cx) >= 0) && ((cx) <= CLIPXVAL) && ((cy) >= 0) && ((cy) <= CLIPYVAL) )
            if (test_clip(mcore, x_reg, y_reg)) begin
                do_state_next = do_write_pixel;
            end else begin
                do_state_next = do_post_x;
            end
        end

        do_write_pixel: begin
            if (!framebuffer_if.busy) begin
                framebuffer_if.x = x_reg;
                framebuffer_if.y = y_reg;
                framebuffer_if.req = '1;
                framebuffer_if.pixel = pixel;

                do_state_next = do_post_x;
            end
        end

        do_done: begin
            ret_valid = '1;
            ret_code = '0;
            do_state_next = do_wait_req;
        end
    endcase
end

always_ff @(posedge aclk, negedge aresetn) begin
    if (!aresetn) begin
        x_reg <= '0;
        y_reg <= '0;
        deltax_reg <= '0;
        deltay_reg <= '0;
        do_state <= do_wait_req;
    end else begin
        x_reg <= x_next;
        y_reg <= y_next;
        deltax_reg <= deltax_next;
        deltay_reg <= deltay_next;

        do_state <= do_state_next;
    end
end

function logic test_clip(input mcore_t mcore, input int32_t x, input int32_t y);
    if (x < 0) begin
        return '0;
    end
    if (x > `CLIPXVAL(mcore)) begin
        return '0;
    end
    if (y < 0) begin
        return '0;
    end
    if (y > `CLIPYVAL(mcore)) begin
        return '0;
    end
    return '1;
endfunction

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

`ifndef SYNTHESIS

always_ff @(posedge aclk) begin
    case(do_state)
        do_wait_req: begin
            if (req) begin
                $display("[DRAW SCALED] === do_wait_req: req=%X", req);
                $display("[DRAW SCALED] === do_wait_req #1 TEXEL_INCX=%x, TEXEL_INCY=%x", `TEXEL_INCX(mcore), `TEXEL_INCY(mcore));
            end
        end
        do_pretest: begin
            $display("[DRAW SCALED] === do_pretest:");
            $display("[DRAW SCALED] === do_pretest #1 x_next=%x y_next=%x deltax_next=%x deltay_next=%x", x_next, y_next, deltax_next, deltay_next);
            $display("[DRAW SCALED] === do_pretest #2 ret_valid=%x ret_code=%x", ret_valid, ret_code);
        end
        do_test_clip: begin
            $display("[DRAW SCALED] === do_test_clip:");
            $display("[DRAW SCALED] === do_test_clip #1 x_reg=%x, y_reg=%x, CLIPXVAL=%x, CLIPYVAL=%x", x_reg, y_reg, `CLIPXVAL(mcore), `CLIPYVAL(mcore));
        end
        do_write_pixel: begin
            if (!framebuffer_if.busy) begin
                $display("[DRAW SCALED] === do_write_pixel: pixel=%x", pixel);
            end
        end
        do_done: begin
            $display("[DRAW SCALED] === do_done");
        end
    endcase
end

`endif //SYNTHESIS

endmodule