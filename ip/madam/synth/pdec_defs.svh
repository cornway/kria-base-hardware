`ifndef PDEC_DEFS_SVH
`define PDEC_DEFS_SVH

typedef struct packed {
	logic [14:0] pad;
	logic c;
} cp1btag;

typedef struct packed {
	logic [13:0] pad;
	logic [1:0] c;
} cp2btag;

typedef struct packed {
	logic [11:0] pad;
	logic [3:0] c;
} cp4btag;

typedef struct packed {
	logic [9:0] pad;
	logic pw;
	logic [4:0] c;
} cp6btag;

typedef struct packed {
	logic [7:0] pad;
	logic [1:0] m;
	logic mpw;
	logic [4:0] c;
} cp8btag;

typedef struct packed {
	logic pw;
	logic pad;
	logic [2:0] mr;
	logic [2:0] mg;
	logic [2:0] mb;
	logic [4:0] c;
} cp16btag;

typedef struct packed {
	logic [7:0] pad;
	logic [2:0] r;
	logic [2:0] g;
	logic [1:0] b;
} up8btag;

typedef struct packed {
	logic p;
	logic [4:0] r;
	logic [4:0] g;
	logic [3:0] b;
	logic bw;
} up16btag;

typedef struct packed {
	logic p;
	logic [4:0] r;
	logic [4:0] g;
	logic [4:0] b;
} res16btag;

typedef union packed {
	logic [15:0] raw;
	cp1btag c1b;
	cp2btag c2b;
	cp4btag c4b;
	cp6btag c6b;
	cp8btag c8b;
	cp16btag c16b;
	up8btag u8b;
	up16btag u16b;
	res16btag r16b;
} pdeco;

typedef struct {
	logic [31:0] plutaCCBbits;
	logic [31:0] pixelBitsMask;
	logic tmask;
} pdec;

typedef struct {
	logic [31:0] pmode;
	logic [31:0] pmodeORmask;
	logic [31:0] pmodeANDmask;
	logic Transparent;
} pproj;

typedef logic [15:0] pd_uint16_t;
typedef logic [7:0] pd_uint8_t;

`endif /*PDEC_DEFS_SVH*/