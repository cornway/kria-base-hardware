
`ifndef BITREADER_TYPES_SVH
`define BITREADER_TYPES_SVH

typedef enum logic [1:0] {
    BR_ATTACH = 2'd0,
    BR_SKIP = 2'd1,
    BR_READ = 2'd2
} bitreader_op_e;

`endif /*BITREADER_TYPES_SVH*/