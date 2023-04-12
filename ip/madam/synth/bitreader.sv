`include "bitreader_types.svh"


module bitreader #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32
) (
    input wire aclk,
    input wire aresetn,

    mem_if memory,

    input wire [ADDR_WIDTH-1:0] addr_in,
    input wire [$clog2(DATA_WIDTH):0] bitrate_in,
    input wire [DATA_WIDTH-1:0] bitskip_in,

    input wire req,
    input bitreader_op_e op,

    output wire ap_busy,

    output wire [DATA_WIDTH-1:0] data_out
);

localparam DATA_ALIGN_MASK = (1 << $clog2(DATA_WIDTH/8)) - 1;

typedef struct {
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] data_cache;
    logic                   data_cache_valid;
    logic [ADDR_WIDTH-1:0] bits_count_cache;
    logic [ADDR_WIDTH-1:0] offset;
    logic [$clog2(DATA_WIDTH):0] bit_offset;
} bitreader_struct_t;


bitreader_struct_t bitreader_struct, bitreader_struct_next;

typedef enum logic[4:0] { bstate_wait_req,
                        bstate_attach,
                        bstate_skip,
                        bstate_skip_invalidate,
                        bstate_read_1,
                        bstate_read_2,
                        bstate_mem_read,
                        bstate_mem_resp } b_state_e;

b_state_e b_state, b_state_next;
b_state_e b_state_mem_read_state, b_state_mem_read_state_next;
b_state_e b_state_skip_state, b_state_skip_state_next;

logic [DATA_WIDTH-1:0] bitskip_reg, bitskip_reg_next;
logic [DATA_WIDTH-1:0] data_out_reg, data_out_reg_next;
logic [DATA_WIDTH-1:0] bits_word_offset;
logic [DATA_WIDTH-1:0] bits_word_offset_lr_reg, bits_word_offset_lr_next;
logic [ADDR_WIDTH-1:0] mem_addr_aligned;
logic [ADDR_WIDTH-1:0] mem_addr_aligned;
logic [DATA_WIDTH-1:0] memory_rsp_rdata, memory_rsp_rdata_next;
logic [DATA_WIDTH-1:0] bit_skip_next;

assign bits_word_offset = bitreader_struct.bit_offset + ((bitreader_struct.offset & DATA_ALIGN_MASK) << 3);
assign bits_word_offset_lr_next = DATA_WIDTH - bits_word_offset;

assign bit_skip_next = bitskip_reg + bitreader_struct.bit_offset;

assign mem_addr_aligned = (bitreader_struct.addr + bitreader_struct.offset) & ~DATA_ALIGN_MASK;

always_ff @(posedge aclk) begin

    if (!aresetn) begin
        data_out_reg <= '0;
        bitskip_reg <= '0;
        bitreader_struct <= '{default: '0};
        b_state <= bstate_wait_req;
        b_state_skip_state <= bstate_wait_req;
        b_state_mem_read_state <= bstate_wait_req;
        bits_word_offset_lr_reg <= '0;
    end else begin
        data_out_reg <= data_out_reg_next;
        bitskip_reg <= bitskip_reg_next;
        bitreader_struct <= bitreader_struct_next;
        b_state <= b_state_next;
        b_state_skip_state <= b_state_skip_state_next;
        b_state_mem_read_state <= b_state_mem_read_state_next;
        case (b_state)
            bstate_skip: begin
                bits_word_offset_lr_reg <= bits_word_offset_lr_next;
            end
        endcase
    end

end

always_comb begin


    memory.req = '0;
    memory.we = '0;
    memory.addr = '0;
    memory.be = '0;
    memory.wdata = '0;

    data_out_reg_next = data_out_reg;
    bitskip_reg_next = bitskip_reg;
    bitreader_struct_next = bitreader_struct;
    b_state_next = b_state;
    b_state_skip_state_next = b_state_skip_state;
    b_state_mem_read_state_next = b_state_mem_read_state;

    case(b_state)
        bstate_wait_req: begin
            if (req) begin
                case(op)
                    BR_ATTACH: b_state_next = bstate_attach;
                    BR_SKIP: begin
                        bitskip_reg_next = bitskip_in;
                        b_state_skip_state_next = bstate_wait_req;
                        b_state_next = bstate_skip_invalidate;
                    end
                    BR_READ: begin
                        bitskip_reg_next = bitrate_in;
                        b_state_next = bstate_read_1;
                    end
                endcase
            end
        end
        bstate_attach: begin
            bitreader_struct_next.addr = addr_in;
            bitreader_struct_next.data_cache = '0;
            bitreader_struct_next.data_cache_valid = '0;
            bitreader_struct_next.bits_count_cache = '0;
            bitreader_struct_next.offset = '0;
            bitreader_struct_next.bit_offset = '0;

            b_state_next = bstate_wait_req;
        end
        bstate_skip: begin
            bitreader_struct_next.offset = bitreader_struct.offset + (bit_skip_next >> 3);
            bitreader_struct_next.bit_offset = (bit_skip_next & 32'h7);
            bitreader_struct_next.bits_count_cache = (bitreader_struct.bits_count_cache + bitskip_reg) & 32'h1f;

            b_state_next = b_state_skip_state;
        end
        bstate_skip_invalidate: begin
            if (bitreader_struct.bits_count_cache + bitskip_reg > 32'h1f) begin
                bitreader_struct_next.data_cache_valid = '0;
            end
            b_state_next = bstate_skip;
        end
        bstate_read_1: begin
            if (bitreader_struct.data_cache_valid == '0) begin
                b_state_mem_read_state_next = bstate_read_1;
                b_state_next = bstate_mem_read;
            end else begin
                data_out_reg_next = bitreader_struct.data_cache >> bits_word_offset;

                if (bits_word_offset + bitrate_in >= 32'd32) begin
                    b_state_skip_state_next = bstate_mem_read;
                    b_state_mem_read_state_next = bstate_read_2;
                    b_state_next = bstate_skip;
                end else begin
                    b_state_skip_state_next = bstate_wait_req;
                    b_state_next = bstate_skip;
                end
            end
        end
        bstate_read_2: begin
            data_out_reg_next = data_out_reg | bitreader_struct.data_cache << bits_word_offset_lr_reg;
            b_state_next = bstate_wait_req;
        end

        bstate_mem_read: begin
            memory.req = '1;
            memory.addr = mem_addr_aligned;
            if (memory.gnt) begin
                b_state_next = bstate_mem_resp;
            end
        end
        bstate_mem_resp: begin
            if (memory.rsp_valid) begin
                bitreader_struct_next.data_cache = memory_rsp_rdata;
                bitreader_struct_next.data_cache_valid = '1;
                b_state_next = b_state_mem_read_state;
            end
        end
    endcase
end

always_ff @(posedge aclk) begin
    if (memory.rsp_valid) begin
        memory_rsp_rdata <= memory_rsp_rdata_next;
    end
end

`define REVERSE_BITS_MACRO(_bits, _input)   \
wire [_bits-1:0] reverse_data_u``_bits;     \
genvar i``_bits;                            \
generate                                    \
for (i``_bits = 0; i``_bits < _bits; i``_bits++) begin \
    assign reverse_data_u``_bits[_bits - 1 - i``_bits] = _input[i``_bits]; \
end                                         \
endgenerate

`REVERSE_BITS_MACRO(32, memory.rsp_rdata);
assign memory_rsp_rdata_next = reverse_data_u32;

`REVERSE_BITS_MACRO(24, data_out_reg);
`REVERSE_BITS_MACRO(16, data_out_reg);
`REVERSE_BITS_MACRO(8, data_out_reg);
`REVERSE_BITS_MACRO(6, data_out_reg);
`REVERSE_BITS_MACRO(4, data_out_reg);
`REVERSE_BITS_MACRO(2, data_out_reg);
`REVERSE_BITS_MACRO(1, data_out_reg);

assign data_out = bitrate_in == 32'd24 ? reverse_data_u24 :
                bitrate_in == 32'd16 ? reverse_data_u16 :
                bitrate_in == 32'd8 ? reverse_data_u8 :
                bitrate_in == 32'd6 ? reverse_data_u6 :
                bitrate_in == 32'd4 ? reverse_data_u4 :
                bitrate_in == 32'd2 ? reverse_data_u2 :
                bitrate_in == 32'd1 ? reverse_data_u1 : '0;

assign ap_busy = b_state != bstate_wait_req;

endmodule