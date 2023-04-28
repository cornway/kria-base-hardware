
`timescale 1ns/1ps


`include "pdec_defs.svh"
`include "mcore_defs.svh"

parameter PRE0_BPP_MASK = 32'h7;
parameter PRE0_LINEAR = 32'h10;

module pdec #(

) (
    input wire aclk,
    input wire aresetn,

    input logic pixel_valid_in,
    input uint16_t pixel_in,
    input pdec pdec_in,
    input mcore_t mcore,

    output wire transparent,
    output uint16_t amv_out,
    output uint16_t pres_out,
    output logic pixel_valid_out
);

pdeco pix1;

uint16_t amv_reg, amv_next;
uint16_t pres_reg, pres_next;
logic transparent_reg, transparent_next;
uint32_t PRE0;

assign PRE0 = mcore.cel_vars.var_unsigned[PRE0_ID];

assign pix1.raw = pixel_in;

always_comb begin
    amv_next = amv_reg;
    pres_next = pres_reg;
    transparent_next = transparent_reg;

    case(PRE0 & PRE0_BPP_MASK)
        3'h4: begin
            pres_next = (mcore.plut[pix1.c6b.c] & 16'h7fff) | (pix1.c6b.pw << 15);
            amv_next = 8'h49;
        end
        3'h5: begin
            if (PRE0 & PRE0_LINEAR) begin
                pres_next = MAPu8b_func(pix1.raw & 8'hff);
                amv_next = 8'h49;
            end else begin
                pres_next = mcore.plut[pix1.c8b.c];
                amv_next = MAPc8bAMV_func(pix1.raw & 32'hff);
            end
        end
        3'h6, 3'h7: begin
            if (PRE0 & PRE0_LINEAR) begin
                pres_next = pix1.raw;
                amv_next = 8'h49;
            end else begin
                pres_next = (mcore.plut[pix1.c16b.c] & 16'h7fff) | pixel_in & 16'h8000;
                amv_next = MAPc16bAMV_func((pix1.raw >> 5) & 16'h1FF);
            end
        end
        default: begin
            pres_next = mcore.plut[(pdec_in.plutaCCBbits + ((pix1.raw & pdec_in.pixelBitsMask) * 2)) >> 1];
            amv_next = 8'h49;
        end
    endcase
    transparent_next = ((pres_next & 16'h7fff) == 16'h0) & pdec_in.tmask;
end

assign pres_out = pres_reg;
assign amv_out = amv_reg;
assign transparent = transparent_reg;

always_ff @(posedge aclk, negedge aresetn) begin
    if (!aresetn) begin
        pres_reg <= '0;
        amv_reg <= '0;
        transparent_reg <= '0;
        pixel_valid_out <= '0;
    end else begin
        pres_reg <= pres_next;
        amv_reg <= amv_next;
        transparent_reg <= transparent_next;
        pixel_valid_out <= pixel_valid_in;
    end
end

function pd_uint16_t MAPu8b_func (input pd_uint8_t i);
    pdeco pix1, pix2;

    pix1.raw = i;

    pix2.r16b.b = (pix1.u8b.b << 3) + (pix1.u8b.b << 1) + (pix1.u8b.b >> 1);
    pix2.r16b.g = (pix1.u8b.g << 2) + (pix1.u8b.g >> 1);
    pix2.r16b.r = (pix1.u8b.r << 2) + (pix1.u8b.r >> 1);
    MAPu8b_func = pix2.raw & 16'h7fff;

endfunction

function pd_uint16_t MAPc8bAMV_func (input pd_uint8_t i);
    pdeco pix1;
    pd_uint16_t resamv;

    pix1.raw = i;
    resamv = (pix1.c8b.m << 1) + pix1.c8b.mpw;
    MAPc8bAMV_func = (resamv << 6) + (resamv << 3) + resamv;

endfunction

function pd_uint16_t MAPc16bAMV_func (input pd_uint16_t i);
    pdeco pix1;

    pix1.raw = i << 5;
    MAPc16bAMV_func = (pix1.c16b.mr << 6) + (pix1.c16b.mg << 3) + pix1.c16b.mb;
endfunction

endmodule