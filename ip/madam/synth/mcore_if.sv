
`include "bitreader_types.svh"
`include "mcore_defs.svh"

interface bitreader_if #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32
);

    logic [ADDR_WIDTH-1:0] addr;
    logic [$clog2(DATA_WIDTH):0] bitrate;
    logic [DATA_WIDTH-1:0] bitskip;

    logic req;
    bitreader_op_e op;

    logic [DATA_WIDTH-1:0] data;
    logic [ADDR_WIDTH-1:0] offset;

    logic busy;
    logic data_ready;

    modport master (
        output data, offset, busy, data_ready,
        input addr, bitrate, bitskip, req, op
    );

    modport slave (
        input data, offset, busy, data_ready,
        output addr, bitrate, bitskip, req, op
    );

    modport monitor (
        input data, offset, busy, data_ready,
        addr, bitrate, bitskip, req, op
    );

endinterface //bitreader_if

interface fb_if;
    pixel_t pixel;
    uint16_t x;
    uint16_t y;
    logic req;
    logic resp;
    logic busy;

    modport master (
        output resp, busy,
        input req, pixel, x, y
    );

    modport slave (
        input resp, busy,
        output req, pixel, x, y
    );

    modport monitor (
        input resp, busy,
        req, pixel, x, y
    );

endinterface //fb_if