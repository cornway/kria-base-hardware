`timescale 1ns/1ps

`include "bitreader_types.svh"
`include "mcore_defs.svh"
`include "pdec_defs.svh"
`include "typedef.svh"

module mcore_top #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,
    parameter PIXEL_WIDTH = 32'd16
) (

    input wire aclk,
    input wire aresetn,

    input wire mr_clka,
    input wire mr_rsta,
    input wire [ADDR_WIDTH-1:0] mr_addra,
    input wire [DATA_WIDTH-1:0] mr_dina,
    output wire [DATA_WIDTH-1:0] mr_douta,
    input wire mr_ena,
    input wire [DATA_WIDTH/8-1:0] mr_wea,

    //Memory interface
    output wire mem_req,
    output wire [ADDR_WIDTH-1:0] mem_addr,
    output wire mem_we,
    output wire [DATA_WIDTH-1:0] mem_wdata,
    output wire [DATA_WIDTH/8-1:0] mem_be,

    input wire mem_gnt,
    input wire mem_rsp_valid,
    input wire [DATA_WIDTH-1:0] mem_rsp_rdata,
    input wire mem_rsp_error,

    output wire [ADDR_WIDTH-1:0] ps_mem_offset_out,
    output wire [63:0] debug_port

);

localparam DATA_ADDR_INC = DATA_WIDTH/8;

`define REG_ADDR(_x) 32'd0 + DATA_ADDR_INC*_x
`define ADDR_TO_REG_ID(_addr) (_addr >> $clog2(DATA_WIDTH/8))
`define BITS_FROM_INDEX(_i, _bits) (_i + 1) * _bits - 1 : _i * _bits

logic [ADDR_WIDTH-1:0] ps_mem_offset;
logic [ADDR_WIDTH-1:0] mr_addra_off;
logic [ADDR_WIDTH-1:0] mr_reg_id;
logic [DATA_WIDTH-1:0] mr_douta_reg;
logic [DATA_WIDTH-1:0] pbsq_dout;
logic [DATA_WIDTH-1:0] ps_mem_test_rsp_rdata_reg;

assign ps_mem_offset_out = ps_mem_offset;
assign mr_addra_off = mr_addra & (~M_ADDR_MASK);
assign mr_reg_id = `ADDR_TO_REG_ID(mr_addra_off);
assign mr_douta = mr_douta_reg;


mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) ps_mem();

mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) ps_mem_test();

mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) ps_mem_out();


mcore_t mcore;
integer i;

always_ff @( posedge mr_clka ) begin
    if (!aresetn) begin

    end else if (mr_ena && mr_wea) begin
        unique case (mr_addra & M_ADDR_MASK)
            M_RMOD_WMOD_FSM_ADDR: begin
                unique case(mr_reg_id)
                    32'h0: begin
                        mcore.rmod <= mr_dina;
                    end
                    32'h1: begin
                        mcore.wmod <= mr_dina;
                    end
                    32'h2: begin
                        mcore.fsm <= mr_dina;
                    end
                endcase
            end
            M_PBUSQ_ADDR: begin
                for (i = 0; i < DATA_WIDTH/8; i++) begin
                    if (mr_wea[i])
                        mcore.pbus_queue[mr_addra_off + i] <= byte_t'(mr_dina >> (i * 8));
                end
            end
            M_PLUT_ADDR: begin
                mcore.plut[mr_reg_id] <= mr_dina;
            end
            M_REGS_ADDR: begin
                mcore.regs[mr_reg_id] <= mr_dina;
            end
            M_CEL_VARS_ADDR: begin
                if (mr_reg_id & CEL_VARS_SUB_SIZE) begin
                    mcore.cel_vars.var_unsigned[mr_reg_id ^ CEL_VARS_SUB_SIZE] <= mr_dina;
                end else begin
                    mcore.cel_vars.var_signed[mr_reg_id] <= mr_dina;
                end
            end
        default: begin
        end
        endcase
    end
end

always_ff @(posedge mr_clka) begin
    if (mr_ena) begin
        unique case (mr_addra & M_ADDR_MASK)
            M_RMOD_WMOD_FSM_ADDR: begin
                unique case(mr_reg_id)
                    32'h0: begin
                        mr_douta_reg <= mcore.rmod;
                    end
                    32'h1: begin
                        mr_douta_reg <= mcore.wmod;
                    end
                    32'h2: begin
                        mr_douta_reg <= mcore.fsm;
                    end
                endcase
            end
            M_PBUSQ_ADDR: begin
                mr_douta_reg <= pbsq_dout;
            end
            M_PLUT_ADDR: begin
                mr_douta_reg <= mcore.plut[mr_reg_id];
            end
            M_REGS_ADDR: begin
                mr_douta_reg <= mcore.regs[mr_reg_id];
            end
            M_CEL_VARS_ADDR: begin
                if (mr_reg_id & CEL_VARS_SUB_SIZE) begin
                    mr_douta_reg <= mcore.cel_vars.var_unsigned[mr_reg_id ^ CEL_VARS_SUB_SIZE];
                end else begin
                    mr_douta_reg <= mcore.cel_vars.var_signed[mr_reg_id];
                end
            end
            M_UTIL_ADDR: begin
                case (mr_reg_id)
                    32'h0: begin
                        mr_douta_reg <= ps_mem_offset;
                    end
                    32'h1: begin
                        mr_douta_reg <= bitreader_attach_addr;
                    end
                    32'h2: begin
                        mr_douta_reg <= bitreader_busy;
                    end
                    32'h3: begin
                        mr_douta_reg <= bitreader_data_out;
                    end
                    32'h4: begin
                        mr_douta_reg <= bitreader_offset;
                    end
                    //PDEC
                    32'h24: begin
                        mr_douta_reg <= {'0, pdec_amv, pdec_pres};
                    end
                    32'h25: begin
                        mr_douta_reg <= {'0, pdec_transparent};
                    end

                    //FB
                    32'h41: begin
                        mr_douta_reg <=  {'0, fb_busy, fb_pixel};
                    end
                    //Test Memory
                    32'h100: begin
                        mr_douta_reg <= ps_mem_test.addr;
                    end
                    32'h101: begin
                        mr_douta_reg <= ps_mem_test_rsp_rdata_reg;
                    end
                    32'h102: begin
                        mr_douta_reg <= {'0, ps_mem_test.rsp_valid};
                    end
                default: begin
                    mr_douta_reg <= '0;
                end
                endcase
            end
            default: begin
                mr_douta_reg <= '0;
            end
        endcase
    end
end

genvar j;
generate

for (j = 0; j < DATA_WIDTH/8; j++) begin
    assign pbsq_dout[`BITS_FROM_INDEX(j, 8)] = mcore.pbus_queue[mr_reg_id + j];
