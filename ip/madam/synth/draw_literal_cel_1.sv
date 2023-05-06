
`timescale 1ns/1ps

`include "mcore_defs.svh"
`include "bitreader_types.svh"
`include "pdec_defs.svh"

module draw_literal_cel_1 #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter PIXEL_WIDTH = 32'd16
) (
    input wire aclk,
    input wire aresetn,

    input wire req,

    mem_if.slave bitreader_mem,
    mem_if.slave draw_mem,

    input uint32_t offset_in,
    input pdec pdec_data,
    input mcore_t mcore,

    output mcore_t mcore_out,

    output wire busy,
    output logic ap_done,
    output logic [31:0] debug_port
);

bitreader_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) bit_if();

uint32_t PRE0_offset;
uint16_t bitskip_next, bitskip_reg;
uint32_t draw_height_next, draw_height_reg;
int32_t xcur_reg, xcur_next;
int32_t ycur_reg, ycur_next;

int32_t xvert_reg, xvert_next;
int32_t yvert_reg, yvert_next;

uint32_t row_count_next, row_count_reg;
uint32_t col_count_next, col_count_reg;

uint32_t deltax_reg, deltax_next;
uint32_t deltay_reg, deltay_next;

mcore_t mcore_out_reg, mcore_out_next;

uint32_t offset;

logic draw_scaled_busy;
logic draw_scaled_ret_valid;
logic draw_scaled_ret_code;
logic draw_scaled_req;
logic pdec_transparent;
logic pdec_valid;

