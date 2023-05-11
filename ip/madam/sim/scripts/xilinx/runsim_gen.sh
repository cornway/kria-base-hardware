#!/bin/bash

if test "$#" -ne 2; then
        echo "Usage: $0 <top_project_dir> <top module name>"
        exit -1
fi

TOP_DIR=$(realpath $1)
TOP_MODULE=$2

LIB_NAME="xil_default_lib"

UT_TOP_PATH="$TOP_DIR/ip/madam/sim/draw_ut_top.sv"

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
        $TOP_DIR/ip/madam/synth/draw_packed_cel_0.sv \
        $TOP_DIR/ip/madam/synth/packed_header.sv \
        $TOP_DIR/ip/madam/synth/draw_scaled.sv \
        $TOP_DIR/ip/madam/synth/fb.sv \
        $TOP_DIR/ip/utils/synth/if.sv \
        $TOP_DIR/ip/madam/synth/mcore.sv \
        $TOP_DIR/ip/madam/synth/mcore_if.sv \
        $TOP_DIR/ip/utils/synth/mem_wconvert.sv \
        $TOP_DIR/ip/madam/synth/pdec.sv \
        $TOP_DIR/ip/utils/synth/xmem_cross.sv \
        $TOP_DIR/ip/utils/synth/xilinx/xmem_mux.sv \
        $UT_TOP_PATH"

INC_SV="--include $TOP_DIR/ip/common_cells/include/common_cells \
        --include $TOP_DIR/ip/axi/include/axi \
        --include $TOP_DIR/ip/madam/synth \
        --include $TOP_DIR/ip/utils/synth \
        --include $TOP_DIR/ip/madam/sim"

#prepare unit test
rm $UT_TOP_PATH
cp "$TOP_DIR/ip/madam/sim/draw_ut_top_template.sv" $UT_TOP_PATH

SIM_DIR_PATH=$TOP_DIR/ip/madam/sim
TEST_DATA=$SIM_DIR_PATH/test_data/$TOP_MODULE

sed -i "s+UT_TOP_MODULE_NAME+$TOP_MODULE\_ut_top+g" -i $UT_TOP_PATH

sed -i "s+CEL_SETUP_SVH+$TOP_MODULE\_cel_setup.svh+g" -i $UT_TOP_PATH
sed -i "s+CEL_CHECK_SVH+$TOP_MODULE\_cel_check.svh+g" -i $UT_TOP_PATH

sed -i "s+MEM_CAP_BEFORE+$TEST_DATA\_before.bin+g" -i $UT_TOP_PATH
sed -i "s+MEM_CAP_AFTER+$TEST_DATA\_after.bin+g" -i $UT_TOP_PATH

sed -i "s+TRIGGER_REG_NUM+MCORE_${TOP_MODULE^^}_TRIGGER_ID+g" -i $UT_TOP_PATH

#Cleanup
rm -rf xsim.dir/

xvlog $INC_V $SRCS_V --sv $INC_SV $SRCS_SV
[[ $? -ne 0 ]] && exit 1

xelab -debug typical -top $TOP_MODULE\_ut_top -snapshot snapshot
[[ $? -ne 0 ]] && exit 1

xsim -R snapshot
[[ $? -ne 0 ]] && exit 1

exit 0