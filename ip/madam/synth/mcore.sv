

`include "mcore_defs.svh"
`include "typedef.svh"

interface ps_mem_if #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32
);

    logic req;
    logic [ADDR_WIDTH-1:0] addr;
    logic we;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH/8-1:0] be;
    logic gnt;
    logic rsp_valid;
    logic [DATA_WIDTH-1:0] rsp_rdata;
    logic rsp_error;

endinterface

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

    //Req channel
    output wire [AXI_ADDR_WIDTH-1:0] m_axi_aw_addr,
    output wire [2:0] m_axi_aw_prot,
    output wire m_axi_aw_valid,
    output wire [AXI_DATA_WIDTH-1:0] m_axi_w_data,
    output wire [AXI_DATA_WIDTH/8-1:0] m_axi_w_strb,
    output wire m_axi_w_valid,
    output wire m_axi_b_ready,
    output wire [AXI_ADDR_WIDTH-1:0] m_axi_ar_addr,
    output wire [2:0] m_axi_ar_prot,
    output wire m_axi_ar_valid,
    output wire m_axi_r_ready,

    //Resp channel
    input wire m_axi_aw_ready,
    input wire m_axi_w_ready,
    input wire [1:0] m_axi_b_resp,
    input wire m_axi_b_valid,
    input wire m_axi_ar_ready,
    input wire [AXI_DATA_WIDTH-1:0] m_axi_r_data,
    input wire [1:0] m_axi_r_resp,
    input wire m_axi_r_valid,


    output wire [32:0] debug

);

localparam DATA_ADDR_INC = DATA_WIDTH/8;

