#!/bin/bash

# Set UVM home - UPDATE THIS PATH to where you installed UVM
export UVM_HOME=/Users/fjpolo/uvm-1.2

# Verify UVM exists
if [ ! -f "$UVM_HOME/src/uvm_pkg.sv" ]; then
    echo "        [ERROR] UVM not found at $UVM_HOME/src/uvm_pkg.sv"
    echo "        Download UVM 1.2 from Accellera and set UVM_HOME"
    exit 1
fi

echo "        [UVM] Compiling testbench with UVM at $UVM_HOME..."

# Compile with Icarus Verilog
iverilog -g2012 \
    -I$UVM_HOME/src \
    -D UVM_NO_DEPRECATED \
    -s tb_top \
    -o simv \
    $UVM_HOME/src/uvm_pkg.sv \
    dut_wrapper.sv \
    wbpwmaudio.v \
    tb_top.sv \
    wbpwmaudio_if.sv \
    wbpwmaudio_transaction.sv \
    wbpwmaudio_sequence.sv \
    wbpwmaudio_driver.sv \
    wbpwmaudio_monitor.sv \
    wbpwmaudio_agent.sv \
    wbpwmaudio_env.sv \
    wbpwmaudio_scoreboard.sv \
    wbpwmaudio_test.sv

if [ $? -ne 0 ]; then
    echo "        [UVM] Compilation failed!"
    exit 1
fi

echo "        [UVM] Running test..."
vvp -n simv +UVM_TESTNAME=wbpwmaudio_test +UVM_VERBOSITY=UVM_MEDIUM | tee uvm.log

if grep -q "UVM_ERROR" uvm.log; then
    echo "        [UVM] TEST FAILED"
    exit 1
else
    echo "        [UVM] TEST PASSED"
fi