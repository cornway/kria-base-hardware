
`timescale 1ns/1ps

`include "mcore_defs.svh"
`include "bitreader_types.svh"
`include "pdec_defs.svh"

module draw_literal_cel_0 #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter PIXEL_WIDTH = 32'd16
) (
    input wire aclk,
    input wire aresetn,

    input wire req,

    mem_if.slave bitreader_mem,
    mem_if.slave bitmap_row_mem,

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

mcore_t mcore_out_next, mcore_out_reg;
int32_t xvert_next, yvert_next;
int32_t xvert_reg, yvert_reg;
int32_t x_offset[2], y_offset[2];
int32_t x_offset_next[2], y_offset_next[2];
uint32_t pdata_offset, pdata_offset_next;
int32_t offset;
uint32_t row_count, row_count_next;
uint32_t PRE0_step;
uint32_t bitskip, bitskip_next;

uint32_t pix_count;

pixel_t pdec_pixel;

logic bmap_row_req;

assign offset = (offset_in + 2) << 2;
assign PRE0_step = ((`PRE0(mcore_out_reg) >> 24) & 32'hf);

assign bit_if.addr = `PDATA(mcore_out_next);
assign bit_if.bitskip = bitskip;
assign bit_if.bitrate = `GET_BPP(mcore_out_reg);

assign pix_count = `SPRWI(mcore_out_reg) - `TEXTURE_WI_START(mcore_out_reg);
assign mcore_out = mcore_out_reg;

typedef enum logic [15:0] {
    do_wait_req,
    do_setup_1,
    do_row_count_check,
    do_attach,
    do_setup_2,
    do_skip_1,
    do_setup_3,
    do_skip_2,
    do_draw_row_req,
    do_draw_row,
    do_post_setup,
    do_done
 } do_state_e;
do_state_e do_state, do_state_next;

assign busy = do_state != do_wait_req;

always_comb begin

    xvert_next = xvert_reg;
    yvert_next = yvert_reg;
    mcore_out_next = mcore_out_reg;
    x_offset_next = x_offset;
    y_offset_next = y_offset;
    pdata_offset_next = pdata_offset;
    row_count_next = row_count;
    bitskip_next = bitskip;

    bit_if.req = '0;
    bit_if.op = BR_ATTACH;

    bmap_row_req = '0;

    ap_done = '0;

    do_state_next = do_state;

    case(do_state)
        do_wait_req: begin
            if (req) begin
                `PRE0               (mcore_out_next) = `PRE0            (mcore);

                `SPRWI              (mcore_out_next) = `SPRWI(mcore) - PRE0_step;
                `BITCALC            (mcore_out_next) = offset << 5;
                `VDX1616            (mcore_out_next) = `VDX1616         (mcore);
                `VDY1616            (mcore_out_next) = `VDY1616         (mcore);
                `PDATA              (mcore_out_next) = `PDATA           (mcore);
                `TEXTURE_WI_LIM     (mcore_out_next) = `TEXTURE_WI_LIM  (mcore);
                `TEXTURE_HI_LIM     (mcore_out_next) = `TEXTURE_HI_LIM  (mcore);
                `TEXTURE_WI_START   (mcore_out_next) = `TEXTURE_WI_START(mcore);
                `TEXTURE_HI_START   (mcore_out_next) = `TEXTURE_HI_START(mcore);

                x_offset_next[0] = `TEXTURE_HI_START(mcore) * `VDX1616(mcore);
                y_offset_next[0] = `TEXTURE_HI_START(mcore) * `VDY1616(mcore);

                x_offset_next[1] = `TEXTURE_WI_START(mcore) * `HDX1616(mcore);
                y_offset_next[1] = `TEXTURE_WI_START(mcore) * `HDY1616(mcore);

                xvert_next = `XPOS1616(mcore);
                yvert_next = `YPOS1616(mcore);

                pdata_offset_next = offset * `TEXTURE_HI_START(mcore);

                do_state_next = do_setup_1;
            end
        end

        do_setup_1: begin
            xvert_next = xvert_reg + x_offset_next[0] + x_offset_next[1];
            yvert_next = yvert_reg + y_offset_next[0] + y_offset_next[1];

            `PDATA(mcore_out_next) = `PDATA(mcore_out_reg) + pdata_offset_next;
            if (`SPRWI(mcore_out_reg) > `TEXTURE_WI_LIM(mcore_out_reg)) begin
                `SPRWI(mcore_out_next) = `TEXTURE_WI_LIM(mcore_out_reg);
            end
            row_count_next = `TEXTURE_HI_START(mcore_out_reg);

            do_state_next = do_row_count_check;
        end

        do_row_count_check: begin
            if (row_count < `TEXTURE_HI_LIM(mcore_out_reg)) begin
                do_state_next = do_attach;
            end else begin
                do_state_next = do_done;
            end
        end

        do_attach: begin
            if (!bit_if.busy) begin
                bit_if.req = '1;
                bit_if.op = BR_ATTACH;

                do_state_next = do_setup_2;
            end
        end

        do_setup_2: begin
            bitskip_next = `GET_BPP(mcore_out_reg) * PRE0_step;

            do_state_next = do_skip_1;
        end

        do_skip_1: begin
            if (!bit_if.busy) begin
                bit_if.req = '1;
                bit_if.op = BR_SKIP;

                if (`TEXTURE_WI_START(mcore_out_reg)) begin
                    do_state_next = do_setup_3;
                end else begin
                    do_state_next = do_draw_row_req;
                end
            end
        end

        do_setup_3: begin
            bitskip_next = `GET_BPP(mcore_out_reg) * `TEXTURE_WI_START(mcore_out_reg);
            do_state_next = do_skip_2;
        end

        do_skip_2: begin
            if (!bit_if.busy) begin
                bit_if.req = '1;
                bit_if.op = BR_SKIP;

                do_state_next = do_draw_row_req;
            end
        end

        do_draw_row_req: begin
            if (!bmap_row_busy) begin
                bmap_row_req = '1;

                do_state_next = do_draw_row;
            end
        end

        do_draw_row: begin
            if (!bmap_row_busy) begin
                do_state_next = do_post_setup;
            end
            bit_if.req = bmap_row_pix_req;
            bit_if.op = BR_READ;
        end

        do_post_setup: begin
            xvert_next = xvert_reg + `VDX1616(mcore_out_reg);
            yvert_next = yvert_reg + `VDY1616(mcore_out_reg);
            row_count_next = row_count + 1'b1;
            `PDATA(mcore_out_next) = `PDATA(mcore_out_reg) + offset;

            do_state_next = do_row_count_check;
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
        x_offset <= '{default: '0};
        y_offset <= '{default: '0};
        pdata_offset = '0;

        row_count <= '0;
        xvert_reg <= '0;
        yvert_reg <= '0;
        bitskip <= '0;
        do_state <= do_wait_req;
    end else begin
        mcore_out_reg <= mcore_out_next;

        x_offset <= x_offset_next;
        y_offset <= y_offset_next;
        pdata_offset = pdata_offset_next;

        row_count <= row_count_next;
        xvert_reg <= xvert_next;
        yvert_reg <= yvert_next;
        bitskip <= bitskip_next;
        do_state <= do_state_next;
    end
end

bitreader #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH))
            bitreader_inst (
                .aclk(aclk),
                .aresetn(aresetn),

                .memory(bitreader_mem),
                .br_if(bit_if.master),

                .debug_port()
            );

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

draw_bmap_row #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIPE_LEN(32'd4)
) draw_bmap_row_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .memory(bitmap_row_mem),
    .req(bmap_row_req),
    .mcore(mcore),
    .xcur_in(xvert_reg),
    .ycur_in(yvert_reg),
    .cnt_in(pix_count),
    .pdec_transparent_in(pdec_transparent),
    .pix_req(bmap_row_pix_req),
    .pix_valid(pdec_valid),
    .pix_busy(bit_if.busy),
    .pixel(pdec_pixel),
    .busy(bmap_row_busy),
    .debug_port(debug_port[7:0])
);

assign debug_port[11:8] = do_state;

`ifndef SYNTHESIS

always_ff @(posedge aclk) begin
    case(do_state)
    do_wait_req:
        if (req) begin
                $display("[DRAW LITERAL CEL] === do_wait_req: req = %x:", req);

                $display("bpp = %x", `GET_BPP(mcore_out_next));
                $display("XPOS1616 = %x", `XPOS1616(mcore));
                $display("YPOS1616 = %x", `YPOS1616(mcore));

                $display("[DRAW LITERAL CEL] PRE0 = %x",                `PRE0(mcore_out_next));
                $display("[DRAW LITERAL CEL] SPRWI = %x",               `SPRWI              (mcore_out_next));
                $display("[DRAW LITERAL CEL] BITCALC = %x",             `BITCALC            (mcore_out_next));
                $display("[DRAW LITERAL CEL] VDX1616 = %x",             `VDX1616            (mcore_out_next));
                $display("[DRAW LITERAL CEL] VDY1616 = %x",             `VDY1616            (mcore_out_next));

                $display("[DRAW LITERAL CEL] TEXTURE_WI_LIM = %x",      `TEXTURE_WI_LIM     (mcore_out_next));
                $display("[DRAW LITERAL CEL] TEXTURE_HI_LIM = %x",      `TEXTURE_HI_LIM     (mcore_out_next));

                $display("[DRAW LITERAL CEL] TEXTURE_WI_START = %x",    `TEXTURE_WI_START   (mcore_out_next));
                $display("[DRAW LITERAL CEL] TEXTURE_HI_START = %x",    `TEXTURE_HI_START   (mcore_out_next));

                $display("[DRAW LITERAL CEL] PDATA = %x",               `PDATA(mcore_out_next) );

                $display("[DRAW LITERAL CEL] xvert_next = %x", xvert_next);
                $display("[DRAW LITERAL CEL] yvert_next = %x", yvert_next);
                $display("xoff = %x %x", x_offset_next[0], x_offset_next[1]);
                $display("yoff = %x %x", y_offset_next[0], y_offset_next[1]);
                $display("`TEXTURE_WI_START(mcore) + `HDX1616(mcore) = %x", `TEXTURE_WI_START(mcore) + `HDX1616(mcore));

        end
    do_setup_1: begin
        $display("[DRAW LITERAL CEL] === do_setup_1:");
        $display("[DRAW LITERAL CEL] xvert_next = %x", xvert_next);
        $display("[DRAW LITERAL CEL] yvert_next = %x", yvert_next);
    end
    do_draw_row_req: begin
        if (!bmap_row_busy) begin
            $display("[DRAW LITERAL CEL] === do_draw_row_req");
            $display("[DRAW LITERAL CEL] xvert_reg = %x, yvert_reg = %x", xvert_reg, yvert_reg);
        end
    end
    do_post_setup: begin
        $display("[DRAW LITERAL CEL] === do_post_setup");
        $display("[DRAW LITERAL CEL] PDATA = %x", `PDATA(mcore_out_next) );
        $display("[DRAW LITERAL CEL] xvert_next = %x, yvert_next = %x", xvert_next, yvert_next);
    end
    endcase
end

`endif /*SYNTHESIS*/

endmodule