
`ifndef BITREADER_TYPES_SVH
`define BITREADER_TYPES_SVH

typedef enum logic [1:0] {
    BR_ATTACH = 2'd0,
    BR_SKIP = 2'd1,
    BR_READ = 2'd2
} bitreader_op_e;

`define BIT_IF_INIT(_if) \
_if.req = '0; \
_if.op = BR_ATTACH; \
_if.addr = '0; \
_if.bitskip = '0; \
_if.bitrate = '0;

`define BIT_IF_INIT_S(_src) \
_src.data = '0; \
_src.data_ready = '0; \
_src.busy = '0; \
_src.offset = '0;

`define BIT_IF_ASSIGN(_dst, _src) \
_dst.req = _src.req; \
_dst.op = _src.op; \
_dst.addr = _src.addr; \
_dst.bitskip = _src.bitskip; \
_dst.bitrate = _src.bitrate; \
_src.data = _dst.data; \
_src.data_ready = _dst.data_ready; \
_src.busy = _dst.busy; \
_src.offset = _dst.offset;

`endif /*BITREADER_TYPES_SVH*/