`define REG_ADDR(_x) 32'd0 + DATA_ADDR_INC*_x
`define ADDR_TO_REG_ID(_addr) (_addr >> $clog2(DATA_WIDTH/8))
`define BITS_FROM_INDEX(_i, _bits) (_i + 1) * _bits - 1 : _i * _bits

logic [ADDR_WIDTH-1:0] ps_mem_offset;
logic [ADDR_WIDTH-1:0] mr_addra_off;
logic [ADDR_WIDTH-1:0] mr_reg_id;
logic [DATA_WIDTH-1:0] mr_douta_reg;
logic [ADDR_WIDTH-1:0] cel_vars_addr_off;
logic [DATA_WIDTH-1:0] pbsq_dout;

assign mr_addra_off = mr_addra & (~M_ADDR_MASK);
assign mr_reg_id = `ADDR_TO_REG_ID(mr_addra_off);
assign cel_vars_reg_id = `ADDR_TO_REG_ID(mr_addra_off & (~CEL_VARS_SUB_SIZE));
assign mr_douta = mr_douta_reg;


ps_mem_if #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) ps_mem();

logic ps_mem_test_req, ps_mem_test_resp;
logic ps_mem_test_resp_next;
logic [31:0] ps_mem_test_data_count_p, ps_mem_test_data_count;
logic [31:0] ps_mem_test_data_count_next;
logic [31:0] ps_mem_test_value;

mcore_t mcore;
integer i;

always_ff @( posedge mr_clka ) begin
    if (!aresetn) begin
        ps_mem_test_req <= '0;
        ps_mem_test_data_count_p <= '0;
        ps_mem_offset <= '0;
        ps_mem_test_value <= '0;
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
                if (mr_addra_off & CEL_VARS_SUB_SIZE) begin
                    mcore.cel_vars.var_unsigned[cel_vars_reg_id] <= mr_dina;
                end else begin
                    mcore.cel_vars.var_signed[cel_vars_reg_id] <= mr_dina;
                end
            end
            M_UTIL_ADDR: begin
                case (mr_reg_id)
                    32'h0: begin
                        ps_mem_offset <= mr_dina;
                    end
                    32'h1: begin
                        ps_mem_test_req <= ~ps_mem_test_req;
                    end
                    32'h2: begin
                        ps_mem_test_data_count_p <= mr_dina;
                    end
                    32'h3: begin
                        ps_mem_test_value <= mr_dina;
                    end
                endcase
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
                if (mr_addra_off & CEL_VARS_SUB_SIZE) begin
                    mr_douta_reg <= mcore.cel_vars.var_unsigned[cel_vars_reg_id];
                end else begin
                    mr_douta_reg <= mcore.cel_vars.var_signed[cel_vars_reg_id];
                end
            end
            M_UTIL_ADDR: begin
                case (mr_reg_id)
                    32'h0: begin
                        mr_douta_reg <= ps_mem_offset;
                    end
                    32'h1: begin
                        mr_douta_reg <= ps_mem_test_req == ps_mem_test_resp;
                    end
                    32'h2: begin
                        mr_douta_reg <= ps_mem_test_data_count;
                    end
                    32'h3: begin
                        mr_douta_reg <= ps_mem_test_value;
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

typedef enum logic[2:0] { psmt_idle, psmt_write, psmt_resp } ps_mtest_state_t;

ps_mtest_state_t psmt_state, psmt_state_next;

always_ff @(posedge mr_clka) begin
    if (!aresetn) begin
        ps_mem_test_resp <= '0;
        ps_mem_test_data_count <= '0;
        psmt_state <= psmt_idle;
    end else begin
        psmt_state <= psmt_state_next;
        ps_mem_test_data_count <= ps_mem_test_data_count_next;
        ps_mem_test_resp <= ps_mem_test_resp_next;
    end
end

assign debug[31] = ps_mem.req;
assign debug[30] = ps_mem.we;
assign debug[29] = ps_mem.gnt;
assign debug[28] = ps_mem.rsp_valid;
assign debug[27] = ps_mem.rsp_error;
assign debug[26:24] = psmt_state;

always_comb begin
    ps_mem_test_resp_next = ps_mem_test_resp;
    ps_mem_test_data_count_next = ps_mem_test_data_count;
    psmt_state_next = psmt_state;
    ps_mem.req = '0;
    ps_mem.be = '0;
    ps_mem.we = '0;
    ps_mem.addr = '0;
    ps_mem.wdata = '0;
    case (psmt_state)
        psmt_idle: begin
            if (ps_mem_test_req != ps_mem_test_resp) begin
                psmt_state_next = psmt_write;
            end
        end
        psmt_write: begin
            if (ps_mem_test_data_count < ps_mem_test_data_count_p) begin
                ps_mem.addr = ps_mem_test_data_count << $clog2(DATA_WIDTH/8);
                ps_mem.wdata = ps_mem_test_data_count | ps_mem_test_value;
                ps_mem.be = '1;
                ps_mem.we = '1;
                ps_mem.req = '1;
                if (ps_mem.gnt) begin
                    psmt_state_next = psmt_resp;
                end
            end else begin
                ps_mem_test_resp_next = ps_mem_test_req;
                ps_mem_test_data_count_next = '0;
                psmt_state_next = psmt_idle;
            end
        end
        psmt_resp: begin
            if (ps_mem.rsp_valid) begin
                ps_mem_test_data_count_next = ps_mem_test_data_count + 1'b1;
                psmt_state_next = psmt_write;
            end
        end
    endcase
end

`AXI_LITE_TYPEDEF_ALL(axi_lite, logic [AXI_ADDR_WIDTH-1:0], logic [AXI_DATA_WIDTH-1:0], logic [AXI_DATA_WIDTH/8-1:0])
axi_lite_req_t axi_lite_req;
axi_lite_resp_t axi_lite_rsp;

  axi_lite_from_mem #(
    .MemAddrWidth    ( ADDR_WIDTH        ),
    .AxiAddrWidth    ( AXI_ADDR_WIDTH    ),
    .DataWidth       ( DATA_WIDTH        ),
    .MaxRequests     ( 32'd2             ),
    .AxiProt         ( 32'b010           ),
    .axi_req_t       ( axi_lite_req_t    ),
    .axi_rsp_t       ( axi_lite_resp_t   )
  ) i_axi_lite_from_mem (
    .clk_i          (mr_clka),
    .rst_ni         (aresetn),
    .mem_req_i      (ps_mem.req),
    .mem_addr_i     (ps_mem.addr),
    .mem_we_i       (ps_mem.we),
    .mem_wdata_i    (ps_mem.wdata),
    .mem_be_i       (ps_mem.be),
    .mem_gnt_o      (ps_mem.gnt),
    .mem_rsp_valid_o(ps_mem.rsp_valid),
    .mem_rsp_rdata_o(ps_mem.rsp_rdata),
    .mem_rsp_error_o(ps_mem.rsp_error),
    .axi_req_o       ( axi_lite_req    ),
    .axi_rsp_i       ( axi_lite_rsp    )
  );



    //Req channel
    assign m_axi_aw_addr = axi_lite_req.aw.addr | ps_mem_offset;
    assign m_axi_aw_prot = axi_lite_req.aw.prot;
    assign m_axi_aw_valid = axi_lite_req.aw_valid;
    assign m_axi_w_data = axi_lite_req.w.data;
    assign m_axi_w_strb = axi_lite_req.w.strb;
    assign m_axi_w_valid = axi_lite_req.w_valid;
    assign m_axi_b_ready = axi_lite_req.b_ready;
    assign m_axi_ar_addr = axi_lite_req.ar.addr | ps_mem_offset;
    assign m_axi_ar_prot = axi_lite_req.ar.prot;
    assign m_axi_ar_valid = axi_lite_req.ar_valid;
    assign m_axi_r_ready = axi_lite_req.r_ready;

    //Resp channel
    assign axi_lite_rsp.aw_ready = m_axi_aw_ready;
    assign axi_lite_rsp.w_ready = m_axi_w_ready;
    assign axi_lite_rsp.b.resp = m_axi_b_resp;
    assign axi_lite_rsp.b_valid = m_axi_b_valid;
    assign axi_lite_rsp.ar_ready = m_axi_ar_ready;
    assign axi_lite_rsp.r.data = m_axi_r_data;
    assign axi_lite_rsp.r.resp = m_axi_r_resp;
    assign axi_lite_rsp.r_valid = m_axi_r_valid;


endmodule