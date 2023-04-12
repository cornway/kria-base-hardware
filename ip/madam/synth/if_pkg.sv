interface mem_if #(
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

    modport master (
        input rsp_valid, rsp_rdata, rsp_error, gnt,
        output req, addr, wdata, be, we
    );

    modport slave (
        output rsp_valid, rsp_rdata, rsp_error, gnt,
        input req, addr, wdata, be, we
    );

endinterface