end

endgenerate


//Bitreader/memory

logic [ADDR_WIDTH-1:0] bitreader_attach_addr;
logic [DATA_WIDTH-1:0] bitreader_bitrate;
logic [DATA_WIDTH-1:0] bitreader_bitskip;
logic [DATA_WIDTH-1:0] bitreader_data_out;
logic [ADDR_WIDTH-1:0] bitreader_offset;
logic bitreader_aresetn;
bitreader_op_e bitreader_op;
logic bitreader_req, bitreader_busy, bitreader_data_ready;

always_ff @( posedge mr_clka ) begin
    if (!aresetn) begin
        ps_mem_offset <= '0;
        bitreader_req <= '0;
        bitreader_aresetn <= '1;

        ps_mem_test.wdata <= '0;
        ps_mem_test.addr <= '0;
        ps_mem_test.req <= '0;
        ps_mem_test.we <= '0;
        ps_mem_test.be <= '0;
        ps_mem_test_rsp_rdata_reg <= '0;
        pdec_data <= '{default: '0};
    end else begin
        if (mr_ena && mr_wea) begin
            unique case (mr_addra & M_ADDR_MASK)
                M_UTIL_ADDR: begin
                    case (mr_reg_id)
                        32'h0: begin
                            ps_mem_offset <= mr_dina;
                        end
                        32'h1: begin
                            bitreader_req <= '1;
                            bitreader_attach_addr <= mr_dina;
                            bitreader_op <= BR_ATTACH;
                        end
                        32'h2: begin
                            bitreader_req <= '1;
                            bitreader_op <= bitreader_op_e'(mr_dina[1:0]);
                            bitreader_bitrate <= mr_dina[15:8];
                            bitreader_bitskip <= mr_dina[31:16];
                        end
                        32'h3: begin
                            bitreader_aresetn <= '0;
                            bitreader_attach_addr <= '0;
                            bitreader_req <= '0;
                            bitreader_op <= BR_ATTACH;
                            bitreader_bitrate <= '0;
                            bitreader_bitskip <= '0;
                        end
                        //PDEC
                        32'h20: begin
                            pdec_data.plutaCCBbits <= mr_dina;
                        end
                        32'h21: begin
                            pdec_data.pixelBitsMask <= mr_dina;
                        end
                        32'h22: begin
                            pdec_data.tmask <= mr_dina[0];
                        end

                        32'h40: begin
                            fb_x <= mr_dina[15:0];
                            fb_y <= mr_dina[31:16];
                        end
                        32'h41: begin
                            fb_pixel <= mr_dina[15:0];
                            fb_req <= '1;
                        end
                        32'h100: begin
                            ps_mem_test.addr <= mr_dina;
                        end
                        32'h101: begin
                            ps_mem_test.wdata <= mr_dina;
                        end
                        32'h102: begin
                            ps_mem_test.req <= '1;
                            ps_mem_test.we <= mr_dina[0];
                            ps_mem_test.be <= '1;
                        end
                        32'h103: begin
                            ps_mem_test.wdata <= '0;
                            ps_mem_test.addr <= '0;
                            ps_mem_test.req <= '0;
                            ps_mem_test.we <= '0;
                            ps_mem_test.be <= '0;
                        end

                        default: begin
                        end
                    endcase
                end
                default: begin
                end
            endcase
        end
        if (bitreader_busy) begin
            bitreader_req <= '0;
        end
        if (!bitreader_aresetn) begin
            bitreader_aresetn <= '1;
        end
        if (ps_mem_test.rsp_valid) begin
            ps_mem_test.wdata <= '0;
            ps_mem_test.addr <= '0;
            ps_mem_test.req <= '0;
            ps_mem_test.we <= '0;
            ps_mem_test.be <= '0;
            ps_mem_test_rsp_rdata_reg <= ps_mem_test.rsp_rdata;
        end
        if (fb_busy) begin
            fb_req <= '0;
        end
    end
