# !/bin/bash

# Source the OSS CAD Suite environment
echo "          [COCOTB] Sourcing OSS CAD Suite environment..."
source ~/oss-cad-suite/environment
if [ $? -ne 0 ]; then
    echo "          [COCOTB] FAIL: Failed to source OSS CAD Suite environment. Exiting script."
    exit 1
fi

# Copy original FixedPointAdder.v
cp ${PWD}/../../../../rtl/FixedPointAdder.v .

# Call cocoTB
echo "        [COCOTB][ICARUS] Running testbench..."
python3 testrunner_icarus.py
if [ $? -ne 0 ]; then
    echo "          [COCOTB][ICARUS] FAIL: Simulation failed. Exiting script."
    exit 1
fi
echo "        [COCOTB][ICARUS] PASS: CocoTB simulation passed!"

echo "        [COCOTB][VERILATOR] Running testbench..."
python3 testrunner_verilator.py
if [ $? -ne 0 ]; then
    echo "          [COCOTB][VERILATOR] FAIL: Simulation failed. Exiting script."
    exit 1
fi
echo "        [COCOTB][VERILATOR] PASS: CocoTB simulation passed!"

# Remove FixedPointAdder.-v
rm FixedPointAdder.v