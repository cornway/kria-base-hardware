

module arbiter_RR #(
    parameter NUM_MASTERS = 2
) (
    input wire aclk,
    input wire aresetn,

    input wire [NUM_MASTERS-1:0] req_in,
    output wire [NUM_MASTERS-1:0] gnt_out,

    input wire [NUM_MASTERS-1:0] release_in,
    output wire [$clog2(NUM_MASTERS)-1:0] select,
    output wire select_valid
);

typedef logic [$clog2(NUM_MASTERS)-1:0] req_t;

req_t req_next, req_next_reg;
req_t req_curr, req_curr_reg;
wire req_in_any;
wire release_in_any;

assign req_in_any = |req_in;
assign release_in_any = |release_in;

typedef enum logic[1:0] { a_idle, a_gnt } a_state_e;

a_state_e a_state, a_state_next;

always_comb begin
    a_state_next = a_state;
    req_curr = req_curr_reg;
    req_next = req_next_reg;

    case (a_state)
        a_idle: begin
            if (req_in_any) begin
                req_curr = get_next_req(req_next_reg);
                a_state_next = a_gnt;
            end
        end
        a_gnt: begin
            if (release_in_any) begin
                req_next = _wrap_next(req_curr_reg);
                a_state_next = a_idle;
            end
        end
    endcase
end

always_ff @(posedge aclk, negedge aresetn) begin
    if (!aresetn) begin
        a_state <= a_idle;
        req_curr_reg <= '0;
        req_next_reg <= '0;
    end else begin
        a_state <= a_state_next;
        req_curr_reg <= req_curr;
        req_next_reg <= req_next;
    end
end

assign select = req_curr_reg;
assign select_valid = a_state != a_idle;

genvar j;
generate
    for (j = 0; j < NUM_MASTERS; j++) begin
        assign gnt_out[j] = req_curr == j ? req_in[j] : '0;
    end
endgenerate

function req_t _wrap_next(input req_t _req);
    _wrap_next = _req >= (NUM_MASTERS-1'b1) ? '0 : _req + 1'b1;
endfunction

function req_t get_next_req (input req_t _req_i);
    automatic integer i;
    automatic req_t req_i = _req_i;

    for (i = 0; i < NUM_MASTERS; i++) begin
        if (req_in[req_i]) begin
            return req_i;
        end
        req_i = _wrap_next(req_i);
    end
    return req_i;
endfunction

`ifndef SYNTHESIS
always_ff @(posedge aclk) begin
    case(a_state)
        a_idle: begin
            if (req_in_any) begin
                $display("[arbiter_RR] received request, requestor = %x", req_curr);
            end
        end
        a_gnt: begin
            if (release_in_any) begin
                $display("[arbiter_RR] received release, requestor = %x, next = %x", req_curr, req_next);
            end
        end
    endcase
end
`endif /*SYNTHESIS*/

endmodule