`timescale 1ns/1ps

`include "bitreader_types.svh"
`include "mcore_defs.svh"
`include "typedef.svh"

module mcore_top #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32,

    AXI_ADDR_WIDTH = 32'd32,
    AXI_DATA_WIDTH = 32'd32,
    AXI_ID_WIDTH = 1,
    AXI_USER_WIDTH = 1
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

assign mr_addra_off = mr_addra & (~M_ADDR_MASK);
assign mr_reg_id = `ADDR_TO_REG_ID(mr_addra_off);
assign mr_douta = mr_douta_reg;


mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) ps_mem();

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
                        mcore.pbus_queue[mr_reg_id + i] <= byte_t'(mr_dina >> (i * 8));
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


assign mem_req = ps_mem.req;
assign mem_addr = ps_mem.addr | ps_mem_offset;
assign mem_we = ps_mem.we;
assign mem_wdata = ps_mem.wdata;
assign mem_be = ps_mem.be;

assign ps_mem.gnt = mem_gnt;
assign ps_mem.rsp_valid = mem_rsp_valid;
assign ps_mem.rsp_rdata = mem_rsp_rdata;
assign ps_mem.rsp_error = mem_rsp_error;

endmodule