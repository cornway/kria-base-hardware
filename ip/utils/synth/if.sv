interface mem_if #(
    parameter DATA_WIDTH = 32'd32,
    parameter ADDR_WIDTH = 32'd32
);

    //High when requesting memory bus
    logic req;
    //Read/Write address
    logic [ADDR_WIDTH-1:0] addr;
    //Write enable
    logic we;
    //Write data
    logic [DATA_WIDTH-1:0] wdata;
    //Byte enable for write data
    logic [DATA_WIDTH/8-1:0] be;
    //Access granted - high when bus granted
    logic gnt;
    //Transaction completed, high at the end of read/write cycle,
    //generally comes from AXI protocol b channel,
    //if memory has fixed latency and no other masters on the bus - must be always high
    logic rsp_valid;
    //Read data
    logic [DATA_WIDTH-1:0] rsp_rdata;
    //Read/Write error
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
