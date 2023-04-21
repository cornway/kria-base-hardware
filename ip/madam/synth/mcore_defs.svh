
`ifndef MCORE_DEFS_SVH
`define MCORE_DEFS_SVH

typedef logic signed [31:0] int32_t;
typedef logic [31:0] uint32_t;
typedef logic signed [32:0] int33_t;
typedef logic [32:0] uint33_t;

typedef logic signed [15:0] int16_t;
typedef logic [15:0] uint16_t;

typedef logic signed [7:0] int8_t;
typedef logic [7:0] uint8_t;

typedef logic [7:0] byte_t;

typedef logic[15:0] pixel_t;

parameter CEL_VARS_SUB_SIZE = 32'h80;

typedef struct {
    int32_t var_signed [24];
    uint32_t var_unsigned [24];
} cel_vars_t;

typedef struct {
    bit [31:0] regs[2048];
    bit [15:0] plut[32];
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


parameter HDDX1616_ID           = 0;
parameter HDDY1616_ID           = 1;
parameter HDX1616_ID            = 2;
parameter HDY1616_ID            = 3;
parameter VDX1616_ID            = 4;
parameter VDY1616_ID            = 5;
parameter XPOS1616_ID           = 6;
parameter YPOS1616_ID           = 7;
parameter HDX1616_2_ID          = 8;
parameter HDY1616_2_ID          = 9;
parameter TEXTURE_WI_START_ID   = 10;
parameter TEXTURE_HI_START_ID   = 11;
parameter TEXEL_INCX_ID         = 12;
parameter TEXEL_INCY_ID         = 13;
parameter TEXTURE_WI_LIM_ID     = 14;
parameter TEXTURE_HI_LIM_ID     = 15;
parameter TEXEL_FUN_NUMBER_ID   = 16;
parameter SPRWI_ID              = 17;
parameter SPRHI_ID              = 18;
parameter CELCYCLES_ID          = 19;
parameter __smallcycles_ID      = 20;
//static SDL_Event cpuevent;
parameter BITCALC_ID            = 21;



parameter BITADDR_ID            = 0;
parameter BITBUFLEN_ID          = 1;
parameter BITBUF_ID             = 2;

parameter CCBFLAGS_ID           = 3;
parameter PIXC_ID               = 4;
parameter PRE0_ID               = 5;
parameter PRE1_ID               = 6;
parameter TARGETPROJ_ID         = 7;
parameter SRCDATA_ID            = 8;
parameter PLUTF_ID              = 9;
parameter PDATF_ID              = 10;
parameter NCCBF_ID              = 11;
parameter PXOR1_ID              = 12;
parameter PXOR2_ID              = 13;


parameter MREGS_FBTARGET_ID     = 32'h13c;

`endif /*MCORE_DEFS_SVH*/