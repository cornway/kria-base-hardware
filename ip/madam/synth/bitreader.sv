`timescale 1ns/1ps

`include "bitreader_types.svh"


module bitreader #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32
) (
    input wire aclk,
    input wire aresetn,

    //Memory interface
    mem_if.slave memory,
    bitreader_if.master br_if,

    output wire [7:0] debug_port
);

localparam DATA_ALIGN_MASK = (1 << $clog2(DATA_WIDTH/8)) - 1;
localparam DATA_BITS_MASK = (1 << DATA_WIDTH) - 1;

typedef struct {
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] data_cache;
    logic                   data_cache_valid;
    logic [ADDR_WIDTH-1:0] bits_count_cache;
    logic [ADDR_WIDTH-1:0] offset;
    logic [$clog2(DATA_WIDTH):0] bit_offset;
} bitreader_struct_t;


bitreader_struct_t bitreader_struct, bitreader_struct_next;

typedef enum logic[7:0] { bstate_wait_req,
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
logic [DATA_WIDTH-1:0] memory_rsp_rdata_next;
logic [DATA_WIDTH-1:0] bit_skip_next;

assign br_if.offset                     = bitreader_struct.offset;
assign bits_word_offset                 = bitreader_struct.bit_offset + ((bitreader_struct.offset & DATA_ALIGN_MASK) << 3);
assign bits_word_offset_lr_next         = DATA_WIDTH - bits_word_offset;
assign bit_skip_next                    = bitskip_reg + bitreader_struct.bit_offset;
assign mem_addr_aligned                 = (bitreader_struct.addr + bitreader_struct.offset) & ~DATA_ALIGN_MASK;

always_ff @(posedge aclk) begin

    if (!aresetn) begin
        data_out_reg                    <= '0;
        bitskip_reg                     <= '0;
        bitreader_struct                <= '{default: '0};
        b_state                         <= bstate_wait_req;
        b_state_skip_state              <= bstate_wait_req;
        b_state_mem_read_state          <= bstate_wait_req;
        bits_word_offset_lr_reg         <= '0;
    end else begin
        data_out_reg                    <= data_out_reg_next;
        bitskip_reg                     <= bitskip_reg_next;
        bitreader_struct                <= bitreader_struct_next;
        b_state                         <= b_state_next;
        b_state_skip_state              <= b_state_skip_state_next;
        b_state_mem_read_state          <= b_state_mem_read_state_next;
        case (b_state)
            bstate_skip: begin
                bits_word_offset_lr_reg <= bits_word_offset_lr_next;
            end
        endcase
    end

end

