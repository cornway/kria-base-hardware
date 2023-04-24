`ifndef XMEM_ASSIGN_SVH
`define XMEM_ASSIGN_SVH

`define XMEM_ASSIGN(_src, _dst) \
assign ``_src.req = ``_dst.req; \
assign ``_src.we = ``_dst.we; \
assign ``_src.be = ``_dst.be; \
assign ``_src.addr = ``_dst.addr; \
assign ``_src.wdata = ``_dst.wdata; \
assign ``_dst.gnt = ``_src.gnt; \
assign ``_dst.rsp_valid = ``_src.rsp_valid; \
assign ``_dst.rsp_rdata = ``_src.rsp_rdata; \
assign ``_dst.rsp_error = ``_src.rsp_error;

`endif /*XMEM_ASSIGN_SVH*/