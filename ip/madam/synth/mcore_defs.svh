
`ifndef MCORE_DEFS_SVH
`define MCORE_DEFS_SVH

typedef logic signed [31:0] int32_t;
typedef logic [31:0] uint32_t;
typedef logic [7:0] byte_t;

parameter CEL_VARS_SUB_SIZE = 32'h80;

typedef struct {
    int32_t var_signed [CEL_VARS_SUB_SIZE];
    uint32_t var_unsigned [CEL_VARS_SUB_SIZE];
} cel_vars_t;

typedef struct {
    bit [31:0] regs[2048];
    bit [31:0] plut[32];
    bit [7:0]  pbus_queue[20];
    bit [31:0] rmod;
    bit [31:0] wmod;
    bit [31:0] fsm;
    cel_vars_t cel_vars;
} mcore_t;

parameter M_REGS_ADDR = 32'h0;
parameter M_PLUT_ADDR = 32'h4000;
parameter M_PBUSQ_ADDR = 32'h8000;
parameter M_RMOD_WMOD_FSM_ADDR = 32'hC000;
parameter M_UTIL_ADDR = 32'h10000;
parameter M_CEL_VARS_ADDR = 32'h14000;

parameter M_ADDR_MASK = M_REGS_ADDR |
                        M_PLUT_ADDR |
                        M_PBUSQ_ADDR |
                        M_RMOD_WMOD_FSM_ADDR |
                        M_UTIL_ADDR |
                        M_CEL_VARS_ADDR;


parameter HDDX1616_ID0      = 0;
parameter HDDY1616_ID1      = 1;
parameter HDX1616_ID2      = 2;
parameter HDY1616_ID3      = 3;
parameter VDX1616_ID4      = 4;
parameter VDY1616_ID5      = 5;
parameter XPOS1616_ID6      = 6;
parameter YPOS1616_ID7      = 7;
parameter HDX1616_2_ID8     = 8;
parameter HDY1616_2_ID9     = 9;
parameter TEXTURE_WI_START_ID10 = 10;
parameter TEXTURE_HI_START_ID11 = 11;
parameter TEXEL_INCX_ID12   = 12;
parameter TEXEL_INCY_ID13   = 13;
parameter TEXTURE_WI_LIM_ID14 = 14;
parameter TEXTURE_HI_LIM_ID15 = 15;
parameter TEXEL_FUN_NUMBER_ID16 = 16;
parameter SPRWI_ID17            = 17;
parameter SPRHI_ID18            = 18;
parameter CELCYCLES_ID19        = 19;
parameter __smallcycles_ID20    = 20;
//static SDL_Event cpuevent;
parameter BITCALC_ID21          = 21;



parameter BITADDR_ID0 = 0;
parameter BITBUFLEN_ID1 = 1;
parameter BITBUF_ID2 = 2;

parameter CCBFLAGS_ID3 = 3;
parameter PIXC_ID4 = 4;
parameter PRE0_ID5 = 5;
parameter PRE1_ID6 = 6;
parameter TARGETPROJ_ID7 = 7;
parameter SRCDATA_ID8 = 8;
parameter PLUTF_ID9 = 9;
parameter PDATF_ID10 = 10;
parameter NCCBF_ID11 = 11;
parameter ADD_ID12 = 12;

`endif /*MCORE_DEFS_SVH*/