end

bitreader #(.DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH))
            bitreader_inst (
                .aclk(aclk),
                .aresetn(aresetn && bitreader_aresetn),

                .mem_req(ps_mem.req),
                .mem_addr(ps_mem.addr),
                .mem_we(ps_mem.we),
                .mem_wdata(ps_mem.wdata),
                .mem_be(ps_mem.be),
                .mem_gnt(ps_mem.gnt),
                .mem_rsp_valid(ps_mem.rsp_valid),
                .mem_rsp_rdata(ps_mem.rsp_rdata),
                .mem_rsp_error(ps_mem.rsp_error),

                .addr_in(bitreader_attach_addr),
                .bitrate_in(bitreader_bitrate),
                .bitskip_in(bitreader_bitskip),
                .req(bitreader_req),
                .op(bitreader_op),
                .ap_busy(bitreader_busy),
                .ap_data_ready(bitreader_data_ready),
                .data_out(bitreader_data_out),
                .offset_out(bitreader_offset),
                .debug_port(debug_port)
            );

pdec pdec_data;
logic pdec_transparent;
logic [15:0] pdec_amv;
logic [15:0] pdec_pres;

pdec #(
) pdec_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .pixel_in(bitreader_data_out),
    .pdec_in(pdec_data),
    .mcore(mcore),
    .transparent(pdec_transparent),
    .amv_out(pdec_amv),
    .pres_out(pdec_pres),
    .ap_busy(),
    .ap_data_ready()
);

mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) fb_mem();

uint16_t fb_pixel;
uint16_t fb_x, fb_y;
logic fb_req, fb_resp, fb_busy;

frame_buffer #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .PIXEL_WIDTH(PIXEL_WIDTH)
) frame_buffer_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .memory(fb_mem.slave),
    .mcore(mcore),
    .pixel(fb_pixel),
    .x(fb_x),
    .y(fb_y),
    .req(fb_req),
    .resp(fb_resp),
    .busy(fb_busy)
);

assign mem_req = ps_mem_out.req;
assign mem_addr = ps_mem_out.addr;
assign mem_we = ps_mem_out.we;
assign mem_wdata = ps_mem_out.wdata;
assign mem_be = ps_mem_out.be;

assign ps_mem_out.gnt = mem_gnt;
assign ps_mem_out.rsp_valid = mem_rsp_valid;
assign ps_mem_out.rsp_rdata = mem_rsp_rdata;
assign ps_mem_out.rsp_error = mem_rsp_error;


xmem_cross_or #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .NUM_MASTERS(3)
) xmem_cross_or_inst (
    .m_if( '{   ps_mem.master,
                ps_mem_test.master,
                fb_mem.master
            } ),

    .s_if(ps_mem_out.slave)
);

endmodule