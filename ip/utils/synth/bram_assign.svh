`ifndef BRAM_ASSIGN_SVH
`define BRAM_ASSIGN_SVH

`define BRAM_ASSIGN(_dst, _src) \
assign ``_dst.addra = ``_src.addra; \
assign ``_dst.dina = ``_src.dina; \
assign ``_dst.wea = ``_src.wea; \
assign ``_dst.ena = ``_src.ena; \
assign ``_src.douta = ``_dst.douta;

`endif /*BRAM_ASSIGN_SVH*/