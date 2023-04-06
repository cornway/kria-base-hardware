
`ifndef MCORE_DEFS_SVH
`define MCORE_DEFS_SVH

typedef struct {
    bit [31:0] regs[2048+64];
    bit [15:0] plut[32];
    bit [7:0] pbus_queue[20];
    bit [31:0] rmod;
    bit [31:0] wmod;
    bit [31:0] fsm;
} mcore_t;

parameter M_REGS_ADDR = 32'h0;
parameter M_PLUT_ADDR = 32'h1000;
parameter M_PBUSQ_ADDR = 32'h2000;
parameter M_RMOD_ADDR = 32'h4000;
parameter M_WMOD_ADDR = 32'h4010;
parameter M_FSM_ADDR = 32'h4020;
parameter M_UTIL_ADDR = 32'h8000;

parameter M_ADDR_MASK = M_REGS_ADDR |
                        M_PLUT_ADDR |
                        M_PBUSQ_ADDR |
                        M_RMOD_ADDR |
                        M_WMOD_ADDR |
                        M_FSM_ADDR |
                        M_UTIL_ADDR;

`endif /*MCORE_DEFS_SVH*/