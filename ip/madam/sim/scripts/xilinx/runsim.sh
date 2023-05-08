#!/bin/bash

if test "$#" -ne 2; then
        echo "Usage: $0 <top_project_dir> <top module name>"
        exit -1
fi

TOP_DIR=$1
TOP_MODULE=$2

LIB_NAME="xil_default_lib"

SRCS_V="$TOP_DIR/ip/madam/synth/mcore_wrapper.v"

INC_V="--include $TOP_DIR/ip/common_cells/include/common_cells \
        --include $TOP_DIR/ip/axi/include/axi \
        --include $TOP_DIR/ip/madam/synth \
        --include $TOP_DIR/ip/utils/synth \
        --include $TOP_DIR/ip/madam/sim"

SRCS_SV="$TOP_DIR/ip/utils/synth/arb.sv \
        $TOP_DIR/ip/madam/synth/bitreader.sv \
        $TOP_DIR/ip/utils/sim/bram_if.sv \
        $TOP_DIR/ip/utils/sim/bram_class.sv \
        $TOP_DIR/ip/madam/synth/draw.sv \
        $TOP_DIR/ip/utils/sim/xmem_class.sv \
        $TOP_DIR/ip/madam/sim/mcore_class.sv \
        $TOP_DIR/ip/madam/synth/draw_literal_cel.sv \
        $TOP_DIR/ip/madam/synth/draw_literal_cel_1.sv \
        $TOP_DIR/ip/madam/synth/draw_scaled.sv \
        $TOP_DIR/ip/madam/synth/fb.sv \
        $TOP_DIR/ip/utils/synth/if.sv \
        $TOP_DIR/ip/madam/synth/mcore.sv \
        $TOP_DIR/ip/madam/synth/mcore_if.sv \
        $TOP_DIR/ip/utils/synth/mem_wconvert.sv \
        $TOP_DIR/ip/madam/synth/pdec.sv \
        $TOP_DIR/ip/utils/synth/xmem_cross.sv \
        $TOP_DIR/ip/utils/synth/xilinx/xmem_mux.sv \
        $TOP_DIR/ip/madam/sim/draw_lit_cel_0.sv"

INC_SV="--include $TOP_DIR/ip/common_cells/include/common_cells \
        --include $TOP_DIR/ip/axi/include/axi \
        --include $TOP_DIR/ip/madam/synth \
        --include $TOP_DIR/ip/utils/synth \
        --include $TOP_DIR/ip/madam/sim"


#Cleanup
rm -rf xsim.dir/

xvlog $INC_V $SRCS_V --sv $INC_SV $SRCS_SV

xelab -debug typical -top draw_lit_cel_0_top -snapshot draw_lit_cel_0_snapshot

xsim -R draw_lit_cel_0_snapshot