always_comb begin
    data_out_reg_next               = data_out_reg;
    bitskip_reg_next                = bitskip_reg;
    bitreader_struct_next           = bitreader_struct;
    b_state_next                    = b_state;
    b_state_skip_state_next         = b_state_skip_state;
    b_state_mem_read_state_next     = b_state_mem_read_state;

    case(b_state)
        bstate_wait_req: begin
            if (br_if.req) begin
                case(br_if.op)
                    BR_ATTACH: b_state_next     = bstate_attach;
                    BR_SKIP: begin
                        bitskip_reg_next        = br_if.bitskip;
                        b_state_skip_state_next = bstate_wait_req;
                        b_state_next            = bstate_skip_invalidate;
                    end
                    BR_READ: begin
                        bitskip_reg_next        = br_if.bitrate;
                        b_state_next            = bstate_read_1;
                    end
                endcase
            end
        end
        bstate_attach: begin
            bitreader_struct_next = '{addr: br_if.addr, default: '0};

            b_state_next = bstate_wait_req;
        end
        bstate_skip: begin
            bitreader_struct_next.offset                = bitreader_struct.offset + (bit_skip_next >> 3);
            bitreader_struct_next.bit_offset            = (bit_skip_next & 32'h7);
            bitreader_struct_next.bits_count_cache      = (bitreader_struct.bits_count_cache + bitskip_reg) & DATA_BITS_MASK;

            b_state_next = b_state_skip_state;
        end
        bstate_skip_invalidate: begin
            if (bitreader_struct.bits_count_cache + bitskip_reg >= DATA_WIDTH) begin
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
                if (bits_word_offset + br_if.bitrate >= DATA_WIDTH) begin
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
            if (memory.gnt) begin
                b_state_next = bstate_mem_resp;
            end
        end
        bstate_mem_resp: begin
            if (memory.rsp_valid) begin
                bitreader_struct_next.data_cache = memory_rsp_rdata_next;
                bitreader_struct_next.data_cache_valid = '1;
                b_state_next = b_state_mem_read_state;
            end
        end
    endcase
end

always_comb begin
    memory.we           = '0;
    memory.be           = '0;
    memory.wdata        = '0;
    memory.req          = '0;
    memory.addr         = '0;
    case (b_state)
        bstate_mem_read: begin
            memory.req = '1;
            memory.addr = mem_addr_aligned;
        end
        bstate_mem_resp: begin
            memory.addr = mem_addr_aligned;
        end
    endcase
end

logic data_ready;

always_ff @(posedge aclk, negedge aresetn) begin
    if (!aresetn) begin
        data_ready <= '0;
    end else begin
        case(b_state)
            bstate_wait_req: begin
                data_ready <= '0;
            end
            bstate_read_1: begin
                if (bitreader_struct.data_cache_valid && (bits_word_offset + br_if.bitrate < DATA_WIDTH)) begin
                    data_ready <= '1;
                end
            end
            bstate_read_2: begin
                data_ready <= '1;
            end
            default: begin
                data_ready <= '0;
            end
        endcase
    end
end

//TODO : Revisit this !
always_ff @(posedge aclk) begin
    //1 Clock latency to settle the output
    br_if.data_ready <= data_ready;
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

assign br_if.data = br_if.bitrate == 32'd24 ? reverse_data_u24 :
                br_if.bitrate == 32'd16 ? reverse_data_u16 :
                br_if.bitrate == 32'd8 ? reverse_data_u8 :
                br_if.bitrate == 32'd6 ? reverse_data_u6 :
                br_if.bitrate == 32'd4 ? reverse_data_u4 :
                br_if.bitrate == 32'd2 ? reverse_data_u2 :
                br_if.bitrate == 32'd1 ? reverse_data_u1 : '0;

assign br_if.busy = b_state != bstate_wait_req;

assign debug_port[7] = br_if.busy;
assign debug_port[4] = br_if.data_ready;
assign debug_port[6:5] = '0;
assign debug_port[3:0] = b_state == bstate_wait_req         ? 5'h0 :
                        b_state == bstate_attach            ? 5'h1 :
                        b_state == bstate_skip              ? 5'h2 :
                        b_state == bstate_skip_invalidate   ? 5'h3 :
                        b_state == bstate_read_1            ? 5'h4 :
                        b_state == bstate_read_2            ? 5'h5 :
                        b_state == bstate_mem_read          ? 5'h6 :
                        b_state == bstate_mem_resp          ? 5'h7 : '0;

`ifndef SYNTHESIS

always_ff @(posedge aclk) begin
    case (b_state)
        bstate_wait_req: begin
            if (br_if.req)
                $display("[BITREADER] bstate_wait_req: br_if.req=%x, br_if.op=%x", br_if.req, br_if.op);
        end
        bstate_attach: begin
            $display("[BITREADER] bstate_attach: addr=%x", bitreader_struct_next.addr);
        end
        bstate_skip: begin
            $display("[BITREADER] bstate_skip #1: bit_skip_next=%x", bit_skip_next);
            $display("[BITREADER] bstate_skip #2: bitreader_struct_next.offset=%x", bitreader_struct_next.offset);
            $display("[BITREADER] bstate_skip #3: bitreader_struct_next.bit_offset=%x", bitreader_struct_next.bit_offset);
            $display("[BITREADER] bstate_skip #4: bitreader_struct_next.bits_count_cache=%x", bitreader_struct_next.bits_count_cache);
        end
        bstate_skip_invalidate: begin
            $display("[BITREADER] bstate_skip_invalidate: bitreader_struct_next.data_cache_valid=%x", bitreader_struct_next.data_cache_valid);
        end
        bstate_read_1: begin
                $display("[BITREADER] bstate_read_1: #1");
                if (bitreader_struct_next.data_cache_valid)
                    $display("[BITREADER] bstate_read_1: #2 bits_word_offset=%x, data_out_reg=%x", bits_word_offset, data_out_reg);
        end
        bstate_read_2: begin
            $display("[BITREADER] bstate_read_2: data_out_reg=%x", data_out_reg);
        end
        bstate_mem_read: begin
            if (memory.gnt)
                $display("[BITREADER] bstate_mem_read: memory.gnt=1");
        end
        bstate_mem_resp: begin
            if (memory.rsp_valid) begin
                $display("[BITREADER] bstate_mem_resp #1: memory.rsp_valid=1 memory_rsp_rdata_next=%x", memory_rsp_rdata_next);
                $display("[BITREADER] bstate_mem_resp #2: b_state_mem_read_state=%x", b_state_mem_read_state);
            end
        end
    endcase
end

`endif /* SYNTHESIS */

endmodule