assign offset = ((offset_in + 32'd2) << 2);

assign PRE0_offset = (`PRE0(mcore) >> 24) & 32'hf;

assign bit_if.addr = `PDATA(mcore_out_next);
assign bit_if.bitskip = bitskip_reg;
assign bit_if.bitrate = `GET_BPP(mcore);

typedef enum logic[10:0] { do_wait_req, do_check_row, do_setup_row, do_skip_1, do_setup_col, do_check_col,
                            do_setup_pix, do_wait_pdec, do_draw_scaled_req, do_draw_scaled_wait_resp, do_col_post, do_row_post, do_done } do_state_e;

do_state_e do_state_next, do_state;

always_comb begin

    bitskip_next = bitskip_reg;
    mcore_out_next = mcore_out_reg;
    draw_height_next = draw_height_reg;

    xcur_next = xcur_reg;
    ycur_next = ycur_reg;

    xvert_next = xvert_reg;
    yvert_next = yvert_reg;

    row_count_next = row_count_reg;
    col_count_next = col_count_reg;

    deltax_next = deltax_reg;
    deltay_next = deltay_reg;

    bit_if.req = '0;
    bit_if.op = BR_ATTACH;

    draw_scaled_req = '0;

    ap_done = '0;

    do_state_next = do_state;

    case(do_state)
        do_wait_req: begin
            if (req) begin
                `SPRWI(mcore_out_next) = `SPRWI(mcore) - PRE0_offset;
                `PDATA(mcore_out_next) = `PDATA(mcore);
                `BITCALC(mcore_out_next) = offset << 5;

                if ((`CCBFLAGS(mcore) & CCB_MARIA) && (`VDY1616(mcore) > (32'h1 << 16))) begin
                    draw_height_next = 32'h1 << 16;
                end else begin
                    draw_height_next = `VDY1616(mcore);
                end

                row_count_next = '0;
                col_count_next = '0;

                xvert_next = `XPOS1616(mcore);
                yvert_next = `YPOS1616(mcore);

                do_state_next = do_check_row;
            end
        end
        do_check_row: begin
            if (row_count_reg < `SPRHI(mcore)) begin
                do_state_next = do_setup_row;
            end else begin
                do_state_next = do_done;
            end
        end
        do_setup_row: begin
            xcur_next = xvert_reg;
            ycur_next = yvert_reg;
            bitskip_next = `GET_BPP(mcore) * PRE0_offset;
            if (!bit_if.busy) begin
                bit_if.req = '1;
                bit_if.op = BR_ATTACH;

                do_state_next = do_skip_1;
            end
        end
        do_skip_1: begin

            if (!bit_if.busy && bitskip_reg) begin
                bit_if.req = '1;
                bit_if.op = BR_SKIP;
            end

            if (!bitskip_reg || !bit_if.busy) begin
                do_state_next = do_setup_col;
            end
        end
        do_setup_col: begin
            col_count_next = '0;
            do_state_next = do_check_col;
        end
        do_check_col: begin
            if (col_count_reg < `SPRWI(mcore_out_next)) begin
                do_state_next = do_setup_pix;
            end else begin
                do_state_next = do_row_post;
            end
        end
        do_setup_pix: begin
            if (!bit_if.busy) begin
                bit_if.req = '1;
                bit_if.op = BR_READ;

                do_state_next = do_wait_pdec;
            end
        end
        do_wait_pdec: begin
            if (pdec_valid) begin
                if (pdec_transparent) begin
                    do_state_next = do_col_post;
                end else begin
                    deltax_next = xcur_reg + `HDX1616(mcore) + `VDX1616(mcore);
                    deltay_next = ycur_reg + `HDY1616(mcore) + draw_height_reg;

                    do_state_next = do_draw_scaled_req;
                end
            end
        end
        do_draw_scaled_req: begin
            if (!draw_scaled_busy) begin
                draw_scaled_req = '1;
                do_state_next = do_draw_scaled_wait_resp;
            end
        end
        do_draw_scaled_wait_resp: begin
            if (draw_scaled_ret_valid) begin
                if (draw_scaled_ret_code) begin
                    do_state_next = do_row_post;
                end else begin
                    do_state_next = do_col_post;
                end
            end
        end
        do_col_post: begin
            xcur_next = xcur_reg + `HDX1616(mcore);
            ycur_next = ycur_reg + `HDY1616(mcore);
            col_count_next = col_count_reg + 1'b1;
            do_state_next = do_check_col;
        end

        do_row_post: begin
            xvert_next = xvert_reg + `VDX1616(mcore);
            yvert_next = yvert_reg + `VDY1616(mcore);
            `PDATA(mcore_out_next) = `PDATA(mcore_out_reg) + offset;
            row_count_next = row_count_reg + 1'b1;

            do_state_next = do_check_row;
        end

        do_done: begin
            ap_done = '1;
            do_state_next = do_wait_req;
        end
    endcase
end

always_ff @(posedge aclk, negedge aresetn) begin
    if (!aresetn) begin
        mcore_out_reg <= '{default: '0};
        bitskip_reg <= '0;
        draw_height_reg <= '0;

        xcur_reg <= '0;
        ycur_reg <= '0;

        xvert_reg <= '0;
        yvert_reg <= '0;

        row_count_reg <= '0;
        col_count_reg <= '0;

        deltax_reg <= '0;
        deltay_reg <= '0;

        do_state <= do_wait_req;
    end else begin
        mcore_out_reg <= mcore_out_next;
        bitskip_reg <= bitskip_next;
        draw_height_reg <= draw_height_next;

        xcur_reg <= xcur_next;
        ycur_reg <= ycur_next;

        xvert_reg <= xvert_next;
        yvert_reg <= yvert_next;
        row_count_reg <= row_count_next;
        col_count_reg <= col_count_next;

        deltax_reg <= deltax_next;
        deltay_reg <= deltay_next;

        do_state <= do_state_next;
    end
end

assign busy = do_state != do_wait_req;

bitreader #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH))
            bitreader_inst (
                .aclk(aclk),
                .aresetn(aresetn),

                .memory(bitreader_mem),
                .br_if(bit_if.master),

                .debug_port()
            );

pixel_t pdec_pixel;

pdec #(
) pdec_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .pixel_valid_in(bit_if.data_ready),
    .pixel_in(bit_if.data),
    .pdec_in(pdec_data),
    .mcore(mcore),
    .transparent(pdec_transparent),
    .amv_out(),
    .pres_out(pdec_pixel),
    .pixel_valid_out(pdec_valid)
);

draw_scaled #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIPE_LEN(32'd4)
) draw_scaled_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .memory(draw_mem),
    .req(draw_scaled_req),
    .mcore(mcore),
    .xcur_in(xcur_reg >> 16),
    .ycur_in(ycur_reg >> 16),

    .deltax_in(deltax_reg >> 16),
    .deltay_in(deltay_reg >> 16),

    .pixel(pdec_pixel),
    .busy(draw_scaled_busy),
    .ret_valid(draw_scaled_ret_valid),
    .ret_code(draw_scaled_ret_code)
);

`ifndef SYNTHESIS

always_ff @(posedge aclk) begin
    case (do_state)
        do_wait_req: begin
            if (req) begin
                $display("[DRAW LIT CEL 1] === do_wait_req: req=%x", req);
                $display("[DRAW LIT CEL 1] === do_wait_req #0 PDATA=%x, BITCALC=%x draw_height_next=%x",
                        `PDATA(mcore_out_next), `BITCALC(mcore_out_next), draw_height_next);
                $display("[DRAW LIT CEL 1] === do_wait_req #1 SPRWI=%x", `SPRWI(mcore_out_next));
                $display("[DRAW LIT CEL 1] === do_wait_req #2 SPRHI=%x", `SPRHI(mcore));
                $display("[DRAW LIT CEL 1] === do_wait_req #3 VDX1616=%x", `VDX1616(mcore));
                $display("[DRAW LIT CEL 1] === do_wait_req #4 VDY1616=%x", `VDY1616(mcore));
                $display("[DRAW LIT CEL 1] === do_wait_req #5 HDX1616=%x", `HDX1616(mcore));
                $display("[DRAW LIT CEL 1] === do_wait_req #6 HDY1616=%x", `HDY1616(mcore));
                $display("[DRAW LIT CEL 1] === do_wait_req #7 CLIPXVAL=%x", `CLIPXVAL(mcore));
                $display("[DRAW LIT CEL 1] === do_wait_req #8 CLIPYVAL=%x", `CLIPYVAL(mcore));
                $display("[DRAW LIT CEL 1] === do_wait_req #7 TEXEL_INCX=%x", `TEXEL_INCX(mcore));
                $display("[DRAW LIT CEL 1] === do_wait_req #8 TEXEL_INCY=%x", `TEXEL_INCY(mcore));
            end
        end
        do_setup_row: begin
            $display("[DRAW LIT CEL 1] === do_setup_row: xcur_next=%x, ycur_next=%x, bitskip_next=%x", xcur_next, ycur_next, bitskip_next);
        end
        do_draw_scaled_req: begin
            if (!draw_scaled_busy)
                $display("[DRAW LIT CEL 1] === do_draw_scaled_req");
        end
        do_col_post: begin
            $display("[DRAW LIT CEL 1] === do_col_post: xcur_next=%x, ycur_next=%x, col_count_next=%x", xcur_next, ycur_next, col_count_next);
        end
        do_row_post: begin
            $display("[DRAW LIT CEL 1] === do_row_post: xvert_next=%x, yvert_next=%x, row_count_next=%x PDATA_next=%x",
                    xvert_next, yvert_next, row_count_next, `PDATA(mcore_out_next));
        end
        do_done: begin
            $display("[DRAW LIT CEL 1] === do_done");
        end

    endcase
end

`endif

endmodule